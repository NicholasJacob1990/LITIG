"""
Rotas para obter recomendações (matches) persistidas.
"""
import os
from typing import List
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException

from backend.auth import get_current_user
from backend.models import (  # Reutilizar os modelos existentes
    MatchResponse,
    MatchResult,
)
from supabase import Client, create_client

# Configuração do Supabase
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

router = APIRouter()


@router.get("/cases/{case_id}/matches",
            response_model=MatchResponse, tags=["Recommendations"])
async def get_persisted_matches(
        case_id: UUID, current_user: dict = Depends(get_current_user)):
    """
    Busca os matches de advogados que foram previamente gerados e salvos
    para um caso específico.
    """
    try:
        # Primeiro, verificar se o caso pertence ao usuário logado
        case_response = supabase.table("cases").select(
            "id, user_id").eq("id", str(case_id)).single().execute()
        if case_response.data.get("user_id") != current_user["id"]:
            raise HTTPException(status_code=403, detail="Acesso negado a este caso.")

        # Buscar os matches salvos
        matches_response = supabase.table("case_matches").select(
            "*").eq("case_id", str(case_id)).order("fair_score", desc=True).execute()

        saved_matches = matches_response.data
        if not saved_matches:
            return MatchResponse(case_id=str(case_id), matches=[])

        # Formatar a resposta para o modelo MatchResult
        formatted_matches: List[MatchResult] = []
        for match in saved_matches:
            # Precisamos buscar os dados completos do advogado para preencher o card
            lawyer_data_response = supabase.table("lawyers").select(
                "*").eq("id", match["lawyer_id"]).single().execute()
            lawyer_data = lawyer_data_response.data or {}

            formatted_matches.append(
                MatchResult(
                    lawyer_id=match["lawyer_id"],
                    nome=lawyer_data.get("nome", "N/A"),
                    fair=match["fair_score"],
                    equity=match["equity_score"],
                    features=match["features"],
                    breakdown=match["breakdown"],
                    weights_used=match["weights_used"],
                    preset_used=match["preset_used"],
                    avatar_url=lawyer_data.get("avatar_url"),
                    is_available=lawyer_data.get("is_available", False),
                    primary_area=lawyer_data.get("primary_area", "N/A"),
                    rating=lawyer_data.get("rating"),
                    distance_km=0  # Este dado não está salvo, pode ser recalculado se necessário
                )
            )

        return MatchResponse(case_id=str(case_id), matches=formatted_matches)

    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        raise HTTPException(status_code=500,
                            detail=f"Erro ao buscar recomendações: {e}")
