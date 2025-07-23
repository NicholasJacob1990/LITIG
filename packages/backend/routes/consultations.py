"""
Rotas para gestão de consultas jurídicas
"""
from datetime import datetime
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from auth import get_current_user
from services.consultation_service import ConsultationService

router = APIRouter(prefix="/consultations", tags=["consultations"])

# ============================================================================
# DTOs
# ============================================================================


class CreateConsultationDTO(BaseModel):
    case_id: str = Field(..., description="ID do caso")
    lawyer_id: str = Field(..., description="ID do advogado")
    scheduled_at: datetime = Field(..., description="Data e hora agendada")
    duration_minutes: int = Field(45, description="Duração em minutos")
    modality: str = Field(
        'video',
        description="Modalidade: video, presencial, telefone")
    plan_type: str = Field('Por Ato', description="Tipo de plano")
    notes: Optional[str] = Field(None, description="Observações")
    meeting_url: Optional[str] = Field(None, description="URL da reunião")


class UpdateConsultationDTO(BaseModel):
    scheduled_at: Optional[datetime] = None
    duration_minutes: Optional[int] = None
    modality: Optional[str] = None
    plan_type: Optional[str] = None
    status: Optional[str] = None
    notes: Optional[str] = None
    meeting_url: Optional[str] = None


class ConsultationResponse(BaseModel):
    id: str
    case_id: str
    lawyer_id: str
    client_id: str
    scheduled_at: datetime
    duration_minutes: int
    modality: str
    plan_type: str
    status: str
    notes: Optional[str]
    meeting_url: Optional[str]
    created_at: datetime
    updated_at: datetime

# ============================================================================
# Rotas
# ============================================================================


@router.post("/", response_model=ConsultationResponse)
async def create_consultation(
    consultation_data: CreateConsultationDTO,
    current_user: dict = Depends(get_current_user)
):
    """
    Criar nova consulta
    """
    try:
        consultation_service = ConsultationService()

        consultation = await consultation_service.create_consultation(
            case_id=consultation_data.case_id,
            lawyer_id=consultation_data.lawyer_id,
            client_id=current_user["id"],
            scheduled_at=consultation_data.scheduled_at,
            duration_minutes=consultation_data.duration_minutes,
            modality=consultation_data.modality,
            plan_type=consultation_data.plan_type,
            notes=consultation_data.notes,
            meeting_url=consultation_data.meeting_url
        )

        return ConsultationResponse(**consultation)

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao criar consulta: {str(e)}"
        )


@router.get("/{consultation_id}", response_model=ConsultationResponse)
async def get_consultation(
    consultation_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Buscar consulta por ID
    """
    try:
        consultation_service = ConsultationService()
        consultation = await consultation_service.get_consultation(consultation_id)

        if not consultation:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Consulta não encontrada"
            )

        # Verificar permissão
        if consultation['client_id'] != current_user["id"] and consultation['lawyer_id'] != current_user["id"]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Sem permissão para visualizar esta consulta"
            )

        return ConsultationResponse(**consultation)

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao buscar consulta: {str(e)}"
        )


@router.put("/{consultation_id}", response_model=ConsultationResponse)
async def update_consultation(
    consultation_id: str,
    consultation_data: UpdateConsultationDTO,
    current_user: dict = Depends(get_current_user)
):
    """
    Atualizar consulta
    """
    try:
        consultation_service = ConsultationService()

        # Verificar se existe e permissão
        consultation = await consultation_service.get_consultation(consultation_id)
        if not consultation:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Consulta não encontrada"
            )

        if consultation['client_id'] != current_user["id"] and consultation['lawyer_id'] != current_user["id"]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Sem permissão para atualizar esta consulta"
            )

        # Atualizar apenas campos fornecidos
        updates = consultation_data.dict(exclude_none=True)
        if updates:
            updated_consultation = await consultation_service.update_consultation(consultation_id, **updates)
            return ConsultationResponse(**updated_consultation)

        return ConsultationResponse(**consultation)

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao atualizar consulta: {str(e)}"
        )


@router.post("/{consultation_id}/cancel")
async def cancel_consultation(
    consultation_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Cancelar consulta
    """
    try:
        consultation_service = ConsultationService()

        # Verificar se existe e permissão
        consultation = await consultation_service.get_consultation(consultation_id)
        if not consultation:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Consulta não encontrada"
            )

        if consultation['client_id'] != current_user["id"] and consultation['lawyer_id'] != current_user["id"]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Sem permissão para cancelar esta consulta"
            )

        await consultation_service.cancel_consultation(consultation_id)

        return {"message": "Consulta cancelada com sucesso"}

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao cancelar consulta: {str(e)}"
        )


@router.post("/{consultation_id}/complete")
async def complete_consultation(
    consultation_id: str,
    notes: Optional[str] = None,
    current_user: dict = Depends(get_current_user)
):
    """
    Marcar consulta como concluída
    """
    try:
        consultation_service = ConsultationService()

        # Verificar se existe e permissão
        consultation = await consultation_service.get_consultation(consultation_id)
        if not consultation:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Consulta não encontrada"
            )

        if consultation['lawyer_id'] != current_user["id"]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Apenas o advogado pode marcar consulta como concluída"
            )

        await consultation_service.complete_consultation(consultation_id, notes)

        return {"message": "Consulta marcada como concluída"}

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao concluir consulta: {str(e)}"
        )


@router.get("/case/{case_id}", response_model=List[ConsultationResponse])
async def get_case_consultations(
    case_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Listar consultas de um caso
    """
    try:
        consultation_service = ConsultationService()
        consultations = await consultation_service.get_case_consultations(case_id)

        return [ConsultationResponse(**consultation) for consultation in consultations]

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao listar consultas: {str(e)}"
        )


@router.get("/case/{case_id}/latest")
async def get_latest_consultation(
    case_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Buscar consulta mais recente de um caso
    """
    try:
        consultation_service = ConsultationService()
        consultation = await consultation_service.get_latest_consultation(case_id)

        if not consultation:
            return None

        return ConsultationResponse(**consultation)

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao buscar última consulta: {str(e)}"
        )


@router.get("/user/me", response_model=List[ConsultationResponse])
async def get_user_consultations(
    status_filter: Optional[str] = None,
    limit: int = 20,
    offset: int = 0,
    current_user: dict = Depends(get_current_user)
):
    """
    Listar consultas do usuário
    """
    try:
        consultation_service = ConsultationService()
        consultations = await consultation_service.get_user_consultations(
            user_id=current_user["id"],
            status_filter=status_filter,
            limit=limit,
            offset=offset
        )

        return [ConsultationResponse(**consultation) for consultation in consultations]

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao listar consultas: {str(e)}"
        )
