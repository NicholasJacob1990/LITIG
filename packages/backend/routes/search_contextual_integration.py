"""
Endpoints para Integração: Busca e Contextualização
API para conectar sistema de busca com contextualização
"""

from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
import logging

from ..auth import get_current_user
from ..services.search_contextual_integration_service import (
    SearchContextualIntegrationService,
    SearchMatchResult,
    SearchMatchType,
    SearchOrigin
)
from ..models.user import User

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/search-contextual", tags=["search-contextual"])

# Pydantic Models
class SearchMatchRequest(BaseModel):
    match_id: str = Field(..., description="ID único do match")
    lawyer_id: str = Field(..., description="ID do advogado")
    client_id: str = Field(..., description="ID do cliente")
    match_type: str = Field(..., description="Tipo de match")
    search_origin: str = Field(..., description="Origem da busca")
    match_score: float = Field(..., ge=0, le=1, description="Score do match")
    search_query: str = Field(..., description="Query de busca")
    search_filters: Dict[str, Any] = Field(default_factory=dict, description="Filtros aplicados")
    search_context: Dict[str, Any] = Field(default_factory=dict, description="Contexto da busca")
    preset_used: Optional[str] = Field(None, description="Preset utilizado")
    coordinates: Optional[Dict[str, float]] = Field(None, description="Coordenadas de busca")
    proximity_radius: Optional[float] = Field(None, description="Raio de proximidade")
    partnership_id: Optional[str] = Field(None, description="ID da parceria")
    firm_id: Optional[str] = Field(None, description="ID do escritório")
    case_id: Optional[str] = Field(None, description="ID do caso (se existente)")

class BulkSearchMatchRequest(BaseModel):
    matches: List[SearchMatchRequest] = Field(..., description="Lista de matches")

class SearchAllocationAnalyticsRequest(BaseModel):
    start_date: datetime = Field(..., description="Data de início")
    end_date: datetime = Field(..., description="Data de fim")
    search_origin: Optional[str] = Field(None, description="Origem da busca")
    match_type: Optional[str] = Field(None, description="Tipo de match")

class PresetAllocationRequest(BaseModel):
    preset_name: str = Field(..., description="Nome do preset")
    allocation_type: str = Field(..., description="Tipo de alocação")
    sla_hours: int = Field(..., ge=1, description="SLA em horas")
    priority_level: int = Field(..., ge=1, le=5, description="Nível de prioridade")

class SearchMatchResponse(BaseModel):
    case_id: str
    allocation_type: str
    match_score: float
    sla_hours: int
    priority_level: int
    contextual_data: Optional[Dict[str, Any]]
    search_context: Dict[str, Any]

class SearchAllocationAnalyticsResponse(BaseModel):
    period: Dict[str, str]
    total_matches: int
    breakdown: List[Dict[str, Any]]
    summary: Dict[str, Any]

# Dependency
def get_search_integration_service():
    return SearchContextualIntegrationService()

@router.post("/process-match", response_model=SearchMatchResponse)
async def process_search_match(
    request: SearchMatchRequest,
    integration_service: SearchContextualIntegrationService = Depends(get_search_integration_service),
    current_user: User = Depends(get_current_user)
):
    """Processa um match de busca e registra contexto de alocação"""
    try:
        # Valida enums
        try:
            match_type = SearchMatchType(request.match_type)
            search_origin = SearchOrigin(request.search_origin)
        except ValueError as e:
            raise HTTPException(status_code=400, detail=f"Invalid enum value: {e}")
        
        # Cria objeto SearchMatchResult
        search_result = SearchMatchResult(
            match_id=request.match_id,
            lawyer_id=request.lawyer_id,
            client_id=request.client_id,
            match_type=match_type,
            search_origin=search_origin,
            match_score=request.match_score,
            search_query=request.search_query,
            search_filters=request.search_filters,
            search_context=request.search_context,
            preset_used=request.preset_used,
            coordinates=request.coordinates,
            proximity_radius=request.proximity_radius,
            partnership_id=request.partnership_id,
            firm_id=request.firm_id,
            created_at=datetime.utcnow()
        )
        
        # Processa match
        result = await integration_service.process_search_match(
            search_result=search_result,
            user=current_user,
            case_id=request.case_id
        )
        
        return SearchMatchResponse(
            case_id=result['case_id'],
            allocation_type=result['allocation_type'],
            match_score=result['match_score'],
            sla_hours=result['sla_hours'],
            priority_level=result['priority_level'],
            contextual_data=result.get('contextual_data'),
            search_context=result['search_context']
        )
        
    except Exception as e:
        logger.error(f"Error processing search match: {e}")
        raise HTTPException(status_code=500, detail="Failed to process search match")

@router.post("/process-bulk-matches", response_model=List[SearchMatchResponse])
async def process_bulk_search_matches(
    request: BulkSearchMatchRequest,
    integration_service: SearchContextualIntegrationService = Depends(get_search_integration_service),
    current_user: User = Depends(get_current_user)
):
    """Processa múltiplos matches de busca em lote"""
    try:
        search_results = []
        
        for match_request in request.matches:
            try:
                match_type = SearchMatchType(match_request.match_type)
                search_origin = SearchOrigin(match_request.search_origin)
                
                search_result = SearchMatchResult(
                    match_id=match_request.match_id,
                    lawyer_id=match_request.lawyer_id,
                    client_id=match_request.client_id,
                    match_type=match_type,
                    search_origin=search_origin,
                    match_score=match_request.match_score,
                    search_query=match_request.search_query,
                    search_filters=match_request.search_filters,
                    search_context=match_request.search_context,
                    preset_used=match_request.preset_used,
                    coordinates=match_request.coordinates,
                    proximity_radius=match_request.proximity_radius,
                    partnership_id=match_request.partnership_id,
                    firm_id=match_request.firm_id,
                    created_at=datetime.utcnow()
                )
                
                search_results.append(search_result)
                
            except ValueError as e:
                logger.error(f"Invalid enum value in bulk request: {e}")
                continue
        
        # Processa matches em lote
        results = await integration_service.process_bulk_search_matches(
            search_results=search_results,
            user=current_user
        )
        
        return [
            SearchMatchResponse(
                case_id=result['case_id'],
                allocation_type=result['allocation_type'],
                match_score=result['match_score'],
                sla_hours=result['sla_hours'],
                priority_level=result['priority_level'],
                contextual_data=result.get('contextual_data'),
                search_context=result['search_context']
            )
            for result in results
        ]
        
    except Exception as e:
        logger.error(f"Error processing bulk search matches: {e}")
        raise HTTPException(status_code=500, detail="Failed to process bulk search matches")

@router.post("/analytics", response_model=SearchAllocationAnalyticsResponse)
async def get_search_allocation_analytics(
    request: SearchAllocationAnalyticsRequest,
    integration_service: SearchContextualIntegrationService = Depends(get_search_integration_service),
    current_user: User = Depends(get_current_user)
):
    """Obtém analytics de alocação por busca"""
    try:
        # Apenas admins podem ver analytics
        if not current_user.is_admin:
            raise HTTPException(status_code=403, detail="Admin access required")
        
        # Valida enums opcionais
        search_origin = None
        match_type = None
        
        if request.search_origin:
            try:
                search_origin = SearchOrigin(request.search_origin)
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid search origin")
        
        if request.match_type:
            try:
                match_type = SearchMatchType(request.match_type)
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid match type")
        
        analytics = await integration_service.get_search_allocation_analytics(
            start_date=request.start_date,
            end_date=request.end_date,
            search_origin=search_origin,
            match_type=match_type
        )
        
        return SearchAllocationAnalyticsResponse(
            period=analytics.get('period', {}),
            total_matches=analytics.get('total_matches', 0),
            breakdown=analytics.get('breakdown', []),
            summary=analytics.get('summary', {})
        )
        
    except Exception as e:
        logger.error(f"Error getting search allocation analytics: {e}")
        raise HTTPException(status_code=500, detail="Failed to get search allocation analytics")

@router.put("/preset-allocation")
async def update_preset_allocation(
    request: PresetAllocationRequest,
    integration_service: SearchContextualIntegrationService = Depends(get_search_integration_service),
    current_user: User = Depends(get_current_user)
):
    """Atualiza configuração de alocação para preset de busca"""
    try:
        # Apenas admins podem atualizar presets
        if not current_user.is_admin:
            raise HTTPException(status_code=403, detail="Admin access required")
        
        success = await integration_service.update_search_preset_allocation(
            preset_name=request.preset_name,
            allocation_type=request.allocation_type,
            sla_hours=request.sla_hours,
            priority_level=request.priority_level
        )
        
        if not success:
            raise HTTPException(status_code=500, detail="Failed to update preset allocation")
        
        return {
            "status": "success",
            "message": f"Preset allocation updated for {request.preset_name}"
        }
        
    except Exception as e:
        logger.error(f"Error updating preset allocation: {e}")
        raise HTTPException(status_code=500, detail="Failed to update preset allocation")

@router.get("/allocation-types")
async def get_allocation_types(
    current_user: User = Depends(get_current_user)
):
    """Retorna tipos de alocação disponíveis baseados na busca"""
    try:
        allocation_types = {
            "platform_match_direct": {
                "description": "Match direto da plataforma",
                "typical_origins": ["client_search"],
                "typical_types": ["semantic_match", "directory_match"],
                "default_sla_hours": 24,
                "priority_level": 1
            },
            "platform_match_partnership": {
                "description": "Match da plataforma com parceria",
                "typical_origins": ["partnership_search"],
                "typical_types": ["hybrid_match", "semantic_match"],
                "default_sla_hours": 48,
                "priority_level": 2
            },
            "partnership_proactive_search": {
                "description": "Busca proativa por parceria",
                "typical_origins": ["lawyer_search", "proactive_search"],
                "typical_types": ["directory_match", "preset_match"],
                "default_sla_hours": 72,
                "priority_level": 3
            },
            "partnership_platform_suggestion": {
                "description": "Sugestão da plataforma via parceria",
                "typical_origins": ["platform_suggestion"],
                "typical_types": ["ai_recommendation"],
                "default_sla_hours": 48,
                "priority_level": 3
            },
            "internal_delegation": {
                "description": "Delegação interna de escritório",
                "typical_origins": ["firm_search"],
                "typical_types": ["directory_match"],
                "default_sla_hours": 48,
                "priority_level": 2
            }
        }
        
        return {
            "allocation_types": allocation_types,
            "search_origins": [origin.value for origin in SearchOrigin],
            "match_types": [match_type.value for match_type in SearchMatchType]
        }
        
    except Exception as e:
        logger.error(f"Error getting allocation types: {e}")
        raise HTTPException(status_code=500, detail="Failed to get allocation types")

@router.get("/search-origins")
async def get_search_origins(
    current_user: User = Depends(get_current_user)
):
    """Retorna origens de busca disponíveis"""
    try:
        origins = {
            "client_search": {
                "description": "Busca iniciada pelo cliente",
                "typical_allocation": "platform_match_direct",
                "user_roles": ["cliente"]
            },
            "lawyer_search": {
                "description": "Busca iniciada pelo advogado",
                "typical_allocation": "partnership_proactive_search",
                "user_roles": ["advogado"]
            },
            "firm_search": {
                "description": "Busca iniciada pelo escritório",
                "typical_allocation": "internal_delegation",
                "user_roles": ["escritorio", "admin"]
            },
            "platform_suggestion": {
                "description": "Sugestão automática da plataforma",
                "typical_allocation": "partnership_platform_suggestion",
                "user_roles": ["system"]
            },
            "partnership_search": {
                "description": "Busca através de parceria",
                "typical_allocation": "platform_match_partnership",
                "user_roles": ["advogado", "escritorio"]
            },
            "proactive_search": {
                "description": "Busca proativa do advogado",
                "typical_allocation": "partnership_proactive_search",
                "user_roles": ["advogado"]
            }
        }
        
        return {
            "search_origins": origins,
            "user_role": current_user.role
        }
        
    except Exception as e:
        logger.error(f"Error getting search origins: {e}")
        raise HTTPException(status_code=500, detail="Failed to get search origins")

@router.get("/match-types")
async def get_match_types(
    current_user: User = Depends(get_current_user)
):
    """Retorna tipos de match disponíveis"""
    try:
        match_types = {
            "semantic_match": {
                "description": "Match baseado em análise semântica",
                "typical_score_range": [0.7, 1.0],
                "features": ["nlp", "embedding", "similarity"]
            },
            "directory_match": {
                "description": "Match baseado em filtros de diretório",
                "typical_score_range": [0.5, 0.9],
                "features": ["filters", "criteria", "exact_match"]
            },
            "hybrid_match": {
                "description": "Match combinando semântica e filtros",
                "typical_score_range": [0.6, 1.0],
                "features": ["semantic", "filters", "weighted"]
            },
            "preset_match": {
                "description": "Match usando preset configurado",
                "typical_score_range": [0.4, 0.8],
                "features": ["preset", "template", "predefined"]
            },
            "ai_recommendation": {
                "description": "Recomendação baseada em IA",
                "typical_score_range": [0.8, 1.0],
                "features": ["ai", "ml", "recommendation"]
            },
            "proximity_match": {
                "description": "Match baseado em proximidade geográfica",
                "typical_score_range": [0.3, 0.7],
                "features": ["location", "distance", "geographic"]
            }
        }
        
        return {
            "match_types": match_types
        }
        
    except Exception as e:
        logger.error(f"Error getting match types: {e}")
        raise HTTPException(status_code=500, detail="Failed to get match types")

@router.get("/integration-status")
async def get_integration_status(
    integration_service: SearchContextualIntegrationService = Depends(get_search_integration_service),
    current_user: User = Depends(get_current_user)
):
    """Retorna status da integração entre busca e contextualização"""
    try:
        # Apenas admins podem ver status de integração
        if not current_user.is_admin:
            raise HTTPException(status_code=403, detail="Admin access required")
        
        # Verifica se features contextuais estão habilitadas
        contextual_config = await integration_service.feature_flag_service.get_contextual_feature_config(
            user=current_user
        )
        
        status = {
            "integration_active": True,
            "contextual_features": {
                "allocation_types_enabled": contextual_config.allocation_types_enabled,
                "metrics_collection_enabled": contextual_config.metrics_collection_enabled,
                "performance_monitoring_enabled": contextual_config.performance_monitoring_enabled
            },
            "search_mappings_count": len(integration_service.search_mappings),
            "supported_origins": [origin.value for origin in SearchOrigin],
            "supported_match_types": [match_type.value for match_type in SearchMatchType],
            "last_updated": datetime.utcnow().isoformat()
        }
        
        return status
        
    except Exception as e:
        logger.error(f"Error getting integration status: {e}")
        raise HTTPException(status_code=500, detail="Failed to get integration status") 