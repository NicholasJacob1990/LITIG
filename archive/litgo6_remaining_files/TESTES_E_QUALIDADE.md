# 🧪 Testes e Qualidade - LITGO5

## 🎯 Estratégia de Testes

O LITGO5 implementa uma estratégia de testes em múltiplas camadas para garantir qualidade e confiabilidade do sistema.

## 📊 Pirâmide de Testes

```
         /\
        /E2E\        (5%)  - Testes End-to-End
       /------\
      /Integr. \     (20%) - Testes de Integração
     /----------\
    / Unitários  \   (75%) - Testes Unitários
   /--------------\
```

## 🔧 Testes Backend (Python)

### Estrutura de Testes

```
backend/tests/
├── unit/                    # Testes unitários
│   ├── test_algorithm.py    # Testes do algoritmo
│   ├── test_triage.py       # Testes de triagem
│   ├── test_auth.py         # Testes de autenticação
│   └── test_services.py     # Testes de serviços
│
├── integration/             # Testes de integração
│   ├── test_api.py          # Testes de endpoints
│   ├── test_database.py     # Testes de banco
│   ├── test_docusign.py     # Testes DocuSign
│   └── test_celery.py       # Testes assíncronos
│
├── e2e/                     # Testes end-to-end
│   └── test_user_flow.py    # Fluxo completo
│
├── conftest.py              # Fixtures pytest
└── test_data/               # Dados de teste
```

### Executar Testes Backend

```bash
# Todos os testes
python -m pytest tests/ -v

# Com coverage
python -m pytest tests/ -v --cov=backend --cov-report=html

# Apenas unitários
python -m pytest tests/unit/ -v

# Apenas integração
python -m pytest tests/integration/ -v

# Teste específico
python -m pytest tests/unit/test_algorithm.py::test_match_calculation -v
```

### Exemplo de Teste Unitário

```python
# tests/unit/test_algorithm.py
import pytest
from backend.algoritmo_match import MatchmakingAlgorithm, Case, Lawyer

class TestMatchAlgorithm:
    @pytest.fixture
    def algorithm(self):
        return MatchmakingAlgorithm()
    
    @pytest.fixture
    def sample_case(self):
        return Case(
            id="test-case-1",
            area="Trabalhista",
            subarea="Rescisão",
            urgency_h=48,
            coords=(-23.5505, -46.6333),
            summary_embedding=np.random.rand(384)
        )
    
    def test_match_calculation(self, algorithm, sample_case):
        # Arrange
        lawyers = create_test_lawyers()
        
        # Act
        results = algorithm.rank(sample_case, lawyers, top_n=5)
        
        # Assert
        assert len(results) <= 5
        assert all(l.scores['fair'] >= 0 for l in results)
        assert results[0].scores['fair'] >= results[-1].scores['fair']
```

### Exemplo de Teste de Integração

```python
# tests/integration/test_api.py
import pytest
from httpx import AsyncClient
from backend.main import app

class TestTriageAPI:
    @pytest.mark.asyncio
    async def test_triage_endpoint(self, async_client: AsyncClient):
        # Arrange
        payload = {
            "texto_cliente": "Fui demitido sem justa causa",
            "coords": [-23.5505, -46.6333]
        }
        
        # Act
        response = await async_client.post(
            "/api/triage",
            json=payload,
            headers={"Authorization": "Bearer test-token"}
        )
        
        # Assert
        assert response.status_code == 202
        assert "task_id" in response.json()
```

## 🎨 Testes Frontend (React Native)

### Estrutura de Testes

```
__tests__/
├── components/              # Testes de componentes
│   ├── LawyerMatchCard.test.tsx
│   ├── CaseCard.test.tsx
│   └── atoms/
│       └── Badge.test.tsx
│
├── screens/                 # Testes de telas
│   ├── Triagem.test.tsx
│   ├── MatchesPage.test.tsx
│   └── CaseDetail.test.tsx
│
├── hooks/                   # Testes de hooks
│   ├── useTaskPolling.test.ts
│   └── useAuth.test.ts
│
├── services/               # Testes de serviços
│   └── api.test.ts
│
└── setup.ts               # Configuração Jest
```

### Executar Testes Frontend

```bash
# Todos os testes
npm test

# Com coverage
npm test -- --coverage

# Watch mode
npm test -- --watch

# Teste específico
npm test LawyerMatchCard
```

### Exemplo de Teste de Componente

```tsx
// __tests__/components/LawyerMatchCard.test.tsx
import { render, fireEvent } from '@testing-library/react-native';
import { LawyerMatchCard } from '@/components/LawyerMatchCard';

describe('LawyerMatchCard', () => {
  const mockLawyer = {
    id: 'lw-001',
    nome: 'Dr. João Silva',
    score: 0.95,
    taxa_sucesso: 0.85,
    distance_km: 2.5
  };

  it('should render lawyer information correctly', () => {
    const { getByText } = render(
      <LawyerMatchCard lawyer={mockLawyer} />
    );
    
    expect(getByText('Dr. João Silva')).toBeTruthy();
    expect(getByText('95%')).toBeTruthy();
    expect(getByText('2.5 km')).toBeTruthy();
  });

  it('should call onPress when clicked', () => {
    const onPress = jest.fn();
    const { getByTestId } = render(
      <LawyerMatchCard 
        lawyer={mockLawyer} 
        onPress={onPress}
      />
    );
    
    fireEvent.press(getByTestId('lawyer-card'));
    expect(onPress).toHaveBeenCalledWith(mockLawyer);
  });
});
```

## 🔍 Qualidade de Código

### Linting e Formatação

#### Backend (Python)
```bash
# Linting com flake8
flake8 backend/ --max-line-length=88

# Formatação com black
black backend/

# Type checking com mypy
mypy backend/

# Import sorting com isort
isort backend/
```

#### Frontend (TypeScript)
```bash
# Linting com ESLint
npm run lint

# Formatação com Prettier
npm run format

# Type checking
npm run type-check
```

### Pre-commit Hooks

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/psf/black
    rev: 23.3.0
    hooks:
      - id: black
        language_version: python3.10

  - repo: https://github.com/pycqa/flake8
    rev: 6.0.0
    hooks:
      - id: flake8

  - repo: https://github.com/pre-commit/mirrors-eslint
    rev: v8.42.0
    hooks:
      - id: eslint
        files: \.[jt]sx?$
```

## 📈 Métricas de Qualidade

### Coverage Mínimo
- **Backend**: 80%
- **Frontend**: 70%
- **Crítico**: 90% (algoritmo, auth)

### Complexidade Ciclomática
- **Máximo por função**: 10
- **Máximo por classe**: 20

### Duplicação de Código
- **Máximo permitido**: 5%

## 🚨 Testes de Performance

### Load Testing (Locust)

```python
# locustfile.py
from locust import HttpUser, task, between

class LitgoUser(HttpUser):
    wait_time = between(1, 3)
    
    @task
    def triage_flow(self):
        # 1. Criar triagem
        response = self.client.post("/api/triage", json={
            "texto_cliente": "Caso de teste",
            "coords": [-23.5505, -46.6333]
        })
        task_id = response.json()["task_id"]
        
        # 2. Verificar status
        self.client.get(f"/api/triage/status/{task_id}")
        
        # 3. Buscar matches
        self.client.post("/api/match", json={
            "case_id": "test-case"
        })
```

### Métricas de Performance
- **Triagem**: < 3s (P95)
- **Match**: < 1s (P95)
- **API Response**: < 200ms (P95)
- **Throughput**: > 100 req/s

## 🔒 Testes de Segurança

### Checklist de Segurança
- [ ] Autenticação JWT válida
- [ ] Rate limiting funcionando
- [ ] SQL injection prevenido
- [ ] XSS protection
- [ ] CORS configurado
- [ ] Secrets não expostos
- [ ] HTTPS obrigatório

### Testes de Penetração
```bash
# OWASP ZAP
docker run -t owasp/zap2docker-stable zap-baseline.py \
  -t https://api.litgo.com

# SQLMap
sqlmap -u "https://api.litgo.com/api/match" \
  --data='{"case_id":"test"}' \
  --headers="Authorization: Bearer token"
```

## 📊 CI/CD Pipeline

### GitHub Actions Workflow

```yaml
name: Tests
on: [push, pull_request]

jobs:
  backend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.10'
      - run: |
          pip install -r backend/requirements.txt
          python -m pytest backend/tests/ -v --cov

  frontend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: |
          npm install
          npm test -- --coverage
```

## 🎯 Melhores Práticas

### 1. TDD (Test-Driven Development)
- Escrever teste antes do código
- Red → Green → Refactor

### 2. AAA Pattern
- **Arrange**: Preparar dados
- **Act**: Executar ação
- **Assert**: Verificar resultado

### 3. Test Isolation
- Cada teste independente
- Usar mocks e fixtures
- Limpar estado após teste

### 4. Naming Convention
- `test_should_<action>_when_<condition>`
- Descritivo e claro
- Em inglês

---

**Última atualização:** Janeiro 2025  
**Coverage Atual:** Backend 85% | Frontend 73%
