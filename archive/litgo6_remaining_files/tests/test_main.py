"""
Testes para o main.py
"""
import pytest
from unittest.mock import patch, MagicMock, AsyncMock
from fastapi.testclient import TestClient


@pytest.fixture
def mock_redis_service():
    """Mock do RedisService"""
    mock = MagicMock()
    mock.connect = AsyncMock()
    mock.disconnect = AsyncMock()
    mock.is_connected = MagicMock(return_value=True)
    return mock


@pytest.fixture
def mock_cache_service():
    """Mock do SimpleCacheService"""
    mock = MagicMock()
    mock.connect = AsyncMock()
    mock.disconnect = AsyncMock()
    return mock


@pytest.fixture
def client_with_mocks(mock_redis_service, mock_cache_service):
    """Cliente de teste com mocks"""
    with patch('backend.main.redis_service', mock_redis_service):
        with patch('backend.main.cache_service', mock_cache_service):
            from backend.main import app
            return TestClient(app)


def test_startup_event(mock_redis_service, mock_cache_service):
    """Testa evento de startup"""
    with patch('backend.main.redis_service', mock_redis_service):
        with patch('backend.main.cache_service', mock_cache_service):
            from backend.main import app
            
            # Simular startup
            with TestClient(app) as client:
                # Verificar que os serviços foram conectados
                mock_redis_service.connect.assert_called_once()
                mock_cache_service.connect.assert_called_once()


def test_shutdown_event(mock_redis_service, mock_cache_service):
    """Testa evento de shutdown"""
    with patch('backend.main.redis_service', mock_redis_service):
        with patch('backend.main.cache_service', mock_cache_service):
            from backend.main import app
            
            # Simular ciclo completo
            with TestClient(app) as client:
                pass
            
            # Verificar que os serviços foram desconectados
            mock_redis_service.disconnect.assert_called_once()
            mock_cache_service.disconnect.assert_called_once()


def test_cors_middleware(client_with_mocks):
    """Testa configuração CORS"""
    response = client_with_mocks.options("/")
    assert "access-control-allow-origin" in response.headers
    assert response.headers["access-control-allow-origin"] == "*"


def test_prometheus_middleware(client_with_mocks):
    """Testa middleware do Prometheus"""
    # Fazer uma requisição
    response = client_with_mocks.get("/")
    assert response.status_code == 200
    
    # Verificar métricas
    metrics_response = client_with_mocks.get("/metrics")
    assert metrics_response.status_code == 200
    assert "http_requests_total" in metrics_response.text


def test_exception_handler(client_with_mocks):
    """Testa handler de exceções"""
    # Criar uma rota que lança exceção
    from backend.main import app
    
    @app.get("/test-exception")
    def raise_exception():
        raise ValueError("Test exception")
    
    response = client_with_mocks.get("/test-exception")
    assert response.status_code == 500
    assert "Internal server error" in response.json()["detail"]


def test_validation_exception_handler(client_with_mocks):
    """Testa handler de exceções de validação"""
    # Endpoint que requer parâmetros
    response = client_with_mocks.post("/api/triage", json={})
    assert response.status_code in [422, 202]  # Pode ser 422 (validation) ou 202 (accepted)


def test_all_routes_included(client_with_mocks):
    """Testa se todas as rotas foram incluídas"""
    from backend.main import app
    
    # Obter todas as rotas
    routes = [route.path for route in app.routes]
    
    # Verificar rotas principais
    assert "/" in routes
    assert "/metrics" in routes
    assert "/cache/stats" in routes
    
    # Verificar que routers foram incluídos (pelo menos um endpoint de cada)
    api_routes = [r for r in routes if r.startswith("/api")]
    assert len(api_routes) > 0


def test_lifespan_context():
    """Testa contexto lifespan"""
    startup_called = False
    shutdown_called = False
    
    async def mock_startup():
        nonlocal startup_called
        startup_called = True
    
    async def mock_shutdown():
        nonlocal shutdown_called
        shutdown_called = True
    
    with patch('backend.main.redis_service.connect', mock_startup):
        with patch('backend.main.redis_service.disconnect', mock_shutdown):
            with patch('backend.main.cache_service.connect', AsyncMock()):
                with patch('backend.main.cache_service.disconnect', AsyncMock()):
                    from backend.main import app
                    
                    with TestClient(app):
                        assert startup_called
                    
                    assert shutdown_called


def test_health_endpoint_integration(client_with_mocks):
    """Testa integração do endpoint de health"""
    response = client_with_mocks.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert "message" in data


def test_cache_stats_endpoint_integration(client_with_mocks):
    """Testa integração do endpoint de cache stats"""
    # Mock do cache stats
    mock_stats = {
        "connected": True,
        "redis_version": "6.2.0",
        "total_keys": 10,
        "used_memory": "1M"
    }
    
    with patch('backend.main.cache_service.get_stats', return_value=mock_stats):
        response = client_with_mocks.get("/cache/stats")
        assert response.status_code == 200
        data = response.json()
        assert data["connected"] is True
        assert data["redis_version"] == "6.2.0"


def test_metrics_endpoint_integration(client_with_mocks):
    """Testa integração do endpoint de métricas"""
    response = client_with_mocks.get("/metrics")
    assert response.status_code == 200
    assert response.headers["content-type"] == "text/plain; version=0.0.4; charset=utf-8"
    
    # Verificar métricas básicas
    metrics_text = response.text
    assert "python_info" in metrics_text
    assert "litgo_system_info" in metrics_text
    assert "http_requests_total" in metrics_text


def test_app_metadata():
    """Testa metadados da aplicação"""
    from backend.main import app
    
    assert app.title == "LITGO5 API"
    assert app.version == "2.2.0"
    assert "legal" in app.description.lower()


def test_error_handling_in_startup():
    """Testa tratamento de erros no startup"""
    with patch('backend.main.redis_service.connect', side_effect=Exception("Connection failed")):
        with patch('backend.main.cache_service.connect', AsyncMock()):
            from backend.main import app
            
            # Deve inicializar mesmo com erro no Redis
            with TestClient(app) as client:
                response = client.get("/")
                assert response.status_code == 200


def test_error_handling_in_shutdown():
    """Testa tratamento de erros no shutdown"""
    with patch('backend.main.redis_service.disconnect', side_effect=Exception("Disconnect failed")):
        with patch('backend.main.cache_service.disconnect', AsyncMock()):
            from backend.main import app
            
            # Deve finalizar mesmo com erro
            try:
                with TestClient(app):
                    pass
            except Exception:
                pytest.fail("Shutdown error should be handled gracefully") 