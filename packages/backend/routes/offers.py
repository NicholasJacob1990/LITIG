"""
backend/routes/offers.py

Rotas da API para funcionalidades de ofertas para advogados.
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from typing import List, Optional
from uuid import UUID
from pydantic import BaseModel

# Importar serviços atualizados
from ..services.offer_service import (
    get_pending_offers, 
    accept_offer, 
    reject_offer, 
    get_lawyer_offer_statistics,
    get_lawyer_offers, 
    update_offer_status
)
from ..auth import get_current_user
from ..models import Offer, OfferStatusUpdate

router = APIRouter(
    prefix="/offers",
    tags=["Offers"],
    responses={404: {"description": "Not found"}},
)

# Modelos para requests
class AcceptOfferRequest(BaseModel):
    notes: Optional[str] = None

class RejectOfferRequest(BaseModel):
    reason: str

# --- API Endpoints ---

@router.get("/pending", response_model=List[Offer])
async def get_pending_offers_endpoint(
    current_user: dict = Depends(get_current_user)
):
    """
    Busca ofertas pendentes do advogado logado.
    """
    user_id = current_user.get("id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Usuário não autenticado.")

    try:
        offers = await get_pending_offers(user_id)
        return offers
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.patch("/{offer_id}/accept")
async def accept_offer_endpoint(
    offer_id: UUID,
    request: AcceptOfferRequest,
    current_user: dict = Depends(get_current_user)
):
    """
    Aceita uma oferta de caso.
    """
    user_id = current_user.get("id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Usuário não autenticado.")

    try:
        result = await accept_offer(offer_id, user_id, request.notes)
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.patch("/{offer_id}/reject")
async def reject_offer_endpoint(
    offer_id: UUID,
    request: RejectOfferRequest,
    current_user: dict = Depends(get_current_user)
):
    """
    Rejeita uma oferta de caso.
    """
    user_id = current_user.get("id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Usuário não autenticado.")

    try:
        result = await reject_offer(offer_id, user_id, request.reason)
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/stats")
async def get_offer_stats_endpoint(
    current_user: dict = Depends(get_current_user)
):
    """
    Estatísticas de ofertas do advogado logado.
    """
    user_id = current_user.get("id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Usuário não autenticado.")

    try:
        stats = await get_lawyer_offer_statistics(user_id)
        return stats
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/history", response_model=List[Offer])
async def get_offer_history_endpoint(
    status: Optional[str] = Query(None, enum=["accepted", "rejected", "declined", "expired"]),
    limit: int = Query(20, ge=1, le=100),
    current_user: dict = Depends(get_current_user)
):
    """
    Histórico de ofertas (aceitas, rejeitadas, expiradas).
    """
    user_id = current_user.get("id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Usuário não autenticado.")

    try:
        offers = await get_lawyer_offers(user_id, status)
        # Limitar resultados
        return offers[:limit]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/", response_model=List[Offer])
async def get_my_offers(
    status: str = Query(None, enum=["pending", "interested", "accepted", "declined", "rejected", "expired"]),
    current_user: dict = Depends(get_current_user)
):
    """
    Busca as ofertas do advogado logado, opcionalmente filtradas por status.
    """
    user_id = current_user.get("id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Usuário não autenticado.")

    try:
        offers = await get_lawyer_offers(user_id, status)
        return offers
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.patch("/{offer_id}/status", response_model=Offer)
async def update_my_offer_status_route(
    offer_id: UUID,
    update_data: OfferStatusUpdate,
    current_user: dict = Depends(get_current_user)
):
    """
    Permite que um advogado atualize o status de uma de suas ofertas.
    (Ex: de 'pending' para 'interested' ou 'declined') - COMPATIBILIDADE
    """
    user_id = current_user.get("id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Usuário não autenticado.")

    try:
        updated_offer = await update_offer_status(offer_id, update_data, user_id)
        if not updated_offer:
            raise HTTPException(status_code=404, detail="Oferta não encontrada ou não pertence a você.")
        return updated_offer
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e)) 