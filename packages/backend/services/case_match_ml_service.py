#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Case Match ML Service
====================

🆕 FASE 2: Sistema de Machine Learning adaptativo para matching casos-advogados.
Baseado no PartnershipMLService, mas adaptado para o contexto de casos jurídicos.

Funcionalidades:
1. **Learning from Case Outcomes**: Aprende com resultados reais dos casos
2. **Feature Weight Optimization**: Ajusta pesos A,S,T,G,Q,U,R,C,E,P,M,I via gradient descent
3. **Preset Optimization**: Otimiza presets (fast, expert, balanced, etc.) dinamicamente
4. **Context-Aware Learning**: Adapta por área jurídica, complexidade e tipo de caso
5. **A/B Testing**: Testa variantes de pesos em produção
6. **Performance Tracking**: Monitora hire rate, satisfaction e success rate

Integração com algoritmo_match.py via get_optimized_weights() e record_feedback()
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
class CaseFeedback:
    """Feedback de outcome de um caso para treinamento do algoritmo."""
    case_id: str
    lawyer_id: str
    client_id: str
    
    # Outcomes principais
    hired: bool  # Cliente contratou o advogado?
    client_satisfaction: float  # 0.0-5.0 rating do cliente
    case_success: bool  # Caso foi bem-sucedido?
    case_outcome_value: Optional[float] = None  # Valor recuperado/economizado
    
    # Métricas de processo
    response_time_hours: Optional[float] = None  # Tempo real de resposta
    negotiation_rounds: Optional[int] = None  # Rounds de negociação
    case_duration_days: Optional[int] = None  # Duração total do caso
    
    # Contexto do caso  
    case_area: str = ""
    case_complexity: str = "MEDIUM"
    case_urgency_hours: int = 48
    case_value_range: str = "unknown"  # low, medium, high
    
    # Contexto do match
    lawyer_rank_position: int = 1  # Posição no ranking (1=primeiro)
    total_candidates: int = 5  # Total de candidatos apresentados
    match_score: float = 0.0  # Score que o algoritmo deu
    features_used: Dict[str, float] = field(default_factory=dict)  # Features A,S,T,etc
    preset_used: str = "balanced"
    
    # Metadata
    feedback_source: str = "client"  # client, admin, automatic
    feedback_notes: Optional[str] = None
    timestamp: datetime = field(default_factory=datetime.utcnow)


@dataclass  
class CaseMatchWeights:
    """Pesos otimizados para as 12 features do algoritmo de matching."""
    
    # Features principais (soma deve ser ~1.0)
    A: float = 0.23  # Area match
    S: float = 0.18  # Case similarity  
    T: float = 0.11  # Success rate
    G: float = 0.07  # Geographic score
    Q: float = 0.07  # Qualification score
    U: float = 0.05  # Urgency capacity
    R: float = 0.05  # Review score
    C: float = 0.03  # Soft skills (Communication)
    E: float = 0.02  # Employer/Firm reputation
    P: float = 0.02  # Price fit
    M: float = 0.15  # Maturity score
    I: float = 0.02  # Interaction score (IEP)
    
    # Multipliers contextuais
    urgency_multiplier: float = 1.0  # Boost para casos urgentes
    complexity_multiplier: float = 1.0  # Boost para casos complexos
    premium_multiplier: float = 1.0  # Boost para casos premium
    
    # Penalties
    overload_penalty: float = 0.1  # Penalidade por sobrecarga
    conflict_penalty: float = 1.0  # Penalidade por conflito
    
    # Learning parameters
    learning_rate: float = 0.01
    
    def to_dict(self) -> Dict[str, float]:
        """Converte para formato compatível com algoritmo_match.py"""
        return {
            "A": self.A, "S": self.S, "T": self.T, "G": self.G,
            "Q": self.Q, "U": self.U, "R": self.R, "C": self.C,
            "E": self.E, "P": self.P, "M": self.M, "I": self.I,
            "urgency_multiplier": self.urgency_multiplier,
            "complexity_multiplier": self.complexity_multiplier,
            "premium_multiplier": self.premium_multiplier,
            "overload_penalty": self.overload_penalty,
            "conflict_penalty": self.conflict_penalty,
            "learning_rate": self.learning_rate
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, float]) -> 'CaseMatchWeights':
        # Filtrar apenas campos válidos para evitar erros
        valid_fields = {k: v for k, v in data.items() if hasattr(cls, k)}
        return cls(**valid_fields)
    
    def normalize(self) -> 'CaseMatchWeights':
        """Normaliza os pesos principais para somar 1.0"""
        features = ["A", "S", "T", "G", "Q", "U", "R", "C", "E", "P", "M", "I"]
        total = sum(getattr(self, f) for f in features)
        
        if total > 0:
            factor = 1.0 / total
            for feature in features:
                setattr(self, feature, getattr(self, feature) * factor)
        
        return self
    
    def validate(self) -> bool:
        """Valida se os pesos estão em ranges válidos"""
        features = ["A", "S", "T", "G", "Q", "U", "R", "C", "E", "P", "M", "I"]
        
        # Cada feature deve estar entre 0 e 1
        for feature in features:
            value = getattr(self, feature)
            if not (0.0 <= value <= 1.0):
                return False
        
        # Soma total deve estar próxima de 1.0 (±10%)
        total = sum(getattr(self, f) for f in features)
        if not (0.9 <= total <= 1.1):
            return False
            
        return True


class CaseMatchMLService:
    """
    🆕 FASE 2: Serviço de ML para otimização do algoritmo de matching casos-advogados.
    
    Funciona como um AutoML que:
    1. Coleta feedback de outcomes reais dos casos
    2. Otimiza pesos das features automaticamente
    3. Adapta por contexto (área, complexidade, etc.)
    4. Executa A/B testing de variantes
    """
    
    def __init__(self, db: AsyncSession, redis_url: str = "redis://localhost:6379/0"):
        self.db = db
        self.redis = aioredis.from_url(redis_url, decode_responses=True)
        self.logger = logging.getLogger(__name__)
        
        # Carregar pesos otimizados
        self.weights = self._load_optimized_weights()
        self.preset_weights = self._load_preset_weights()
        
        # Cache para evitar recálculos
        self.optimization_cache = {}
        
        # Métricas de performance
        self.performance_metrics = {
            "total_cases": 0,
            "hired_rate": 0.0,
            "avg_client_satisfaction": 0.0,
            "avg_case_success": 0.0,
            "last_optimization": None,
            "optimization_iterations": 0
        }
        
        # Configurações de otimização
        self.optimization_config = {
            "min_feedback_threshold": 50,  # Mínimo de feedback para retreinar
            "optimization_frequency_hours": 24,  # Otimizar a cada 24h
            "learning_rate_decay": 0.95,  # Decay da learning rate
            "convergence_threshold": 0.001,  # Threshold para convergência
            "max_iterations": 100  # Máximo de iterações por otimização
        }
    
    def _load_optimized_weights(self) -> CaseMatchWeights:
        """Carrega pesos otimizados do arquivo JSON."""
        weights_file = Path("packages/backend/models/case_match_weights.json")
        
        if weights_file.exists():
            try:
                with open(weights_file, 'r') as f:
                    data = json.load(f)
                    weights = CaseMatchWeights.from_dict(data)
                    if weights.validate():
                        self.logger.info("✅ Pesos otimizados carregados do arquivo")
                        return weights
                    else:
                        self.logger.warning("❌ Pesos inválidos no arquivo - usando padrão")
            except Exception as e:
                self.logger.warning(f"Erro ao carregar pesos otimizados: {e}")
        
        # Pesos padrão se arquivo não existir ou inválido
        return CaseMatchWeights()
    
    def _load_preset_weights(self) -> Dict[str, CaseMatchWeights]:
        """Carrega pesos otimizados para cada preset."""
        preset_file = Path("packages/backend/models/case_match_presets.json")
        
        presets = {}
        if preset_file.exists():
            try:
                with open(preset_file, 'r') as f:
                    data = json.load(f)
                    for preset_name, preset_data in data.items():
                        weights = CaseMatchWeights.from_dict(preset_data)
                        if weights.validate():
                            presets[preset_name] = weights
                
                if presets:
                    self.logger.info(f"✅ {len(presets)} presets otimizados carregados")
                    return presets
            except Exception as e:
                self.logger.warning(f"Erro ao carregar presets: {e}")
        
        # Presets padrão baseados no algoritmo_match.py atual
        return self._get_default_presets()
    
    def _get_default_presets(self) -> Dict[str, CaseMatchWeights]:
        """Retorna presets padrão baseados no algoritmo atual."""
        return {
            "fast": CaseMatchWeights(
                A=0.39, S=0.15, T=0.19, G=0.15, Q=0.07, U=0.03, R=0.01,
                C=0.00, P=0.00, E=0.00, M=0.00, I=0.01
            ),
            "expert": CaseMatchWeights(
                A=0.19, S=0.25, T=0.14, G=0.05, Q=0.15, U=0.05, R=0.03,
                C=0.02, P=0.01, E=0.00, M=0.09, I=0.02
            ),
            "balanced": CaseMatchWeights(),  # Usar padrão
            "economic": CaseMatchWeights(
                A=0.17, S=0.12, T=0.06, G=0.17, Q=0.04, U=0.17, R=0.05,
                C=0.05, P=0.12, E=0.00, M=0.04, I=0.01
            )
        }
    
    async def save_optimized_weights(self, weights: CaseMatchWeights):
        """Salva pesos otimizados no arquivo JSON."""
        weights_file = Path("packages/backend/models/case_match_weights.json")
        weights_file.parent.mkdir(parents=True, exist_ok=True)
        
        try:
            # Validar antes de salvar
            if not weights.validate():
                weights = weights.normalize()  # Normalizar se inválido
            
            with open(weights_file, 'w') as f:
                json.dump(weights.to_dict(), f, indent=2)
            
            self.logger.info("✅ Pesos otimizados salvos no arquivo")
            
            # Atualizar cache no Redis para outros workers
            await self.redis.set(
                "case_match:optimized_weights", 
                json.dumps(weights.to_dict()),
                ex=86400  # 24h TTL
            )
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao salvar pesos otimizados: {e}")
    
    async def record_feedback(self, feedback: CaseFeedback):
        """Registra feedback de outcome de caso para treinamento."""
        try:
            # Validar feedback
            if not self._validate_feedback(feedback):
                self.logger.warning(f"Feedback inválido para caso {feedback.case_id}")
                return
            
            # Salvar no banco de dados
            query = text("""
                INSERT INTO case_feedback (
                    case_id, lawyer_id, client_id, hired, client_satisfaction,
                    case_success, case_outcome_value, response_time_hours,
                    negotiation_rounds, case_duration_days, case_area,
                    case_complexity, case_urgency_hours, case_value_range,
                    lawyer_rank_position, total_candidates, match_score,
                    features_used, preset_used, feedback_source,
                    feedback_notes, timestamp
                ) VALUES (
                    :case_id, :lawyer_id, :client_id, :hired, :client_satisfaction,
                    :case_success, :case_outcome_value, :response_time_hours,
                    :negotiation_rounds, :case_duration_days, :case_area,
                    :case_complexity, :case_urgency_hours, :case_value_range,
                    :lawyer_rank_position, :total_candidates, :match_score,
                    :features_used, :preset_used, :feedback_source,
                    :feedback_notes, :timestamp
                )
            """)
            
            await self.db.execute(query, {
                **feedback.__dict__,
                "features_used": json.dumps(feedback.features_used)
            })
            await self.db.commit()
            
            # Atualizar métricas
            await self._update_performance_metrics(feedback)
            
            # Verificar se deve retreinar
            if await self._should_retrain():
                self.logger.info("🔄 Trigger de retreinamento ativado")
                await self._trigger_optimization()
            
            self.logger.info(f"✅ Feedback registrado para caso {feedback.case_id}")
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao registrar feedback: {e}")
            await self.db.rollback()
    
    def _validate_feedback(self, feedback: CaseFeedback) -> bool:
        """Valida se o feedback está consistente."""
        if not feedback.case_id or not feedback.lawyer_id:
            return False
        
        if not (0.0 <= feedback.client_satisfaction <= 5.0):
            return False
        
        if not (0.0 <= feedback.match_score <= 1.0):
            return False
        
        return True
    
    async def _update_performance_metrics(self, feedback: CaseFeedback):
        """Atualiza métricas de performance em tempo real."""
        self.performance_metrics["total_cases"] += 1
        
        # Atualizar médias com novo feedback
        total = self.performance_metrics["total_cases"]
        
        if feedback.hired:
            self.performance_metrics["hired_rate"] = self._update_average(
                self.performance_metrics["hired_rate"], 1.0, total
            )
        
        self.performance_metrics["avg_client_satisfaction"] = self._update_average(
            self.performance_metrics["avg_client_satisfaction"],
            feedback.client_satisfaction, total
        )
        
        if feedback.case_success:
            self.performance_metrics["avg_case_success"] = self._update_average(
                self.performance_metrics["avg_case_success"], 1.0, total
            )
    
    def _update_average(self, current_avg: float, new_value: float, total_count: int) -> float:
        """Atualiza uma média com novo valor."""
        if total_count <= 1:
            return new_value
        return ((current_avg * (total_count - 1)) + new_value) / total_count
    
    async def _should_retrain(self) -> bool:
        """Verifica se deve executar retreinamento baseado em critérios."""
        # 1. Threshold mínimo de feedback
        if self.performance_metrics["total_cases"] < self.optimization_config["min_feedback_threshold"]:
            return False
        
        # 2. Frequência de otimização
        last_opt = self.performance_metrics.get("last_optimization")
        if last_opt:
            hours_since = (datetime.utcnow() - last_opt).total_seconds() / 3600
            if hours_since < self.optimization_config["optimization_frequency_hours"]:
                return False
        
        # 3. Performance degradation (trigger urgente)
        if self.performance_metrics["hired_rate"] < 0.1:  # Menos de 10% hire rate
            self.logger.warning("🚨 Performance crítica detectada - forçando retreinamento")
            return True
        
        return True
    
    async def _trigger_optimization(self):
        """Executa otimização dos pesos baseada em feedback."""
        try:
            self.logger.info("🔄 Iniciando otimização de pesos...")
            
            # Carregar feedback recente
            feedback_data = await self._load_recent_feedback()
            if len(feedback_data) < 10:
                self.logger.warning("Feedback insuficiente para otimização")
                return
            
            # Otimizar pesos usando gradient descent
            optimized_weights = await self._optimize_weights_gradient_descent(feedback_data)
            
            if optimized_weights and optimized_weights.validate():
                # Testar se os novos pesos são melhores
                improvement = await self._validate_optimization(optimized_weights, feedback_data)
                
                if improvement > 0.02:  # Melhoria de pelo menos 2%
                    self.weights = optimized_weights
                    await self.save_optimized_weights(optimized_weights)
                    
                    self.performance_metrics["last_optimization"] = datetime.utcnow()
                    self.performance_metrics["optimization_iterations"] += 1
                    
                    self.logger.info(f"✅ Otimização concluída - melhoria: {improvement:.2%}")
                else:
                    self.logger.info("⚡ Otimização sem melhoria significativa")
            else:
                self.logger.warning("❌ Otimização resultou em pesos inválidos")
                
        except Exception as e:
            self.logger.error(f"❌ Erro na otimização: {e}")
    
    async def _load_recent_feedback(self) -> List[CaseFeedback]:
        """Carrega feedback recente para otimização."""
        query = text("""
            SELECT * FROM case_feedback 
            WHERE timestamp >= NOW() - INTERVAL '30 days'
            ORDER BY timestamp DESC
            LIMIT 1000
        """)
        
        result = await self.db.execute(query)
        rows = result.fetchall()
        
        feedback_list = []
        for row in rows:
            feedback = CaseFeedback(
                case_id=row.case_id,
                lawyer_id=row.lawyer_id,
                client_id=row.client_id,
                hired=row.hired,
                client_satisfaction=row.client_satisfaction,
                case_success=row.case_success,
                case_outcome_value=row.case_outcome_value,
                response_time_hours=row.response_time_hours,
                negotiation_rounds=row.negotiation_rounds,
                case_duration_days=row.case_duration_days,
                case_area=row.case_area,
                case_complexity=row.case_complexity,
                case_urgency_hours=row.case_urgency_hours,
                case_value_range=row.case_value_range,
                lawyer_rank_position=row.lawyer_rank_position,
                total_candidates=row.total_candidates,
                match_score=row.match_score,
                features_used=json.loads(row.features_used or "{}"),
                preset_used=row.preset_used,
                feedback_source=row.feedback_source,
                feedback_notes=row.feedback_notes,
                timestamp=row.timestamp
            )
            feedback_list.append(feedback)
        
        return feedback_list
    
    async def _optimize_weights_gradient_descent(self, feedback_data: List[CaseFeedback]) -> Optional[CaseMatchWeights]:
        """Otimiza pesos usando gradient descent baseado em feedback real."""
        try:
            # Converter feedback para matriz de features e targets
            features_matrix = []
            targets = []
            
            for feedback in feedback_data:
                if feedback.features_used:
                    # Normalizar features
                    feature_vector = [
                        feedback.features_used.get("A", 0.0),
                        feedback.features_used.get("S", 0.0),
                        feedback.features_used.get("T", 0.0),
                        feedback.features_used.get("G", 0.0),
                        feedback.features_used.get("Q", 0.0),
                        feedback.features_used.get("U", 0.0),
                        feedback.features_used.get("R", 0.0),
                        feedback.features_used.get("C", 0.0),
                        feedback.features_used.get("E", 0.0),
                        feedback.features_used.get("P", 0.0),
                        feedback.features_used.get("M", 0.0),
                        feedback.features_used.get("I", 0.0),
                    ]
                    
                    # Calcular target baseado em outcomes
                    target = self._calculate_feedback_target(feedback)
                    
                    features_matrix.append(feature_vector)
                    targets.append(target)
            
            if len(features_matrix) < 10:
                return None
            
            # Converter para numpy para cálculos
            X = np.array(features_matrix)
            y = np.array(targets)
            
            # Pesos iniciais
            w = np.array([
                self.weights.A, self.weights.S, self.weights.T, self.weights.G,
                self.weights.Q, self.weights.U, self.weights.R, self.weights.C,
                self.weights.E, self.weights.P, self.weights.M, self.weights.I
            ])
            
            # Gradient descent
            learning_rate = self.weights.learning_rate
            
            for iteration in range(self.optimization_config["max_iterations"]):
                # Forward pass
                predictions = np.dot(X, w)
                
                # Calcular loss (MSE)
                loss = np.mean((predictions - y) ** 2)
                
                # Backward pass - calcular gradients
                gradients = 2 * np.dot(X.T, (predictions - y)) / len(y)
                
                # Atualizar pesos
                w_new = w - learning_rate * gradients
                
                # Projetar para simplex (pesos devem somar 1.0 e ser não-negativos)
                w_new = np.maximum(w_new, 0.0)  # Não-negativos
                w_new = w_new / np.sum(w_new)   # Normalizar para soma = 1.0
                
                # Verificar convergência
                if np.linalg.norm(w_new - w) < self.optimization_config["convergence_threshold"]:
                    self.logger.info(f"Convergência atingida em {iteration} iterações")
                    break
                
                w = w_new
                learning_rate *= self.optimization_config["learning_rate_decay"]
            
            # Criar novos pesos otimizados
            optimized_weights = CaseMatchWeights(
                A=float(w[0]), S=float(w[1]), T=float(w[2]), G=float(w[3]),
                Q=float(w[4]), U=float(w[5]), R=float(w[6]), C=float(w[7]),
                E=float(w[8]), P=float(w[9]), M=float(w[10]), I=float(w[11]),
                learning_rate=learning_rate
            )
            
            return optimized_weights
            
        except Exception as e:
            self.logger.error(f"Erro no gradient descent: {e}")
            return None
    
    def _calculate_feedback_target(self, feedback: CaseFeedback) -> float:
        """Calcula target value baseado em outcomes do feedback."""
        # Combinar múltiplos sinais de sucesso em um target 0-1
        components = []
        
        # 1. Foi contratado? (peso alto)
        if feedback.hired:
            components.append(0.4)
        
        # 2. Satisfação do cliente (normalizada)
        client_sat_normalized = feedback.client_satisfaction / 5.0
        components.append(client_sat_normalized * 0.3)
        
        # 3. Sucesso do caso
        if feedback.case_success:
            components.append(0.2)
        
        # 4. Posição no ranking (inverso - primeira posição é melhor)
        rank_score = max(0, 1.0 - (feedback.lawyer_rank_position - 1) / feedback.total_candidates)
        components.append(rank_score * 0.1)
        
        return sum(components)
    
    async def _validate_optimization(self, new_weights: CaseMatchWeights, feedback_data: List[CaseFeedback]) -> float:
        """Valida se os novos pesos são melhores que os atuais."""
        try:
            # Simular performance com pesos atuais vs novos
            current_score = self._simulate_performance(self.weights, feedback_data)
            new_score = self._simulate_performance(new_weights, feedback_data)
            
            improvement = new_score - current_score
            return improvement
            
        except Exception as e:
            self.logger.error(f"Erro na validação: {e}")
            return 0.0
    
    def _simulate_performance(self, weights: CaseMatchWeights, feedback_data: List[CaseFeedback]) -> float:
        """Simula performance de um conjunto de pesos no feedback histórico."""
        total_score = 0.0
        count = 0
        
        for feedback in feedback_data:
            if not feedback.features_used:
                continue
            
            # Calcular score que o algoritmo daria com estes pesos
            predicted_score = (
                feedback.features_used.get("A", 0.0) * weights.A +
                feedback.features_used.get("S", 0.0) * weights.S +
                feedback.features_used.get("T", 0.0) * weights.T +
                feedback.features_used.get("G", 0.0) * weights.G +
                feedback.features_used.get("Q", 0.0) * weights.Q +
                feedback.features_used.get("U", 0.0) * weights.U +
                feedback.features_used.get("R", 0.0) * weights.R +
                feedback.features_used.get("C", 0.0) * weights.C +
                feedback.features_used.get("E", 0.0) * weights.E +
                feedback.features_used.get("P", 0.0) * weights.P +
                feedback.features_used.get("M", 0.0) * weights.M +
                feedback.features_used.get("I", 0.0) * weights.I
            )
            
            # Target real baseado em outcomes
            actual_target = self._calculate_feedback_target(feedback)
            
            # Erro quadrático
            error = (predicted_score - actual_target) ** 2
            total_score += (1.0 - error)  # Inverter para que maior seja melhor
            count += 1
        
        return total_score / count if count > 0 else 0.0
    
    def get_optimized_weights(self, preset: str = "balanced") -> Dict[str, float]:
        """
        🎯 MÉTODO PRINCIPAL: Retorna pesos otimizados para uso no algoritmo_match.py
        
        Args:
            preset: Nome do preset (balanced, fast, expert, economic, etc.)
            
        Returns:
            Dict com pesos otimizados no formato esperado pelo algoritmo
        """
        try:
            # Usar preset específico se disponível
            if preset in self.preset_weights:
                weights = self.preset_weights[preset]
            else:
                weights = self.weights  # Fallback para pesos globais
            
            # Retornar no formato esperado pelo algoritmo_match.py
            optimized_dict = weights.to_dict()
            
            self.logger.debug(f"Retornando pesos otimizados para preset '{preset}'")
            return optimized_dict
            
        except Exception as e:
            self.logger.error(f"Erro ao obter pesos otimizados: {e}")
            # Fallback para pesos hardcoded do algoritmo
            return {
                "A": 0.23, "S": 0.18, "T": 0.11, "G": 0.07,
                "Q": 0.07, "U": 0.05, "R": 0.05, "C": 0.03,
                "E": 0.02, "P": 0.02, "M": 0.15, "I": 0.02
            }
    
    async def get_performance_report(self) -> Dict[str, Any]:
        """Retorna relatório de performance do ML service."""
        return {
            "metrics": self.performance_metrics.copy(),
            "optimization_config": self.optimization_config.copy(),
            "current_weights": self.weights.to_dict(),
            "available_presets": list(self.preset_weights.keys()),
            "service_status": "active",
            "last_feedback_count": await self._get_recent_feedback_count(),
        }
    
    async def _get_recent_feedback_count(self) -> int:
        """Conta feedback recente para relatórios."""
        try:
            query = text("""
                SELECT COUNT(*) as count
                FROM case_feedback 
                WHERE timestamp >= NOW() - INTERVAL '7 days'
            """)
            result = await self.db.execute(query)
            row = result.fetchone()
            return row.count if row else 0
        except Exception:
            return 0


# 🎯 Factory function para integração fácil com algoritmo_match.py
async def create_case_match_ml_service(db: AsyncSession) -> Optional[CaseMatchMLService]:
    """
    Factory function para criar CaseMatchMLService com error handling.
    
    Returns:
        CaseMatchMLService instance ou None se não conseguir inicializar
    """
    try:
        service = CaseMatchMLService(db)
        logger.info("✅ CaseMatchMLService inicializado com sucesso")
        return service
    except Exception as e:
        logger.error(f"❌ Erro ao inicializar CaseMatchMLService: {e}")
        return None 