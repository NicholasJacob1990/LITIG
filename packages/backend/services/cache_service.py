"""
Cache Service para o LITGO5
Implementa cache agressivo com Redis para melhorar performance e reduzir custos
"""
import asyncio
import hashlib
import json
import logging
import pickle
from datetime import timedelta
from functools import wraps
from typing import Any, Dict, List, Optional, Union

import aioredis
from aioredis import Redis

logger = logging.getLogger(__name__)


class CacheService:
    """
    Serviço centralizado de cache usando Redis.
    Reduz latência e custos com APIs externas.
    """

    def __init__(self, redis_url: str = "redis://localhost:6379"):
        self.redis_url = redis_url
        self._redis: Optional[Redis] = None

        # TTL padrão para diferentes tipos de dados (em segundos)
        self.ttl_config = {
            'lawyer_profile': 3600,        # 1 hora
            'lawyer_list': 1800,           # 30 minutos
            'jusbrasil_search': 86400,     # 24 horas
            'jusbrasil_process': 604800,   # 7 dias
            'ai_analysis': 604800,         # 7 dias
            'ai_triage': 86400,           # 24 horas
            'case_matches': 3600,          # 1 hora
            'api_response': 300,           # 5 minutos (genérico)
        }

    async def connect(self):
        """Conecta ao Redis de forma assíncrona"""
        if not self._redis:
            self._redis = await aioredis.from_url(
                self.redis_url,
                encoding="utf-8",
                decode_responses=False  # Vamos lidar com encoding manualmente
            )
            logger.info("Conectado ao Redis para cache")

    async def disconnect(self):
        """Desconecta do Redis"""
        if self._redis:
            await self._redis.close()
            self._redis = None

    @property
    async def redis(self) -> Redis:
        """Garante que estamos conectados ao Redis"""
        if not self._redis:
            await self.connect()
        return self._redis

    def _generate_key(self, prefix: str, *args, **kwargs) -> str:
        """
        Gera uma chave única para o cache baseada nos argumentos.
        Usa hash MD5 para keys muito longas.
        """
        # Combina todos os argumentos em uma string única
        key_parts = [str(arg) for arg in args]
        key_parts.extend([f"{k}:{v}" for k, v in sorted(kwargs.items())])
        key_data = ":".join(key_parts)

        # Se a chave for muito longa, usa hash
        if len(key_data) > 200:
            key_hash = hashlib.md5(key_data.encode()).hexdigest()
            return f"{prefix}:{key_hash}"

        return f"{prefix}:{key_data}"

    async def get(self, key: str) -> Optional[Any]:
        """Recupera um valor do cache"""
        try:
            redis = await self.redis
            value = await redis.get(key)

            if value is None:
                return None

            # Tenta decodificar como JSON primeiro
            try:
                return json.loads(value)
            except (json.JSONDecodeError, TypeError):
                # Se falhar, tenta pickle
                try:
                    return pickle.loads(value)
                except BaseException:
                    # Se ainda falhar, retorna como string
                    return value.decode('utf-8') if isinstance(value, bytes) else value

        except Exception as e:
            logger.error(f"Erro ao recuperar do cache: {e}")
            return None

    async def set(
        self,
        key: str,
        value: Any,
        ttl: Optional[int] = None,
        cache_type: Optional[str] = None
    ) -> bool:
        """
        Armazena um valor no cache.

        Args:
            key: Chave do cache
            value: Valor a ser armazenado
            ttl: Time to live em segundos (opcional)
            cache_type: Tipo de cache para usar TTL padrão
        """
        try:
            redis = await self.redis

            # Determina o TTL
            if ttl is None and cache_type:
                ttl = self.ttl_config.get(cache_type, 300)

            # Serializa o valor
            if isinstance(value, (dict, list)):
                serialized = json.dumps(value)
            elif isinstance(value, (str, int, float, bool)):
                serialized = json.dumps(value)
            else:
                # Para objetos complexos, usa pickle
                serialized = pickle.dumps(value)

            # Armazena no Redis
            if ttl:
                await redis.setex(key, ttl, serialized)
            else:
                await redis.set(key, serialized)

            return True

        except Exception as e:
            logger.error(f"Erro ao armazenar no cache: {e}")
            return False

    async def delete(self, key: str) -> bool:
        """Remove um valor do cache"""
        try:
            redis = await self.redis
            result = await redis.delete(key)
            return result > 0
        except Exception as e:
            logger.error(f"Erro ao deletar do cache: {e}")
            return False

    async def delete_pattern(self, pattern: str) -> int:
        """Remove todas as chaves que correspondem ao padrão"""
        try:
            redis = await self.redis
            keys = []
            async for key in redis.scan_iter(match=pattern):
                keys.append(key)

            if keys:
                return await redis.delete(*keys)
            return 0

        except Exception as e:
            logger.error(f"Erro ao deletar padrão do cache: {e}")
            return 0

    async def exists(self, key: str) -> bool:
        """Verifica se uma chave existe no cache"""
        try:
            redis = await self.redis
            return await redis.exists(key) > 0
        except Exception as e:
            logger.error(f"Erro ao verificar existência no cache: {e}")
            return False

    # Métodos específicos para cada tipo de dado

    async def get_lawyer_profile(self, lawyer_id: str) -> Optional[Dict]:
        """Recupera perfil de advogado do cache"""
        key = self._generate_key("lawyer_profile", lawyer_id)
        return await self.get(key)

    async def set_lawyer_profile(self, lawyer_id: str, profile: Dict) -> bool:
        """Armazena perfil de advogado no cache"""
        key = self._generate_key("lawyer_profile", lawyer_id)
        return await self.set(key, profile, cache_type='lawyer_profile')

    async def get_jusbrasil_search(self, cpf_cnpj: str) -> Optional[List[Dict]]:
        """Recupera resultado de busca Jusbrasil do cache"""
        key = self._generate_key("jusbrasil_search", cpf_cnpj)
        return await self.get(key)

    async def set_jusbrasil_search(self, cpf_cnpj: str, results: List[Dict]) -> bool:
        """Armazena resultado de busca Jusbrasil no cache"""
        key = self._generate_key("jusbrasil_search", cpf_cnpj)
        return await self.set(key, results, cache_type='jusbrasil_search')

    async def get_ai_analysis(self, text_hash: str) -> Optional[Dict]:
        """Recupera análise de IA do cache"""
        key = self._generate_key("ai_analysis", text_hash)
        return await self.get(key)

    async def set_ai_analysis(self, text: str, analysis: Dict) -> bool:
        """Armazena análise de IA no cache"""
        # Gera hash do texto para usar como chave
        text_hash = hashlib.md5(text.encode()).hexdigest()
        key = self._generate_key("ai_analysis", text_hash)
        return await self.set(key, analysis, cache_type='ai_analysis')

    async def get_case_matches(self, case_id: str,
                               filters: Optional[Dict] = None) -> Optional[List]:
        """Recupera matches de um caso do cache"""
        key = self._generate_key("case_matches", case_id, **(filters or {}))
        return await self.get(key)

    async def set_case_matches(self, case_id: str, matches: List,
                               filters: Optional[Dict] = None) -> bool:
        """Armazena matches de um caso no cache"""
        key = self._generate_key("case_matches", case_id, **(filters or {}))
        return await self.set(key, matches, cache_type='case_matches')

    async def invalidate_lawyer_cache(self, lawyer_id: str):
        """Invalida todo o cache relacionado a um advogado"""
        patterns = [
            f"lawyer_profile:{lawyer_id}*",
            f"case_matches:*{lawyer_id}*"
        ]

        total_deleted = 0
        for pattern in patterns:
            deleted = await self.delete_pattern(pattern)
            total_deleted += deleted

        logger.info(
            f"Invalidado {total_deleted} entradas de cache para advogado {lawyer_id}")
        return total_deleted

    async def get_cache_stats(self) -> Dict[str, Any]:
        """Retorna estatísticas do cache"""
        try:
            redis = await self.redis
            info = await redis.info()

            # Conta chaves por tipo
            type_counts = {}
            for cache_type in self.ttl_config.keys():
                pattern = f"{cache_type}:*"
                count = 0
                async for _ in redis.scan_iter(match=pattern):
                    count += 1
                type_counts[cache_type] = count

            return {
                'connected': True,
                'used_memory': info.get('used_memory_human', 'N/A'),
                'total_keys': await redis.dbsize(),
                'keys_by_type': type_counts,
                'hit_rate': self._calculate_hit_rate(info),
                'evicted_keys': info.get('evicted_keys', 0)
            }

        except Exception as e:
            logger.error(f"Erro ao obter estatísticas do cache: {e}")
            return {'connected': False, 'error': str(e)}

    def _calculate_hit_rate(self, info: Dict) -> float:
        """Calcula a taxa de hit do cache"""
        hits = info.get('keyspace_hits', 0)
        misses = info.get('keyspace_misses', 0)
        total = hits + misses

        if total == 0:
            return 0.0

        return round((hits / total) * 100, 2)


def cache_result(cache_type: str, ttl: Optional[int] = None):
    """
    Decorator para cachear resultados de funções assíncronas.

    Uso:
        @cache_result('lawyer_profile')
        async def get_lawyer_profile(lawyer_id: str):
            # código que busca o perfil
    """
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # Pula o 'self' se for método de classe
            cache_args = args[1:] if args and hasattr(args[0], '__class__') else args

            # Gera chave do cache
            cache_key = cache_service._generate_key(cache_type, *cache_args, **kwargs)

            # Tenta recuperar do cache
            cached = await cache_service.get(cache_key)
            if cached is not None:
                logger.debug(f"Cache hit para {func.__name__}: {cache_key}")
                return cached

            # Se não estiver no cache, executa a função
            logger.debug(f"Cache miss para {func.__name__}: {cache_key}")
            result = await func(*args, **kwargs)

            # Armazena no cache
            if result is not None:
                await cache_service.set(cache_key, result, ttl=ttl, cache_type=cache_type)

            return result

        return wrapper
    return decorator


# Instância global do serviço de cache
cache_service = CacheService()


# Função para inicializar o cache na aplicação
async def init_cache(redis_url: Optional[str] = None):
    """Inicializa o serviço de cache"""
    global cache_service

    if redis_url:
        cache_service = CacheService(redis_url)

    await cache_service.connect()
    logger.info("Serviço de cache inicializado")

    return cache_service


# Função para fechar o cache na aplicação
async def close_cache():
    """Fecha a conexão com o cache"""
    await cache_service.disconnect()
    logger.info("Serviço de cache fechado")
