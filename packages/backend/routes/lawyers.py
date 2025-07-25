from fastapi import APIRouter, Depends, status, HTTPException
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime, timedelta
from uuid import UUID

from auth import get_current_user
from services.availability_service import AvailabilityService
from database import get_database
from services.notification_service import NotificationService
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/lawyers", tags=["Lawyers"])

class AvailabilitySettings(BaseModel):
    availability_status: Optional[str] = Field(None, description="Valores: available, busy, vacation, inactive")
    max_concurrent_cases: Optional[int] = Field(None, ge=1, le=100)
    vacation_start: Optional[datetime] = None
    vacation_end: Optional[datetime] = None

@router.get("/availability", response_model=AvailabilitySettings)
async def get_availability_settings(current_user: dict = Depends(get_current_user)):
    service = AvailabilityService()
    return await service.get_settings(current_user['id'])

@router.patch("/availability", status_code=status.HTTP_204_NO_CONTENT)
async def update_availability_settings(
    settings: AvailabilitySettings,
    current_user: dict = Depends(get_current_user)
):
    service = AvailabilityService()
    await service.update_settings(current_user['id'], settings)
    return None

# Pydantic Models for Hiring
class HireLawyerRequest(BaseModel):
    lawyer_id: str
    case_id: str
    contract_type: str  # 'hourly', 'fixed', 'success'
    budget: float
    notes: Optional[str] = None

class HiringResultResponse(BaseModel):
    proposal_id: str
    contract_id: str
    message: str
    created_at: datetime

@router.post("/hire", response_model=HiringResultResponse)
async def hire_lawyer(
    request: HireLawyerRequest,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_database)
):
    """
    Envia proposta de contratação para advogado
    """
    try:
        # Verificar se o advogado existe
        lawyer_result = await db.from_("users").select("id, name").eq("id", request.lawyer_id).execute()
        if not lawyer_result.data:
            raise HTTPException(status_code=404, detail="Advogado não encontrado")
        
        lawyer_data = lawyer_result.data[0]

        # Verificar se o caso existe e pertence ao cliente
        case_result = await db.from_("cases").select("id, title, description").eq("id", request.case_id).eq("client_id", current_user['id']).execute()
        if not case_result.data:
            raise HTTPException(status_code=404, detail="Caso não encontrado")

        case_data = case_result.data[0]
        
        # Criar proposta na tabela hiring_proposals
        proposal_data = {
            "client_id": current_user['id'],
            "lawyer_id": request.lawyer_id,
            "case_id": request.case_id,
            "contract_type": request.contract_type,
            "budget": request.budget,
            "notes": request.notes or "",
            "status": "pending",
            "created_at": datetime.utcnow().isoformat(),
            "expires_at": (datetime.utcnow() + timedelta(days=7)).isoformat()
        }
        
        proposal_result = await db.from_("hiring_proposals").insert(proposal_data).execute()
        
        if not proposal_result.data:
            raise HTTPException(status_code=500, detail="Erro ao criar proposta")
        
        proposal = proposal_result.data[0]
        
        # Enviar notificação para o advogado
        notification_service = NotificationService()
        await notification_service.send_notification(
            user_id=request.lawyer_id,
            notification_type="hiring_proposal",
            title="Nova Proposta de Contratação",
            message=f"Você recebeu uma proposta de contratação para o caso {case_data['title']}",
            data={
                "proposal_id": proposal["id"],
                "case_id": request.case_id,
                "client_name": current_user.get('name', 'Cliente'),
                "budget": request.budget,
                "contract_type": request.contract_type
            }
        )
        
        return HiringResultResponse(
            proposal_id=proposal["id"],
            contract_id="",  # Será preenchido quando aceito
            message="Proposta enviada com sucesso",
            created_at=datetime.fromisoformat(proposal["created_at"])
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao enviar proposta: {e}")
        raise HTTPException(status_code=500, detail="Erro interno do servidor") 