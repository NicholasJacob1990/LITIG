"""
Testes básicos da API LITGO
"""
import pytest
from fastapi.testclient import TestClient

# A fixture 'client' é carregada automaticamente do conftest.py

def test_root_endpoint(client: TestClient):
    """Testa o endpoint raiz da API"""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"


def test_cache_stats_endpoint(client: TestClient):
    """Testa o endpoint de estatísticas do cache"""
    from unittest.mock import patch, AsyncMock
    mock_stats = {"connected": True, "total_keys": 6}
    
    # O patch deve apontar para onde o serviço é usado na rota
    with patch('backend.services.cache_service_simple.simple_cache_service.get_cache_stats', new_callable=AsyncMock) as mock_get_stats:
        mock_get_stats.return_value = mock_stats
        response = client.get("/cache/stats")
        assert response.status_code == 200
        data = response.json()
        assert data["connected"] is True
        assert data["total_keys"] == 6


def test_metrics_endpoint(client: TestClient):
    """Testa o endpoint de métricas do Prometheus"""
    response = client.get("/metrics")
    assert response.status_code == 200
    assert "http_requests_total" in response.text


def test_api_routes_exist(client: TestClient):
    """Verifica se as rotas principais da API existem"""
    # Rotas que devem existir (sem autenticação)
    public_routes = [
        "/",
        "/metrics",
        "/cache/stats",
    ]
    
    for route in public_routes:
        response = client.get(route)
        assert response.status_code != 404, f"Rota {route} não encontrada"


def test_protected_routes_unauthorized(client: TestClient):
    """Verifica se as rotas protegidas retornam 403 sem autenticação."""
    from backend.main import app
    from backend.auth import get_current_user
    
    # Remove o override de autenticação para este teste
    original_override = app.dependency_overrides.pop(get_current_user, None)
        
    try:
        # Rotas que sabidamente existem e são protegidas
        protected_routes = [
            "/api/cases/my-cases",
            "/api/offers/case/some-case-id", 
            "/api/contracts",
        ]
        
        for route in protected_routes:
            response = client.get(route)
            # Aceita tanto 403 (Forbidden) quanto 401 (Unauthorized) como válidos
            assert response.status_code in [401, 403], f"Rota {route} não retornou 401 ou 403, retornou {response.status_code}"
    
    finally:
        # Restaura o override para não afetar outros testes
        if original_override:
            app.dependency_overrides[get_current_user] = original_override 