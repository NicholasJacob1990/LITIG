"""
Rotas para casos contextuais - implementa o sistema de Contextual Case View
Conforme especificado em ARQUITETURA_GERAL_DO_SISTEMA.md
"""

from fastapi import APIRouter, Depends, HTTPException, status
from typing import Dict, Any, List
import logging

from ..auth import get_current_user
from ..config import get_supabase_client
from ..services.contextual_case_service import create_contextual_case_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/contextual-cases", tags=["Contextual Cases"])

@router.get("/{case_id}")
async def get_contextual_case(
    case_id: str,
    current_user: dict = Depends(get_current_user),
    supabase=Depends(get_supabase_client)
):
    """
    Retorna dados contextuais completos de um caso
    
    Inclui:
    - Dados básicos do caso
    - KPIs específicos por contexto
    - Ações contextuais
    - Destaque contextual
    - Metadados específicos por tipo de alocação
    """
    try:
        contextual_service = create_contextual_case_service(supabase)
        
        contextual_data = await contextual_service.get_contextual_case_data(
            case_id=case_id,
            user_id=current_user["id"]
        )
        
        return contextual_data
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Erro ao buscar dados contextuais do caso {case_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao buscar dados contextuais"
        )

@router.get("/{case_id}/kpis")
async def get_case_kpis(
    case_id: str,
    current_user: dict = Depends(get_current_user),
    supabase=Depends(get_supabase_client)
):
    """
    Retorna apenas os KPIs contextuais de um caso
    """
    try:
        contextual_service = create_contextual_case_service(supabase)
        
        contextual_data = await contextual_service.get_contextual_case_data(
            case_id=case_id,
            user_id=current_user["id"]
        )
        
        return {
            "allocation_type": contextual_data["contextual_data"]["allocation_type"],
            "kpis": contextual_data["kpis"]
        }
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Erro ao buscar KPIs do caso {case_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao buscar KPIs contextuais"
        )

@router.get("/{case_id}/actions")
async def get_case_actions(
    case_id: str,
    current_user: dict = Depends(get_current_user),
    supabase=Depends(get_supabase_client)
):
    """
    Retorna ações contextuais disponíveis para um caso
    """
    try:
        contextual_service = create_contextual_case_service(supabase)
        
        contextual_data = await contextual_service.get_contextual_case_data(
            case_id=case_id,
            user_id=current_user["id"]
        )
        
        return contextual_data["actions"]
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Erro ao buscar ações do caso {case_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao buscar ações contextuais"
        )

@router.post("/{case_id}/allocation")
async def set_case_allocation(
    case_id: str,
    allocation_data: Dict[str, Any],
    current_user: dict = Depends(get_current_user),
    supabase=Depends(get_supabase_client)
):
    """
    Define o tipo de alocação e metadados de um caso
    
    Body:
    {
        "allocation_type": "platform_match_direct",
        "metadata": {
            "match_score": 95,
            "distance": 12.5,
            "estimated_value": 8500,
            "response_deadline": "2025-01-31T18:00:00Z"
        }
    }
    """
    try:
        contextual_service = create_contextual_case_service(supabase)
        
        # Validar dados obrigatórios
        if "allocation_type" not in allocation_data:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="allocation_type é obrigatório"
            )
        
        allocation_type = allocation_data["allocation_type"]
        metadata = allocation_data.get("metadata", {})
        
        # Validar allocation_type
        valid_types = [
            "platform_match_direct",
            "platform_match_partnership", 
            "partnership_proactive_search",
            "partnership_platform_suggestion",
            "internal_delegation"
        ]
        
        if allocation_type not in valid_types:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"allocation_type deve ser um de: {valid_types}"
            )
        
        updated_case = await contextual_service.set_case_allocation(
            case_id=case_id,
            allocation_type=allocation_type,
            metadata=metadata
        )
        
        return {
            "success": True,
            "case_id": case_id,
            "allocation_type": allocation_type,
            "updated_case": updated_case
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao definir alocação do caso {case_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao definir alocação do caso"
        )

@router.get("/user/cases-by-allocation")
async def get_cases_by_allocation(
    current_user: dict = Depends(get_current_user),
    supabase=Depends(get_supabase_client)
):
    """
    Retorna casos do usuário agrupados por tipo de alocação
    """
    try:
        # Buscar casos do usuário
        response = supabase.table("cases")\
            .select("*")\
            .or_(f"client_id.eq.{current_user['id']},lawyer_id.eq.{current_user['id']},partner_id.eq.{current_user['id']},delegated_by.eq.{current_user['id']}")\
            .execute()
        
        cases = response.data or []
        
        # Agrupar por tipo de alocação
        cases_by_allocation = {}
        contextual_service = create_contextual_case_service(supabase)
        
        for case in cases:
            allocation_type = case.get("allocation_type", "platform_match_direct")
            
            if allocation_type not in cases_by_allocation:
                cases_by_allocation[allocation_type] = []
            
            # Adicionar dados contextuais básicos
            contextual_data = await contextual_service.get_contextual_case_data(
                case_id=case["id"],
                user_id=current_user["id"]
            )
            
            cases_by_allocation[allocation_type].append({
                "id": case["id"],
                "status": case["status"],
                "created_at": case["created_at"],
                "allocation_type": allocation_type,
                "kpis": contextual_data["kpis"],
                "highlight": contextual_data["highlight"]
            })
        
        return cases_by_allocation
        
    except Exception as e:
        logger.error(f"Erro ao buscar casos por alocação: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao buscar casos por alocação"
        ) 