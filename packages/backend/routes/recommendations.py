"""
Rotas para obter recomendações (matches) persistidas.
"""
import os
from typing import List
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException

from auth import get_current_user
from models import (  # Reutilizar os modelos existentes
    MatchRequest,
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
        
@router.get("/cases/{case_id}/enhanced-matches", 
            tags=["Recommendations", "LLM Enhanced"])
async def get_enhanced_matches(
        case_id: UUID, 
        enable_explanations: bool = True,
        current_user: dict = Depends(get_current_user)):
    """
    🤖 NOVO: Endpoint para matching aprimorado com LLMs
    
    Combina algoritmo tradicional com análises LLM para:
    - Análise contextual de casos
    - Análise de perfis de advogados  
    - Scores de compatibilidade inteligentes
    - Explicações detalhadas dos matches
    """
    
    # Verificar se LLM enhanced está habilitado
    llm_enabled = os.getenv("ENABLE_LLM_MATCHING", "false").lower() == "true"
    
    if not llm_enabled:
        # Fallback para matching tradicional
        return await get_persisted_matches(case_id, current_user)
    
    try:
        from ..services.enhanced_match_service import EnhancedMatchService
        
        # Carregar dados do caso
        case_data = await load_case_data(case_id)
        
        if not case_data:
            raise HTTPException(status_code=404, detail="Caso não encontrado")
        
        # Usar serviço aprimorado
        enhanced_service = EnhancedMatchService()
        enhanced_matches = await enhanced_service.find_enhanced_matches(
            case_data=case_data,
            top_n=10,
            enable_explanations=enable_explanations
        )
        
        # Formatar resposta
        return {
            "case_id": case_id,
            "algorithm_version": "hybrid_llm_v1.0",
            "llm_enhanced": True,
            "total_matches": len(enhanced_matches),
            "matches": [
                {
                    "lawyer_id": match.lawyer_id,
                    "traditional_score": match.traditional_score,
                    "llm_compatibility_score": match.llm_compatibility_score,
                    "combined_score": match.combined_score,
                    "match_reasoning": match.match_reasoning,
                    "confidence_level": match.confidence_level,
                    "insights": match.insights
                }
                for match in enhanced_matches
            ],
            "processing_info": {
                "traditional_weight": 0.6,
                "llm_weight": 0.4,
                "llm_candidates_analyzed": min(len(enhanced_matches), 15)
            }
        }
        
    except Exception as e:
        print(f"Erro no matching aprimorado: {e}")
        # Fallback gracioso para matching tradicional
        print("Usando fallback para matching tradicional")
        return await get_persisted_matches(case_id, current_user)
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

