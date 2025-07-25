"""
Configuração principal de fixtures para testes do LITIG-1.
Inclui configuração de banco de dados de teste, sessões async, e cliente HTTP.
"""

import pytest
import pytest_asyncio
import asyncio
from typing import AsyncGenerator
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.pool import StaticPool
import os

# Importar componentes do app
from database import Base, get_async_session

# Criar um app FastAPI simples para testes
from fastapi import FastAPI
app = FastAPI(title="LITIG-1 Test App")

# Incluir rotas de teste - corrigindo import e endpoint prefix
try:
    from api.admin_premium import router as premium_router
    app.include_router(premium_router, prefix="", tags=["admin"])
except ImportError as e:
    print(f"Warning: Could not import admin_premium router: {e}")
    pass

# URL do banco de teste (em memória SQLite ou PostgreSQL dedicado)
TEST_DATABASE_URL = os.getenv(
    "TEST_DATABASE_URL", 
    "sqlite+aiosqlite:///:memory:"
)

# Engine de teste
test_engine = create_async_engine(
    TEST_DATABASE_URL,
    echo=False,
    poolclass=StaticPool,
    connect_args={"check_same_thread": False} if "sqlite" in TEST_DATABASE_URL else {}
)

test_session_maker = async_sessionmaker(
    test_engine, 
    class_=AsyncSession, 
    expire_on_commit=False
)


@pytest.fixture(scope="session")
def event_loop():
    """Cria um event loop para toda a sessão de testes."""
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


@pytest_asyncio.fixture(autouse=True, scope="session")
async def setup_test_db():
    """Cria todas as tabelas no início da sessão de testes."""
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest_asyncio.fixture
async def db_session() -> AsyncSession:
    """Fornece uma sessão de banco de dados para cada teste."""
    async with test_session_maker() as session:
        try:
            yield session
        finally:
            await session.rollback()


@pytest_asyncio.fixture
async def client(db_session: AsyncSession) -> AsyncGenerator[AsyncClient, None]:
    """Fornece um cliente HTTP de teste com override da sessão de banco."""
    
    # Override da dependência de sessão
    app.dependency_overrides[get_async_session] = lambda: db_session
    
    from httpx import ASGITransport
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as test_client:
        yield test_client
    
    # Limpar override
    app.dependency_overrides.clear()


@pytest.fixture
def sample_premium_criteria_data():
    """Dados de exemplo para criar critérios premium."""
    return {
        "service_code": "tributario",
        "subservice_code": "imposto_de_renda",
        "name": "IR Premium > 100k",
        "enabled": True,
        "min_valor_causa": 100000,
        "max_valor_causa": None,
        "min_urgency_h": None,
        "complexity_levels": ["HIGH", "VERY_HIGH"],
        "vip_client_plans": ["PREMIUM", "ENTERPRISE"]
    }


@pytest.fixture
def sample_case_data():
    """Dados de exemplo para criar um caso."""
    return {
        "id": "case_123",
        "area": "Direito Tributário",
        "subarea": "Imposto de Renda",
        "valor_causa": 150000,
        "complexity": "HIGH",
        "urgency_h": 48,
        "client_id": "client_456",
        "cliente_nome": "João Silva",
        "cliente_email": "joao@example.com",
        "cliente_phone": "+5511999999999",
        "detailed_description": "Caso complexo de sonegação fiscal"
    }


# Fixtures para mocks externos
@pytest.fixture
def mock_redis():
    """Mock do Redis usando fakeredis."""
    import fakeredis
    return fakeredis.FakeRedis()


@pytest.fixture
def mock_external_apis(monkeypatch):
    """Mock de APIs externas (LTR, Perplexity, etc.)."""
    
    # Mock do serviço LTR
    def mock_ltr_score(*args, **kwargs):
        return {"score": 0.75, "confidence": 0.85}
    
    # Mock do Perplexity/Academic Enricher
    def mock_academic_score(*args, **kwargs):
        return {
            "academic_score": 0.80,
            "publications": 5,
            "h_index": 3
        }
    
    monkeypatch.setattr("services.ltr_service.get_ltr_score", mock_ltr_score)
    monkeypatch.setattr("services.academic_enrichment_pipeline.AcademicEnricher.score_lawyer", mock_academic_score)
    
    return {
        "ltr_score": mock_ltr_score,
        "academic_score": mock_academic_score
    } 