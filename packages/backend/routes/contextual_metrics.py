"""
Endpoints para Métricas Contextuais
API para monitoramento e análise de performance do sistema de contextualização
"""

from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
import logging

from auth import get_current_user
from services.contextual_metrics_service import ContextualMetricsService
from models.user import User

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/contextual-metrics", tags=["contextual-metrics"])

# Pydantic Models
class MetricEventRequest(BaseModel):
    event_type: str = Field(..., description="Tipo do evento")
    category: str = Field(..., description="Categoria da métrica")
    entity_id: str = Field(..., description="ID da entidade")
    data: Dict[str, Any] = Field(..., description="Dados do evento")
    metadata: Optional[Dict[str, Any]] = Field(None, description="Metadados adicionais")

class AllocationEventRequest(BaseModel):
    case_id: str = Field(..., description="ID do caso")
    allocation_type: str = Field(..., description="Tipo de alocação")
    match_score: float = Field(..., ge=0, le=1, description="Score de match")
    sla_hours: int = Field(..., ge=1, description="SLA em horas")
    metadata: Optional[Dict[str, Any]] = Field(None, description="Metadados")

class EngagementEventRequest(BaseModel):
    interaction_type: str = Field(..., description="Tipo de interação")
    case_id: Optional[str] = Field(None, description="ID do caso")
    duration: Optional[float] = Field(None, ge=0, description="Duração em segundos")
    metadata: Optional[Dict[str, Any]] = Field(None, description="Metadados")

class AccuracyEventRequest(BaseModel):
    case_id: str = Field(..., description="ID do caso")
    allocation_type: str = Field(..., description="Tipo de alocação")
    predicted_score: float = Field(..., ge=0, le=1, description="Score previsto")
    actual_satisfaction: float = Field(..., ge=0, le=1, description="Satisfação real")
    metadata: Optional[Dict[str, Any]] = Field(None, description="Metadados")

class PartnershipEventRequest(BaseModel):
    case_id: str = Field(..., description="ID do caso")
    partnership_type: str = Field(..., description="Tipo de parceria")
    revenue: float = Field(..., ge=0, description="Receita gerada")
    partner_satisfaction: float = Field(..., ge=0, le=1, description="Satisfação do parceiro")
    client_satisfaction: float = Field(..., ge=0, le=1, description="Satisfação do cliente")
    completion_time: float = Field(..., ge=0, description="Tempo de conclusão")
    metadata: Optional[Dict[str, Any]] = Field(None, description="Metadados")

class DelegationEventRequest(BaseModel):
    case_id: str = Field(..., description="ID do caso")
    delegation_reason: str = Field(..., description="Razão da delegação")
    delegation_time: float = Field(..., ge=0, description="Tempo de delegação")
    delegated_to: str = Field(..., description="ID do delegado")
    success: bool = Field(..., description="Sucesso da delegação")
    metadata: Optional[Dict[str, Any]] = Field(None, description="Metadados")

class MetricFilters(BaseModel):
    start_date: Optional[datetime] = Field(None, description="Data de início")
    end_date: Optional[datetime] = Field(None, description="Data de fim")
    allocation_type: Optional[str] = Field(None, description="Tipo de alocação")
    user_role: Optional[str] = Field(None, description="Função do usuário")

class DashboardResponse(BaseModel):
    summary: Dict[str, Any] = Field(..., description="Resumo das métricas")
    allocation_breakdown: Dict[str, Any] = Field(..., description="Breakdown por tipo de alocação")
    temporal_trends: List[Dict[str, Any]] = Field(..., description="Tendências temporais")
    engagement_summary: Dict[str, Any] = Field(..., description="Resumo de engajamento")
    accuracy_summary: Dict[str, Any] = Field(..., description="Resumo de precisão")

# Dependency
def get_metrics_service():
    return ContextualMetricsService()

@router.post("/events/allocation")
async def record_allocation_event(
    request: AllocationEventRequest,
    metrics_service: ContextualMetricsService = Depends(get_metrics_service),
    current_user: User = Depends(get_current_user)
):
    """Registra evento de alocação de caso"""
    try:
        await metrics_service.record_allocation_event(
            case_id=request.case_id,
            allocation_type=request.allocation_type,
            match_score=request.match_score,
            sla_hours=request.sla_hours,
            user_id=current_user.id,
            metadata=request.metadata
        )
        
        return {"status": "success", "message": "Allocation event recorded"}
        
    except Exception as e:
        logger.error(f"Error recording allocation event: {e}")
        raise HTTPException(status_code=500, detail="Failed to record allocation event")

@router.post("/events/engagement")
async def record_engagement_event(
    request: EngagementEventRequest,
    metrics_service: ContextualMetricsService = Depends(get_metrics_service),
    current_user: User = Depends(get_current_user)
):
    """Registra evento de engajamento do usuário"""
    try:
        await metrics_service.record_engagement_event(
            user_id=current_user.id,
            user_role=current_user.role,
            interaction_type=request.interaction_type,
            case_id=request.case_id,
            duration=request.duration,
            metadata=request.metadata
        )
        
        return {"status": "success", "message": "Engagement event recorded"}
        
    except Exception as e:
        logger.error(f"Error recording engagement event: {e}")
        raise HTTPException(status_code=500, detail="Failed to record engagement event")

@router.post("/events/accuracy")
async def record_accuracy_event(
    request: AccuracyEventRequest,
    metrics_service: ContextualMetricsService = Depends(get_metrics_service),
    current_user: User = Depends(get_current_user)
):
    """Registra evento de precisão contextual"""
    try:
        await metrics_service.record_accuracy_event(
            case_id=request.case_id,
            allocation_type=request.allocation_type,
            predicted_score=request.predicted_score,
            actual_satisfaction=request.actual_satisfaction,
            metadata=request.metadata
        )
        
        return {"status": "success", "message": "Accuracy event recorded"}
        
    except Exception as e:
        logger.error(f"Error recording accuracy event: {e}")
        raise HTTPException(status_code=500, detail="Failed to record accuracy event")

@router.post("/events/partnership")
async def record_partnership_event(
    request: PartnershipEventRequest,
    metrics_service: ContextualMetricsService = Depends(get_metrics_service),
    current_user: User = Depends(get_current_user)
):
    """Registra evento de parceria"""
    try:
        await metrics_service.record_partnership_event(
            case_id=request.case_id,
            partnership_type=request.partnership_type,
            revenue=request.revenue,
            partner_satisfaction=request.partner_satisfaction,
            client_satisfaction=request.client_satisfaction,
            completion_time=request.completion_time,
            metadata=request.metadata
        )
        
        return {"status": "success", "message": "Partnership event recorded"}
        
    except Exception as e:
        logger.error(f"Error recording partnership event: {e}")
        raise HTTPException(status_code=500, detail="Failed to record partnership event")

@router.post("/events/delegation")
async def record_delegation_event(
    request: DelegationEventRequest,
    metrics_service: ContextualMetricsService = Depends(get_metrics_service),
    current_user: User = Depends(get_current_user)
):
    """Registra evento de delegação"""
    try:
        await metrics_service.record_delegation_event(
            case_id=request.case_id,
            delegation_reason=request.delegation_reason,
            delegation_time=request.delegation_time,
            delegated_by=current_user.id,
            delegated_to=request.delegated_to,
            success=request.success,
            metadata=request.metadata
        )
        
        return {"status": "success", "message": "Delegation event recorded"}
        
    except Exception as e:
        logger.error(f"Error recording delegation event: {e}")
        raise HTTPException(status_code=500, detail="Failed to record delegation event")

@router.get("/allocation", response_model=List[Dict[str, Any]])
async def get_allocation_metrics(
    start_date: Optional[datetime] = Query(None, description="Data de início"),
    end_date: Optional[datetime] = Query(None, description="Data de fim"),
    allocation_type: Optional[str] = Query(None, description="Tipo de alocação"),
    metrics_service: ContextualMetricsService = Depends(get_metrics_service),
    current_user: User = Depends(get_current_user)
):
    """Obtém métricas de alocação"""
    try:
        # Default to last 24 hours if no dates provided
        if not start_date:
            start_date = datetime.utcnow() - timedelta(hours=24)
        if not end_date:
            end_date = datetime.utcnow()
        
        metrics = await metrics_service.get_allocation_metrics(
            start_date=start_date,
            end_date=end_date,
            allocation_type=allocation_type
        )
        
        return [
            {
                "allocation_type": m.allocation_type,
                "total_cases": m.total_cases,
                "successful_allocations": m.successful_allocations,
                "failed_allocations": m.failed_allocations,
                "average_sla_compliance": m.average_sla_compliance,
                "average_match_score": m.average_match_score,
                "average_response_time": m.average_response_time,
                "conversion_rate": m.conversion_rate,
                "created_at": m.created_at.isoformat()
            }
            for m in metrics
        ]
        
    except Exception as e:
        logger.error(f"Error getting allocation metrics: {e}")
        raise HTTPException(status_code=500, detail="Failed to get allocation metrics")

@router.get("/engagement", response_model=List[Dict[str, Any]])
async def get_engagement_metrics(
    start_date: Optional[datetime] = Query(None, description="Data de início"),
    end_date: Optional[datetime] = Query(None, description="Data de fim"),
    user_role: Optional[str] = Query(None, description="Função do usuário"),
    metrics_service: ContextualMetricsService = Depends(get_metrics_service),
    current_user: User = Depends(get_current_user)
):
    """Obtém métricas de engajamento"""
    try:
        # Default to last 24 hours if no dates provided
        if not start_date:
            start_date = datetime.utcnow() - timedelta(hours=24)
        if not end_date:
            end_date = datetime.utcnow()
        
        metrics = await metrics_service.get_engagement_metrics(
            start_date=start_date,
            end_date=end_date,
            user_role=user_role
        )
        
        return [
            {
                "user_role": m.user_role,
                "total_interactions": m.total_interactions,
                "contextual_views": m.contextual_views,
                "action_clicks": m.action_clicks,
                "highlight_views": m.highlight_views,
                "kpi_views": m.kpi_views,
                "time_spent_seconds": m.time_spent_seconds,
                "session_duration": m.session_duration,
                "bounce_rate": m.bounce_rate,
                "created_at": m.created_at.isoformat()
            }
            for m in metrics
        ]
        
    except Exception as e:
        logger.error(f"Error getting engagement metrics: {e}")
        raise HTTPException(status_code=500, detail="Failed to get engagement metrics")

@router.get("/accuracy", response_model=List[Dict[str, Any]])
async def get_accuracy_metrics(
    start_date: Optional[datetime] = Query(None, description="Data de início"),
    end_date: Optional[datetime] = Query(None, description="Data de fim"),
    allocation_type: Optional[str] = Query(None, description="Tipo de alocação"),
    metrics_service: ContextualMetricsService = Depends(get_metrics_service),
    current_user: User = Depends(get_current_user)
):
    """Obtém métricas de precisão"""
    try:
        # Default to last 24 hours if no dates provided
        if not start_date:
            start_date = datetime.utcnow() - timedelta(hours=24)
        if not end_date:
            end_date = datetime.utcnow()
        
        metrics = await metrics_service.get_accuracy_metrics(
            start_date=start_date,
            end_date=end_date,
            allocation_type=allocation_type
        )
        
        return [
            {
                "allocation_type": m.allocation_type,
                "predicted_match_score": m.predicted_match_score,
                "actual_satisfaction": m.actual_satisfaction,
                "accuracy_score": m.accuracy_score,
                "false_positive_rate": m.false_positive_rate,
                "false_negative_rate": m.false_negative_rate,
                "precision": m.precision,
                "recall": m.recall,
                "f1_score": m.f1_score,
                "created_at": m.created_at.isoformat()
            }
            for m in metrics
        ]
        
    except Exception as e:
        logger.error(f"Error getting accuracy metrics: {e}")
        raise HTTPException(status_code=500, detail="Failed to get accuracy metrics")

@router.get("/dashboard", response_model=DashboardResponse)
async def get_contextual_dashboard(
    start_date: Optional[datetime] = Query(None, description="Data de início"),
    end_date: Optional[datetime] = Query(None, description="Data de fim"),
    metrics_service: ContextualMetricsService = Depends(get_metrics_service),
    current_user: User = Depends(get_current_user)
):
    """Obtém dados completos para dashboard contextual"""
    try:
        # Default to last 24 hours if no dates provided
        if not start_date:
            start_date = datetime.utcnow() - timedelta(hours=24)
        if not end_date:
            end_date = datetime.utcnow()
        
        dashboard_data = await metrics_service.get_contextual_dashboard_data(
            start_date=start_date,
            end_date=end_date
        )
        
        return DashboardResponse(**dashboard_data)
        
    except Exception as e:
        logger.error(f"Error getting dashboard data: {e}")
        raise HTTPException(status_code=500, detail="Failed to get dashboard data")

@router.get("/performance/allocation-types")
async def get_allocation_type_performance(
    start_date: Optional[datetime] = Query(None, description="Data de início"),
    end_date: Optional[datetime] = Query(None, description="Data de fim"),
    metrics_service: ContextualMetricsService = Depends(get_metrics_service),
    current_user: User = Depends(get_current_user)
):
    """Obtém performance por tipo de alocação"""
    try:
        # Default to last 7 days if no dates provided
        if not start_date:
            start_date = datetime.utcnow() - timedelta(days=7)
        if not end_date:
            end_date = datetime.utcnow()
        
        allocation_types = [
            "platform_match_direct",
            "platform_match_partnership", 
            "partnership_proactive_search",
            "partnership_platform_suggestion",
            "internal_delegation"
        ]
        
        performance_data = {}
        
        for allocation_type in allocation_types:
            metrics = await metrics_service.get_allocation_metrics(
                start_date=start_date,
                end_date=end_date,
                allocation_type=allocation_type
            )
            
            if metrics:
                total_cases = sum(m.total_cases for m in metrics)
                successful_cases = sum(m.successful_allocations for m in metrics)
                avg_match_score = sum(m.average_match_score * m.total_cases for m in metrics) / total_cases if total_cases > 0 else 0
                avg_response_time = sum(m.average_response_time * m.total_cases for m in metrics) / total_cases if total_cases > 0 else 0
                
                performance_data[allocation_type] = {
                    "total_cases": total_cases,
                    "success_rate": successful_cases / total_cases if total_cases > 0 else 0,
                    "average_match_score": round(avg_match_score, 2),
                    "average_response_time": round(avg_response_time, 2),
                    "efficiency_score": round((successful_cases / total_cases) * avg_match_score, 2) if total_cases > 0 else 0
                }
            else:
                performance_data[allocation_type] = {
                    "total_cases": 0,
                    "success_rate": 0.0,
                    "average_match_score": 0.0,
                    "average_response_time": 0.0,
                    "efficiency_score": 0.0
                }
        
        return {
            "period": {
                "start": start_date.isoformat(),
                "end": end_date.isoformat()
            },
            "performance_by_type": performance_data
        }
        
    except Exception as e:
        logger.error(f"Error getting allocation type performance: {e}")
        raise HTTPException(status_code=500, detail="Failed to get allocation type performance")

@router.get("/analytics/trends")
async def get_contextual_trends(
    start_date: Optional[datetime] = Query(None, description="Data de início"),
    end_date: Optional[datetime] = Query(None, description="Data de fim"),
    granularity: str = Query("hour", description="Granularidade (hour, day, week)"),
    metrics_service: ContextualMetricsService = Depends(get_metrics_service),
    current_user: User = Depends(get_current_user)
):
    """Obtém tendências temporais das métricas contextuais"""
    try:
        # Default to last 24 hours if no dates provided
        if not start_date:
            start_date = datetime.utcnow() - timedelta(hours=24)
        if not end_date:
            end_date = datetime.utcnow()
        
        allocation_metrics = await metrics_service.get_allocation_metrics(
            start_date=start_date,
            end_date=end_date
        )
        
        engagement_metrics = await metrics_service.get_engagement_metrics(
            start_date=start_date,
            end_date=end_date
        )
        
        accuracy_metrics = await metrics_service.get_accuracy_metrics(
            start_date=start_date,
            end_date=end_date
        )
        
        # Group metrics by time periods
        trends = {}
        
        for metric in allocation_metrics:
            timestamp = metric.created_at.isoformat()
            if timestamp not in trends:
                trends[timestamp] = {
                    "timestamp": timestamp,
                    "total_cases": 0,
                    "success_rate": 0.0,
                    "avg_match_score": 0.0,
                    "avg_response_time": 0.0,
                    "total_interactions": 0,
                    "overall_accuracy": 0.0
                }
            
            trends[timestamp]["total_cases"] += metric.total_cases
            trends[timestamp]["success_rate"] = metric.successful_allocations / metric.total_cases if metric.total_cases > 0 else 0
            trends[timestamp]["avg_match_score"] = metric.average_match_score
            trends[timestamp]["avg_response_time"] = metric.average_response_time
        
        for metric in engagement_metrics:
            timestamp = metric.created_at.isoformat()
            if timestamp in trends:
                trends[timestamp]["total_interactions"] += metric.total_interactions
        
        for metric in accuracy_metrics:
            timestamp = metric.created_at.isoformat()
            if timestamp in trends:
                trends[timestamp]["overall_accuracy"] = metric.accuracy_score
        
        return {
            "period": {
                "start": start_date.isoformat(),
                "end": end_date.isoformat()
            },
            "granularity": granularity,
            "trends": list(trends.values())
        }
        
    except Exception as e:
        logger.error(f"Error getting contextual trends: {e}")
        raise HTTPException(status_code=500, detail="Failed to get contextual trends")

@router.delete("/cleanup")
async def cleanup_old_metrics(
    retention_days: int = Query(90, ge=1, le=365, description="Dias de retenção"),
    metrics_service: ContextualMetricsService = Depends(get_metrics_service),
    current_user: User = Depends(get_current_user)
):
    """Remove métricas antigas baseado na política de retenção"""
    try:
        # Only admin users can cleanup metrics
        if not current_user.is_admin:
            raise HTTPException(status_code=403, detail="Admin access required")
        
        await metrics_service.cleanup_old_metrics(retention_days=retention_days)
        
        return {
            "status": "success",
            "message": f"Cleaned up metrics older than {retention_days} days"
        }
        
    except Exception as e:
        logger.error(f"Error cleaning up metrics: {e}")
        raise HTTPException(status_code=500, detail="Failed to cleanup metrics") 