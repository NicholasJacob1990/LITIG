from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime
import json

from backend.services.unipile_app_service import get_unipile_app_service
# Supondo que você tenha um helper para obter o usuário e a conta principal
from backend.auth import get_current_user 
from backend.models.user import User
from backend.database import get_user_primary_social_account # Esta função precisa ser criada

router = APIRouter(prefix="/api/v1/calendar", tags=["calendar"])

# Pydantic Models
class CalendarEventParticipant(BaseModel):
    email: str
    name: Optional[str] = None

class CalendarEventRequest(BaseModel):
    title: str
    start_time: str = Field(..., description="ISO 8601 format: YYYY-MM-DDTHH:MM:SSZ")
    end_time: str = Field(..., description="ISO 8601 format: YYYY-MM-DDTHH:MM:SSZ")
    participants: Optional[List[CalendarEventParticipant]] = []
    description: Optional[str] = None
    location: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None

class LegalEventRequest(CalendarEventRequest):
    case_id: str
    case_type: str
    event_category: str # 'audiencia', 'consulta', 'prazo'

# --- Funções Auxiliares (Simuladas) ---

async def get_user_primary_calendar_account(user_id: str) -> Optional[Dict[str, Any]]:
    """
    Função auxiliar para buscar a conta de calendário primária do usuário no DB.
    Na implementação real, isso buscaria na tabela `user_social_accounts`.
    Por agora, vamos simular, assumindo que a conta de email principal também é a do calendário.
    """
    # Exemplo: Chamar uma função que busca no banco de dados.
    # return await get_user_primary_social_account(user_id, provider='google')
    # Mock por enquanto:
    return {"account_id": "acc_mock_calendar_12345", "provider": "gmail"}

# --- Endpoints da API ---

@router.get("/events", response_model=Dict)
async def get_events(
    start_date: str = Query(..., description="Start date in YYYY-MM-DD format"), 
    end_date: str = Query(..., description="End date in YYYY-MM-DD format"),
    current_user: User = Depends(get_current_user)
):
    """Busca eventos do calendário unificado do usuário."""
    unipile_service = get_unipile_app_service()
    account = await get_user_primary_calendar_account(current_user.id)
    
    if not account or not account.get("account_id"):
        raise HTTPException(status_code=404, detail="Nenhuma conta de calendário conectada ou encontrada.")
    
    # O SDK do Unipile espera um ID de calendário, não um ID de conta para listar eventos.
    # Primeiro, listamos os calendários da conta.
    calendars_result = await unipile_service.list_calendars(account["account_id"])
    if not calendars_result or not calendars_result.get("success"):
        raise HTTPException(status_code=500, detail="Falha ao listar calendários da conta.")

    calendars = calendars_result.get("data", [])
    primary_calendar = next((cal for cal in calendars if cal.get("primary")), calendars[0] if calendars else None)

    if not primary_calendar:
         raise HTTPException(status_code=404, detail="Nenhum calendário primário encontrado para esta conta.")

    calendar_id = primary_calendar.get("id")
    options = {"start_date": start_date, "end_date": end_date}
    
    events_result = await unipile_service.list_calendar_events(calendar_id, options)
    
    if events_result and events_result.get("success"):
        return {"success": True, "events": events_result.get("data", [])}
    
    error_detail = events_result.get("error") if events_result else "Erro desconhecido."
    raise HTTPException(status_code=500, detail=f"Falha ao buscar eventos do calendário: {error_detail}")

@router.post("/events", response_model=Dict)
async def create_event(
    request: CalendarEventRequest,
    current_user: User = Depends(get_current_user)
):
    """Cria um novo evento genérico no calendário do usuário."""
    unipile_service = get_unipile_app_service()
    account = await get_user_primary_calendar_account(current_user.id)
    if not account:
        raise HTTPException(status_code=404, detail="Nenhuma conta de calendário conectada.")

    calendars_result = await unipile_service.list_calendars(account["account_id"])
    if not calendars_result or not calendars_result.get("success"):
        raise HTTPException(status_code=500, detail="Falha ao listar calendários da conta.")

    calendars = calendars_result.get("data", [])
    primary_calendar = next((cal for cal in calendars if cal.get("primary")), calendars[0] if calendars else None)
    
    if not primary_calendar:
         raise HTTPException(status_code=404, detail="Nenhum calendário primário encontrado para esta conta.")

    calendar_id = primary_calendar.get("id")
    
    event_result = await unipile_service.create_calendar_event(calendar_id, request.dict())
    
    if event_result and event_result.get("success"):
        return {"success": True, "message": "Evento criado com sucesso", "event": event_result.get("data")}
    
    error_detail = event_result.get("error") if event_result else "Erro desconhecido."
    raise HTTPException(status_code=500, detail=f"Falha ao criar evento: {error_detail}")

@router.post("/legal-event", response_model=Dict)
async def create_legal_event(
    request: LegalEventRequest,
    current_user: User = Depends(get_current_user)
):
    """Cria um evento jurídico específico (audiência, consulta, prazo) no calendário."""
    unipile_service = get_unipile_app_service()
    account = await get_user_primary_calendar_account(current_user.id)
    if not account:
        raise HTTPException(status_code=404, detail="Nenhuma conta de calendário conectada.")
    
    calendars_result = await unipile_service.list_calendars(account["account_id"])
    if not calendars_result or not calendars_result.get("success"):
        raise HTTPException(status_code=500, detail="Falha ao listar calendários da conta.")

    calendars = calendars_result.get("data", [])
    primary_calendar = next((cal for cal in calendars if cal.get("primary")), calendars[0] if calendars else None)

    if not primary_calendar:
         raise HTTPException(status_code=404, detail="Nenhum calendário primário encontrado para esta conta.")
    
    calendar_id = primary_calendar.get("id")
    
    # Usar o método específico do wrapper para eventos legais
    event_result = await unipile_service.create_legal_event(calendar_id, request.dict())

    if event_result and event_result.get("success"):
        return {"success": True, "message": f"Evento '{request.event_category}' criado com sucesso.", "event": event_result.get("data")}
        
    error_detail = event_result.get("error") if event_result else "Erro desconhecido."
    raise HTTPException(status_code=500, detail=f"Falha ao criar evento jurídico: {error_detail}") 