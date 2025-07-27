"""
backend/routes/financials.py

Rotas da API para métricas financeiras dos advogados.
"""
from fastapi import APIRouter, Depends, HTTPException
from typing import Dict, Any

from services.financial_reports_service import financial_reports_service
from auth import get_current_user

router = APIRouter(
    prefix="/financials",
    tags=["Financials"],
    responses={404: {"description": "Not found"}},
)

@router.get("/dashboard", response_model=Dict[str, Any])
async def get_my_financial_dashboard(current_user: dict = Depends(get_current_user)):
    """
    Busca o dashboard financeiro do advogado logado.
    """
    user_id = current_user.get("id")
    # Validar se o perfil é de advogado (individual ou escritório)
    from ..schemas.user_types import normalize_entity_type, is_lawyer
    
    user_type = current_user.get("user_metadata", {}).get("user_type", "")
    normalized_type = normalize_entity_type(user_type)
    
    if not is_lawyer(normalized_type):
        raise HTTPException(status_code=403, detail="Acesso negado. Apenas para advogados.")

    if not user_id:
        raise HTTPException(status_code=401, detail="Usuário não autenticado.")

    try:
        financials = await financial_reports_service.get_lawyer_financials(user_id)
        return financials
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e)) 