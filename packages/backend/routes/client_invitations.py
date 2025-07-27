"""
Client Invitations Routes

Endpoints para o sistema de convites de clientes para advogados externos.
Implementa o motor de aquisição viral da LITIG.
"""

import logging
from typing import Dict, Any, Optional
from datetime import datetime

from fastapi import APIRouter, HTTPException, Depends, BackgroundTasks, status
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

# Dependências internas
from dependencies.auth import get_current_user
from services.client_invitation_service import ClientInvitationService, InvitationResult
from api.schemas import BaseResponseSchema, ErrorResponseSchema

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/v1/invites", tags=["Client Invitations"])

# ============================================================================
# Schemas
# ============================================================================

class ClientRequestSchema(BaseModel):
    """Schema para solicitação de contato de cliente."""
    target_profile: Dict[str, Any] = Field(..., description="Dados do perfil externo")
    case_info: Dict[str, Any] = Field(..., description="Informações do caso")
    client_info: Dict[str, Any] = Field(..., description="Informações do cliente")

class InvitationResponseSchema(BaseModel):
    """Schema para resposta de tentativa de convite."""
    success: bool = Field(..., description="Se a operação foi bem-sucedida")
    status: str = Field(..., description="Status da tentativa")
    channel: str = Field(..., description="Canal utilizado")
    message: Optional[str] = Field(None, description="Mensagem informativa")
    linkedin_url: Optional[str] = Field(None, description="URL do LinkedIn (se fallback)")
    linkedin_message: Optional[str] = Field(None, description="Mensagem para LinkedIn")
    invitation_id: Optional[str] = Field(None, description="ID do convite criado")

class ClaimProfileSchema(BaseModel):
    """Schema para reivindicação de perfil."""
    lawyer_name: str = Field(..., description="Nome completo do advogado")
    oab_number: str = Field(..., description="Número da OAB")
    oab_state: str = Field(..., description="Estado da OAB")
    email: str = Field(..., description="E-mail profissional")
    phone: str = Field(..., description="Telefone de contato")
    specializations: list[str] = Field(default_factory=list, description="Especializações")
    accepts_case: bool = Field(True, description="Aceita o caso original")

class ClaimResponseSchema(BaseModel):
    """Schema para resposta de reivindicação."""
    success: bool = Field(..., description="Se a reivindicação foi processada")
    message: str = Field(..., description="Mensagem de resultado")
    lawyer_id: Optional[str] = Field(None, description="ID do advogado criado")
    case_id: Optional[str] = Field(None, description="ID do caso associado")

# ============================================================================
# Endpoints
# ============================================================================

@router.post("/client-request", 
             response_model=InvitationResponseSchema,
             responses={
                 400: {"model": ErrorResponseSchema},
                 401: {"model": ErrorResponseSchema},
                 500: {"model": ErrorResponseSchema}
             },
             summary="Solicitar contato com advogado externo",
             description="Inicia processo de convite para advogado não cadastrado com fallbacks automáticos")
async def request_contact_with_external_lawyer(
    request: ClientRequestSchema,
    background_tasks: BackgroundTasks,
    current_user: Any = Depends(get_current_user),
    # db: AsyncSession = Depends(get_db_session)  # TODO: Adicionar quando DB estiver configurado
):
    """
    Endpoint principal para solicitar contato com advogado externo.
    
    Fluxo:
    1. Valida dados do perfil externo
    2. Cria convite pendente
    3. Tenta envio por e-mail (canal primário)
    4. Se falhar, oferece fallback LinkedIn
    5. Se não tiver contato, orienta para verificados
    """
    try:
        # Validar dados mínimos
        target_profile = request.target_profile
        if not target_profile.get('name'):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Nome do advogado é obrigatório"
            )
        
        case_info = request.case_info
        if not case_info.get('area'):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Área jurídica do caso é obrigatória"
            )
        
        # Enriquecer informações do cliente com dados do usuário atual
        client_info = request.client_info.copy()
        client_info.update({
            'id': current_user.get('id'),
            'name': current_user.get('name'),
            'email': current_user.get('email'),
            'type': current_user.get('user_type', 'PF')
        })
        
        # Inicializar serviço de convites
        invitation_service = ClientInvitationService()
        
        # Tentar enviar convite
        result = await invitation_service.send_client_lead_notification(
            target_profile=target_profile,
            case_info=case_info,
            client_info=client_info
        )
        
        # Converter resultado para schema de resposta
        response = InvitationResponseSchema(
            success=result.status in ['success', 'fallback'],
            status=result.status,
            channel=result.channel,
            message=result.message,
            linkedin_url=result.linkedin_url,
            linkedin_message=result.linkedin_message,
            invitation_id=result.invitation_id
        )
        
        # Log da operação
        logger.info("Solicitação de contato processada", {
            "client_id": client_info['id'],
            "target_name": target_profile['name'],
            "result_status": result.status,
            "result_channel": result.channel
        })
        
        return response
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao processar solicitação de contato: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro interno ao processar solicitação"
        )

@router.get("/{token}/claim",
            summary="Landing page para reivindicação de perfil",
            description="Endpoint para advogados acessarem via link do e-mail")
async def get_claim_profile_info(token: str):
    """
    Endpoint para mostrar informações do convite antes da reivindicação.
    
    Retorna dados do caso e formulário para o advogado preencher.
    """
    try:
        invitation_service = ClientInvitationService()
        invitation = await invitation_service.get_invitation_by_token(token)
        
        if not invitation:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Convite não encontrado ou expirado"
            )
        
        if invitation.expires_at < datetime.utcnow():
            raise HTTPException(
                status_code=status.HTTP_410_GONE,
                detail="Este convite expirou"
            )
        
        return {
            "invitation_id": invitation.id,
            "target_name": invitation.target_name,
            "case_summary": invitation.case_summary,
            "expires_at": invitation.expires_at.isoformat(),
            "status": invitation.status
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao buscar informações do convite: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao processar convite"
        )

@router.post("/{token}/accept",
             response_model=ClaimResponseSchema,
             responses={
                 400: {"model": ErrorResponseSchema},
                 404: {"model": ErrorResponseSchema},
                 410: {"model": ErrorResponseSchema},
                 500: {"model": ErrorResponseSchema}
             },
             summary="Aceitar convite e criar perfil",
             description="Processa reivindicação de perfil e criação de conta de advogado")
async def accept_invitation_and_create_profile(
    token: str,
    claim_data: ClaimProfileSchema,
    background_tasks: BackgroundTasks,
    # db: AsyncSession = Depends(get_db_session)  # TODO: Adicionar quando DB estiver configurado
):
    """
    Endpoint para advogados aceitarem convite e criarem perfil.
    
    Fluxo:
    1. Valida token e dados do advogado
    2. Cria perfil na plataforma
    3. Associa com caso original (se aceito)
    4. Notifica cliente sobre aceitação
    5. Envia e-mail de boas-vindas
    """
    try:
        invitation_service = ClientInvitationService()
        
        # Converter dados do schema para dict
        lawyer_data = {
            'name': claim_data.lawyer_name,
            'oab_number': claim_data.oab_number,
            'oab_state': claim_data.oab_state,
            'email': claim_data.email,
            'phone': claim_data.phone,
            'specializations': claim_data.specializations,
            'accepts_case': claim_data.accepts_case
        }
        
        # Processar aceitação
        success = await invitation_service.accept_invitation(token, lawyer_data)
        
        if not success:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Não foi possível processar a reivindicação"
            )
        
        # TODO: Implementar criação real do perfil quando DB estiver pronto
        mock_lawyer_id = "lawyer_" + token[:8]
        mock_case_id = "case_" + token[8:16] if claim_data.accepts_case else None
        
        response = ClaimResponseSchema(
            success=True,
            message="Perfil criado com sucesso! Bem-vindo à LITIG.",
            lawyer_id=mock_lawyer_id,
            case_id=mock_case_id
        )
        
        # Background task para notificações
        background_tasks.add_task(
            _send_welcome_notifications,
            lawyer_data,
            mock_lawyer_id,
            claim_data.accepts_case
        )
        
        logger.info("Convite aceito e perfil criado", {
            "token": token[:8] + "...",  # Log parcial por segurança
            "lawyer_name": claim_data.lawyer_name,
            "accepts_case": claim_data.accepts_case
        })
        
        return response
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao processar aceitação de convite: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro interno ao processar reivindicação"
        )

@router.get("/analytics",
            summary="Analytics de convites",
            description="Métricas de performance do sistema de convites")
async def get_invitation_analytics(
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    current_user: Any = Depends(get_current_user)
):
    """
    Endpoint para obter analytics do sistema de convites.
    
    Restrito a usuários admin.
    """
    # TODO: Implementar verificação de permissão admin
    
    try:
        invitation_service = ClientInvitationService()
        
        # Parse das datas (com fallbacks)
        if start_date:
            start_dt = datetime.fromisoformat(start_date)
        else:
            start_dt = datetime.utcnow().replace(day=1)  # Início do mês
        
        if end_date:
            end_dt = datetime.fromisoformat(end_date)
        else:
            end_dt = datetime.utcnow()
        
        analytics = await invitation_service.get_invitation_analytics(start_dt, end_dt)
        
        return {
            "period": {
                "start_date": start_dt.isoformat(),
                "end_date": end_dt.isoformat()
            },
            "metrics": analytics
        }
        
    except Exception as e:
        logger.error(f"Erro ao obter analytics: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao obter métricas"
        )

# ============================================================================
# Background Tasks
# ============================================================================

async def _send_welcome_notifications(lawyer_data: Dict[str, Any], 
                                     lawyer_id: str, 
                                     accepts_case: bool):
    """Background task para enviar notificações de boas-vindas."""
    try:
        # TODO: Implementar envio de e-mail de boas-vindas
        # TODO: Notificar cliente se advogado aceitou o caso
        logger.info("Notificações de boas-vindas enviadas", {
            "lawyer_id": lawyer_id,
            "accepts_case": accepts_case
        })
    except Exception as e:
        logger.error(f"Erro ao enviar notificações: {e}") 