"""
Rotas de API para Política de Privacidade Universal com Supabase
==============================================================

Implementa endpoints que usam RLS (Row Level Security) e views do Supabase
para garantir que dados do cliente só sejam expostos após aceite.
"""

from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from pydantic import BaseModel, Field

from ..auth import get_current_user
from ..services.supabase_privacy_service import supabase_privacy_service

router = APIRouter(prefix="/api/cases", tags=["Privacy Cases - Supabase"])


# Schemas
class CasePreviewResponse(BaseModel):
    """Schema para preview de caso (dados não-sensíveis)"""
    id: str
    area: str
    subarea: str
    complexity: str
    urgency_h: int
    is_premium: bool
    valor_faixa: str  # Faixa de valores, não valor exato
    status: str
    created_at: str
    has_client_data: int  # 1 se tem dados, 0 se não
    documents_count: int
    is_accepted: bool


class AcceptCaseRequest(BaseModel):
    """Schema para aceitar caso"""
    case_id: str = Field(..., description="ID do caso a ser aceito")


class AcceptCaseResponse(BaseModel):
    """Schema de resposta do aceite"""
    success: bool
    case_id: Optional[str] = None
    accepted_by: Optional[str] = None
    accepted_at: Optional[str] = None
    error: Optional[str] = None


@router.get("/preview", response_model=List[CasePreviewResponse])
async def list_cases_preview(
    area: Optional[str] = Query(None, description="Filtrar por área jurídica"),
    subarea: Optional[str] = Query(None, description="Filtrar por subárea"),
    is_premium: Optional[bool] = Query(None, description="Filtrar apenas casos premium"),
    location_state: Optional[str] = Query(None, description="Filtrar por estado"),
    current_user = Depends(get_current_user)
):
    """
    🔒 Lista casos disponíveis (PREVIEW) - Nova Política de Privacidade Universal
    
    **TODOS** os casos retornam apenas dados não-sensíveis:
    - ✅ Área, subárea, complexidade, urgência
    - ✅ Valor em FAIXA (não exato): "R$ 50-100 mil"
    - ✅ Localização GENÉRICA (cidade/estado)
    - ❌ Nome do cliente (mascarado)
    - ❌ Email, telefone, CPF/CNPJ (ocultos)
    - ❌ Valor exato da causa (protegido)
    - ❌ Documentos completos (só contagem)
    
    Para ver dados completos: aceite o caso com POST /accept
    """
    try:
        # Montar filtros
        filters = {}
        if area:
            filters["area"] = area
        if subarea:
            filters["subarea"] = subarea
        if is_premium is not None:
            filters["is_premium"] = is_premium
        if location_state:
            filters["location_state"] = location_state
        
        # Buscar usando view segura do Supabase
        cases = await supabase_privacy_service.list_cases_preview(filters)
        
        # Converter para schema de resposta
        return [
            CasePreviewResponse(
                id=case["id"],
                area=case["area"],
                subarea=case["subarea"],
                complexity=case.get("complexity", "MEDIUM"),
                urgency_h=case["urgency_h"],
                is_premium=case.get("is_premium", False),
                valor_faixa=case.get("valor_faixa", "Não informado"),
                status=case.get("status", "ABERTO"),
                created_at=case["created_at"],
                has_client_data=case.get("has_client_data", 0),
                documents_count=case.get("documents_count", 0),
                is_accepted=case.get("is_accepted", False)
            )
            for case in cases
        ]
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao buscar casos: {str(e)}"
        )


@router.post("/accept", response_model=AcceptCaseResponse)
async def accept_case(
    request: AcceptCaseRequest,
    current_user = Depends(get_current_user)
):
    """
    🔓 Aceita um caso, revelando dados completos do cliente
    
    **Após aceitar:**
    - ✅ Nome, email, telefone do cliente visíveis
    - ✅ Valor exato da causa disponível  
    - ✅ Documentos completos acessíveis
    - ✅ Endereço completo do cliente
    - 🔒 Outros advogados não podem mais aceitar
    - 📝 Ação é registrada na auditoria
    
    **Controle automático via Supabase RLS:**
    - Race condition protegida
    - Um caso = um advogado apenas
    - Logs de auditoria automáticos
    """
    try:
        # Verificar se pode aceitar antes de tentar
        can_accept = await supabase_privacy_service.can_accept_case(request.case_id)
        if not can_accept:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Caso não pode ser aceito. Pode já ter sido aceito por outro advogado."
            )
        
        # Aceitar usando RPC function do Supabase
        result = await supabase_privacy_service.accept_case(request.case_id)
        
        if result.get("success"):
            return AcceptCaseResponse(
                success=True,
                case_id=result.get("case_id"),
                accepted_by=result.get("accepted_by"),
                accepted_at=result.get("accepted_at")
            )
        else:
            return AcceptCaseResponse(
                success=False,
                error=result.get("error", "Erro desconhecido ao aceitar caso")
            )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro interno: {str(e)}"
        )


@router.get("/{case_id}")
async def get_case_details(
    case_id: str,
    current_user = Depends(get_current_user)
):
    """
    📋 Retorna detalhes de um caso específico
    
    **Comportamento baseado em permissões (RLS automático):**
    - 🔒 Se não aceitou: dados mascarados (mesmo que preview)
    - 🔓 Se aceitou: dados completos do cliente
    - 👮 Se é admin: sempre dados completos
    - 👤 Se é o cliente: sempre dados completos
    
    **Supabase RLS garante automaticamente que:**
    - Não há vazamento de dados por burla de API
    - Políticas são aplicadas no nível do banco
    - Zero configuração manual de permissões
    """
    try:
        # Tentar buscar dados completos (RLS controla automaticamente)
        full_case = await supabase_privacy_service.get_case_full_details(case_id)
        
        if full_case:
            # Usuário tem permissão - retornar dados completos
            return {
                "access_level": "full",
                "message": "Dados completos disponíveis - caso aceito",
                "case": full_case
            }
        else:
            # Sem permissão - buscar apenas preview
            preview_filters = {"id": case_id}  # Não é suportado pela view, então faz workaround
            previews = await supabase_privacy_service.list_cases_preview()
            case_preview = next((case for case in previews if case["id"] == case_id), None)
            
            if not case_preview:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Caso não encontrado"
                )
            
            return {
                "access_level": "preview",
                "message": "Apenas preview disponível - aceite o caso para ver dados completos",
                "case": case_preview
            }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao buscar caso: {str(e)}"
        )


@router.get("/{case_id}/can-accept")
async def check_can_accept(
    case_id: str,
    current_user = Depends(get_current_user)
):
    """
    ✅ Verifica se usuário pode aceitar um caso
    
    Útil para mostrar/ocultar botão "Aceitar" na UI.
    """
    try:
        can_accept = await supabase_privacy_service.can_accept_case(case_id)
        
        return {
            "can_accept": can_accept,
            "case_id": case_id,
            "user_id": current_user.get("id")
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao verificar permissão: {str(e)}"
        )


@router.get("/my/accepted")
async def get_my_accepted_cases(
    current_user = Depends(get_current_user)
):
    """
    📁 Lista casos aceitos pelo usuário atual
    
    Retorna casos onde o usuário tem acesso completo aos dados.
    """
    try:
        accepted_cases = await supabase_privacy_service.get_user_accepted_cases()
        
        return {
            "count": len(accepted_cases),
            "cases": accepted_cases
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao buscar casos aceitos: {str(e)}"
        )


@router.post("/{case_id}/abandon")
async def abandon_case(
    case_id: str,
    reason: Optional[str] = None,
    current_user = Depends(get_current_user)
):
    """
    🚪 Abandona um caso aceito
    
    **Efeitos:**
    - ❌ Usuário perde acesso aos dados do cliente
    - 🔄 Caso volta a estar disponível para outros
    - 📝 Abandono é registrado na auditoria
    - ⚠️ Ação pode afetar reputação do advogado
    """
    try:
        result = await supabase_privacy_service.abandon_case(case_id, reason)
        
        return result
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao abandonar caso: {str(e)}"
        )


@router.get("/{case_id}/documents")
async def list_case_documents(
    case_id: str,
    current_user = Depends(get_current_user)
):
    """
    📎 Lista documentos de um caso
    
    **Controle automático via Storage RLS:**
    - 🔒 Só retorna se usuário aceitou o caso
    - 📁 Lista arquivos do bucket case-files/{case_id}/
    - 🛡️ Política aplicada no nível do storage
    """
    try:
        documents = await supabase_privacy_service.get_case_documents(case_id)
        
        return {
            "case_id": case_id,
            "documents_count": len(documents),
            "documents": documents
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao listar documentos: {str(e)}"
        ) 