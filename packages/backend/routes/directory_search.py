"""
backend/routes/directory_search.py

Endpoint para busca direta no diretório com filtros avançados.
"""
import logging
from typing import List, Optional
from fastapi import APIRouter, Depends, Query, HTTPException

from ..services.directory_search_service import DirectorySearchService, DirectorySearchRequest
from ..api.schemas import MatchedLawyerSchema # Reutilizar schema de resposta

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/lawyers", tags=["Directory Search"])

@router.get("/directory-search", response_model=List[MatchedLawyerSchema])
async def directory_search(
    query: Optional[str] = Query(None, description="Texto de busca para nome ou especialidade"),
    min_rating: Optional[float] = Query(None, ge=0, le=5, description="Avaliação mínima"),
    min_price: Optional[float] = Query(None, ge=0, description="Preço mínimo por hora"),
    max_price: Optional[float] = Query(None, ge=0, description="Preço máximo por hora"),
    is_available: Optional[bool] = Query(None, description="Filtrar por disponibilidade"),
    limit: int = Query(20, ge=1, le=100),
    service: DirectorySearchService = Depends(DirectorySearchService)
):
    """
    Realiza uma busca direta no diretório de advogados e escritórios
    com base em filtros granulares.
    """
    try:
        request = DirectorySearchRequest(
            query=query,
            min_rating=min_rating,
            min_price=min_price,
            max_price=max_price,
            is_available=is_available,
            limit=limit,
        )
        results = await service.search(request)
        return results
    except Exception as e:
        logger.error(f"Erro na busca por diretório: {e}")
        raise HTTPException(
            status_code=500,
            detail="Ocorreu um erro ao processar a busca no diretório."
        ) 