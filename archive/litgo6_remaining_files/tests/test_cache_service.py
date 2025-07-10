"""
Testes para o SimpleCacheService
"""
import pytest
import asyncio
from unittest.mock import Mock, AsyncMock, patch
from backend.services.cache_service_simple import SimpleCacheService


@pytest.fixture
async def cache_service():
    """Fixture para criar uma instância do SimpleCacheService"""
    service = SimpleCacheService()
    # Mock do Redis
    service.redis = Mock()
    service.redis.get = Mock(return_value=None)
    service.redis.set = Mock(return_value=True)
    service.redis.delete = Mock(return_value=1)
    service.redis.exists = Mock(return_value=0)
    service.redis.expire = Mock(return_value=True)
    service.redis.info = Mock(return_value={
        'redis_version': '6.2.0',
        'used_memory_human': '1M',
        'connected_clients': 1
    })
    service.redis.dbsize = Mock(return_value=10)
    service._connected = True
    yield service


@pytest.mark.asyncio
async def test_get_cache_miss(cache_service):
    """Testa quando não há valor no cache"""
    result = await cache_service.get("test_key")
    assert result is None
    cache_service.redis.get.assert_called_once_with("test_key")


@pytest.mark.asyncio
async def test_get_cache_hit(cache_service):
    """Testa quando há valor no cache"""
    cache_service.redis.get.return_value = b'{"value": "test"}'
    result = await cache_service.get("test_key")
    assert result == {"value": "test"}
    cache_service.redis.get.assert_called_once_with("test_key")


@pytest.mark.asyncio
async def test_set_cache(cache_service):
    """Testa a inserção de valor no cache"""
    result = await cache_service.set("test_key", {"value": "test"}, ttl=300)
    assert result is True
    cache_service.redis.set.assert_called_once()
    # Verifica se o JSON foi serializado corretamente
    call_args = cache_service.redis.set.call_args
    assert call_args[0][0] == "test_key"
    assert b'"value"' in call_args[0][1]  # Verifica se foi serializado como JSON


@pytest.mark.asyncio
async def test_delete_cache(cache_service):
    """Testa a remoção de valor do cache"""
    result = await cache_service.delete("test_key")
    assert result is True
    cache_service.redis.delete.assert_called_once_with("test_key")


@pytest.mark.asyncio
async def test_exists_cache(cache_service):
    """Testa a verificação de existência de chave"""
    # Quando não existe
    result = await cache_service.exists("test_key")
    assert result is False
    
    # Quando existe
    cache_service.redis.exists.return_value = 1
    result = await cache_service.exists("test_key")
    assert result is True


@pytest.mark.asyncio
async def test_expire_cache(cache_service):
    """Testa a definição de TTL em chave existente"""
    result = await cache_service.expire("test_key", 300)
    assert result is True
    cache_service.redis.expire.assert_called_once_with("test_key", 300)


@pytest.mark.asyncio
async def test_get_cache_stats(cache_service):
    """Testa a obtenção de estatísticas do cache"""
    stats = await cache_service.get_cache_stats()
    assert stats["connected"] is True
    assert stats["redis_version"] == "6.2.0"
    assert stats["used_memory"] == "1M"
    assert stats["total_keys"] == 10


@pytest.mark.asyncio
async def test_cache_with_ttl(cache_service):
    """Testa cache com TTL personalizado"""
    await cache_service.set("temp_key", {"temp": "data"}, ttl=60)
    call_args = cache_service.redis.set.call_args
    assert call_args[1]["ex"] == 60


@pytest.mark.asyncio
async def test_cache_without_connection(cache_service):
    """Testa comportamento quando não há conexão com Redis"""
    cache_service._connected = False
    
    # Get deve retornar None
    result = await cache_service.get("test_key")
    assert result is None
    
    # Set deve retornar False
    result = await cache_service.set("test_key", {"value": "test"})
    assert result is False
    
    # Delete deve retornar False
    result = await cache_service.delete("test_key")
    assert result is False


@pytest.mark.asyncio
async def test_delete_pattern(cache_service):
    """Testa a remoção de chaves por padrão"""
    # Mock do scan_iter
    cache_service.redis.scan_iter = Mock(return_value=iter(["key1", "key2", "key3"]))
    
    result = await cache_service.delete_pattern("test:*")
    assert result == 3
    cache_service.redis.delete.assert_called_with("key1", "key2", "key3")


@pytest.mark.asyncio
async def test_cache_error_handling(cache_service):
    """Testa tratamento de erros do Redis"""
    # Simula erro no Redis
    cache_service.redis.get.side_effect = Exception("Redis error")
    
    result = await cache_service.get("test_key")
    assert result is None  # Deve retornar None em caso de erro
    
    # Simula erro no set
    cache_service.redis.set.side_effect = Exception("Redis error")
    result = await cache_service.set("test_key", {"value": "test"})
    assert result is False  # Deve retornar False em caso de erro 