#!/usr/bin/env python3
"""
features/enriched_semantic.py

Strategy para Features de Similaridade Semântica Enriquecida que combina:
1. Embeddings tradicionais (CV puro)  
2. Embeddings enriquecidos (CV + KPIs + performance)
3. Peso adaptativo baseado na qualidade dos dados

Implementa a melhoria fundamental identificada: usar embeddings que "veem" 
tanto o conteúdo semântico quanto as métricas de performance.
"""
import logging
import asyncio
from typing import Dict, List, Any, Optional, Tuple
from .base import FeatureStrategy
from ..models.domain import Case, Lawyer
from ..utils.math_utils import cosine_similarity

logger = logging.getLogger(__name__)


class EnrichedSemanticFeatures(FeatureStrategy):
    """
    Strategy para features de similaridade semântica enriquecida.
    
    Combina:
    - Similaridade semântica tradicional (CV vs caso)
    - Similaridade semântica enriquecida (CV+KPIs vs caso)
    - Peso adaptativo baseado na qualidade dos dados
    - Contexto de performance para relevância
    """
    
    def __init__(self, case: Case, lawyer: Lawyer):
        super().__init__(case, lawyer)
        self.feature_prefix = "enriched_semantic"
        
        # Cache para embeddings para evitar recálculos
        self._case_embedding_cache = None
        self._lawyer_standard_embedding_cache = None
        self._lawyer_enriched_embedding_cache = None

    def get_feature_names(self) -> List[str]:
        """Retorna lista de features calculadas por esta strategy."""
        return [
            f"{self.feature_prefix}_similarity_standard",
            f"{self.feature_prefix}_similarity_enriched", 
            f"{self.feature_prefix}_similarity_weighted",
            f"{self.feature_prefix}_data_quality_score",
            f"{self.feature_prefix}_enrichment_boost",
            f"{self.feature_prefix}_performance_context"
        ]

    def calculate_features(self) -> Dict[str, float]:
        """
        Calcula features de similaridade semântica enriquecida. (implementação síncrona)
        Este método chama a implementação principal para compatibilidade.
        """
        return self.calculate() # Chama o método original

    def calculate(self) -> Dict[str, float]:
        """
        Calcula features de similaridade semântica enriquecida.
        
        Nota: Esta é a versão síncrona. Para embedding generation, 
        use calculate_features_async() que é mais robusta.
        """
        try:
            # Para versão síncrona, usar embeddings existentes se disponíveis
            features = {}
            
            # 1. Similaridade padrão (usando embeddings existentes)
            standard_similarity = self._calculate_standard_similarity()
            features[f"{self.feature_prefix}_similarity_standard"] = standard_similarity
            
            # 2. Verificar se temos embedding enriquecido
            enriched_similarity = self._calculate_enriched_similarity()
            features[f"{self.feature_prefix}_similarity_enriched"] = enriched_similarity
            
            # 3. Score de qualidade dos dados
            data_quality = self._calculate_data_quality_score()
            features[f"{self.feature_prefix}_data_quality_score"] = data_quality
            
            # 4. Boost de enriquecimento
            enrichment_boost = self._calculate_enrichment_boost(data_quality)
            features[f"{self.feature_prefix}_enrichment_boost"] = enrichment_boost
            
            # 5. Contexto de performance
            performance_context = self._calculate_performance_context()
            features[f"{self.feature_prefix}_performance_context"] = performance_context
            
            # 6. Similaridade ponderada final (combinação inteligente)
            weighted_similarity = self._calculate_weighted_similarity(
                standard_similarity, 
                enriched_similarity, 
                data_quality, 
                enrichment_boost
            )
            features[f"{self.feature_prefix}_similarity_weighted"] = weighted_similarity
            
            return features
            
        except Exception as e:
            logger.error(f"Erro ao calcular features semânticas enriquecidas: {e}")
            # Retornar features padrão em caso de erro
            return {name: 0.0 for name in self.get_feature_names()}

    async def calculate_features_async(self) -> Dict[str, float]:
        """
        Versão assíncrona que pode gerar embeddings se necessário.
        
        Esta é a versão recomendada que suporta:
        - Geração de embeddings em tempo real
        - Fallback inteligente para dados existentes
        - Cache para otimização de performance
        """
        try:
            features = {}
            
            # 1. Garantir que temos embedding do caso
            case_embedding = await self._get_or_generate_case_embedding()
            
            # 2. Similaridade padrão (CV tradicional)
            lawyer_standard_embedding = await self._get_or_generate_lawyer_standard_embedding()
            standard_similarity = 0.0
            if case_embedding and lawyer_standard_embedding:
                standard_similarity = cosine_similarity(case_embedding, lawyer_standard_embedding)
            features[f"{self.feature_prefix}_similarity_standard"] = standard_similarity
            
            # 3. Similaridade enriquecida (CV + KPIs)
            lawyer_enriched_embedding = await self._get_or_generate_lawyer_enriched_embedding()
            enriched_similarity = 0.0
            if case_embedding and lawyer_enriched_embedding:
                enriched_similarity = cosine_similarity(case_embedding, lawyer_enriched_embedding)
            features[f"{self.feature_prefix}_similarity_enriched"] = enriched_similarity
            
            # 4. Análise de qualidade e contexto
            data_quality = self._calculate_data_quality_score()
            features[f"{self.feature_prefix}_data_quality_score"] = data_quality
            
            enrichment_boost = self._calculate_enrichment_boost(data_quality)
            features[f"{self.feature_prefix}_enrichment_boost"] = enrichment_boost
            
            performance_context = self._calculate_performance_context()
            features[f"{self.feature_prefix}_performance_context"] = performance_context
            
            # 5. Similaridade ponderada inteligente
            weighted_similarity = self._calculate_weighted_similarity(
                standard_similarity, 
                enriched_similarity, 
                data_quality, 
                enrichment_boost
            )
            features[f"{self.feature_prefix}_similarity_weighted"] = weighted_similarity
            
            return features
            
        except Exception as e:
            logger.error(f"Erro ao calcular features semânticas enriquecidas (async): {e}")
            # Fallback para versão síncrona
            return self.calculate_features()

    def _calculate_standard_similarity(self) -> float:
        """Calcula similaridade semântica tradicional usando embeddings padrão."""
        try:
            # Verificar se temos embeddings V2 padrão
            if hasattr(self.lawyer, 'cv_embedding_v2') and self.lawyer.cv_embedding_v2:
                lawyer_embedding = self.lawyer.cv_embedding_v2
            elif hasattr(self.lawyer, 'cv_embedding') and self.lawyer.cv_embedding:
                lawyer_embedding = self.lawyer.cv_embedding
            else:
                return 0.0
            
            # Embedding do caso (assumindo que existe)
            if hasattr(self.case, 'embedding') and self.case.embedding:
                case_embedding = self.case.embedding
            else:
                return 0.0
            
            return cosine_similarity(case_embedding, lawyer_embedding)
            
        except Exception as e:
            logger.debug(f"Erro na similaridade padrão: {e}")
            return 0.0

    def _calculate_enriched_similarity(self) -> float:
        """Calcula similaridade usando embedding enriquecido se disponível."""
        try:
            # Verificar se o advogado tem embedding enriquecido
            if (hasattr(self.lawyer, 'cv_embedding_v2_enriched') and 
                self.lawyer.cv_embedding_v2_enriched and
                hasattr(self.lawyer, 'use_enriched_embeddings') and
                self.lawyer.use_enriched_embeddings):
                
                lawyer_enriched_embedding = self.lawyer.cv_embedding_v2_enriched
                
                # Embedding do caso
                if hasattr(self.case, 'embedding') and self.case.embedding:
                    case_embedding = self.case.embedding
                    return cosine_similarity(case_embedding, lawyer_enriched_embedding)
            
            return 0.0
            
        except Exception as e:
            logger.debug(f"Erro na similaridade enriquecida: {e}")
            return 0.0

    def _calculate_data_quality_score(self) -> float:
        """
        Calcula score de qualidade dos dados do advogado para embeddings enriquecidos.
        
        Score considera:
        - Riqueza dos KPIs (quantidade e qualidade)
        - Especialização definida
        - Tamanho e qualidade do CV
        - Dados de performance
        """
        score = 0.0
        max_score = 10.0
        
        # 1. Qualidade dos KPIs (0-3 pontos)
        if hasattr(self.lawyer, 'kpi') and self.lawyer.kpi:
            kpi_fields = len([k for k, v in self.lawyer.kpi.items() if v and v != 0])
            if kpi_fields >= 5:
                score += 3.0
            elif kpi_fields >= 3:
                score += 2.0
            elif kpi_fields >= 1:
                score += 1.0
        
        # 2. Especialização definida (0-2 pontos)
        if hasattr(self.lawyer, 'tags_expertise') and self.lawyer.tags_expertise:
            expertise_count = len(self.lawyer.tags_expertise)
            if expertise_count >= 3:
                score += 2.0
            elif expertise_count >= 1:
                score += 1.0
        
        # 3. Qualidade do CV (0-2 pontos)
        if hasattr(self.lawyer, 'cv_text') and self.lawyer.cv_text:
            cv_length = len(self.lawyer.cv_text)
            if cv_length >= 500:
                score += 2.0
            elif cv_length >= 100:
                score += 1.0
        
        # 4. Dados de performance (0-2 pontos)
        if hasattr(self.lawyer, 'total_cases') and self.lawyer.total_cases:
            if self.lawyer.total_cases >= 20:
                score += 2.0
            elif self.lawyer.total_cases >= 5:
                score += 1.0
        
        # 5. Publicações e qualificações (0-1 ponto)
        if hasattr(self.lawyer, 'publications') and self.lawyer.publications:
            if len(self.lawyer.publications) >= 3:
                score += 1.0
        
        return min(score / max_score, 1.0)

    def _calculate_enrichment_boost(self, data_quality: float) -> float:
        """
        Calcula boost adicional quando usando embeddings enriquecidos.
        
        Advogados com dados ricos devem se beneficiar mais dos embeddings enriquecidos.
        """
        base_boost = 0.1  # 10% boost base para embeddings enriquecidos
        quality_multiplier = data_quality * 0.2  # Até 20% adicional baseado na qualidade
        
        return base_boost + quality_multiplier

    def _calculate_performance_context(self) -> float:
        """
        Calcula contexto de performance que influencia a relevância semântica.
        
        Advogados com alta performance têm maior relevância mesmo com similaridade menor.
        """
        context_score = 0.0
        
        if hasattr(self.lawyer, 'kpi') and self.lawyer.kpi:
            # Taxa de sucesso
            success_rate = self.lawyer.kpi.get('taxa_sucesso', self.lawyer.kpi.get('success_rate', 0))
            if success_rate > 0.8:
                context_score += 0.3
            elif success_rate > 0.6:
                context_score += 0.1
            
            # Avaliação dos clientes
            rating = self.lawyer.kpi.get('avaliacao_media', self.lawyer.kpi.get('avg_rating', 0))
            if rating > 4.5:
                context_score += 0.2
            elif rating > 4.0:
                context_score += 0.1
            
            # Atividade recente
            recent_cases = self.lawyer.kpi.get('casos_30d', self.lawyer.kpi.get('cases_30d', 0))
            if recent_cases > 10:
                context_score += 0.1
        
        return min(context_score, 1.0)

    def _calculate_weighted_similarity(
        self, 
        standard_similarity: float,
        enriched_similarity: float, 
        data_quality: float,
        enrichment_boost: float
    ) -> float:
        """
        Calcula similaridade ponderada final combinando todas as informações.
        
        Lógica:
        - Se temos embedding enriquecido e qualidade boa, priorizar enriquecido
        - Se não, usar padrão com boost baseado em qualidade
        - Sempre considerar o contexto de performance
        """
        
        # Se temos embedding enriquecido e dados de qualidade
        if enriched_similarity > 0 and data_quality > 0.5:
            # Usar principalmente o embedding enriquecido
            primary_similarity = enriched_similarity
            
            # Aplicar boost de enriquecimento
            boosted_similarity = primary_similarity + (primary_similarity * enrichment_boost)
            
            # Combinar com padrão em proporção menor (10%)
            final_similarity = (0.9 * boosted_similarity) + (0.1 * standard_similarity)
            
        # Se temos embedding enriquecido mas dados de qualidade baixa
        elif enriched_similarity > 0:
            # Misturar os dois com peso mais equilibrado
            final_similarity = (0.6 * enriched_similarity) + (0.4 * standard_similarity)
            
        # Se só temos embedding padrão
        else:
            final_similarity = standard_similarity
            
            # Aplicar boost mínimo baseado na qualidade dos dados
            if data_quality > 0.7:
                final_similarity += (final_similarity * 0.05)  # 5% boost para dados de qualidade
        
        return min(final_similarity, 1.0)

    async def _get_or_generate_case_embedding(self) -> Optional[List[float]]:
        """Obtém ou gera embedding do caso."""
        if self._case_embedding_cache:
            return self._case_embedding_cache
        
        try:
            # Tentar usar embedding existente
            if hasattr(self.case, 'embedding') and self.case.embedding:
                self._case_embedding_cache = self.case.embedding
                return self._case_embedding_cache
            
            # Se não existe, gerar novo embedding do caso
            if hasattr(self.case, 'descricao') and self.case.descricao:
                from services.embedding_service_v2 import legal_embedding_service_v2
                
                embedding, _ = await legal_embedding_service_v2.generate_legal_embedding(
                    self.case.descricao, "case"
                )
                self._case_embedding_cache = embedding
                return embedding
            
            return None
            
        except Exception as e:
            logger.error(f"Erro ao obter embedding do caso: {e}")
            return None

    async def _get_or_generate_lawyer_standard_embedding(self) -> Optional[List[float]]:
        """Obtém ou gera embedding padrão do advogado."""
        if self._lawyer_standard_embedding_cache:
            return self._lawyer_standard_embedding_cache
        
        try:
            # Tentar usar embedding V2 existente
            if hasattr(self.lawyer, 'cv_embedding_v2') and self.lawyer.cv_embedding_v2:
                self._lawyer_standard_embedding_cache = self.lawyer.cv_embedding_v2
                return self._lawyer_standard_embedding_cache
            
            # Fallback para V1
            if hasattr(self.lawyer, 'cv_embedding') and self.lawyer.cv_embedding:
                self._lawyer_standard_embedding_cache = self.lawyer.cv_embedding
                return self._lawyer_standard_embedding_cache
            
            # Gerar novo se necessário
            if hasattr(self.lawyer, 'cv_text') and self.lawyer.cv_text:
                from services.embedding_service_v2 import legal_embedding_service_v2
                
                embedding, _ = await legal_embedding_service_v2.generate_legal_embedding(
                    self.lawyer.cv_text, "lawyer_cv"
                )
                self._lawyer_standard_embedding_cache = embedding
                return embedding
            
            return None
            
        except Exception as e:
            logger.error(f"Erro ao obter embedding padrão do advogado: {e}")
            return None

    async def _get_or_generate_lawyer_enriched_embedding(self) -> Optional[List[float]]:
        """Obtém ou gera embedding enriquecido do advogado."""
        if self._lawyer_enriched_embedding_cache:
            return self._lawyer_enriched_embedding_cache
        
        try:
            # Tentar usar embedding enriquecido existente
            if (hasattr(self.lawyer, 'cv_embedding_v2_enriched') and 
                self.lawyer.cv_embedding_v2_enriched and
                hasattr(self.lawyer, 'use_enriched_embeddings') and
                self.lawyer.use_enriched_embeddings):
                
                self._lawyer_enriched_embedding_cache = self.lawyer.cv_embedding_v2_enriched
                return self._lawyer_enriched_embedding_cache
            
            # Se não existe, gerar novo embedding enriquecido
            # (apenas se temos dados suficientes)
            data_quality = self._calculate_data_quality_score()
            if data_quality > 0.5:  # Só gerar se dados são bons o suficiente
                from services.enriched_embedding_service import LawyerProfile, enriched_embedding_service
                
                # Criar perfil do advogado
                profile = LawyerProfile(
                    id=getattr(self.lawyer, 'id', ''),
                    nome=getattr(self.lawyer, 'nome', ''),
                    cv_text=getattr(self.lawyer, 'cv_text', ''),
                    tags_expertise=getattr(self.lawyer, 'tags_expertise', []),
                    kpi=getattr(self.lawyer, 'kpi', {}),
                    kpi_subarea=getattr(self.lawyer, 'kpi_subarea', {}),
                    total_cases=getattr(self.lawyer, 'total_cases', 0),
                    publications=getattr(self.lawyer, 'publications', []),
                    education=getattr(self.lawyer, 'education', ''),
                    professional_experience=getattr(self.lawyer, 'professional_experience', ''),
                    city=getattr(self.lawyer, 'city', ''),
                    state=getattr(self.lawyer, 'state', ''),
                    interaction_score=getattr(self.lawyer, 'interaction_score', None)
                )
                
                # Gerar embedding enriquecido
                embedding, _, _ = await enriched_embedding_service.generate_enriched_embedding(
                    profile, "balanced"
                )
                
                self._lawyer_enriched_embedding_cache = embedding
                return embedding
            
            return None
            
        except Exception as e:
            logger.error(f"Erro ao obter embedding enriquecido do advogado: {e}")
            return None
 
 