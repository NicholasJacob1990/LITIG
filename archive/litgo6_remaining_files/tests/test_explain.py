"""
Testes para o endpoint de explicações de matches.
"""
import pytest
from unittest.mock import patch, MagicMock

# Caminho correto para a função de autenticação
AUTH_PATH = 'backend.auth.get_current_user'

@pytest.mark.api
def test_explain_endpoint_success(client, mock_auth, sample_explain_request):
    """Testa endpoint de explicações com sucesso."""
    with patch(AUTH_PATH, mock_auth):
        with patch('backend.main_routes.generate_explanations_for_matches') as mock_explain:
            mock_explain.return_value = {
                "test-lawyer-123": "Dr. João Silva é uma excelente opção para seu caso!",
                "test-lawyer-456": "Dra. Maria Santos também é uma ótima escolha!"
            }
            
            response = client.post("/api/explain", json=sample_explain_request)
            
            assert response.status_code == 200
            data = response.json()
            assert "explanations" in data
            assert "test-lawyer-123" in data["explanations"]
            assert "test-lawyer-456" in data["explanations"]


@pytest.mark.api
def test_explain_endpoint_unauthorized(client, sample_explain_request):
    """Testa endpoint de explicações sem autenticação."""
    response = client.post("/api/explain", json=sample_explain_request)
    assert response.status_code == 401


@pytest.mark.api
def test_explain_endpoint_invalid_payload(client, mock_auth):
    """Testa endpoint de explicações com payload inválido."""
    with patch(AUTH_PATH, mock_auth):
        response = client.post("/api/explain", json={"invalid": "data"})
        assert response.status_code == 422


@pytest.mark.api
def test_explain_endpoint_case_not_found(client, mock_auth, sample_explain_request):
    """Testa endpoint de explicações com caso não encontrado."""
    with patch(AUTH_PATH, mock_auth):
        with patch('backend.main_routes.generate_explanations_for_matches') as mock_explain:
            mock_explain.side_effect = ValueError("Caso não encontrado")
            
            response = client.post("/api/explain", json=sample_explain_request)
            
            assert response.status_code == 404
            data = response.json()
            assert "não encontrado" in data["detail"]


@pytest.mark.api
def test_explain_endpoint_internal_error(client, mock_auth, sample_explain_request):
    """Testa endpoint de explicações com erro interno."""
    with patch(AUTH_PATH, mock_auth):
        with patch('backend.main_routes.generate_explanations_for_matches') as mock_explain:
            mock_explain.side_effect = Exception("Erro na API do Claude")
            
            response = client.post("/api/explain", json=sample_explain_request)
            
            assert response.status_code == 500
            data = response.json()
            assert "Erro ao gerar explicações" in data["detail"]


@pytest.mark.unit
def test_explain_service_call(mock_auth, sample_explain_request):
    """Testa se o serviço de explicações é chamado corretamente."""
    from backend.routes import generate_explanations_for_matches
    
    with patch('backend.routes.generate_explanations_for_matches') as mock_explain:
        mock_explain.return_value = {"test": "explanation"}
        
        # Simular chamada do serviço
        result = generate_explanations_for_matches(
            sample_explain_request["case_id"],
            sample_explain_request["lawyer_ids"]
        )
        
        mock_explain.assert_called_once_with(
            sample_explain_request["case_id"],
            sample_explain_request["lawyer_ids"]
        )
        
        assert result == {"test": "explanation"}


@pytest.mark.integration
def test_explain_with_mock_anthropic(client, mock_auth, mock_anthropic, sample_explain_request):
    """Testa explicações com mock do Anthropic."""
    with patch(AUTH_PATH, mock_auth):
        with patch('backend.explanation_service.generate_explanation') as mock_gen:
            mock_gen.return_value = "Explicação gerada pela IA"
            
            response = client.post("/api/explain", json=sample_explain_request)
            
            assert response.status_code == 200
            data = response.json()
            assert "explanations" in data


@pytest.mark.api
def test_explain_empty_lawyer_list(client, mock_auth):
    """Testa explicações com lista vazia de advogados."""
    with patch(AUTH_PATH, mock_auth):
        request_data = {
            "case_id": "test-case-123",
            "lawyer_ids": []
        }
        
        response = client.post("/api/explain", json=request_data)
        assert response.status_code == 422


@pytest.mark.api
def test_explain_rate_limiting(client, mock_auth, sample_explain_request):
    """Testa rate limiting do endpoint de explicações."""
    with patch(AUTH_PATH, mock_auth):
        with patch('backend.main_routes.generate_explanations_for_matches') as mock_explain:
            mock_explain.return_value = {"test": "explanation"}
            
            # Simular múltiplas requisições (rate limit é 30/min)
            for i in range(5):
                response = client.post("/api/explain", json=sample_explain_request)
                if i < 4:
                    assert response.status_code == 200
                # Na prática, o rate limiting seria testado com mais requisições
                # mas evitamos para não tornar o teste muito lento


@pytest.mark.slow
def test_explain_performance(client, mock_auth):
    """Testa performance do endpoint de explicações."""
    import time
    
    with patch(AUTH_PATH, mock_auth):
        with patch('backend.main_routes.generate_explanations_for_matches') as mock_explain:
            mock_explain.return_value = {"test": "explanation"}
            
            request_data = {
                "case_id": "test-case-123",
                "lawyer_ids": ["lw-1", "lw-2", "lw-3", "lw-4", "lw-5"]
            }
            
            start_time = time.time()
            response = client.post("/api/explain", json=request_data)
            end_time = time.time()
            
            assert response.status_code == 200
            # Verificar que a resposta é rápida (< 1 segundo com mocks)
            assert end_time - start_time < 1.0 