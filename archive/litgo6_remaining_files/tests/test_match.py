# tests/test_match.py
import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock
import numpy as np

# Adicione o diretório raiz ao path para que o 'backend' possa ser importado
import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from backend.main import app
from backend.algoritmo_match import Case, Lawyer, KPI

# --- Mocks ---

@pytest.fixture
def client():
    """Fixture para o TestClient do FastAPI."""
    return TestClient(app)

@pytest.fixture
def mock_supabase():
    """Fixture para mockar o cliente Supabase."""
    with patch('backend.services.supabase') as mock:
        yield mock

def get_mock_case_data():
    """Retorna dados de um caso mockado."""
    return {
        "id": "test-case-123",
        "area": "Trabalhista",
        "subarea": "Rescisão",
        "urgency_h": 24,
        "coords": [-23.55, -46.63],
        "summary_embedding": np.random.rand(384).tolist(),
    }

def get_mock_lawyers_data():
    """Retorna uma lista de advogados mockados."""
    return [
        {
            "id": "lw-1", "nome": "Advogado A", "tags_expertise": ["Trabalhista"],
            "geo_latlon": [-23.55, -46.63], "curriculo_json": {"anos_experiencia": 10},
            "casos_historicos_embeddings": [np.random.rand(384).tolist()],
            "kpi": {"success_rate": 0.9, "cases_30d": 10, "capacidade_mensal": 15, "avaliacao_media": 4.8, "tempo_resposta_h": 10}
        },
        {
            "id": "lw-2", "nome": "Advogado B", "tags_expertise": ["Trabalhista", "Cível"],
            "geo_latlon": [-23.56, -46.64], "curriculo_json": {"anos_experiencia": 5},
            "casos_historicos_embeddings": [np.random.rand(384).tolist()],
            "kpi": {"success_rate": 0.8, "cases_30d": 5, "capacidade_mensal": 10, "avaliacao_media": 4.5, "tempo_resposta_h": 20}
        }
    ]

# --- Testes ---

def test_root_endpoint(client):
    """Testa se o endpoint raiz está funcionando."""
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"status": "ok", "message": "Bem-vindo à API LITGO!"}

def test_match_endpoint_success(client, mock_supabase):
    """Testa o endpoint /match com sucesso."""
    # Configura o mock do Supabase para retornar dados
    mock_supabase.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = get_mock_case_data()
    mock_supabase.table.return_value.select.return_value.contains.return_value.execute.return_value.data = get_mock_lawyers_data()

    # Chama o endpoint
    response = client.post("/api/match", json={"case_id": "test-case-123", "k": 2})

    # Asserts
    assert response.status_code == 200
    data = response.json()
    assert data["case_id"] == "test-case-123"
    assert len(data["matches"]) == 2
    assert "lawyer_id" in data["matches"][0]
    assert "fair" in data["matches"][0]
    # Verifica se os scores 'fair' estão ordenados de forma decrescente
    assert data["matches"][0]["fair"] >= data["matches"][1]["fair"]

def test_match_endpoint_case_not_found(client, mock_supabase):
    """Testa o endpoint /match quando o caso não é encontrado."""
    # Configura o mock para não encontrar o caso
    mock_supabase.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = None

    response = client.post("/api/match", json={"case_id": "non-existent-case"})

    assert response.status_code == 404
    assert "não encontrado" in response.json()["detail"]

def test_create_case_endpoint(client, mock_supabase):
    """Testa o endpoint de criação de caso."""
    mock_case_payload = {
        "texto_cliente": "Fui demitido sem justa causa.",
        "area": "Trabalhista",
        "subarea": "Rescisão",
        "urgency_h": 48,
        "summary_embedding": np.random.rand(384).tolist(),
        "coords": [-23.5505, -46.6333]
    }
    
    # Configura o mock para simular a inserção bem-sucedida
    mock_supabase.table.return_value.insert.return_value.execute.return_value.data = [{"id": "new-case-id"}]

    response = client.post("/api/cases", json=mock_case_payload)
    
    assert response.status_code == 201
    assert "case_id" in response.json()
    # Verifica se a função de insert do supabase foi chamada com os dados corretos
    mock_supabase.table.return_value.insert.assert_called_once() 