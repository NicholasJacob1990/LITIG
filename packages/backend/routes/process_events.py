"""
Rotas para gestão de eventos do processo judicial
"""
from datetime import datetime
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from ..auth import get_current_user
from ..services.process_event_service import ProcessEventService

router = APIRouter(prefix="/process-events", tags=["process-events"])

# ============================================================================
# DTOs
# ============================================================================


class CreateEventDTO(BaseModel):
    case_id: str = Field(..., description="ID do caso")
    event_date: datetime = Field(..., description="Data do evento")
    title: str = Field(..., description="Título do evento")
    description: Optional[str] = Field(None, description="Descrição do evento")
    document_url: Optional[str] = Field(None, description="URL do documento")


class UpdateEventDTO(BaseModel):
    event_date: Optional[datetime] = None
    title: Optional[str] = None
    description: Optional[str] = None
    document_url: Optional[str] = None


class EventResponse(BaseModel):
    id: str
    case_id: str
    event_date: datetime
    title: str
    description: Optional[str]
    document_url: Optional[str]
    created_at: datetime
    updated_at: datetime


class TimelineStatsResponse(BaseModel):
    total_events: int
    first_event: Optional[str]
    last_event: Optional[str]
    events_with_documents: int
    duration_days: int

# ============================================================================
# Rotas
# ============================================================================


@router.post("/", response_model=EventResponse)
async def create_event(
    event_data: CreateEventDTO,
    current_user: dict = Depends(get_current_user)
):
    """
    Criar novo evento do processo
    """
    try:
        event_service = ProcessEventService()

        event = await event_service.create_event(
            case_id=event_data.case_id,
            event_date=event_data.event_date,
            title=event_data.title,
            description=event_data.description,
            document_url=event_data.document_url
        )

        return EventResponse(**event)

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao criar evento: {str(e)}"
        )


@router.get("/{event_id}", response_model=EventResponse)
async def get_event(
    event_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Buscar evento por ID
    """
    try:
        event_service = ProcessEventService()
        event = await event_service.get_event(event_id)

        if not event:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Evento não encontrado"
            )

        return EventResponse(**event)

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao buscar evento: {str(e)}"
        )


@router.put("/{event_id}", response_model=EventResponse)
async def update_event(
    event_id: str,
    event_data: UpdateEventDTO,
    current_user: dict = Depends(get_current_user)
):
    """
    Atualizar evento
    """
    try:
        event_service = ProcessEventService()

        # Verificar se existe
        event = await event_service.get_event(event_id)
        if not event:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Evento não encontrado"
            )

        # Atualizar apenas campos fornecidos
        updates = event_data.dict(exclude_none=True)
        if updates:
            updated_event = await event_service.update_event(event_id, **updates)
            return EventResponse(**updated_event)

        return EventResponse(**event)

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao atualizar evento: {str(e)}"
        )


@router.delete("/{event_id}")
async def delete_event(
    event_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Remover evento
    """
    try:
        event_service = ProcessEventService()

        success = await event_service.delete_event(event_id)

        if success:
            return {"message": "Evento removido com sucesso"}
        else:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Erro ao remover evento"
            )

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao remover evento: {str(e)}"
        )


@router.get("/case/{case_id}", response_model=List[EventResponse])
async def get_case_events(
    case_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Listar todos os eventos de um caso
    """
    try:
        event_service = ProcessEventService()
        events = await event_service.get_case_events(case_id)

        return [EventResponse(**event) for event in events]

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao listar eventos: {str(e)}"
        )


@router.get("/case/{case_id}/preview", response_model=List[EventResponse])
async def get_case_events_preview(
    case_id: str,
    limit: int = 3,
    current_user: dict = Depends(get_current_user)
):
    """
    Buscar preview dos eventos de um caso (limitado)
    """
    try:
        event_service = ProcessEventService()
        events = await event_service.get_case_events_preview(case_id, limit)

        return [EventResponse(**event) for event in events]

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao buscar preview: {str(e)}"
        )


@router.get("/case/{case_id}/recent", response_model=List[EventResponse])
async def get_recent_events(
    case_id: str,
    days: int = 30,
    current_user: dict = Depends(get_current_user)
):
    """
    Buscar eventos recentes de um caso
    """
    try:
        event_service = ProcessEventService()
        events = await event_service.get_recent_events(case_id, days)

        return [EventResponse(**event) for event in events]

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao buscar eventos recentes: {str(e)}"
        )


@router.get("/case/{case_id}/stats", response_model=TimelineStatsResponse)
async def get_timeline_stats(
    case_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Obter estatísticas da linha do tempo
    """
    try:
        event_service = ProcessEventService()
        stats = await event_service.get_timeline_stats(case_id)

        return TimelineStatsResponse(**stats)

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao calcular estatísticas: {str(e)}"
        )
