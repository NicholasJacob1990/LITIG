"""
Analytics Service for Billing Conversion Metrics
Serviço de analytics para métricas de conversão de billing
"""
import os
import logging
from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta
from dataclasses import dataclass
import json

import mixpanel
from config import get_supabase_client

logger = logging.getLogger(__name__)


@dataclass
class ConversionMetrics:
    """Métricas de conversão de billing."""
    total_users: int
    total_upgrades: int
    conversion_rate: float
    revenue_total: float
    revenue_by_plan: Dict[str, float]
    churn_rate: float
    ltv_average: float


@dataclass
class FunnelMetrics:
    """Métricas de funil de conversão."""
    page_views: int
    plan_selections: int
    checkout_starts: int
    checkout_completions: int
    view_to_selection_rate: float
    selection_to_checkout_rate: float
    checkout_completion_rate: float
    overall_conversion_rate: float


class BillingAnalyticsService:
    """Serviço de analytics para billing e conversão."""
    
    def __init__(self):
        self.supabase = get_supabase_client()
        
        # Configuração Mixpanel
        mixpanel_token = os.getenv("MIXPANEL_TOKEN")
        if mixpanel_token:
            self.mixpanel = mixpanel.Mixpanel(mixpanel_token)
        else:
            self.mixpanel = None
            logger.warning("Mixpanel token not configured")
    
    async def track_billing_event(self, event_name: str, user_id: str, properties: Dict[str, Any]) -> bool:
        """Registra evento de billing para analytics."""
        try:
            # Adicionar metadata padrão
            enhanced_properties = {
                **properties,
                "timestamp": datetime.now().isoformat(),
                "source": "billing_system",
                "environment": os.getenv("ENVIRONMENT", "development")
            }
            
            # Registrar no Supabase para analytics interno
            analytics_data = {
                "user_id": user_id,
                "event_name": event_name,
                "properties": enhanced_properties,
                "created_at": datetime.now().isoformat()
            }
            
            self.supabase.table("billing_analytics").insert(analytics_data).execute()
            
            # Enviar para Mixpanel se configurado
            if self.mixpanel:
                self.mixpanel.track(user_id, event_name, enhanced_properties)
            
            logger.info(f"Analytics event tracked: {event_name} for user {user_id}")
            return True
            
        except Exception as e:
            logger.error(f"Error tracking analytics event: {e}")
            return False
    
    async def track_page_view(self, user_id: str, entity_type: str, page: str = "plans") -> bool:
        """Registra visualização da página de planos."""
        return await self.track_billing_event("billing_page_view", user_id, {
            "page": page,
            "entity_type": entity_type
        })
    
    async def track_plan_selection(self, user_id: str, entity_type: str, selected_plan: str, current_plan: str) -> bool:
        """Registra seleção de plano."""
        return await self.track_billing_event("plan_selected", user_id, {
            "entity_type": entity_type,
            "selected_plan": selected_plan,
            "current_plan": current_plan,
            "is_upgrade": self._is_upgrade(current_plan, selected_plan, entity_type)
        })
    
    async def track_checkout_start(self, user_id: str, entity_type: str, plan: str, amount_cents: int) -> bool:
        """Registra início do checkout."""
        return await self.track_billing_event("checkout_started", user_id, {
            "entity_type": entity_type,
            "plan": plan,
            "amount_cents": amount_cents,
            "amount_reais": amount_cents / 100.0
        })
    
    async def track_checkout_completion(self, user_id: str, entity_type: str, plan: str, amount_cents: int, session_id: str) -> bool:
        """Registra conclusão do checkout."""
        return await self.track_billing_event("checkout_completed", user_id, {
            "entity_type": entity_type,
            "plan": plan,
            "amount_cents": amount_cents,
            "amount_reais": amount_cents / 100.0,
            "session_id": session_id
        })
    
    async def track_plan_change(self, user_id: str, entity_type: str, old_plan: str, new_plan: str, amount_cents: int) -> bool:
        """Registra mudança efetiva de plano."""
        action = self._get_plan_change_action(old_plan, new_plan, entity_type)
        
        return await self.track_billing_event("plan_changed", user_id, {
            "entity_type": entity_type,
            "old_plan": old_plan,
            "new_plan": new_plan,
            "action": action,
            "amount_cents": amount_cents,
            "amount_reais": amount_cents / 100.0
        })
    
    async def track_churn(self, user_id: str, entity_type: str, cancelled_plan: str, reason: str = "unknown") -> bool:
        """Registra cancelamento/churn."""
        return await self.track_billing_event("plan_cancelled", user_id, {
            "entity_type": entity_type,
            "cancelled_plan": cancelled_plan,
            "reason": reason
        })
    
    async def get_conversion_metrics(self, entity_type: str, days: int = 30) -> ConversionMetrics:
        """Calcula métricas de conversão para um período."""
        try:
            start_date = datetime.now() - timedelta(days=days)
            
            # Query base para o período
            base_query = (
                self.supabase.table("billing_analytics")
                .select("*")
                .gte("created_at", start_date.isoformat())
                .eq("properties->>entity_type", entity_type)
            )
            
            # Total de usuários únicos que visualizaram planos
            page_views = base_query.eq("event_name", "billing_page_view").execute()
            total_users = len(set(event["user_id"] for event in page_views.data))
            
            # Total de upgrades
            upgrades = base_query.eq("event_name", "plan_changed").execute()
            upgrade_events = [
                event for event in upgrades.data 
                if event["properties"].get("action") == "upgrade"
            ]
            total_upgrades = len(upgrade_events)
            
            # Conversão
            conversion_rate = (total_upgrades / total_users * 100) if total_users > 0 else 0
            
            # Revenue
            revenue_total = sum(
                event["properties"].get("amount_reais", 0) 
                for event in upgrade_events
            )
            
            # Revenue por plano
            revenue_by_plan = {}
            for event in upgrade_events:
                plan = event["properties"].get("new_plan", "unknown")
                amount = event["properties"].get("amount_reais", 0)
                revenue_by_plan[plan] = revenue_by_plan.get(plan, 0) + amount
            
            # Churn rate
            cancellations = base_query.eq("event_name", "plan_cancelled").execute()
            churn_rate = (len(cancellations.data) / total_users * 100) if total_users > 0 else 0
            
            # LTV médio (estimativa simples)
            ltv_average = (revenue_total / total_upgrades) if total_upgrades > 0 else 0
            
            return ConversionMetrics(
                total_users=total_users,
                total_upgrades=total_upgrades,
                conversion_rate=conversion_rate,
                revenue_total=revenue_total,
                revenue_by_plan=revenue_by_plan,
                churn_rate=churn_rate,
                ltv_average=ltv_average
            )
            
        except Exception as e:
            logger.error(f"Error calculating conversion metrics: {e}")
            return ConversionMetrics(0, 0, 0, 0, {}, 0, 0)
    
    async def get_funnel_metrics(self, entity_type: str, days: int = 30) -> FunnelMetrics:
        """Calcula métricas do funil de conversão."""
        try:
            start_date = datetime.now() - timedelta(days=days)
            
            # Query base
            base_query = (
                self.supabase.table("billing_analytics")
                .select("*")
                .gte("created_at", start_date.isoformat())
                .eq("properties->>entity_type", entity_type)
            )
            
            # Métricas do funil
            page_views = len(base_query.eq("event_name", "billing_page_view").execute().data)
            plan_selections = len(base_query.eq("event_name", "plan_selected").execute().data)
            checkout_starts = len(base_query.eq("event_name", "checkout_started").execute().data)
            checkout_completions = len(base_query.eq("event_name", "checkout_completed").execute().data)
            
            # Calcular taxas de conversão
            view_to_selection_rate = (plan_selections / page_views * 100) if page_views > 0 else 0
            selection_to_checkout_rate = (checkout_starts / plan_selections * 100) if plan_selections > 0 else 0
            checkout_completion_rate = (checkout_completions / checkout_starts * 100) if checkout_starts > 0 else 0
            overall_conversion_rate = (checkout_completions / page_views * 100) if page_views > 0 else 0
            
            return FunnelMetrics(
                page_views=page_views,
                plan_selections=plan_selections,
                checkout_starts=checkout_starts,
                checkout_completions=checkout_completions,
                view_to_selection_rate=view_to_selection_rate,
                selection_to_checkout_rate=selection_to_checkout_rate,
                checkout_completion_rate=checkout_completion_rate,
                overall_conversion_rate=overall_conversion_rate
            )
            
        except Exception as e:
            logger.error(f"Error calculating funnel metrics: {e}")
            return FunnelMetrics(0, 0, 0, 0, 0, 0, 0, 0)
    
    async def get_cohort_analysis(self, entity_type: str, months: int = 6) -> Dict[str, Any]:
        """Análise de coorte para retenção de usuários."""
        try:
            # Implementação simplificada - pode ser expandida
            start_date = datetime.now() - timedelta(days=months * 30)
            
            # Buscar todos os upgrades no período
            upgrades = (
                self.supabase.table("billing_analytics")
                .select("*")
                .gte("created_at", start_date.isoformat())
                .eq("event_name", "plan_changed")
                .eq("properties->>entity_type", entity_type)
                .eq("properties->>action", "upgrade")
            ).execute()
            
            # Buscar cancelamentos
            cancellations = (
                self.supabase.table("billing_analytics")
                .select("*")
                .gte("created_at", start_date.isoformat())
                .eq("event_name", "plan_cancelled")
                .eq("properties->>entity_type", entity_type)
            ).execute()
            
            # Agrupar por mês
            cohorts = {}
            for event in upgrades.data:
                month = event["created_at"][:7]  # YYYY-MM
                if month not in cohorts:
                    cohorts[month] = {"upgrades": 0, "cancellations": 0}
                cohorts[month]["upgrades"] += 1
            
            for event in cancellations.data:
                month = event["created_at"][:7]
                if month in cohorts:
                    cohorts[month]["cancellations"] += 1
            
            # Calcular retenção por coorte
            for month_data in cohorts.values():
                month_data["retention_rate"] = (
                    (month_data["upgrades"] - month_data["cancellations"]) / month_data["upgrades"] * 100
                    if month_data["upgrades"] > 0 else 0
                )
            
            return cohorts
            
        except Exception as e:
            logger.error(f"Error calculating cohort analysis: {e}")
            return {}
    
    async def generate_analytics_report(self, entity_type: str, days: int = 30) -> Dict[str, Any]:
        """Gera relatório completo de analytics."""
        try:
            # Buscar todas as métricas
            conversion_metrics = await self.get_conversion_metrics(entity_type, days)
            funnel_metrics = await self.get_funnel_metrics(entity_type, days)
            cohort_analysis = await self.get_cohort_analysis(entity_type, 6)
            
            # Métricas adicionais
            top_plans = await self._get_top_performing_plans(entity_type, days)
            conversion_by_day = await self._get_daily_conversion_trends(entity_type, days)
            
            return {
                "entity_type": entity_type,
                "period_days": days,
                "generated_at": datetime.now().isoformat(),
                "conversion_metrics": conversion_metrics.__dict__,
                "funnel_metrics": funnel_metrics.__dict__,
                "cohort_analysis": cohort_analysis,
                "top_performing_plans": top_plans,
                "daily_conversion_trends": conversion_by_day,
                "summary": {
                    "health_score": self._calculate_health_score(conversion_metrics, funnel_metrics),
                    "recommendations": self._generate_recommendations(conversion_metrics, funnel_metrics)
                }
            }
            
        except Exception as e:
            logger.error(f"Error generating analytics report: {e}")
            return {"error": str(e)}
    
    def _is_upgrade(self, current_plan: str, new_plan: str, entity_type: str) -> bool:
        """Determina se uma mudança de plano é um upgrade."""
        plan_hierarchy = {
            "client": ["FREE", "VIP", "ENTERPRISE"],
            "lawyer": ["FREE", "PRO"],
            "firm": ["FREE", "PARTNER", "PREMIUM"]
        }
        
        hierarchy = plan_hierarchy.get(entity_type, [])
        if current_plan in hierarchy and new_plan in hierarchy:
            return hierarchy.index(new_plan) > hierarchy.index(current_plan)
        return False
    
    def _get_plan_change_action(self, old_plan: str, new_plan: str, entity_type: str) -> str:
        """Determina o tipo de ação (upgrade/downgrade/lateral)."""
        if old_plan == "FREE" and new_plan != "FREE":
            return "upgrade"
        elif old_plan != "FREE" and new_plan == "FREE":
            return "downgrade" 
        elif self._is_upgrade(old_plan, new_plan, entity_type):
            return "upgrade"
        elif self._is_upgrade(new_plan, old_plan, entity_type):
            return "downgrade"
        else:
            return "lateral"
    
    async def _get_top_performing_plans(self, entity_type: str, days: int) -> List[Dict[str, Any]]:
        """Retorna planos com melhor performance."""
        try:
            start_date = datetime.now() - timedelta(days=days)
            
            upgrades = (
                self.supabase.table("billing_analytics")
                .select("*")
                .gte("created_at", start_date.isoformat())
                .eq("event_name", "plan_changed")
                .eq("properties->>entity_type", entity_type)
                .eq("properties->>action", "upgrade")
            ).execute()
            
            plan_stats = {}
            for event in upgrades.data:
                plan = event["properties"].get("new_plan", "unknown")
                amount = event["properties"].get("amount_reais", 0)
                
                if plan not in plan_stats:
                    plan_stats[plan] = {"count": 0, "revenue": 0}
                
                plan_stats[plan]["count"] += 1
                plan_stats[plan]["revenue"] += amount
            
            # Ordenar por revenue
            top_plans = sorted(
                [{"plan": k, **v} for k, v in plan_stats.items()],
                key=lambda x: x["revenue"],
                reverse=True
            )
            
            return top_plans[:5]  # Top 5
            
        except Exception as e:
            logger.error(f"Error getting top performing plans: {e}")
            return []
    
    async def _get_daily_conversion_trends(self, entity_type: str, days: int) -> List[Dict[str, Any]]:
        """Retorna tendências diárias de conversão."""
        try:
            start_date = datetime.now() - timedelta(days=days)
            
            # Buscar dados por dia
            daily_data = {}
            for i in range(days):
                date = start_date + timedelta(days=i)
                date_str = date.strftime("%Y-%m-%d")
                daily_data[date_str] = {"views": 0, "conversions": 0}
            
            # Contar views
            views = (
                self.supabase.table("billing_analytics")
                .select("*")
                .gte("created_at", start_date.isoformat())
                .eq("event_name", "billing_page_view")
                .eq("properties->>entity_type", entity_type)
            ).execute()
            
            for event in views.data:
                date_str = event["created_at"][:10]
                if date_str in daily_data:
                    daily_data[date_str]["views"] += 1
            
            # Contar conversões
            conversions = (
                self.supabase.table("billing_analytics")
                .select("*")
                .gte("created_at", start_date.isoformat())
                .eq("event_name", "checkout_completed")
                .eq("properties->>entity_type", entity_type)
            ).execute()
            
            for event in conversions.data:
                date_str = event["created_at"][:10]
                if date_str in daily_data:
                    daily_data[date_str]["conversions"] += 1
            
            # Calcular taxa de conversão diária
            trends = []
            for date_str, data in daily_data.items():
                conversion_rate = (data["conversions"] / data["views"] * 100) if data["views"] > 0 else 0
                trends.append({
                    "date": date_str,
                    "views": data["views"],
                    "conversions": data["conversions"],
                    "conversion_rate": conversion_rate
                })
            
            return sorted(trends, key=lambda x: x["date"])
            
        except Exception as e:
            logger.error(f"Error getting daily conversion trends: {e}")
            return []
    
    def _calculate_health_score(self, conversion_metrics: ConversionMetrics, funnel_metrics: FunnelMetrics) -> float:
        """Calcula score de saúde do billing (0-100)."""
        try:
            # Pesos para diferentes métricas
            scores = [
                min(conversion_metrics.conversion_rate * 2, 25),  # Max 25 pontos
                min(funnel_metrics.overall_conversion_rate * 2, 25),  # Max 25 pontos
                min(100 - conversion_metrics.churn_rate, 25),  # Max 25 pontos (inverso do churn)
                min(funnel_metrics.checkout_completion_rate / 4, 25)  # Max 25 pontos
            ]
            
            return sum(scores)
            
        except Exception:
            return 0
    
    def _generate_recommendations(self, conversion_metrics: ConversionMetrics, funnel_metrics: FunnelMetrics) -> List[str]:
        """Gera recomendações baseadas nas métricas."""
        recommendations = []
        
        if funnel_metrics.view_to_selection_rate < 10:
            recommendations.append("Melhore a apresentação dos planos para aumentar seleções")
        
        if funnel_metrics.checkout_completion_rate < 70:
            recommendations.append("Simplifique o processo de checkout para reduzir abandono")
        
        if conversion_metrics.conversion_rate < 5:
            recommendations.append("Considere ajustar preços ou criar ofertas promocionais")
        
        if conversion_metrics.churn_rate > 10:
            recommendations.append("Implemente estratégias de retenção para reduzir cancelamentos")
        
        if not recommendations:
            recommendations.append("Métricas estão saudáveis! Continue monitorando tendências")
        
        return recommendations


# Instância global do serviço de analytics
analytics_service = BillingAnalyticsService() 