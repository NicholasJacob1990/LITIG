import asyncio
import json
import logging
import os
from datetime import datetime
from typing import Any, Dict, List, Optional

import redis.asyncio as redis

logger = logging.getLogger(__name__)

# Configurações do Redis
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")
REDIS_MAX_CONNECTIONS = int(os.getenv("REDIS_MAX_CONNECTIONS", "20"))
REDIS_RETRY_ON_TIMEOUT = os.getenv("REDIS_RETRY_ON_TIMEOUT", "True").lower() == "true"
REDIS_DECODE_RESPONSES = os.getenv("REDIS_DECODE_RESPONSES", "True").lower() == "true"


class RedisService:
    """Serviço centralizado para operações Redis usando a biblioteca 'redis'."""

    def __init__(self):
        self.redis_pool = None
        self._pool = None  # Para compatibilidade com testes
        self._redis = None
        self._connected = False

    async def initialize(self):
        """Inicializa o pool de conexões com Redis."""
        try:
            self.redis_pool = redis.ConnectionPool.from_url(
                REDIS_URL,
                max_connections=REDIS_MAX_CONNECTIONS,
            )
            self._pool = self.redis_pool
            # Testa a conexão
            r = self.get_redis()
            await r.ping()
            self._connected = True
            logger.info("Redis (redis-py) conectado com sucesso.")
        except Exception as e:
            logger.error(f"Erro ao conectar com Redis (redis-py): {e}")
            self.redis_pool = None
            self._pool = None
            self._connected = False
            raise

    async def connect(self):
        """Conecta ao Redis (compatibilidade com testes)."""
        max_retries = 3
        for attempt in range(max_retries):
            try:
                self._redis = redis.from_url(
                    REDIS_URL,
                    max_connections=REDIS_MAX_CONNECTIONS,
                    retry_on_timeout=REDIS_RETRY_ON_TIMEOUT,
                    decode_responses=REDIS_DECODE_RESPONSES
                )
                await self._redis.ping()
                self._connected = True
                logger.info("Redis conectado com sucesso.")
                return
            except Exception as e:
                logger.error(f"Tentativa {attempt + 1} falhou: {e}")
                if attempt < max_retries - 1:
                    await asyncio.sleep(1)
                else:
                    self._connected = False
                    self._redis = None

    async def disconnect(self):
        """Desconecta do Redis."""
        if self._redis:
            await self._redis.close()
        self._redis = None
        self._connected = False

    def is_connected(self) -> bool:
        """Verifica se está conectado."""
        return self._connected

    def get_redis(self) -> redis.Redis:
        """Obtém uma conexão Redis do pool."""
        if not self.redis_pool:
            logger.warning("RedisService.get_redis() chamado antes de initialize().")
            asyncio.run(self.initialize())

        return redis.Redis(
            connection_pool=self.redis_pool,
            retry_on_timeout=REDIS_RETRY_ON_TIMEOUT,
            decode_responses=REDIS_DECODE_RESPONSES
        )

    async def get(self, key: str) -> Optional[Any]:
        """Recupera um valor do Redis."""
        if not self._connected:
            return None

        try:
            if self._redis:
                data = await self._redis.get(key)
            else:
                r = self.get_redis()
                data = await r.get(key)

            if data:
                try:
                    return json.loads(data)
                except json.JSONDecodeError:
                    return data
            return None
        except Exception as e:
            logger.error(f"Erro ao recuperar {key}: {e}")
            return None

    async def set(self, key: str, value: Any, ttl: Optional[int] = None) -> bool:
        """Armazena um valor no Redis."""
        if not self._connected:
            return False

        try:
            if self._redis:
                r = self._redis
            else:
                r = self.get_redis()

            if isinstance(value, (dict, list)):
                serialized = json.dumps(value, ensure_ascii=False, default=str)
            else:
                serialized = str(value)

            if ttl:
                return await r.set(key, serialized, ex=ttl)
            else:
                return await r.set(key, serialized)
        except Exception as e:
            logger.error(f"Erro ao salvar {key}: {e}")
            return False

    async def delete(self, key: str) -> int:
        """Remove uma chave do Redis."""
        if not self._connected:
            return 0

        try:
            if self._redis:
                r = self._redis
            else:
                r = self.get_redis()
            return await r.delete(key)
        except Exception as e:
            logger.error(f"Erro ao deletar {key}: {e}")
            return 0

    async def exists(self, key: str) -> bool:
        """Verifica se uma chave existe."""
        if not self._connected:
            return False

        try:
            if self._redis:
                r = self._redis
            else:
                r = self.get_redis()
            return await r.exists(key) > 0
        except Exception as e:
            logger.error(f"Erro ao verificar {key}: {e}")
            return False

    async def expire(self, key: str, ttl: int) -> bool:
        """Define um TTL para uma chave existente."""
        if not self._connected:
            return False

        try:
            if self._redis:
                r = self._redis
            else:
                r = self.get_redis()
            return await r.expire(key, ttl)
        except Exception as e:
            logger.error(f"Erro ao definir TTL para {key}: {e}")
            return False

    async def keys(self, pattern: str) -> List[str]:
        """Busca chaves por um padrão."""
        if not self._connected:
            return []

        try:
            if self._redis:
                r = self._redis
            else:
                r = self.get_redis()
            keys = await r.keys(pattern)
            # Converter bytes para string se necessário
            return [key.decode() if isinstance(key, bytes) else key for key in keys]
        except Exception as e:
            logger.error(f"Erro ao buscar padrão {pattern}: {e}")
            return []

    async def scan_iter(self, pattern: str):
        """Itera sobre chaves que correspondem ao padrão."""
        if not self._connected:
            return

        try:
            if self._redis:
                r = self._redis
            else:
                r = self.get_redis()

            async for key in r.scan_iter(match=pattern):
                yield key.decode() if isinstance(key, bytes) else key
        except Exception as e:
            logger.error(f"Erro ao iterar padrão {pattern}: {e}")

    async def get_info(self) -> Dict[str, Any]:
        """Obtém informações do Redis."""
        if not self._connected:
            return {"connected": False}

        try:
            if self._redis:
                r = self._redis
            else:
                r = self.get_redis()
            info = await r.info()
            info["connected"] = True
            return info
        except Exception as e:
            logger.error(f"Erro ao obter info: {e}")
            return {"connected": False, "error": str(e)}

    async def publish(self, channel: str, message: Dict[str, Any]) -> bool:
        """Publica uma mensagem em um canal Redis."""
        if not self._connected:
            return False

        try:
            if self._redis:
                r = self._redis
            else:
                r = self.get_redis()
            serialized_message = json.dumps(message, default=str)
            await r.publish(channel, serialized_message)
            return True
        except Exception as e:
            logger.error(f"Erro ao publicar no canal {channel}: {e}")
            return False

    async def subscribe(self, channel: str):
        """Inscreve-se em um canal Redis e produz mensagens."""
        if not self._connected:
            return

        try:
            if self._redis:
                r = self._redis
            else:
                r = self.get_redis()
            pubsub = r.pubsub()
            await pubsub.subscribe(channel)

            logger.info(f"Inscrito no canal {channel}")

            while True:
                message = await pubsub.get_message(ignore_subscribe_messages=True, timeout=1.0)
                if message:
                    try:
                        data = json.loads(message['data'])
                        yield data
                    except (json.JSONDecodeError, TypeError):
                        yield message['data']
                await asyncio.sleep(0.01)

        except asyncio.CancelledError:
            logger.info(f"Inscrição no canal {channel} cancelada.")
        except Exception as e:
            logger.error(f"Erro na inscrição do canal {channel}: {e}")
        finally:
            if 'pubsub' in locals() and pubsub:
                await pubsub.unsubscribe(channel)
                await pubsub.close()
                logger.info(f"Inscrição no canal {channel} finalizada.")

    # Métodos legados para compatibilidade
    async def set_json(self, key: str, value: Any, ttl: Optional[int] = None) -> bool:
        """Armazena um objeto JSON no Redis."""
        return await self.set(key, value, ttl)

    async def get_json(self, key: str) -> Optional[Any]:
        """Recupera um objeto JSON do Redis."""
        return await self.get(key)

    async def get_keys_pattern(self, pattern: str) -> List[str]:
        """Busca chaves por um padrão."""
        return await self.keys(pattern)

    async def set_ttl(self, key: str, ttl: int) -> bool:
        """Define um TTL para uma chave existente."""
        return await self.expire(key, ttl)

    async def get_ttl(self, key: str) -> int:
        """Obtém o TTL de uma chave."""
        try:
            if self._redis:
                r = self._redis
            else:
                r = self.get_redis()
            return await r.ttl(key)
        except Exception as e:
            logger.error(f"Erro ao obter TTL de {key}: {e}")
            return -1

    async def increment_float(self, key: str, amount: float) -> float:
        """Incrementa um valor float."""
        try:
            if self._redis:
                r = self._redis
            else:
                r = self.get_redis()
            return await r.incrbyfloat(key, amount)
        except Exception as e:
            logger.error(f"Erro ao incrementar {key}: {e}")
            return 0.0

    async def get_float(self, key: str) -> Optional[float]:
        """Obtém um valor float."""
        try:
            if self._redis:
                r = self._redis
            else:
                r = self.get_redis()
            value = await r.get(key)
            return float(value) if value else None
        except Exception as e:
            logger.error(f"Erro ao obter float de {key}: {e}")
            return None

    async def list_append(self, key: str, value: Any) -> bool:
        """Adiciona um item a uma lista."""
        try:
            if self._redis:
                r = self._redis
            else:
                r = self.get_redis()
            serialized = json.dumps(value, ensure_ascii=False, default=str)
            await r.lpush(key, serialized)
            return True
        except Exception as e:
            logger.error(f"Erro ao adicionar à lista {key}: {e}")
            return False

    async def list_get_all(self, key: str) -> List[Any]:
        """Obtém todos os itens de uma lista."""
        try:
            if self._redis:
                r = self._redis
            else:
                r = self.get_redis()
            items = await r.lrange(key, 0, -1)
            return [json.loads(item) for item in items]
        except Exception as e:
            logger.error(f"Erro ao obter lista {key}: {e}")
            return []

    async def cleanup_expired(self, pattern: str) -> int:
        """Remove chaves expiradas que correspondem ao padrão."""
        try:
            if self._redis:
                r = self._redis
            else:
                r = self.get_redis()
            keys = await r.keys(pattern)
            cleaned_count = 0

            for key in keys:
                ttl = await r.ttl(key)
                if ttl == -2:  # Chave expirada
                    await r.delete(key)
                    cleaned_count += 1

            return cleaned_count
        except Exception as e:
            logger.error(f"Erro ao limpar chaves expiradas {pattern}: {e}")
            return 0

    async def health_check(self) -> Dict[str, Any]:
        """Verifica a saúde da conexão com o Redis."""
        if not self.redis_pool and not self._connected:
            return {"status": "unhealthy", "error": "Pool não inicializado"}

        try:
            if self._redis:
                r = self._redis
            else:
                r = self.get_redis()
            start_time = asyncio.get_event_loop().time()
            await r.ping()
            latency = (asyncio.get_event_loop().time() - start_time) * 1000
            info = await r.info()

            return {
                "status": "healthy",
                "latency_ms": round(latency, 2),
                "connected_clients": info.get("connected_clients", "N/A"),
                "used_memory": info.get("used_memory_human", "N/A"),
                "uptime_seconds": info.get("uptime_in_seconds", "N/A"),
            }
        except Exception as e:
            return {
                "status": "unhealthy",
                "error": str(e),
                "timestamp": datetime.now().isoformat(),
            }

    async def close(self):
        """Fecha o pool de conexões."""
        if self._redis:
            await self._redis.close()
        if self.redis_pool:
            r = self.get_redis()
            await r.close()
            await self.redis_pool.disconnect()
            self.redis_pool = None
            self._pool = None
        self._connected = False
        logger.info("Pool de conexões Redis fechado.")


# Instância global do serviço
redis_service = RedisService()
