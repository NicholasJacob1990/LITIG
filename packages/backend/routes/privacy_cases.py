"""
Rotas de API para Política de Privacidade Universal
==================================================

Implementa endpoints que respeitam a nova política corporativa:
"Qualquer caso – premium ou não – só expõe dados do cliente depois que o advogado/escritório clica em Aceitar."
"""

from typing import List, Optional, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status, Query
from pydantic import BaseModel, Field

from ..auth import get_current_user
from ..services.privacy_service import privacy_service

router = APIRouter(prefix="/api/privacy-cases", tags=["Privacy Cases"])


# Schemas de resposta
class CasePreviewOut(BaseModel):
    """Schema para preview de caso (dados não-sensíveis)"""
    id: str
    area: str
    subarea: str
    complexity: str
    urgency_h: int
    is_premium: bool
    valor_faixa: str
    created_at: str
    status: str
    location_city: Optional[str] = None
    location_state: Optional[str] = None
    documents_count: Optional[int] = 0
    # Note: Não inclui dados pessoais do cliente


class CaseFullOut(BaseModel):
    """Schema para caso completo (após aceite)"""
    id: str
    area: str
    subarea: str
    complexity: str
    urgency_h: int
    is_premium: bool
    valor_causa: Optional[float] = None
    created_at: str
    status: str
    # Dados do cliente (só após aceite)
    client_name: Optional[str] = None
    client_email: Optional[str] = None
    client_phone: Optional[str] = None
    client_cpf: Optional[str] = None
    client_cnpj: Optional[str] = None
    detailed_description: Optional[str] = None
    client_address: Optional[str] = None
    # Dados completos
    accepted_by: Optional[str] = None
    accepted_at: Optional[str] = None


class AcceptCaseRequest(BaseModel):
    """Schema para solicitação de aceite de caso"""
    case_id: str = Field(..., description="ID do caso a ser aceito")


class AcceptCaseResponse(BaseModel):
    """Schema para resposta de aceite de caso"""
    success: bool
    case_id: str
    accepted_by: str
    accepted_at: str
    message: str = "Caso aceito com sucesso. Dados do cliente agora estão visíveis."


@router.get("/discover", response_model=List[CasePreviewOut])
async def discover_cases(
    area: Optional[str] = Query(None, description="Filtrar por área jurídica"),
    subarea: Optional[str] = Query(None, description="Filtrar por subárea"),
    location_state: Optional[str] = Query(None, description="Filtrar por estado"),
    is_premium: Optional[bool] = Query(None, description="Filtrar apenas casos premium"),
    current_user = Depends(get_current_user)
):
    """
    Lista casos disponíveis para descoberta (matching).
    
    TODOS os casos retornam dados mascarados conforme nova política de privacidade,
    independentemente de serem premium ou não.
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
        
        # Buscar casos com mascaramento universal
        cases = await privacy_service.list_cases_for_discovery(
            user_id=current_user.get("id"),
            filters=filters
        )
        
        # Converter para schema de resposta
        preview_cases = []
        for case in cases:
            preview = CasePreviewOut(
                id=case["id"],
                area=case["area"],
                subarea=case["subarea"],
                complexity=case.get("complexity", "MEDIUM"),
                urgency_h=case["urgency_h"],
                is_premium=case.get("is_premium", False),
                valor_faixa=case.get("valor_faixa", "Não informado"),
                created_at=case["created_at"],
                status=case.get("status", "ABERTO"),
                location_city=case.get("location_city"),
                location_state=case.get("location_state"),
                documents_count=case.get("documents_count", 0)
            )
            preview_cases.append(preview)
        
        return preview_cases
        
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
    Aceita um caso, revelando os dados completos do cliente.
    
    Após aceitar, o advogado/escritório terá acesso completo aos dados pessoais
    do cliente para este caso específico.
    """
    try:
        user_id = current_user.get("id")
        user_role = current_user.get("role", "lawyer")
        
        # Verificar se pode aceitar o caso
        can_accept = await privacy_service.can_user_accept_case(
            case_id=request.case_id,
            user_id=user_id
        )
        
        if not can_accept:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Você não pode aceitar este caso. Ele pode já ter sido aceito por outro advogado ou não estar disponível."
            )
        
        # Realizar aceite
        result = await privacy_service.accept_case(
            case_id=request.case_id,
            lawyer_id=user_id
        )
        
        return AcceptCaseResponse(
            success=result["success"],
            case_id=result["case_id"],
            accepted_by=result["accepted_by"],
            accepted_at=result["accepted_at"]
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao aceitar caso: {str(e)}"
        )


@router.get("/{case_id}", response_model=CaseFullOut)
async def get_case_details(
    case_id: str,
    current_user = Depends(get_current_user)
):
    """
    Retorna detalhes de um caso específico.
    
    - Se o usuário não aceitou o caso: retorna dados mascarados (preview)
    - Se o usuário aceitou o caso: retorna dados completos do cliente
    - Se é admin: sempre retorna dados completos
    - Se é o próprio cliente: sempre retorna dados completos
    """
    try:
        user_id = current_user.get("id")
        user_role = current_user.get("role", "lawyer")
        
        # Buscar caso respeitando política de privacidade
        case_data = await privacy_service.get_case_for_user(
            case_id=case_id,
            user_id=user_id,
            user_role=user_role
        )
        
        # Converter para schema de resposta
        case_response = CaseFullOut(
            id=case_data["id"],
            area=case_data["area"],
            subarea=case_data["subarea"],
            complexity=case_data.get("complexity", "MEDIUM"),
            urgency_h=case_data["urgency_h"],
            is_premium=case_data.get("is_premium", False),
            valor_causa=case_data.get("valor_causa"),
            created_at=case_data["created_at"],
            status=case_data.get("status", "ABERTO"),
            client_name=case_data.get("client_name"),
            client_email=case_data.get("client_email"),
            client_phone=case_data.get("client_phone"),
            client_cpf=case_data.get("client_cpf"),
            client_cnpj=case_data.get("client_cnpj"),
            detailed_description=case_data.get("detailed_description"),
            client_address=case_data.get("client_address"),
            accepted_by=case_data.get("accepted_by"),
            accepted_at=case_data.get("accepted_at")
        )
        
        return case_response
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao buscar caso: {str(e)}"
        )


@router.get("/{case_id}/can-accept")
async def check_can_accept_case(
    case_id: str,
    current_user = Depends(get_current_user)
):
    """
    Verifica se o usuário atual pode aceitar um caso específico.
    
    Útil para mostrar/ocultar botão "Aceitar caso" na UI.
    """
    try:
        user_id = current_user.get("id")
        
        can_accept = await privacy_service.can_user_accept_case(
            case_id=case_id,
            user_id=user_id
        )
        
        return {
            "can_accept": can_accept,
            "case_id": case_id,
            "user_id": user_id
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao verificar permissão: {str(e)}"
        ) 