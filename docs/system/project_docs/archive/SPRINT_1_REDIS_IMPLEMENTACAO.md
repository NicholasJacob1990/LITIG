# Sprint 1: Implementação Redis e Persistência

## 📋 **Checklist de Implementação**

### **Dia 1-2: Configuração Base do Redis**

#### **1. Docker Compose - Redis Service**
```yaml
# docker-compose.yml
services:
  redis:
    image: redis:7-alpine
    container_name: litgo5_redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
      - ./redis/redis.conf:/usr/local/etc/redis/redis.conf
    command: redis-server /usr/local/etc/redis/redis.conf
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 3

volumes:
  redis_data:
```

#### **2. Configuração Redis**
```conf
# redis/redis.conf
maxmemory 1gb
maxmemory-policy allkeys-lru
save 900 1
save 300 10
save 60 10000
appendonly yes
appendfsync everysec
```

#### **3. Dependências Python**
```txt
# requirements.txt
aioredis==2.0.1
redis==5.0.1
```

#### **4. Variáveis de Ambiente**
```env
# .env
REDIS_URL=redis://localhost:6379/0
REDIS_MAX_CONNECTIONS=20
REDIS_RETRY_ON_TIMEOUT=True
REDIS_DECODE_RESPONSES=True
```

### **Dia 3-5: Serviço Base Redis**

#### **1. Redis Service**
```python
# backend/services/redis_service.py
import aioredis
import json
import logging
from typing import Any, Optional, Dict, List
from datetime import datetime, timedelta
import asyncio

logger = logging.getLogger(__name__)

class RedisService:
    """Serviço centralizado para operações Redis."""
    
    def __init__(self):
        self.redis_pool = None
        self.connection_retries = 3
        self.connection_timeout = 5
    
    async def initialize(self):
        """Inicializa conexão com Redis."""
        try:
            self.redis_pool = aioredis.ConnectionPool.from_url(
                REDIS_URL,
                max_connections=REDIS_MAX_CONNECTIONS,
                retry_on_timeout=REDIS_RETRY_ON_TIMEOUT,
                decode_responses=REDIS_DECODE_RESPONSES
            )
            
            # Testar conexão
            async with aioredis.Redis(connection_pool=self.redis_pool) as redis:
                await redis.ping()
                logger.info("Redis conectado com sucesso")
                
        except Exception as e:
            logger.error(f"Erro ao conectar Redis: {e}")
            raise
    
    async def get_redis(self) -> aioredis.Redis:
        """Obtém instância Redis."""
        if not self.redis_pool:
            await self.initialize()
        return aioredis.Redis(connection_pool=self.redis_pool)
    
    async def set_json(self, key: str, value: Any, ttl: Optional[int] = None) -> bool:
        """Armazena objeto JSON no Redis."""
        try:
            redis = await self.get_redis()
            serialized = json.dumps(value, ensure_ascii=False, default=str)
            
            if ttl:
                return await redis.setex(key, ttl, serialized)
            else:
                return await redis.set(key, serialized)
                
        except Exception as e:
            logger.error(f"Erro ao salvar {key}: {e}")
            return False
    
    async def get_json(self, key: str) -> Optional[Any]:
        """Recupera objeto JSON do Redis."""
        try:
            redis = await self.get_redis()
            data = await redis.get(key)
            
            if data:
                return json.loads(data)
            return None
            
        except Exception as e:
            logger.error(f"Erro ao recuperar {key}: {e}")
            return None
    
    async def delete(self, key: str) -> bool:
        """Remove chave do Redis."""
        try:
            redis = await self.get_redis()
            return await redis.delete(key) > 0
            
        except Exception as e:
            logger.error(f"Erro ao deletar {key}: {e}")
            return False
    
    async def exists(self, key: str) -> bool:
        """Verifica se chave existe."""
        try:
            redis = await self.get_redis()
            return await redis.exists(key) > 0
            
        except Exception as e:
            logger.error(f"Erro ao verificar {key}: {e}")
            return False
    
    async def get_keys_pattern(self, pattern: str) -> List[str]:
        """Busca chaves por padrão."""
        try:
            redis = await self.get_redis()
            return await redis.keys(pattern)
            
        except Exception as e:
            logger.error(f"Erro ao buscar padrão {pattern}: {e}")
            return []
    
    async def set_ttl(self, key: str, ttl: int) -> bool:
        """Define TTL para chave existente."""
        try:
            redis = await self.get_redis()
            return await redis.expire(key, ttl)
            
        except Exception as e:
            logger.error(f"Erro ao definir TTL {key}: {e}")
            return False
    
    async def get_ttl(self, key: str) -> int:
        """Obtém TTL de uma chave."""
        try:
            redis = await self.get_redis()
            return await redis.ttl(key)
            
        except Exception as e:
            logger.error(f"Erro ao obter TTL {key}: {e}")
            return -1
    
    async def health_check(self) -> Dict[str, Any]:
        """Verifica saúde do Redis."""
        try:
            redis = await self.get_redis()
            start_time = asyncio.get_event_loop().time()
            
            await redis.ping()
            latency = (asyncio.get_event_loop().time() - start_time) * 1000
            
            info = await redis.info()
            
            return {
                "status": "healthy",
                "latency_ms": round(latency, 2),
                "connected_clients": info.get("connected_clients", 0),
                "used_memory": info.get("used_memory_human", "0B"),
                "uptime_seconds": info.get("uptime_in_seconds", 0)
            }
            
        except Exception as e:
            return {
                "status": "unhealthy",
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }
    
    async def cleanup_expired(self, pattern: str = "*") -> int:
        """Remove chaves expiradas manualmente."""
        try:
            redis = await self.get_redis()
            keys = await redis.keys(pattern)
            expired_count = 0
            
            for key in keys:
                ttl = await redis.ttl(key)
                if ttl == -2:  # Chave expirada
                    await redis.delete(key)
                    expired_count += 1
            
            return expired_count
            
        except Exception as e:
            logger.error(f"Erro na limpeza: {e}")
            return 0

# Instância global
redis_service = RedisService()
```

### **Dia 6-8: Conversation State Manager**

#### **1. State Manager**
```python
# backend/services/conversation_state_manager.py
from typing import Dict, List, Optional, Any
from datetime import datetime, timedelta
import uuid
from .redis_service import redis_service
import logging

logger = logging.getLogger(__name__)

class ConversationStateManager:
    """Gerencia estado de conversas no Redis."""
    
    def __init__(self):
        self.conversation_prefix = "conversation:"
        self.orchestration_prefix = "orchestration:"
        self.default_ttl = 3600 * 24  # 24 horas
    
    # ========== CONVERSAS ==========
    
    async def save_conversation_state(
        self, 
        case_id: str, 
        state: Dict[str, Any],
        ttl: Optional[int] = None
    ) -> bool:
        """Salva estado da conversa."""
        try:
            key = f"{self.conversation_prefix}{case_id}"
            
            # Adicionar metadados
            state["_metadata"] = {
                "case_id": case_id,
                "updated_at": datetime.now().isoformat(),
                "version": "1.0"
            }
            
            return await redis_service.set_json(
                key, 
                state, 
                ttl or self.default_ttl
            )
            
        except Exception as e:
            logger.error(f"Erro ao salvar conversa {case_id}: {e}")
            return False
    
    async def get_conversation_state(self, case_id: str) -> Optional[Dict[str, Any]]:
        """Recupera estado da conversa."""
        try:
            key = f"{self.conversation_prefix}{case_id}"
            state = await redis_service.get_json(key)
            
            if state:
                # Remover metadados internos
                state.pop("_metadata", None)
                
            return state
            
        except Exception as e:
            logger.error(f"Erro ao recuperar conversa {case_id}: {e}")
            return None
    
    async def delete_conversation_state(self, case_id: str) -> bool:
        """Remove estado da conversa."""
        try:
            key = f"{self.conversation_prefix}{case_id}"
            return await redis_service.delete(key)
            
        except Exception as e:
            logger.error(f"Erro ao deletar conversa {case_id}: {e}")
            return False
    
    async def conversation_exists(self, case_id: str) -> bool:
        """Verifica se conversa existe."""
        key = f"{self.conversation_prefix}{case_id}"
        return await redis_service.exists(key)
    
    async def extend_conversation_ttl(self, case_id: str, ttl: int) -> bool:
        """Estende TTL da conversa."""
        key = f"{self.conversation_prefix}{case_id}"
        return await redis_service.set_ttl(key, ttl)
    
    async def list_active_conversations(self) -> List[Dict[str, Any]]:
        """Lista todas as conversas ativas."""
        try:
            pattern = f"{self.conversation_prefix}*"
            keys = await redis_service.get_keys_pattern(pattern)
            
            conversations = []
            for key in keys:
                case_id = key.replace(self.conversation_prefix, "")
                state = await redis_service.get_json(key)
                
                if state:
                    metadata = state.get("_metadata", {})
                    conversations.append({
                        "case_id": case_id,
                        "updated_at": metadata.get("updated_at"),
                        "ttl": await redis_service.get_ttl(key)
                    })
            
            return conversations
            
        except Exception as e:
            logger.error(f"Erro ao listar conversas: {e}")
            return []
    
    # ========== ORQUESTRAÇÕES ==========
    
    async def save_orchestration_state(
        self, 
        case_id: str, 
        state: Dict[str, Any],
        ttl: Optional[int] = None
    ) -> bool:
        """Salva estado da orquestração."""
        try:
            key = f"{self.orchestration_prefix}{case_id}"
            
            # Adicionar metadados
            state["_metadata"] = {
                "case_id": case_id,
                "updated_at": datetime.now().isoformat(),
                "version": "1.0"
            }
            
            return await redis_service.set_json(
                key, 
                state, 
                ttl or self.default_ttl
            )
            
        except Exception as e:
            logger.error(f"Erro ao salvar orquestração {case_id}: {e}")
            return False
    
    async def get_orchestration_state(self, case_id: str) -> Optional[Dict[str, Any]]:
        """Recupera estado da orquestração."""
        try:
            key = f"{self.orchestration_prefix}{case_id}"
            state = await redis_service.get_json(key)
            
            if state:
                # Remover metadados internos
                state.pop("_metadata", None)
                
            return state
            
        except Exception as e:
            logger.error(f"Erro ao recuperar orquestração {case_id}: {e}")
            return None
    
    async def delete_orchestration_state(self, case_id: str) -> bool:
        """Remove estado da orquestração."""
        try:
            key = f"{self.orchestration_prefix}{case_id}"
            return await redis_service.delete(key)
            
        except Exception as e:
            logger.error(f"Erro ao deletar orquestração {case_id}: {e}")
            return False
    
    # ========== UTILITÁRIOS ==========
    
    async def cleanup_expired_conversations(self) -> Dict[str, int]:
        """Remove conversas expiradas."""
        try:
            conv_pattern = f"{self.conversation_prefix}*"
            orch_pattern = f"{self.orchestration_prefix}*"
            
            conv_cleaned = await redis_service.cleanup_expired(conv_pattern)
            orch_cleaned = await redis_service.cleanup_expired(orch_pattern)
            
            return {
                "conversations_cleaned": conv_cleaned,
                "orchestrations_cleaned": orch_cleaned,
                "total_cleaned": conv_cleaned + orch_cleaned
            }
            
        except Exception as e:
            logger.error(f"Erro na limpeza: {e}")
            return {"conversations_cleaned": 0, "orchestrations_cleaned": 0, "total_cleaned": 0}
    
    async def get_system_stats(self) -> Dict[str, Any]:
        """Obtém estatísticas do sistema."""
        try:
            conv_pattern = f"{self.conversation_prefix}*"
            orch_pattern = f"{self.orchestration_prefix}*"
            
            conv_keys = await redis_service.get_keys_pattern(conv_pattern)
            orch_keys = await redis_service.get_keys_pattern(orch_pattern)
            
            redis_health = await redis_service.health_check()
            
            return {
                "active_conversations": len(conv_keys),
                "active_orchestrations": len(orch_keys),
                "redis_health": redis_health,
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Erro ao obter estatísticas: {e}")
            return {}

# Instância global
conversation_state_manager = ConversationStateManager()
```

### **Dia 9-10: Migração dos Serviços**

#### **1. Migração do IntelligentInterviewerService**
```python
# backend/services/intelligent_interviewer_service.py
# Substituir self.active_conversations por Redis

class IntelligentInterviewerService:
    def __init__(self):
        # REMOVER: self.active_conversations = {}
        self.state_manager = conversation_state_manager
        # ... resto do código
    
    async def start_conversation(self, user_id: str) -> Tuple[str, str]:
        """Inicia nova conversa - MIGRADO PARA REDIS"""
        case_id = str(uuid.uuid4())
        
        # Estado inicial
        initial_state = {
            "user_id": user_id,
            "messages": [],
            "context": {},
            "complexity_level": "unknown",
            "confidence_score": 0.0,
            "status": "active",
            "created_at": datetime.now().isoformat()
        }
        
        # Salvar no Redis
        await self.state_manager.save_conversation_state(case_id, initial_state)
        
        # Gerar primeira mensagem
        first_message = await self._generate_first_message()
        
        # Atualizar com primeira mensagem
        initial_state["messages"].append({
            "role": "assistant",
            "content": first_message,
            "timestamp": datetime.now().isoformat()
        })
        
        await self.state_manager.save_conversation_state(case_id, initial_state)
        
        return case_id, first_message
    
    async def continue_conversation(self, case_id: str, user_message: str) -> Tuple[str, bool]:
        """Continua conversa - MIGRADO PARA REDIS"""
        # Recuperar estado do Redis
        state = await self.state_manager.get_conversation_state(case_id)
        if not state:
            raise ValueError(f"Conversa {case_id} não encontrada")
        
        # Adicionar mensagem do usuário
        state["messages"].append({
            "role": "user",
            "content": user_message,
            "timestamp": datetime.now().isoformat()
        })
        
        # Processar resposta
        ai_response, is_complete = await self._process_user_message(state, user_message)
        
        # Adicionar resposta da IA
        state["messages"].append({
            "role": "assistant",
            "content": ai_response,
            "timestamp": datetime.now().isoformat()
        })
        
        # Atualizar estado
        state["updated_at"] = datetime.now().isoformat()
        if is_complete:
            state["status"] = "completed"
        
        # Salvar no Redis
        await self.state_manager.save_conversation_state(case_id, state)
        
        return ai_response, is_complete
    
    async def get_conversation_status(self, case_id: str) -> Optional[Dict]:
        """Obtém status da conversa - MIGRADO PARA REDIS"""
        state = await self.state_manager.get_conversation_state(case_id)
        if not state:
            return None
        
        return {
            "case_id": case_id,
            "status": state.get("status", "unknown"),
            "complexity_level": state.get("complexity_level", "unknown"),
            "confidence_score": state.get("confidence_score", 0.0),
            "message_count": len(state.get("messages", [])),
            "created_at": state.get("created_at"),
            "updated_at": state.get("updated_at")
        }
    
    def cleanup_conversation(self, case_id: str):
        """Remove conversa - MIGRADO PARA REDIS"""
        # Será executado de forma assíncrona
        asyncio.create_task(
            self.state_manager.delete_conversation_state(case_id)
        )
```

#### **2. Migração do IntelligentTriageOrchestrator**
```python
# backend/services/intelligent_triage_orchestrator.py
# Substituir self.active_orchestrations por Redis

class IntelligentTriageOrchestrator:
    def __init__(self):
        # REMOVER: self.active_orchestrations = {}
        self.state_manager = conversation_state_manager
        # ... resto do código
    
    async def start_intelligent_triage(self, user_id: str) -> Dict[str, str]:
        """Inicia triagem - MIGRADO PARA REDIS"""
        case_id, first_message = await self.interviewer.start_conversation(user_id)
        
        # Estado inicial da orquestração
        orchestration_state = {
            "user_id": user_id,
            "started_at": time.time(),
            "status": "interviewing",
            "flow_type": "unknown",
            "created_at": datetime.now().isoformat()
        }
        
        # Salvar no Redis
        await self.state_manager.save_orchestration_state(case_id, orchestration_state)
        
        return {
            "case_id": case_id,
            "message": first_message,
            "status": "active"
        }
    
    async def continue_intelligent_triage(self, case_id: str, user_message: str) -> Dict[str, Any]:
        """Continua triagem - MIGRADO PARA REDIS"""
        # Recuperar estado do Redis
        orchestration = await self.state_manager.get_orchestration_state(case_id)
        if not orchestration:
            raise ValueError(f"Orquestração {case_id} não encontrada")
        
        # ... resto da lógica permanece igual
        
        # Salvar estado atualizado
        await self.state_manager.save_orchestration_state(case_id, orchestration)
        
        return response
    
    async def get_orchestration_status(self, case_id: str) -> Optional[Dict]:
        """Obtém status - MIGRADO PARA REDIS"""
        orchestration = await self.state_manager.get_orchestration_state(case_id)
        if not orchestration:
            return None
        
        # ... resto da lógica
        
        return status_data
    
    def cleanup_orchestration(self, case_id: str):
        """Remove orquestração - MIGRADO PARA REDIS"""
        asyncio.create_task(
            self.state_manager.delete_orchestration_state(case_id)
        )
```

### **Dia 11-12: Testes e Validação**

#### **1. Testes de Persistência**
```python
# tests/test_redis_persistence.py
import pytest
import asyncio
from backend.services.conversation_state_manager import conversation_state_manager
from backend.services.intelligent_triage_orchestrator import intelligent_triage_orchestrator

@pytest.mark.asyncio
async def test_conversation_persistence():
    """Testa persistência de conversas."""
    # Iniciar conversa
    result = await intelligent_triage_orchestrator.start_intelligent_triage("test_user")
    case_id = result["case_id"]
    
    # Verificar se foi salvo no Redis
    state = await conversation_state_manager.get_conversation_state(case_id)
    assert state is not None
    assert state["user_id"] == "test_user"
    
    # Continuar conversa
    await intelligent_triage_orchestrator.continue_intelligent_triage(
        case_id, "Mensagem de teste"
    )
    
    # Verificar se foi atualizado
    updated_state = await conversation_state_manager.get_conversation_state(case_id)
    assert len(updated_state["messages"]) > 0
    
    # Cleanup
    await conversation_state_manager.delete_conversation_state(case_id)

@pytest.mark.asyncio
async def test_server_restart_simulation():
    """Simula restart do servidor."""
    # Criar conversa
    result = await intelligent_triage_orchestrator.start_intelligent_triage("test_user")
    case_id = result["case_id"]
    
    # Simular "restart" criando nova instância
    new_orchestrator = IntelligentTriageOrchestrator()
    
    # Verificar se consegue recuperar estado
    status = await new_orchestrator.get_orchestration_status(case_id)
    assert status is not None
    assert status["status"] == "interviewing"
    
    # Cleanup
    await conversation_state_manager.delete_conversation_state(case_id)

@pytest.mark.asyncio
async def test_ttl_functionality():
    """Testa TTL das conversas."""
    # Criar conversa com TTL curto
    case_id = "test_ttl_case"
    state = {"test": "data"}
    
    await conversation_state_manager.save_conversation_state(case_id, state, ttl=2)
    
    # Verificar se existe
    assert await conversation_state_manager.conversation_exists(case_id)
    
    # Aguardar TTL
    await asyncio.sleep(3)
    
    # Verificar se foi removido
    assert not await conversation_state_manager.conversation_exists(case_id)
```

#### **2. Script de Migração**
```python
# scripts/migrate_to_redis.py
import asyncio
import json
from backend.services.conversation_state_manager import conversation_state_manager

async def migrate_existing_conversations():
    """Migra conversas existentes para Redis."""
    print("🔄 Iniciando migração para Redis...")
    
    # Se houver conversas em memória, migrar aqui
    # Este é um exemplo - ajustar conforme necessário
    
    existing_conversations = {}  # Carregar de onde estiver
    
    migrated_count = 0
    for case_id, state in existing_conversations.items():
        success = await conversation_state_manager.save_conversation_state(
            case_id, state
        )
        if success:
            migrated_count += 1
            print(f"✅ Migrado: {case_id}")
        else:
            print(f"❌ Erro ao migrar: {case_id}")
    
    print(f"🎉 Migração concluída: {migrated_count} conversas migradas")

if __name__ == "__main__":
    asyncio.run(migrate_existing_conversations())
```

### **Dia 13-14: Documentação e Deploy**

#### **1. Atualização do Docker Compose**
```bash
# Iniciar Redis
docker-compose up -d redis

# Verificar saúde
docker-compose exec redis redis-cli ping

# Monitorar logs
docker-compose logs -f redis
```

#### **2. Health Check Endpoint**
```python
# backend/routes/health_routes.py
@router.get("/health/redis")
async def redis_health():
    """Verifica saúde do Redis."""
    health = await redis_service.health_check()
    
    if health["status"] == "healthy":
        return health
    else:
        raise HTTPException(status_code=503, detail=health)
```

## 🎯 **Critérios de Sucesso Sprint 1**

- [ ] ✅ Redis rodando em Docker
- [ ] ✅ Conversas persistem após restart
- [ ] ✅ TTL funciona corretamente
- [ ] ✅ Múltiplas instâncias sincronizam
- [ ] ✅ Testes passando
- [ ] ✅ Documentação atualizada
- [ ] ✅ Health checks funcionando
- [ ] ✅ Performance mantida ou melhorada

**Resultado esperado**: Sistema 100% resiliente com persistência garantida e escalabilidade horizontal habilitada. 