#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Cluster Momentum Service
========================

Serviço para detecção de clusters emergentes e cálculo de momentum.
Implementa algoritmos de crescimento temporal e marcação automática de nichos emergentes.

Features:
- Cálculo de momentum baseado em crescimento temporal
- Detecção automática de clusters emergentes
- Análise de tendências e velocidade de crescimento
- Métricas de qualidade e relevância
"""

import asyncio
import logging
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional, Tuple
from dataclasses import dataclass
from enum import Enum
import numpy as np
from scipy import stats
import json

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, text, and_, or_, func, desc
from sqlalchemy.sql import text


class MomentumTrend(Enum):
    """Tendências de momentum possíveis."""
    RAPIDLY_INCREASING = "rapidly_increasing"
    INCREASING = "increasing"
    STABLE = "stable"
    DECREASING = "decreasing"
    RAPIDLY_DECREASING = "rapidly_decreasing"


@dataclass
class MomentumMetrics:
    """Métricas de momentum de um cluster."""
    cluster_id: str
    current_momentum: float
    growth_rate: float
    velocity: float
    acceleration: float
    trend: MomentumTrend
    is_emergent: bool
    emergent_confidence: float
    stability_score: float
    market_potential: float
    data_points: int
    calculation_date: datetime


@dataclass
class EmergentClusterAlert:
    """Alerta de cluster emergente detectado."""
    cluster_id: str
    cluster_label: str
    detection_date: datetime
    momentum_score: float
    growth_rate: float
    market_opportunity: str
    recommended_actions: List[str]
    urgency_level: str


class ClusterMomentumService:
    """Serviço para análise de momentum e detecção de clusters emergentes."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
        self.logger = logging.getLogger(__name__)
        
        # Configurações do algoritmo
        self.EMERGENT_THRESHOLD = 0.7  # Threshold para marcar como emergente
        self.MIN_DATA_POINTS = 5       # Mínimo de pontos para análise
        self.LOOKBACK_DAYS = 30        # Período de análise em dias
        self.VELOCITY_WEIGHT = 0.4     # Peso da velocidade no cálculo
        self.GROWTH_WEIGHT = 0.3       # Peso do crescimento no cálculo
        self.STABILITY_WEIGHT = 0.3    # Peso da estabilidade no cálculo
    
    async def calculate_cluster_momentum(self, cluster_id: str) -> Optional[MomentumMetrics]:
        """
        Calcula métricas de momentum para um cluster específico.
        
        Args:
            cluster_id: ID do cluster para análise
            
        Returns:
            Métricas de momentum ou None se dados insuficientes
        """
        
        try:
            self.logger.info(f"📊 Calculando momentum para cluster {cluster_id}")
            
            # 1. Buscar histórico de crescimento do cluster
            history_data = await self._get_cluster_growth_history(cluster_id)
            
            if len(history_data) < self.MIN_DATA_POINTS:
                self.logger.warning(f"❌ Dados insuficientes para {cluster_id}: {len(history_data)} pontos")
                return None
            
            # 2. Calcular métricas de crescimento
            growth_metrics = self._calculate_growth_metrics(history_data)
            
            # 3. Calcular momentum composto
            momentum_score = self._calculate_composite_momentum(growth_metrics)
            
            # 4. Determinar se é emergente
            is_emergent, emergent_confidence = self._detect_emergent_pattern(growth_metrics)
            
            # 5. Calcular potencial de mercado
            market_potential = await self._calculate_market_potential(cluster_id, growth_metrics)
            
            # 6. Determinar tendência
            trend = self._determine_trend(growth_metrics)
            
            metrics = MomentumMetrics(
                cluster_id=cluster_id,
                current_momentum=momentum_score,
                growth_rate=growth_metrics["growth_rate"],
                velocity=growth_metrics["velocity"],
                acceleration=growth_metrics["acceleration"],
                trend=trend,
                is_emergent=is_emergent,
                emergent_confidence=emergent_confidence,
                stability_score=growth_metrics["stability"],
                market_potential=market_potential,
                data_points=len(history_data),
                calculation_date=datetime.now()
            )
            
            self.logger.info(f"✅ Momentum calculado para {cluster_id}: {momentum_score:.3f}")
            return metrics
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao calcular momentum para {cluster_id}: {e}")
            return None
    
    async def detect_emergent_clusters(self, cluster_type: str = "case") -> List[EmergentClusterAlert]:
        """
        Detecta clusters emergentes no sistema.
        
        Args:
            cluster_type: Tipo de cluster ('case' ou 'lawyer')
            
        Returns:
            Lista de alertas de clusters emergentes
        """
        
        try:
            self.logger.info(f"🚀 Detectando clusters emergentes: {cluster_type}")
            
            # 1. Buscar clusters ativos com dados suficientes
            active_clusters = await self._get_active_clusters(cluster_type)
            
            emergent_alerts = []
            
            # 2. Analisar cada cluster
            for cluster_data in active_clusters:
                cluster_id = cluster_data["cluster_id"]
                
                # Calcular momentum
                momentum_metrics = await self.calculate_cluster_momentum(cluster_id)
                
                if momentum_metrics and momentum_metrics.is_emergent:
                    # Gerar alerta
                    alert = await self._generate_emergent_alert(cluster_data, momentum_metrics)
                    if alert:
                        emergent_alerts.append(alert)
            
            # 3. Ordenar por prioridade/momentum
            emergent_alerts.sort(key=lambda x: x.momentum_score, reverse=True)
            
            self.logger.info(f"✅ {len(emergent_alerts)} clusters emergentes detectados")
            return emergent_alerts
            
        except Exception as e:
            self.logger.error(f"❌ Erro na detecção de clusters emergentes: {e}")
            return []
    
    async def update_cluster_momentum_history(self, cluster_id: str, total_items: int) -> bool:
        """
        Atualiza histórico de momentum de um cluster.
        
        Args:
            cluster_id: ID do cluster
            total_items: Número atual de itens no cluster
            
        Returns:
            True se atualizado com sucesso
        """
        
        try:
            # Inserir novo ponto de dados no histórico
            insert_query = text("""
                INSERT INTO cluster_momentum_history 
                (cluster_id, total_items, momentum_score, recorded_at)
                VALUES (:cluster_id, :total_items, :momentum_score, NOW())
                ON CONFLICT (cluster_id, recorded_at::date) 
                DO UPDATE SET 
                    total_items = :total_items,
                    momentum_score = :momentum_score
            """)
            
            # Calcular momentum atual (simplificado para inserção inicial)
            momentum_score = min(total_items / 100.0, 1.0)  # Normalizado
            
            await self.db.execute(insert_query, {
                "cluster_id": cluster_id,
                "total_items": total_items,
                "momentum_score": momentum_score
            })
            
            await self.db.commit()
            return True
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao atualizar histórico de momentum: {e}")
            await self.db.rollback()
            return False
    
    async def mark_cluster_as_emergent(self, cluster_id: str, momentum_metrics: MomentumMetrics) -> bool:
        """
        Marca um cluster como emergente no banco de dados.
        
        Args:
            cluster_id: ID do cluster
            momentum_metrics: Métricas calculadas
            
        Returns:
            True se marcado com sucesso
        """
        
        try:
            update_query = text("""
                UPDATE cluster_metadata 
                SET 
                    is_emergent = true,
                    emergent_since = CASE 
                        WHEN emergent_since IS NULL THEN NOW() 
                        ELSE emergent_since 
                    END,
                    momentum_score = :momentum_score,
                    last_updated = NOW()
                WHERE cluster_id = :cluster_id
            """)
            
            await self.db.execute(update_query, {
                "cluster_id": cluster_id,
                "momentum_score": momentum_metrics.current_momentum
            })
            
            await self.db.commit()
            
            self.logger.info(f"🚀 Cluster {cluster_id} marcado como emergente")
            return True
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao marcar cluster como emergente: {e}")
            await self.db.rollback()
            return False
    
    # Métodos auxiliares privados
    
    async def _get_cluster_growth_history(self, cluster_id: str) -> List[Dict[str, Any]]:
        """Busca histórico de crescimento de um cluster."""
        
        history_query = text("""
            SELECT 
                recorded_at,
                total_items,
                momentum_score,
                EXTRACT(EPOCH FROM (recorded_at - LAG(recorded_at) OVER (ORDER BY recorded_at))) / 86400 as days_diff,
                total_items - LAG(total_items) OVER (ORDER BY recorded_at) as items_diff
            FROM cluster_momentum_history
            WHERE cluster_id = :cluster_id
                AND recorded_at >= NOW() - INTERVAL ':lookback_days days'
            ORDER BY recorded_at ASC
        """)
        
        result = await self.db.execute(history_query, {
            "cluster_id": cluster_id,
            "lookback_days": self.LOOKBACK_DAYS
        })
        
        history_data = []
        for row in result.fetchall():
            history_data.append({
                "recorded_at": row.recorded_at,
                "total_items": row.total_items,
                "momentum_score": row.momentum_score or 0.0,
                "days_diff": row.days_diff or 1.0,
                "items_diff": row.items_diff or 0
            })
        
        return history_data
    
    def _calculate_growth_metrics(self, history_data: List[Dict]) -> Dict[str, float]:
        """Calcula métricas de crescimento baseadas no histórico."""
        
        if len(history_data) < 2:
            return {"growth_rate": 0.0, "velocity": 0.0, "acceleration": 0.0, "stability": 0.0}
        
        # Extrair séries temporais
        items_series = np.array([point["total_items"] for point in history_data])
        days_series = np.array([i for i in range(len(history_data))])
        
        # 1. Taxa de crescimento (regressão linear)
        if len(items_series) > 1:
            slope, intercept, r_value, p_value, std_err = stats.linregress(days_series, items_series)
            growth_rate = max(0.0, slope / max(np.mean(items_series), 1.0))  # Normalizado
        else:
            growth_rate = 0.0
        
        # 2. Velocidade (média das diferenças)
        velocities = []
        for i in range(1, len(history_data)):
            items_diff = history_data[i]["items_diff"]
            days_diff = history_data[i]["days_diff"]
            velocity = items_diff / max(days_diff, 1.0)
            velocities.append(velocity)
        
        avg_velocity = np.mean(velocities) if velocities else 0.0
        
        # 3. Aceleração (mudança na velocidade)
        if len(velocities) >= 2:
            acceleration = np.mean(np.diff(velocities))
        else:
            acceleration = 0.0
        
        # 4. Estabilidade (consistência do crescimento)
        stability = 1.0 - (np.std(velocities) / max(np.mean(velocities), 1.0)) if velocities else 0.0
        stability = max(0.0, min(1.0, stability))
        
        return {
            "growth_rate": growth_rate,
            "velocity": avg_velocity,
            "acceleration": acceleration,
            "stability": stability,
            "r_squared": r_value ** 2 if 'r_value' in locals() else 0.0
        }
    
    def _calculate_composite_momentum(self, growth_metrics: Dict[str, float]) -> float:
        """Calcula momentum composto baseado nas métricas."""
        
        # Normalizar métricas
        normalized_velocity = min(growth_metrics["velocity"] / 10.0, 1.0)  # Assumindo max 10 itens/dia
        normalized_growth = min(growth_metrics["growth_rate"], 1.0)
        normalized_stability = growth_metrics["stability"]
        
        # Calcular momentum ponderado
        momentum = (
            normalized_velocity * self.VELOCITY_WEIGHT +
            normalized_growth * self.GROWTH_WEIGHT +
            normalized_stability * self.STABILITY_WEIGHT
        )
        
        # Bonus por aceleração positiva
        if growth_metrics["acceleration"] > 0:
            momentum *= 1.2
        
        return min(momentum, 1.0)
    
    def _detect_emergent_pattern(self, growth_metrics: Dict[str, float]) -> Tuple[bool, float]:
        """Detecta se o padrão indica um cluster emergente."""
        
        # Critérios para detecção
        criteria_scores = []
        
        # 1. Crescimento acelerado
        if growth_metrics["growth_rate"] > 0.5:
            criteria_scores.append(0.4)
        elif growth_metrics["growth_rate"] > 0.3:
            criteria_scores.append(0.2)
        
        # 2. Velocidade alta
        if growth_metrics["velocity"] > 2.0:
            criteria_scores.append(0.3)
        elif growth_metrics["velocity"] > 1.0:
            criteria_scores.append(0.15)
        
        # 3. Aceleração positiva
        if growth_metrics["acceleration"] > 0:
            criteria_scores.append(0.2)
        
        # 4. Estabilidade do crescimento
        if growth_metrics["stability"] > 0.6:
            criteria_scores.append(0.1)
        
        confidence = sum(criteria_scores)
        is_emergent = confidence >= 0.6  # Threshold para classificação
        
        return is_emergent, confidence
    
    async def _calculate_market_potential(self, cluster_id: str, growth_metrics: Dict[str, float]) -> float:
        """Calcula potencial de mercado do cluster."""
        
        # Implementação simplificada - pode ser expandida
        base_potential = growth_metrics["growth_rate"] * 0.5
        velocity_factor = min(growth_metrics["velocity"] / 5.0, 0.3)
        stability_factor = growth_metrics["stability"] * 0.2
        
        market_potential = base_potential + velocity_factor + stability_factor
        return min(market_potential, 1.0)
    
    def _determine_trend(self, growth_metrics: Dict[str, float]) -> MomentumTrend:
        """Determina tendência baseada nas métricas."""
        
        growth_rate = growth_metrics["growth_rate"]
        acceleration = growth_metrics["acceleration"]
        
        if growth_rate > 0.7 and acceleration > 0:
            return MomentumTrend.RAPIDLY_INCREASING
        elif growth_rate > 0.3:
            return MomentumTrend.INCREASING
        elif growth_rate > -0.1 and growth_rate <= 0.3:
            return MomentumTrend.STABLE
        elif growth_rate > -0.5:
            return MomentumTrend.DECREASING
        else:
            return MomentumTrend.RAPIDLY_DECREASING
    
    async def _get_active_clusters(self, cluster_type: str) -> List[Dict[str, Any]]:
        """Busca clusters ativos para análise."""
        
        query = text("""
            SELECT 
                cm.cluster_id,
                cm.cluster_label,
                cm.total_items,
                cm.momentum_score,
                cm.is_emergent,
                cm.last_updated,
                cl.label as generated_label
            FROM cluster_metadata cm
            LEFT JOIN {}_cluster_labels cl ON cm.cluster_id = cl.cluster_id
            WHERE cm.cluster_type = :cluster_type
                AND cm.total_items >= 3
                AND cm.cluster_id NOT LIKE '%_-1'
                AND cm.last_updated >= NOW() - INTERVAL '7 days'
            ORDER BY cm.total_items DESC
        """.format(cluster_type))
        
        result = await self.db.execute(query, {"cluster_type": cluster_type})
        
        return [dict(row._mapping) for row in result.fetchall()]
    
    async def _generate_emergent_alert(self, cluster_data: Dict, momentum_metrics: MomentumMetrics) -> Optional[EmergentClusterAlert]:
        """Gera alerta para cluster emergente."""
        
        try:
            cluster_label = cluster_data.get("generated_label") or cluster_data.get("cluster_label") or "Nicho Emergente"
            
            # Determinar oportunidade de mercado
            if momentum_metrics.market_potential > 0.8:
                market_opportunity = "Alto potencial de crescimento e demanda crescente"
            elif momentum_metrics.market_potential > 0.6:
                market_opportunity = "Potencial moderado com tendência positiva"
            else:
                market_opportunity = "Nicho específico com crescimento inicial"
            
            # Ações recomendadas baseadas no momentum
            recommended_actions = [
                "Investigar demanda de mercado para este nicho",
                "Capacitar equipe para atender casos similares",
                "Desenvolver marketing direcionado"
            ]
            
            if momentum_metrics.current_momentum > 0.8:
                recommended_actions.append("Priorizar captação neste segmento")
                urgency_level = "high"
            elif momentum_metrics.current_momentum > 0.6:
                urgency_level = "medium"
            else:
                urgency_level = "low"
            
            alert = EmergentClusterAlert(
                cluster_id=momentum_metrics.cluster_id,
                cluster_label=cluster_label,
                detection_date=datetime.now(),
                momentum_score=momentum_metrics.current_momentum,
                growth_rate=momentum_metrics.growth_rate,
                market_opportunity=market_opportunity,
                recommended_actions=recommended_actions,
                urgency_level=urgency_level
            )
            
            return alert
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao gerar alerta emergente: {e}")
            return None


# Função de conveniência para criar o serviço
def create_momentum_service(db: AsyncSession) -> ClusterMomentumService:
    """Factory function para criar ClusterMomentumService."""
    return ClusterMomentumService(db) 