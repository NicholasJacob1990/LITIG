# EPIC 2.3: Validação A/B para LTR - IMPLEMENTADO

## 📋 Resumo da Implementação

O **EPIC 2.3: Validação A/B para LTR** do Sprint 2 foi **completamente implementado**, incluindo todas as User Stories planejadas:

- ✅ **US-2.3.1**: Serviço de A/B Testing
- ✅ **US-2.3.2**: Job de retreino automático  
- ✅ **US-2.3.3**: Monitoramento de modelo

## 🏗️ Arquitetura Implementada

### 1. Serviço de A/B Testing (`backend/services/ab_testing.py`)

#### Funcionalidades Principais:
- **Distribuição de Tráfego**: Algoritmo baseado em hash consistente para distribuir usuários entre grupos
- **Análise Estatística**: Teste Z para proporções com cálculo de p-value e intervalos de confiança
- **Rollback Automático**: Detecção automática de degradação significativa (>10%) e rollback
- **Métricas Prometheus**: Exposição de métricas para monitoramento

#### Classes Implementadas:
```python
class ABTestingService:
    - create_test(config: ABTestConfig) -> bool
    - get_model_for_request(user_id: str) -> Tuple[str, str]
    - record_conversion(user_id: str, test_id: str, group: str, converted: bool)
    - analyze_test_results(test_id: str) -> ABTestResult
    - should_rollback(test_id: str) -> bool
    - rollback_test(test_id: str) -> bool
```

### 2. Job de Retreino Automático (`backend/jobs/auto_retrain.py`)

#### Componentes:
- **LTRModelTrainer**: Classe para treinar modelos Learning-to-Rank
- **ModelValidator**: Validação de modelos com métricas NDCG, MSE, R²
- **Tasks Celery**: Jobs assíncronos para retreino e limpeza

#### Fluxo de Retreino:
1. **Coleta de Dados**: Últimos 30 dias de matches e resultados
2. **Preparação**: Extração de features (T, G, Q, R, A, S, U, C)
3. **Treinamento**: RandomForestRegressor com validação
4. **Validação**: Métricas em dados dos últimos 7 dias
5. **Teste A/B**: Criação automática de teste se validação OK
6. **Rollback**: Monitoramento contínuo e rollback se necessário

### 3. Monitoramento de Modelo (`backend/services/model_monitoring.py`)

#### Funcionalidades:
- **Drift Detection**: Detecção de mudanças na distribuição das features usando KL-divergence
- **Performance Monitoring**: MSE, MAE, Correlação, NDCG
- **Anomaly Detection**: Detecção de predições anômalas (>2σ)
- **Alertas Automáticos**: Sistema de alertas com níveis (LOW, MEDIUM, HIGH, CRITICAL)

#### Métricas Monitoradas:
- **Performance**: MSE, MAE, Correlação, NDCG
- **Drift**: Score por feature e geral
- **Anomalias**: Taxa de anomalias nas predições
- **Health Score**: Score geral de saúde do modelo (0-1)

## 🗄️ Estrutura de Banco de Dados

### Tabelas Criadas (`supabase/migrations/20250705003000_create_ab_testing_tables.sql`):

```sql
-- Configurações de testes A/B
CREATE TABLE ab_tests (
    id SERIAL PRIMARY KEY,
    test_id VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(500) NOT NULL,
    control_model VARCHAR(255) NOT NULL,
    treatment_model VARCHAR(255) NOT NULL,
    traffic_split DECIMAL(3,2) NOT NULL,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    -- ... outros campos
);

-- Conversões dos testes A/B
CREATE TABLE ab_test_conversions (
    id SERIAL PRIMARY KEY,
    test_id VARCHAR(255) NOT NULL,
    user_id UUID NOT NULL,
    group_name VARCHAR(20) NOT NULL,
    converted BOOLEAN NOT NULL DEFAULT FALSE,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Alertas de monitoramento
CREATE TABLE model_alerts (
    id SERIAL PRIMARY KEY,
    alert_id VARCHAR(255) UNIQUE NOT NULL,
    model_name VARCHAR(255) NOT NULL,
    alert_type VARCHAR(100) NOT NULL,
    level VARCHAR(20) NOT NULL,
    message TEXT NOT NULL,
    metrics JSONB,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Histórico de métricas
CREATE TABLE model_metrics_history (
    id SERIAL PRIMARY KEY,
    model_name VARCHAR(255) NOT NULL,
    metric_type VARCHAR(100) NOT NULL,
    metric_value DECIMAL(10,6) NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Histórico de drift
CREATE TABLE feature_drift_history (
    id SERIAL PRIMARY KEY,
    model_name VARCHAR(255) NOT NULL,
    feature_name VARCHAR(100) NOT NULL,
    drift_score DECIMAL(10,6) NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## 📊 Métricas Prometheus

### Métricas Adicionadas (`backend/metrics.py`):

```python
# A/B Testing
ab_test_exposure_total = Counter(
    'ab_test_exposure_total',
    'Total de exposições em testes A/B',
    ['test_id', 'group']
)

ab_test_conversions_total = Counter(
    'ab_test_conversions_total', 
    'Total de conversões em testes A/B',
    ['test_id', 'group']
)

ab_test_performance_gauge = Gauge(
    'ab_test_performance_gauge',
    'Performance dos grupos em testes A/B',
    ['test_id', 'group']
)

# Monitoramento de Modelos
model_performance_gauge = Gauge(
    'model_performance_gauge',
    'Métricas de performance dos modelos',
    ['model_type', 'metric']
)

model_drift_gauge = Gauge(
    'model_drift_gauge',
    'Score de drift das features dos modelos',
    ['model_type', 'feature']
)

model_retrain_total = Counter(
    'model_retrain_total',
    'Total de retreinos de modelo',
    ['trigger']
)

model_alert_total = Counter(
    'model_alert_total',
    'Total de alertas de modelo',
    ['model_type', 'alert_type', 'level']
)
```

## 🔄 Jobs Celery

### Agendamento (`backend/celery_app.py`):

```python
'auto-retrain-ltr': {
    'task': 'backend.jobs.auto_retrain.auto_retrain_task',
    'schedule': crontab(day_of_week=0, hour=2, minute=0),  # Domingo às 2h
},
'monitor-ab-tests': {
    'task': 'backend.jobs.auto_retrain.monitor_ab_tests', 
    'schedule': crontab(minute='*/15'),  # A cada 15 minutos
},
'cleanup-old-models': {
    'task': 'backend.jobs.auto_retrain.cleanup_old_models',
    'schedule': crontab(day_of_week=1, hour=3, minute=0),  # Segunda-feira às 3h
}
```

## 🌐 API Endpoints

### Rotas Implementadas (`backend/routes/ab_testing.py`):

#### A/B Testing:
- `POST /ab-testing/tests` - Criar teste A/B
- `GET /ab-testing/tests` - Listar testes A/B
- `GET /ab-testing/tests/{test_id}/results` - Obter resultados
- `POST /ab-testing/tests/{test_id}/pause` - Pausar teste
- `POST /ab-testing/tests/{test_id}/rollback` - Executar rollback

#### Monitoramento:
- `GET /ab-testing/models/{model_name}/performance` - Métricas de performance
- `GET /ab-testing/models/{model_name}/drift` - Análise de drift
- `GET /ab-testing/models/{model_name}/anomalies` - Detecção de anomalias
- `GET /ab-testing/models/{model_name}/alerts` - Alertas ativos
- `GET /ab-testing/models/{model_name}/report` - Relatório completo

#### Retreino:
- `POST /ab-testing/models/retrain` - Disparar retreino manual
- `GET /ab-testing/models/retrain/status/{task_id}` - Status do retreino

## 🧪 Testes Implementados

### Arquivo de Testes (`tests/test_ab_testing.py`):

#### Cobertura de Testes:
- ✅ **Criação de Testes A/B**: Validação de configuração e persistência
- ✅ **Distribuição de Tráfego**: Consistência e proporções corretas
- ✅ **Análise Estatística**: Cálculo de métricas e significância
- ✅ **Rollback Automático**: Detecção de degradação e rollback
- ✅ **Monitoramento**: Drift, performance e anomalias
- ✅ **Integração**: Testes end-to-end entre componentes

## 📈 Exemplo de Uso

### 1. Criar Teste A/B:
```python
# Configuração do teste
config = ABTestConfig(
    test_id="ltr_test_001",
    name="Teste Novo Modelo LTR",
    description="Teste do modelo retreinado",
    control_model="production",
    treatment_model="ltr_model_20250705_120000",
    traffic_split=0.1,  # 10% para tratamento
    start_date=datetime.now(),
    end_date=datetime.now() + timedelta(days=7),
    min_sample_size=100,
    significance_level=0.05,
    success_metric="conversion_rate",
    status=TestStatus.ACTIVE
)

# Criar teste
success = ab_testing_service.create_test(config)
```

### 2. Usar em Produção:
```python
# No algoritmo de matching
model, group = ab_testing_service.get_model_for_request(user_id)

# Usar modelo selecionado
if model == "production":
    # Usar modelo atual
    matches = production_matcher.rank(candidates, case)
else:
    # Usar modelo de tratamento
    matches = load_model(model).rank(candidates, case)

# Registrar conversão quando usuário aceita oferta
ab_testing_service.record_conversion(user_id, test_id, group, converted=True)
```

### 3. Monitorar Modelo:
```python
# Obter relatório completo
report = model_monitoring_service.generate_monitoring_report("ltr_model_001", days_back=7)

# Verificar alertas
alerts = model_monitoring_service.get_active_alerts("ltr_model_001")

# Verificar se precisa rollback
if ab_testing_service.should_rollback("ltr_test_001"):
    ab_testing_service.rollback_test("ltr_test_001")
```

## 🔧 Configuração e Deploy

### Dependências Adicionadas:
```
scikit-learn>=1.3.0
pandas>=2.0.0
numpy>=1.24.0
joblib>=1.3.0
```

### Variáveis de Ambiente:
```bash
# A/B Testing
AB_TESTING_ENABLED=true
AB_TESTING_DEFAULT_TRAFFIC_SPLIT=0.1

# Monitoramento
MODEL_MONITORING_ENABLED=true
DRIFT_THRESHOLD=0.3
PERFORMANCE_DEGRADATION_THRESHOLD=0.1
```

## 🚀 Próximos Passos

### Melhorias Futuras:
1. **Dashboard Web**: Interface para gerenciar testes A/B
2. **Alertas Avançados**: Integração com Slack/Teams
3. **Modelos Mais Complexos**: XGBoost, LightGBM para LTR
4. **Multi-Armed Bandit**: Otimização dinâmica de tráfego
5. **Bayesian A/B Testing**: Testes mais eficientes

### Monitoramento em Produção:
- Configurar alertas Prometheus/Grafana
- Definir SLAs para métricas de modelo
- Implementar runbooks para rollback
- Configurar backup automático de modelos

## ✅ Status Final

**EPIC 2.3 está 100% IMPLEMENTADO e TESTADO**

- ✅ Todas as User Stories implementadas
- ✅ Testes unitários e de integração
- ✅ Documentação completa
- ✅ Métricas e monitoramento
- ✅ APIs funcionais
- ✅ Jobs agendados configurados
- ✅ Banco de dados estruturado

O sistema está pronto para uso em produção e oferece uma solução robusta para validação A/B de modelos LTR com monitoramento contínuo e rollback automático. 