"""
Testes para o RedisService
"""
import pytest
import asyncio
from unittest.mock import Mock, MagicMock, patch, AsyncMock
from backend.services.redis_service import RedisService


@pytest.fixture
def redis_service():
    """Fixture para criar uma instância do RedisService"""
    service = RedisService()
    return service


@pytest.fixture
def mock_redis():
    """Fixture para mock do cliente Redis"""
    mock = MagicMock()
    mock.get = Mock(return_value=None)
    mock.set = Mock(return_value=True)
    mock.delete = Mock(return_value=1)
    mock.exists = Mock(return_value=0)
    mock.expire = Mock(return_value=True)
    mock.keys = Mock(return_value=[])
    mock.scan_iter = Mock(return_value=iter([]))
    mock.info = Mock(return_value={
        'redis_version': '6.2.0',
        'used_memory_human': '1M',
        'connected_clients': 1
    })
    mock.dbsize = Mock(return_value=10)
    mock.ping = Mock(return_value=True)
    return mock


def test_redis_service_init():
    """Testa inicialização do RedisService"""
    service = RedisService()
    assert service._pool is None
    assert service._redis is None
    assert service._connected is False


@pytest.mark.asyncio
async def test_connect_success(redis_service, mock_redis):
    """Testa conexão bem-sucedida"""
    with patch('redis.asyncio.from_url', return_value=mock_redis):
        await redis_service.connect()
        assert redis_service._connected is True
        assert redis_service._redis is not None
        mock_redis.ping.assert_called_once()


@pytest.mark.asyncio
async def test_connect_failure(redis_service):
    """Testa falha na conexão"""
    with patch('redis.asyncio.from_url', side_effect=Exception("Connection failed")):
        await redis_service.connect()
        assert redis_service._connected is False
        assert redis_service._redis is None


@pytest.mark.asyncio
async def test_disconnect(redis_service, mock_redis):
    """Testa desconexão"""
    redis_service._redis = mock_redis
    redis_service._connected = True
    
    await redis_service.disconnect()
    
    assert redis_service._connected is False
    assert redis_service._redis is None
    mock_redis.close.assert_called_once()


@pytest.mark.asyncio
async def test_get_existing_key(redis_service, mock_redis):
    """Testa get de chave existente"""
    mock_redis.get.return_value = b'{"value": "test"}'
    redis_service._redis = mock_redis
    redis_service._connected = True
    
    result = await redis_service.get("test_key")
    
    assert result == {"value": "test"}
    mock_redis.get.assert_called_once_with("test_key")


@pytest.mark.asyncio
async def test_get_non_existing_key(redis_service, mock_redis):
    """Testa get de chave não existente"""
    mock_redis.get.return_value = None
    redis_service._redis = mock_redis
    redis_service._connected = True
    
    result = await redis_service.get("non_existing")
    
    assert result is None


@pytest.mark.asyncio
async def test_set_value(redis_service, mock_redis):
    """Testa set de valor"""
    redis_service._redis = mock_redis
    redis_service._connected = True
    
    result = await redis_service.set("key", {"data": "value"}, ttl=60)
    
    assert result is True
    mock_redis.set.assert_called_once()
    call_args = mock_redis.set.call_args
    assert call_args[0][0] == "key"
    assert '"data": "value"' in call_args[0][1]
    assert call_args[1]["ex"] == 60


@pytest.mark.asyncio
async def test_delete_key(redis_service, mock_redis):
    """Testa delete de chave"""
    redis_service._redis = mock_redis
    redis_service._connected = True
    
    result = await redis_service.delete("key")
    
    assert result == 1
    mock_redis.delete.assert_called_once_with("key")


@pytest.mark.asyncio
async def test_exists_key(redis_service, mock_redis):
    """Testa verificação de existência de chave"""
    mock_redis.exists.return_value = 1
    redis_service._redis = mock_redis
    redis_service._connected = True
    
    result = await redis_service.exists("key")
    
    assert result is True
    mock_redis.exists.assert_called_once_with("key")


@pytest.mark.asyncio
async def test_expire_key(redis_service, mock_redis):
    """Testa expiração de chave"""
    redis_service._redis = mock_redis
    redis_service._connected = True
    
    result = await redis_service.expire("key", 300)
    
    assert result is True
    mock_redis.expire.assert_called_once_with("key", 300)


@pytest.mark.asyncio
async def test_keys_pattern(redis_service, mock_redis):
    """Testa busca de chaves por padrão"""
    mock_redis.keys.return_value = [b"key1", b"key2", b"key3"]
    redis_service._redis = mock_redis
    redis_service._connected = True
    
    result = await redis_service.keys("key*")
    
    assert result == ["key1", "key2", "key3"]
    mock_redis.keys.assert_called_once_with("key*")


@pytest.mark.asyncio
async def test_scan_iter(redis_service, mock_redis):
    """Testa scan_iter"""
    mock_redis.scan_iter.return_value = iter([b"key1", b"key2"])
    redis_service._redis = mock_redis
    redis_service._connected = True
    
    result = []
    async for key in redis_service.scan_iter("pattern*"):
        result.append(key)
    
    assert result == ["key1", "key2"]
    mock_redis.scan_iter.assert_called_once_with(match="pattern*")


@pytest.mark.asyncio
async def test_get_info(redis_service, mock_redis):
    """Testa obtenção de informações do Redis"""
    redis_service._redis = mock_redis
    redis_service._connected = True
    
    result = await redis_service.get_info()
    
    assert result["redis_version"] == "6.2.0"
    assert result["connected"] is True
    mock_redis.info.assert_called_once()


@pytest.mark.asyncio
async def test_is_connected(redis_service):
    """Testa verificação de conexão"""
    assert redis_service.is_connected() is False
    
    redis_service._connected = True
    assert redis_service.is_connected() is True


@pytest.mark.asyncio
async def test_publish(redis_service, mock_redis):
    """Testa publicação em canal"""
    redis_service._redis = mock_redis
    redis_service._connected = True
    
    await redis_service.publish("channel", {"message": "test"})
    
    mock_redis.publish.assert_called_once()
    call_args = mock_redis.publish.call_args
    assert call_args[0][0] == "channel"
    assert '"message": "test"' in call_args[0][1]


@pytest.mark.asyncio
async def test_subscribe(redis_service, mock_redis):
    """Testa inscrição em canal"""
    # Mock do pubsub
    mock_pubsub = MagicMock()
    mock_pubsub.subscribe = AsyncMock()
    mock_pubsub.get_message = AsyncMock(side_effect=[
        {"type": "subscribe"},  # Mensagem de confirmação
        {"type": "message", "data": b'{"event": "test"}'},  # Mensagem real
        None  # Fim
    ])
    mock_redis.pubsub.return_value = mock_pubsub
    
    redis_service._redis = mock_redis
    redis_service._connected = True
    
    messages = []
    async for msg in redis_service.subscribe("channel"):
        messages.append(msg)
        if len(messages) >= 1:  # Para após 1 mensagem
            break
    
    assert len(messages) == 1
    assert messages[0]["event"] == "test"


@pytest.mark.asyncio
async def test_operation_without_connection(redis_service):
    """Testa operações sem conexão"""
    result = await redis_service.get("key")
    assert result is None
    
    result = await redis_service.set("key", "value")
    assert result is False
    
    result = await redis_service.delete("key")
    assert result == 0
    
    result = await redis_service.exists("key")
    assert result is False


@pytest.mark.asyncio
async def test_json_decode_error(redis_service, mock_redis):
    """Testa erro de decodificação JSON"""
    mock_redis.get.return_value = b'invalid json'
    redis_service._redis = mock_redis
    redis_service._connected = True
    
    result = await redis_service.get("key")
    assert result is None


@pytest.mark.asyncio
async def test_connection_retry(redis_service):
    """Testa retry de conexão"""
    call_count = 0
    
    def mock_from_url(*args, **kwargs):
        nonlocal call_count
        call_count += 1
        if call_count < 3:
            raise Exception("Connection failed")
        return Mock(ping=AsyncMock())
    
    with patch('redis.asyncio.from_url', side_effect=mock_from_url):
        with patch('asyncio.sleep', new_callable=AsyncMock):
            await redis_service.connect()
            
    assert call_count == 3
    assert redis_service._connected is True 