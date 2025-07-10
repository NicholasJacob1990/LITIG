"""
Cache Service Simplificado para o LITGO5
Implementa cache com Redis usando a biblioteca redis padrão
"""
import asyncio
import hashlib
import json
import logging
from concurrent.futures import ThreadPoolExecutor
from typing import Any, Dict, List, Optional

import redis

logger = logging.getLogger(__name__)

# Executor para operações síncronas
executor = ThreadPoolExecutor(max_workers=5)


class SimpleCacheService:
    """
    Serviço simplificado de cache usando Redis.
    Usa redis síncrono com wrappers assíncronos para compatibilidade.
    """

    def __init__(self, redis_url: str = "redis://localhost:6379"):
        self.redis_url = redis_url
        self._redis = None

        # TTL padrão para diferentes tipos de dados (em segundos)
        self.ttl_config = {
            'lawyer_profile': 3600,        # 1 hora
            'lawyer_list': 1800,           # 30 minutos
            'jusbrasil_search': 86400,     # 24 horas
            'ai_analysis': 604800,         # 7 dias
            'case_matches': 3600,          # 1 hora
            'api_response': 300,           # 5 minutos (genérico)
        }

    def _get_redis(self):
        """Obtém conexão Redis (síncrona)"""
        if not self._redis:
            self._redis = redis.from_url(
                self.redis_url,
                encoding="utf-8",
                decode_responses=True
            )
        return self._redis

    async def connect(self):
        """Conecta ao Redis"""
        loop = asyncio.get_event_loop()

        def _connect():
            try:
                r = self._get_redis()
                r.ping()
                logger.info("Conectado ao Redis para cache")
                return True
            except Exception as e:
                logger.error(f"Erro ao conectar ao Redis: {e}")
                return False

        return await loop.run_in_executor(executor, _connect)

    async def disconnect(self):
        """Desconecta do Redis"""
        if self._redis:
            loop = asyncio.get_event_loop()
            await loop.run_in_executor(executor, self._redis.close)
            self._redis = None

    def _generate_key(self, prefix: str, *args, **kwargs) -> str:
        """Gera uma chave única para o cache"""
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
        loop = asyncio.get_event_loop()

        def _get():
            try:
                r = self._get_redis()
                value = r.get(key)

                if value is None:
                    return None

                # Tenta decodificar como JSON
                try:
                    return json.loads(value)
                except json.JSONDecodeError:
                    return value

            except Exception as e:
                logger.error(f"Erro ao recuperar do cache: {e}")
                return None

        return await loop.run_in_executor(executor, _get)

    async def set(
        self,
        key: str,
        value: Any,
        ttl: Optional[int] = None,
        cache_type: Optional[str] = None
    ) -> bool:
        """Armazena um valor no cache"""
        loop = asyncio.get_event_loop()

        def _set():
            try:
                r = self._get_redis()

                # Determina o TTL
                final_ttl = ttl
                if final_ttl is None and cache_type:
                    final_ttl = self.ttl_config.get(cache_type, 300)

                # Serializa o valor
                if isinstance(value, (dict, list)):
                    serialized = json.dumps(value)
                else:
                    serialized = str(value)

                # Armazena no Redis
                if final_ttl:
                    r.setex(key, final_ttl, serialized)
                else:
                    r.set(key, serialized)

                return True

            except Exception as e:
                logger.error(f"Erro ao armazenar no cache: {e}")
                return False

        return await loop.run_in_executor(executor, _set)

    async def delete(self, key: str) -> bool:
        """Remove um valor do cache"""
        loop = asyncio.get_event_loop()

        def _delete():
            try:
                r = self._get_redis()
                result = r.delete(key)
                return result > 0
            except Exception as e:
                logger.error(f"Erro ao deletar do cache: {e}")
                return False

        return await loop.run_in_executor(executor, _delete)

    async def delete_pattern(self, pattern: str) -> int:
        """Remove todas as chaves que correspondem ao padrão"""
        loop = asyncio.get_event_loop()

        def _delete_pattern():
            try:
                r = self._get_redis()
                keys = list(r.scan_iter(match=pattern))

                if keys:
                    return r.delete(*keys)
                return 0

            except Exception as e:
                logger.error(f"Erro ao deletar padrão do cache: {e}")
                return 0

        return await loop.run_in_executor(executor, _delete_pattern)

    async def get_cache_stats(self) -> Dict[str, Any]:
        """Retorna estatísticas do cache"""
        loop = asyncio.get_event_loop()

        def _get_stats():
            try:
                r = self._get_redis()
                info = r.info()

                return {
                    'connected': True,
                    'used_memory': info.get('used_memory_human', 'N/A'),
                    'total_keys': r.dbsize(),
                    'redis_version': info.get('redis_version', 'N/A')
                }

            except Exception as e:
                logger.error(f"Erro ao obter estatísticas do cache: {e}")
                return {'connected': False, 'error': str(e)}

        return await loop.run_in_executor(executor, _get_stats)

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


# Instância global do serviço de cache
simple_cache_service = SimpleCacheService()


# Função para inicializar o cache na aplicação
async def init_simple_cache(redis_url: Optional[str] = None):
    """Inicializa o serviço de cache"""
    global simple_cache_service

    if redis_url:
        simple_cache_service = SimpleCacheService(redis_url)

    await simple_cache_service.connect()
    logger.info("Serviço de cache simples inicializado")

    return simple_cache_service


# Função para fechar o cache na aplicação
async def close_simple_cache():
    """Fecha a conexão com o cache"""
    await simple_cache_service.disconnect()
    logger.info("Serviço de cache simples fechado")
