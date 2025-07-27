#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Partnership ML Service
======================

Sistema de Machine Learning adaptativo para recomendações de parceria.
Aprende com feedback dos usuários e ajusta pesos automaticamente.

Funcionalidades:
1. **Learning from Feedback**: Coleta feedback sobre relevância das recomendações
2. **Weight Optimization**: Ajusta pesos dos componentes do score via gradient descent
3. **A/B Testing**: Testa diferentes configurações de pesos
4. **Performance Tracking**: Monitora métricas de sucesso das recomendações
5. **Auto-retraining**: Retreina modelo periodicamente com novos dados

Arquitetura similar ao LTR Service do algoritmo_match.py
"""

import asyncio
import json
import logging
import math
import numpy as np
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
import redis.asyncio as aioredis

logger = logging.getLogger(__name__)


@dataclass
class PartnershipFeedback:
    """Feedback do usuário sobre uma recomendação de parceria."""
    user_id: str
    lawyer_id: str  # Advogado que recebeu a recomendação
    recommended_lawyer_id: str  # Advogado recomendado
    feedback_type: str  # 'accepted', 'rejected', 'contacted', 'dismissed'
    feedback_score: float  # 0.0-1.0 (relevância percebida)
    interaction_time_seconds: Optional[int] = None
    feedback_notes: Optional[str] = None
    timestamp: datetime = field(default_factory=datetime.utcnow)


@dataclass
class PartnershipWeights:
    """Pesos otimizados para o algoritmo de parceria."""
    complementarity_weight: float = 0.5
    momentum_weight: float = 0.2
    reputation_weight: float = 0.1
    diversity_weight: float = 0.1
    firm_synergy_weight: float = 0.1
    
    # Sub-pesos para firm synergy
    portfolio_gap_weight: float = 0.5
    strategic_complementarity_weight: float = 0.3
    market_positioning_weight: float = 0.2
    
    # Penalties
    monoexpertise_penalty: float = 0.2
    low_confidence_penalty: float = 0.1
    
    # Learning rate
    learning_rate: float = 0.01
    
    def to_dict(self) -> Dict[str, float]:
        return {
            "complementarity_weight": self.complementarity_weight,
            "momentum_weight": self.momentum_weight,
            "reputation_weight": self.reputation_weight,
            "diversity_weight": self.diversity_weight,
            "firm_synergy_weight": self.firm_synergy_weight,
            "portfolio_gap_weight": self.portfolio_gap_weight,
            "strategic_complementarity_weight": self.strategic_complementarity_weight,
            "market_positioning_weight": self.market_positioning_weight,
            "monoexpertise_penalty": self.monoexpertise_penalty,
            "low_confidence_penalty": self.low_confidence_penalty,
            "learning_rate": self.learning_rate
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, float]) -> 'PartnershipWeights':
        return cls(**{k: v for k, v in data.items() if hasattr(cls, k)})


class PartnershipMLService:
    """Serviço de ML para otimização de recomendações de parceria."""
    
    def __init__(self, db: AsyncSession, redis_url: str = "redis://localhost:6379/0"):
        self.db = db
        self.redis = aioredis.from_url(redis_url, decode_responses=True)
        self.logger = logging.getLogger(__name__)
        
        # Carregar pesos otimizados
        self.weights = self._load_optimized_weights()
        
        # Cache para features calculadas
        self.feature_cache = {}
        
        # Métricas de performance
        self.performance_metrics = {
            "total_recommendations": 0,
            "accepted_recommendations": 0,
            "contacted_recommendations": 0,
            "avg_feedback_score": 0.0,
            "last_optimization": None
        }
    
    def _load_optimized_weights(self) -> PartnershipWeights:
        """Carrega pesos otimizados do arquivo JSON."""
        weights_file = Path("packages/backend/models/partnership_weights.json")
        
        if weights_file.exists():
            try:
                with open(weights_file, 'r') as f:
                    data = json.load(f)
                    self.logger.info("Pesos otimizados carregados do arquivo")
                    return PartnershipWeights.from_dict(data)
            except Exception as e:
                self.logger.warning(f"Erro ao carregar pesos otimizados: {e}")
        
        # Pesos padrão se arquivo não existir
        return PartnershipWeights()
    
    async def save_optimized_weights(self, weights: PartnershipWeights):
        """Salva pesos otimizados no arquivo JSON."""
        weights_file = Path("packages/backend/models/partnership_weights.json")
        weights_file.parent.mkdir(parents=True, exist_ok=True)
        
        try:
            with open(weights_file, 'w') as f:
                json.dump(weights.to_dict(), f, indent=2)
            self.logger.info("Pesos otimizados salvos no arquivo")
        except Exception as e:
            self.logger.error(f"Erro ao salvar pesos otimizados: {e}")
    
    async def record_feedback(self, feedback: PartnershipFeedback):
        """Registra feedback do usuário para treinamento."""
        try:
            # Salvar no banco de dados
            query = text("""
                INSERT INTO partnership_feedback (
                    user_id, lawyer_id, recommended_lawyer_id, feedback_type,
                    feedback_score, interaction_time_seconds, feedback_notes, timestamp
                ) VALUES (
                    :user_id, :lawyer_id, :recommended_lawyer_id, :feedback_type,
                    :feedback_score, :interaction_time_seconds, :feedback_notes, :timestamp
                )
            """)
            
            await self.db.execute(query, {
                "user_id": feedback.user_id,
                "lawyer_id": feedback.lawyer_id,
                "recommended_lawyer_id": feedback.recommended_lawyer_id,
                "feedback_type": feedback.feedback_type,
                "feedback_score": feedback.feedback_score,
                "interaction_time_seconds": feedback.interaction_time_seconds,
                "feedback_notes": feedback.feedback_notes,
                "timestamp": feedback.timestamp
            })
            
            await self.db.commit()
            
            # Atualizar métricas em tempo real
            await self._update_performance_metrics(feedback)
            
            # Cache para treinamento incremental
            await self._cache_feedback_for_training(feedback)
            
            self.logger.info(f"Feedback registrado: {feedback.feedback_type} - score: {feedback.feedback_score}")
            
        except Exception as e:
            self.logger.error(f"Erro ao registrar feedback: {e}")
            await self.db.rollback()
    
    async def _update_performance_metrics(self, feedback: PartnershipFeedback):
        """Atualiza métricas de performance em tempo real."""
        self.performance_metrics["total_recommendations"] += 1
        
        if feedback.feedback_type in ["accepted", "contacted"]:
            self.performance_metrics["accepted_recommendations"] += 1
        
        if feedback.feedback_type == "contacted":
            self.performance_metrics["contacted_recommendations"] += 1
        
        # Média móvel do feedback score
        current_avg = self.performance_metrics["avg_feedback_score"]
        total = self.performance_metrics["total_recommendations"]
        
        self.performance_metrics["avg_feedback_score"] = (
            (current_avg * (total - 1) + feedback.feedback_score) / total
        )
    
    async def _cache_feedback_for_training(self, feedback: PartnershipFeedback):
        """Cache feedback para treinamento incremental."""
        cache_key = f"partnership:feedback:{feedback.lawyer_id}:{feedback.recommended_lawyer_id}"
        
        # Armazenar features e feedback para treinamento
        training_data = {
            "feedback": feedback.feedback_score,
            "timestamp": feedback.timestamp.isoformat(),
            "features": await self._extract_features_for_training(feedback)
        }
        
        await self.redis.setex(cache_key, 86400, json.dumps(training_data))  # 24h TTL
    
    async def _extract_features_for_training(self, feedback: PartnershipFeedback) -> Dict[str, float]:
        """Extrai features da recomendação para treinamento."""
        try:
            # Buscar dados da recomendação original
            query = text("""
                SELECT 
                    lc1.confidence_score as target_confidence,
                    lc2.confidence_score as candidate_confidence,
                    cm1.momentum_score as target_momentum,
                    cm2.momentum_score as candidate_momentum,
                    cm1.total_items as target_cluster_size,
                    cm2.total_items as candidate_cluster_size
                FROM lawyer_clusters lc1
                JOIN lawyer_clusters lc2 ON lc1.cluster_id = lc2.cluster_id
                JOIN cluster_metadata cm1 ON lc1.cluster_id = cm1.cluster_id
                JOIN cluster_metadata cm2 ON lc2.cluster_id = cm2.cluster_id
                WHERE lc1.lawyer_id = :lawyer_id 
                    AND lc2.lawyer_id = :recommended_lawyer_id
                LIMIT 1
            """)
            
            result = await self.db.execute(query, {
                "lawyer_id": feedback.lawyer_id,
                "recommended_lawyer_id": feedback.recommended_lawyer_id
            })
            
            row = result.fetchone()
            if row:
                return {
                    "target_confidence": float(row.target_confidence or 0),
                    "candidate_confidence": float(row.candidate_confidence or 0),
                    "target_momentum": float(row.target_momentum or 0),
                    "candidate_momentum": float(row.candidate_momentum or 0),
                    "target_cluster_size": int(row.target_cluster_size or 0),
                    "candidate_cluster_size": int(row.candidate_cluster_size or 0),
                    "confidence_diff": abs(float(row.target_confidence or 0) - float(row.candidate_confidence or 0)),
                    "momentum_diff": abs(float(row.target_momentum or 0) - float(row.candidate_momentum or 0))
                }
            
            return {}
            
        except Exception as e:
            self.logger.error(f"Erro ao extrair features: {e}")
            return {}
    
    async def optimize_weights(self, min_feedback_count: int = 100):
        """Otimiza pesos baseado no feedback coletado."""
        try:
            # Verificar se há feedback suficiente
            feedback_count = await self._get_feedback_count()
            if feedback_count < min_feedback_count:
                self.logger.info(f"Feedback insuficiente para otimização: {feedback_count}/{min_feedback_count}")
                return False
            
            # Coletar dados de treinamento
            training_data = await self._collect_training_data()
            if not training_data:
                self.logger.warning("Nenhum dado de treinamento encontrado")
                return False
            
            # Otimizar pesos via gradient descent
            optimized_weights = await self._gradient_descent_optimization(training_data)
            
            # Validar melhoria
            if await self._validate_optimization(optimized_weights, training_data):
                self.weights = optimized_weights
                await self.save_optimized_weights(optimized_weights)
                
                self.performance_metrics["last_optimization"] = datetime.utcnow()
                self.logger.info("Pesos otimizados com sucesso")
                return True
            else:
                self.logger.warning("Otimização não melhorou performance - mantendo pesos atuais")
                return False
                
        except Exception as e:
            self.logger.error(f"Erro na otimização de pesos: {e}")
            return False
    
    async def _get_feedback_count(self) -> int:
        """Conta total de feedbacks registrados."""
        query = text("SELECT COUNT(*) FROM partnership_feedback")
        result = await self.db.execute(query)
        return result.scalar() or 0
    
    async def _collect_training_data(self) -> List[Dict[str, Any]]:
        """Coleta dados de treinamento dos últimos 30 dias."""
        query = text("""
            SELECT 
                pf.feedback_score,
                pf.feedback_type,
                pf.timestamp,
                lc1.confidence_score as target_confidence,
                lc2.confidence_score as candidate_confidence,
                cm1.momentum_score as target_momentum,
                cm2.momentum_score as candidate_momentum,
                cm1.total_items as target_cluster_size,
                cm2.total_items as candidate_cluster_size
            FROM partnership_feedback pf
            LEFT JOIN lawyer_clusters lc1 ON pf.lawyer_id = lc1.lawyer_id
            LEFT JOIN lawyer_clusters lc2 ON pf.recommended_lawyer_id = lc2.lawyer_id
            LEFT JOIN cluster_metadata cm1 ON lc1.cluster_id = cm1.cluster_id
            LEFT JOIN cluster_metadata cm2 ON lc2.cluster_id = cm2.cluster_id
            WHERE pf.timestamp >= NOW() - INTERVAL '30 days'
            ORDER BY pf.timestamp DESC
        """)
        
        result = await self.db.execute(query)
        rows = result.fetchall()
        
        training_data = []
        for row in rows:
            training_data.append({
                "feedback_score": float(row.feedback_score),
                "feedback_type": row.feedback_type,
                "target_confidence": float(row.target_confidence or 0),
                "candidate_confidence": float(row.candidate_confidence or 0),
                "target_momentum": float(row.target_momentum or 0),
                "candidate_momentum": float(row.candidate_momentum or 0),
                "target_cluster_size": int(row.target_cluster_size or 0),
                "candidate_cluster_size": int(row.candidate_cluster_size or 0)
            })
        
        return training_data
    
    async def _gradient_descent_optimization(self, training_data: List[Dict[str, Any]]) -> PartnershipWeights:
        """Otimiza pesos via gradient descent."""
        # Inicializar pesos
        weights = PartnershipWeights()
        
        # Hiperparâmetros
        learning_rate = 0.01
        epochs = 100
        batch_size = 32
        
        for epoch in range(epochs):
            total_loss = 0.0
            
            # Processar em batches
            for i in range(0, len(training_data), batch_size):
                batch = training_data[i:i + batch_size]
                batch_loss = 0.0
                
                for sample in batch:
                    # Calcular score predito
                    predicted_score = self._calculate_predicted_score(sample, weights)
                    
                    # Calcular loss (MSE)
                    actual_score = sample["feedback_score"]
                    loss = (predicted_score - actual_score) ** 2
                    batch_loss += loss
                    
                    # Calcular gradientes
                    gradients = self._calculate_gradients(sample, predicted_score, actual_score)
                    
                    # Atualizar pesos
                    weights.complementarity_weight -= learning_rate * gradients.get("complementarity", 0)
                    weights.momentum_weight -= learning_rate * gradients.get("momentum", 0)
                    weights.reputation_weight -= learning_rate * gradients.get("reputation", 0)
                    weights.diversity_weight -= learning_rate * gradients.get("diversity", 0)
                    weights.firm_synergy_weight -= learning_rate * gradients.get("firm_synergy", 0)
                
                total_loss += batch_loss / len(batch)
            
            # Log progresso
            if epoch % 20 == 0:
                self.logger.info(f"Epoch {epoch}: Loss = {total_loss:.6f}")
        
        # Normalizar pesos para somar 1.0
        total_weight = (
            weights.complementarity_weight + weights.momentum_weight + 
            weights.reputation_weight + weights.diversity_weight + 
            weights.firm_synergy_weight
        )
        
        if total_weight > 0:
            weights.complementarity_weight /= total_weight
            weights.momentum_weight /= total_weight
            weights.reputation_weight /= total_weight
            weights.diversity_weight /= total_weight
            weights.firm_synergy_weight /= total_weight
        
        return weights
    
    def _calculate_predicted_score(self, sample: Dict[str, Any], weights: PartnershipWeights) -> float:
        """Calcula score predito baseado nas features e pesos."""
        # Features básicas
        complementarity = (sample["target_confidence"] + sample["candidate_confidence"]) / 2
        momentum = (sample["target_momentum"] + sample["candidate_momentum"]) / 2
        diversity = min(1.0, abs(sample["target_confidence"] - sample["candidate_confidence"]))
        
        # Score predito
        predicted = (
            weights.complementarity_weight * complementarity +
            weights.momentum_weight * momentum +
            weights.reputation_weight * 0.5 +  # Placeholder
            weights.diversity_weight * diversity +
            weights.firm_synergy_weight * 0.5   # Placeholder
        )
        
        return np.clip(predicted, 0, 1)
    
    def _calculate_gradients(self, sample: Dict[str, Any], predicted: float, actual: float) -> Dict[str, float]:
        """Calcula gradientes para cada peso."""
        error = predicted - actual
        
        return {
            "complementarity": error * (sample["target_confidence"] + sample["candidate_confidence"]) / 2,
            "momentum": error * (sample["target_momentum"] + sample["candidate_momentum"]) / 2,
            "reputation": error * 0.5,  # Placeholder
            "diversity": error * min(1.0, abs(sample["target_confidence"] - sample["candidate_confidence"])),
            "firm_synergy": error * 0.5  # Placeholder
        }
    
    async def _validate_optimization(self, new_weights: PartnershipWeights, training_data: List[Dict[str, Any]]) -> bool:
        """Valida se a otimização melhorou a performance."""
        # Calcular performance com pesos antigos
        old_performance = self._calculate_performance(training_data, self.weights)
        
        # Calcular performance com novos pesos
        new_performance = self._calculate_performance(training_data, new_weights)
        
        # Melhoria mínima de 1%
        improvement_threshold = 0.01
        improvement = new_performance - old_performance
        
        self.logger.info(f"Validação de otimização: {old_performance:.4f} → {new_performance:.4f} (Δ{improvement:+.4f})")
        
        return improvement > improvement_threshold
    
    def _calculate_performance(self, training_data: List[Dict[str, Any]], weights: PartnershipWeights) -> float:
        """Calcula performance (R² score) dos pesos."""
        if not training_data:
            return 0.0
        
        predictions = []
        actuals = []
        
        for sample in training_data:
            predicted = self._calculate_predicted_score(sample, weights)
            predictions.append(predicted)
            actuals.append(sample["feedback_score"])
        
        # Calcular R²
        ss_res = sum((p - a) ** 2 for p, a in zip(predictions, actuals))
        ss_tot = sum((a - np.mean(actuals)) ** 2 for a in actuals)
        
        if ss_tot == 0:
            return 0.0
        
        r_squared = 1 - (ss_res / ss_tot)
        return max(0.0, r_squared)
    
    async def get_performance_metrics(self) -> Dict[str, Any]:
        """Retorna métricas de performance atuais."""
        return {
            **self.performance_metrics,
            "acceptance_rate": (
                self.performance_metrics["accepted_recommendations"] / 
                max(self.performance_metrics["total_recommendations"], 1)
            ),
            "contact_rate": (
                self.performance_metrics["contacted_recommendations"] / 
                max(self.performance_metrics["total_recommendations"], 1)
            ),
            "current_weights": self.weights.to_dict()
        }
    
    async def run_ab_test(self, test_config: Dict[str, Any]) -> str:
        """Executa A/B test com diferentes configurações de pesos."""
        test_id = f"ab_test_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}"
        
        # Salvar configuração do teste
        await self.redis.setex(
            f"partnership:ab_test:{test_id}",
            86400 * 7,  # 7 dias
            json.dumps(test_config)
        )
        
        self.logger.info(f"A/B test iniciado: {test_id}")
        return test_id
    
    async def collect_training_data(self, days_back: int = 7) -> List[Dict[str, Any]]:
        """
        Coleta dados de treinamento dos últimos N dias.
        
        Args:
            days_back: Número de dias para coletar dados históricos
            
        Returns:
            Lista de samples de treinamento com features e labels
        """
        cutoff_date = datetime.utcnow() - timedelta(days=days_back)
        
        try:
            # Query para coletar feedback com features
            query = text("""
                SELECT 
                    pf.user_id,
                    pf.lawyer_id,
                    pf.recommended_lawyer_id,
                    pf.feedback_type,
                    pf.feedback_score,
                    pf.interaction_time_seconds,
                    pf.timestamp,
                    -- Features calculadas (simuladas por enquanto)
                    0.75 as complementarity_score,
                    0.65 as momentum_score,
                    0.80 as reputation_score,
                    0.70 as diversity_score,
                    0.60 as firm_synergy_score
                FROM partnership_feedback pf
                WHERE pf.timestamp >= :cutoff_date
                ORDER BY pf.timestamp DESC
            """)
            
            result = await self.db.execute(query, {"cutoff_date": cutoff_date})
            rows = result.fetchall()
            
            training_data = []
            for row in rows:
                training_data.append({
                    "user_id": row.user_id,
                    "lawyer_id": row.lawyer_id,
                    "recommended_lawyer_id": row.recommended_lawyer_id,
                    "feedback_type": row.feedback_type,
                    "feedback_score": float(row.feedback_score),
                    "interaction_time": int(row.interaction_time_seconds or 0),
                    "features": {
                        "complementarity": float(row.complementarity_score),
                        "momentum": float(row.momentum_score),
                        "reputation": float(row.reputation_score),
                        "diversity": float(row.diversity_score),
                        "firm_synergy": float(row.firm_synergy_score)
                    },
                    "timestamp": row.timestamp
                })
            
            self.logger.info(f"Coletados {len(training_data)} samples de treinamento ({days_back} dias)")
            return training_data
            
        except Exception as e:
            self.logger.error(f"Erro ao coletar dados de treinamento: {e}")
            return []
    
    async def optimize_weights_from_feedback(self, min_feedback_count: int = 50) -> Dict[str, Any]:
        """
        Executa otimização de pesos baseada no feedback coletado.
        
        Args:
            min_feedback_count: Mínimo de feedbacks necessários para otimização
            
        Returns:
            Dict com resultado da otimização
        """
        try:
            # Coletar dados de treinamento
            training_data = await self.collect_training_data(days_back=30)
            
            if len(training_data) < min_feedback_count:
                return {
                    "success": False,
                    "error": f"Dados insuficientes: {len(training_data)}/{min_feedback_count}",
                    "training_samples": len(training_data)
                }
            
            # Executar gradient descent
            old_weights = self.weights
            optimized_weights = await self._gradient_descent_optimization(training_data)
            
            # Salvar novos pesos
            self.weights = optimized_weights
            await self.save_optimized_weights(optimized_weights)
            
            # Calcular métricas de melhoria
            performance_improvement = await self._calculate_performance_improvement(
                old_weights, optimized_weights, training_data
            )
            
            # Atualizar timestamp de última otimização
            self.performance_metrics["last_optimization"] = datetime.utcnow()
            
            return {
                "success": True,
                "training_samples": len(training_data),
                "epochs": 100,  # Fixo por enquanto
                "final_loss": performance_improvement.get("final_loss", 0.0),
                "performance_improvement": performance_improvement,
                "old_weights": old_weights.to_dict() if old_weights else {},
                "new_weights": optimized_weights.to_dict(),
                "optimization_timestamp": self.performance_metrics["last_optimization"].isoformat()
            }
            
        except Exception as e:
            self.logger.error(f"Erro na otimização de pesos: {e}")
            return {
                "success": False,
                "error": str(e),
                "training_samples": 0
            }
    
    async def _calculate_performance_improvement(
        self, 
        old_weights: Optional[PartnershipWeights],
        new_weights: PartnershipWeights,
        training_data: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """Calcula métricas de melhoria de performance."""
        
        if not old_weights or len(training_data) == 0:
            return {"final_loss": 0.0, "improvement_percent": 0.0}
        
        # Calcular loss com pesos antigos vs. novos
        old_loss = sum([
            (self._calculate_predicted_score(sample, old_weights) - sample["feedback_score"]) ** 2
            for sample in training_data
        ]) / len(training_data)
        
        new_loss = sum([
            (self._calculate_predicted_score(sample, new_weights) - sample["feedback_score"]) ** 2
            for sample in training_data
        ]) / len(training_data)
        
        improvement_percent = ((old_loss - new_loss) / old_loss * 100) if old_loss > 0 else 0.0
        
        return {
            "old_loss": old_loss,
            "final_loss": new_loss,
            "improvement_percent": improvement_percent,
            "samples_evaluated": len(training_data)
        }

    async def close(self):
        """Fecha conexões."""
        await self.redis.close() 