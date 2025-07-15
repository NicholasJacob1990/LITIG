"""
Serviço de Métricas Contextuais
Monitora performance e KPIs do sistema de contextualização de casos
"""

from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
import json
from dataclasses import dataclass, asdict
from enum import Enum
import logging

from ..models.case import Case
from ..models.user import User
from ..models.metrics import MetricEvent, MetricType
from ..database import get_db_connection
from ..utils.cache import cache_result
from ..utils.analytics import track_event

logger = logging.getLogger(__name__)

class MetricCategory(Enum):
    """Categorias de métricas contextuais"""
    ALLOCATION_PERFORMANCE = "allocation_performance"
    USER_ENGAGEMENT = "user_engagement"
    CONTEXTUAL_ACCURACY = "contextual_accuracy"
    RESPONSE_TIME = "response_time"
    SATISFACTION = "satisfaction"
    CONVERSION = "conversion"
    PARTNERSHIP_EFFECTIVENESS = "partnership_effectiveness"
    DELEGATION_EFFICIENCY = "delegation_efficiency"

@dataclass
class AllocationMetric:
    """Métricas de alocação de casos"""
    allocation_type: str
    total_cases: int
    successful_allocations: int
    failed_allocations: int
    average_sla_compliance: float
    average_match_score: float
    average_response_time: float
    conversion_rate: float
    created_at: datetime

@dataclass
class EngagementMetric:
    """Métricas de engajamento do usuário"""
    user_role: str
    total_interactions: int
    contextual_views: int
    action_clicks: int
    highlight_views: int
    kpi_views: int
    time_spent_seconds: float
    session_duration: float
    bounce_rate: float
    created_at: datetime

@dataclass
class AccuracyMetric:
    """Métricas de precisão contextual"""
    allocation_type: str
    predicted_match_score: float
    actual_satisfaction: float
    accuracy_score: float
    false_positive_rate: float
    false_negative_rate: float
    precision: float
    recall: float
    f1_score: float
    created_at: datetime

@dataclass
class PartnershipMetric:
    """Métricas de eficácia de parcerias"""
    partnership_type: str
    total_cases: int
    successful_matches: int
    revenue_generated: float
    partner_satisfaction: float
    client_satisfaction: float
    average_completion_time: float
    repeat_collaborations: int
    created_at: datetime

@dataclass
class DelegationMetric:
    """Métricas de eficiência de delegação"""
    delegation_reason: str
    total_delegations: int
    successful_delegations: int
    average_delegation_time: float
    delegation_accuracy: float
    workload_distribution: float
    senior_satisfaction: float
    junior_satisfaction: float
    created_at: datetime

class ContextualMetricsService:
    """Serviço para coleta e análise de métricas contextuais"""
    
    def __init__(self):
        self.db = get_db_connection()
    
    async def record_allocation_event(
        self,
        case_id: str,
        allocation_type: str,
        match_score: float,
        sla_hours: int,
        user_id: str,
        metadata: Optional[Dict[str, Any]] = None
    ) -> None:
        """Registra evento de alocação de caso"""
        try:
            event = MetricEvent(
                event_type=MetricType.CASE_ALLOCATION,
                category=MetricCategory.ALLOCATION_PERFORMANCE.value,
                entity_id=case_id,
                user_id=user_id,
                data={
                    'allocation_type': allocation_type,
                    'match_score': match_score,
                    'sla_hours': sla_hours,
                    'metadata': metadata or {}
                },
                timestamp=datetime.utcnow()
            )
            
            await self._store_metric_event(event)
            
            # Track in analytics
            await track_event('case_allocation', {
                'allocation_type': allocation_type,
                'match_score': match_score,
                'sla_hours': sla_hours,
                'user_id': user_id
            })
            
            logger.info(f"Allocation event recorded for case {case_id}")
            
        except Exception as e:
            logger.error(f"Error recording allocation event: {e}")
    
    async def record_engagement_event(
        self,
        user_id: str,
        user_role: str,
        interaction_type: str,
        case_id: Optional[str] = None,
        duration: Optional[float] = None,
        metadata: Optional[Dict[str, Any]] = None
    ) -> None:
        """Registra evento de engajamento do usuário"""
        try:
            event = MetricEvent(
                event_type=MetricType.USER_ENGAGEMENT,
                category=MetricCategory.USER_ENGAGEMENT.value,
                entity_id=case_id or user_id,
                user_id=user_id,
                data={
                    'user_role': user_role,
                    'interaction_type': interaction_type,
                    'duration': duration,
                    'metadata': metadata or {}
                },
                timestamp=datetime.utcnow()
            )
            
            await self._store_metric_event(event)
            
            # Track in analytics
            await track_event('user_engagement', {
                'user_role': user_role,
                'interaction_type': interaction_type,
                'duration': duration,
                'user_id': user_id
            })
            
            logger.info(f"Engagement event recorded for user {user_id}")
            
        except Exception as e:
            logger.error(f"Error recording engagement event: {e}")
    
    async def record_accuracy_event(
        self,
        case_id: str,
        allocation_type: str,
        predicted_score: float,
        actual_satisfaction: float,
        metadata: Optional[Dict[str, Any]] = None
    ) -> None:
        """Registra evento de precisão contextual"""
        try:
            # Calcula métricas de precisão
            accuracy_score = 1.0 - abs(predicted_score - actual_satisfaction)
            
            event = MetricEvent(
                event_type=MetricType.CONTEXTUAL_ACCURACY,
                category=MetricCategory.CONTEXTUAL_ACCURACY.value,
                entity_id=case_id,
                user_id=None,
                data={
                    'allocation_type': allocation_type,
                    'predicted_score': predicted_score,
                    'actual_satisfaction': actual_satisfaction,
                    'accuracy_score': accuracy_score,
                    'metadata': metadata or {}
                },
                timestamp=datetime.utcnow()
            )
            
            await self._store_metric_event(event)
            
            logger.info(f"Accuracy event recorded for case {case_id}")
            
        except Exception as e:
            logger.error(f"Error recording accuracy event: {e}")
    
    async def record_partnership_event(
        self,
        case_id: str,
        partnership_type: str,
        revenue: float,
        partner_satisfaction: float,
        client_satisfaction: float,
        completion_time: float,
        metadata: Optional[Dict[str, Any]] = None
    ) -> None:
        """Registra evento de parceria"""
        try:
            event = MetricEvent(
                event_type=MetricType.PARTNERSHIP_EFFECTIVENESS,
                category=MetricCategory.PARTNERSHIP_EFFECTIVENESS.value,
                entity_id=case_id,
                user_id=None,
                data={
                    'partnership_type': partnership_type,
                    'revenue': revenue,
                    'partner_satisfaction': partner_satisfaction,
                    'client_satisfaction': client_satisfaction,
                    'completion_time': completion_time,
                    'metadata': metadata or {}
                },
                timestamp=datetime.utcnow()
            )
            
            await self._store_metric_event(event)
            
            logger.info(f"Partnership event recorded for case {case_id}")
            
        except Exception as e:
            logger.error(f"Error recording partnership event: {e}")
    
    async def record_delegation_event(
        self,
        case_id: str,
        delegation_reason: str,
        delegation_time: float,
        delegated_by: str,
        delegated_to: str,
        success: bool,
        metadata: Optional[Dict[str, Any]] = None
    ) -> None:
        """Registra evento de delegação"""
        try:
            event = MetricEvent(
                event_type=MetricType.DELEGATION_EFFICIENCY,
                category=MetricCategory.DELEGATION_EFFICIENCY.value,
                entity_id=case_id,
                user_id=delegated_by,
                data={
                    'delegation_reason': delegation_reason,
                    'delegation_time': delegation_time,
                    'delegated_by': delegated_by,
                    'delegated_to': delegated_to,
                    'success': success,
                    'metadata': metadata or {}
                },
                timestamp=datetime.utcnow()
            )
            
            await self._store_metric_event(event)
            
            logger.info(f"Delegation event recorded for case {case_id}")
            
        except Exception as e:
            logger.error(f"Error recording delegation event: {e}")
    
    @cache_result(ttl=300)  # 5 minutos
    async def get_allocation_metrics(
        self,
        start_date: datetime,
        end_date: datetime,
        allocation_type: Optional[str] = None
    ) -> List[AllocationMetric]:
        """Obtém métricas de alocação"""
        try:
            query = """
            SELECT 
                data->>'allocation_type' as allocation_type,
                COUNT(*) as total_cases,
                SUM(CASE WHEN data->>'success' = 'true' THEN 1 ELSE 0 END) as successful_allocations,
                SUM(CASE WHEN data->>'success' = 'false' THEN 1 ELSE 0 END) as failed_allocations,
                AVG(CAST(data->>'sla_compliance' AS FLOAT)) as average_sla_compliance,
                AVG(CAST(data->>'match_score' AS FLOAT)) as average_match_score,
                AVG(CAST(data->>'response_time' AS FLOAT)) as average_response_time,
                AVG(CAST(data->>'conversion_rate' AS FLOAT)) as conversion_rate,
                DATE_TRUNC('hour', timestamp) as created_at
            FROM metric_events 
            WHERE category = %s
            AND timestamp BETWEEN %s AND %s
            """
            
            params = [MetricCategory.ALLOCATION_PERFORMANCE.value, start_date, end_date]
            
            if allocation_type:
                query += " AND data->>'allocation_type' = %s"
                params.append(allocation_type)
            
            query += " GROUP BY allocation_type, DATE_TRUNC('hour', timestamp) ORDER BY created_at DESC"
            
            with self.db.cursor() as cursor:
                cursor.execute(query, params)
                rows = cursor.fetchall()
                
                return [
                    AllocationMetric(
                        allocation_type=row[0],
                        total_cases=row[1],
                        successful_allocations=row[2],
                        failed_allocations=row[3],
                        average_sla_compliance=row[4] or 0.0,
                        average_match_score=row[5] or 0.0,
                        average_response_time=row[6] or 0.0,
                        conversion_rate=row[7] or 0.0,
                        created_at=row[8]
                    )
                    for row in rows
                ]
                
        except Exception as e:
            logger.error(f"Error getting allocation metrics: {e}")
            return []
    
    @cache_result(ttl=300)  # 5 minutos
    async def get_engagement_metrics(
        self,
        start_date: datetime,
        end_date: datetime,
        user_role: Optional[str] = None
    ) -> List[EngagementMetric]:
        """Obtém métricas de engajamento"""
        try:
            query = """
            SELECT 
                data->>'user_role' as user_role,
                COUNT(*) as total_interactions,
                SUM(CASE WHEN data->>'interaction_type' = 'contextual_view' THEN 1 ELSE 0 END) as contextual_views,
                SUM(CASE WHEN data->>'interaction_type' = 'action_click' THEN 1 ELSE 0 END) as action_clicks,
                SUM(CASE WHEN data->>'interaction_type' = 'highlight_view' THEN 1 ELSE 0 END) as highlight_views,
                SUM(CASE WHEN data->>'interaction_type' = 'kpi_view' THEN 1 ELSE 0 END) as kpi_views,
                AVG(CAST(data->>'duration' AS FLOAT)) as time_spent_seconds,
                AVG(CAST(data->>'session_duration' AS FLOAT)) as session_duration,
                AVG(CAST(data->>'bounce_rate' AS FLOAT)) as bounce_rate,
                DATE_TRUNC('hour', timestamp) as created_at
            FROM metric_events 
            WHERE category = %s
            AND timestamp BETWEEN %s AND %s
            """
            
            params = [MetricCategory.USER_ENGAGEMENT.value, start_date, end_date]
            
            if user_role:
                query += " AND data->>'user_role' = %s"
                params.append(user_role)
            
            query += " GROUP BY user_role, DATE_TRUNC('hour', timestamp) ORDER BY created_at DESC"
            
            with self.db.cursor() as cursor:
                cursor.execute(query, params)
                rows = cursor.fetchall()
                
                return [
                    EngagementMetric(
                        user_role=row[0],
                        total_interactions=row[1],
                        contextual_views=row[2],
                        action_clicks=row[3],
                        highlight_views=row[4],
                        kpi_views=row[5],
                        time_spent_seconds=row[6] or 0.0,
                        session_duration=row[7] or 0.0,
                        bounce_rate=row[8] or 0.0,
                        created_at=row[9]
                    )
                    for row in rows
                ]
                
        except Exception as e:
            logger.error(f"Error getting engagement metrics: {e}")
            return []
    
    @cache_result(ttl=300)  # 5 minutos
    async def get_accuracy_metrics(
        self,
        start_date: datetime,
        end_date: datetime,
        allocation_type: Optional[str] = None
    ) -> List[AccuracyMetric]:
        """Obtém métricas de precisão"""
        try:
            query = """
            SELECT 
                data->>'allocation_type' as allocation_type,
                AVG(CAST(data->>'predicted_score' AS FLOAT)) as predicted_match_score,
                AVG(CAST(data->>'actual_satisfaction' AS FLOAT)) as actual_satisfaction,
                AVG(CAST(data->>'accuracy_score' AS FLOAT)) as accuracy_score,
                AVG(CAST(data->>'false_positive_rate' AS FLOAT)) as false_positive_rate,
                AVG(CAST(data->>'false_negative_rate' AS FLOAT)) as false_negative_rate,
                AVG(CAST(data->>'precision' AS FLOAT)) as precision,
                AVG(CAST(data->>'recall' AS FLOAT)) as recall,
                AVG(CAST(data->>'f1_score' AS FLOAT)) as f1_score,
                DATE_TRUNC('hour', timestamp) as created_at
            FROM metric_events 
            WHERE category = %s
            AND timestamp BETWEEN %s AND %s
            """
            
            params = [MetricCategory.CONTEXTUAL_ACCURACY.value, start_date, end_date]
            
            if allocation_type:
                query += " AND data->>'allocation_type' = %s"
                params.append(allocation_type)
            
            query += " GROUP BY allocation_type, DATE_TRUNC('hour', timestamp) ORDER BY created_at DESC"
            
            with self.db.cursor() as cursor:
                cursor.execute(query, params)
                rows = cursor.fetchall()
                
                return [
                    AccuracyMetric(
                        allocation_type=row[0],
                        predicted_match_score=row[1] or 0.0,
                        actual_satisfaction=row[2] or 0.0,
                        accuracy_score=row[3] or 0.0,
                        false_positive_rate=row[4] or 0.0,
                        false_negative_rate=row[5] or 0.0,
                        precision=row[6] or 0.0,
                        recall=row[7] or 0.0,
                        f1_score=row[8] or 0.0,
                        created_at=row[9]
                    )
                    for row in rows
                ]
                
        except Exception as e:
            logger.error(f"Error getting accuracy metrics: {e}")
            return []
    
    async def get_contextual_dashboard_data(
        self,
        start_date: datetime,
        end_date: datetime
    ) -> Dict[str, Any]:
        """Obtém dados completos para dashboard contextual"""
        try:
            allocation_metrics = await self.get_allocation_metrics(start_date, end_date)
            engagement_metrics = await self.get_engagement_metrics(start_date, end_date)
            accuracy_metrics = await self.get_accuracy_metrics(start_date, end_date)
            
            # Calcula KPIs agregados
            total_cases = sum(m.total_cases for m in allocation_metrics)
            avg_match_score = sum(m.average_match_score * m.total_cases for m in allocation_metrics) / total_cases if total_cases > 0 else 0
            avg_response_time = sum(m.average_response_time * m.total_cases for m in allocation_metrics) / total_cases if total_cases > 0 else 0
            overall_accuracy = sum(m.accuracy_score for m in accuracy_metrics) / len(accuracy_metrics) if accuracy_metrics else 0
            
            # Métricas por tipo de alocação
            allocation_breakdown = {}
            for metric in allocation_metrics:
                if metric.allocation_type not in allocation_breakdown:
                    allocation_breakdown[metric.allocation_type] = {
                        'total_cases': 0,
                        'success_rate': 0.0,
                        'avg_match_score': 0.0,
                        'avg_response_time': 0.0
                    }
                
                breakdown = allocation_breakdown[metric.allocation_type]
                breakdown['total_cases'] += metric.total_cases
                breakdown['success_rate'] = metric.successful_allocations / metric.total_cases if metric.total_cases > 0 else 0
                breakdown['avg_match_score'] = metric.average_match_score
                breakdown['avg_response_time'] = metric.average_response_time
            
            # Tendências temporais
            temporal_trends = []
            for metric in allocation_metrics[-24:]:  # Últimas 24 horas
                temporal_trends.append({
                    'timestamp': metric.created_at.isoformat(),
                    'total_cases': metric.total_cases,
                    'success_rate': metric.successful_allocations / metric.total_cases if metric.total_cases > 0 else 0,
                    'avg_match_score': metric.average_match_score,
                    'avg_response_time': metric.average_response_time
                })
            
            return {
                'summary': {
                    'total_cases': total_cases,
                    'avg_match_score': round(avg_match_score, 2),
                    'avg_response_time': round(avg_response_time, 2),
                    'overall_accuracy': round(overall_accuracy, 2),
                    'period': {
                        'start': start_date.isoformat(),
                        'end': end_date.isoformat()
                    }
                },
                'allocation_breakdown': allocation_breakdown,
                'temporal_trends': temporal_trends,
                'engagement_summary': {
                    'total_interactions': sum(m.total_interactions for m in engagement_metrics),
                    'avg_session_duration': sum(m.session_duration for m in engagement_metrics) / len(engagement_metrics) if engagement_metrics else 0,
                    'bounce_rate': sum(m.bounce_rate for m in engagement_metrics) / len(engagement_metrics) if engagement_metrics else 0
                },
                'accuracy_summary': {
                    'overall_accuracy': overall_accuracy,
                    'precision': sum(m.precision for m in accuracy_metrics) / len(accuracy_metrics) if accuracy_metrics else 0,
                    'recall': sum(m.recall for m in accuracy_metrics) / len(accuracy_metrics) if accuracy_metrics else 0,
                    'f1_score': sum(m.f1_score for m in accuracy_metrics) / len(accuracy_metrics) if accuracy_metrics else 0
                }
            }
            
        except Exception as e:
            logger.error(f"Error getting dashboard data: {e}")
            return {}
    
    async def _store_metric_event(self, event: MetricEvent) -> None:
        """Armazena evento de métrica no banco"""
        try:
            query = """
            INSERT INTO metric_events (event_type, category, entity_id, user_id, data, timestamp)
            VALUES (%s, %s, %s, %s, %s, %s)
            """
            
            with self.db.cursor() as cursor:
                cursor.execute(query, (
                    event.event_type.value,
                    event.category,
                    event.entity_id,
                    event.user_id,
                    json.dumps(event.data),
                    event.timestamp
                ))
                self.db.commit()
                
        except Exception as e:
            logger.error(f"Error storing metric event: {e}")
            self.db.rollback()
            raise
    
    async def cleanup_old_metrics(self, retention_days: int = 90) -> None:
        """Remove métricas antigas baseado na política de retenção"""
        try:
            cutoff_date = datetime.utcnow() - timedelta(days=retention_days)
            
            query = "DELETE FROM metric_events WHERE timestamp < %s"
            
            with self.db.cursor() as cursor:
                cursor.execute(query, (cutoff_date,))
                deleted_count = cursor.rowcount
                self.db.commit()
                
                logger.info(f"Cleaned up {deleted_count} old metric events")
                
        except Exception as e:
            logger.error(f"Error cleaning up old metrics: {e}")
            self.db.rollback()
            raise 