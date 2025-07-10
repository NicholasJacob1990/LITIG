"""
backend/routes/availability.py

Rotas da API para gestão de disponibilidade do advogado.
"""
from fastapi import APIRouter, Depends, HTTPException
from typing import Optional
from pydantic import BaseModel

from backend.services.availability_service import availability_service
from backend.auth import get_current_user

router = APIRouter(
    prefix="/availability",
    tags=["Availability"],
    responses={404: {"description": "Not found"}},
)

class AvailabilityUpdateSchema(BaseModel):
    is_available: bool
    reason: Optional[str] = None

@router.patch("/status", response_model=dict)
async def update_my_availability(
    update_data: AvailabilityUpdateSchema,
    current_user: dict = Depends(get_current_user)
):
    """
    Atualiza o status de disponibilidade do advogado logado.
    """
    user_id = current_user.get("id")
    if not user_id or current_user.get("user_metadata", {}).get("user_type") != "LAWYER":
        raise HTTPException(status_code=403, detail="Acesso negado.")

    try:
        await availability_service.update_lawyer_availability(
            lawyer_id=user_id,
            is_available=update_data.is_available,
            reason=update_data.reason
        )
        return {"status": "success", "is_available": update_data.is_available}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e)) 