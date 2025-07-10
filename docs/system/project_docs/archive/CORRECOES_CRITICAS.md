# 🚨 Correções Críticas - LITGO5

## 📋 Status das Correções

Este documento lista as correções críticas identificadas no code review e suas implementações.

---

## 🔴 CRÍTICO - Correção Imediata Necessária

### 1. ❌ Erro Rate Limiter nos Testes

**Problema Identificado:**
```bash
AttributeError: 'APIRouter' object has no attribute '__name__'
```

**Localização:** `backend/main.py:46`

**Causa:** Aplicação incorreta do rate limiter no router inteiro:
```python
# ❌ INCORRETO
limiter.limit("60/minute")(api_router)
```

**Solução Implementada:**
```python
# ✅ CORRETO - Aplicar nas rotas individuais
# backend/routes.py

from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

@router.post("/triage")
@limiter.limit("60/minute")
async def http_triage_case(payload: TriageRequest, user: dict = Depends(get_current_user)):
    # ...

@router.post("/explain")  
@limiter.limit("30/minute")  # Limite menor para endpoint mais caro
async def http_explain_matches(req: ExplainRequest, user: dict = Depends(get_current_user)):
    # ...
```

**Status:** ⏳ Pendente de implementação

---

### 2. ❌ Arquivo .env.example Ausente

**Problema:** Desenvolvedores não sabem quais variáveis configurar

**Solução:** ✅ Criado arquivo `env.example` com:
- Todas as variáveis necessárias
- Comentários explicativos
- Instruções de configuração
- Exemplos de valores

**Status:** ✅ Implementado

---

## 🔶 ALTO - Implementar Antes de Produção

### 3. ⚠️ Configurações de Produção Incompletas

**Problema:** CORS permite localhost em produção

**Localização:** `backend/main.py:23-30`

**Solução:**
```python
# backend/main.py
import os

# ✅ Configuração dinâmica baseada no ambiente
if os.getenv("ENVIRONMENT") == "production":
    origins = [
        os.getenv("FRONTEND_URL", "https://app.litgo.com"),
    ]
else:
    origins = [
        "http://localhost",
        "http://localhost:8081",
        "http://localhost:3000",
    ]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],  # Específico em prod
    allow_headers=["*"],
)
```

**Status:** ⏳ Pendente de implementação

---

### 4. ⚠️ Job DataJud Simulado

**Problema:** API real do CNJ não implementada

**Localização:** `backend/jobs/datajud_sync.py:24-45`

**Solução:**
```python
def get_success_rate_for_lawyer(oab_number: str) -> float:
    """
    Consulta a API real do DataJud CNJ para obter taxa de sucesso.
    """
    if not oab_number:
        return 0.0

    try:
        # ✅ Implementação real da API DataJud
        url = "https://api-publica.datajud.cnj.jus.br/api_publica_tjpb/_search"
        payload = {
            "query": {
                "bool": {
                    "must": [
                        {"term": {"advogado.oab": oab_number}},
                        {"range": {"dataAjuizamento": {"gte": "2020-01-01"}}}
                    ]
                }
            },
            "size": 1000
        }
        
        headers = {
            "Content-Type": "application/json",
            "User-Agent": "LITGO5/1.0"
        }
        
        response = requests.post(url, json=payload, headers=headers, timeout=30)
        
        if response.status_code != 200:
            logger.warning(f"DataJud API returned {response.status_code} for OAB {oab_number}")
            return 0.0
            
        data = response.json()
        hits = data.get("hits", {}).get("hits", [])
        
        if not hits:
            return 0.0
            
        # Calcular taxa de sucesso baseada nos resultados
        victories = sum(1 for hit in hits 
                       if hit["_source"].get("classeProcessual") in ["PROCEDENTE", "PARCIALMENTE_PROCEDENTE"])
        total = len(hits)
        
        return victories / total if total > 0 else 0.0
        
    except requests.RequestException as e:
        logger.error(f"Erro ao consultar DataJud para OAB {oab_number}: {e}")
        return 0.0
    except Exception as e:
        logger.error(f"Erro inesperado no DataJud para OAB {oab_number}: {e}")
        return 0.0
```

**Status:** ⏳ Pendente de implementação

---

## 🔷 MÉDIO - Melhorias de Qualidade

### 5. 🔧 Corrigir Testes Quebrados

**Problema:** Testes não executam devido a configuração incorreta

**Solução:**
```python
# tests/conftest.py (criar arquivo)
import pytest
import os
from fastapi.testclient import TestClient

# Configurar ambiente de teste
os.environ["TESTING"] = "true"
os.environ["SUPABASE_URL"] = "https://test.supabase.co"
os.environ["SUPABASE_SERVICE_KEY"] = "test-key"

@pytest.fixture
def client():
    from backend.main import app
    return TestClient(app)

@pytest.fixture
def mock_auth():
    """Mock para autenticação em testes"""
    def mock_get_current_user():
        return {"id": "test-user-id", "role": "authenticated"}
    return mock_get_current_user
```

**Status:** ⏳ Pendente de implementação

---

### 6. 🔧 Melhorar Cobertura de Testes

**Testes Adicionais Necessários:**

```python
# tests/test_triage.py
def test_triage_endpoint_success(client, mock_auth):
    """Testa endpoint de triagem assíncrona"""
    with patch('backend.routes.get_current_user', mock_auth):
        response = client.post("/api/triage", json={
            "texto_cliente": "Fui demitido sem justa causa",
            "coords": [-23.5505, -46.6333]
        })
        assert response.status_code == 202
        assert "task_id" in response.json()

# tests/test_explain.py  
def test_explain_endpoint_success(client, mock_auth, mock_supabase):
    """Testa endpoint de explicações"""
    # Setup mocks...
    response = client.post("/api/explain", json={
        "case_id": "test-case",
        "lawyer_ids": ["lw-1", "lw-2"]
    })
    assert response.status_code == 200
    assert "explanations" in response.json()
```

**Status:** ⏳ Pendente de implementação

---

## 🔹 BAIXO - Polimento

### 7. 🧹 Limpar Warnings de Linting

**Problemas Identificados:**
```bash
app/(auth)/index.tsx:32:9 - 'width' is assigned but never used
app/(tabs)/_layout.tsx:3:65 - 'LifeBuoy' is defined but never used
app/(tabs)/_layout.tsx:3:75 - 'CheckSquare' is defined but never used
```

**Solução:**
```tsx
// app/(auth)/index.tsx
// ❌ Remover variável não utilizada
const width = Dimensions.get('window').width; // Linha 32

// app/(tabs)/_layout.tsx  
// ❌ Remover imports não utilizados
import { LifeBuoy, CheckSquare, Settings } from 'lucide-react-native';
```

**Status:** ⏳ Pendente de implementação

---

## 📋 Checklist de Implementação

### Correções Críticas
- [ ] Corrigir rate limiter nos testes
- [x] Criar arquivo .env.example
- [ ] Configurar CORS para produção
- [ ] Implementar API DataJud real

### Melhorias de Qualidade  
- [ ] Configurar testes corretamente
- [ ] Adicionar testes para /triage e /explain
- [ ] Melhorar cobertura de testes (>80%)

### Polimento
- [ ] Limpar warnings de linting
- [ ] Adicionar métricas de performance
- [ ] Implementar logging estruturado

---

## 🚀 Próximos Passos

### Implementação Imediata (Esta Sprint)
1. **Corrigir rate limiter** - Bloqueia testes
2. **Configurar CORS produção** - Segurança crítica
3. **Implementar testes básicos** - CI/CD

### Próxima Sprint
1. **API DataJud real** - Funcionalidade completa
2. **Cobertura de testes** - Qualidade
3. **Otimizações de performance** - Escalabilidade

### Backlog
1. **Monitoramento avançado** - Observabilidade
2. **Cache inteligente** - Performance
3. **A/B testing** - Produto

---

## 📞 Responsabilidades

### Backend Team
- Rate limiter fix
- CORS configuration  
- DataJud API implementation
- Tests setup

### Frontend Team
- Linting cleanup
- Error handling improvements
- Performance optimizations

### DevOps Team
- Production environment setup
- Monitoring implementation
- CI/CD pipeline

---

**Última atualização:** Janeiro 2025  
**Próxima revisão:** Após implementação das correções críticas 