# 👨‍💻 Guia de Desenvolvimento - LITGO5

## 🎯 Bem-vindo ao Time LITGO5

Este guia contém tudo que você precisa saber para começar a desenvolver no projeto LITGO5, desde a configuração inicial até as práticas de desenvolvimento e deploy.

---

## 🚀 Setup Inicial Rápido

### 1. Pré-requisitos

```bash
# Verificar versões
node --version    # >= 18.0.0
python --version  # >= 3.10.0
git --version     # >= 2.30.0
docker --version  # >= 20.0.0

# Instalar ferramentas globais
npm install -g @expo/cli
npm install -g eas-cli
```

### 2. Clone e Configuração

```bash
# Clone do repositório
git clone <repository-url>
cd LITGO5

# Configurar variáveis de ambiente
cp env.example .env
# Editar .env com suas chaves (ver seção Configuração de APIs)

# Instalar dependências
npm install
cd backend && pip install -r requirements.txt
```

### 3. Executar em Desenvolvimento

```bash
# Opção 1: Docker (Recomendado)
docker-compose up --build

# Opção 2: Manual
# Terminal 1: Redis
docker run -d -p 6379:6379 redis:alpine

# Terminal 2: Backend API
cd backend
uvicorn backend.main:app --reload

# Terminal 3: Celery Worker
cd backend
celery -A backend.celery_app worker --loglevel=info

# Terminal 4: Frontend
cd ..
npx expo start
```

### 4. Verificar Funcionamento

```bash
# Testar API
curl http://localhost:8000/

# Testar Redis
redis-cli ping

# Testar Worker
celery -A backend.celery_app inspect ping
```

---

## 🔧 Configuração de APIs e Serviços

### Supabase Setup

1. **Criar Projeto**
   ```bash
   # Acesse https://supabase.com/dashboard
   # Crie novo projeto
   # Copie URL e chaves para .env
   ```

2. **Configurar Banco**
   ```sql
   -- No SQL Editor do Supabase
   CREATE EXTENSION IF NOT EXISTS vector;
   
   -- Executar migrações
   -- Ver: supabase/migrations/
   ```

3. **Configurar Autenticação**
   ```bash
   # Authentication > Settings
   # Habilitar email/password
   # Configurar redirect URLs para Expo
   ```

### Anthropic Claude Setup

```bash
# 1. Criar conta em https://console.anthropic.com/
# 2. Gerar API key
# 3. Adicionar ao .env
ANTHROPIC_API_KEY=sk-ant-api03-your-key-here

# 4. Testar
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "content-type: application/json" \
  -d '{"model":"claude-3-5-sonnet-20240620","max_tokens":100,"messages":[{"role":"user","content":"Hello"}]}'
```

### OpenAI Setup

```bash
# 1. Criar conta em https://platform.openai.com/
# 2. Gerar API key
# 3. Adicionar ao .env
OPENAI_API_KEY=sk-your-openai-key-here

# 4. Testar
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer $OPENAI_API_KEY"
```

### Redis Setup

```bash
# Local (desenvolvimento)
docker run -d -p 6379:6379 redis:alpine

# Produção - Redis Cloud
# 1. Criar conta em https://redis.com/
# 2. Criar database
# 3. Copiar connection string para .env
REDIS_URL=redis://username:password@host:port/db
```

---

## 📁 Estrutura do Projeto

### Visão Geral
```
LITGO5/
├── app/                    # Frontend React Native
├── backend/                # Backend FastAPI
├── components/             # Componentes reutilizáveis
├── hooks/                  # Custom hooks
├── lib/                    # Utilitários e serviços
├── supabase/              # Migrações e configs
├── tests/                 # Testes automatizados
├── docs/                  # Documentação
├── docker-compose.yml     # Orquestração local
└── package.json           # Dependências frontend
```

### Backend (`backend/`)
```python
backend/
├── main.py                # Aplicação FastAPI principal
├── routes.py              # Definição de endpoints
├── models.py              # DTOs e schemas Pydantic
├── services.py            # Lógica de negócio
├── auth.py                # Autenticação JWT
├── algoritmo_match.py     # Algoritmo de ranking (CORE)
├── triage_service.py      # Serviço de triagem IA
├── explanation_service.py # Serviço de explicações
├── embedding_service.py   # Serviço de embeddings
├── celery_app.py          # Configuração Celery
├── tasks.py               # Tarefas assíncronas
├── requirements.txt       # Dependências Python
├── Dockerfile             # Container backend
└── jobs/
    └── datajud_sync.py    # Job sincronização DataJud
```

### Frontend (`app/`)
```typescript
app/
├── (auth)/                # Fluxo de autenticação
│   ├── index.tsx         # Login
│   ├── register-client.tsx
│   └── register-lawyer.tsx
├── (tabs)/               # Navegação principal
│   ├── index.tsx         # Home
│   ├── cases.tsx         # Meus casos
│   ├── advogados.tsx     # Lista advogados
│   └── profile.tsx       # Perfil
├── triagem.tsx           # Triagem inteligente
├── MatchesPage.tsx       # Resultados match
├── chat-triagem.tsx      # Chat com IA
└── +not-found.tsx        # 404
```

### Componentes (`components/`)
```typescript
components/
├── atoms/                # Componentes básicos
│   ├── Avatar.tsx
│   ├── Badge.tsx
│   └── ProgressBar.tsx
├── molecules/            # Componentes compostos
│   ├── CaseHeader.tsx
│   ├── DocumentItem.tsx
│   └── StatusProgressBar.tsx
├── organisms/            # Componentes complexos
│   ├── CaseCard.tsx
│   ├── PreAnalysisCard.tsx
│   └── SupportRatingModal.tsx
├── layout/               # Layout components
│   ├── TopBar.tsx
│   └── FabNewCase.tsx
└── LawyerMatchCard.tsx   # Componente principal de match
```

---

## 🔄 Fluxo de Desenvolvimento

### 1. Criando Nova Feature

```bash
# 1. Criar branch
git checkout -b feature/nova-funcionalidade

# 2. Desenvolver
# - Backend: adicionar endpoint em routes.py
# - Frontend: criar componente/tela
# - Testes: adicionar casos de teste

# 3. Testar localmente
npm run lint
cd backend && python -m pytest tests/

# 4. Commit e push
git add .
git commit -m "feat: adicionar nova funcionalidade"
git push origin feature/nova-funcionalidade

# 5. Criar Pull Request
```

### 2. Adicionando Endpoint Backend

```python
# 1. Definir DTO em models.py
class NovaFeatureRequest(BaseModel):
    campo1: str
    campo2: int

class NovaFeatureResponse(BaseModel):
    resultado: str
    dados: List[dict]

# 2. Implementar lógica em services.py
async def processar_nova_feature(req: NovaFeatureRequest) -> NovaFeatureResponse:
    # Lógica de negócio
    resultado = await algum_processamento(req.campo1)
    return NovaFeatureResponse(resultado=resultado, dados=[])

# 3. Criar endpoint em routes.py
@router.post("/nova-feature", response_model=NovaFeatureResponse)
@limiter.limit("30/minute")
async def http_nova_feature(
    req: NovaFeatureRequest, 
    user: dict = Depends(get_current_user)
):
    try:
        resultado = await processar_nova_feature(req)
        return resultado
    except Exception as e:
        raise HTTPException(500, f"Erro: {e}")

# 4. Adicionar teste em tests/
def test_nova_feature_success(client, mock_auth):
    response = client.post("/api/nova-feature", json={
        "campo1": "teste",
        "campo2": 123
    })
    assert response.status_code == 200
```

### 3. Criando Componente Frontend

```typescript
// 1. Criar componente em components/
// components/NovoComponente.tsx
import React from 'react';
import { View, Text, StyleSheet } from 'react-native';

interface NovoComponenteProps {
  titulo: string;
  dados: any[];
  onPress?: () => void;
}

export default function NovoComponente({ titulo, dados, onPress }: NovoComponenteProps) {
  return (
    <View style={styles.container}>
      <Text style={styles.titulo}>{titulo}</Text>
      {dados.map((item, index) => (
        <Text key={index}>{item.nome}</Text>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    padding: 16,
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
  },
  titulo: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 12,
  },
});

// 2. Adicionar serviço em lib/services/api.ts
export async function chamarNovaFeature(dados: any) {
  const headers = await getAuthHeaders();
  const response = await fetch(`${API_URL}/nova-feature`, {
    method: 'POST',
    headers,
    body: JSON.stringify(dados),
  });
  
  if (!response.ok) {
    throw new Error('Erro na API');
  }
  
  return response.json();
}

// 3. Usar em tela
// app/nova-tela.tsx
import { chamarNovaFeature } from '@/lib/services/api';
import NovoComponente from '@/components/NovoComponente';

export default function NovaTela() {
  const [dados, setDados] = useState([]);
  
  useEffect(() => {
    async function carregarDados() {
      try {
        const resultado = await chamarNovaFeature({ campo1: 'valor' });
        setDados(resultado.dados);
      } catch (error) {
        console.error('Erro:', error);
      }
    }
    
    carregarDados();
  }, []);
  
  return (
    <NovoComponente 
      titulo="Minha Nova Feature"
      dados={dados}
      onPress={() => console.log('Clicado')}
    />
  );
}
```

---

## 🧪 Testes e Qualidade

### Testes Backend

```python
# Estrutura de testes
tests/
├── conftest.py           # Configuração pytest
├── test_auth.py          # Testes autenticação
├── test_match.py         # Testes algoritmo match
├── test_triage.py        # Testes triagem
├── test_explain.py       # Testes explicações
└── integration/          # Testes integração
    └── test_full_flow.py

# Executar testes
cd backend

# Todos os testes
TESTING=true python -m pytest tests/ -v

# Testes específicos
python -m pytest tests/test_match.py -v

# Com cobertura
python -m pytest tests/ --cov=backend --cov-report=html

# Testes de integração
python -m pytest tests/integration/ -v
```

### Testes Frontend

```bash
# Linting
npm run lint

# Verificar tipos TypeScript
npx tsc --noEmit

# Testes unitários (se configurado)
npm test

# Testes E2E (futuro)
npx playwright test
```

### Configuração de Teste

```python
# tests/conftest.py
import pytest
import os
from fastapi.testclient import TestClient
from unittest.mock import patch

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
    def mock_get_current_user():
        return {"id": "test-user", "role": "authenticated"}
    return mock_get_current_user

@pytest.fixture
def mock_supabase():
    with patch('backend.services.supabase') as mock:
        yield mock
```

---

## 🔧 Debugging e Troubleshooting

### Logs e Monitoramento

```python
# Configurar logging
import logging

# Logger estruturado
logger = logging.getLogger(__name__)
logger.info("Processando triagem", extra={
    "user_id": user.id,
    "case_id": case.id,
    "timestamp": time.time()
})

# Logs de debug
logger.debug("Dados recebidos", extra={"payload": payload})
```

### Debugging Backend

```bash
# Logs da API
docker-compose logs -f api

# Logs do Worker
docker-compose logs -f worker

# Debug Python
import pdb; pdb.set_trace()  # Breakpoint

# Profiling
python -m cProfile -o profile.stats script.py
```

### Debugging Frontend

```typescript
// Console logs estruturados
console.log('API Response:', {
  endpoint: '/api/triage',
  status: response.status,
  data: response.data,
  timestamp: new Date().toISOString()
});

// React DevTools
// Instalar extensão no browser

// Flipper (para React Native)
// Configurar Flipper para debugging avançado
```

### Problemas Comuns

#### 1. API não responde
```bash
# Verificar se serviços estão rodando
docker-compose ps

# Verificar logs
docker-compose logs api

# Testar conectividade
curl http://localhost:8000/

# Verificar variáveis de ambiente
cat .env | grep -E "(SUPABASE|REDIS)"
```

#### 2. Worker Celery não processa
```bash
# Verificar Redis
redis-cli ping

# Verificar worker
celery -A backend.celery_app inspect ping

# Logs detalhados
celery -A backend.celery_app worker --loglevel=debug
```

#### 3. Frontend não conecta
```bash
# Verificar URL da API
echo $EXPO_PUBLIC_API_URL

# Limpar cache Expo
npx expo start --clear

# Verificar Metro bundler
npx expo start --verbose
```

---

## 🚀 Deploy e Produção

### Deploy Backend

```bash
# 1. Configurar variáveis de produção
# Ver: CORRECOES_CRITICAS.md

# 2. Build Docker
docker build -t litgo-backend -f backend/Dockerfile .

# 3. Deploy Render/Railway
# - Conectar repositório GitHub
# - Configurar variáveis de ambiente
# - Deploy automático

# 4. Verificar saúde
curl https://api.litgo.com/
```

### Deploy Frontend

```bash
# 1. Configurar EAS
eas login
eas build:configure

# 2. Build para produção
eas build --platform all

# 3. Deploy para stores
eas submit --platform all

# 4. Deploy web (opcional)
npx expo export:web
# Upload para Vercel/Netlify
```

### Configuração de Produção

```bash
# Variáveis de ambiente produção
ENVIRONMENT=production
SUPABASE_URL=https://prod.supabase.co
ANTHROPIC_API_KEY=sk-ant-prod-key
REDIS_URL=redis://prod-redis:6379/0
FRONTEND_URL=https://app.litgo.com
CORS_ORIGINS=https://app.litgo.com
```

---

## 📋 Checklist de Desenvolvimento

### Antes de Commitar
- [ ] Código passa no linting (`npm run lint`)
- [ ] Testes passam (`pytest tests/`)
- [ ] Não há console.logs esquecidos
- [ ] Variáveis de ambiente documentadas
- [ ] Comentários em código complexo

### Antes de Pull Request
- [ ] Branch atualizada com main
- [ ] Descrição clara do que foi implementado
- [ ] Screenshots se mudança visual
- [ ] Testes adicionados para nova funcionalidade
- [ ] Documentação atualizada se necessário

### Antes de Deploy
- [ ] Testes passam em staging
- [ ] Variáveis de produção configuradas
- [ ] Backup do banco realizado
- [ ] Monitoramento ativo
- [ ] Rollback plan definido

---

## 🎯 Boas Práticas

### Código Python
```python
# ✅ Bom
async def processar_triagem(texto: str) -> TriagemResult:
    """
    Processa triagem de caso com Claude AI.
    
    Args:
        texto: Relato do cliente
        
    Returns:
        Resultado estruturado da triagem
        
    Raises:
        TriagemError: Se falha na análise
    """
    try:
        resultado = await triage_service.run_triage(texto)
        return TriagemResult(**resultado)
    except Exception as e:
        logger.error("Erro na triagem", extra={"error": str(e)})
        raise TriagemError(f"Falha na triagem: {e}")

# ❌ Ruim
def triagem(txt):
    res = claude_api_call(txt)
    return res
```

### Código TypeScript
```typescript
// ✅ Bom
interface LawyerMatchProps {
  lawyer: LawyerData;
  caseId: string;
  onSelect: (lawyerId: string) => void;
}

export default function LawyerMatch({ lawyer, caseId, onSelect }: LawyerMatchProps) {
  const [isLoading, setIsLoading] = useState(false);
  
  const handleExplain = useCallback(async () => {
    if (!caseId) return;
    
    setIsLoading(true);
    try {
      const explanation = await getExplanation(caseId, [lawyer.id]);
      // Processar explicação
    } catch (error) {
      console.error('Erro ao obter explicação:', error);
    } finally {
      setIsLoading(false);
    }
  }, [caseId, lawyer.id]);
  
  return (
    <TouchableOpacity onPress={() => onSelect(lawyer.id)}>
      {/* UI */}
    </TouchableOpacity>
  );
}

// ❌ Ruim
function LawyerMatch(props: any) {
  return <View>{props.lawyer.name}</View>;
}
```

### Git Commits
```bash
# ✅ Bom
feat: adicionar endpoint de explicações IA
fix: corrigir rate limiter nos testes
docs: atualizar guia de desenvolvimento
refactor: simplificar lógica de matching

# ❌ Ruim
update
fix bug
changes
wip
```

---

## 📚 Recursos e Links

### Documentação
- [FastAPI Docs](https://fastapi.tiangolo.com/)
- [React Native Docs](https://reactnative.dev/)
- [Expo Docs](https://docs.expo.dev/)
- [Supabase Docs](https://supabase.com/docs)
- [Celery Docs](https://docs.celeryproject.org/)

### Ferramentas
- [Postman Collection](./postman/LITGO5.json) - Testes de API
- [VS Code Extensions](./vscode/extensions.json) - Extensões recomendadas
- [Database Schema](./docs/database-schema.md) - Esquema do banco

### Comunidade
- **Slack**: #litgo5-dev
- **GitHub Issues**: Para bugs e features
- **Wiki**: Documentação técnica detalhada

---

**Última atualização:** Janeiro 2025  
**Mantenedores:** Time LITGO5  
**Próxima revisão:** Mensal 