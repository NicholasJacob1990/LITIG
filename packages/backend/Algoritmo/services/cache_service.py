# -*- coding: utf-8 -*-
"""
services/cache_service.py

Serviço de cache Redis para features estáticas e acadêmicas do sistema de matching.
"""

import json
import os
from typing import Dict, Optional, Any
import redis.asyncio as aioredis


class RedisCache:
    """Cache baseado em Redis assíncrono para features quase estáticas."""

    def __init__(self, redis_url: str):
        try:
            self._redis = aioredis.from_url(
                redis_url, socket_timeout=1, decode_responses=True)
        except Exception:  # Fallback para dev local sem Redis
            class _FakeRedis(dict):
                async def get(self, k): 
                    return super().get(k)
                async def set(self, k, v, ex=None): 
                    self[k] = v
                async def close(self): 
                    pass
            self._redis = _FakeRedis()
        self._prefix = 'match:cache'

    async def get_static_feats(self, lawyer_id: str, segmented_cache_enabled: bool = False) -> Optional[Dict[str, float]]:
        """Recupera features estáticas do cache."""
        # Cache segmentado por entidade se feature flag habilitada
        if segmented_cache_enabled:
            entity = 'firm' if str(lawyer_id).startswith('FIRM') else 'lawyer'
            cache_key = f"{self._prefix}:{entity}:{lawyer_id}"
        else:
            # Cache tradicional para compatibilidade
            cache_key = f"{self._prefix}:{lawyer_id}"
        
        raw = await self._redis.get(cache_key)
        if raw:
            return json.loads(raw)
        return None

    async def set_static_feats(self, lawyer_id: str, features: Dict[str, float], segmented_cache_enabled: bool = False):
        """Armazena features estáticas no cache."""
        # Cache segmentado por entidade se feature flag habilitada
        if segmented_cache_enabled:
            entity = 'firm' if str(lawyer_id).startswith('FIRM') else 'lawyer'
            cache_key = f"{self._prefix}:{entity}:{lawyer_id}"
        else:
            # Cache tradicional para compatibilidade
            cache_key = f"{self._prefix}:{lawyer_id}"
        
        # TTL configurável via ENV
        ttl = int(os.getenv("CACHE_TTL_SECONDS", "21600"))  # 6 horas padrão
        
        await self._redis.set(cache_key, json.dumps(features), ex=ttl)

    async def get_academic_score(self, key: str) -> Optional[float]:
        """Recupera score acadêmico do cache."""
        cache_key = f"{self._prefix}:acad:{key}"
        raw = await self._redis.get(cache_key)
        if raw:
            try:
                return float(raw)
            except (ValueError, TypeError):
                return None
        return None

    async def set_academic_score(self, key: str, score: float, *, ttl_h: int):
        """Armazena score acadêmico no cache com TTL em horas."""
        cache_key = f"{self._prefix}:acad:{key}"
        await self._redis.set(cache_key, str(score), ex=ttl_h * 3600)

    async def close(self) -> None:
        """Fecha a conexão com o Redis."""
        await self._redis.close()


def create_redis_cache(redis_url: str) -> RedisCache:
    """Factory function para criar instância do cache Redis."""
    return RedisCache(redis_url)
 
 