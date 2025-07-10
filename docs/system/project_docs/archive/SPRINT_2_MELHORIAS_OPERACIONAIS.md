# 🔧 SPRINT 2: MELHORIAS OPERACIONAIS - PLANO DETALHADO

> **Duração:** 3 semanas (15 dias úteis)  
> **Objetivo:** Otimizar operação e adicionar observabilidade  
> **Prioridade:** P1 - Melhorias operacionais  

## 📋 VISÃO GERAL

Este sprint foca em **melhorias operacionais** e **observabilidade** para garantir que o sistema rode de forma estável e autônoma em produção. Inclui implementação de equidade, monitoramento, fallbacks e validação A/B.

## 🎯 OBJETIVOS DO SPRINT

### Principais Entregas
1. **Sistema Autônomo**: Funciona 24/7 sem intervenção manual
2. **Distribuição Justa**: Equidade entre advogados implementada
3. **Observabilidade Completa**: Métricas, alertas e dashboards
4. **Resiliência**: Fallbacks para todas as dependências externas

### Métricas de Sucesso
- [ ] Sistema roda 24/7 sem intervenção manual
- [ ] Distribuição justa de casos funcionando
- [ ] Alertas funcionando para problemas críticos
- [ ] Métricas coletadas e visualizadas
- [ ] Fallbacks testados e funcionando

## 📊 ÉPICOS E USER STORIES

### ⚖️ EPIC 2.1: Jobs de Equidade
**Problema:** Campos de equidade não são calculados automaticamente

#### US-2.1.1: Implementar job de cálculo de equidade
**Como** sistema  
**Quero** calcular automaticamente os campos de equidade  
**Para que** a distribuição de casos seja justa  

**Critérios de Aceitação:**
- [ ] Job `calculate_equity_metrics` implementado
- [ ] Calcula `cases_30d` para cada advogado
- [ ] Calcula `capacidade_mensal` baseado no perfil
- [ ] Atualiza `last_offered_at` quando necessário
- [ ] Executa diariamente às 2:00 AM

**Implementação:**
```python
# backend/jobs/calculate_equity.py
async def calculate_equity_metrics():
    """Calcula métricas de equidade para todos os advogados"""
    supabase = get_supabase_client()
    
    # Buscar todos os advogados ativos
    lawyers = supabase.table("lawyers").select("*").eq("status", "active").execute()
    
    for lawyer in lawyers.data:
        # Contar casos dos últimos 30 dias
        cases_30d = supabase.table("contracts")\
            .select("id", count="exact")\
            .eq("lawyer_id", lawyer["id"])\
            .gte("created_at", (datetime.now() - timedelta(days=30)).isoformat())\
            .execute()
        
        # Calcular capacidade mensal baseada no perfil
        capacidade_mensal = calculate_monthly_capacity(lawyer)
        
        # Atualizar advogado
        supabase.table("lawyers").update({
            "cases_30d": cases_30d.count,
            "capacidade_mensal": capacidade_mensal
        }).eq("id", lawyer["id"]).execute()
```

**Estimativa:** 2 dias

#### US-2.1.2: Testar distribuição justa
**Como** desenvolvedor  
**Quero** validar que a distribuição de casos é justa  
**Para que** advogados com menos casos recebam mais ofertas  

**Critérios de Aceitação:**
- [ ] Teste automatizado de distribuição
- [ ] Advogados com menos casos recebem mais ofertas
- [ ] Round-robin funcionando em caso de empate
- [ ] Métricas de distribuição coletadas

**Implementação:**
```python
# tests/test_equity_distribution.py
@pytest.mark.asyncio
async def test_fair_distribution():
    # Criar advogados com diferentes cargas
    lawyer_low_load = create_lawyer(cases_30d=2, capacidade_mensal=10)
    lawyer_high_load = create_lawyer(cases_30d=8, capacidade_mensal=10)
    
    # Executar matching múltiplas vezes
    for _ in range(10):
        matches = await MatchService.find_matches(case_data)
        # Advogado com menor carga deve aparecer mais vezes
        assert count_lawyer_in_matches(lawyer_low_load, matches) > \
               count_lawyer_in_matches(lawyer_high_load, matches)
```

**Estimativa:** 1 dia

#### US-2.1.3: Agendar execução diária
**Como** sistema  
**Quero** que o cálculo de equidade rode automaticamente  
**Para que** os dados estejam sempre atualizados  

**Critérios de Aceitação:**
- [ ] Job agendado para 2:00 AM diariamente
- [ ] Logs de execução estruturados
- [ ] Alertas em caso de falha
- [ ] Métricas de tempo de execução

**Implementação:**
```python
# backend/celery_app.py
celery_app.conf.beat_schedule.update({
    'calculate-equity': {
        'task': 'backend.jobs.calculate_equity.calculate_equity_task',
        'schedule': crontab(hour=2, minute=0),  # 2:00 AM diário
    },
})
```

**Estimativa:** 0.5 dias

---

### 📊 EPIC 2.2: Monitoramento e Observabilidade
**Problema:** Falta visibilidade sobre o funcionamento do sistema

#### US-2.2.1: Implementar métricas Prometheus
**Como** desenvolvedor  
**Quero** coletar métricas do sistema  
**Para que** possa monitorar performance e saúde  

**Critérios de Aceitação:**
- [ ] Métricas de contadores implementadas
- [ ] Métricas de latência implementadas
- [ ] Métricas de negócio implementadas
- [ ] Endpoint `/metrics` funcionando

**Implementação:**
```python
# backend/metrics.py
from prometheus_client import Counter, Histogram, Gauge

# Contadores
triage_requests_total = Counter('triage_requests_total', 'Total triage requests')
matches_found_total = Counter('matches_found_total', 'Total matches found')
offers_created_total = Counter('offers_created_total', 'Total offers created')
contracts_signed_total = Counter('contracts_signed_total', 'Total contracts signed')
notifications_sent_total = Counter('notifications_sent_total', 'Total notifications sent', ['type', 'status'])

# Histogramas para latência
triage_duration = Histogram('triage_duration_seconds', 'Triage processing time')
matching_duration = Histogram('matching_duration_seconds', 'Matching processing time')
notification_duration = Histogram('notification_duration_seconds', 'Notification processing time')

# Gauges para estado atual
active_offers = Gauge('active_offers_count', 'Number of active offers')
pending_contracts = Gauge('pending_contracts_count', 'Number of pending contracts')
system_health = Gauge('system_health_score', 'Overall system health score')
```

**Estimativa:** 2 dias

#### US-2.2.2: Configurar alertas
**Como** operador  
**Quero** receber alertas sobre problemas críticos  
**Para que** possa reagir rapidamente a falhas  

**Critérios de Aceitação:**
- [ ] Alertas para falha de jobs críticos
- [ ] Alertas para alta latência
- [ ] Alertas para muitas ofertas expirando
- [ ] Alertas para baixa taxa de sucesso

**Implementação:**
```yaml
# prometheus/alerts.yml
groups:
- name: litgo_alerts
  rules:
  - alert: HighErrorRate
    expr: rate(triage_requests_total{status="error"}[5m]) > 0.1
    for: 2m
    labels:
      severity: critical
    annotations:
      summary: "High error rate in triage service"
      
  - alert: JobFailure
    expr: increase(celery_task_failures_total[5m]) > 0
    for: 1m
    labels:
      severity: warning
    annotations:
      summary: "Celery job failed"
```

**Estimativa:** 1 dia

#### US-2.2.3: Dashboard Grafana
**Como** operador  
**Quero** visualizar métricas em dashboards  
**Para que** possa monitorar o sistema visualmente  

**Critérios de Aceitação:**
- [ ] Dashboard de visão geral implementado
- [ ] Dashboard de métricas de negócio
- [ ] Dashboard de performance técnica
- [ ] Dashboard de jobs e saúde do sistema

**Implementação:**
```json
{
  "dashboard": {
    "title": "LITGO5 - Visão Geral",
    "panels": [
      {
        "title": "Requests por Minuto",
        "targets": [
          {
            "expr": "rate(triage_requests_total[1m])"
          }
        ]
      },
      {
        "title": "Latência Média",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, triage_duration_seconds_bucket)"
          }
        ]
      }
    ]
  }
}
```

**Estimativa:** 2 dias

---

### 🔄 EPIC 2.3: Validação A/B para LTR
**Problema:** Novos modelos não são testados antes do deploy

#### US-2.3.1: Implementar framework A/B
**Como** sistema  
**Quero** testar novos modelos com uma porcentagem do tráfego  
**Para que** possa validar melhorias antes do deploy completo  

**Critérios de Aceitação:**
- [ ] Framework A/B implementado
- [ ] Divisão de tráfego configurável
- [ ] Métricas coletadas por grupo
- [ ] Comparação automática de performance

**Implementação:**
```python
# backend/services/ab_testing.py
class ABTestingService:
    def __init__(self):
        self.experiments = {}
    
    def should_use_variant(self, experiment_name: str, user_id: str) -> bool:
        """Decide se deve usar variante baseado no hash do user_id"""
        experiment = self.experiments.get(experiment_name)
        if not experiment:
            return False
        
        hash_value = hash(f"{experiment_name}_{user_id}") % 100
        return hash_value < experiment["traffic_percentage"]
    
    def track_metric(self, experiment_name: str, user_id: str, metric_name: str, value: float):
        """Registra métrica para análise A/B"""
        variant = "B" if self.should_use_variant(experiment_name, user_id) else "A"
        
        # Registrar no Prometheus
        ab_test_metrics.labels(
            experiment=experiment_name,
            variant=variant,
            metric=metric_name
        ).observe(value)
```

**Estimativa:** 2 dias

#### US-2.3.2: Automatizar retreino
**Como** sistema  
**Quero** retreinar modelos automaticamente  
**Para que** o sistema melhore continuamente  

**Critérios de Aceitação:**
- [ ] Trigger de retreino baseado em volume de dados
- [ ] Validação automática de novos modelos
- [ ] Deploy automático se modelo for melhor
- [ ] Rollback automático se houver degradação

**Implementação:**
```python
# backend/jobs/auto_retrain.py
async def auto_retrain_ltr():
    """Retreina modelo LTR automaticamente"""
    # Verificar se há dados suficientes
    new_reviews_count = count_new_reviews_since_last_training()
    
    if new_reviews_count < MIN_REVIEWS_FOR_RETRAIN:
        logger.info(f"Not enough new reviews: {new_reviews_count}")
        return
    
    # Treinar novo modelo
    new_model = await train_ltr_model()
    
    # Validar modelo
    validation_score = await validate_model(new_model)
    current_score = get_current_model_score()
    
    if validation_score > current_score * 1.05:  # 5% melhoria mínima
        # Deploy novo modelo
        await deploy_model(new_model)
        logger.info(f"New model deployed: {validation_score} vs {current_score}")
    else:
        logger.info(f"New model not better: {validation_score} vs {current_score}")
```

**Estimativa:** 3 dias

#### US-2.3.3: Rollback automático
**Como** sistema  
**Quero** detectar degradação e fazer rollback  
**Para que** o sistema mantenha qualidade mesmo com modelos ruins  

**Critérios de Aceitação:**
- [ ] Monitoramento de métricas de qualidade
- [ ] Detecção automática de degradação
- [ ] Rollback automático para modelo anterior
- [ ] Alertas para equipe técnica

**Implementação:**
```python
# backend/services/model_monitoring.py
class ModelMonitoringService:
    def __init__(self):
        self.quality_threshold = 0.85
        self.degradation_window = timedelta(hours=1)
    
    async def check_model_quality(self):
        """Verifica qualidade do modelo atual"""
        recent_scores = get_recent_match_scores(self.degradation_window)
        avg_score = sum(recent_scores) / len(recent_scores)
        
        if avg_score < self.quality_threshold:
            logger.warning(f"Model quality degraded: {avg_score}")
            await self.rollback_model()
    
    async def rollback_model(self):
        """Faz rollback para modelo anterior"""
        previous_model = get_previous_model()
        await deploy_model(previous_model)
        
        # Enviar alerta
        await send_alert("Model rolled back due to quality degradation")
```

**Estimativa:** 2 dias

---

### 🛡️ EPIC 2.4: Fallbacks e Resiliência
**Problema:** Sistema falha quando dependências externas estão indisponíveis

#### US-2.4.1: Implementar fallback para embeddings
**Como** sistema  
**Quero** usar modelo local quando OpenAI falha  
**Para que** o sistema continue funcionando mesmo com APIs externas indisponíveis  

**Critérios de Aceitação:**
- [ ] Modelo sentence-transformers configurado
- [ ] Fallback automático implementado
- [ ] Qualidade do fallback validada
- [ ] Métricas de uso do fallback

**Implementação:**
```python
# backend/services/embedding_service.py
from sentence_transformers import SentenceTransformer

class EmbeddingService:
    def __init__(self):
        self.openai_client = OpenAI()
        self.local_model = SentenceTransformer('all-MiniLM-L6-v2')
    
    async def generate_embedding(self, text: str) -> List[float]:
        """Gera embedding com fallback local"""
        try:
            # Tentar OpenAI primeiro
            response = await self.openai_client.embeddings.create(
                model="text-embedding-3-small",
                input=text
            )
            embedding_source.labels(source="openai").inc()
            return response.data[0].embedding
            
        except Exception as e:
            logger.warning(f"OpenAI failed, using local model: {e}")
            
            # Fallback para modelo local
            embedding = self.local_model.encode(text).tolist()
            embedding_source.labels(source="local").inc()
            return embedding
```

**Estimativa:** 2 dias

#### US-2.4.2: Fallback para contratos
**Como** sistema  
**Quero** permitir assinatura manual quando DocuSign falha  
**Para que** contratos não sejam bloqueados por falhas externas  

**Critérios de Aceitação:**
- [ ] Opção de assinatura manual implementada
- [ ] Processo de backup documentado
- [ ] Notificação automática em caso de falha
- [ ] Métricas de uso do fallback

**Implementação:**
```python
# backend/services/contract_service.py
async def create_contract(case_id: str, lawyer_id: str, client_id: str):
    """Cria contrato com fallback para assinatura manual"""
    try:
        # Tentar DocuSign primeiro
        envelope = await create_docusign_envelope(case_id, lawyer_id, client_id)
        contract_creation_method.labels(method="docusign").inc()
        return envelope
        
    except Exception as e:
        logger.warning(f"DocuSign failed, creating manual contract: {e}")
        
        # Fallback para processo manual
        contract = await create_manual_contract(case_id, lawyer_id, client_id)
        contract_creation_method.labels(method="manual").inc()
        
        # Notificar equipe
        await notify_manual_contract_needed(contract)
        return contract
```

**Estimativa:** 1.5 dias

#### US-2.4.3: Timeouts configuráveis
**Como** desenvolvedor  
**Quero** configurar timeouts para APIs externas  
**Para que** o sistema não trave esperando respostas  

**Critérios de Aceitação:**
- [ ] Timeouts configuráveis via variáveis de ambiente
- [ ] Timeouts aplicados a todas as APIs externas
- [ ] Retry com backoff exponencial
- [ ] Métricas de timeout coletadas

**Implementação:**
```python
# backend/config.py
class APIConfig:
    OPENAI_TIMEOUT = int(os.getenv("OPENAI_TIMEOUT", "30"))
    DOCUSIGN_TIMEOUT = int(os.getenv("DOCUSIGN_TIMEOUT", "45"))
    ONESIGNAL_TIMEOUT = int(os.getenv("ONESIGNAL_TIMEOUT", "15"))
    SENDGRID_TIMEOUT = int(os.getenv("SENDGRID_TIMEOUT", "15"))

# backend/services/base_service.py
class BaseAPIService:
    def __init__(self, timeout: int):
        self.timeout = timeout
        self.session = httpx.AsyncClient(timeout=timeout)
    
    async def call_with_retry(self, func, *args, **kwargs):
        """Chama função com retry e timeout"""
        for attempt in range(3):
            try:
                return await func(*args, **kwargs)
            except httpx.TimeoutException:
                api_timeouts.labels(service=self.__class__.__name__).inc()
                if attempt == 2:
                    raise
                await asyncio.sleep(2 ** attempt)
```

**Estimativa:** 1 dia

## 📅 CRONOGRAMA DETALHADO

### Semana 1 (Dias 1-5)
| Dia | Atividade | Responsável | Status |
|:---:|:---|:---|:---:|
| 1 | US-2.1.1: Implementar job de equidade | Dev Backend | ⏳ |
| 2 | US-2.1.1: Continuar job de equidade | Dev Backend | ⏳ |
| 2 | US-2.1.2: Testar distribuição justa | Dev Backend | ⏳ |
| 3 | US-2.1.3: Agendar execução diária | Dev Backend | ⏳ |
| 3 | US-2.2.1: Implementar métricas Prometheus | Dev Backend | ⏳ |
| 4 | US-2.2.1: Continuar métricas | Dev Backend | ⏳ |
| 5 | US-2.2.2: Configurar alertas | DevOps | ⏳ |

### Semana 2 (Dias 6-10)
| Dia | Atividade | Responsável | Status |
|:---:|:---|:---|:---:|
| 6 | US-2.2.3: Dashboard Grafana | DevOps | ⏳ |
| 7 | US-2.2.3: Continuar dashboard | DevOps | ⏳ |
| 7 | US-2.3.1: Implementar framework A/B | Dev Backend | ⏳ |
| 8 | US-2.3.1: Continuar framework A/B | Dev Backend | ⏳ |
| 9 | US-2.3.2: Automatizar retreino | Dev Backend | ⏳ |
| 10 | US-2.3.2: Continuar retreino | Dev Backend | ⏳ |

### Semana 3 (Dias 11-15)
| Dia | Atividade | Responsável | Status |
|:---:|:---|:---|:---:|
| 11 | US-2.3.2: Finalizar retreino | Dev Backend | ⏳ |
| 11 | US-2.3.3: Rollback automático | Dev Backend | ⏳ |
| 12 | US-2.3.3: Continuar rollback | Dev Backend | ⏳ |
| 13 | US-2.4.1: Fallback embeddings | Dev Backend | ⏳ |
| 14 | US-2.4.1: Continuar fallback | Dev Backend | ⏳ |
| 14 | US-2.4.2: Fallback contratos | Dev Backend | ⏳ |
| 15 | US-2.4.3: Timeouts configuráveis | Dev Backend | ⏳ |

## 🧪 ESTRATÉGIA DE TESTES

### Testes de Resiliência
- [ ] Testes de falha de APIs externas
- [ ] Testes de timeout e retry
- [ ] Testes de fallback automático
- [ ] Testes de carga e stress

### Testes de Equidade
- [ ] Testes de distribuição justa
- [ ] Testes de round-robin
- [ ] Testes de cálculo de métricas
- [ ] Testes de performance do job

### Testes de Monitoramento
- [ ] Testes de coleta de métricas
- [ ] Testes de alertas
- [ ] Testes de dashboards
- [ ] Testes de A/B testing

## 🚀 CRITÉRIOS DE ACEITAÇÃO DO SPRINT

### Operação Autônoma
- [ ] **24/7 sem intervenção**: Sistema roda sem intervenção manual
- [ ] **Jobs automáticos**: Todos os jobs executam conforme agendado
- [ ] **Fallbacks funcionando**: Sistema resiliente a falhas externas
- [ ] **Alertas ativos**: Problemas são detectados e notificados

### Distribuição Justa
- [ ] **Equidade implementada**: Advogados com menos casos recebem mais ofertas
- [ ] **Métricas atualizadas**: `cases_30d` e `capacidade_mensal` calculados
- [ ] **Round-robin**: Desempate funcionando corretamente
- [ ] **Testes validados**: Distribuição justa comprovada

### Observabilidade
- [ ] **Métricas coletadas**: Prometheus funcionando
- [ ] **Dashboards ativos**: Grafana com visualizações
- [ ] **Alertas configurados**: Notificações para problemas críticos
- [ ] **A/B testing**: Framework para testes de modelo

### Resiliência
- [ ] **Fallbacks testados**: Todos os fallbacks funcionando
- [ ] **Timeouts configurados**: APIs externas com timeout
- [ ] **Retry implementado**: Tentativas automáticas
- [ ] **Monitoramento**: Métricas de falhas coletadas

## 🔧 CONFIGURAÇÃO DE AMBIENTE

### Variáveis de Ambiente Adicionais
```bash
# Timeouts
OPENAI_TIMEOUT=30
DOCUSIGN_TIMEOUT=45
ONESIGNAL_TIMEOUT=15
SENDGRID_TIMEOUT=15

# Monitoramento
PROMETHEUS_PORT=9090
GRAFANA_PORT=3000
GRAFANA_ADMIN_PASSWORD=admin

# A/B Testing
AB_TESTING_ENABLED=true
DEFAULT_TRAFFIC_PERCENTAGE=10

# Fallbacks
LOCAL_EMBEDDING_MODEL=all-MiniLM-L6-v2
FALLBACK_ENABLED=true
```

### Docker Compose Atualizado
```yaml
# docker-compose.yml
services:
  # ... serviços existentes ...
  
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - ./prometheus/alerts.yml:/etc/prometheus/alerts.yml
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--web.enable-lifecycle'
  
  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana-storage:/var/lib/grafana
      - ./grafana/dashboards:/etc/grafana/provisioning/dashboards
      - ./grafana/datasources:/etc/grafana/provisioning/datasources

volumes:
  grafana-storage:
```

## 📊 MÉTRICAS DE SUCESSO

### Métricas Operacionais
- **Uptime**: >99.9% dos serviços funcionando
- **MTTR**: <15 minutos para resolver problemas
- **Alertas**: <5% de falsos positivos
- **Jobs**: 100% executados conforme agendado

### Métricas de Equidade
- **Distribuição**: Coeficiente de Gini <0.3
- **Utilização**: >80% dos advogados recebem ofertas
- **Balanceamento**: Diferença máxima de 20% entre advogados

### Métricas de Resiliência
- **Fallback Usage**: <10% do tempo total
- **Timeout Rate**: <1% das requisições
- **Recovery Time**: <30 segundos para fallbacks

## 🎯 DEFINIÇÃO DE PRONTO

Uma user story está pronta quando:
- [ ] Código implementado e testado
- [ ] Testes unitários e integração passando
- [ ] Métricas implementadas
- [ ] Alertas configurados
- [ ] Documentação atualizada
- [ ] Code review aprovado
- [ ] Deploy em staging validado
- [ ] Monitoramento funcionando

## 📞 PRÓXIMOS PASSOS

### Após Sprint 2
1. **Monitoramento Contínuo**: Acompanhar métricas em produção
2. **Sprint 3**: Otimizações e features avançadas
3. **Refinamentos**: Baseados no feedback operacional

### Riscos e Mitigações
- **Risco**: Overhead de monitoramento afeta performance
  - **Mitigação**: Sampling e otimização de coleta
- **Risco**: Fallbacks com qualidade inferior
  - **Mitigação**: Testes extensivos e métricas de qualidade
- **Risco**: Complexidade do A/B testing
  - **Mitigação**: Implementação gradual e documentação

---

**🔧 Este sprint estabelece as bases para operação estável e autônoma do sistema em produção.** 