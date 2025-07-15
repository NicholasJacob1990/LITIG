"""
Endpoints para Feature Flags
API para gerenciamento de rollout gradual da contextualização
"""

from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from fastapi import APIRouter, Depends, HTTPException, Query, Body
from pydantic import BaseModel, Field
import logging

from ..auth import get_current_user
from ..services.feature_flag_service import FeatureFlagService, FeatureStatus, RolloutStrategy
from ..models.user import User

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/feature-flags", tags=["feature-flags"])

# Pydantic Models
class FeatureFlagRequest(BaseModel):
    name: str = Field(..., description="Nome da feature flag")
    description: str = Field(..., description="Descrição da feature")
    rollout_strategy: str = Field(default="percentage", description="Estratégia de rollout")
    rollout_percentage: float = Field(default=0.0, ge=0, le=100, description="Percentual de rollout")
    target_users: Optional[List[str]] = Field(None, description="Usuários específicos")
    target_roles: Optional[List[str]] = Field(None, description="Roles específicas")
    target_regions: Optional[List[str]] = Field(None, description="Regiões específicas")
    device_types: Optional[List[str]] = Field(None, description="Tipos de dispositivo")
    start_date: Optional[datetime] = Field(None, description="Data de início")
    end_date: Optional[datetime] = Field(None, description="Data de fim")
    metadata: Optional[Dict[str, Any]] = Field(None, description="Metadados")

class FeatureFlagUpdateRequest(BaseModel):
    status: Optional[str] = Field(None, description="Status da feature")
    rollout_percentage: Optional[float] = Field(None, ge=0, le=100, description="Percentual de rollout")
    target_users: Optional[List[str]] = Field(None, description="Usuários específicos")
    target_roles: Optional[List[str]] = Field(None, description="Roles específicas")
    target_regions: Optional[List[str]] = Field(None, description="Regiões específicas")
    device_types: Optional[List[str]] = Field(None, description="Tipos de dispositivo")
    metadata: Optional[Dict[str, Any]] = Field(None, description="Metadados")

class FeatureFlagResponse(BaseModel):
    name: str
    description: str
    status: str
    rollout_strategy: str
    rollout_percentage: float
    target_users: List[str]
    target_roles: List[str]
    target_regions: List[str]
    device_types: List[str]
    start_date: Optional[datetime]
    end_date: Optional[datetime]
    metadata: Dict[str, Any]
    created_at: datetime
    updated_at: datetime

class FeatureCheckRequest(BaseModel):
    feature_name: str = Field(..., description="Nome da feature")
    context: Optional[Dict[str, Any]] = Field(None, description="Contexto adicional")

class ContextualFeaturesResponse(BaseModel):
    allocation_types_enabled: List[str]
    ui_components_enabled: List[str]
    metrics_collection_enabled: bool
    dual_context_enabled: bool
    advanced_kpis_enabled: bool
    real_time_updates_enabled: bool
    performance_monitoring_enabled: bool

class RolloutPhaseRequest(BaseModel):
    phase_name: str = Field(..., description="Nome da fase")
    features: List[str] = Field(..., description="Features a serem habilitadas")
    target_roles: List[str] = Field(..., description="Roles alvo")
    rollout_percentage: float = Field(..., ge=0, le=100, description="Percentual de rollout")
    description: str = Field(..., description="Descrição da fase")

# Dependency
def get_feature_flag_service():
    return FeatureFlagService()

@router.post("/", response_model=FeatureFlagResponse)
async def create_feature_flag(
    request: FeatureFlagRequest,
    feature_service: FeatureFlagService = Depends(get_feature_flag_service),
    current_user: User = Depends(get_current_user)
):
    """Cria uma nova feature flag"""
    try:
        # Apenas admins podem criar feature flags
        if not current_user.is_admin:
            raise HTTPException(status_code=403, detail="Admin access required")
        
        # Valida estratégia de rollout
        try:
            rollout_strategy = RolloutStrategy(request.rollout_strategy)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid rollout strategy")
        
        feature_flag = await feature_service.create_feature_flag(
            name=request.name,
            description=request.description,
            rollout_strategy=rollout_strategy,
            rollout_percentage=request.rollout_percentage,
            target_users=request.target_users,
            target_roles=request.target_roles,
            target_regions=request.target_regions,
            device_types=request.device_types,
            start_date=request.start_date,
            end_date=request.end_date,
            metadata=request.metadata
        )
        
        return FeatureFlagResponse(
            name=feature_flag.name,
            description=feature_flag.description,
            status=feature_flag.status.value,
            rollout_strategy=feature_flag.rollout_strategy.value,
            rollout_percentage=feature_flag.rollout_percentage,
            target_users=feature_flag.target_users,
            target_roles=feature_flag.target_roles,
            target_regions=feature_flag.target_regions,
            device_types=feature_flag.device_types,
            start_date=feature_flag.start_date,
            end_date=feature_flag.end_date,
            metadata=feature_flag.metadata,
            created_at=feature_flag.created_at,
            updated_at=feature_flag.updated_at
        )
        
    except Exception as e:
        logger.error(f"Error creating feature flag: {e}")
        raise HTTPException(status_code=500, detail="Failed to create feature flag")

@router.get("/", response_model=List[FeatureFlagResponse])
async def list_feature_flags(
    feature_service: FeatureFlagService = Depends(get_feature_flag_service),
    current_user: User = Depends(get_current_user)
):
    """Lista todas as feature flags"""
    try:
        # Apenas admins podem listar feature flags
        if not current_user.is_admin:
            raise HTTPException(status_code=403, detail="Admin access required")
        
        feature_flags = await feature_service.list_feature_flags()
        
        return [
            FeatureFlagResponse(
                name=ff.name,
                description=ff.description,
                status=ff.status.value,
                rollout_strategy=ff.rollout_strategy.value,
                rollout_percentage=ff.rollout_percentage,
                target_users=ff.target_users,
                target_roles=ff.target_roles,
                target_regions=ff.target_regions,
                device_types=ff.device_types,
                start_date=ff.start_date,
                end_date=ff.end_date,
                metadata=ff.metadata,
                created_at=ff.created_at,
                updated_at=ff.updated_at
            )
            for ff in feature_flags
        ]
        
    except Exception as e:
        logger.error(f"Error listing feature flags: {e}")
        raise HTTPException(status_code=500, detail="Failed to list feature flags")

@router.get("/{feature_name}", response_model=FeatureFlagResponse)
async def get_feature_flag(
    feature_name: str,
    feature_service: FeatureFlagService = Depends(get_feature_flag_service),
    current_user: User = Depends(get_current_user)
):
    """Obtém uma feature flag específica"""
    try:
        # Apenas admins podem ver feature flags
        if not current_user.is_admin:
            raise HTTPException(status_code=403, detail="Admin access required")
        
        feature_flag = await feature_service.get_feature_flag(feature_name)
        
        if not feature_flag:
            raise HTTPException(status_code=404, detail="Feature flag not found")
        
        return FeatureFlagResponse(
            name=feature_flag.name,
            description=feature_flag.description,
            status=feature_flag.status.value,
            rollout_strategy=feature_flag.rollout_strategy.value,
            rollout_percentage=feature_flag.rollout_percentage,
            target_users=feature_flag.target_users,
            target_roles=feature_flag.target_roles,
            target_regions=feature_flag.target_regions,
            device_types=feature_flag.device_types,
            start_date=feature_flag.start_date,
            end_date=feature_flag.end_date,
            metadata=feature_flag.metadata,
            created_at=feature_flag.created_at,
            updated_at=feature_flag.updated_at
        )
        
    except Exception as e:
        logger.error(f"Error getting feature flag: {e}")
        raise HTTPException(status_code=500, detail="Failed to get feature flag")

@router.put("/{feature_name}", response_model=FeatureFlagResponse)
async def update_feature_flag(
    feature_name: str,
    request: FeatureFlagUpdateRequest,
    feature_service: FeatureFlagService = Depends(get_feature_flag_service),
    current_user: User = Depends(get_current_user)
):
    """Atualiza uma feature flag"""
    try:
        # Apenas admins podem atualizar feature flags
        if not current_user.is_admin:
            raise HTTPException(status_code=403, detail="Admin access required")
        
        # Valida status se fornecido
        status = None
        if request.status:
            try:
                status = FeatureStatus(request.status)
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid feature status")
        
        feature_flag = await feature_service.update_feature_flag(
            name=feature_name,
            status=status,
            rollout_percentage=request.rollout_percentage,
            target_users=request.target_users,
            target_roles=request.target_roles,
            target_regions=request.target_regions,
            device_types=request.device_types,
            metadata=request.metadata
        )
        
        if not feature_flag:
            raise HTTPException(status_code=404, detail="Feature flag not found")
        
        return FeatureFlagResponse(
            name=feature_flag.name,
            description=feature_flag.description,
            status=feature_flag.status.value,
            rollout_strategy=feature_flag.rollout_strategy.value,
            rollout_percentage=feature_flag.rollout_percentage,
            target_users=feature_flag.target_users,
            target_roles=feature_flag.target_roles,
            target_regions=feature_flag.target_regions,
            device_types=feature_flag.device_types,
            start_date=feature_flag.start_date,
            end_date=feature_flag.end_date,
            metadata=feature_flag.metadata,
            created_at=feature_flag.created_at,
            updated_at=feature_flag.updated_at
        )
        
    except Exception as e:
        logger.error(f"Error updating feature flag: {e}")
        raise HTTPException(status_code=500, detail="Failed to update feature flag")

@router.post("/check")
async def check_feature_flag(
    request: FeatureCheckRequest,
    feature_service: FeatureFlagService = Depends(get_feature_flag_service),
    current_user: User = Depends(get_current_user)
):
    """Verifica se uma feature está habilitada para o usuário atual"""
    try:
        is_enabled = await feature_service.is_feature_enabled(
            feature_name=request.feature_name,
            user=current_user,
            context=request.context
        )
        
        return {
            "feature_name": request.feature_name,
            "enabled": is_enabled,
            "user_id": current_user.id,
            "checked_at": datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Error checking feature flag: {e}")
        raise HTTPException(status_code=500, detail="Failed to check feature flag")

@router.get("/contextual/config", response_model=ContextualFeaturesResponse)
async def get_contextual_features_config(
    feature_service: FeatureFlagService = Depends(get_feature_flag_service),
    current_user: User = Depends(get_current_user)
):
    """Obtém configuração completa de features contextuais para o usuário atual"""
    try:
        config = await feature_service.get_contextual_feature_config(
            user=current_user
        )
        
        return ContextualFeaturesResponse(
            allocation_types_enabled=config.allocation_types_enabled,
            ui_components_enabled=config.ui_components_enabled,
            metrics_collection_enabled=config.metrics_collection_enabled,
            dual_context_enabled=config.dual_context_enabled,
            advanced_kpis_enabled=config.advanced_kpis_enabled,
            real_time_updates_enabled=config.real_time_updates_enabled,
            performance_monitoring_enabled=config.performance_monitoring_enabled
        )
        
    except Exception as e:
        logger.error(f"Error getting contextual features config: {e}")
        raise HTTPException(status_code=500, detail="Failed to get contextual features config")

@router.post("/contextual/initialize")
async def initialize_contextual_features(
    feature_service: FeatureFlagService = Depends(get_feature_flag_service),
    current_user: User = Depends(get_current_user)
):
    """Inicializa feature flags para contextualização"""
    try:
        # Apenas admins podem inicializar features
        if not current_user.is_admin:
            raise HTTPException(status_code=403, detail="Admin access required")
        
        await feature_service.initialize_contextual_features()
        
        return {
            "status": "success",
            "message": "Contextual features initialized successfully"
        }
        
    except Exception as e:
        logger.error(f"Error initializing contextual features: {e}")
        raise HTTPException(status_code=500, detail="Failed to initialize contextual features")

@router.post("/rollout/phase")
async def create_rollout_phase(
    request: RolloutPhaseRequest,
    feature_service: FeatureFlagService = Depends(get_feature_flag_service),
    current_user: User = Depends(get_current_user)
):
    """Cria uma nova fase de rollout"""
    try:
        # Apenas admins podem criar fases de rollout
        if not current_user.is_admin:
            raise HTTPException(status_code=403, detail="Admin access required")
        
        created_features = []
        
        for feature_name in request.features:
            try:
                feature_flag = await feature_service.get_feature_flag(feature_name)
                
                if feature_flag:
                    # Atualiza feature existente
                    await feature_service.update_feature_flag(
                        name=feature_name,
                        status=FeatureStatus.GRADUAL_ROLLOUT,
                        rollout_percentage=request.rollout_percentage,
                        target_roles=request.target_roles,
                        metadata={
                            'phase': request.phase_name,
                            'description': request.description
                        }
                    )
                    created_features.append(f"Updated: {feature_name}")
                else:
                    # Cria nova feature
                    await feature_service.create_feature_flag(
                        name=feature_name,
                        description=f"{feature_name} - {request.description}",
                        rollout_strategy=RolloutStrategy.HYBRID,
                        rollout_percentage=request.rollout_percentage,
                        target_roles=request.target_roles,
                        metadata={
                            'phase': request.phase_name,
                            'description': request.description
                        }
                    )
                    created_features.append(f"Created: {feature_name}")
                    
            except Exception as e:
                logger.error(f"Error processing feature {feature_name}: {e}")
                created_features.append(f"Error: {feature_name}")
        
        return {
            "status": "success",
            "phase_name": request.phase_name,
            "features_processed": created_features,
            "total_features": len(request.features)
        }
        
    except Exception as e:
        logger.error(f"Error creating rollout phase: {e}")
        raise HTTPException(status_code=500, detail="Failed to create rollout phase")

@router.get("/{feature_name}/analytics")
async def get_feature_analytics(
    feature_name: str,
    feature_service: FeatureFlagService = Depends(get_feature_flag_service),
    current_user: User = Depends(get_current_user)
):
    """Obtém analytics de uma feature flag"""
    try:
        # Apenas admins podem ver analytics
        if not current_user.is_admin:
            raise HTTPException(status_code=403, detail="Admin access required")
        
        analytics = await feature_service.get_feature_analytics(feature_name)
        
        return {
            "feature_name": feature_name,
            "analytics": analytics,
            "generated_at": datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Error getting feature analytics: {e}")
        raise HTTPException(status_code=500, detail="Failed to get feature analytics")

@router.put("/{feature_name}/enable")
async def enable_feature_flag(
    feature_name: str,
    feature_service: FeatureFlagService = Depends(get_feature_flag_service),
    current_user: User = Depends(get_current_user)
):
    """Habilita uma feature flag completamente"""
    try:
        # Apenas admins podem habilitar features
        if not current_user.is_admin:
            raise HTTPException(status_code=403, detail="Admin access required")
        
        feature_flag = await feature_service.update_feature_flag(
            name=feature_name,
            status=FeatureStatus.ENABLED,
            rollout_percentage=100.0
        )
        
        if not feature_flag:
            raise HTTPException(status_code=404, detail="Feature flag not found")
        
        return {
            "status": "success",
            "feature_name": feature_name,
            "message": "Feature flag enabled for all users"
        }
        
    except Exception as e:
        logger.error(f"Error enabling feature flag: {e}")
        raise HTTPException(status_code=500, detail="Failed to enable feature flag")

@router.put("/{feature_name}/disable")
async def disable_feature_flag(
    feature_name: str,
    feature_service: FeatureFlagService = Depends(get_feature_flag_service),
    current_user: User = Depends(get_current_user)
):
    """Desabilita uma feature flag completamente"""
    try:
        # Apenas admins podem desabilitar features
        if not current_user.is_admin:
            raise HTTPException(status_code=403, detail="Admin access required")
        
        feature_flag = await feature_service.update_feature_flag(
            name=feature_name,
            status=FeatureStatus.DISABLED,
            rollout_percentage=0.0
        )
        
        if not feature_flag:
            raise HTTPException(status_code=404, detail="Feature flag not found")
        
        return {
            "status": "success",
            "feature_name": feature_name,
            "message": "Feature flag disabled for all users"
        }
        
    except Exception as e:
        logger.error(f"Error disabling feature flag: {e}")
        raise HTTPException(status_code=500, detail="Failed to disable feature flag") 