#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Unified Cache Service
====================

🆕 FASE 3: Unificação da Estrutura de Dados e Cache

Este serviço centraliza o cache de features entre o algoritmo_match.py e o 
PartnershipRecommendationService, eliminando recálculos desnecessários e 
garantindo consistência total entre os sistemas.

Funcionalidades:
1. Cache centralizado de features Q, M, I, C, E do FeatureCalculator
2. Cache de similarity scores e breakdowns
3. Cache de quality scores para parcerias
4. Invalidação inteligente baseada em atualizações de dados
5. Performance otimizada com TTLs diferenciados

Baseado na análise do UNIFIED_RECOMMENDATION_PLAN.md - Fase 3
"""

from __future__ import annotations

import asyncio
import json
import logging
import hashlib
from datetime import datetime, timedelta
from typing import Dict, Any, Optional, List, Tuple
from dataclasses import dataclass, asdict
import redis.asyncio as redis

# Import dos caches existentes para reutilização
try:
    from ..Algoritmo.algoritmo_match import RedisCache as AlgorithmCache
    ALGORITHM_CACHE_AVAILABLE = True
except ImportError:
    ALGORITHM_CACHE_AVAILABLE = False

try:
    from .redis_hybrid_cache import RedisHybridCache
    HYBRID_CACHE_AVAILABLE = True
except ImportError:
    HYBRID_CACHE_AVAILABLE = False

logger = logging.getLogger(__name__)


@dataclass
class CachedFeatures:
    """Estrutura unificada para features em cache."""
    
    # Campos obrigatórios
    lawyer_id: str
    cached_at: datetime
    
    # Features do FeatureCalculator (Q, M, I, C, E) - opcionais com padrão
    qualification_score: float = 0.0
    maturity_score: float = 0.0
    interaction_score: float = 0.0  # IEP
    soft_skill_score: float = 0.0
    firm_reputation_score: float = 0.0
    
    # 🆕 FASE 1: Features adicionais do algoritmo_match.py
    area_match_score: Optional[float] = None  # Feature A
    similarity_score: Optional[float] = None  # Feature S  
    success_rate_score: Optional[float] = None  # Feature T
    geo_score: Optional[float] = None  # Feature G
    urgency_score: Optional[float] = None  # Feature U
    review_score: Optional[float] = None  # Feature R
    price_fit_score: Optional[float] = None  # Feature P
    
    # Quality score agregado - opcional
    quality_score: float = 0.0
    quality_breakdown: Optional[Dict[str, float]] = None
    
    # Metadata - opcional
    source: str = "feature_calculator"
    ttl_seconds: int = 86400  # 24 horas - máxima performance com ciclo diário


@dataclass
class CachedSimilarity:
    """Estrutura para similarity scores em cache."""
    
    # Campos obrigatórios
    target_lawyer_id: str
    candidate_lawyer_id: str
    cached_at: datetime
    
    # Similarity scores - opcionais com padrão
    similarity_score: float = 0.0
    complementarity_score: float = 0.0
    depth_score: float = 0.0
    confidence: float = 0.0
    strategy_used: str = "unknown"
    
    # Breakdown detalhado - opcionais
    similarity_breakdown: Dict[str, Any] = None
    similarity_reason: str = ""
    complementary_areas: List[str] = None
    shared_areas: List[str] = None
    
    # Metadata - opcional
    source: str = "similarity_service"
    ttl_seconds: int = 86400  # 24 horas - máxima performance com ciclo diário
    
    def __post_init__(self):
        """Inicializar campos que são listas vazias."""
        if self.similarity_breakdown is None:
            self.similarity_breakdown = {}
        if self.complementary_areas is None:
            self.complementary_areas = []
        if self.shared_areas is None:
            self.shared_areas = []


class UnifiedCacheService:
    """
    🆕 FASE 3: Serviço de Cache Unificado
    
    Centraliza o cache de features entre algoritmo_match.py e 
    PartnershipRecommendationService para eliminar duplicação 
    e garantir consistência.
    """
    
    def __init__(self, redis_url: str = "redis://localhost:6379/0"):
        self.redis_url = redis_url
        self.redis_client: Optional[redis.Redis] = None
        self.is_connected = False
        
        # Prefixos para organização do cache
        self.prefixes = {
            'features': 'unified:features:',
            'similarity': 'unified:similarity:',
            'quality': 'unified:quality:',
            'metadata': 'unified:meta:'
        }
        
        # TTLs diferenciados - OTIMIZADOS para máxima performance
        self.ttl_config = {
            'features': 86400,      # 24 horas - máxima performance, alinhado com jobs diários
            'similarity': 86400,    # 24 horas - máxima performance, ciclo diário completo
            'quality': 86400,       # 24 horas - máxima performance, consistência total
            'metadata': 3600        # 1 hora - metadata de invalidação
        }
        
        # Cache híbrido e de algoritmo (se disponíveis)
        self.algorithm_cache = None
        self.hybrid_cache = None
        
        self.logger = logging.getLogger(__name__)
    
    async def initialize(self):
        """Inicializa conexões com Redis e caches existentes."""
        
        try:
            # Conectar ao Redis
            self.redis_client = redis.from_url(
                self.redis_url, 
                socket_timeout=2, 
                decode_responses=True
            )
            
            # Testar conexão
            await self.redis_client.ping()
            self.is_connected = True
            
            self.logger.info("🆕 FASE 3: UnifiedCacheService conectado ao Redis")
            
            # Inicializar caches existentes se disponíveis
            if ALGORITHM_CACHE_AVAILABLE:
                self.algorithm_cache = AlgorithmCache(self.redis_url)
                self.logger.info("✅ AlgorithmCache integrado")
            
            if HYBRID_CACHE_AVAILABLE:
                self.hybrid_cache = RedisHybridCache()
                await self.hybrid_cache.connect()
                self.logger.info("✅ HybridCache integrado")
            
        except Exception as e:
            self.logger.warning(f"Erro ao conectar Redis: {e} - usando cache em memória")
            self.is_connected = False
            # Fallback para cache em memória
            self._memory_cache = {}
    
    async def close(self):
        """Fecha conexões."""
        
        if self.redis_client:
            await self.redis_client.close()
        
        if self.hybrid_cache:
            await self.hybrid_cache.close()
        
        if self.algorithm_cache:
            await self.algorithm_cache.close()
    
    # ========================================================================
    # FASE 3: Métodos para Cache de Features Unificado
    # ========================================================================
    
    async def get_cached_features(self, lawyer_id: str) -> Optional[CachedFeatures]:
        """
        🆕 FASE 3: Obtém features em cache do FeatureCalculator.
        
        Primeiro tenta o cache unificado, depois fallback para algorithm_cache.
        """
        
        # 1. Tentar cache unificado primeiro
        cache_key = f"{self.prefixes['features']}{lawyer_id}"
        
        try:
            if self.is_connected:
                cached_data = await self.redis_client.get(cache_key)
                if cached_data:
                    data = json.loads(cached_data)
                    return CachedFeatures(**data)
            else:
                # Fallback para cache em memória
                if cache_key in self._memory_cache:
                    return self._memory_cache[cache_key]
        except Exception as e:
            self.logger.warning(f"Erro ao acessar cache unificado: {e}")
        
        # 2. Fallback para algorithm_cache se disponível
        if self.algorithm_cache:
            try:
                features_dict = await self.algorithm_cache.get_static_feats(lawyer_id)
                if features_dict:
                    # Converter para formato unificado
                    cached_features = CachedFeatures(
                        lawyer_id=lawyer_id,
                        qualification_score=features_dict.get("Q", 0.0),
                        maturity_score=features_dict.get("M", 0.0),
                        interaction_score=features_dict.get("I", 0.0),
                        soft_skill_score=features_dict.get("C", 0.0),
                        firm_reputation_score=features_dict.get("E", 0.0),
                        cached_at=datetime.now(),
                        source="algorithm_cache"
                    )
                    
                    # Migrar para cache unificado
                    await self.set_cached_features(cached_features)
                    
                    return cached_features
            except Exception as e:
                self.logger.warning(f"Erro ao acessar algorithm_cache: {e}")
        
        return None
    
    async def set_cached_features(self, features: CachedFeatures):
        """
        🆕 FASE 3: Armazena features no cache unificado.
        
        Propaga para algorithm_cache para compatibilidade reversa.
        """
        
        cache_key = f"{self.prefixes['features']}{features.lawyer_id}"
        
        try:
            # Armazenar no cache unificado
            features.cached_at = datetime.now()
            features_data = asdict(features)
            
            # Converter datetime para string
            features_data['cached_at'] = features.cached_at.isoformat()
            
            if self.is_connected:
                await self.redis_client.set(
                    cache_key, 
                    json.dumps(features_data), 
                    ex=self.ttl_config['features']
                )
            else:
                # Fallback para cache em memória
                self._memory_cache[cache_key] = features
            
            # Propagar para algorithm_cache (compatibilidade)
            if self.algorithm_cache:
                algorithm_features = {
                    "Q": features.qualification_score,
                    "M": features.maturity_score,
                    "I": features.interaction_score,
                    "C": features.soft_skill_score,
                    "E": features.firm_reputation_score
                }
                await self.algorithm_cache.set_static_feats(features.lawyer_id, algorithm_features)
            
            self.logger.debug(f"✅ Features cached para {features.lawyer_id}")
            
        except Exception as e:
            self.logger.error(f"Erro ao armazenar features em cache: {e}")
    
    async def get_cached_quality_score(self, lawyer_id: str) -> Optional[Dict[str, Any]]:
        """
        🆕 FASE 3: Obtém quality score em cache para parcerias.
        """
        
        cache_key = f"{self.prefixes['quality']}{lawyer_id}"
        
        try:
            if self.is_connected:
                cached_data = await self.redis_client.get(cache_key)
                if cached_data:
                    return json.loads(cached_data)
            else:
                return self._memory_cache.get(cache_key)
        except Exception as e:
            self.logger.warning(f"Erro ao acessar quality score cache: {e}")
        
        return None
    
    async def set_cached_quality_score(
        self, 
        lawyer_id: str, 
        quality_result: Dict[str, Any]
    ):
        """
        🆕 FASE 3: Armazena quality score no cache.
        """
        
        cache_key = f"{self.prefixes['quality']}{lawyer_id}"
        
        try:
            # Adicionar timestamp
            quality_result['cached_at'] = datetime.now().isoformat()
            
            if self.is_connected:
                await self.redis_client.set(
                    cache_key, 
                    json.dumps(quality_result), 
                    ex=self.ttl_config['quality']
                )
            else:
                self._memory_cache[cache_key] = quality_result
            
            self.logger.debug(f"✅ Quality score cached para {lawyer_id}")
            
        except Exception as e:
            self.logger.error(f"Erro ao armazenar quality score: {e}")
    
    # ========================================================================
    # FASE 3: Métodos para Cache de Similarity
    # ========================================================================
    
    async def get_cached_similarity(
        self, 
        target_lawyer_id: str, 
        candidate_lawyer_id: str
    ) -> Optional[CachedSimilarity]:
        """
        🆕 FASE 3: Obtém similarity score em cache entre dois advogados.
        """
        
        # Gerar chave única para o par (ordem independente)
        pair_key = self._generate_similarity_key(target_lawyer_id, candidate_lawyer_id)
        cache_key = f"{self.prefixes['similarity']}{pair_key}"
        
        try:
            if self.is_connected:
                cached_data = await self.redis_client.get(cache_key)
                if cached_data:
                    data = json.loads(cached_data)
                    # Restaurar datetime
                    data['cached_at'] = datetime.fromisoformat(data['cached_at'])
                    return CachedSimilarity(**data)
            else:
                return self._memory_cache.get(cache_key)
        except Exception as e:
            self.logger.warning(f"Erro ao acessar similarity cache: {e}")
        
        return None
    
    async def set_cached_similarity(self, similarity: CachedSimilarity):
        """
        🆕 FASE 3: Armazena similarity score no cache.
        """
        
        pair_key = self._generate_similarity_key(
            similarity.target_lawyer_id, 
            similarity.candidate_lawyer_id
        )
        cache_key = f"{self.prefixes['similarity']}{pair_key}"
        
        try:
            similarity.cached_at = datetime.now()
            similarity_data = asdict(similarity)
            
            # Converter datetime para string
            similarity_data['cached_at'] = similarity.cached_at.isoformat()
            
            if self.is_connected:
                await self.redis_client.set(
                    cache_key, 
                    json.dumps(similarity_data), 
                    ex=self.ttl_config['similarity']
                )
            else:
                self._memory_cache[cache_key] = similarity
            
            self.logger.debug(f"✅ Similarity cached para {pair_key}")
            
        except Exception as e:
            self.logger.error(f"Erro ao armazenar similarity: {e}")
    
    def _generate_similarity_key(self, lawyer_id1: str, lawyer_id2: str) -> str:
        """Gera chave única para par de advogados (ordem independente)."""
        
        # Ordenar IDs para garantir consistência
        sorted_ids = sorted([lawyer_id1, lawyer_id2])
        pair_string = f"{sorted_ids[0]}:{sorted_ids[1]}"
        
        # Hash para reduzir tamanho da chave
        return hashlib.md5(pair_string.encode()).hexdigest()
    
    # ========================================================================
    # FASE 3: Métodos de Invalidação e Manutenção
    # ========================================================================
    
    async def invalidate_lawyer_cache(self, lawyer_id: str):
        """
        🆕 FASE 3: Invalida todo cache relacionado a um advogado.
        
        Útil quando dados do advogado são atualizados.
        """
        
        try:
            # Invalidar features
            features_key = f"{self.prefixes['features']}{lawyer_id}"
            quality_key = f"{self.prefixes['quality']}{lawyer_id}"
            
            if self.is_connected:
                await self.redis_client.delete(features_key, quality_key)
                
                # Invalidar similarity scores envolvendo esse advogado
                # TODO: Implementar scan para encontrar chaves de similarity
                
            else:
                # Invalidar cache em memória
                self._memory_cache.pop(features_key, None)
                self._memory_cache.pop(quality_key, None)
            
            # Invalidar também no algorithm_cache
            if self.algorithm_cache:
                # O algorithm_cache não tem método de invalidação,
                # mas podemos sobrescrever com TTL mínimo
                await self.algorithm_cache.set_static_feats(lawyer_id, {})
            
            self.logger.info(f"🗑️ Cache invalidado para advogado {lawyer_id}")
            
        except Exception as e:
            self.logger.error(f"Erro ao invalidar cache: {e}")
    
    async def get_cache_stats(self) -> Dict[str, Any]:
        """
        🆕 FASE 3: Obtém estatísticas do cache para monitoramento.
        """
        
        stats = {
            "is_connected": self.is_connected,
            "redis_url": self.redis_url,
            "cache_prefixes": list(self.prefixes.keys()),
            "ttl_config": self.ttl_config,
            "algorithm_cache_available": ALGORITHM_CACHE_AVAILABLE,
            "hybrid_cache_available": HYBRID_CACHE_AVAILABLE
        }
        
        if self.is_connected:
            try:
                # Contar chaves por prefixo
                for cache_type, prefix in self.prefixes.items():
                    keys = await self.redis_client.keys(f"{prefix}*")
                    stats[f"{cache_type}_keys_count"] = len(keys)
            except Exception as e:
                stats["error"] = str(e)
        
        return stats
    
    # ========================================================================
    # FASE 3: Métodos de Conveniência para Integração
    # ========================================================================
    
    async def get_or_calculate_features(
        self, 
        lawyer_id: str, 
        calculator_func: callable
    ) -> CachedFeatures:
        """
        🆕 FASE 3: Obtém features do cache ou calcula se necessário.
        
        Padrão cache-aside para integração com PartnershipRecommendationService.
        """
        
        # Tentar cache primeiro
        cached = await self.get_cached_features(lawyer_id)
        if cached:
            self.logger.debug(f"✅ Features from cache para {lawyer_id}")
            return cached
        
        # Cache miss - calcular features
        self.logger.debug(f"❌ Cache miss - calculando features para {lawyer_id}")
        
        try:
            # Chamar função de cálculo fornecida
            features_dict = await calculator_func()
            
            # Converter para formato unificado
            cached_features = CachedFeatures(
                lawyer_id=lawyer_id,
                qualification_score=features_dict.get("Q", 0.0),
                maturity_score=features_dict.get("M", 0.0),
                interaction_score=features_dict.get("I", 0.0),
                soft_skill_score=features_dict.get("C", 0.0),
                firm_reputation_score=features_dict.get("E", 0.0),
                cached_at=datetime.now(),
                source="calculated"
            )
            
            # Calcular quality score agregado
            cached_features.quality_score = (
                cached_features.qualification_score * 0.25 +
                cached_features.maturity_score * 0.25 +
                cached_features.interaction_score * 0.25 +
                cached_features.soft_skill_score * 0.15 +
                cached_features.firm_reputation_score * 0.10
            )
            
            cached_features.quality_breakdown = {
                "qualification": cached_features.qualification_score,
                "maturity": cached_features.maturity_score,
                "interaction": cached_features.interaction_score,
                "soft_skill": cached_features.soft_skill_score,
                "firm_reputation": cached_features.firm_reputation_score
            }
            
            # Armazenar no cache
            await self.set_cached_features(cached_features)
            
            return cached_features
            
        except Exception as e:
            self.logger.error(f"Erro ao calcular features para {lawyer_id}: {e}")
            # Retornar features padrão em caso de erro
            return CachedFeatures(
                lawyer_id=lawyer_id,
                cached_at=datetime.now(),
                source="error_fallback"
            )


# Instância global do cache unificado
unified_cache = UnifiedCacheService() 