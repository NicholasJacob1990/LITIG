"""
Rotas relacionadas a casos - usando CaseService ao invés de funções PostgreSQL
"""
import logging
from typing import Any, Dict, List

from fastapi import APIRouter, Depends, HTTPException, status

from ..auth import get_current_user
from ..config import get_supabase_client
from ..services.case_service import create_case_service
from ..services.match_service import process_client_choice
from pydantic import BaseModel
from uuid import UUID

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/cases", tags=["Cases"])


@router.get("/my-cases", response_model=List[Dict[str, Any]])
async def get_my_cases(
    current_user: dict = Depends(get_current_user),
    supabase=Depends(get_supabase_client)
):
    """
    Retorna todos os casos do usuário atual.

    Usa o CaseService ao invés da função PostgreSQL get_user_cases.
    Benefícios:
    - Cache automático
    - Lógica em Python (mais fácil de testar/debugar)
    - Performance melhorada
    """
    try:
        case_service = create_case_service(supabase)
        cases = await case_service.get_user_cases(current_user["id"])
        return cases

    except Exception as e:
        logger.error(f"Erro ao buscar casos do usuário: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao buscar casos"
        )


@router.get("/statistics", response_model=Dict[str, Any])
async def get_case_statistics(
    current_user: dict = Depends(get_current_user),
    supabase=Depends(get_supabase_client)
):
    """
    Retorna estatísticas agregadas dos casos do usuário.

    Substitui views materializadas do PostgreSQL por cálculos em Python.
    """
    try:
        case_service = create_case_service(supabase)
        stats = await case_service.get_case_statistics(current_user["id"])
        return stats

    except Exception as e:
        logger.error(f"Erro ao buscar estatísticas: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao buscar estatísticas"
        )


@router.patch("/{case_id}/status")
async def update_case_status(
    case_id: str,
    new_status: str,
    current_user: dict = Depends(get_current_user),
    supabase=Depends(get_supabase_client)
):
    """
    Atualiza o status de um caso.

    Validações que antes eram feitas por triggers PostgreSQL
    agora são feitas em Python (mais flexível e testável).
    """
    try:
        case_service = create_case_service(supabase)
        updated_case = await case_service.update_case_status(
            case_id,
            new_status,
            current_user["id"]
        )
        return updated_case

    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Erro ao atualizar status do caso: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao atualizar status"
        )


@router.get("/{case_id}", response_model=Dict[str, Any])
async def get_case_details(
    case_id: str,
    current_user: dict = Depends(get_current_user),
    supabase=Depends(get_supabase_client)
):
    """
    Retorna detalhes de um caso específico.

    Inclui validação de permissão e dados enriquecidos.
    """
    try:
        # Buscar o caso
        response = supabase.table("cases")\
            .select("*")\
            .eq("id", case_id)\
            .single()\
            .execute()

        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Caso não encontrado"
            )

        case = response.data

        # Verificar permissão
        if case["client_id"] != current_user["id"] and case.get(
                "lawyer_id") != current_user["id"]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Sem permissão para acessar este caso"
            )

        # Enriquecer dados
        case_service = create_case_service(supabase)
        user_role = "client" if case["client_id"] == current_user["id"] else "lawyer"
        enriched_case = await case_service._enrich_case_data(case, user_role)

        return enriched_case

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao buscar detalhes do caso: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao buscar detalhes do caso"
        )


"""
Rotas para gerenciamento de casos.
"""
router = APIRouter(
    prefix="/cases",
    tags=["Cases"],
    responses={404: {"description": "Not found"}},
)

# Modelos para requests
class ClientChoiceRequest(BaseModel):
    case_id: str
    chosen_lawyer_id: str
    choice_order: int = 1  # 1 = primeira escolha, 2 = segunda, etc.

@router.post("/{case_id}/choose-lawyer")
async def choose_lawyer_for_case(
    request: ClientChoiceRequest,
    current_user: dict = Depends(get_current_user)
):
    """
    Processa a escolha do cliente após o matching.
    Cria uma oferta para o advogado escolhido.
    """
    user_id = current_user.get("id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Usuário não autenticado.")

    try:
        # Verificar se o caso pertence ao usuário
        # TODO: Implementar verificação de ownership do caso
        
        result = await process_client_choice(
            case_id=request.case_id,
            chosen_lawyer_id=request.chosen_lawyer_id,
            choice_order=request.choice_order
        )
        
        return result
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
