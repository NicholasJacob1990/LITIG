# Sprints para Melhorias da Triagem Inteligente

## Visão Geral dos Sprints

### Sprint 1: Persistência e Resiliência (2 semanas)
**Foco**: Redis para persistência de conversas e recuperação de estado

### Sprint 2: Performance e Experiência do Usuário (2 semanas)  
**Foco**: Streaming de respostas e processamento em background

### Sprint 3: Observabilidade e Validação (2 semanas)
**Foco**: Monitoramento de custos e A/B testing

---

## 🚀 **SPRINT 1: PERSISTÊNCIA E RESILIÊNCIA**
**Duração**: 2 semanas  
**Objetivo**: Garantir que conversas não sejam perdidas e permitir escalabilidade horizontal

### **Épico 1.1: Configuração do Redis**
**Estimativa**: 2 dias

#### **Tarefas**:
1. **Configurar Redis no Docker Compose**
   - Adicionar serviço Redis ao `docker-compose.yml`
   - Configurar volumes para persistência
   - Definir configurações de memória e TTL

2. **Instalar Dependências**
   - Adicionar `aioredis` ao `requirements.txt`
   - Configurar variáveis de ambiente para Redis

3. **Criar Serviço Base Redis**
   - Implementar `backend/services/redis_service.py`
   - Configurar conexão com retry e health check
   - Implementar métodos base (get, set, delete, exists)

#### **Entregáveis**:
- [ ] Redis rodando no Docker
- [ ] Conexão Redis configurada
- [ ] Serviço base Redis implementado

### **Épico 1.2: Migração de Conversas para Redis**
**Estimativa**: 5 dias

#### **Tarefas**:
1. **Criar ConversationStateManager**
   ```python
   # backend/services/conversation_state_manager.py
   class ConversationStateManager:
       async def save_conversation_state(case_id, state)
       async def get_conversation_state(case_id)
       async def delete_conversation_state(case_id)
       async def list_active_conversations()
   ```

2. **Migrar IntelligentInterviewerService**
   - Substituir `self.active_conversations` por Redis
   - Implementar serialização/deserialização de estado
   - Adicionar TTL para limpeza automática

3. **Migrar IntelligentTriageOrchestrator**
   - Substituir `self.active_orchestrations` por Redis
   - Implementar recuperação de estado após restart
   - Adicionar logs de recuperação

4. **Implementar Migração de Dados**
   - Script para migrar conversas ativas para Redis
   - Estratégia de rollback se necessário

#### **Entregáveis**:
- [ ] ConversationStateManager implementado
- [ ] Serviços migrados para Redis
- [ ] Scripts de migração criados
- [ ] Testes de persistência funcionando

### **Épico 1.3: Testes e Validação**
**Estimativa**: 3 dias

#### **Tarefas**:
1. **Testes de Persistência**
   - Teste de restart do servidor
   - Teste de recuperação de conversas
   - Teste de TTL e limpeza automática

2. **Testes de Escalabilidade**
   - Teste com múltiplas instâncias
   - Validação de sincronização entre instâncias
   - Teste de load balancing

3. **Documentação**
   - Atualizar documentação de deploy
   - Criar guia de troubleshooting Redis
   - Documentar estratégias de backup

#### **Entregáveis**:
- [ ] Suite de testes completa
- [ ] Validação de múltiplas instâncias
- [ ] Documentação atualizada

---

## ⚡ **SPRINT 2: PERFORMANCE E EXPERIÊNCIA DO USUÁRIO**
**Duração**: 2 semanas  
**Objetivo**: Implementar streaming de respostas e processamento em background

### **Épico 2.1: Streaming de Respostas**
**Estimativa**: 4 dias

#### **Tarefas**:
1. **Backend - Streaming API**
   ```python
   # backend/routes/intelligent_triage_routes.py
   @router.post("/continue-stream")
   async def continue_conversation_stream(request, payload):
       # Implementar StreamingResponse
   ```

2. **Modificar Serviços de IA**
   - Adicionar suporte a streaming no OpenAI
   - Implementar streaming no Anthropic
   - Criar wrapper unificado para streaming

3. **Frontend - Processamento de Stream**
   ```typescript
   // lib/services/intelligentTriage.ts
   async function* continueConversationStream(caseId, message) {
       // Implementar processamento de stream
   }
   ```

4. **UI - Atualização em Tempo Real**
   - Componente de typing indicator melhorado
   - Atualização palavra por palavra
   - Fallback para modo não-stream

#### **Entregáveis**:
- [ ] API de streaming implementada
- [ ] Serviços de IA com streaming
- [ ] Frontend processando stream
- [ ] UI atualizada em tempo real

### **Épico 2.2: Processamento em Background**
**Estimativa**: 5 dias

#### **Tarefas**:
1. **Configurar Celery para Triagem**
   - Adicionar worker específico para triagem
   - Configurar queues separadas por complexidade
   - Implementar retry policies

2. **Criar Tarefas Celery**
   ```python
   # backend/jobs/intelligent_triage_tasks.py
   @celery.task(bind=True)
   def process_completed_conversation_task(self, case_id):
       # Implementar processamento assíncrono
   ```

3. **Modificar Endpoints**
   - `/continue` retorna imediatamente para casos complexos
   - Adicionar endpoint `/status` melhorado
   - Implementar webhook para notificação de conclusão

4. **Frontend - Polling Inteligente**
   - Implementar polling adaptativo
   - UI de "processando análise"
   - Notificações push quando pronto

#### **Entregáveis**:
- [ ] Celery configurado para triagem
- [ ] Tarefas assíncronas implementadas
- [ ] Endpoints modificados
- [ ] Frontend com polling inteligente

### **Épico 2.3: Otimização de Performance**
**Estimativa**: 1 dia

#### **Tarefas**:
1. **Cache de Resultados**
   - Cache Redis para análises similares
   - Hash de contexto para identificar duplicatas
   - TTL configurável por tipo de análise

2. **Otimização de Queries**
   - Implementar connection pooling
   - Otimizar queries do banco
   - Adicionar índices necessários

#### **Entregáveis**:
- [ ] Sistema de cache implementado
- [ ] Queries otimizadas
- [ ] Performance melhorada

---

## 📊 **SPRINT 3: OBSERVABILIDADE E VALIDAÇÃO**
**Duração**: 2 semanas  
**Objetivo**: Monitorar custos, latência e validar melhorias via A/B testing

### **Épico 3.1: Monitoramento de Custos e Latência**
**Estimativa**: 4 dias

#### **Tarefas**:
1. **Instrumentação de APIs de IA**
   ```python
   # backend/services/ai_monitoring_service.py
   class AIMonitoringService:
       async def track_openai_call(self, model, tokens, cost, latency)
       async def track_anthropic_call(self, model, tokens, cost, latency)
       async def get_daily_costs(self)
   ```

2. **Métricas Prometheus**
   - Contador de chamadas por modelo
   - Histograma de latência
   - Gauge de custo por dia/hora
   - Métricas de taxa de sucesso

3. **Dashboards Grafana**
   - Dashboard de custos de IA
   - Dashboard de performance
   - Alertas para custos elevados
   - Alertas para latência alta

4. **Relatórios Automatizados**
   - Relatório diário de custos
   - Relatório semanal de performance
   - Notificações Slack para alertas

#### **Entregáveis**:
- [ ] Serviço de monitoramento implementado
- [ ] Métricas Prometheus configuradas
- [ ] Dashboards Grafana criados
- [ ] Relatórios automatizados

### **Épico 3.2: A/B Testing da Nova Arquitetura**
**Estimativa**: 5 dias

#### **Tarefas**:
1. **Configurar Experimento A/B**
   ```python
   # backend/services/ab_testing_service.py
   experiment_config = {
       "name": "intelligent_triage_v2",
       "variants": {
           "control": {"weight": 50, "version": "v1"},
           "treatment": {"weight": 50, "version": "v2"}
       }
   }
   ```

2. **Modificar Frontend**
   - Integrar com serviço A/B testing
   - Roteamento baseado em variante
   - Tracking de eventos por variante

3. **Métricas de Comparação**
   - Taxa de conclusão de triagem
   - Tempo médio de triagem
   - Satisfação do usuário (NPS)
   - Precisão da classificação

4. **Análise Estatística**
   - Implementar testes de significância
   - Dashboard de resultados A/B
   - Relatórios de conclusão

#### **Entregáveis**:
- [ ] Experimento A/B configurado
- [ ] Frontend com roteamento A/B
- [ ] Métricas de comparação
- [ ] Análise estatística implementada

### **Épico 3.3: Documentação e Treinamento**
**Estimativa**: 1 dia

#### **Tarefas**:
1. **Documentação Técnica**
   - Arquitetura atualizada
   - Guias de troubleshooting
   - Runbooks para produção

2. **Treinamento da Equipe**
   - Workshop sobre nova arquitetura
   - Guia de monitoramento
   - Procedimentos de incident response

#### **Entregáveis**:
- [ ] Documentação completa
- [ ] Equipe treinada
- [ ] Procedimentos documentados

---

## 📋 **CRITÉRIOS DE ACEITAÇÃO GERAIS**

### **Sprint 1 - Persistência**
- [ ] Conversas persistem após restart do servidor
- [ ] Múltiplas instâncias funcionam corretamente
- [ ] TTL limpa conversas antigas automaticamente
- [ ] Tempo de recuperação < 2 segundos

### **Sprint 2 - Performance**
- [ ] Streaming funciona em 95% dos casos
- [ ] Tempo de primeira resposta < 500ms
- [ ] Análises complexas processam em background
- [ ] UI atualiza em tempo real

### **Sprint 3 - Observabilidade**
- [ ] Custos de IA são monitorados em tempo real
- [ ] Alertas funcionam corretamente
- [ ] A/B testing mostra resultados significativos
- [ ] Dashboards estão atualizados

---

## 🔧 **CONFIGURAÇÃO DE DESENVOLVIMENTO**

### **Preparação dos Sprints**

```bash
# Sprint 1 - Setup Redis
docker-compose up -d redis
pip install aioredis

# Sprint 2 - Setup Celery
celery -A backend.celery worker --loglevel=info

# Sprint 3 - Setup Monitoring
docker-compose up -d prometheus grafana
```

### **Estrutura de Testes**

```python
# tests/test_sprint_1_redis.py
# tests/test_sprint_2_streaming.py
# tests/test_sprint_3_monitoring.py
```

---

## 📈 **MÉTRICAS DE SUCESSO**

### **Objetivos Quantitativos**
- **Disponibilidade**: 99.9% uptime
- **Performance**: Tempo de resposta < 2s (P95)
- **Custo**: Redução de 20% no custo por triagem
- **Satisfação**: NPS > 8.0

### **Objetivos Qualitativos**
- Experiência do usuário mais fluida
- Maior confiabilidade do sistema
- Melhor observabilidade operacional
- Validação científica das melhorias

---

## 🚀 **PRÓXIMOS PASSOS**

1. **Priorização**: Definir ordem dos sprints baseado em necessidades do negócio
2. **Recursos**: Alocar desenvolvedores para cada épico
3. **Ambiente**: Preparar ambientes de desenvolvimento e staging
4. **Monitoramento**: Configurar métricas baseline antes das mudanças

**Recomendação**: Começar com Sprint 1 (Persistência) por ser fundamental para estabilidade, seguir com Sprint 2 (Performance) para melhorar UX, e finalizar com Sprint 3 (Observabilidade) para validar os resultados. 