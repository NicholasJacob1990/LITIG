#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Partnership Similarity Service
==============================

🆕 FASE 2: Adaptação da Lógica de Similaridade para Parcerias

Este serviço implementa a adaptação inteligente das lógicas de similaridade 
do algoritmo_match.py para o contexto de parcerias estratégicas.

Implementa duas estratégias:
1. **Busca por Complementaridade**: Encontrar parceiros com expertise que 
   complement a área de atuação (ex: Tributário + Societário para M&A)
2. **Busca por Profundidade**: Encontrar parceiros com expertise profunda 
   na mesma área para casos complexos

Baseado na análise do UNIFIED_RECOMMENDATION_PLAN.md
"""

from __future__ import annotations

import logging
import math
from typing import List, Dict, Any, Optional, Tuple, Set
from dataclasses import dataclass
import numpy as np

# Import do FeatureCalculator para reutilizar lógicas
try:
    from ..Algoritmo.algoritmo_match import FeatureCalculator, Lawyer, Case
    FEATURE_CALCULATOR_AVAILABLE = True
except ImportError:
    FEATURE_CALCULATOR_AVAILABLE = False

logger = logging.getLogger(__name__)


@dataclass
class SimilarityResult:
    """Resultado de análise de similaridade entre advogados para parcerias."""
    
    target_lawyer_id: str
    candidate_lawyer_id: str
    
    # Scores de similaridade
    complementarity_score: float  # Quão complementar é a expertise
    depth_score: float            # Quão profunda é a expertise na mesma área
    synergy_score: float          # Score combinado de sinergia
    
    # Detalhamento da análise
    complementary_areas: List[str]  # Áreas onde há complementaridade
    shared_areas: List[str]         # Áreas compartilhadas (profundidade)
    synergy_reason: str             # Explicação da sinergia
    
    # Metadados
    strategy_used: str              # "complementarity", "depth", ou "hybrid"
    confidence: float               # Confiança na análise


class PartnershipSimilarityService:
    """
    🆕 FASE 2: Serviço de Similaridade para Parcerias
    
    Adapta e estende as lógicas do algoritmo_match.py para encontrar
    parceiros ideais baseado em complementaridade ou profundidade.
    """
    
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        
        # Matriz de sinergia entre áreas do direito
        self.synergy_matrix = self._build_synergy_matrix()
        
        # Áreas de alta complexidade que se beneficiam de profundidade
        self.complex_areas = {
            "direito_tributario", "direito_societario", "m_and_a", 
            "direito_bancario", "direito_imobiliario", "propriedade_intelectual",
            "direito_administrativo", "regulatorio"
        }
        
        self.logger.info("PartnershipSimilarityService inicializado com matriz de sinergia")
    
    def _build_synergy_matrix(self) -> Dict[str, Dict[str, float]]:
        """
        Constrói matriz de sinergia entre áreas do direito.
        
        Returns:
            Dict com scores de sinergia entre pares de áreas (0.0 a 1.0)
        """
        
        # Matriz de sinergia baseada em colaborações reais no mercado jurídico
        synergy_matrix = {
            # Direito Empresarial + M&A são altamente sinérgicos
            "direito_empresarial": {
                "direito_tributario": 0.9,      # Estruturação societária + tributos
                "m_and_a": 0.95,                # Fusões e aquisições
                "direito_societario": 0.9,      # Sociedades e contratos
                "direito_bancario": 0.8,        # Operações bancárias
                "regulatorio": 0.8,             # Compliance empresarial
                "direito_imobiliario": 0.7,     # Investimentos imobiliários
                "propriedade_intelectual": 0.75  # Ativos intangíveis
            },
            
            # Direito Tributário tem sinergia com várias áreas
            "direito_tributario": {
                "direito_empresarial": 0.9,
                "direito_societario": 0.85,
                "m_and_a": 0.9,                 # Aspectos fiscais de M&A
                "direito_imobiliario": 0.8,     # Tributação imobiliária
                "direito_bancario": 0.75,       # Tributação bancária
                "previdenciario": 0.7            # Aspectos tributários previdenciários
            },
            
            # M&A é complexo e requer várias expertises
            "m_and_a": {
                "direito_empresarial": 0.95,
                "direito_tributario": 0.9,
                "direito_societario": 0.9,
                "direito_bancario": 0.85,       # Financiamento de aquisições
                "regulatorio": 0.8,             # Aprovações regulatórias
                "direito_concorrencial": 0.9,   # Análise antitruste
                "propriedade_intelectual": 0.75  # Due diligence de PI
            },
            
            # Direito do Trabalho
            "direito_trabalhista": {
                "previdenciario": 0.85,          # Benefícios e previdência
                "direito_empresarial": 0.7,      # Relações trabalhistas empresariais
                "regulatorio": 0.6               # Compliance trabalhista
            },
            
            # Direito Civil e áreas relacionadas
            "direito_civil": {
                "direito_familia": 0.8,          # Direito civil + família
                "direito_imobiliario": 0.75,     # Contratos imobiliários
                "direito_consumidor": 0.7,       # Relações de consumo
                "responsabilidade_civil": 0.9    # Acidentes e indenizações
            },
            
            # Direito Penal e áreas relacionadas
            "direito_penal": {
                "direito_empresarial": 0.8,      # Crime empresarial/compliance
                "regulatorio": 0.75,             # Crimes regulatórios
                "direito_tributario": 0.7        # Crimes contra ordem tributária
            },
            
            # Propriedade Intelectual
            "propriedade_intelectual": {
                "direito_empresarial": 0.75,
                "m_and_a": 0.75,
                "direito_digital": 0.9,          # PI digital
                "direito_concorrencial": 0.8     # Concorrência desleal
            },
            
            # Direito Digital (área emergente)
            "direito_digital": {
                "propriedade_intelectual": 0.9,
                "direito_consumidor": 0.8,       # E-commerce
                "regulatorio": 0.85,             # LGPD e regulações
                "direito_empresarial": 0.7       # Transformação digital
            }
        }
        
        # Tornar matriz simétrica
        all_areas = set()
        for area, synergies in synergy_matrix.items():
            all_areas.add(area)
            all_areas.update(synergies.keys())
        
        # Completar matriz simétrica
        complete_matrix = {}
        for area in all_areas:
            complete_matrix[area] = {}
            for other_area in all_areas:
                if area == other_area:
                    complete_matrix[area][other_area] = 0.0  # Mesma área = sem complementaridade
                else:
                    # Buscar sinergia em ambas as direções
                    score1 = synergy_matrix.get(area, {}).get(other_area, 0.0)
                    score2 = synergy_matrix.get(other_area, {}).get(area, 0.0)
                    complete_matrix[area][other_area] = max(score1, score2)
        
        return complete_matrix
    
    async def analyze_partnership_similarity(
        self, 
        target_lawyer_data: Dict[str, Any],
        candidate_lawyer_data: Dict[str, Any],
        strategy: str = "hybrid"  # "complementarity", "depth", "hybrid"
    ) -> SimilarityResult:
        """
        🆕 FASE 2: Análise principal de similaridade para parcerias.
        
        Args:
            target_lawyer_data: Dados do advogado que busca parceria
            candidate_lawyer_data: Dados do candidato a parceiro
            strategy: Estratégia de busca ("complementarity", "depth", "hybrid")
            
        Returns:
            SimilarityResult com análise completa da sinergia
        """
        
        target_id = target_lawyer_data.get("id", "unknown")
        candidate_id = candidate_lawyer_data.get("id", "unknown")
        
        # Extrair áreas de expertise
        target_areas = set(target_lawyer_data.get("expertise_areas", []))
        candidate_areas = set(candidate_lawyer_data.get("expertise_areas", []))
        
        self.logger.debug(f"🔍 Analisando similaridade: {target_id} vs {candidate_id}")
        self.logger.debug(f"   Target areas: {target_areas}")
        self.logger.debug(f"   Candidate areas: {candidate_areas}")
        
        # Análise de complementaridade
        complementarity_score, complementary_areas = self._calculate_complementarity(
            target_areas, candidate_areas
        )
        
        # Análise de profundidade (áreas compartilhadas)
        depth_score, shared_areas = await self._calculate_depth_similarity(
            target_lawyer_data, candidate_lawyer_data, target_areas & candidate_areas
        )
        
        # Score de sinergia combinado baseado na estratégia
        synergy_score, synergy_reason, strategy_used = self._calculate_synergy_score(
            complementarity_score, depth_score, strategy,
            len(complementary_areas), len(shared_areas)
        )
        
        # Confiança baseada na quantidade de dados disponíveis
        confidence = self._calculate_confidence(
            target_areas, candidate_areas, target_lawyer_data, candidate_lawyer_data
        )
        
        result = SimilarityResult(
            target_lawyer_id=target_id,
            candidate_lawyer_id=candidate_id,
            complementarity_score=complementarity_score,
            depth_score=depth_score,
            synergy_score=synergy_score,
            complementary_areas=list(complementary_areas),
            shared_areas=list(shared_areas),
            synergy_reason=synergy_reason,
            strategy_used=strategy_used,
            confidence=confidence
        )
        
        self.logger.info(f"✅ Similaridade calculada - Score: {synergy_score:.3f} ({strategy_used})")
        
        return result
    
    def _calculate_complementarity(
        self, 
        target_areas: Set[str], 
        candidate_areas: Set[str]
    ) -> Tuple[float, List[str]]:
        """
        Calcula score de complementaridade entre expertise areas.
        
        Returns:
            Tuple com (score, list of complementary areas)
        """
        
        if not target_areas or not candidate_areas:
            return 0.0, []
        
        complementary_areas = []
        total_synergy = 0.0
        total_combinations = 0
        
        # Verificar sinergia entre cada par de áreas
        for target_area in target_areas:
            for candidate_area in candidate_areas:
                if target_area != candidate_area:  # Só áreas diferentes
                    synergy = self.synergy_matrix.get(target_area, {}).get(candidate_area, 0.0)
                    if synergy > 0.5:  # Threshold para sinergia significativa
                        complementary_areas.append(candidate_area)
                        total_synergy += synergy
                        total_combinations += 1
        
        # Remover duplicatas
        complementary_areas = list(set(complementary_areas))
        
        # Calcular score médio de complementaridade
        if total_combinations > 0:
            avg_synergy = total_synergy / total_combinations
            
            # Bonus por diversidade de áreas complementares
            diversity_bonus = min(0.2, len(complementary_areas) * 0.05)
            
            complementarity_score = min(1.0, avg_synergy + diversity_bonus)
        else:
            complementarity_score = 0.0
        
        return complementarity_score, complementary_areas
    
    async def _calculate_depth_similarity(
        self,
        target_lawyer_data: Dict[str, Any],
        candidate_lawyer_data: Dict[str, Any], 
        shared_areas: Set[str]
    ) -> Tuple[float, List[str]]:
        """
        Calcula similaridade por profundidade nas áreas compartilhadas.
        
        Adapta a lógica de case_similarity do algoritmo_match.py para 
        comparar experiência em áreas específicas.
        """
        
        if not shared_areas:
            return 0.0, []
        
        # Filtrar apenas áreas de alta complexidade que se beneficiam de profundidade
        complex_shared_areas = [area for area in shared_areas if area in self.complex_areas]
        
        if not complex_shared_areas:
            return 0.0, []
        
        total_depth_score = 0.0
        
        # Para cada área compartilhada complexa, calcular similaridade de experiência
        for area in complex_shared_areas:
            area_depth_score = await self._calculate_area_depth_score(
                target_lawyer_data, candidate_lawyer_data, area
            )
            total_depth_score += area_depth_score
        
        # Score médio de profundidade
        avg_depth_score = total_depth_score / len(complex_shared_areas)
        
        # Bonus por múltiplas áreas de profundidade compartilhada
        multi_area_bonus = min(0.15, (len(complex_shared_areas) - 1) * 0.05)
        
        final_depth_score = min(1.0, avg_depth_score + multi_area_bonus)
        
        return final_depth_score, complex_shared_areas
    
    async def _calculate_area_depth_score(
        self,
        target_lawyer_data: Dict[str, Any],
        candidate_lawyer_data: Dict[str, Any],
        area: str
    ) -> float:
        """
        Calcula score de profundidade para uma área específica.
        
        Baseado na lógica de case_similarity mas adaptado para comparar
        experiência e expertise entre advogados.
        """
        
        # Fatores de profundidade em uma área
        target_experience = self._extract_area_experience(target_lawyer_data, area)
        candidate_experience = self._extract_area_experience(candidate_lawyer_data, area)
        
        # Similaridade de experiência (anos, casos, complexidade)
        experience_similarity = self._calculate_experience_similarity(
            target_experience, candidate_experience
        )
        
        # Se ambos têm experiência sólida na área, é bom para colaboração
        min_experience_threshold = 0.6
        if (target_experience.get("experience_score", 0) >= min_experience_threshold and 
            candidate_experience.get("experience_score", 0) >= min_experience_threshold):
            collaboration_bonus = 0.2
        else:
            collaboration_bonus = 0.0
        
        area_depth_score = min(1.0, experience_similarity + collaboration_bonus)
        
        return area_depth_score
    
    def _extract_area_experience(self, lawyer_data: Dict[str, Any], area: str) -> Dict[str, float]:
        """Extrai métricas de experiência do advogado em uma área específica."""
        
        # Experiência geral (fallback se não há dados específicos da área)
        general_experience = lawyer_data.get("anos_experiencia", 0)
        cases_30d = lawyer_data.get("cases_30d", 0)
        success_rate = lawyer_data.get("success_rate", 0.5)
        
        # Score normalizado de experiência (0-1)
        experience_years_score = min(1.0, general_experience / 10.0)  # 10 anos = experiência máxima
        cases_volume_score = min(1.0, cases_30d / 20.0)  # 20 casos = volume alto
        
        # Score combinado de experiência na área
        experience_score = (
            experience_years_score * 0.4 +
            cases_volume_score * 0.3 +
            success_rate * 0.3
        )
        
        return {
            "experience_score": experience_score,
            "years": general_experience,
            "cases_volume": cases_30d,
            "success_rate": success_rate
        }
    
    def _calculate_experience_similarity(
        self, 
        target_exp: Dict[str, float], 
        candidate_exp: Dict[str, float]
    ) -> float:
        """Calcula similaridade entre experiências de dois advogados."""
        
        # Diferença absoluta nos scores de experiência
        exp_diff = abs(target_exp["experience_score"] - candidate_exp["experience_score"])
        
        # Similaridade inversa (quanto menor a diferença, maior a similaridade)
        similarity = 1.0 - exp_diff
        
        # Bonus se ambos têm experiência alta (colaboração entre experientes)
        if (target_exp["experience_score"] > 0.7 and candidate_exp["experience_score"] > 0.7):
            similarity += 0.15
        
        return min(1.0, similarity)
    
    def _calculate_synergy_score(
        self,
        complementarity_score: float,
        depth_score: float,
        strategy: str,
        num_complementary: int,
        num_shared: int
    ) -> Tuple[float, str, str]:
        """
        Calcula score final de sinergia baseado na estratégia escolhida.
        
        Returns:
            Tuple com (score, reason, strategy_used)
        """
        
        if strategy == "complementarity":
            # Foco total em complementaridade
            synergy_score = complementarity_score
            reason = self._generate_complementarity_reason(complementarity_score, num_complementary)
            strategy_used = "complementarity"
            
        elif strategy == "depth":
            # Foco total em profundidade
            synergy_score = depth_score
            reason = self._generate_depth_reason(depth_score, num_shared)
            strategy_used = "depth"
            
        else:  # hybrid
            # Estratégia híbrida - escolher a melhor abordagem
            if complementarity_score > depth_score * 1.2:  # Complementaridade claramente melhor
                synergy_score = complementarity_score
                reason = self._generate_complementarity_reason(complementarity_score, num_complementary)
                strategy_used = "complementarity"
            elif depth_score > complementarity_score * 1.2:  # Profundidade claramente melhor
                synergy_score = depth_score
                reason = self._generate_depth_reason(depth_score, num_shared)
                strategy_used = "depth"
            else:  # Combinação balanceada
                synergy_score = (complementarity_score * 0.6 + depth_score * 0.4)
                reason = self._generate_hybrid_reason(complementarity_score, depth_score, num_complementary, num_shared)
                strategy_used = "hybrid"
        
        return synergy_score, reason, strategy_used
    
    def _generate_complementarity_reason(self, score: float, num_areas: int) -> str:
        """Gera explicação para estratégia de complementaridade."""
        
        if score >= 0.8:
            return f"Excelente complementaridade estratégica em {num_areas} áreas especializadas"
        elif score >= 0.6:
            return f"Boa sinergia complementar em {num_areas} áreas de expertise"
        elif score >= 0.4:
            return f"Complementaridade moderada em {num_areas} áreas"
        else:
            return "Baixa complementaridade de áreas de atuação"
    
    def _generate_depth_reason(self, score: float, num_areas: int) -> str:
        """Gera explicação para estratégia de profundidade."""
        
        if score >= 0.8:
            return f"Expertise profunda compartilhada em {num_areas} áreas complexas"
        elif score >= 0.6:
            return f"Boa experiência conjunta em {num_areas} áreas especializadas"
        elif score >= 0.4:
            return f"Experiência similar em {num_areas} áreas"
        else:
            return "Limitada experiência compartilhada"
    
    def _generate_hybrid_reason(self, comp_score: float, depth_score: float, num_comp: int, num_shared: int) -> str:
        """Gera explicação para estratégia híbrida."""
        
        return f"Sinergia balanceada: complementaridade em {num_comp} áreas ({comp_score:.0%}) e experiência compartilhada em {num_shared} áreas ({depth_score:.0%})"
    
    def _calculate_confidence(
        self,
        target_areas: Set[str],
        candidate_areas: Set[str], 
        target_data: Dict[str, Any],
        candidate_data: Dict[str, Any]
    ) -> float:
        """Calcula confiança na análise baseada na qualidade dos dados."""
        
        confidence_factors = []
        
        # Fator 1: Quantidade de áreas de expertise
        areas_factor = min(1.0, (len(target_areas) + len(candidate_areas)) / 6.0)
        confidence_factors.append(areas_factor)
        
        # Fator 2: Dados de experiência disponíveis
        target_exp_completeness = self._calculate_data_completeness(target_data)
        candidate_exp_completeness = self._calculate_data_completeness(candidate_data)
        data_factor = (target_exp_completeness + candidate_exp_completeness) / 2.0
        confidence_factors.append(data_factor)
        
        # Fator 3: Presença na matriz de sinergia
        known_areas_target = len([area for area in target_areas if area in self.synergy_matrix])
        known_areas_candidate = len([area for area in candidate_areas if area in self.synergy_matrix])
        total_areas = len(target_areas) + len(candidate_areas)
        
        if total_areas > 0:
            synergy_coverage = (known_areas_target + known_areas_candidate) / total_areas
        else:
            synergy_coverage = 0.0
        
        confidence_factors.append(synergy_coverage)
        
        # Confiança média
        overall_confidence = sum(confidence_factors) / len(confidence_factors)
        
        return overall_confidence
    
    def _calculate_data_completeness(self, lawyer_data: Dict[str, Any]) -> float:
        """Calcula completude dos dados de um advogado."""
        
        required_fields = ["anos_experiencia", "cases_30d", "success_rate", "rating"]
        available_fields = sum(1 for field in required_fields if field in lawyer_data)
        
        return available_fields / len(required_fields)
    
    # 🆕 Método de conveniência para integração com PartnershipRecommendationService
    async def enhance_partnership_recommendation(
        self,
        target_lawyer_data: Dict[str, Any],
        candidate_data: Dict[str, Any],
        strategy: str = "hybrid"
    ) -> Dict[str, Any]:
        """
        Método de conveniência para enriquecer recomendações de parceria
        com análise de similaridade avançada.
        
        Returns:
            Dict com scores e insights para uso no PartnershipRecommendationService
        """
        
        similarity_result = await self.analyze_partnership_similarity(
            target_lawyer_data, candidate_data, strategy
        )
        
        return {
            "similarity_score": similarity_result.synergy_score,
            "similarity_breakdown": {
                "complementarity": similarity_result.complementarity_score,
                "depth": similarity_result.depth_score,
                "strategy_used": similarity_result.strategy_used,
                "confidence": similarity_result.confidence
            },
            "similarity_reason": similarity_result.synergy_reason,
            "complementary_areas": similarity_result.complementary_areas,
            "shared_areas": similarity_result.shared_areas
        } 