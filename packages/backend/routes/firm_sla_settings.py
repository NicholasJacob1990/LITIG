"""
API endpoints for firm SLA settings management
"""

from typing import Dict, List, Optional, Any
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field, validator
from datetime import datetime, timedelta
import logging

from ..auth import get_current_user
from ..dependencies import get_supabase_client
from ..models import User

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/firms", tags=["firm-sla-settings"])


class FirmSlaSettingsModel(BaseModel):
    """Model for firm SLA settings"""
    default_internal_delegation_hours: int = Field(
        default=48, 
        ge=1, 
        le=720, 
        description="Default SLA hours for internal delegations (1-720 hours)"
    )
    urgent_internal_delegation_hours: int = Field(
        default=24, 
        ge=1, 
        le=168, 
        description="SLA hours for urgent internal delegations (1-168 hours)"
    )
    complex_case_delegation_hours: int = Field(
        default=72, 
        ge=1, 
        le=720, 
        description="SLA hours for complex case delegations (1-720 hours)"
    )
    notify_before_deadline_hours: int = Field(
        default=4, 
        ge=1, 
        le=48, 
        description="Hours before deadline to send notification"
    )
    escalate_after_deadline_hours: int = Field(
        default=2, 
        ge=0, 
        le=24, 
        description="Hours after deadline to escalate"
    )
    allow_weekend_deadlines: bool = Field(
        default=False, 
        description="Allow deadlines to fall on weekends"
    )
    business_hours_only: bool = Field(
        default=False, 
        description="Adjust deadlines to business hours only"
    )
    business_start_hour: int = Field(
        default=9, 
        ge=0, 
        le=23, 
        description="Business day start hour (0-23)"
    )
    business_end_hour: int = Field(
        default=18, 
        ge=1, 
        le=23, 
        description="Business day end hour (1-23)"
    )
    settings_metadata: Dict[str, Any] = Field(
        default_factory=dict, 
        description="Additional metadata for settings"
    )
    is_active: bool = Field(
        default=True, 
        description="Whether these settings are active"
    )

    @validator('business_end_hour')
    def validate_business_hours(cls, v, values):
        if 'business_start_hour' in values and v <= values['business_start_hour']:
            raise ValueError('business_end_hour must be greater than business_start_hour')
        return v

    @validator('urgent_internal_delegation_hours')
    def validate_urgent_hours(cls, v, values):
        if 'default_internal_delegation_hours' in values and v > values['default_internal_delegation_hours']:
            raise ValueError('urgent_internal_delegation_hours should not exceed default_internal_delegation_hours')
        return v


class SlaSettingsResponse(BaseModel):
    """Response model for SLA settings"""
    id: str
    firm_id: str
    created_at: datetime
    updated_at: datetime
    default_internal_delegation_hours: int
    urgent_internal_delegation_hours: int
    complex_case_delegation_hours: int
    notify_before_deadline_hours: int
    escalate_after_deadline_hours: int
    allow_weekend_deadlines: bool
    business_hours_only: bool
    business_start_hour: int
    business_end_hour: int
    settings_metadata: Dict[str, Any]
    is_active: bool


class DelegationSlaRequest(BaseModel):
    """Request model for calculating delegation SLA"""
    priority_level: int = Field(default=1, ge=1, le=3, description="Priority: 1=normal, 2=urgent, 3=emergency")
    sla_override_hours: Optional[int] = Field(default=None, ge=1, le=720, description="Override SLA hours")
    start_time: Optional[datetime] = Field(default=None, description="Custom start time")


class DelegationSlaResponse(BaseModel):
    """Response model for delegation SLA calculation"""
    deadline: datetime
    sla_hours_used: int
    priority_level: int
    business_rules_applied: Dict[str, Any]
    firm_settings_used: bool


async def _get_user_firm_id(user: User, supabase) -> str:
    """Get firm ID for the current user"""
    try:
        # Check if user is associated with a firm
        response = supabase.table("firm_lawyers")\
            .select("firm_id")\
            .eq("lawyer_id", user.id)\
            .eq("is_active", True)\
            .execute()
        
        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Usuário não está associado a nenhum escritório"
            )
        
        return response.data[0]["firm_id"]
        
    except Exception as e:
        logger.error(f"Erro ao buscar firm_id do usuário {user.id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao verificar associação com escritório"
        )


async def _check_firm_admin_permission(user: User, firm_id: str, supabase) -> bool:
    """Check if user has admin permission for the firm"""
    try:
        response = supabase.table("firm_lawyers")\
            .select("role")\
            .eq("lawyer_id", user.id)\
            .eq("firm_id", firm_id)\
            .eq("is_active", True)\
            .execute()
        
        if not response.data:
            return False
        
        return response.data[0]["role"] in ["owner", "partner", "admin"]
        
    except Exception as e:
        logger.error(f"Erro ao verificar permissão de admin: {e}")
        return False


@router.get("/{firm_id}/sla-settings", response_model=SlaSettingsResponse)
async def get_firm_sla_settings(
    firm_id: str,
    current_user: User = Depends(get_current_user),
    supabase=Depends(get_supabase_client)
):
    """
    Get SLA settings for a specific firm
    """
    try:
        # Verify user belongs to this firm
        user_firm_id = await _get_user_firm_id(current_user, supabase)
        
        if user_firm_id != firm_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Acesso negado: usuário não pertence a este escritório"
            )
        
        # Get SLA settings
        response = supabase.table("firm_sla_settings")\
            .select("*")\
            .eq("firm_id", firm_id)\
            .eq("is_active", True)\
            .execute()
        
        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Configurações de SLA não encontradas"
            )
        
        settings = response.data[0]
        return SlaSettingsResponse(**settings)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao buscar configurações de SLA: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao buscar configurações de SLA"
        )


@router.get("/my-firm/sla-settings", response_model=SlaSettingsResponse)
async def get_my_firm_sla_settings(
    current_user: User = Depends(get_current_user),
    supabase=Depends(get_supabase_client)
):
    """
    Get SLA settings for the current user's firm
    """
    firm_id = await _get_user_firm_id(current_user, supabase)
    return await get_firm_sla_settings(firm_id, current_user, supabase)


@router.put("/{firm_id}/sla-settings", response_model=SlaSettingsResponse)
async def update_firm_sla_settings(
    firm_id: str,
    settings: FirmSlaSettingsModel,
    current_user: User = Depends(get_current_user),
    supabase=Depends(get_supabase_client)
):
    """
    Update SLA settings for a firm (admin only)
    """
    try:
        # Verify user belongs to this firm and has admin permission
        user_firm_id = await _get_user_firm_id(current_user, supabase)
        
        if user_firm_id != firm_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Acesso negado: usuário não pertence a este escritório"
            )
        
        has_admin_permission = await _check_firm_admin_permission(current_user, firm_id, supabase)
        if not has_admin_permission:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Acesso negado: usuário não tem permissão de administrador"
            )
        
        # Update settings
        update_data = settings.dict()
        update_data['updated_at'] = datetime.now().isoformat()
        
        response = supabase.table("firm_sla_settings")\
            .update(update_data)\
            .eq("firm_id", firm_id)\
            .execute()
        
        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Configurações de SLA não encontradas"
            )
        
        updated_settings = response.data[0]
        return SlaSettingsResponse(**updated_settings)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao atualizar configurações de SLA: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao atualizar configurações de SLA"
        )


@router.put("/my-firm/sla-settings", response_model=SlaSettingsResponse)
async def update_my_firm_sla_settings(
    settings: FirmSlaSettingsModel,
    current_user: User = Depends(get_current_user),
    supabase=Depends(get_supabase_client)
):
    """
    Update SLA settings for the current user's firm
    """
    firm_id = await _get_user_firm_id(current_user, supabase)
    return await update_firm_sla_settings(firm_id, settings, current_user, supabase)


@router.post("/{firm_id}/calculate-delegation-sla", response_model=DelegationSlaResponse)
async def calculate_delegation_sla(
    firm_id: str,
    request: DelegationSlaRequest,
    current_user: User = Depends(get_current_user),
    supabase=Depends(get_supabase_client)
):
    """
    Calculate delegation SLA deadline based on firm settings and parameters
    """
    try:
        # Verify user belongs to this firm
        user_firm_id = await _get_user_firm_id(current_user, supabase)
        
        if user_firm_id != firm_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Acesso negado: usuário não pertence a este escritório"
            )
        
        # Use database function to calculate deadline
        start_time = request.start_time or datetime.now()
        
        # Call PostgreSQL function
        result = supabase.rpc(
            'calculate_delegation_deadline',
            {
                'p_firm_id': firm_id,
                'p_priority_level': request.priority_level,
                'p_sla_override_hours': request.sla_override_hours,
                'p_start_time': start_time.isoformat()
            }
        ).execute()
        
        if not result.data:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Erro ao calcular prazo de delegação"
            )
        
        deadline = datetime.fromisoformat(result.data)
        
        # Get firm settings for response details
        settings_response = supabase.table("firm_sla_settings")\
            .select("*")\
            .eq("firm_id", firm_id)\
            .eq("is_active", True)\
            .execute()
        
        settings = settings_response.data[0] if settings_response.data else None
        
        # Calculate hours used
        time_diff = deadline - start_time
        sla_hours_used = int(time_diff.total_seconds() / 3600)
        
        # Determine business rules applied
        business_rules_applied = {}
        if settings:
            business_rules_applied = {
                "weekend_adjustment": not settings.get("allow_weekend_deadlines", False),
                "business_hours_adjustment": settings.get("business_hours_only", False),
                "business_start_hour": settings.get("business_start_hour", 9),
                "business_end_hour": settings.get("business_end_hour", 18)
            }
        
        return DelegationSlaResponse(
            deadline=deadline,
            sla_hours_used=sla_hours_used,
            priority_level=request.priority_level,
            business_rules_applied=business_rules_applied,
            firm_settings_used=settings is not None
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao calcular SLA de delegação: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao calcular SLA de delegação"
        )


@router.post("/my-firm/calculate-delegation-sla", response_model=DelegationSlaResponse)
async def calculate_my_firm_delegation_sla(
    request: DelegationSlaRequest,
    current_user: User = Depends(get_current_user),
    supabase=Depends(get_supabase_client)
):
    """
    Calculate delegation SLA for current user's firm
    """
    firm_id = await _get_user_firm_id(current_user, supabase)
    return await calculate_delegation_sla(firm_id, request, current_user, supabase)


@router.get("/{firm_id}/sla-presets")
async def get_sla_presets(
    firm_id: str,
    current_user: User = Depends(get_current_user),
    supabase=Depends(get_supabase_client)
):
    """
    Get predefined SLA presets for quick configuration
    """
    try:
        # Verify user belongs to this firm
        user_firm_id = await _get_user_firm_id(current_user, supabase)
        
        if user_firm_id != firm_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Acesso negado: usuário não pertence a este escritório"
            )
        
        presets = {
            "conservative": {
                "name": "Conservador",
                "description": "Prazos generosos para garantir qualidade",
                "settings": {
                    "default_internal_delegation_hours": 72,
                    "urgent_internal_delegation_hours": 48,
                    "complex_case_delegation_hours": 120,
                    "notify_before_deadline_hours": 8,
                    "escalate_after_deadline_hours": 4,
                    "allow_weekend_deadlines": False,
                    "business_hours_only": True,
                    "business_start_hour": 9,
                    "business_end_hour": 18
                }
            },
            "balanced": {
                "name": "Equilibrado",
                "description": "Balanceamento entre agilidade e qualidade",
                "settings": {
                    "default_internal_delegation_hours": 48,
                    "urgent_internal_delegation_hours": 24,
                    "complex_case_delegation_hours": 72,
                    "notify_before_deadline_hours": 4,
                    "escalate_after_deadline_hours": 2,
                    "allow_weekend_deadlines": False,
                    "business_hours_only": False,
                    "business_start_hour": 8,
                    "business_end_hour": 19
                }
            },
            "aggressive": {
                "name": "Agressivo",
                "description": "Prazos apertados para máxima agilidade",
                "settings": {
                    "default_internal_delegation_hours": 24,
                    "urgent_internal_delegation_hours": 12,
                    "complex_case_delegation_hours": 48,
                    "notify_before_deadline_hours": 2,
                    "escalate_after_deadline_hours": 1,
                    "allow_weekend_deadlines": True,
                    "business_hours_only": False,
                    "business_start_hour": 7,
                    "business_end_hour": 22
                }
            },
            "large_firm": {
                "name": "Escritório Grande",
                "description": "Configurado para escritórios com muitos advogados",
                "settings": {
                    "default_internal_delegation_hours": 36,
                    "urgent_internal_delegation_hours": 18,
                    "complex_case_delegation_hours": 84,
                    "notify_before_deadline_hours": 6,
                    "escalate_after_deadline_hours": 3,
                    "allow_weekend_deadlines": False,
                    "business_hours_only": True,
                    "business_start_hour": 8,
                    "business_end_hour": 20
                }
            }
        }
        
        return {
            "presets": presets,
            "firm_id": firm_id
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao buscar presets de SLA: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao buscar presets de SLA"
        ) 
API endpoints for firm SLA settings management
"""

from typing import Dict, List, Optional, Any
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field, validator
from datetime import datetime, timedelta
import logging

from ..auth import get_current_user
from ..dependencies import get_supabase_client
from ..models import User

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/firms", tags=["firm-sla-settings"])


class FirmSlaSettingsModel(BaseModel):
    """Model for firm SLA settings"""
    default_internal_delegation_hours: int = Field(
        default=48, 
        ge=1, 
        le=720, 
        description="Default SLA hours for internal delegations (1-720 hours)"
    )
    urgent_internal_delegation_hours: int = Field(
        default=24, 
        ge=1, 
        le=168, 
        description="SLA hours for urgent internal delegations (1-168 hours)"
    )
    complex_case_delegation_hours: int = Field(
        default=72, 
        ge=1, 
        le=720, 
        description="SLA hours for complex case delegations (1-720 hours)"
    )
    notify_before_deadline_hours: int = Field(
        default=4, 
        ge=1, 
        le=48, 
        description="Hours before deadline to send notification"
    )
    escalate_after_deadline_hours: int = Field(
        default=2, 
        ge=0, 
        le=24, 
        description="Hours after deadline to escalate"
    )
    allow_weekend_deadlines: bool = Field(
        default=False, 
        description="Allow deadlines to fall on weekends"
    )
    business_hours_only: bool = Field(
        default=False, 
        description="Adjust deadlines to business hours only"
    )
    business_start_hour: int = Field(
        default=9, 
        ge=0, 
        le=23, 
        description="Business day start hour (0-23)"
    )
    business_end_hour: int = Field(
        default=18, 
        ge=1, 
        le=23, 
        description="Business day end hour (1-23)"
    )
    settings_metadata: Dict[str, Any] = Field(
        default_factory=dict, 
        description="Additional metadata for settings"
    )
    is_active: bool = Field(
        default=True, 
        description="Whether these settings are active"
    )

    @validator('business_end_hour')
    def validate_business_hours(cls, v, values):
        if 'business_start_hour' in values and v <= values['business_start_hour']:
            raise ValueError('business_end_hour must be greater than business_start_hour')
        return v

    @validator('urgent_internal_delegation_hours')
    def validate_urgent_hours(cls, v, values):
        if 'default_internal_delegation_hours' in values and v > values['default_internal_delegation_hours']:
            raise ValueError('urgent_internal_delegation_hours should not exceed default_internal_delegation_hours')
        return v


class SlaSettingsResponse(BaseModel):
    """Response model for SLA settings"""
    id: str
    firm_id: str
    created_at: datetime
    updated_at: datetime
    default_internal_delegation_hours: int
    urgent_internal_delegation_hours: int
    complex_case_delegation_hours: int
    notify_before_deadline_hours: int
    escalate_after_deadline_hours: int
    allow_weekend_deadlines: bool
    business_hours_only: bool
    business_start_hour: int
    business_end_hour: int
    settings_metadata: Dict[str, Any]
    is_active: bool


class DelegationSlaRequest(BaseModel):
    """Request model for calculating delegation SLA"""
    priority_level: int = Field(default=1, ge=1, le=3, description="Priority: 1=normal, 2=urgent, 3=emergency")
    sla_override_hours: Optional[int] = Field(default=None, ge=1, le=720, description="Override SLA hours")
    start_time: Optional[datetime] = Field(default=None, description="Custom start time")


class DelegationSlaResponse(BaseModel):
    """Response model for delegation SLA calculation"""
    deadline: datetime
    sla_hours_used: int
    priority_level: int
    business_rules_applied: Dict[str, Any]
    firm_settings_used: bool


async def _get_user_firm_id(user: User, supabase) -> str:
    """Get firm ID for the current user"""
    try:
        # Check if user is associated with a firm
        response = supabase.table("firm_lawyers")\
            .select("firm_id")\
            .eq("lawyer_id", user.id)\
            .eq("is_active", True)\
            .execute()
        
        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Usuário não está associado a nenhum escritório"
            )
        
        return response.data[0]["firm_id"]
        
    except Exception as e:
        logger.error(f"Erro ao buscar firm_id do usuário {user.id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao verificar associação com escritório"
        )


async def _check_firm_admin_permission(user: User, firm_id: str, supabase) -> bool:
    """Check if user has admin permission for the firm"""
    try:
        response = supabase.table("firm_lawyers")\
            .select("role")\
            .eq("lawyer_id", user.id)\
            .eq("firm_id", firm_id)\
            .eq("is_active", True)\
            .execute()
        
        if not response.data:
            return False
        
        return response.data[0]["role"] in ["owner", "partner", "admin"]
        
    except Exception as e:
        logger.error(f"Erro ao verificar permissão de admin: {e}")
        return False


@router.get("/{firm_id}/sla-settings", response_model=SlaSettingsResponse)
async def get_firm_sla_settings(
    firm_id: str,
    current_user: User = Depends(get_current_user),
    supabase=Depends(get_supabase_client)
):
    """
    Get SLA settings for a specific firm
    """
    try:
        # Verify user belongs to this firm
        user_firm_id = await _get_user_firm_id(current_user, supabase)
        
        if user_firm_id != firm_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Acesso negado: usuário não pertence a este escritório"
            )
        
        # Get SLA settings
        response = supabase.table("firm_sla_settings")\
            .select("*")\
            .eq("firm_id", firm_id)\
            .eq("is_active", True)\
            .execute()
        
        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Configurações de SLA não encontradas"
            )
        
        settings = response.data[0]
        return SlaSettingsResponse(**settings)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao buscar configurações de SLA: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao buscar configurações de SLA"
        )


@router.get("/my-firm/sla-settings", response_model=SlaSettingsResponse)
async def get_my_firm_sla_settings(
    current_user: User = Depends(get_current_user),
    supabase=Depends(get_supabase_client)
):
    """
    Get SLA settings for the current user's firm
    """
    firm_id = await _get_user_firm_id(current_user, supabase)
    return await get_firm_sla_settings(firm_id, current_user, supabase)


@router.put("/{firm_id}/sla-settings", response_model=SlaSettingsResponse)
async def update_firm_sla_settings(
    firm_id: str,
    settings: FirmSlaSettingsModel,
    current_user: User = Depends(get_current_user),
    supabase=Depends(get_supabase_client)
):
    """
    Update SLA settings for a firm (admin only)
    """
    try:
        # Verify user belongs to this firm and has admin permission
        user_firm_id = await _get_user_firm_id(current_user, supabase)
        
        if user_firm_id != firm_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Acesso negado: usuário não pertence a este escritório"
            )
        
        has_admin_permission = await _check_firm_admin_permission(current_user, firm_id, supabase)
        if not has_admin_permission:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Acesso negado: usuário não tem permissão de administrador"
            )
        
        # Update settings
        update_data = settings.dict()
        update_data['updated_at'] = datetime.now().isoformat()
        
        response = supabase.table("firm_sla_settings")\
            .update(update_data)\
            .eq("firm_id", firm_id)\
            .execute()
        
        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Configurações de SLA não encontradas"
            )
        
        updated_settings = response.data[0]
        return SlaSettingsResponse(**updated_settings)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao atualizar configurações de SLA: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao atualizar configurações de SLA"
        )


@router.put("/my-firm/sla-settings", response_model=SlaSettingsResponse)
async def update_my_firm_sla_settings(
    settings: FirmSlaSettingsModel,
    current_user: User = Depends(get_current_user),
    supabase=Depends(get_supabase_client)
):
    """
    Update SLA settings for the current user's firm
    """
    firm_id = await _get_user_firm_id(current_user, supabase)
    return await update_firm_sla_settings(firm_id, settings, current_user, supabase)


@router.post("/{firm_id}/calculate-delegation-sla", response_model=DelegationSlaResponse)
async def calculate_delegation_sla(
    firm_id: str,
    request: DelegationSlaRequest,
    current_user: User = Depends(get_current_user),
    supabase=Depends(get_supabase_client)
):
    """
    Calculate delegation SLA deadline based on firm settings and parameters
    """
    try:
        # Verify user belongs to this firm
        user_firm_id = await _get_user_firm_id(current_user, supabase)
        
        if user_firm_id != firm_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Acesso negado: usuário não pertence a este escritório"
            )
        
        # Use database function to calculate deadline
        start_time = request.start_time or datetime.now()
        
        # Call PostgreSQL function
        result = supabase.rpc(
            'calculate_delegation_deadline',
            {
                'p_firm_id': firm_id,
                'p_priority_level': request.priority_level,
                'p_sla_override_hours': request.sla_override_hours,
                'p_start_time': start_time.isoformat()
            }
        ).execute()
        
        if not result.data:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Erro ao calcular prazo de delegação"
            )
        
        deadline = datetime.fromisoformat(result.data)
        
        # Get firm settings for response details
        settings_response = supabase.table("firm_sla_settings")\
            .select("*")\
            .eq("firm_id", firm_id)\
            .eq("is_active", True)\
            .execute()
        
        settings = settings_response.data[0] if settings_response.data else None
        
        # Calculate hours used
        time_diff = deadline - start_time
        sla_hours_used = int(time_diff.total_seconds() / 3600)
        
        # Determine business rules applied
        business_rules_applied = {}
        if settings:
            business_rules_applied = {
                "weekend_adjustment": not settings.get("allow_weekend_deadlines", False),
                "business_hours_adjustment": settings.get("business_hours_only", False),
                "business_start_hour": settings.get("business_start_hour", 9),
                "business_end_hour": settings.get("business_end_hour", 18)
            }
        
        return DelegationSlaResponse(
            deadline=deadline,
            sla_hours_used=sla_hours_used,
            priority_level=request.priority_level,
            business_rules_applied=business_rules_applied,
            firm_settings_used=settings is not None
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao calcular SLA de delegação: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao calcular SLA de delegação"
        )


@router.post("/my-firm/calculate-delegation-sla", response_model=DelegationSlaResponse)
async def calculate_my_firm_delegation_sla(
    request: DelegationSlaRequest,
    current_user: User = Depends(get_current_user),
    supabase=Depends(get_supabase_client)
):
    """
    Calculate delegation SLA for current user's firm
    """
    firm_id = await _get_user_firm_id(current_user, supabase)
    return await calculate_delegation_sla(firm_id, request, current_user, supabase)


@router.get("/{firm_id}/sla-presets")
async def get_sla_presets(
    firm_id: str,
    current_user: User = Depends(get_current_user),
    supabase=Depends(get_supabase_client)
):
    """
    Get predefined SLA presets for quick configuration
    """
    try:
        # Verify user belongs to this firm
        user_firm_id = await _get_user_firm_id(current_user, supabase)
        
        if user_firm_id != firm_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Acesso negado: usuário não pertence a este escritório"
            )
        
        presets = {
            "conservative": {
                "name": "Conservador",
                "description": "Prazos generosos para garantir qualidade",
                "settings": {
                    "default_internal_delegation_hours": 72,
                    "urgent_internal_delegation_hours": 48,
                    "complex_case_delegation_hours": 120,
                    "notify_before_deadline_hours": 8,
                    "escalate_after_deadline_hours": 4,
                    "allow_weekend_deadlines": False,
                    "business_hours_only": True,
                    "business_start_hour": 9,
                    "business_end_hour": 18
                }
            },
            "balanced": {
                "name": "Equilibrado",
                "description": "Balanceamento entre agilidade e qualidade",
                "settings": {
                    "default_internal_delegation_hours": 48,
                    "urgent_internal_delegation_hours": 24,
                    "complex_case_delegation_hours": 72,
                    "notify_before_deadline_hours": 4,
                    "escalate_after_deadline_hours": 2,
                    "allow_weekend_deadlines": False,
                    "business_hours_only": False,
                    "business_start_hour": 8,
                    "business_end_hour": 19
                }
            },
            "aggressive": {
                "name": "Agressivo",
                "description": "Prazos apertados para máxima agilidade",
                "settings": {
                    "default_internal_delegation_hours": 24,
                    "urgent_internal_delegation_hours": 12,
                    "complex_case_delegation_hours": 48,
                    "notify_before_deadline_hours": 2,
                    "escalate_after_deadline_hours": 1,
                    "allow_weekend_deadlines": True,
                    "business_hours_only": False,
                    "business_start_hour": 7,
                    "business_end_hour": 22
                }
            },
            "large_firm": {
                "name": "Escritório Grande",
                "description": "Configurado para escritórios com muitos advogados",
                "settings": {
                    "default_internal_delegation_hours": 36,
                    "urgent_internal_delegation_hours": 18,
                    "complex_case_delegation_hours": 84,
                    "notify_before_deadline_hours": 6,
                    "escalate_after_deadline_hours": 3,
                    "allow_weekend_deadlines": False,
                    "business_hours_only": True,
                    "business_start_hour": 8,
                    "business_end_hour": 20
                }
            }
        }
        
        return {
            "presets": presets,
            "firm_id": firm_id
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao buscar presets de SLA: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro ao buscar presets de SLA"
        ) 