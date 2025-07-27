#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Partnership Invitations API Routes
==================================

Rotas da API para gerenciar convites de parceria para perfis externos.
Implementa o sistema de aquisição viral do modelo híbrido.
"""

from typing import List, Dict, Any, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, Path
from fastapi.security import HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel, Field
from datetime import datetime

from ..dependencies.auth import get_current_user
from ..dependencies.database import get_async_db
from ..services.partnership_invitation_service import PartnershipInvitationService

router = APIRouter(prefix="/v1/partnerships/invites", tags=["Partnership Invitations"])
security = HTTPBearer()


# Pydantic Models
class CreateInvitationRequest(BaseModel):
    """Request para criar convite de parceria."""
    external_profile: Dict[str, Any] = Field(..., description="Dados do perfil externo")
    partnership_context: Dict[str, Any] = Field(..., description="Contexto da parceria")
    
    class Config:
        schema_extra = {
            "example": {
                "external_profile": {
                    "full_name": "Dr. João Silva",
                    "profile_url": "https://linkedin.com/in/joao-silva",
                    "headline": "Especialista em Direito Empresarial",
                    "summary": "Advogado com 15 anos de experiência...",
                    "city": "São Paulo",
                    "confidence_score": 0.85
                },
                "partnership_context": {
                    "area_expertise": "Direito Empresarial",
                    "compatibility_score": "85%",
                    "partnership_reason": "Complementa expertise em direito societário"
                }
            }
        }


class InvitationResponse(BaseModel):
    """Response de convite criado."""
    status: str
    invitation_id: str
    claim_url: str
    linkedin_message: str
    invitee_profile_url: Optional[str]
    expires_at: str
    message: Optional[str] = None


class AcceptInvitationRequest(BaseModel):
    """Request para aceitar convite."""
    new_lawyer_id: str = Field(..., description="ID do novo advogado cadastrado")


# Routes
@router.post("/", 
             response_model=InvitationResponse,
             summary="🎯 Criar Convite de Parceria")
async def create_partnership_invitation(
    request: CreateInvitationRequest,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_async_db)
):
    """
    🎯 **Criar Convite de Parceria para Perfil Externo**
    
    Cria um convite para um advogado encontrado via busca externa.
    
    **Fluxo:**
    1. Sistema gera token único e URL de convite
    2. Sistema prepara mensagem personalizada para LinkedIn
    3. Usuário copia mensagem e envia manualmente via LinkedIn
    4. Destinatário clica no link e se cadastra na plataforma
    
    **Assisted Notification Strategy:**
    - Protege a marca LinkedIn da empresa
    - Utiliza credibilidade pessoal do convidador
    - Gera mensagem otimizada para conversão
    
    **Returns:**
    - URL de convite único
    - Mensagem pré-formatada para LinkedIn
    - Dados do convite para tracking
    """
    
    try:
        invitation_service = PartnershipInvitationService(db)
        
        # Extrair dados do usuário atual
        lawyer_id = current_user.get("id") or current_user.get("lawyer_id")
        lawyer_name = current_user.get("name") or current_user.get("full_name", "Advogado")
        
        if not lawyer_id:
            raise HTTPException(
                status_code=400,
                detail="ID do advogado não encontrado no token"
            )
        
        # Validar dados do perfil externo
        external_profile = request.external_profile
        if not external_profile.get("full_name"):
            raise HTTPException(
                status_code=400,
                detail="Nome completo do perfil externo é obrigatório"
            )
        
        # Criar convite
        result = await invitation_service.create_invitation(
            inviter_lawyer_id=lawyer_id,
            inviter_name=lawyer_name,
            external_profile=external_profile,
            partnership_context=request.partnership_context
        )
        
        if result["status"] == "already_exists":
            raise HTTPException(
                status_code=409,
                detail=result["message"]
            )
        
        return InvitationResponse(
            status=result["status"],
            invitation_id=result["invitation_id"],
            claim_url=result["claim_url"],
            linkedin_message=result["linkedin_message"],
            invitee_profile_url=result.get("invitee_profile_url"),
            expires_at=result["expires_at"]
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Erro interno ao criar convite: {str(e)}"
        )


@router.get("/", 
            summary="📋 Listar Meus Convites")
async def get_my_invitations(
    status: Optional[str] = Query(None, description="Filtrar por status (pending, accepted, expired, cancelled)"),
    limit: int = Query(20, ge=1, le=50, description="Limite de resultados"),
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_async_db)
):
    """
    📋 **Listar Convites Enviados**
    
    Retorna lista de convites de parceria enviados pelo advogado atual.
    
    **Filtros disponíveis:**
    - `status`: pending, accepted, expired, cancelled
    - `limit`: quantidade de resultados (max: 50)
    
    **Returns:**
    - Lista de convites com status atualizado
    - Estatísticas de conversão
    - Dados para UI de "Meus Convites"
    """
    
    try:
        invitation_service = PartnershipInvitationService(db)
        
        lawyer_id = current_user.get("id") or current_user.get("lawyer_id")
        if not lawyer_id:
            raise HTTPException(
                status_code=400,
                detail="ID do advogado não encontrado"
            )
        
        # Buscar convites
        invitations = await invitation_service.get_invitations_by_inviter(
            inviter_lawyer_id=lawyer_id,
            status_filter=status,
            limit=limit
        )
        
        # Buscar estatísticas
        stats = await invitation_service.get_invitation_stats(lawyer_id)
        
        return {
            "invitations": invitations,
            "total_count": len(invitations),
            "stats": stats,
            "filters_applied": {
                "status": status,
                "limit": limit
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Erro interno ao buscar convites: {str(e)}"
        )


@router.get("/stats",
            summary="📊 Estatísticas de Convites")
async def get_invitation_statistics(
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_async_db)
):
    """
    📊 **Estatísticas de Convites**
    
    Retorna métricas detalhadas sobre convites enviados:
    - Taxa de aceitação
    - Convites por status
    - Performance ao longo do tempo
    """
    
    try:
        invitation_service = PartnershipInvitationService(db)
        
        lawyer_id = current_user.get("id") or current_user.get("lawyer_id")
        if not lawyer_id:
            raise HTTPException(
                status_code=400,
                detail="ID do advogado não encontrado"
            )
        
        stats = await invitation_service.get_invitation_stats(lawyer_id)
        
        return {
            "lawyer_id": lawyer_id,
            "statistics": stats,
            "generated_at": datetime.utcnow().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Erro interno ao buscar estatísticas: {str(e)}"
        )


@router.get("/{invitation_id}",
            summary="🔍 Detalhes do Convite")
async def get_invitation_details(
    invitation_id: str = Path(..., description="ID do convite"),
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_async_db)
):
    """
    🔍 **Detalhes de um Convite Específico**
    
    Retorna informações detalhadas sobre um convite específico.
    Apenas o criador do convite pode acessar seus detalhes.
    """
    
    try:
        invitation_service = PartnershipInvitationService(db)
        
        lawyer_id = current_user.get("id") or current_user.get("lawyer_id")
        if not lawyer_id:
            raise HTTPException(
                status_code=400,
                detail="ID do advogado não encontrado"
            )
        
        # Buscar convites do usuário e filtrar pelo ID
        invitations = await invitation_service.get_invitations_by_inviter(lawyer_id, limit=100)
        invitation = next((inv for inv in invitations if inv["id"] == invitation_id), None)
        
        if not invitation:
            raise HTTPException(
                status_code=404,
                detail="Convite não encontrado"
            )
        
        return invitation
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Erro interno ao buscar convite: {str(e)}"
        )


@router.delete("/{invitation_id}",
               summary="❌ Cancelar Convite")
async def cancel_invitation(
    invitation_id: str = Path(..., description="ID do convite"),
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_async_db)
):
    """
    ❌ **Cancelar Convite Pendente**
    
    Cancela um convite que ainda está pendente.
    Apenas convites com status 'pending' podem ser cancelados.
    """
    
    try:
        invitation_service = PartnershipInvitationService(db)
        
        lawyer_id = current_user.get("id") or current_user.get("lawyer_id")
        if not lawyer_id:
            raise HTTPException(
                status_code=400,
                detail="ID do advogado não encontrado"
            )
        
        success = await invitation_service.cancel_invitation(invitation_id, lawyer_id)
        
        if not success:
            raise HTTPException(
                status_code=404,
                detail="Convite não encontrado ou não pode ser cancelado"
            )
        
        return {
            "status": "cancelled",
            "message": "Convite cancelado com sucesso",
            "invitation_id": invitation_id
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Erro interno ao cancelar convite: {str(e)}"
        )


# Public endpoints (sem autenticação)
@router.get("/public/{token}",
            summary="🔗 Visualizar Convite (Público)")
async def get_invitation_by_token(
    token: str = Path(..., description="Token do convite"),
    db: AsyncSession = Depends(get_async_db)
):
    """
    🔗 **Visualizar Convite por Token (Endpoint Público)**
    
    Permite que qualquer pessoa visualize um convite usando o token.
    Usado na página de landing do convite.
    
    **Não requer autenticação.**
    """
    
    try:
        invitation_service = PartnershipInvitationService(db)
        
        invitation = await invitation_service.get_invitation_by_token(token)
        
        if not invitation:
            raise HTTPException(
                status_code=404,
                detail="Convite não encontrado ou expirado"
            )
        
        # Retornar apenas dados seguros (sem dados sensíveis)
        safe_data = {
            "inviter_name": invitation["inviter_name"],
            "invitee_name": invitation["invitee_name"],
            "area_expertise": invitation["area_expertise"],
            "compatibility_score": invitation["compatibility_score"],
            "partnership_reason": invitation["partnership_reason"],
            "status": invitation["status"],
            "is_expired": invitation["is_expired"],
            "is_pending": invitation["is_pending"],
            "created_at": invitation["created_at"]
        }
        
        return safe_data
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Erro interno ao buscar convite: {str(e)}"
        )


@router.post("/public/{token}/accept",
             summary="✅ Aceitar Convite (Público)")
async def accept_invitation_public(
    token: str = Path(..., description="Token do convite"),
    request: AcceptInvitationRequest = None,
    db: AsyncSession = Depends(get_async_db)
):
    """
    ✅ **Aceitar Convite (Endpoint Público)**
    
    Aceita um convite de parceria após o usuário se cadastrar.
    
    **Fluxo:**
    1. Usuário clica no link do convite
    2. Usuário se cadastra na plataforma
    3. Sistema chama este endpoint com o novo lawyer_id
    4. Convite é marcado como aceito
    5. Convidador é notificado do sucesso
    
    **Não requer autenticação prévia.**
    """
    
    try:
        invitation_service = PartnershipInvitationService(db)
        
        new_lawyer_id = request.new_lawyer_id if request else None
        if not new_lawyer_id:
            raise HTTPException(
                status_code=400,
                detail="ID do novo advogado é obrigatório"
            )
        
        result = await invitation_service.accept_invitation(token, new_lawyer_id)
        
        if result["status"] not in ["accepted"]:
            raise HTTPException(
                status_code=400,
                detail=result["message"]
            )
        
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Erro interno ao aceitar convite: {str(e)}"
        ) 