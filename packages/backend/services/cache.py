"""
Serviço de cache Redis para features estáticas do algoritmo de match v2.2.
Armazena features que mudam pouco (Q, T, G, R) para otimizar performance.
"""
import json
import logging
import os
from datetime import datetime, timedelta
from typing import Any, Dict, Optional

try:
    from redis.exceptions import RedisError

    import redis
except ImportError:
    print("Redis não instalado. Instale com: pip install redis")
    redis = None

# Configuração
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")
CACHE_PREFIX = "ltr_cache:"
DEFAULT_TTL = 3600  # 1 hora em segundos

logger = logging.getLogger(__name__)


class CacheService:
    """Serviço de cache para features estáticas do algoritmo."""

    def __init__(self):
        self.redis_client = None
        self._connect()

    def _connect(self):
        """Conecta ao Redis."""
        if not redis:
            logger.warning("Redis não disponível, usando cache em memória")
            self._memory_cache = {}
            return

        try:
            self.redis_client = redis.from_url(REDIS_URL)
            # Testar conexão
            self.redis_client.ping()
            logger.info("Conectado ao Redis com sucesso")
        except Exception as e:
            logger.warning(f"Erro conectando ao Redis: {e}. Usando cache em memória")
            self.redis_client = None
            self._memory_cache = {}

    def _get_key(self, lawyer_id: str) -> str:
        """Gera chave do cache para um advogado."""
        return f"{CACHE_PREFIX}lawyer:{lawyer_id}"

    async def get_static_feats(self, lawyer_id: str) -> Optional[Dict[str, float]]:
        """
        Recupera features estáticas do cache.
        """
        key = self._get_key(lawyer_id)

        try:
            if self.redis_client:
                # Cache Redis
                cached_data = self.redis_client.get(key)
                if cached_data:
                    data = json.loads(cached_data)
                    # Verificar se não expirou
                    if self._is_valid(data):
                        return data.get("features")
            else:
                # Cache em memória
                cached_data = self._memory_cache.get(key)
                if cached_data and self._is_valid(cached_data):
                    return cached_data.get("features")

        except Exception as e:
            logger.error(f"Erro recuperando cache para {lawyer_id}: {e}")

        return None

    async def set_static_feats(
            self, lawyer_id: str, features: Dict[str, float], ttl: int = DEFAULT_TTL):
        """
        Armazena features estáticas no cache.
        """
        key = self._get_key(lawyer_id)

        cache_data = {
            "features": features,
            "cached_at": datetime.now().isoformat(),
            "expires_at": (datetime.now() + timedelta(seconds=ttl)).isoformat()
        }

        try:
            if self.redis_client:
                # Cache Redis
                self.redis_client.setex(
                    key,
                    ttl,
                    json.dumps(cache_data)
                )
            else:
                # Cache em memória
                self._memory_cache[key] = cache_data

        except Exception as e:
            logger.error(f"Erro salvando cache para {lawyer_id}: {e}")

    async def invalidate_lawyer(self, lawyer_id: str):
        """
        Invalida cache de um advogado específico.
        """
        key = self._get_key(lawyer_id)

        try:
            if self.redis_client:
                self.redis_client.delete(key)
            else:
                self._memory_cache.pop(key, None)

            logger.info(f"Cache invalidado para advogado {lawyer_id}")

        except Exception as e:
            logger.error(f"Erro invalidando cache para {lawyer_id}: {e}")

    async def clear_all(self):
        """
        Limpa todo o cache.
        """
        try:
            if self.redis_client:
                keys = self.redis_client.keys(f"{CACHE_PREFIX}*")
                if keys:
                    self.redis_client.delete(*keys)
            else:
                self._memory_cache.clear()

            logger.info("Cache limpo completamente")

        except Exception as e:
            logger.error(f"Erro limpando cache: {e}")

    def _is_valid(self, cache_data: Dict) -> bool:
        """
        Verifica se dados do cache ainda são válidos.
        """
        try:
            expires_at = datetime.fromisoformat(cache_data["expires_at"])
            return datetime.now() < expires_at
        except (KeyError, ValueError):
            return False

    async def get_cache_stats(self) -> Dict[str, Any]:
        """
        Retorna estatísticas do cache.
        """
        stats = {
            "type": "redis" if self.redis_client else "memory",
            "connected": self.redis_client is not None
        }

        try:
            if self.redis_client:
                info = self.redis_client.info()
                keys_count = len(self.redis_client.keys(f"{CACHE_PREFIX}*"))
                stats.update({
                    "keys_count": keys_count,
                    "memory_usage": info.get("used_memory_human", "N/A"),
                    "hit_ratio": info.get("keyspace_hits", 0) / max(1, info.get("keyspace_hits", 0) + info.get("keyspace_misses", 0))
                })
            else:
                stats.update({
                    "keys_count": len(self._memory_cache),
                    "memory_usage": "N/A",
                    "hit_ratio": 0.0
                })

        except Exception as e:
            logger.error(f"Erro obtendo estatísticas do cache: {e}")
            stats["error"] = str(e)

        return stats


# Instância global do cache
cache_service = CacheService()

# Funções de conveniência para compatibilidade


async def get_static_feats(lawyer_id: str) -> Optional[Dict[str, float]]:
    """Função de conveniência para recuperar features estáticas."""
    return await cache_service.get_static_feats(lawyer_id)


async def set_static_feats(lawyer_id: str, features: Dict[str, float]):
    """Função de conveniência para armazenar features estáticas."""
    return await cache_service.set_static_feats(lawyer_id, features)


async def invalidate_lawyer_cache(lawyer_id: str):
    """Função de conveniência para invalidar cache de um advogado."""
    return await cache_service.invalidate_lawyer(lawyer_id)
