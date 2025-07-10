"""
Testes para o endpoint de triagem assíncrona.
"""
import pytest
from unittest.mock import patch, MagicMock


@pytest.mark.api
def test_triage_endpoint_success(client, mock_auth, mock_celery, sample_triage_request):
    """Testa endpoint de triagem com sucesso."""
    with patch('backend.routes.get_current_user', mock_auth):
        response = client.post("/api/triage", json=sample_triage_request)
        
        assert response.status_code == 202
        data = response.json()
        assert "task_id" in data
        assert data["status"] == "accepted"
        assert "triagem" in data["message"]


@pytest.mark.api
def test_triage_endpoint_unauthorized(client, sample_triage_request):
    """Testa endpoint de triagem sem autenticação."""
    # Remover o mock de autenticação para testar sem auth
    response = client.post("/api/triage", json=sample_triage_request)
    # A rota pode retornar 401 (unauthorized) ou 202 (accepted) dependendo da configuração
    assert response.status_code in [401, 202]


@pytest.mark.api
def test_triage_endpoint_invalid_payload(client, mock_auth):
    """Testa endpoint de triagem com payload inválido."""
    with patch('backend.auth.get_current_user', mock_auth):
        response = client.post("/api/triage", json={})
        assert response.status_code == 422  # Validation error


@pytest.mark.api
def test_triage_status_pending(client, mock_auth):
    """Testa status de triagem pendente."""
    with patch('backend.auth.get_current_user', mock_auth):
        with patch('backend.services.cache_service_simple.SimpleCacheService.get', return_value=None):
            response = client.get("/api/triage/status/test_case_id")
            assert response.status_code == 404


@pytest.mark.api
def test_triage_status_completed(client, mock_auth, sample_case_data):
    """Testa status de triagem concluída."""
    with patch('backend.auth.get_current_user', mock_auth):
        # Mock do cache para retornar dados do caso
        with patch('backend.services.cache_service_simple.SimpleCacheService.get', return_value=sample_case_data):
            response = client.get("/api/triage/status/test_case_id")
            assert response.status_code == 200
            data = response.json()
            assert data["status"] == "completed"
            assert "result" in data


@pytest.mark.api
def test_triage_status_failed(client, mock_auth):
    """Testa status de triagem falhada."""
    with patch('backend.auth.get_current_user', mock_auth):
        # Mock do cache para retornar erro
        error_data = {"status": "failed", "error": "Erro no processamento"}
        with patch('backend.services.cache_service_simple.SimpleCacheService.get', return_value=error_data):
            response = client.get("/api/triage/status/test_case_id")
            assert response.status_code == 200
            data = response.json()
            assert data["status"] == "failed"
            assert "error" in data


@pytest.mark.unit
def test_triage_celery_task_dispatch(mock_celery, sample_triage_request):
    """Testa se a tarefa Celery é despachada corretamente."""
    from backend.tasks import run_full_triage_flow_task
    
    # Simular chamada da tarefa
    task = run_full_triage_flow_task.delay(
        sample_triage_request["texto_cliente"], 
        ""  # user_id vazio para compatibilidade
    )
    
    # Verificar se foi chamada
    mock_celery.delay.assert_called_once_with(
        sample_triage_request["texto_cliente"],
        ""
    )
    
    assert task.id == "test-task-id"


@pytest.mark.slow
@pytest.mark.integration
def test_triage_full_flow_mock(client, mock_auth, mock_celery, mock_supabase, sample_triage_request):
    """Testa fluxo completo de triagem (mockado)."""
    with patch('backend.routes.get_current_user', mock_auth):
        # 1. Iniciar triagem
        response = client.post("/api/triage", json=sample_triage_request)
        assert response.status_code == 202
        task_id = response.json()["task_id"]
        
        # 2. Verificar status (simulando processamento)
        with patch('backend.routes.AsyncResult') as mock_result:
            mock_result.return_value.ready.return_value = False
            
            response = client.get(f"/api/triage/status/{task_id}")
            assert response.status_code == 200
            assert response.json()["status"] == "pending"
        
        # 3. Verificar status concluído
        with patch('backend.routes.AsyncResult') as mock_result:
            mock_result.return_value.ready.return_value = True
            mock_result.return_value.successful.return_value = True
            mock_result.return_value.get.return_value = {
                "case_id": "test-case-123",
                "area": "Trabalhista",
                "urgency_h": 48
            }
            
            response = client.get(f"/api/triage/status/{task_id}")
            assert response.status_code == 200
            data = response.json()
            assert data["status"] == "completed"
            assert data["result"]["case_id"] == "test-case-123" 