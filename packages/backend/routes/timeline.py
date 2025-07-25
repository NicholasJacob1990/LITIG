"""
backend/routes/timeline.py

Rotas da API para a timeline de eventos do caso.
"""
from fastapi import APIRouter, Depends, HTTPException
from typing import List, Dict, Any
from uuid import UUID
from pydantic import BaseModel

from services.timeline_service import timeline_service
from auth import get_current_user

router = APIRouter(
    prefix="/cases/{case_id}/timeline",
    tags=["Timeline"],
    responses={404: {"description": "Not found"}},
)

# --- Schemas (Data Models) ---
class TimelineEventSchema(BaseModel):
    id: UUID
    event_type: str
    description: str
    created_at: str
    author: Dict[str, Any] | None

    class Config:
        orm_mode = True

# --- API Endpoints ---

@router.get("/", response_model=List[TimelineEventSchema])
async def get_case_timeline_route(
    case_id: UUID,
    current_user: dict = Depends(get_current_user)
):
    """
    Busca a timeline de eventos de um caso.
    """
    user_id = current_user.get("id")
    if not user_id:
        raise HTTPException(status_code=401, detail="Usuário não autenticado.")

    try:
        timeline_events = await timeline_service.get_case_timeline(case_id, user_id)
        return timeline_events
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e)) 