"""
Endpoints para contexto duplo de advogados contratantes
Permite que advogados contratantes atuem como clientes
"""

from fastapi import APIRouter, Depends, HTTPException, status
from typing import Dict, Any, Optional
import logging

from auth import get_current_user
from config import get_supabase_client
from services.dual_context_service import create_dual_context_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/dual-context", tags=["Dual Context"])

@router.post("/create-case-as-client")
async def create_case_as_client(
    case_data: Dict[str, Any],
    current_user: dict = Depends(get_current_user),
    supabase=Depends(get_supabase_client)
):
    """
    Cria caso com advogado contratante atuando como cliente
    
    Body:
    {
        "title": "Consultoria Jurídica",
        "description": "Preciso de consultoria para minha empresa",
        "category": "corporate",
        "urgency": "high",
        "estimated_value": 10000
    }
    """
    try:
        dual_context_service = create_dual_context_service(supabase)
        
        result = await dual_context_service.create_case_as_client(
            contractor_id=current_user["id"],
            case_data=case_data
        )
        
        return result
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Erro ao criar caso como cliente: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao criar caso"
        )

@router.post("/switch-context")
async def switch_context(
    context_data: Dict[str, Any],
    current_user: dict = Depends(get_current_user),
    supabase=Depends(get_supabase_client)
):
    """
    Alterna contexto do usuário
    
    Body:
    {
        "target_context": "client",
        "case_id": "optional-case-id"
    }
    """
    try:
        dual_context_service = create_dual_context_service(supabase)
        
        target_context = context_data.get("target_context")
        case_id = context_data.get("case_id")
        
        if not target_context:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="target_context é obrigatório"
            )
        
        result = await dual_context_service.switch_context(
            user_id=current_user["id"],
            target_context=target_context,
            case_id=case_id
        )
        
        return result
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Erro ao alternar contexto: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao alternar contexto"
        )

@router.get("/cases")
async def get_cases_by_context(
    context: str = "all",
    current_user: dict = Depends(get_current_user),
    supabase=Depends(get_supabase_client)
):
    """
    Busca casos por contexto
    
    Query params:
    - context: "client", "contractor", "all"
    """
    try:
        dual_context_service = create_dual_context_service(supabase)
        
        result = await dual_context_service.get_cases_by_context(
            user_id=current_user["id"],
            context=context
        )
        
        return result
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Erro ao buscar casos por contexto: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao buscar casos"
        )

@router.get("/navigation")
async def get_navigation_context(
    current_route: str,
    current_user: dict = Depends(get_current_user),
    supabase=Depends(get_supabase_client)
):
    """
    Obtém contexto de navegação para advogado contratante
    
    Query params:
    - current_route: Rota atual do usuário
    """
    try:
        dual_context_service = create_dual_context_service(supabase)
        
        result = await dual_context_service.get_navigation_context(
            user_id=current_user["id"],
            current_route=current_route
        )
        
        return result
        
    except Exception as e:
        logger.error(f"Erro ao obter contexto de navegação: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao obter contexto de navegação"
        )

@router.get("/available-contexts")
async def get_available_contexts(
    current_user: dict = Depends(get_current_user),
    supabase=Depends(get_supabase_client)
):
    """
    Retorna contextos disponíveis para o usuário
    """
    try:
        dual_context_service = create_dual_context_service(supabase)
        
        # Verificar se é um advogado contratante válido
        if not await dual_context_service._is_valid_contractor(current_user["id"]):
            return {
                "dual_context": False,
                "available_contexts": [],
                "message": "Usuário não é um advogado contratante válido"
            }
        
        available_contexts = await dual_context_service._get_available_contexts(current_user["id"])
        
        return {
            "dual_context": True,
            "available_contexts": available_contexts,
            "current_user_id": current_user["id"]
        }
        
    except Exception as e:
        logger.error(f"Erro ao obter contextos disponíveis: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao obter contextos disponíveis"
        )

@router.get("/context-stats")
async def get_context_stats(
    current_user: dict = Depends(get_current_user),
    supabase=Depends(get_supabase_client)
):
    """
    Retorna estatísticas dos contextos do usuário
    """
    try:
        dual_context_service = create_dual_context_service(supabase)
        
        # Verificar se é um advogado contratante válido
        if not await dual_context_service._is_valid_contractor(current_user["id"]):
            return {
                "dual_context": False,
                "client_stats": {},
                "contractor_stats": {}
            }
        
        client_stats = await dual_context_service._get_client_context_stats(current_user["id"])
        contractor_stats = await dual_context_service._get_contractor_context_stats(current_user["id"])
        
        return {
            "dual_context": True,
            "client_stats": client_stats,
            "contractor_stats": contractor_stats
        }
        
    except Exception as e:
        logger.error(f"Erro ao obter estatísticas de contexto: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao obter estatísticas de contexto"
        )

@router.post("/validate-dual-context")
async def validate_dual_context(
    current_user: dict = Depends(get_current_user),
    supabase=Depends(get_supabase_client)
):
    """
    Valida se o usuário pode usar contexto duplo
    """
    try:
        dual_context_service = create_dual_context_service(supabase)
        
        is_valid = await dual_context_service._is_valid_contractor(current_user["id"])
        
        if is_valid:
            return {
                "valid": True,
                "message": "Usuário pode usar contexto duplo",
                "user_id": current_user["id"]
            }
        else:
            return {
                "valid": False,
                "message": "Usuário não é um advogado contratante válido",
                "user_id": current_user["id"]
            }
        
    except Exception as e:
        logger.error(f"Erro ao validar contexto duplo: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao validar contexto duplo"
        ) 