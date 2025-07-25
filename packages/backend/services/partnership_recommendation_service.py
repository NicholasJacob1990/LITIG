#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Partnership Recommendation Service
==================================

Serviço avançado de recomendação de parcerias entre advogados baseado em
complementaridade de clusters e métricas de qualidade.

Algoritmo de Scoring:
- **Complementarity Score (60%)**  – Proporção de clusters fortes do candidato que
  o advogado-alvo NÃO possui.
- **Cluster Momentum Score (20%)** – Momentum médio dos clusters complementares.
- **Reputation Score (10%)**        – Placeholder usando rating médio (quando
  disponível) ou 0.5.
- **Diversity Bonus (10%)**         – Bônus pela variedade de clusters
  complementares.

Retorna recomendações ordenadas pelo `final_score` com explicação textual.
"""

from __future__ import annotations

import logging
import math
from dataclasses import dataclass
from datetime import datetime
from typing import List, Dict, Any, Optional

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text

logger = logging.getLogger(__name__)

# Import ML service
try:
    from services.partnership_ml_service import PartnershipMLService, PartnershipWeights
    ML_SERVICE_AVAILABLE = True
except ImportError:
    ML_SERVICE_AVAILABLE = False
    logger.warning("PartnershipMLService não disponível - usando pesos fixos")


@dataclass
class PartnershipRecommendation:
    lawyer_id: str
    lawyer_name: str
    firm_name: Optional[str]
    compatibility_clusters: List[str]
    complementarity_score: float
    diversity_score: float
    momentum_score: float
    reputation_score: float
    firm_synergy_score: float  # NOVO: Sinergia entre escritórios
    final_score: float
    recommendation_reason: str
    firm_synergy_reason: Optional[str] = None  # NOVO: Explicação da sinergia


class PartnershipRecommendationService:
    """Serviço para geração de recomendações de parceria."""

    def __init__(self, db: AsyncSession):
        self.db = db
        self.logger = logging.getLogger(__name__)
        
        # Inicializar ML service se disponível
        self.ml_service = None
        if ML_SERVICE_AVAILABLE:
            try:
                self.ml_service = PartnershipMLService(db)
                self.logger.info("ML service inicializado - usando pesos otimizados")
            except Exception as e:
                self.logger.warning(f"Erro ao inicializar ML service: {e}")
        
        # Pesos padrão (fallback se ML não disponível)
        self.default_weights = PartnershipWeights() if ML_SERVICE_AVAILABLE else None

    async def get_recommendations(
        self,
        lawyer_id: str,
        limit: int = 10,
        min_confidence: float = 0.6,
        exclude_same_firm: bool = True,
    ) -> List[PartnershipRecommendation]:
        """Gera recomendações ordenadas para o advogado informado."""
        
        # Validações de entrada
        if not lawyer_id or not lawyer_id.strip():
            self.logger.warning("ID do advogado é obrigatório")
            return []
            
        if limit <= 0:
            limit = 10
            
        if not (0.0 <= min_confidence <= 1.0):
            min_confidence = 0.6
            self.logger.warning(f"min_confidence ajustado para {min_confidence}")

        try:
            # 1. Clusters do advogado alvo
            target_clusters = await self._get_lawyer_clusters(lawyer_id, min_confidence)
            if not target_clusters:
                self.logger.info(f"Advogado {lawyer_id} sem clusters fortes (min_conf={min_confidence}) – retornando lista vazia")
                return []

            target_cluster_ids = set(target_clusters.keys())
            self.logger.info(f"Advogado {lawyer_id} possui {len(target_cluster_ids)} clusters fortes")

            # 2. Carregar clusters fortes dos demais advogados
            candidate_rows = await self._fetch_candidate_clusters(
                lawyer_id, min_confidence, exclude_same_firm
            )
            
            if not candidate_rows:
                self.logger.info("Nenhum candidato encontrado com clusters complementares")
                return []

            # 3. Organizar por candidato e filtrar qualidade mínima
            candidates: Dict[str, Dict[str, Any]] = {}
            for row in candidate_rows:
                # Filtrar clusters pequenos (menos de 3 membros)
                if (row.total_items or 0) < 3:
                    continue
                    
                cid = row.lawyer_id
                if cid not in candidates:
                    candidates[cid] = {
                        "lawyer_name": row.name,
                        "firm_name": row.firm_name,
                        "clusters": [],
                        "avg_rating": getattr(row, 'avg_rating', None),  # Rating real se disponível
                    }
                candidates[cid]["clusters"].append(
                    {
                        "cluster_id": row.cluster_id,
                        "cluster_label": row.cluster_label,
                        "confidence": float(row.confidence_score),
                        "momentum": float(row.momentum_score or 0.0),
                        "cluster_size": int(row.total_items or 0),
                    }
                )

            if not candidates:
                self.logger.info("Nenhum candidato válido após filtros de qualidade")
                return []

            # 4. Calcular scores com algoritmo aprimorado
            recommendations: List[PartnershipRecommendation] = []
            for cid, info in candidates.items():
                complement_clusters = [c for c in info["clusters"] if c["cluster_id"] not in target_cluster_ids]
                if not complement_clusters:
                    continue  # Sem complementaridade

                # Complementarity score – média ponderada por confiança e tamanho do cluster
                total_weight = sum(c["confidence"] * min(c["cluster_size"] / 10.0, 1.0) for c in complement_clusters)
                total_confidence = sum(c["confidence"] for c in complement_clusters)
                
                if total_confidence == 0:
                    continue
                    
                complementarity = total_weight / len(complement_clusters)

                # Diversity score melhorado – fórmula logarítmica
                diversity = min(1.0, math.log(1 + len(complement_clusters)) / math.log(6))  # log₆(1+n)

                # Momentum score – média ponderada por confiança
                weighted_momentum = sum(c["momentum"] * c["confidence"] for c in complement_clusters)
                momentum = weighted_momentum / total_confidence if total_confidence > 0 else 0.0

                # Reputation score melhorado
                if info["avg_rating"] and info["avg_rating"] > 0:
                    reputation = min(1.0, info["avg_rating"] / 5.0)  # Normalizar rating de 0-5 para 0-1
                else:
                    reputation = 0.5  # Fallback neutro

                # NOVO: Firm Synergy Score
                firm_synergy, synergy_reason = await self._calculate_firm_synergy(
                    lawyer_id, cid, complement_clusters
                )

                # Obter pesos otimizados do ML service ou usar padrão
                weights = self._get_optimized_weights()
                
                # Score final usando pesos otimizados
                final_score = (
                    complementarity * weights.complementarity_weight +
                    momentum * weights.momentum_weight +
                    reputation * weights.reputation_weight +
                    diversity * weights.diversity_weight +
                    firm_synergy * weights.firm_synergy_weight
                )
                
                # Aplicar penalidade se muito poucos clusters complementares
                if len(complement_clusters) == 1:
                    final_score *= 0.8  # 20% de penalidade

                # Motivo textual melhorado
                top_clusters = sorted(complement_clusters, key=lambda x: x["confidence"], reverse=True)[:2]
                cluster_names = [c["cluster_label"] for c in top_clusters]
                
                if len(cluster_names) == 1:
                    reason = (
                        f"Especialista em '{cluster_names[0]}' (confiança {top_clusters[0]['confidence']:.0%}) "
                        f"complementando seu portfólio. Momentum do nicho: {momentum:.0%}."
                    )
                else:
                    reason = (
                        f"Forte atuação em '{cluster_names[0]}' e '{cluster_names[1]}' "
                        f"(confiança média {complementarity:.0%}) que complementam suas expertises. "
                        f"Momentum médio: {momentum:.0%}."
                    )

                recommendations.append(
                    PartnershipRecommendation(
                        lawyer_id=cid,
                        lawyer_name=info["lawyer_name"],
                        firm_name=info["firm_name"],
                        compatibility_clusters=[c["cluster_label"] for c in complement_clusters],
                        complementarity_score=complementarity,
                        diversity_score=diversity,
                        momentum_score=momentum,
                        reputation_score=reputation,
                        firm_synergy_score=firm_synergy, # NOVO: Incluir sinergia
                        final_score=final_score,
                        recommendation_reason=reason,
                        firm_synergy_reason=synergy_reason, # NOVO: Incluir razão da sinergia
                    )
                )

            # 5. Ordenar e limitar com diversificação
            recommendations.sort(key=lambda r: r.final_score, reverse=True)
            
            # Aplicar diversificação de escritórios (evitar muitas recomendações do mesmo escritório)
            diversified_recs = self._diversify_by_firm(recommendations, limit)
            
            self.logger.info(f"✅ {len(diversified_recs)} recomendações geradas para advogado {lawyer_id}")
            return diversified_recs[:limit]
            
        except Exception as e:
            self.logger.error(f"❌ Erro inesperado ao gerar recomendações para {lawyer_id}: {e}")
            return []

    def _diversify_by_firm(self, recommendations: List[PartnershipRecommendation], limit: int) -> List[PartnershipRecommendation]:
        """Aplica diversificação por escritório para evitar concentração."""
        if not recommendations:
            return []
            
        diversified = []
        firm_count = {}
        
        for rec in recommendations:
            firm_key = rec.firm_name or "sem_escritorio"
            current_count = firm_count.get(firm_key, 0)
            
            # Permitir até 2 advogados do mesmo escritório nas primeiras 10 recomendações
            max_per_firm = 2 if len(diversified) < 10 else 1
            
            if current_count < max_per_firm:
                diversified.append(rec)
                firm_count[firm_key] = current_count + 1
                
            if len(diversified) >= limit:
                break
                
        return diversified

    async def _get_lawyer_clusters(self, lawyer_id: str, min_conf: float) -> Dict[str, float]:
        """Retorna clusters fortes do advogado alvo."""
        query = text(
            """
            SELECT cluster_id, confidence_score
            FROM lawyer_clusters
            WHERE lawyer_id = :lawyer_id AND confidence_score >= :min_conf
            """
        )
        result = await self.db.execute(query, {"lawyer_id": lawyer_id, "min_conf": min_conf})
        return {row.cluster_id: float(row.confidence_score) for row in result.fetchall()}

    async def _fetch_candidate_clusters(
        self,
        lawyer_id: str,
        min_conf: float,
        exclude_same_firm: bool,
    ):
        """Busca clusters fortes dos candidatos."""
        exclude_firm_sql = ""
        if exclude_same_firm:
            exclude_firm_sql = (
                "AND (l.law_firm_id IS NULL OR l.law_firm_id != t.law_firm_id)"
            )

        query = text(
            f"""
            SELECT 
                lc.lawyer_id,
                l.name,
                lf.name AS firm_name,
                lc.cluster_id,
                cm.cluster_label,
                lc.confidence_score,
                cm.momentum_score,
                cm.total_items,
                l.avg_rating
            FROM lawyer_clusters lc
            JOIN lawyers l ON lc.lawyer_id = l.id
            LEFT JOIN law_firms lf ON l.law_firm_id = lf.id
            JOIN cluster_metadata cm ON lc.cluster_id = cm.cluster_id
            JOIN lawyers t ON t.id = :lawyer_id
            WHERE lc.lawyer_id != :lawyer_id
                AND lc.confidence_score >= :min_conf
                AND cm.total_items >= 3
                {exclude_firm_sql}
            ORDER BY lc.confidence_score DESC, cm.momentum_score DESC
            """
        )
        result = await self.db.execute(
            query, {"lawyer_id": lawyer_id, "min_conf": min_conf}
        )
        return result.fetchall() 

    async def _calculate_firm_synergy(
        self, 
        target_lawyer_id: str, 
        candidate_lawyer_id: str, 
        candidate_complement_clusters: List[Dict]
    ) -> tuple[float, Optional[str]]:
        """
        Calcula sinergia entre escritórios baseada em:
        1. Portfolio Gap Analysis - lacunas no portfólio do escritório alvo
        2. Strategic Complementarity - força combinada dos clusters
        3. Market Positioning - posicionamento estratégico conjunto
        """
        
        try:
            # 1. Obter portfólio completo do escritório alvo
            target_firm_portfolio = await self._get_firm_cluster_portfolio(target_lawyer_id)
            if not target_firm_portfolio:
                return 0.0, None  # Sem dados suficientes
            
            # 2. Obter portfólio do escritório candidato
            candidate_firm_portfolio = await self._get_firm_cluster_portfolio(candidate_lawyer_id)
            if not candidate_firm_portfolio:
                return 0.0, None
            
            # 3. Análise de gaps no portfólio
            portfolio_gap_score = self._analyze_portfolio_gaps(
                target_firm_portfolio, 
                candidate_complement_clusters
            )
            
            # 4. Strategic complementarity score
            strategic_score = self._calculate_strategic_complementarity(
                target_firm_portfolio,
                candidate_firm_portfolio
            )
            
            # 5. Market positioning score
            market_positioning_score = self._calculate_market_positioning_synergy(
                target_firm_portfolio,
                candidate_firm_portfolio
            )
            
            # Score final da sinergia (média ponderada)
            firm_synergy_score = (
                portfolio_gap_score * 0.5 +      # 50% - gaps críticos
                strategic_score * 0.3 +          # 30% - complementaridade estratégica  
                market_positioning_score * 0.2   # 20% - posicionamento de mercado
            )
            
            # Gerar explicação da sinergia
            synergy_reason = self._generate_synergy_explanation(
                portfolio_gap_score,
                strategic_score, 
                market_positioning_score,
                target_firm_portfolio,
                candidate_firm_portfolio
            )
            
            return firm_synergy_score, synergy_reason
            
        except Exception as e:
            self.logger.error(f"Erro ao calcular sinergia entre escritórios: {e}")
            return 0.0, None

    async def _get_firm_cluster_portfolio(self, lawyer_id: str) -> Optional[Dict[str, Any]]:
        """Obtém portfolio completo de clusters do escritório do advogado."""
        
        query = text("""
            WITH firm_clusters AS (
                SELECT DISTINCT
                    cm.cluster_id,
                    cm.cluster_label,
                    cm.cluster_type,
                    cm.total_items,
                    cm.momentum_score,
                    AVG(lc.confidence_score) as avg_confidence,
                    COUNT(DISTINCT lc.lawyer_id) as firm_lawyers_count
                FROM lawyers l1
                JOIN lawyers l2 ON l1.law_firm_id = l2.law_firm_id
                JOIN lawyer_clusters lc ON l2.id = lc.lawyer_id
                JOIN cluster_metadata cm ON lc.cluster_id = cm.cluster_id
                WHERE l1.id = :lawyer_id 
                    AND l1.law_firm_id IS NOT NULL
                    AND lc.confidence_score >= 0.4
                GROUP BY cm.cluster_id, cm.cluster_label, cm.cluster_type, cm.total_items, cm.momentum_score
            )
            SELECT 
                cluster_id,
                cluster_label,
                cluster_type,
                total_items,
                momentum_score,
                avg_confidence,
                firm_lawyers_count,
                -- Força do cluster no escritório
                CASE 
                    WHEN firm_lawyers_count >= 3 THEN 'strong'
                    WHEN firm_lawyers_count = 2 THEN 'medium' 
                    ELSE 'weak'
                END as cluster_strength
            FROM firm_clusters
            ORDER BY avg_confidence DESC, momentum_score DESC
        """)
        
        result = await self.db.execute(query, {"lawyer_id": lawyer_id})
        rows = result.fetchall()
        
        if not rows:
            return None
            
        portfolio = {
            "clusters": [dict(row._mapping) for row in rows],
            "strong_areas": [row.cluster_label for row in rows if row.cluster_strength == 'strong'],
            "coverage_score": len([r for r in rows if r.cluster_strength in ['strong', 'medium']]) / max(len(rows), 1),
            "momentum_avg": sum(float(row.momentum_score or 0) for row in rows) / len(rows)
        }
        
        return portfolio

    def _analyze_portfolio_gaps(
        self, 
        target_portfolio: Dict[str, Any], 
        candidate_clusters: List[Dict]
    ) -> float:
        """Analisa gaps críticos no portfólio que o candidato pode preencher."""
        
        target_strong_areas = set(target_portfolio["strong_areas"])
        target_all_areas = set(c["cluster_label"] for c in target_portfolio["clusters"])
        
        # Clusters que o candidato oferece que são gaps no target
        gap_filling_clusters = [
            c for c in candidate_clusters 
            if c["cluster_label"] not in target_all_areas and c["confidence"] > 0.6
        ]
        
        # High-value gaps (nichos com momentum alto)
        high_value_gaps = [
            c for c in gap_filling_clusters 
            if c["momentum"] > 0.6
        ]
        
        if not gap_filling_clusters:
            return 0.0
            
        # Score baseado na qualidade e valor dos gaps preenchidos
        gap_score = (
            len(gap_filling_clusters) * 0.3 +           # Quantidade de gaps
            len(high_value_gaps) * 0.7                  # Valor estratégico dos gaps
        ) / 5.0  # Normalizar para máximo de 5 gaps de alto valor
        
        return min(1.0, gap_score)

    def _calculate_strategic_complementarity(
        self, 
        target_portfolio: Dict[str, Any], 
        candidate_portfolio: Dict[str, Any]
    ) -> float:
        """Calcula complementaridade estratégica entre portfólios."""
        
        target_strong = set(target_portfolio["strong_areas"])
        candidate_strong = set(candidate_portfolio["strong_areas"])
        
        # Overlap mínimo (sobreposição baixa é melhor)
        overlap = len(target_strong.intersection(candidate_strong))
        total_strong = len(target_strong.union(candidate_strong))
        
        if total_strong == 0:
            return 0.0
            
        # Complementarity score (baixo overlap = alta complementaridade)
        overlap_penalty = overlap / total_strong
        complementarity = max(0.0, 1.0 - overlap_penalty)
        
        # Bonus por cobertura estratégica ampla
        coverage_bonus = min(0.3, total_strong / 10.0)  # Até 10 áreas = bonus máximo
        
        return min(1.0, complementarity + coverage_bonus)

    def _calculate_market_positioning_synergy(
        self, 
        target_portfolio: Dict[str, Any], 
        candidate_portfolio: Dict[str, Any]
    ) -> float:
        """Calcula sinergia de posicionamento de mercado."""
        
        # Momentum combinado (escritórios em nichos de crescimento)
        combined_momentum = (
            target_portfolio["momentum_avg"] + 
            candidate_portfolio["momentum_avg"]
        ) / 2.0
        
        # Coverage score combinado
        combined_coverage = (
            target_portfolio["coverage_score"] + 
            candidate_portfolio["coverage_score"]
        ) / 2.0
        
        # Market positioning score
        positioning_score = (combined_momentum * 0.6 + combined_coverage * 0.4)
        
        return min(1.0, positioning_score)

    def _generate_synergy_explanation(
        self,
        gap_score: float,
        strategic_score: float, 
        positioning_score: float,
        target_portfolio: Dict[str, Any],
        candidate_portfolio: Dict[str, Any]
    ) -> str:
        """Gera explicação textual da sinergia entre escritórios."""
        
        explanations = []
        
        # Portfolio gaps
        if gap_score > 0.6:
            explanations.append("preenche gaps críticos no portfólio")
        elif gap_score > 0.3:
            explanations.append("complementa áreas de atuação")
            
        # Strategic complementarity  
        if strategic_score > 0.7:
            explanations.append("alta complementaridade estratégica")
        elif strategic_score > 0.4:
            explanations.append("boa sinergia de expertise")
            
        # Market positioning
        if positioning_score > 0.6:
            explanations.append("forte posicionamento de mercado conjunto")
            
        if not explanations:
            return "sinergia básica entre escritórios"
            
        if len(explanations) == 1:
            return f"Escritório {explanations[0]}."
        else:
            return f"Escritório {', '.join(explanations[:-1])} e {explanations[-1]}."

    def _get_optimized_weights(self) -> PartnershipWeights:
        """Retorna pesos otimizados do ML service ou pesos padrão."""
        if self.ml_service and self.ml_service.weights:
            return self.ml_service.weights
        elif self.default_weights:
            return self.default_weights
        else:
            # Fallback para pesos fixos se ML não disponível
            return PartnershipWeights(
                complementarity_weight=0.5,
                momentum_weight=0.2,
                reputation_weight=0.1,
                diversity_weight=0.1,
                firm_synergy_weight=0.1
            ) 