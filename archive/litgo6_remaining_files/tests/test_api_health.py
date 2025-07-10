import pytest
from fastapi import status
from unittest.mock import AsyncMock, patch

# As fixtures 'client' e 'app_with_mocks' são carregadas automaticamente do conftest.py

def test_health_check_root(client):
    """
    Testa o endpoint raiz '/' para verificar se a API está online.
    """
    response = client.get("/")
    assert response.status_code == status.HTTP_200_OK
    assert response.json()["status"] == "ok"

def test_health_check_redis_healthy(client):
    """
    Testa o endpoint de health check do Redis com status 'healthy'.
    O override da dependência no conftest já mocka o serviço para retornar 'healthy'.
    """
    response = client.get("/api/health/redis")
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["status"] == "healthy"

@patch('backend.services.redis_service.RedisService.health_check', new_callable=AsyncMock)
def test_health_check_redis_unhealthy(mock_health_check, client):
    """
    Testa o endpoint de health check do Redis com status 'unhealthy'.
    """
    # Para este teste específico, damos patch no método da classe para simular a falha.
    mock_health_check.return_value = {"status": "unhealthy", "error": "Connection failed"}
    
    response = client.get("/api/health/redis")
    
    assert response.status_code == status.HTTP_503_SERVICE_UNAVAILABLE
    # O detalhe da exceção estará no corpo da resposta
    data = response.json()
    assert data["detail"]["status"] == "unhealthy"
    assert "error" in data["detail"]

def test_metrics_endpoint(client):
    """
    Testa o endpoint de métricas do Prometheus.
    """
    response = client.get("/metrics")
    assert response.status_code == status.HTTP_200_OK
    assert 'http_requests_total' in response.text
