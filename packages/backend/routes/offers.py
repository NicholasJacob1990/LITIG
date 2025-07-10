"""
backend/routes/offers.py

Rotas da API para funcionalidades de ofertas para advogados.
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from typing import List
from uuid import UUID
from pydantic import BaseModel

# Usando o serviço de ofertas correto e completo
from backend.services.offer_service import get_lawyer_offers, update_offer_status, Offer
from backend.auth import get_current_user
from backend.models import OfferStatusUpdate

router = APIRouter(
    prefix="/offers",
    tags=["Offers"],
    responses={404: {"description": "Not found"}},
)

# --- API Endpoints ---

@router.get("/", response_model=List[Offer])
async def get_my_offers(
    status: str = Query(None, enum=["pending", "interested", "declined", "expired"]),
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
    (Ex: de 'pending' para 'interested' ou 'declined')
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