#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Partnership Recommendation Service
==================================

Serviço avançado de recomendação de parcerias entre advogados baseado em
complementaridade de clusters e métricas de qualidade.

🆕 FASE 1 - UNIFICAÇÃO: Integrado com FeatureCalculator do algoritmo_match.py
=========================================================================
- Reutiliza features Q (qualification_score), M (maturity_score), I (interaction_score/IEP), 
  C (soft_skill), E (firm_reputation) para garantir consistência
- Usa as mesmas dataclasses (Lawyer, Case, KPI, etc.) para unificação de dados
- Aproveita cache Redis de features já calculadas

Algoritmo de Scoring:
- **Complementarity Score (60%)**  – Proporção de clusters fortes do candidato que
  o advogado-alvo NÃO possui.
- **Cluster Momentum Score (20%)** – Momentum médio dos clusters complementares.
- **🆕 Quality Score (15%)**       – Score unificado usando FeatureCalculator (Q+M+I+C+E)
- **Diversity Bonus (5%)**         – Reduzido para acomodar Quality Score

Retorna recomendações ordenadas pelo `final_score` com explicação textual.
"""

from __future__ import annotations

import logging
import math
from dataclasses import dataclass
from datetime import datetime
from typing import List, Dict, Any, Optional, Tuple
import numpy as np

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text

# Definir logger primeiro antes dos imports que o utilizam
logger = logging.getLogger(__name__)

# 🆕 FASE 1: Imports do Algoritmo de Casos para Unificação
try:
    from ..Algoritmo.algoritmo_match import (
        FeatureCalculator, 
        Lawyer, 
        Case, 
        KPI, 
        FirmKPI,
        ProfessionalMaturityData
    )
    FEATURE_CALCULATOR_AVAILABLE = True
except ImportError:
    FEATURE_CALCULATOR_AVAILABLE = False
    logger.warning("FeatureCalculator não disponível - usando scoring legado")

# Import ML service
try:
    from services.partnership_ml_service import PartnershipMLService, PartnershipWeights
    ML_SERVICE_AVAILABLE = True
except ImportError:
    ML_SERVICE_AVAILABLE = False
    logger.warning("PartnershipMLService não disponível - usando pesos fixos")

# 🆕 Import External Profile Enrichment Service
try:
    from .external_profile_enrichment_service import ExternalProfileEnrichmentService
    EXTERNAL_ENRICHMENT_AVAILABLE = True
except ImportError:
    EXTERNAL_ENRICHMENT_AVAILABLE = False
    logger.warning("ExternalProfileEnrichmentService não disponível - busca externa desabilitada")

# 🆕 FASE 2: Import Partnership Similarity Service
try:
    from .partnership_similarity_service import PartnershipSimilarityService
    SIMILARITY_SERVICE_AVAILABLE = True
except ImportError:
    SIMILARITY_SERVICE_AVAILABLE = False
    logger.warning("PartnershipSimilarityService não disponível - usando lógica de similaridade básica")

# 🆕 FASE 3: Import Unified Cache Service
try:
    from .unified_cache_service import UnifiedCacheService, unified_cache
    UNIFIED_CACHE_AVAILABLE = True
except ImportError:
    UNIFIED_CACHE_AVAILABLE = False
    logger.warning("UnifiedCacheService não disponível - sem otimização de cache")


@dataclass
class PartnershipRecommendation:
    # Campos obrigatórios (sem valor padrão)
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
    # Campos opcionais (com valor padrão)
    # 🆕 FASE 1: Score de Qualidade Unificado
    quality_score: float = 0.0  # Score baseado no FeatureCalculator (Q+M+I+C+E)
    quality_breakdown: Optional[Dict[str, float]] = None  # Detalhamento das features Q, M, I, C, E
    # 🆕 FASE 2: Score de Similaridade
    similarity_score: float = 0.0  # Score baseado no PartnershipSimilarityService
    similarity_breakdown: Optional[Dict[str, Any]] = None  # Detalhamento da análise de similaridade
    firm_synergy_reason: Optional[str] = None  # NOVO: Explicação da sinergia
    # 🆕 Campos para modelo híbrido
    status: str = "verified"  # "verified" ou "public_profile"
    invitation_id: Optional[str] = None  # Para perfis externos convidados
    profile_data: Optional[Dict[str, Any]] = None  # Dados do perfil externo


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

        # 🆕 LLM Enhancement Service
        self.llm_enhancer = None
        try:
            from .partnership_llm_enhancement_service import create_partnership_llm_enhancer
            self.llm_enhancer = create_partnership_llm_enhancer()
            self.logger.info("LLM enhancement service inicializado")
        except ImportError:
            self.logger.warning("LLM enhancement service não disponível")
        
        # 🆕 External Profile Enrichment Service
        self.external_enrichment = None
        if EXTERNAL_ENRICHMENT_AVAILABLE:
            try:
                self.external_enrichment = ExternalProfileEnrichmentService()
                self.logger.info("External profile enrichment service inicializado")
            except Exception as e:
                self.logger.warning(f"Erro ao inicializar external enrichment: {e}")
        
        # 🆕 FASE 2: Partnership Similarity Service
        self.similarity_service = None
        if SIMILARITY_SERVICE_AVAILABLE:
            try:
                self.similarity_service = PartnershipSimilarityService()
                self.logger.info("🆕 FASE 2: Partnership similarity service inicializado")
            except Exception as e:
                self.logger.warning(f"Erro ao inicializar similarity service: {e}")
        
        # 🆕 FASE 3: Unified Cache Service
        self.unified_cache = None
        if UNIFIED_CACHE_AVAILABLE:
            try:
                self.unified_cache = unified_cache
                # Inicializar assincronamente quando necessário
                self.logger.info("🆕 FASE 3: Unified cache service configurado")
            except Exception as e:
                self.logger.warning(f"Erro ao configurar unified cache: {e}")
        
        # Flag para controlar uso de LLM
        import os
        self.llm_enabled = os.getenv("ENABLE_PARTNERSHIP_LLM", "false").lower() == "true"

    async def get_recommendations(
        self,
        lawyer_id: str,
        limit: int = 10,
        min_confidence: float = 0.6,
        exclude_same_firm: bool = True,
        expand_search: bool = False,  # 🆕 Novo parâmetro para busca híbrida
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
            # 1. Obter recomendações internas (lógica existente)
            internal_recommendations = await self._get_internal_recommendations(
                lawyer_id, limit, min_confidence, exclude_same_firm
            )
            
            # 2. 🆕 Busca externa se habilitada
            external_recommendations = []
            if expand_search and self.external_enrichment:
                try:
                    external_recommendations = await self._get_external_recommendations(
                        lawyer_id, limit // 2  # Até metade do limite para externos
                    )
                    self.logger.info(f"🌐 {len(external_recommendations)} recomendações externas encontradas")
                except Exception as e:
                    self.logger.error(f"Erro na busca externa: {e}")
            
            # 3. Mesclar e ordenar resultados
            all_recommendations = internal_recommendations + external_recommendations
            all_recommendations.sort(key=lambda r: r.final_score, reverse=True)
            
            # 4. Aplicar diversificação e limite final
            final_recommendations = self._diversify_by_firm(all_recommendations, limit)
            
            # 5. 🆕 Aprimoramento LLM (se habilitado)
            if self.llm_enabled and self.llm_enhancer and final_recommendations:
                try:
                    # Criar perfil do advogado alvo para análise LLM
                    target_profile = await self._create_lawyer_profile_for_llm(lawyer_id)
                    
                    if target_profile:
                        # Aprimorar recomendações com insights LLM
                        enhanced_recs = await self.llm_enhancer.enhance_partnership_recommendations(
                            final_recommendations, target_profile
                        )
                        final_recommendations = enhanced_recs
                        
                        self.logger.info(f"🤖 {len(final_recommendations)} recomendações aprimoradas com LLM")
                    else:
                        self.logger.warning("Não foi possível criar perfil LLM - usando recomendações tradicionais")
                        
                except Exception as e:
                    self.logger.error(f"Erro no aprimoramento LLM: {e}")
                    # Manter recomendações tradicionais em caso de erro
                    pass
            
            self.logger.info(
                f"✅ {len(final_recommendations)} recomendações geradas para advogado {lawyer_id} "
                f"(internas: {len(internal_recommendations)}, externas: {len(external_recommendations)})"
            )
            return final_recommendations
            
        except Exception as e:
            self.logger.error(f"❌ Erro inesperado ao gerar recomendações para {lawyer_id}: {e}")
            return []

    async def _get_internal_recommendations(
        self,
        lawyer_id: str,
        limit: int,
        min_confidence: float,
        exclude_same_firm: bool,
    ) -> List[PartnershipRecommendation]:
        """Gera recomendações internas usando a lógica existente."""
        
        # 1. Clusters do advogado alvo
        target_clusters = await self._get_lawyer_clusters(lawyer_id, min_confidence)
        if not target_clusters:
            self.logger.info(f"Advogado {lawyer_id} sem clusters fortes (min_conf={min_confidence}) – retornando lista vazia")
            return []

        # 🆕 FASE 2: Obter dados do advogado alvo para similarity analysis
        target_lawyer_info = await self._get_lawyer_info(lawyer_id)

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

            # 🆕 FASE 1: Calcular Quality Score usando FeatureCalculator
            quality_result = await self.calculate_quality_scores(info)
            quality_score = quality_result["quality_score"]
            quality_breakdown = quality_result["breakdown"]

            # 🆕 FASE 2: Calcular Similarity Score usando PartnershipSimilarityService
            similarity_result = await self.calculate_similarity_scores(target_lawyer_info, info)
            similarity_score = similarity_result["similarity_score"]
            similarity_breakdown = similarity_result["similarity_breakdown"]

            # Obter pesos otimizados do ML service ou usar padrão
            weights = self._get_optimized_weights()
            
            # 🆕 Score final atualizado com Quality Score (15%) e Similarity Score (10%)
            # Ajustar pesos: Complementarity (35%), Quality (15%), Similarity (10%), 
            # Momentum (15%), Reputation (10%), Diversity (5%), Firm Synergy (10%)
            final_score = (
                complementarity * 0.35 +       # Reduzido de 45% para 35%
                quality_score * 0.15 +         # 🆕 Novo: Quality Score
                similarity_score * 0.10 +      # 🆕 FASE 2: Similarity Score
                momentum * 0.15 +              # Mantido em 15%
                reputation * 0.10 +            # Mantido em 10%
                diversity * 0.05 +             # Mantido em 5%
                firm_synergy * 0.10            # Mantido em 10%
            )
            
            # Aplicar penalidade se muito poucos clusters complementares
            if len(complement_clusters) == 1:
                final_score *= 0.8  # 20% de penalidade

            # Motivo textual melhorado com quality insights
            top_clusters = sorted(complement_clusters, key=lambda x: x["confidence"], reverse=True)[:2]
            cluster_names = [c["cluster_label"] for c in top_clusters]
            
            # Adicionar insights de qualidade ao motivo
            quality_insights = []
            if quality_breakdown.get("interaction", 0) > 0.7:
                quality_insights.append("alta participação na plataforma")
            if quality_breakdown.get("qualification", 0) > 0.7:
                quality_insights.append("forte qualificação")
            if quality_breakdown.get("maturity", 0) > 0.7:
                quality_insights.append("experiência consolidada")
            
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
            
            # Adicionar insights de qualidade se relevantes
            if quality_insights:
                reason += f" Destaque: {', '.join(quality_insights)}."

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
                    # 🆕 FASE 1: Adicionar campos de qualidade
                    quality_score=quality_score,
                    quality_breakdown=quality_breakdown,
                    # 🆕 FASE 2: Adicionar campos de similaridade
                    similarity_score=similarity_score,
                    similarity_breakdown=similarity_breakdown,
                    firm_synergy_reason=synergy_reason, # NOVO: Incluir razão da sinergia
                    status="verified",  # 🆕 Membro verificado da plataforma
                )
            )

        # 5. Ordenar por score
        recommendations.sort(key=lambda r: r.final_score, reverse=True)
        return recommendations

    async def _get_external_recommendations(
        self,
        lawyer_id: str,
        limit: int,
    ) -> List[PartnershipRecommendation]:
        """🆕 Gera recomendações externas usando ExternalProfileEnrichmentService."""
        
        if not self.external_enrichment:
            return []
        
        try:
            # 1. Obter clusters do advogado alvo para determinar áreas de busca
            target_clusters = await self._get_lawyer_clusters(lawyer_id, 0.6)
            if not target_clusters:
                return []
            
            # 2. Extrair áreas complementares para busca
            complementary_areas = await self._get_complementary_search_areas(target_clusters)
            if not complementary_areas:
                return []
            
            # 3. Buscar perfis externos para cada área complementar
            external_profiles = []
            for area in complementary_areas[:3]:  # Limitar a 3 áreas para performance
                try:
                    profile = await self.external_enrichment.enrich_profile(
                        name=f"advogado {area['name']}",  # Busca genérica por área
                        area=area["name"],
                        city="São Paulo"  # TODO: Usar localização do advogado alvo
                    )
                    if profile:
                        # Simular clusters complementares para o perfil externo
                        profile["simulated_clusters"] = [area["name"]]
                        profile["area_expertise"] = area["name"]
                        external_profiles.append(profile)
                        
                except Exception as e:
                    self.logger.warning(f"Erro ao buscar perfil externo para {area['name']}: {e}")
                    continue
            
            # 4. Converter perfis externos em recomendações
            external_recommendations = []
            for profile in external_profiles[:limit]:
                # Simular scoring para perfil externo (simplificado)
                external_score = self._calculate_external_profile_score(profile)
                
                recommendation = PartnershipRecommendation(
                    lawyer_id=f"external_{profile.get('profile_url', 'unknown').split('/')[-1]}",
                    lawyer_name=profile.get("full_name", "Profissional não identificado"),
                    firm_name=None,  # Perfis externos não têm firma associada
                    compatibility_clusters=profile.get("simulated_clusters", []),
                    complementarity_score=external_score["complementarity"],
                    diversity_score=external_score["diversity"],
                    momentum_score=external_score["momentum"],
                    reputation_score=external_score["reputation"],
                    firm_synergy_score=0.0,  # Sem sinergia de firma para externos
                    final_score=external_score["final"],
                    recommendation_reason=f"Especialista em {profile.get('area_expertise', 'área complementar')} encontrado via busca pública. "
                                        f"Confiança na análise: {profile.get('confidence_score', 0.7):.0%}.",
                    firm_synergy_reason=None,
                    status="public_profile",  # 🆕 Perfil público
                    profile_data={  # 🆕 Dados do perfil externo
                        "profile_url": profile.get("profile_url"),
                        "full_name": profile.get("full_name"),
                        "headline": profile.get("headline"),
                        "summary": profile.get("summary"),
                        "photo_url": profile.get("photo_url"),
                        "city": profile.get("city"),
                        "confidence_score": profile.get("confidence_score"),
                    }
                )
                external_recommendations.append(recommendation)
            
            return external_recommendations
            
        except Exception as e:
            self.logger.error(f"Erro na busca externa: {e}")
            return []

    async def _get_complementary_search_areas(self, target_clusters: Dict[str, float]) -> List[Dict[str, str]]:
        """Identifica áreas complementares para busca externa baseadas nos clusters do advogado."""
        
        # Mapeamento de clusters para áreas de busca complementares
        # TODO: Implementar lógica mais sofisticada baseada em dados reais
        cluster_complementarity_map = {
            "direito_trabalhista": ["direito_previdenciario", "direito_sindical"],
            "direito_civil": ["direito_empresarial", "direito_imobiliario"],
            "direito_criminal": ["direito_compliance", "direito_administrativo"],
            "direito_tributario": ["direito_empresarial", "direito_financeiro"],
            "direito_empresarial": ["direito_tributario", "direito_concorrencial"],
        }
        
        complementary_areas = []
        for cluster_id in target_clusters.keys():
            # Simplificar cluster_id para área de busca
            area_key = cluster_id.lower().replace("_", "_")
            
            if area_key in cluster_complementarity_map:
                for comp_area in cluster_complementarity_map[area_key]:
                    complementary_areas.append({
                        "name": comp_area.replace("_", " ").title(),
                        "search_key": comp_area
                    })
        
        # Remover duplicatas e limitar
        seen = set()
        unique_areas = []
        for area in complementary_areas:
            if area["search_key"] not in seen:
                seen.add(area["search_key"])
                unique_areas.append(area)
        
        return unique_areas[:5]  # Máximo 5 áreas complementares

    def _calculate_external_profile_score(self, profile: Dict[str, Any]) -> Dict[str, float]:
        """Calcula scores simplificados para perfil externo."""
        
        confidence = profile.get("confidence_score", 0.7)
        
        # Scores baseados na confiança da busca externa
        complementarity = min(0.9, confidence * 1.2)  # Boost para perfis externos
        diversity = 0.8  # Score fixo para diversidade (perfil novo)
        momentum = 0.6  # Score médio para momentum (sem dados históricos)
        reputation = confidence  # Baseado na confiança da busca
        
        # Score final com peso menor para perfis externos
        final_score = (
            complementarity * 0.4 +
            diversity * 0.2 +
            momentum * 0.2 +
            reputation * 0.2
        ) * 0.8  # Fator de desconto para perfis externos
        
        return {
            "complementarity": complementarity,
            "diversity": diversity,
            "momentum": momentum,
            "reputation": reputation,
            "final": final_score
        }

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

    # 🆕 FASE 1: Método de Unificação com FeatureCalculator
    async def calculate_quality_scores(
        self, 
        lawyer_data: Dict[str, Any], 
        target_lawyer_data: Optional[Dict[str, Any]] = None
    ) -> Dict[str, float]:
        """
        🆕 FASE 1: Calcula scores de qualidade usando FeatureCalculator do algoritmo_match.py
        🆕 FASE 3: Otimizado com UnifiedCacheService para eliminar recálculos
        
        Utiliza as features Q (qualification), M (maturity), I (interaction/IEP), 
        C (soft_skill), E (firm_reputation) para garantir consistência entre 
        o sistema de casos e o sistema de parcerias.
        
        Args:
            lawyer_data: Dados do advogado candidato
            target_lawyer_data: Dados do advogado alvo (opcional, para comparações)
            
        Returns:
            Dict com quality_score e breakdown das features individuais
        """
        lawyer_id = lawyer_data.get("id", "unknown")
        
        # 🆕 FASE 3: Tentar cache primeiro se disponível
        if UNIFIED_CACHE_AVAILABLE and self.unified_cache:
            try:
                # Inicializar cache se necessário
                if not self.unified_cache.is_connected:
                    await self.unified_cache.initialize()
                
                # Tentar obter do cache
                cached_quality = await self.unified_cache.get_cached_quality_score(lawyer_id)
                if cached_quality and cached_quality.get("source") != "error_fallback":
                    self.logger.debug(f"🚀 FASE 3: Quality score from cache para {lawyer_id}")
                    return cached_quality
                
            except Exception as e:
                self.logger.warning(f"Erro ao acessar cache: {e}")
        
        if not FEATURE_CALCULATOR_AVAILABLE:
            # Fallback para scoring legado se FeatureCalculator não disponível
            result = {
                "quality_score": 0.5,
                "breakdown": {
                    "qualification": 0.5,
                    "maturity": 0.5,
                    "interaction": 0.5,
                    "soft_skill": 0.5,
                    "firm_reputation": 0.5
                },
                "source": "legacy_fallback"
            }
            
            # 🆕 FASE 3: Cache do fallback também
            if UNIFIED_CACHE_AVAILABLE and self.unified_cache:
                try:
                    await self.unified_cache.set_cached_quality_score(lawyer_id, result)
                except Exception:
                    pass  # Falha no cache não deve afetar a funcionalidade
            
            return result
        
        try:
            # 🆕 FASE 3: Usar get_or_calculate_features para otimização
            if UNIFIED_CACHE_AVAILABLE and self.unified_cache:
                # Função de cálculo para passar ao cache
                async def calculate_features():
                    lawyer_obj = self._convert_to_lawyer_dataclass(lawyer_data)
                    dummy_case = Case(
                        id="partnership_context",
                        area=lawyer_data.get("main_expertise", "geral"),
                        subarea="partnership",
                        urgency_h=72,
                        coords=lawyer_obj.geo_latlon,
                        complexity="MEDIUM",
                        type="PARTNERSHIP",
                        radius_km=100
                    )
                    calculator = FeatureCalculator(dummy_case, lawyer_obj)
                    return await calculator.all_async()
                
                # Usar cache otimizado
                cached_features = await self.unified_cache.get_or_calculate_features(
                    lawyer_id, calculate_features
                )
                
                # Construir resultado do cache
                result = {
                    "quality_score": cached_features.quality_score,
                    "breakdown": cached_features.quality_breakdown or {
                        "qualification": cached_features.qualification_score,
                        "maturity": cached_features.maturity_score,
                        "interaction": cached_features.interaction_score,
                        "soft_skill": cached_features.soft_skill_score,
                        "firm_reputation": cached_features.firm_reputation_score
                    },
                    "weights": {
                        "qualification": 0.25,
                        "maturity": 0.25,
                        "interaction": 0.25,
                        "soft_skill": 0.15,
                        "firm_reputation": 0.10
                    },
                    "source": f"unified_cache_{cached_features.source}"
                }
                
                # Cache do resultado final
                await self.unified_cache.set_cached_quality_score(lawyer_id, result)
                
                self.logger.debug(f"🎯 FASE 3: Quality score calculado/cached: {result['quality_score']:.3f} para {lawyer_id}")
                return result
            
            else:
                # Fallback para cálculo direto sem cache
                lawyer_obj = self._convert_to_lawyer_dataclass(lawyer_data)
                dummy_case = Case(
                    id="partnership_context",
                    area=lawyer_data.get("main_expertise", "geral"),
                    subarea="partnership",
                    urgency_h=72,
                    coords=lawyer_obj.geo_latlon,
                    complexity="MEDIUM",
                    type="PARTNERSHIP",
                    radius_km=100
                )
                
                calculator = FeatureCalculator(dummy_case, lawyer_obj)
                features = await calculator.all_async()
                
                quality_features = {
                    "qualification": features.get("Q", 0.0),
                    "maturity": features.get("M", 0.0),
                    "interaction": features.get("I", 0.0),
                    "soft_skill": features.get("C", 0.0),
                    "firm_reputation": features.get("E", 0.0)
                }
                
                partnership_weights = {
                    "qualification": 0.25,
                    "maturity": 0.25,
                    "interaction": 0.25,
                    "soft_skill": 0.15,
                    "firm_reputation": 0.10
                }
                
                quality_score = sum(
                    quality_features[feature] * weight 
                    for feature, weight in partnership_weights.items()
                )
                
                quality_score = max(0.0, min(1.0, quality_score))
                
                self.logger.debug(f"🎯 Quality score calculado: {quality_score:.3f} para {lawyer_id}")
                
                return {
                    "quality_score": quality_score,
                    "breakdown": quality_features,
                    "weights": partnership_weights,
                    "source": "feature_calculator_direct"
                }
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao calcular quality score: {e}")
            # Fallback em caso de erro
            error_result = {
                "quality_score": 0.5,
                "breakdown": {
                    "qualification": 0.5,
                    "maturity": 0.5,
                    "interaction": 0.5,
                    "soft_skill": 0.5,
                    "firm_reputation": 0.5
                },
                "source": "error_fallback"
            }
            
            # Cache do erro também para evitar recálculos
            if UNIFIED_CACHE_AVAILABLE and self.unified_cache:
                try:
                    await self.unified_cache.set_cached_quality_score(lawyer_id, error_result)
                except Exception:
                    pass
            
            return error_result

    # 🆕 FASE 2: Método de Unificação com PartnershipSimilarityService
    async def calculate_similarity_scores(
        self, 
        target_lawyer_data: Dict[str, Any], 
        candidate_lawyer_data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        🆕 FASE 2: Calcula scores de similaridade usando PartnershipSimilarityService
        🆕 FASE 3: Otimizado com UnifiedCacheService para eliminar recálculos de similaridade
        
        Implementa busca por complementaridade e profundidade baseada na
        adaptação das lógicas do algoritmo_match.py para parcerias.
        
        Args:
            target_lawyer_data: Dados do advogado que busca parceria
            candidate_lawyer_data: Dados do candidato a parceiro
            
        Returns:
            Dict com similarity_score e breakdown da análise
        """
        target_id = target_lawyer_data.get("id", "unknown_target")
        candidate_id = candidate_lawyer_data.get("id", "unknown_candidate")
        
        # 🆕 FASE 3: Tentar cache de similaridade primeiro
        if UNIFIED_CACHE_AVAILABLE and self.unified_cache:
            try:
                if not self.unified_cache.is_connected:
                    await self.unified_cache.initialize()
                
                cached_similarity = await self.unified_cache.get_cached_similarity(
                    target_id, candidate_id
                )
                if cached_similarity:
                    self.logger.debug(f"🚀 FASE 3: Similarity score from cache para {target_id} ↔ {candidate_id}")
                    return {
                        "similarity_score": cached_similarity.similarity_score,
                        "similarity_breakdown": cached_similarity.similarity_breakdown,
                        "similarity_reason": cached_similarity.similarity_reason,
                        "complementary_areas": cached_similarity.complementary_areas,
                        "shared_areas": cached_similarity.shared_areas,
                        "source": f"unified_cache_{cached_similarity.source}"
                    }
                
            except Exception as e:
                self.logger.warning(f"Erro ao acessar similarity cache: {e}")
        
        if not SIMILARITY_SERVICE_AVAILABLE or not self.similarity_service:
            # Fallback para scoring básico se PartnershipSimilarityService não disponível
            fallback_result = {
                "similarity_score": 0.5,
                "similarity_breakdown": {
                    "complementarity": 0.5,
                    "depth": 0.5,
                    "strategy_used": "fallback",
                    "confidence": 0.3
                },
                "similarity_reason": "Análise básica de similaridade",
                "source": "fallback"
            }
            
            # 🆕 FASE 3: Cache do fallback também para evitar recálculos
            if UNIFIED_CACHE_AVAILABLE and self.unified_cache:
                try:
                    from .unified_cache_service import CachedSimilarity
                    cached_sim = CachedSimilarity(
                        target_lawyer_id=target_id,
                        candidate_lawyer_id=candidate_id,
                        similarity_score=0.5,
                        complementarity_score=0.5,
                        depth_score=0.5,
                        confidence=0.3,
                        strategy_used="fallback",
                        similarity_breakdown=fallback_result["similarity_breakdown"],
                        similarity_reason=fallback_result["similarity_reason"],
                        complementary_areas=[],
                        shared_areas=[],
                        cached_at=datetime.now(),
                        source="fallback"
                    )
                    await self.unified_cache.set_cached_similarity(cached_sim)
                except Exception:
                    pass
            
            return fallback_result
        
        try:
            # Usar o PartnershipSimilarityService para análise avançada
            result = await self.similarity_service.enhance_partnership_recommendation(
                target_lawyer_data, candidate_lawyer_data, strategy="hybrid"
            )
            
            self.logger.debug(f"🔍 FASE 3: Similarity score calculado: {result['similarity_score']:.3f} - {result.get('similarity_reason', '')}")
            
            # 🆕 FASE 3: Cache do resultado calculado
            if UNIFIED_CACHE_AVAILABLE and self.unified_cache:
                try:
                    from .unified_cache_service import CachedSimilarity
                    cached_sim = CachedSimilarity(
                        target_lawyer_id=target_id,
                        candidate_lawyer_id=candidate_id,
                        similarity_score=result["similarity_score"],
                        complementarity_score=result["similarity_breakdown"].get("complementarity", 0.0),
                        depth_score=result["similarity_breakdown"].get("depth", 0.0),
                        confidence=result["similarity_breakdown"].get("confidence", 0.0),
                        strategy_used=result["similarity_breakdown"].get("strategy_used", "unknown"),
                        similarity_breakdown=result["similarity_breakdown"],
                        similarity_reason=result.get("similarity_reason", ""),
                        complementary_areas=result.get("complementary_areas", []),
                        shared_areas=result.get("shared_areas", []),
                        cached_at=datetime.now(),
                        source="similarity_service"
                    )
                    await self.unified_cache.set_cached_similarity(cached_sim)
                except Exception as e:
                    self.logger.warning(f"Erro ao armazenar similarity cache: {e}")
            
            return {
                **result,
                "source": "similarity_service"
            }
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao calcular similarity score: {e}")
            # Fallback em caso de erro
            error_result = {
                "similarity_score": 0.4,  # Score conservador em caso de erro
                "similarity_breakdown": {
                    "complementarity": 0.4,
                    "depth": 0.4,
                    "strategy_used": "error_fallback",
                    "confidence": 0.2
                },
                "similarity_reason": "Erro na análise - usando score conservador",
                "source": "error_fallback"
            }
            
            # 🆕 FASE 3: Cache do erro também
            if UNIFIED_CACHE_AVAILABLE and self.unified_cache:
                try:
                    from .unified_cache_service import CachedSimilarity
                    cached_sim = CachedSimilarity(
                        target_lawyer_id=target_id,
                        candidate_lawyer_id=candidate_id,
                        similarity_score=0.4,
                        complementarity_score=0.4,
                        depth_score=0.4,
                        confidence=0.2,
                        strategy_used="error_fallback",
                        similarity_breakdown=error_result["similarity_breakdown"],
                        similarity_reason=error_result["similarity_reason"],
                        complementary_areas=[],
                        shared_areas=[],
                        cached_at=datetime.now(),
                        source="error_fallback"
                    )
                    await self.unified_cache.set_cached_similarity(cached_sim)
                except Exception:
                    pass
            
            return error_result

    async def _get_lawyer_info(self, lawyer_id: str) -> Dict[str, Any]:
        """
        🆕 FASE 2: Obtém informações detalhadas de um advogado para análise de similaridade.
        
        Args:
            lawyer_id: ID do advogado
            
        Returns:
            Dict com dados do advogado formatados para o PartnershipSimilarityService
        """
        try:
            # Query para obter dados completos do advogado
            query = text("""
                SELECT 
                    l.id,
                    l.name,
                    l.anos_experiencia,
                    l.avg_hourly_fee,
                    l.success_rate,
                    l.cases_30d,
                    l.rating,
                    l.response_time_hours,
                    lf.name as firm_name,
                    lf.id as firm_id,
                    ARRAY_AGG(DISTINCT cm.cluster_label) as expertise_areas
                FROM lawyers l
                LEFT JOIN law_firms lf ON l.law_firm_id = lf.id
                LEFT JOIN lawyer_clusters lc ON l.id = lc.lawyer_id
                LEFT JOIN cluster_metadata cm ON lc.cluster_id = cm.cluster_id
                WHERE l.id = :lawyer_id
                    AND (lc.confidence_score IS NULL OR lc.confidence_score >= 0.5)
                GROUP BY l.id, l.name, l.anos_experiencia, l.avg_hourly_fee, 
                         l.success_rate, l.cases_30d, l.rating, l.response_time_hours,
                         lf.name, lf.id
            """)
            
            result = await self.db.execute(query, {"lawyer_id": lawyer_id})
            row = result.fetchone()
            
            if not row:
                # Fallback mínimo se não encontrar dados
                return {
                    "id": lawyer_id,
                    "name": "Advogado",
                    "expertise_areas": [],
                    "anos_experiencia": 5,
                    "success_rate": 0.7,
                    "cases_30d": 10,
                    "rating": 4.0
                }
            
            # Converter dados para formato esperado pelo PartnershipSimilarityService
            lawyer_info = {
                "id": row.id,
                "name": row.name,
                "expertise_areas": [area for area in (row.expertise_areas or []) if area],
                "anos_experiencia": row.anos_experiencia or 5,
                "success_rate": row.success_rate or 0.7,
                "cases_30d": row.cases_30d or 10,
                "rating": row.rating or 4.0,
                "response_time_hours": row.response_time_hours or 24,
                "avg_hourly_fee": row.avg_hourly_fee or 300.0,
                "firm_name": row.firm_name,
                "firm_id": row.firm_id,
                "geo_latlon": [-23.5505, -46.6333],  # TODO: obter coordenadas reais
            }
            
            return lawyer_info
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao obter dados do advogado {lawyer_id}: {e}")
            # Fallback mínimo em caso de erro
            return {
                "id": lawyer_id,
                "name": "Advogado",
                "expertise_areas": [],
                "anos_experiencia": 5,
                "success_rate": 0.7,
                "cases_30d": 10,
                "rating": 4.0
            }

    def _convert_to_lawyer_dataclass(self, lawyer_data: Dict[str, Any]) -> Lawyer:
        """
        Converte dados do advogado do formato de parceria para a dataclass Lawyer 
        do algoritmo_match.py para garantir compatibilidade.
        """
        if not FEATURE_CALCULATOR_AVAILABLE:
            # Se FeatureCalculator não disponível, retornar dados mock
            self.logger.debug("FeatureCalculator não disponível - retornando dados mock para conversão")
            return type('MockLawyer', (), {
                'id': lawyer_data.get("id", "mock"),
                'nome': lawyer_data.get("name", "Mock Lawyer"),
                'tags_expertise': lawyer_data.get("expertise_areas", []),
                'geo_latlon': tuple(lawyer_data.get("geo_latlon", [-23.5505, -46.6333])),
                'kpi': type('MockKPI', (), {
                    'success_rate': lawyer_data.get("success_rate", 0.7),
                    'avaliacao_media': lawyer_data.get("rating", 4.0)
                })()
            })()
        
        try:
            # Dados básicos
            lawyer_id = lawyer_data.get("id", "unknown")
            nome = lawyer_data.get("name", "Advogado")
            tags_expertise = lawyer_data.get("expertise_areas", [])
            
            # Geolocalização (com fallback para São Paulo)
            geo_latlon = lawyer_data.get("geo_latlon", (-23.5505, -46.6333))
            if isinstance(geo_latlon, list):
                geo_latlon = tuple(geo_latlon)
            
            # Currículo JSON
            curriculo_json = lawyer_data.get("curriculo_json", {})
            if not curriculo_json:
                curriculo_json = {
                    "anos_experiencia": lawyer_data.get("anos_experiencia", 5),
                    "pos_graduacoes": [],
                    "reconhecimentos": []
                }
            
            # KPI - criar baseado nos dados disponíveis
            kpi = KPI(
                success_rate=lawyer_data.get("success_rate", 0.7),
                cases_30d=lawyer_data.get("cases_30d", 10),
                avaliacao_media=lawyer_data.get("rating", 4.0),
                tempo_resposta_h=lawyer_data.get("response_time_hours", 24),
                active_cases=lawyer_data.get("active_cases", 5),
                cv_score=lawyer_data.get("cv_score", 0.6),
                success_status=lawyer_data.get("success_status", "V")
            )
            
            # Criar objeto Lawyer
            lawyer = Lawyer(
                id=lawyer_id,
                nome=nome,
                tags_expertise=tags_expertise,
                geo_latlon=geo_latlon,
                curriculo_json=curriculo_json,
                kpi=kpi,
                max_concurrent_cases=lawyer_data.get("max_concurrent_cases", 10),
                firm_id=lawyer_data.get("firm_id"),
                avg_hourly_fee=lawyer_data.get("avg_hourly_fee", 300.0)
            )
            
            # Adicionar dados de maturidade se disponíveis
            if "maturity_data" in lawyer_data:
                maturity = lawyer_data["maturity_data"]
                lawyer.maturity_data = ProfessionalMaturityData(
                    experience_years=maturity.get("experience_years", 5.0),
                    network_strength=maturity.get("network_strength", 50),
                    reputation_signals=maturity.get("reputation_signals", 10),
                    responsiveness_hours=maturity.get("responsiveness_hours", 24.0)
                )
            
            return lawyer
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao converter dados para Lawyer dataclass: {e}")
            # Fallback mínimo em caso de erro
            return Lawyer(
                id="fallback",
                nome="Advogado",
                tags_expertise=["geral"],
                geo_latlon=(-23.5505, -46.6333),
                curriculo_json={},
                kpi=KPI(
                    success_rate=0.5,
                    cases_30d=5,
                    avaliacao_media=3.5,
                    tempo_resposta_h=48
                )
            )

    async def _create_lawyer_profile_for_llm(self, lawyer_id: str):
        """Cria perfil completo do advogado para análise LLM."""
        try:
            from .partnership_llm_enhancement_service import LawyerProfileForPartnership
            
            # Query para obter dados completos do advogado
            query = text("""
                SELECT 
                    l.id,
                    l.name,
                    lf.name as firm_name,
                    l.anos_experiencia,
                    l.communication_style,
                    l.market_reputation,
                    l.fee_structure_style,
                    ARRAY_AGG(DISTINCT cm.cluster_label) as specializations,
                    ARRAY_AGG(DISTINCT l.geographic_focus) as geo_focus,
                    ARRAY_AGG(DISTINCT l.client_types) as client_types
                FROM lawyers l
                LEFT JOIN law_firms lf ON l.law_firm_id = lf.id
                LEFT JOIN lawyer_clusters lc ON l.id = lc.lawyer_id
                LEFT JOIN cluster_metadata cm ON lc.cluster_id = cm.cluster_id
                WHERE l.id = :lawyer_id
                    AND (lc.confidence_score IS NULL OR lc.confidence_score >= 0.5)
                GROUP BY l.id, l.name, lf.name, l.anos_experiencia, 
                         l.communication_style, l.market_reputation, l.fee_structure_style
            """)
            
            result = await self.db.execute(query, {"lawyer_id": lawyer_id})
            row = result.fetchone()
            
            if not row:
                return None
                
            return LawyerProfileForPartnership(
                lawyer_id=row.id,
                name=row.name,
                firm_name=row.firm_name,
                experience_years=row.anos_experiencia or 5,
                specialization_areas=row.specializations or [],
                recent_cases_summary="",  # TODO: Implementar busca de casos recentes
                communication_style=row.communication_style or "professional",
                collaboration_history=[],  # TODO: Implementar histórico de colaborações
                market_reputation=row.market_reputation or "established",
                client_types=row.client_types or ["corporate"],
                fee_structure_style=row.fee_structure_style or "competitive",
                geographic_focus=row.geo_focus or ["São Paulo"]
            )
            
        except Exception as e:
            self.logger.error(f"Erro ao criar perfil LLM para {lawyer_id}: {e}")
            return None 