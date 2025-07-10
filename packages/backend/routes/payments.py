"""
backend/routes/payments.py

Rotas da API para funcionalidades de pagamento.
"""
from fastapi import APIRouter, Depends, HTTPException
from typing import List
from uuid import UUID
from pydantic import BaseModel

from backend.services.payments_service import payments_service
from backend.auth import get_current_user

router = APIRouter(
    prefix="/payments",
    tags=["Payments"],
    responses={404: {"description": "Not found"}},
)

# --- Schemas (Data Models) ---
class InvoiceSchema(BaseModel):
    id: UUID
    status: str
    amount_cents: int
    description: str
    class Config:
        orm_mode = True

# --- API Endpoints ---

@router.get("/invoices", response_model=List[InvoiceSchema])
async def get_my_invoices(current_user: dict = Depends(get_current_user)):
    """
    Busca todas as faturas do usuário logado.
    """
    user_id = current_user.get("id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Usuário não autenticado.")

    try:
        invoices = await payments_service.get_invoices_by_user(user_id)
        return invoices
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e)) 