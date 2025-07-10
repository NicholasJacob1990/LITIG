"""
Configuração pytest para o projeto LITGO5.

Este arquivo configura fixtures e mocks necessários para os testes.
"""
import pytest
import os
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock, AsyncMock

# Configurar ambiente de teste
os.environ["TESTING"] = "true"
os.environ["SUPABASE_URL"] = "https://test.supabase.co"
os.environ["SUPABASE_SERVICE_KEY"] = "test-service-key"
os.environ["ANTHROPIC_API_KEY"] = "test-anthropic-key"
os.environ["OPENAI_API_KEY"] = "test-openai-key"

# Usar Redis do contêiner se já estiver configurado, senão usar localhost
# Isso permite que os testes funcionem tanto localmente quanto no Docker
if "REDIS_URL" not in os.environ:
    os.environ["REDIS_URL"] = "redis://localhost:6379/1"  # DB diferente para testes locais


@pytest.fixture(scope="session")
def app_with_mocks():
    """
    Cria uma instância do app FastAPI com as dependências
    de serviços mockadas para testes.
    """
    mock_redis_service = MagicMock()
    mock_redis_service.initialize = AsyncMock()
    mock_redis_service.close = AsyncMock()
    mock_redis_service.health_check = AsyncMock(return_value={"status": "healthy"})

    mock_cache_service_init = AsyncMock()
    mock_cache_service_close = AsyncMock()

    # Importa o app e as dependências que vamos substituir
    from backend.main import app, redis_service, init_simple_cache, close_simple_cache
    from backend.auth import get_current_user

    # Aplica os overrides
    app.dependency_overrides[redis_service] = lambda: mock_redis_service
    app.dependency_overrides[init_simple_cache] = mock_cache_service_init
    app.dependency_overrides[close_simple_cache] = lambda: mock_cache_service_close
    app.dependency_overrides[get_current_user] = lambda: {"id": "test-user-id"}

    yield app

    # Limpa os overrides depois que os testes terminarem
    app.dependency_overrides.clear()


@pytest.fixture(scope="session")
def client(app_with_mocks):
    """
    Cria um TestClient para interagir com o app mockado.
    """
    with TestClient(app_with_mocks) as test_client:
        yield test_client


@pytest.fixture
def mock_auth():
    """Mock para autenticação em testes."""
    def mock_get_current_user():
        return {
            "id": "test-user-id",
            "email": "test@example.com",
            "role": "authenticated"
        }
    return mock_get_current_user


@pytest.fixture
def mock_supabase():
    """Mock para cliente Supabase."""
    with patch('backend.services.supabase') as mock:
        # Configurar comportamento padrão
        mock.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value.data = {
            "id": "test-case-id",
            "area": "Trabalhista",
            "subarea": "Rescisão",
            "urgency_h": 48,
            "coords": [-23.5505, -46.6333],
            "embedding": [0.1] * 384
        }
        yield mock


@pytest.fixture
def mock_celery():
    """Mock para tarefas Celery."""
    with patch('backend.routes.run_triage_async_task') as mock_task:
        mock_task.delay.return_value.id = "test-task-id"
        yield mock_task


@pytest.fixture
def mock_anthropic():
    """Mock para cliente Anthropic Claude."""
    with patch('backend.triage_service.anthropic') as mock:
        # Mock da resposta do Claude
        mock_response = MagicMock()
        mock_response.content = [{
            "type": "tool_use",
            "name": "extract_case_details",
            "input": {
                "area": "Trabalhista",
                "subarea": "Rescisão Indireta",
                "urgency_h": 48,
                "summary": "Cliente foi demitido sem justa causa"
            }
        }]
        mock.Anthropic.return_value.messages.create.return_value = mock_response
        yield mock


@pytest.fixture
def mock_openai():
    """Mock para cliente OpenAI."""
    with patch('backend.embedding_service.openai') as mock:
        # Mock da resposta de embedding
        mock.Embedding.create.return_value = {
            "data": [{"embedding": [0.1] * 384}]
        }
        yield mock


@pytest.fixture
def sample_case_data():
    """Dados de exemplo para um caso."""
    return {
        "id": "test-case-123",
        "texto_cliente": "Fui demitido sem justa causa e não recebi verbas rescisórias",
        "area": "Trabalhista",
        "subarea": "Rescisão Indireta",
        "urgency_h": 48,
        "coords": [-23.5505, -46.6333],
        "embedding": [0.1] * 384,
        "created_at": "2025-01-15T10:00:00Z"
    }


@pytest.fixture
def sample_lawyer_data():
    """Dados de exemplo para um advogado."""
    return {
        "id": "test-lawyer-123",
        "nome": "Dr. João Silva",
        "oab_number": "123456/SP",
        "tags_expertise": ["Trabalhista", "Civil"],
        "geo_latlon": [-23.5505, -46.6333],
        "curriculo_json": {
            "anos_experiencia": 15,
            "pos_graduacoes": [
                {"nivel": "lato", "area": "Trabalhista"},
                {"nivel": "mestrado", "area": "Trabalhista"}
            ],
            "num_publicacoes": 5
        },
        "casos_historicos_embeddings": [[0.2] * 384, [0.3] * 384],
        "kpi": {
            "success_rate": 0.85,
            "cases_30d": 10,
            "capacidade_mensal": 20,
            "avaliacao_media": 4.8,
            "tempo_resposta_h": 12
        },
        "last_offered_at": "2025-01-14T10:00:00Z"
    }


@pytest.fixture
def sample_match_request():
    """Request de exemplo para match."""
    return {
        "case_id": "test-case-123",
        "k": 5,
        "equity": 0.3
    }


@pytest.fixture
def sample_triage_request():
    """Request de exemplo para triagem."""
    return {
        "texto_cliente": "Fui demitido sem justa causa e não recebi as verbas rescisórias",
        "coords": [-23.5505, -46.6333]
    }


@pytest.fixture
def sample_explain_request():
    """Request de exemplo para explicações."""
    return {
        "case_id": "test-case-123",
        "lawyer_ids": ["test-lawyer-123", "test-lawyer-456"]
    }


# Configuração global do pytest
def pytest_configure(config):
    """Configuração global do pytest."""
    # Configurar logging para testes
    import logging
    logging.getLogger("httpx").setLevel(logging.WARNING)
    logging.getLogger("httpcore").setLevel(logging.WARNING)
    
    # Registrar marcadores personalizados
    config.addinivalue_line(
        "markers", "unit: marca testes unitários"
    )
    config.addinivalue_line(
        "markers", "integration: marca testes de integração"
    )
    config.addinivalue_line(
        "markers", "slow: marca testes lentos"
    )
    config.addinivalue_line(
        "markers", "api: marca testes de API"
    ) 