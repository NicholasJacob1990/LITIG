# packages/backend/api/routes/firm_routes.py

from fastapi import APIRouter, HTTPException, Depends, Body
from typing import List, Dict, Any

from ...services.firm_profile_service import firm_profile_service
from pydantic import BaseModel, Field

router = APIRouter()

class SemanticSearchRequest(BaseModel):
    query: str = Field(..., min_length=10, description="Texto de busca em linguagem natural para encontrar escritórios.")
    top_k: int = Field(10, gt=0, le=50, description="Número de resultados a serem retornados.")

@router.post(
    "/firms/semantic-search",
    response_model=List[Dict[str, Any]],
    tags=["Firms", "B2B"],
    summary="Busca Semântica de Escritórios de Advocacia",
    description="Realiza uma busca por escritórios de advocacia com base na similaridade semântica de uma consulta em linguagem natural."
)
async def semantic_firm_search(
    request: SemanticSearchRequest = Body(...)
):
    """
    Este endpoint recebe uma consulta textual e retorna uma lista de escritórios
    cujos perfis semânticos são mais relevantes para a consulta.

    - **query**: O texto para a busca (ex: "escritório especialista em fusões e aquisições de startups de tecnologia").
    - **top_k**: O número máximo de escritórios a serem retornados.
    """
    try:
        similar_firms = await firm_profile_service.find_similar_firms(
            text_query=request.query,
            top_k=request.top_k
        )
        if not similar_firms:
            raise HTTPException(
                status_code=404,
                detail="Nenhum escritório compatível encontrado para a sua busca."
            )
        return similar_firms
    except Exception as e:
        # Log do erro no servidor para depuração
        print(f"Erro interno durante a busca semântica de escritórios: {e}")
        raise HTTPException(
            status_code=500,
            detail="Ocorreu um erro inesperado ao processar sua busca."
        ) 
 