"""
Serviço de notificações semanais para prestadores.
Analisa mudanças na performance e envia insights acionáveis.
"""

import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple

from supabase import create_client

from ..config import settings
from .email_service import email_service
from .provider_insights_service import ProviderInsightsService

logger = logging.getLogger(__name__)


class ProviderNotificationsService:
    """Serviço para notificações semanais de performance para prestadores."""

    def __init__(self):
        self.supabase = create_client(
            settings.SUPABASE_URL,
            settings.SUPABASE_SERVICE_KEY
        )
        self.email_service = email_service
        self.provider_insights_service = ProviderInsightsService(self.supabase)

    async def send_weekly_performance_notifications(self) -> Dict[str, int]:
        """
        Envia notificações semanais para todos os prestadores ativos.
        
        Returns:
            Dict com estatísticas do envio
        """
        logger.info("Iniciando envio de notificações semanais de performance")
        
        stats = {
            "total_providers": 0,
            "notifications_sent": 0,
            "significant_changes": 0,
            "errors": 0
        }
        
        try:
            # Buscar prestadores ativos
            active_providers = await self._get_active_providers()
            stats["total_providers"] = len(active_providers)
            
            for provider in active_providers:
                try:
                    # Analisar mudanças na performance
                    changes = await self._analyze_weekly_changes(provider["id"])
                    
                    if changes["has_significant_changes"]:
                        stats["significant_changes"] += 1
                        
                        # Gerar e enviar notificação
                        await self._send_provider_notification(provider, changes)
                        stats["notifications_sent"] += 1
                        
                        logger.info(f"Notificação enviada para {provider['email']}")
                    else:
                        logger.debug(f"Sem mudanças significativas para {provider['email']}")
                        
                except Exception as e:
                    logger.error(f"Erro ao processar notificação para {provider['email']}: {e}")
                    stats["errors"] += 1
                    
            logger.info(f"Notificações semanais concluídas: {stats}")
            return stats
            
        except Exception as e:
            logger.error(f"Erro no envio de notificações semanais: {e}")
            raise

    async def _get_active_providers(self) -> List[Dict]:
        """Busca prestadores ativos que devem receber notificações."""
        try:
            # Buscar advogados ativos com pelo menos 1 caso nos últimos 30 dias
            response = self.supabase.table("profiles").select(
                "id, email, full_name, created_at, notification_preferences"
            ).eq("role", "lawyer").eq("status", "active").execute()
            
            if not response.data:
                return []
            
            active_providers = []
            for provider in response.data:
                # Verificar se tem atividade recente
                if await self._has_recent_activity(provider["id"]):
                    # Verificar preferências de notificação
                    preferences = provider.get("notification_preferences", {})
                    if preferences.get("weekly_performance", True):  # Default: True
                        active_providers.append(provider)
            
            return active_providers
            
        except Exception as e:
            logger.error(f"Erro ao buscar prestadores ativos: {e}")
            return []

    async def _has_recent_activity(self, provider_id: str) -> bool:
        """Verifica se o prestador teve atividade nos últimos 30 dias."""
        try:
            cutoff_date = datetime.now() - timedelta(days=30)
            
            # Verificar casos recentes
            response = self.supabase.table("cases").select("id").eq(
                "lawyer_id", provider_id
            ).gte("created_at", cutoff_date.isoformat()).limit(1).execute()
            
            return len(response.data) > 0
            
        except Exception as e:
            logger.error(f"Erro ao verificar atividade recente: {e}")
            return False

    async def _analyze_weekly_changes(self, provider_id: str) -> Dict:
        """
        Analisa mudanças na performance do prestador na última semana.
        
        Returns:
            Dict com análise das mudanças
        """
        try:
            # Obter insights atuais
            current_insights = await self.provider_insights_service.generate_performance_insights(provider_id)
            
            # Obter dados históricos (simulado - em produção viria de uma tabela de histórico)
            historical_data = await self._get_historical_performance(provider_id)
            
            changes = {
                "has_significant_changes": False,
                "score_change": 0,
                "improved_metrics": [],
                "declined_metrics": [],
                "new_weak_points": [],
                "resolved_weak_points": [],
                "trend_change": None
            }
            
            if not historical_data:
                # Primeira análise - sempre consideramos significativa
                changes["has_significant_changes"] = True
                changes["trend_change"] = "new_profile"
                return changes
            
            # Comparar score geral
            score_change = current_insights["overall_score"] - historical_data.get("overall_score", 0)
            changes["score_change"] = score_change
            
            # Mudança significativa se score mudou mais de 5 pontos
            if abs(score_change) >= 5:
                changes["has_significant_changes"] = True
            
            # Analisar métricas específicas
            current_metrics = current_insights.get("benchmarks", {})
            historical_metrics = historical_data.get("benchmarks", {})
            
            for metric, current_value in current_metrics.items():
                historical_value = historical_metrics.get(metric, {}).get("your_score", 0)
                change = current_value.get("your_score", 0) - historical_value
                
                if change > 0.1:  # Melhoria significativa
                    changes["improved_metrics"].append({
                        "metric": metric,
                        "change": change,
                        "current": current_value.get("your_score", 0)
                    })
                elif change < -0.1:  # Declínio significativo
                    changes["declined_metrics"].append({
                        "metric": metric,
                        "change": change,
                        "current": current_value.get("your_score", 0)
                    })
            
            # Se houve mudanças nas métricas, é significativo
            if changes["improved_metrics"] or changes["declined_metrics"]:
                changes["has_significant_changes"] = True
            
            # Analisar pontos fracos
            current_weak_points = set(wp["metric"] for wp in current_insights.get("weak_points", []))
            historical_weak_points = set(wp["metric"] for wp in historical_data.get("weak_points", []))
            
            changes["new_weak_points"] = list(current_weak_points - historical_weak_points)
            changes["resolved_weak_points"] = list(historical_weak_points - current_weak_points)
            
            if changes["new_weak_points"] or changes["resolved_weak_points"]:
                changes["has_significant_changes"] = True
            
            return changes
            
        except Exception as e:
            logger.error(f"Erro ao analisar mudanças semanais: {e}")
            return {"has_significant_changes": False}

    async def _get_historical_performance(self, provider_id: str) -> Optional[Dict]:
        """
        Busca dados históricos de performance (simulado).
        Em produção, isso viria de uma tabela de snapshots semanais.
        """
        try:
            # Simular dados históricos baseados no score atual com pequenas variações
            current_insights = await self.provider_insights_service.generate_performance_insights(provider_id)
            
            # Simular dados da semana passada com pequenas variações
            historical_data = {
                "overall_score": max(0, min(100, current_insights["overall_score"] + (-5 + (hash(provider_id) % 10)))),
                "benchmarks": {},
                "weak_points": []
            }
            
            # Simular variações nos benchmarks
            for metric, data in current_insights.get("benchmarks", {}).items():
                variation = (hash(f"{provider_id}_{metric}") % 20 - 10) / 100  # -0.1 a +0.1
                historical_score = max(0, min(1, data.get("your_score", 0) + variation))
                
                historical_data["benchmarks"][metric] = {
                    "your_score": historical_score
                }
            
            return historical_data
            
        except Exception as e:
            logger.error(f"Erro ao buscar dados históricos: {e}")
            return None

    async def _send_provider_notification(self, provider: Dict, changes: Dict) -> bool:
        """Envia notificação personalizada para o prestador."""
        try:
            # Gerar conteúdo personalizado
            email_content = await self._generate_email_content(provider, changes)
            
            # Enviar e-mail
            success = await self.email_service.send_email(
                to=[provider["email"]],
                subject=f"📊 Atualização Semanal de Performance - {provider['full_name']}",
                body=email_content,
                html=True
            )
            
            if success:
                # Registrar envio no banco
                await self._log_notification_sent(provider["id"], changes)
            
            return success
            
        except Exception as e:
            logger.error(f"Erro ao enviar notificação: {e}")
            return False

    async def _generate_email_content(self, provider: Dict, changes: Dict) -> str:
        """Gera conteúdo HTML personalizado do e-mail."""
        try:
            # Obter insights atuais para incluir no e-mail
            current_insights = await self.provider_insights_service.generate_performance_insights(provider["id"])
            
            # Cabeçalho
            html_content = f"""
            <!DOCTYPE html>
            <html>
            <head>
                <style>
                    body {{ font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }}
                    .container {{ max-width: 600px; margin: 0 auto; background-color: white; border-radius: 10px; overflow: hidden; }}
                    .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; }}
                    .content {{ padding: 30px; }}
                    .metric-card {{ background-color: #f8f9fa; border-left: 4px solid #007bff; padding: 15px; margin: 15px 0; border-radius: 5px; }}
                    .improvement {{ border-left-color: #28a745; }}
                    .decline {{ border-left-color: #dc3545; }}
                    .score-circle {{ display: inline-block; width: 60px; height: 60px; border-radius: 50%; background-color: #007bff; color: white; text-align: center; line-height: 60px; font-weight: bold; margin-right: 15px; }}
                    .button {{ display: inline-block; padding: 12px 24px; background-color: #007bff; color: white; text-decoration: none; border-radius: 5px; margin-top: 20px; }}
                    .footer {{ background-color: #f8f9fa; padding: 20px; text-align: center; color: #666; }}
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <h1>📊 Atualização Semanal de Performance</h1>
                        <p>Olá, {provider['full_name']}!</p>
                    </div>
                    
                    <div class="content">
            """
            
            # Score atual
            score = current_insights["overall_score"]
            grade = current_insights["grade"]
            score_color = "#28a745" if score >= 80 else "#ffc107" if score >= 60 else "#dc3545"
            
            html_content += f"""
                        <div style="text-align: center; margin-bottom: 30px;">
                            <div class="score-circle" style="background-color: {score_color};">
                                {score}
                            </div>
                            <div style="display: inline-block; vertical-align: middle;">
                                <h3 style="margin: 0;">Sua nota atual: {grade}</h3>
                                <p style="margin: 5px 0; color: #666;">Score: {score}/100</p>
                            </div>
                        </div>
            """
            
            # Mudanças significativas
            if changes["score_change"] != 0:
                change_text = "subiu" if changes["score_change"] > 0 else "desceu"
                change_color = "#28a745" if changes["score_change"] > 0 else "#dc3545"
                
                html_content += f"""
                        <div class="metric-card">
                            <h4 style="color: {change_color};">📈 Mudança na Nota Geral</h4>
                            <p>Sua nota {change_text} <strong>{abs(changes['score_change']):.1f} pontos</strong> esta semana!</p>
                        </div>
                """
            
            # Métricas melhoradas
            if changes["improved_metrics"]:
                html_content += """
                        <div class="metric-card improvement">
                            <h4 style="color: #28a745;">🎯 Métricas que Melhoraram</h4>
                            <ul>
                """
                for metric in changes["improved_metrics"]:
                    metric_name = self._format_metric_name(metric["metric"])
                    html_content += f"<li><strong>{metric_name}</strong>: +{metric['change']:.1%}</li>"
                
                html_content += """
                            </ul>
                        </div>
                """
            
            # Métricas que declinaram
            if changes["declined_metrics"]:
                html_content += """
                        <div class="metric-card decline">
                            <h4 style="color: #dc3545;">⚠️ Métricas que Precisam de Atenção</h4>
                            <ul>
                """
                for metric in changes["declined_metrics"]:
                    metric_name = self._format_metric_name(metric["metric"])
                    html_content += f"<li><strong>{metric_name}</strong>: {metric['change']:.1%}</li>"
                
                html_content += """
                            </ul>
                        </div>
                """
            
            # Pontos fracos resolvidos
            if changes["resolved_weak_points"]:
                html_content += """
                        <div class="metric-card improvement">
                            <h4 style="color: #28a745;">✅ Pontos Fracos Resolvidos</h4>
                            <p>Parabéns! Você melhorou nestas áreas:</p>
                            <ul>
                """
                for metric in changes["resolved_weak_points"]:
                    metric_name = self._format_metric_name(metric)
                    html_content += f"<li>{metric_name}</li>"
                
                html_content += """
                            </ul>
                        </div>
                """
            
            # Novos pontos fracos
            if changes["new_weak_points"]:
                html_content += """
                        <div class="metric-card decline">
                            <h4 style="color: #dc3545;">🔍 Novas Oportunidades de Melhoria</h4>
                            <p>Identificamos algumas áreas onde você pode melhorar:</p>
                            <ul>
                """
                for metric in changes["new_weak_points"]:
                    metric_name = self._format_metric_name(metric)
                    html_content += f"<li>{metric_name}</li>"
                
                html_content += """
                            </ul>
                        </div>
                """
            
            # Principais sugestões
            if current_insights.get("improvement_suggestions"):
                html_content += """
                        <div class="metric-card">
                            <h4 style="color: #007bff;">💡 Sugestões para Esta Semana</h4>
                            <ul>
                """
                for suggestion in current_insights["improvement_suggestions"][:3]:  # Top 3
                    html_content += f"<li>{suggestion['action']}</li>"
                
                html_content += """
                            </ul>
                        </div>
                """
            
            # Call to action
            dashboard_url = f"{settings.FRONTEND_URL}/profile/performance"
            html_content += f"""
                        <div style="text-align: center; margin-top: 30px;">
                            <a href="{dashboard_url}" class="button">Ver Dashboard Completo</a>
                        </div>
                        
                        <div style="margin-top: 30px; padding: 20px; background-color: #e3f2fd; border-radius: 5px;">
                            <h4 style="color: #1976d2; margin-top: 0;">💪 Dica da Semana</h4>
                            <p>Advogados que respondem em até 2 horas têm 40% mais chances de serem contratados!</p>
                        </div>
                    </div>
                    
                    <div class="footer">
                        <p>LITGO - Conexão Jurídica Inteligente</p>
                        <p style="font-size: 12px;">
                            Não quer mais receber esses e-mails? 
                            <a href="{settings.FRONTEND_URL}/profile/notifications">Alterar preferências</a>
                        </p>
                    </div>
                </div>
            </body>
            </html>
            """
            
            return html_content
            
        except Exception as e:
            logger.error(f"Erro ao gerar conteúdo do e-mail: {e}")
            return self._generate_fallback_email(provider)

    def _format_metric_name(self, metric: str) -> str:
        """Formata nome da métrica para exibição."""
        metric_names = {
            "response_time": "Tempo de Resposta",
            "success_rate": "Taxa de Sucesso",
            "client_satisfaction": "Satisfação do Cliente",
            "case_completion": "Conclusão de Casos",
            "availability": "Disponibilidade",
            "specialization_match": "Especialização",
            "price_competitiveness": "Competitividade de Preços",
            "experience_years": "Anos de Experiência"
        }
        return metric_names.get(metric, metric.replace("_", " ").title())

    def _generate_fallback_email(self, provider: Dict) -> str:
        """Gera e-mail simples em caso de erro."""
        return f"""
        <html>
        <body>
            <h2>Atualização Semanal de Performance</h2>
            <p>Olá, {provider['full_name']}!</p>
            <p>Sua análise semanal de performance está disponível no dashboard.</p>
            <p><a href="{settings.FRONTEND_URL}/profile/performance">Acessar Dashboard</a></p>
            <p>LITGO - Conexão Jurídica Inteligente</p>
        </body>
        </html>
        """

    async def _log_notification_sent(self, provider_id: str, changes: Dict) -> None:
        """Registra o envio da notificação no banco."""
        try:
            log_data = {
                "provider_id": provider_id,
                "notification_type": "weekly_performance",
                "sent_at": datetime.now().isoformat(),
                "changes_summary": changes,
                "status": "sent"
            }
            
            # Em produção, salvar em uma tabela de logs de notificações
            logger.info(f"Notificação registrada para {provider_id}: {log_data}")
            
        except Exception as e:
            logger.error(f"Erro ao registrar notificação: {e}")

    async def _get_provider_data(self, provider_id: str) -> Optional[Dict]:
        """Busca dados de um prestador específico."""
        try:
            response = self.supabase.table("profiles").select(
                "id, email, full_name, created_at, notification_preferences"
            ).eq("id", provider_id).eq("role", "lawyer").single().execute()
            
            return response.data if response.data else None
            
        except Exception as e:
            logger.error(f"Erro ao buscar dados do prestador {provider_id}: {e}")
            return None


# Instância singleton
provider_notifications_service = ProviderNotificationsService() 