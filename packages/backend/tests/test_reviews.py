# -*- coding: utf-8 -*-
"""
Testes para o Sistema de Reviews/Avaliações - Fase 9
====================================================
Testa a implementação da separação entre feedback subjetivo (R) e KPI objetivo (T).
"""

import uuid
from datetime import datetime, timedelta
from unittest.mock import AsyncMock, Mock, patch

import pytest
from fastapi.testclient import TestClient

from backend.main import app

client = TestClient(app)

# =============================================================================
# Fixtures
# =============================================================================


@pytest.fixture
def mock_supabase():
    """Mock do cliente Supabase."""
    with patch('backend.routes.reviews.supabase') as mock:
        yield mock


@pytest.fixture
def mock_auth_user():
    """Mock do usuário autenticado."""
    user_mock = Mock()
    user_mock.id = "test-client-id"
    user_mock.role = "client"

    with patch('backend.routes.reviews.get_current_user', return_value=user_mock):
        yield user_mock


@pytest.fixture
def sample_contract():
    """Dados de um contrato de exemplo."""
    return {
        "id": "contract-123",
        "client_id": "test-client-id",
        "lawyer_id": "lawyer-456",
        "status": "closed"
    }


@pytest.fixture
def sample_review_data():
    """Dados de uma review de exemplo."""
    return {
        "rating": 5,
        "comment": "Excelente advogado, muito profissional",
        "outcome": "won",
        "communication_rating": 5,
        "expertise_rating": 5,
        "timeliness_rating": 4,
        "would_recommend": True
    }

# =============================================================================
# Testes de Criação de Review
# =============================================================================


def test_create_review_success(
        mock_supabase, mock_auth_user, sample_contract, sample_review_data):
    """Teste de criação de review bem-sucedida."""
    # Configurar mocks
    mock_supabase.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = sample_contract
    # Nenhuma review existente
    mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = []

    # Mock da inserção
    created_review = {
        "id": "review-789",
        "contract_id": sample_contract["id"],
        "lawyer_id": sample_contract["lawyer_id"],
        "client_id": mock_auth_user.id,
        "created_at": datetime.now().isoformat(),
        "updated_at": datetime.now().isoformat(),
        **sample_review_data
    }
    mock_supabase.table.return_value.insert.return_value.execute.return_value.data = [
        created_review]

    # Fazer requisição
    response = client.post(
        f"/api/reviews/contracts/{sample_contract['id']}/review",
        json=sample_review_data
    )

    # Verificações
    assert response.status_code == 201
    data = response.json()
    assert data["rating"] == 5
    assert data["comment"] == "Excelente advogado, muito profissional"
    assert data["outcome"] == "won"
    assert data["would_recommend"] is True


def test_create_review_contract_not_found(
        mock_supabase, mock_auth_user, sample_review_data):
    """Teste de criação de review para contrato inexistente."""
    # Mock contrato não encontrado
    mock_supabase.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = None

    response = client.post(
        "/api/reviews/contracts/invalid-contract/review",
        json=sample_review_data
    )

    assert response.status_code == 404
    assert "não encontrado" in response.json()["detail"]


def test_create_review_not_client(
        mock_supabase, mock_auth_user, sample_contract, sample_review_data):
    """Teste de criação de review por usuário que não é o cliente."""
    # Alterar o client_id do contrato
    different_contract = {**sample_contract, "client_id": "different-client"}
    mock_supabase.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = different_contract

    response = client.post(
        f"/api/reviews/contracts/{sample_contract['id']}/review",
        json=sample_review_data
    )

    assert response.status_code == 403
    assert "cliente pode avaliar" in response.json()["detail"]


def test_create_review_contract_not_closed(
        mock_supabase, mock_auth_user, sample_contract, sample_review_data):
    """Teste de criação de review para contrato não fechado."""
    # Contrato ainda ativo
    active_contract = {**sample_contract, "status": "active"}
    mock_supabase.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = active_contract

    response = client.post(
        f"/api/reviews/contracts/{sample_contract['id']}/review",
        json=sample_review_data
    )

    assert response.status_code == 400
    assert "concluídos podem ser avaliados" in response.json()["detail"]


def test_create_review_already_exists(
        mock_supabase, mock_auth_user, sample_contract, sample_review_data):
    """Teste de criação de review duplicada."""
    # Mock contrato válido
    mock_supabase.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = sample_contract

    # Mock review existente
    existing_review = {"id": "existing-review"}
    mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [
        existing_review]

    response = client.post(
        f"/api/reviews/contracts/{sample_contract['id']}/review",
        json=sample_review_data
    )

    assert response.status_code == 409
    assert "já foi avaliado" in response.json()["detail"]


def test_create_review_invalid_rating(mock_auth_user):
    """Teste de criação de review com rating inválido."""
    invalid_data = {
        "rating": 6,  # Inválido (deve ser 1-5)
        "comment": "Teste"
    }

    response = client.post(
        "/api/reviews/contracts/test-contract/review",
        json=invalid_data
    )

    assert response.status_code == 422  # Validation error


def test_create_review_invalid_outcome(mock_auth_user):
    """Teste de criação de review com outcome inválido."""
    invalid_data = {
        "rating": 5,
        "outcome": "invalid_outcome"
    }

    response = client.post(
        "/api/reviews/contracts/test-contract/review",
        json=invalid_data
    )

    assert response.status_code == 422  # Validation error

# =============================================================================
# Testes de Consulta de Reviews
# =============================================================================


def test_get_lawyer_reviews(mock_supabase, mock_auth_user):
    """Teste de consulta de reviews de um advogado."""
    # Mock reviews do advogado
    lawyer_reviews = [
        {
            "id": "review-1",
            "lawyer_id": "lawyer-456",
            "rating": 5,
            "comment": "Ótimo",
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat(),
            "contract_id": "contract-1",
            "client_id": "client-1",
            "outcome": "won",
            "communication_rating": 5,
            "expertise_rating": 5,
            "timeliness_rating": 4,
            "would_recommend": True
        },
        {
            "id": "review-2",
            "lawyer_id": "lawyer-456",
            "rating": 4,
            "comment": "Bom",
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat(),
            "contract_id": "contract-2",
            "client_id": "client-2",
            "outcome": "settled",
            "communication_rating": 4,
            "expertise_rating": 4,
            "timeliness_rating": 4,
            "would_recommend": True
        }
    ]

    mock_supabase.table.return_value.select.return_value.eq.return_value.order.return_value.range.return_value.execute.return_value.data = lawyer_reviews

    response = client.get("/api/reviews/lawyers/lawyer-456/reviews")

    assert response.status_code == 200
    data = response.json()
    assert len(data) == 2
    assert data[0]["rating"] == 5
    assert data[1]["rating"] == 4


def test_get_contract_review(mock_supabase, mock_auth_user):
    """Teste de consulta de review de um contrato específico."""
    # Mock contrato
    contract = {
        "client_id": mock_auth_user.id,
        "lawyer_id": "lawyer-456"
    }
    mock_supabase.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = contract

    # Mock review
    review = {
        "id": "review-123",
        "contract_id": "contract-123",
        "lawyer_id": "lawyer-456",
        "client_id": mock_auth_user.id,
        "rating": 5,
        "comment": "Excelente",
        "created_at": datetime.now().isoformat(),
        "updated_at": datetime.now().isoformat(),
        "outcome": "won",
        "communication_rating": 5,
        "expertise_rating": 5,
        "timeliness_rating": 5,
        "would_recommend": True
    }
    mock_supabase.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = review

    response = client.get("/api/reviews/contracts/contract-123/review")

    assert response.status_code == 200
    data = response.json()
    assert data["rating"] == 5
    assert data["outcome"] == "won"

# =============================================================================
# Testes do Job de Atualização de KPI
# =============================================================================


@pytest.mark.asyncio
async def test_update_lawyers_review_kpi():
    """Teste do job de atualização de KPI de reviews."""
    from backend.jobs.update_review_kpi import ReviewKPIUpdater

    # Mock do Supabase
    mock_supabase = Mock()
    mock_result = Mock()
    mock_result.data = 5  # 5 advogados atualizados
    mock_supabase.rpc.return_value.execute.return_value = mock_result

    # Criar updater com mock
    updater = ReviewKPIUpdater()
    updater.supabase = mock_supabase

    # Executar atualização
    stats = await updater.update_all_lawyers_kpi()

    # Verificações
    assert stats["success"] is True
    assert stats["updated_lawyers"] == 5
    assert "start_time" in stats
    assert "end_time" in stats

    # Verificar que a função SQL foi chamada
    mock_supabase.rpc.assert_called_once_with('update_lawyers_review_kpi')

# =============================================================================
# Testes de Validação
# =============================================================================


def test_review_validation_rating_required():
    """Teste de validação: rating é obrigatório."""
    data = {"comment": "Teste sem rating"}

    response = client.post(
        "/api/reviews/contracts/test-contract/review",
        json=data
    )

    assert response.status_code == 422


def test_review_validation_rating_range():
    """Teste de validação: rating deve estar entre 1-5."""
    for invalid_rating in [0, 6, -1, 10]:
        data = {"rating": invalid_rating}

        response = client.post(
            "/api/reviews/contracts/test-contract/review",
            json=data
        )

        assert response.status_code == 422


def test_review_validation_comment_length():
    """Teste de validação: comentário não pode exceder 1000 caracteres."""
    data = {
        "rating": 5,
        "comment": "x" * 1001  # Excede o limite
    }

    response = client.post(
        "/api/reviews/contracts/test-contract/review",
        json=data
    )

    assert response.status_code == 422


def test_review_validation_specific_ratings():
    """Teste de validação: ratings específicos devem estar entre 1-5."""
    data = {
        "rating": 5,
        "communication_rating": 6,  # Inválido
        "expertise_rating": 0,      # Inválido
        "timeliness_rating": 3      # Válido
    }

    response = client.post(
        "/api/reviews/contracts/test-contract/review",
        json=data
    )

    assert response.status_code == 422

# =============================================================================
# Testes de Integração com Algoritmo
# =============================================================================


def test_algorithm_integration_review_score():
    """Teste de integração: verificar se reviews afetam a feature R do algoritmo."""
    import numpy as np

    from backend.algoritmo_match import KPI, Case, FeatureCalculator, Lawyer

    # Criar advogado com KPI atualizado
    kpi = KPI(
        success_rate=0.85,  # T (do Jusbrasil) - não afetado por reviews
        cases_30d=10,
        active_cases=20,
        avaliacao_media=4.5,  # R (das reviews) - atualizado pelo job
        tempo_resposta_h=12
    )

    lawyer = Lawyer(
        id="lawyer-test",
        nome="Dr. Teste",
        tags_expertise=["Trabalhista"],
        geo_latlon=(-23.5505, -46.6333),
        curriculo_json={"anos_experiencia": 10},
        kpi=kpi,
        casos_historicos_embeddings=[np.random.rand(384)]
    )

    case = Case(
        id="case-test",
        area="Trabalhista",
        subarea="Rescisão",
        urgency_h=48,
        coords=(-23.5505, -46.6333),
        summary_embedding=np.random.rand(384)
    )

    # Calcular features
    calculator = FeatureCalculator(case, lawyer)
    features = calculator.all()

    # Verificar que T e R são independentes
    assert features["T"] == 0.85  # Taxa de sucesso do Jusbrasil
    assert features["R"] == 0.9   # Review score: 4.5/5 = 0.9

    # Verificar que ambas contribuem para o score final
    raw_score = sum(
        weight * features[feature]
        for feature, weight in {
            "A": 0.30, "S": 0.25, "T": 0.15,
            "G": 0.10, "Q": 0.10, "U": 0.05, "R": 0.05
        }.items()
    )

    # R contribui com 5% do score total
    r_contribution = 0.05 * features["R"]
    assert r_contribution > 0  # Reviews impactam o score
