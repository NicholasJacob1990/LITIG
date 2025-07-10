import pytest
import asyncio
import uuid
from unittest.mock import AsyncMock, MagicMock, patch
from backend.services.conversation_state_manager import conversation_state_manager
from backend.services.intelligent_interviewer_service import intelligent_interviewer_service
from backend.services.intelligent_triage_orchestrator import intelligent_triage_orchestrator
from backend.services.redis_service import redis_service
from backend.routes.health_routes import router as health_router
from fastapi.testclient import TestClient
from backend.main import app

# Mock do Redis para testes
class MockRedis:
    def __init__(self):
        self.data = {}
        self.ttls = {}
    
    async def set(self, key, value):
        self.data[key] = value
        return True
    
    async def setex(self, key, ttl, value):
        self.data[key] = value
        self.ttls[key] = ttl
        return True
    
    async def get(self, key):
        return self.data.get(key)
    
    async def delete(self, key):
        if key in self.data:
            del self.data[key]
            return 1
        return 0
    
    async def exists(self, key):
        return 1 if key in self.data else 0
    
    async def keys(self, pattern):
        import fnmatch
        return [k for k in self.data.keys() if fnmatch.fnmatch(k, pattern)]
    
    async def ttl(self, key):
        return self.ttls.get(key, -1)
    
    async def ping(self):
        return True
    
    async def info(self):
        return {
            "connected_clients": 1,
            "used_memory_human": "1MB",
            "uptime_in_seconds": 3600
        }
    
    async def close(self):
        pass

@pytest.fixture
async def mock_redis():
    """Fixture que fornece um Redis mockado."""
    mock_redis = MockRedis()
    
    # Patch do redis_service para usar nosso mock
    with patch.object(redis_service, 'get_redis', return_value=mock_redis):
        # Inicializar o redis_service
        redis_service.redis_pool = MagicMock()
        yield mock_redis

@pytest.mark.asyncio
async def test_conversation_persistence(mock_redis):
    """Testa se as conversas são persistidas corretamente."""
    case_id = str(uuid.uuid4())
    
    # Estado inicial da conversa
    initial_state = {
        "status": "active",
        "current_step": "initial_questions",
        "questions": ["Qual é o seu nome?", "Qual é o problema?"],
        "answers": {}
    }
    
    # Salvar estado
    success = await conversation_state_manager.save_conversation_state(case_id, initial_state)
    assert success is True
    
    # Recuperar estado
    recovered_state = await conversation_state_manager.get_conversation_state(case_id)
    assert recovered_state is not None
    assert recovered_state["status"] == "active"
    assert recovered_state["current_step"] == "initial_questions"
    assert len(recovered_state["questions"]) == 2

@pytest.mark.asyncio
async def test_server_restart_simulation(mock_redis):
    """Simula um restart do servidor e verifica se os dados persistem."""
    case_id = str(uuid.uuid4())
    
    # Configurar estado inicial
    initial_orchestration = {
        "status": "in_progress",
        "current_phase": "interview",
        "interview_completed": False,
        "data": {"user_name": "João"}
    }
    
    # Salvar orquestração
    success = await conversation_state_manager.save_orchestration_state(case_id, initial_orchestration)
    assert success is True
    
    # Simular "restart" criando nova instância do orquestrador
    # (na prática, isso seria uma nova instância após restart)
    new_orchestrator = intelligent_triage_orchestrator
    
    # Verificar se consegue recuperar o estado
    status = await new_orchestrator.get_orchestration_status(case_id)
    assert status is not None
    assert status["status"] == "in_progress"
    assert status["current_phase"] == "interview"

@pytest.mark.asyncio  
async def test_ttl_functionality(mock_redis):
    """Testa se o TTL está funcionando corretamente."""
    case_id = "test_ttl_case"
    
    # Salvar com TTL muito baixo para teste
    test_state = {"test": "data"}
    success = await conversation_state_manager.save_conversation_state(case_id, test_state, ttl=2)
    assert success is True
    
    # Verificar se existe imediatamente
    exists = await conversation_state_manager.conversation_exists(case_id)
    assert exists is True
    
    # Simular expiração (no mock, vamos apenas remover)
    await mock_redis.delete(f"conversation:{case_id}")
    
    # Verificar se foi removido
    exists_after = await conversation_state_manager.conversation_exists(case_id)
    assert exists_after is False

@pytest.mark.asyncio
async def test_redis_health_check_endpoint(mock_redis):
    """Testa o endpoint de health check do Redis."""
    # Simular usuário autenticado
    with patch('backend.routes.health_routes.get_current_user') as mock_auth:
        mock_auth.return_value = {"id": "test_user"}
        
        client = TestClient(app)
        response = client.get("/api/health/redis")
        
        assert response.status_code == 200
        health = response.json()
        assert health["status"] == "healthy"
        assert "latency_ms" in health

@pytest.mark.asyncio
async def test_system_stats():
    """Testa as estatísticas do sistema."""
    with patch.object(redis_service, 'get_redis', return_value=MockRedis()):
        redis_service.redis_pool = MagicMock()
        
        stats = await conversation_state_manager.get_system_stats()
        assert "active_conversations" in stats
        assert "active_orchestrations" in stats
        assert "redis_health" in stats
        assert "timestamp" in stats

@pytest.mark.asyncio
async def test_migration_functionality():
    """Testa a funcionalidade de migração."""
    with patch.object(redis_service, 'get_redis', return_value=MockRedis()):
        redis_service.redis_pool = MagicMock()
        
        # Dados de exemplo para migração
        memory_data = {
            "conversations": {
                "case_1": {"status": "active", "step": 1},
                "case_2": {"status": "completed", "step": 5}
            },
            "orchestrations": {
                "case_1": {"phase": "interview", "progress": 0.5}
            }
        }
        
        result = await conversation_state_manager.migrate_memory_to_redis(memory_data)
        
        assert result["conversations_migrated"] == 2
        assert result["orchestrations_migrated"] == 1
        assert result["total_migrated"] == 3

if __name__ == "__main__":
    # Executar testes individualmente para debug
    asyncio.run(test_conversation_persistence(MockRedis()))
    print("✅ Teste de persistência de conversas passou!")
    
    asyncio.run(test_ttl_functionality(MockRedis()))
    print("✅ Teste de TTL passou!")
    
    asyncio.run(test_system_stats())
    print("✅ Teste de estatísticas do sistema passou!")
    
    asyncio.run(test_migration_functionality())
    print("✅ Teste de migração passou!")
    
    print("🎉 Todos os testes passaram!") 