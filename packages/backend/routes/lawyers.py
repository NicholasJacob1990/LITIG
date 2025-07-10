from fastapi import APIRouter, Depends, status
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from uuid import UUID

from backend.auth import get_current_user
from backend.services.availability_service import AvailabilityService

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