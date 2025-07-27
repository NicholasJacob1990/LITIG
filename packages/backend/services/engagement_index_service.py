#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Engagement Index Service (IEP)
==============================

Serviço para calcular o Índice de Engajamento na Plataforma (IEP).
Combate oportunismo e recompensa participação genuína no ecossistema.
"""

import logging
import math
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional, Tuple
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text, select, func
from dataclasses import dataclass

logger = logging.getLogger(__name__)


@dataclass
class EngagementMetrics:
    """Métricas de engajamento de um advogado."""
    lawyer_id: str
    
    # Métricas de ofertas e aceitações
    offers_received_30d: int = 0
    offers_accepted_30d: int = 0
    offers_sent_30d: int = 0
    
    # Métricas de comunicação
    messages_sent_30d: int = 0
    messages_received_30d: int = 0
    response_time_avg_hours: float = 48.0
    
    # Métricas de parcerias
    partnerships_initiated_30d: int = 0
    partnerships_completed_30d: int = 0
    partnerships_success_rate: float = 0.0
    
    # Métricas de plataforma
    login_days_30d: int = 0
    profile_updates_30d: int = 0
    cases_worked_30d: int = 0
    
    # Métricas financeiras na plataforma
    revenue_generated_platform_30d: float = 0.0
    contracts_signed_platform_30d: int = 0
    
    # Pontuações calculadas
    current_iep_score: float = 0.5
    previous_iep_score: float = 0.5
    trend: str = "stable"  # "improving", "declining", "stable"


class EngagementIndexService:
    """Serviço para calcular e gerenciar o Índice de Engajamento na Plataforma."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
        self.logger = logging.getLogger(__name__)
    
    async def calculate_engagement_score(self, lawyer_id: str) -> EngagementMetrics:
        """
        Calcula o score de engajamento completo para um advogado.
        
        Fórmula IEP:
        - 25% Responsividade (aceita ofertas, responde rápido)
        - 20% Atividade na plataforma (login, atualizações)
        - 20% Iniciativa (envia ofertas, inicia parcerias)
        - 15% Completion rate (finaliza o que inicia)
        - 10% Revenue share (gera receita na plataforma)
        - 10% Comunidade (ajuda outros, feedback positivo)
        
        Args:
            lawyer_id: ID do advogado
        
        Returns:
            EngagementMetrics com score calculado
        """
        
        try:
            # 1. Buscar métricas brutas
            metrics = await self._collect_raw_metrics(lawyer_id)
            
            # 2. Calcular componentes do IEP
            responsiveness_score = self._calculate_responsiveness_score(metrics)
            activity_score = self._calculate_activity_score(metrics)
            initiative_score = self._calculate_initiative_score(metrics)
            completion_score = self._calculate_completion_score(metrics)
            revenue_score = self._calculate_revenue_score(metrics)
            community_score = self._calculate_community_score(metrics)
            
            # 3. Score final ponderado
            iep_score = (
                responsiveness_score * 0.25 +
                activity_score * 0.20 +
                initiative_score * 0.20 +
                completion_score * 0.15 +
                revenue_score * 0.10 +
                community_score * 0.10
            )
            
            # 4. Normalizar entre 0 e 1
            iep_score = max(0.0, min(1.0, iep_score))
            
            # 5. Calcular trend
            trend = await self._calculate_trend(lawyer_id, iep_score)
            
            # 6. Atualizar métricas
            metrics.current_iep_score = iep_score
            metrics.trend = trend
            
            self.logger.info(f"IEP calculado para {lawyer_id}: {iep_score:.3f} ({trend})")
            
            return metrics
            
        except Exception as e:
            self.logger.error(f"Erro ao calcular IEP para {lawyer_id}: {e}")
            # Retornar métrica neutra em caso de erro
            return EngagementMetrics(
                lawyer_id=lawyer_id,
                current_iep_score=0.5,
                trend="stable"
            )
    
    async def _collect_raw_metrics(self, lawyer_id: str) -> EngagementMetrics:
        """Coleta métricas brutas do banco de dados."""
        
        # Data de corte (30 dias atrás)
        cutoff_date = datetime.utcnow() - timedelta(days=30)
        
        metrics = EngagementMetrics(lawyer_id=lawyer_id)
        
        try:
            # Query de ofertas recebidas e aceitas
            offers_query = text("""
                SELECT 
                    COUNT(*) as total_received,
                    COUNT(CASE WHEN status = 'accepted' THEN 1 END) as total_accepted
                FROM case_offers 
                WHERE lawyer_id = :lawyer_id 
                AND created_at >= :cutoff_date
            """)
            
            result = await self.db.execute(offers_query, {
                "lawyer_id": lawyer_id, 
                "cutoff_date": cutoff_date
            })
            row = result.fetchone()
            if row:
                metrics.offers_received_30d = row.total_received or 0
                metrics.offers_accepted_30d = row.total_accepted or 0
            
            # Query de mensagens (chat/comunicação)
            messages_query = text("""
                SELECT 
                    COUNT(CASE WHEN sender_id = :lawyer_id THEN 1 END) as sent,
                    COUNT(CASE WHEN receiver_id = :lawyer_id THEN 1 END) as received,
                    AVG(CASE WHEN receiver_id = :lawyer_id AND response_time_hours IS NOT NULL 
                        THEN response_time_hours END) as avg_response_time
                FROM chat_messages 
                WHERE (sender_id = :lawyer_id OR receiver_id = :lawyer_id)
                AND created_at >= :cutoff_date
            """)
            
            result = await self.db.execute(messages_query, {
                "lawyer_id": lawyer_id,
                "cutoff_date": cutoff_date
            })
            row = result.fetchone()
            if row:
                metrics.messages_sent_30d = row.sent or 0
                metrics.messages_received_30d = row.received or 0
                metrics.response_time_avg_hours = row.avg_response_time or 48.0
            
            # Query de parcerias
            partnerships_query = text("""
                SELECT 
                    COUNT(CASE WHEN initiator_id = :lawyer_id THEN 1 END) as initiated,
                    COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed,
                    COUNT(*) as total
                FROM partnerships 
                WHERE (initiator_id = :lawyer_id OR partner_id = :lawyer_id)
                AND created_at >= :cutoff_date
            """)
            
            result = await self.db.execute(partnerships_query, {
                "lawyer_id": lawyer_id,
                "cutoff_date": cutoff_date
            })
            row = result.fetchone()
            if row:
                metrics.partnerships_initiated_30d = row.initiated or 0
                metrics.partnerships_completed_30d = row.completed or 0
                total_partnerships = row.total or 0
                if total_partnerships > 0:
                    metrics.partnerships_success_rate = row.completed / total_partnerships
            
            # Query de atividade na plataforma
            activity_query = text("""
                SELECT 
                    COUNT(DISTINCT DATE(login_time)) as login_days,
                    COUNT(CASE WHEN action_type = 'profile_update' THEN 1 END) as profile_updates
                FROM user_activity_logs 
                WHERE user_id = :lawyer_id 
                AND created_at >= :cutoff_date
            """)
            
            result = await self.db.execute(activity_query, {
                "lawyer_id": lawyer_id,
                "cutoff_date": cutoff_date
            })
            row = result.fetchone()
            if row:
                metrics.login_days_30d = row.login_days or 0
                metrics.profile_updates_30d = row.profile_updates or 0
            
            # Query de casos trabalhados
            cases_query = text("""
                SELECT COUNT(DISTINCT case_id) as cases_worked
                FROM case_lawyer_assignments 
                WHERE lawyer_id = :lawyer_id 
                AND created_at >= :cutoff_date
            """)
            
            result = await self.db.execute(cases_query, {
                "lawyer_id": lawyer_id,
                "cutoff_date": cutoff_date
            })
            row = result.fetchone()
            if row:
                metrics.cases_worked_30d = row.cases_worked or 0
            
            # Query de receita na plataforma
            revenue_query = text("""
                SELECT 
                    COALESCE(SUM(amount), 0) as total_revenue,
                    COUNT(*) as contracts_signed
                FROM platform_transactions 
                WHERE lawyer_id = :lawyer_id 
                AND transaction_type = 'lawyer_fee'
                AND created_at >= :cutoff_date
            """)
            
            result = await self.db.execute(revenue_query, {
                "lawyer_id": lawyer_id,
                "cutoff_date": cutoff_date
            })
            row = result.fetchone()
            if row:
                metrics.revenue_generated_platform_30d = float(row.total_revenue or 0)
                metrics.contracts_signed_platform_30d = row.contracts_signed or 0
            
            return metrics
            
        except Exception as e:
            self.logger.error(f"Erro ao coletar métricas para {lawyer_id}: {e}")
            return metrics
    
    def _calculate_responsiveness_score(self, metrics: EngagementMetrics) -> float:
        """Calcula score de responsividade (0-1)."""
        
        # Taxa de aceitação de ofertas
        acceptance_rate = 0.0
        if metrics.offers_received_30d > 0:
            acceptance_rate = metrics.offers_accepted_30d / metrics.offers_received_30d
        
        # Score de tempo de resposta (melhor = menor)
        response_score = max(0.0, 1.0 - (metrics.response_time_avg_hours / 72.0))  # 72h = score 0
        
        # Combinação ponderada
        return 0.6 * acceptance_rate + 0.4 * response_score
    
    def _calculate_activity_score(self, metrics: EngagementMetrics) -> float:
        """Calcula score de atividade na plataforma (0-1)."""
        
        # Frequência de login (30 dias = score máximo)
        login_score = min(1.0, metrics.login_days_30d / 30.0)
        
        # Atualizações de perfil (2+ = score máximo)
        profile_score = min(1.0, metrics.profile_updates_30d / 2.0)
        
        # Casos trabalhados (5+ = score máximo)
        cases_score = min(1.0, metrics.cases_worked_30d / 5.0)
        
        # Média ponderada
        return 0.4 * login_score + 0.3 * profile_score + 0.3 * cases_score
    
    def _calculate_initiative_score(self, metrics: EngagementMetrics) -> float:
        """Calcula score de iniciativa (0-1)."""
        
        # Mensagens enviadas (20+ = score máximo)
        messages_score = min(1.0, metrics.messages_sent_30d / 20.0)
        
        # Parcerias iniciadas (3+ = score máximo)
        partnerships_score = min(1.0, metrics.partnerships_initiated_30d / 3.0)
        
        # Combinação
        return 0.6 * messages_score + 0.4 * partnerships_score
    
    def _calculate_completion_score(self, metrics: EngagementMetrics) -> float:
        """Calcula score de completion rate (0-1)."""
        
        # Taxa de sucesso em parcerias
        partnership_completion = metrics.partnerships_success_rate
        
        # Se tem atividade mas baixa completion, penalizar
        if metrics.partnerships_initiated_30d > 0:
            return partnership_completion
        else:
            # Sem atividade = score neutro
            return 0.5
    
    def _calculate_revenue_score(self, metrics: EngagementMetrics) -> float:
        """Calcula score de geração de receita na plataforma (0-1)."""
        
        # Score baseado em contratos assinados na plataforma
        contracts_score = min(1.0, metrics.contracts_signed_platform_30d / 3.0)  # 3+ contratos = máximo
        
        # Score baseado em receita (normalizado por valor médio)
        revenue_score = 0.0
        if metrics.revenue_generated_platform_30d > 0:
            # Assumindo R$ 5000 como receita média mensal para score máximo
            revenue_score = min(1.0, metrics.revenue_generated_platform_30d / 5000.0)
        
        return 0.7 * contracts_score + 0.3 * revenue_score
    
    def _calculate_community_score(self, metrics: EngagementMetrics) -> float:
        """Calcula score de contribuição para a comunidade (0-1)."""
        
        # Baseado em ratio de mensagens recebidas vs enviadas (indica se outros procuram o advogado)
        community_ratio = 0.5  # Neutro por padrão
        
        if metrics.messages_sent_30d > 0:
            ratio = metrics.messages_received_30d / metrics.messages_sent_30d
            # Ratio > 1 indica que outros procuram mais este advogado
            community_ratio = min(1.0, ratio / 2.0)  # 2:1 = score máximo
        
        return community_ratio
    
    async def _calculate_trend(self, lawyer_id: str, current_score: float) -> str:
        """Calcula tendência comparando com score anterior."""
        
        try:
            # Buscar score anterior (última calculada)
            trend_query = text("""
                SELECT iep_score 
                FROM lawyer_engagement_history 
                WHERE lawyer_id = :lawyer_id 
                ORDER BY calculated_at DESC 
                LIMIT 1 OFFSET 1
            """)
            
            result = await self.db.execute(trend_query, {"lawyer_id": lawyer_id})
            row = result.fetchone()
            
            if row:
                previous_score = float(row.iep_score)
                diff = current_score - previous_score
                
                if diff > 0.05:
                    return "improving"
                elif diff < -0.05:
                    return "declining"
                else:
                    return "stable"
            
            return "stable"
            
        except Exception as e:
            self.logger.error(f"Erro ao calcular trend para {lawyer_id}: {e}")
            return "stable"
    
    async def save_engagement_score(self, metrics: EngagementMetrics) -> bool:
        """Salva o score de engajamento no banco de dados."""
        
        try:
            # Salvar na tabela principal
            update_query = text("""
                UPDATE lawyers 
                SET 
                    interaction_score = :iep_score,
                    engagement_trend = :trend,
                    engagement_updated_at = CURRENT_TIMESTAMP
                WHERE id = :lawyer_id
            """)
            
            await self.db.execute(update_query, {
                "iep_score": metrics.current_iep_score,
                "trend": metrics.trend,
                "lawyer_id": metrics.lawyer_id
            })
            
            # Salvar histórico
            history_query = text("""
                INSERT INTO lawyer_engagement_history 
                (lawyer_id, iep_score, metrics_json, calculated_at)
                VALUES (:lawyer_id, :iep_score, :metrics_json, CURRENT_TIMESTAMP)
            """)
            
            # Serializar métricas para JSON
            metrics_json = {
                "offers_received_30d": metrics.offers_received_30d,
                "offers_accepted_30d": metrics.offers_accepted_30d,
                "messages_sent_30d": metrics.messages_sent_30d,
                "partnerships_initiated_30d": metrics.partnerships_initiated_30d,
                "login_days_30d": metrics.login_days_30d,
                "revenue_generated_platform_30d": metrics.revenue_generated_platform_30d,
                "trend": metrics.trend
            }
            
            await self.db.execute(history_query, {
                "lawyer_id": metrics.lawyer_id,
                "iep_score": metrics.current_iep_score,
                "metrics_json": metrics_json
            })
            
            await self.db.commit()
            
            self.logger.info(f"IEP salvo para {metrics.lawyer_id}: {metrics.current_iep_score:.3f}")
            return True
            
        except Exception as e:
            await self.db.rollback()
            self.logger.error(f"Erro ao salvar IEP para {metrics.lawyer_id}: {e}")
            return False
    
    async def calculate_batch_scores(self, lawyer_ids: List[str]) -> Dict[str, float]:
        """Calcula scores IEP para múltiplos advogados em batch."""
        
        results = {}
        
        for lawyer_id in lawyer_ids:
            try:
                metrics = await self.calculate_engagement_score(lawyer_id)
                await self.save_engagement_score(metrics)
                results[lawyer_id] = metrics.current_iep_score
                
            except Exception as e:
                self.logger.error(f"Erro no batch para {lawyer_id}: {e}")
                results[lawyer_id] = 0.5  # Score neutro em caso de erro
        
        self.logger.info(f"Batch IEP calculado para {len(results)} advogados")
        return results
    
    async def get_engagement_leaderboard(self, limit: int = 50) -> List[Dict[str, Any]]:
        """Retorna ranking dos advogados com maior IEP."""
        
        try:
            query = text("""
                SELECT 
                    l.id,
                    l.name,
                    l.interaction_score,
                    l.engagement_trend,
                    l.engagement_updated_at
                FROM lawyers l
                WHERE l.interaction_score IS NOT NULL
                ORDER BY l.interaction_score DESC
                LIMIT :limit
            """)
            
            result = await self.db.execute(query, {"limit": limit})
            rows = result.fetchall()
            
            leaderboard = []
            for i, row in enumerate(rows, 1):
                leaderboard.append({
                    "rank": i,
                    "lawyer_id": row.id,
                    "name": row.name,
                    "iep_score": round(float(row.interaction_score), 3),
                    "trend": row.engagement_trend,
                    "last_updated": row.engagement_updated_at.isoformat() if row.engagement_updated_at else None
                })
            
            return leaderboard
            
        except Exception as e:
            self.logger.error(f"Erro ao buscar leaderboard: {e}")
            return [] 