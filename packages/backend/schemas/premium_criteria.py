from pydantic import BaseModel, field_validator
from typing import List, Optional
from datetime import datetime
from enum import Enum

# Existing PremiumCriteria schemas
class PremiumCriteriaBase(BaseModel):
    service_code: str
    subservice_code: Optional[str] = None
    name: str
    enabled: bool = True
    min_valor_causa: Optional[float] = None
    max_valor_causa: Optional[float] = None
    min_urgency_h: Optional[int] = None
    complexity_levels: List[str] = []
    vip_client_plans: List[str] = []

class PremiumCriteriaCreate(PremiumCriteriaBase):
    pass

class PremiumCriteriaUpdate(BaseModel):
    service_code: Optional[str] = None
    subservice_code: Optional[str] = None
    name: Optional[str] = None
    enabled: Optional[bool] = None
    min_valor_causa: Optional[float] = None
    max_valor_causa: Optional[float] = None
    min_urgency_h: Optional[int] = None
    complexity_levels: Optional[List[str]] = None
    vip_client_plans: Optional[List[str]] = None

class PremiumCriteriaResponse(PremiumCriteriaBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

# Legacy alias for backward compatibility
PremiumCriteria = PremiumCriteriaResponse 

# New Client schemas for plan management
class ClientPlan(str, Enum):
    FREE = "FREE"
    VIP = "VIP"
    ENTERPRISE = "ENTERPRISE"

class ClientBase(BaseModel):
    full_name: Optional[str] = None
    avatar_url: Optional[str] = None
    role: str = "client"
    phone: Optional[str] = None
    plan: ClientPlan = ClientPlan.FREE

class ClientCreate(ClientBase):
    user_id: str  # Required for creating new client

class ClientUpdate(BaseModel):
    full_name: Optional[str] = None
    avatar_url: Optional[str] = None
    phone: Optional[str] = None
    plan: Optional[ClientPlan] = None

class ClientResponse(ClientBase):
    id: str
    user_id: str
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class ClientPlanUpdate(BaseModel):
    plan: ClientPlan

    @field_validator('plan')
    @classmethod
    def validate_plan(cls, v):
        if v not in [ClientPlan.FREE, ClientPlan.VIP, ClientPlan.ENTERPRISE]:
            raise ValueError('Plan must be FREE, VIP, or ENTERPRISE')
        return v 