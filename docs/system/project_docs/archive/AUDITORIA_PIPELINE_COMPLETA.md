# 📋 **AUDITORIA COMPLETA DO PIPELINE DE MATCHING JURÍDICO LITGO5**

> **Data da Auditoria:** Janeiro 2025  
> **Versão do Sistema:** v2.2  
> **Escopo:** Pipeline completo (10 fases) - Triagem → Feedback  
> **Status:** 🟡 **80% Funcional** - Necessita correções críticas para produção

---

## 📊 **RESUMO EXECUTIVO**

### **🎯 Visão Geral**
O sistema LITGO5 possui uma **arquitetura robusta e bem projetada**, com implementação de alta qualidade técnica na maioria das fases. O algoritmo de matching é sofisticado, usando 8 features balanceadas (A-S-T-G-Q-U-R-C) com pesos adaptativos e aprendizado de máquina via LightGBM. 

**Porém**, há **lacunas críticas de integração** que impedem o funcionamento completo em produção, principalmente relacionadas a:
- Discrepâncias entre schema do banco e código
- Funções de notificação não implementadas  
- Ausência de agendamento automático de jobs
- Testes desatualizados

### **📈 Métricas de Qualidade**

| Categoria | Status | Nota | Observações |
|:---|:---:|:---:|:---|
| **Arquitetura** | 🟢 | 9/10 | Microserviços bem estruturados |
| **Algoritmo Core** | 🟢 | 8/10 | Matemática sólida, features balanceadas |
| **Integração** | 🔴 | 4/10 | Múltiplas quebras entre componentes |
| **Testes** | 🟡 | 6/10 | Existem, mas desatualizados |
| **Operação** | 🔴 | 3/10 | Sem automação, jobs manuais |
| **Observabilidade** | 🟡 | 7/10 | Logs estruturados, mas sem métricas |

### **🚨 Problemas Críticos (P0)**

1. **Schema-Código Mismatch**: Campos `tags_expertise`, `cases_30d`, `capacidade_mensal` não existem
2. **Notificações Quebradas**: Funções `send_push_notification` não implementadas
3. **Jobs Sem Agendamento**: Nenhum job roda automaticamente
4. **Ofertas Sem Expiração**: SLA de 24h não é respeitado

---

## 🔍 **ANÁLISE DETALHADA POR FASE**

### **Fase 1: Triagem LLM** 
**Status:** 🟢 **FUNCIONAL** - Implementação robusta

#### **✅ Pontos Fortes**
- **Ensemble LLM**: Claude (principal) + OpenAI (fallback) com estratégia "juiz"
- **Prompts Estruturados**: Tool calling + JSON mode para saídas consistentes
- **Fallback Robusto**: Regex para área/urgência quando LLM falha
- **Arquitetura Assíncrona**: Celery + Redis para processamento escalável
- **Embedding Integrado**: Gera vetores durante triagem

#### **⚠️ Problemas Identificados**
- **Testes Desatualizados**: Referenciam `run_triage_async_task` que não existe mais
- **Inconsistência de Tasks**: `main_routes.py` importa tarefa inexistente
- **Sem Timeout Config**: Prompts LLM podem travar sem timeout configurável

#### **🛠️ Ações Necessárias**
1. **Corrigir Import**: Atualizar `main_routes.py` para usar `run_full_triage_flow_task`
2. **Atualizar Testes**: Sincronizar com implementação atual
3. **Configurar Timeouts**: Adicionar timeouts configuráveis para LLM calls

---

### **Fase 2: Embeddings (pgvector)**
**Status:** 🟢 **FUNCIONAL** - Implementação eficiente

#### **✅ Pontos Fortes**
- **Modelo Eficiente**: `text-embedding-3-small` (1536 dim) - bom custo-benefício
- **Retry Inteligente**: Backoff exponencial para chamadas OpenAI
- **Normalização L2**: Vetores normalizados para comparação correta
- **Cache Implementado**: Evita recálculos desnecessários

#### **⚠️ Problemas Identificados**
- **Dependência Única**: Apenas OpenAI, sem fallback local
- **Sem Monitoramento**: Não há métricas de latência/custo
- **Dimensionalidade Fixa**: Não suporta modelos alternativos

#### **🛠️ Ações Necessárias**
1. **Implementar Fallback**: Modelo local (sentence-transformers) para emergências
2. **Adicionar Métricas**: Latência, custo, taxa de erro
3. **Configurar Dimensões**: Suporte a modelos com diferentes dimensões

---

### **Fase 3: Filtro & Features**
**Status:** 🔴 **CRÍTICO** - Discrepâncias schema-código

#### **✅ Pontos Fortes**
- **8 Features Balanceadas**: A-S-T-G-Q-U-R-C bem implementadas matematicamente
- **Filtro Geográfico**: Função RPC `lawyers_nearby` otimizada
- **Cálculos Corretos**: Fórmulas de similaridade e qualidade implementadas
- **Configuração Flexível**: Presets para diferentes cenários

#### **🚨 Problemas Críticos**
- **Campos Inexistentes**: Código usa `tags_expertise` mas tabela tem `specialties`
- **Schema Mismatch**: `geo_latlon` vs `lat`/`lng`, `cases_30d` não existe
- **Função Quebrada**: `lawyers_nearby` espera campos que não existem

#### **🛠️ Ações Críticas**
1. **Migração Urgente**: Adicionar campos faltantes ou mapear existentes
2. **Alinhar Nomenclatura**: Padronizar nomes entre código e schema
3. **Testar Integração**: Validar que filtros funcionam ponta-a-ponta

---

### **Fase 4: Score & ε-cluster**
**Status:** 🟡 **PARCIALMENTE FUNCIONAL** - Depende da Fase 3

#### **✅ Pontos Fortes**
- **Sistema de Pesos Multicamada**: Base + Presets + Dinâmicos + LTR
- **Epsilon Adaptativo**: Ajusta automaticamente baseado na qualidade dos matches
- **LTR Integrado**: LightGBM para aprendizado contínuo
- **Configuração Rica**: Múltiplos presets (`fast`, `expert`, `balanced`)

#### **⚠️ Problemas Identificados**
- **Dependência da Fase 3**: Não funciona sem correção dos campos
- **Pesos Desatualizados**: Arquivo `ltr_weights.json` pode estar obsoleto
- **Sem Validação A/B**: Novos modelos não são testados antes do deploy

#### **🛠️ Ações Necessárias**
1. **Aguardar Fase 3**: Corrigir dependências primeiro
2. **Validar Pesos**: Verificar se pesos LTR estão atualizados
3. **Implementar A/B**: Sistema para testar novos modelos

---

### **Fase 5: Equidade + Round-robin**
**Status:** 🔴 **CRÍTICO** - Dados de equidade não atualizados

#### **✅ Pontos Fortes**
- **Fórmula Correta**: `equity = 1 - cases_30d / capacidade_mensal`
- **Round-robin Implementado**: Desempate por `last_offered_at`
- **Peso Balanceado**: β=0.30 para equidade vs performance

#### **🚨 Problemas Críticos**
- **Dados Não Atualizados**: Campos `cases_30d`, `capacidade_mensal` não são calculados
- **Sem Job de Equidade**: Não há processo para atualizar essas métricas
- **Equidade Não Funciona**: Sistema sempre usa valores padrão/zerados

#### **🛠️ Ações Críticas**
1. **Criar Job de Equidade**: Calcular `cases_30d` e `capacidade_mensal` diariamente
2. **Implementar Lógica**: Contar casos dos últimos 30 dias por advogado
3. **Testar Distribuição**: Validar que casos são distribuídos de forma justa

---

### **Fase 6: Notificação**
**Status:** 🔴 **CRÍTICO** - Funções não implementadas

#### **✅ Pontos Fortes**
- **Arquitetura Correta**: Push (OneSignal) + Email (SendGrid) fallback
- **Rate Limiting**: Controle de frequência implementado
- **Retry Logic**: Tentativas com backoff exponencial
- **Cache**: Evita notificações duplicadas

#### **🚨 Problemas Críticos**
- **Funções Não Implementadas**: `send_push_notification` e `send_email_notification` não existem
- **Inconsistência de Nomes**: Código chama funções com nomes diferentes dos implementados
- **Sem Configuração**: Chaves OneSignal/SendGrid não configuradas

#### **🛠️ Ações Críticas**
1. **Implementar Funções**: Completar `send_push_notification` e `send_email_notification`
2. **Configurar Chaves**: Adicionar credenciais OneSignal/SendGrid
3. **Testar Integração**: Validar que notificações chegam aos advogados

---

### **Fase 7: Offers**
**Status:** 🟡 **FUNCIONAL** - Falta automação

#### **✅ Pontos Fortes**
- **Schema Robusto**: Tabela bem projetada com constraints
- **Estados Bem Definidos**: Fluxo claro de pending → interested/declined
- **Snapshot de Scores**: Preserva dados históricos para análise
- **Testes Abrangentes**: Boa cobertura de cenários

#### **⚠️ Problemas Identificados**
- **Expiração Manual**: Job `expire_offers` não roda automaticamente
- **SLA Não Respeitado**: Ofertas ficam pendentes além de 24h
- **Sem Alertas**: Não há notificação quando ofertas expiram

#### **🛠️ Ações Necessárias**
1. **Agendar Job**: Configurar `expire_offers` para rodar de hora em hora
2. **Implementar Alertas**: Notificar quando muitas ofertas expiram
3. **Métricas**: Acompanhar tempo médio de resposta dos advogados

---

### **Fase 8: Contracts**
**Status:** 🟢 **FUNCIONAL** - Implementação completa

#### **✅ Pontos Fortes**
- **Integração DocuSign**: Completa com webhooks e status sync
- **Geração PDF**: Template HTML bem estruturado
- **Lifecycle Completo**: Estados bem definidos com triggers
- **Testes Robustos**: Cobertura de cenários de assinatura

#### **⚠️ Problemas Identificados**
- **Dependência Externa**: Falha se DocuSign estiver indisponível
- **Sem Fallback**: Não há opção de assinatura manual
- **Custos**: Cada envelope DocuSign tem custo

#### **🛠️ Ações Necessárias**
1. **Implementar Fallback**: Opção de assinatura manual/local
2. **Monitorar Custos**: Métricas de uso DocuSign
3. **Backup**: Processo para casos de falha da integração

---

### **Fase 9: Reviews**
**Status:** 🟡 **FUNCIONAL** - Falta automação

#### **✅ Pontos Fortes**
- **Separação T vs R**: Features objetivas vs subjetivas bem separadas
- **Schema Completo**: Todos os campos necessários para análise
- **Job de Atualização**: `update_review_kpi` implementado
- **Testes Abrangentes**: Boa cobertura de cenários

#### **⚠️ Problemas Identificados**
- **Job Manual**: `update_review_kpi` não roda automaticamente
- **Sem Análise de Sentimento**: Comentários não são analisados
- **Métricas Limitadas**: Apenas média simples, sem ponderação

#### **🛠️ Ações Necessárias**
1. **Agendar Job**: Executar `update_review_kpi` diariamente
2. **Implementar Sentimento**: Analisar comentários com NLP
3. **Métricas Avançadas**: Ponderação por tempo, tipo de caso, etc.

---

### **Fase 10: Jobs de Dados**
**Status:** 🔴 **CRÍTICO** - Sem automação

#### **✅ Pontos Fortes**
- **Jusbrasil Sync v2.2**: Job sofisticado com KPI granular
- **LTR Training**: Pipeline ML completo com validação
- **Logging Estruturado**: JSON para observabilidade
- **Scripts Organizados**: Fácil execução manual

#### **🚨 Problemas Críticos**
- **Sem Celery Beat**: Nenhum job roda automaticamente
- **Sem Agendamento**: Não há cron, GitHub Actions schedule
- **Dados Desatualizados**: Sistema não aprende nem atualiza

#### **🛠️ Ações Críticas**
1. **Configurar Celery Beat**: Adicionar scheduler ao docker-compose
2. **Agendar Jobs**: Jusbrasil (diário), LTR (semanal), Reviews (diário)
3. **Implementar Monitoramento**: Métricas e alertas para jobs

---

## 📋 **PLANOS DE SPRINT DETALHADOS**

### **🚀 SPRINT 1: CORREÇÕES CRÍTICAS (2 semanas)**
**Objetivo:** Fazer o sistema funcionar ponta-a-ponta

#### **Epic 1.1: Correção Schema-Código**
- **US-1.1.1**: Criar migração para adicionar campos faltantes
  - `ALTER TABLE lawyers ADD COLUMN tags_expertise TEXT[]`
  - `ALTER TABLE lawyers ADD COLUMN cases_30d INTEGER DEFAULT 0`
  - `ALTER TABLE lawyers ADD COLUMN capacidade_mensal INTEGER DEFAULT 10`
  - `ALTER TABLE lawyers ADD COLUMN geo_latlon POINT`
- **US-1.1.2**: Implementar mapeamento de campos existentes
  - Função para converter `specialties` → `tags_expertise`
  - Função para converter `lat,lng` → `geo_latlon`
- **US-1.1.3**: Testar integração ponta-a-ponta
  - Validar que filtros funcionam
  - Testar cálculo de features

#### **Epic 1.2: Implementação de Notificações**
- **US-1.2.1**: Implementar `send_push_notification`
  - Integração OneSignal completa
  - Tratamento de erros e retry
- **US-1.2.2**: Implementar `send_email_notification`
  - Integração SendGrid completa
  - Templates de email
- **US-1.2.3**: Configurar credenciais
  - Adicionar chaves OneSignal/SendGrid ao .env
  - Testar envio real

#### **Epic 1.3: Configuração de Agendamento**
- **US-1.3.1**: Adicionar Celery Beat ao docker-compose
  ```yaml
  celery-beat:
    build: .
    command: celery -A backend.celery_app beat --loglevel=info
    depends_on: [redis]
  ```
- **US-1.3.2**: Configurar periodic tasks
  - `expire_offers`: de hora em hora
  - `jusbrasil_sync`: diário às 3:00 AM
  - `update_review_kpi`: diário às 4:00 AM
- **US-1.3.3**: Testar execução automática

#### **Epic 1.4: Correção de Testes**
- **US-1.4.1**: Atualizar testes da Fase 1
  - Corrigir referências a tarefas inexistentes
  - Testar fluxo completo de triagem
- **US-1.4.2**: Atualizar testes da Fase 7
  - Sincronizar com implementação atual
  - Adicionar testes de expiração

### **🔧 SPRINT 2: MELHORIAS OPERACIONAIS (3 semanas)**
**Objetivo:** Otimizar operação e adicionar observabilidade

#### **Epic 2.1: Jobs de Equidade**
- **US-2.1.1**: Implementar job de cálculo de equidade
  - Contar casos dos últimos 30 dias por advogado
  - Calcular capacidade mensal baseada em perfil
  - Atualizar campos `cases_30d` e `capacidade_mensal`
- **US-2.1.2**: Testar distribuição justa
  - Validar que advogados com menos casos recebem mais ofertas
  - Verificar round-robin em caso de empate
- **US-2.1.3**: Agendar execução diária

#### **Epic 2.2: Monitoramento e Observabilidade**
- **US-2.2.1**: Implementar métricas Prometheus
  - Métricas de sucesso/falha de jobs
  - Latência de processamento
  - Contadores de ofertas/contratos
- **US-2.2.2**: Configurar alertas
  - Falha de jobs críticos
  - Muitas ofertas expirando
  - Latência alta no matching
- **US-2.2.3**: Dashboard Grafana
  - Visão geral do sistema
  - Métricas de negócio
  - Status dos jobs

#### **Epic 2.3: Validação A/B para LTR**
- **US-2.3.1**: Implementar framework A/B
  - Dividir tráfego entre modelo atual e novo
  - Coletar métricas de performance
- **US-2.3.2**: Automatizar retreino
  - Trigger baseado em volume de dados
  - Validação automática de novos modelos
- **US-2.3.3**: Rollback automático
  - Detectar degradação de performance
  - Voltar para modelo anterior

#### **Epic 2.4: Fallbacks e Resiliência**
- **US-2.4.1**: Implementar fallback para embeddings
  - Modelo local sentence-transformers
  - Fallback automático em caso de falha OpenAI
- **US-2.4.2**: Fallback para contratos
  - Assinatura manual quando DocuSign falha
  - Processo de backup
- **US-2.4.3**: Timeouts configuráveis
  - Timeout para chamadas LLM
  - Timeout para APIs externas

### **📊 SPRINT 3: OTIMIZAÇÕES E FEATURES (2 semanas)**
**Objetivo:** Melhorar performance e adicionar funcionalidades

#### **Epic 3.1: Otimizações de Performance**
- **US-3.1.1**: Otimizar queries de matching
  - Índices específicos para filtros
  - Cache de resultados frequentes
- **US-3.1.2**: Paralelização de embeddings
  - Processar múltiplos casos simultaneamente
  - Pool de conexões OpenAI
- **US-3.1.3**: Compressão de dados
  - Compressão de vetores embeddings
  - Otimização de storage pgvector

#### **Epic 3.2: Análise de Sentimento**
- **US-3.2.1**: Implementar análise de reviews
  - Classificar sentimento dos comentários
  - Extrair tópicos principais
- **US-3.2.2**: Integrar ao algoritmo
  - Usar sentimento como feature adicional
  - Ajustar pesos baseado em feedback

#### **Epic 3.3: Métricas Avançadas**
- **US-3.3.1**: Implementar métricas de negócio
  - Taxa de conversão (oferta → contrato)
  - Tempo médio de resposta
  - Satisfação por área jurídica
- **US-3.3.2**: Relatórios automatizados
  - Relatório semanal de performance
  - Alertas de tendências negativas

---

## 🎯 **CRITÉRIOS DE ACEITAÇÃO**

### **Definição de Pronto (DoD)**
- [ ] Código implementado e testado
- [ ] Testes unitários passando (>80% cobertura)
- [ ] Testes de integração validados
- [ ] Documentação atualizada
- [ ] Métricas implementadas
- [ ] Logs estruturados
- [ ] Review de código aprovado

### **Critérios de Sucesso por Sprint**

#### **Sprint 1 - Funcionalidade Básica**
- [ ] Pipeline completo funciona ponta-a-ponta
- [ ] Triagem → Matching → Ofertas → Contratos
- [ ] Advogados recebem notificações
- [ ] Jobs rodam automaticamente
- [ ] Testes principais passando

#### **Sprint 2 - Operação Estável**
- [ ] Sistema roda 24/7 sem intervenção manual
- [ ] Distribuição justa de casos
- [ ] Alertas funcionando
- [ ] Métricas coletadas
- [ ] Fallbacks testados

#### **Sprint 3 - Otimização**
- [ ] Performance melhorada (latência <2s)
- [ ] Análise de sentimento funcionando
- [ ] Relatórios automatizados
- [ ] Sistema completamente autônomo

---

## 📚 **DOCUMENTAÇÃO TÉCNICA**

### **Arquivos de Configuração**

#### **docker-compose.yml Atualizado**
```yaml
services:
  # ... serviços existentes ...
  
  celery-beat:
    build:
      context: .
      dockerfile: backend/Dockerfile
    volumes:
      - ./backend:/app/backend
    env_file:
      - .env
    depends_on:
      - db
      - redis
    command: celery -A backend.celery_app beat --loglevel=info
    
  prometheus:
    image: prom/prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      
  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
```

#### **Celery Beat Configuration**
```python
# backend/celery_app.py
from celery.schedules import crontab

celery_app.conf.beat_schedule = {
    'expire-offers': {
        'task': 'backend.jobs.expire_offers.expire_offers_task',
        'schedule': crontab(minute=0),  # Toda hora
    },
    'jusbrasil-sync': {
        'task': 'backend.jobs.jusbrasil_sync.sync_all_lawyers_task',
        'schedule': crontab(hour=3, minute=0),  # 3:00 AM diário
    },
    'update-review-kpi': {
        'task': 'backend.jobs.update_review_kpi.update_kpi_task',
        'schedule': crontab(hour=4, minute=0),  # 4:00 AM diário
    },
}
```

### **Migrações SQL Necessárias**

#### **Migração: Adicionar Campos de Matching**
```sql
-- supabase/migrations/20250125000000_add_matching_fields.sql

-- Adicionar campos faltantes para o algoritmo de matching
ALTER TABLE public.lawyers 
ADD COLUMN IF NOT EXISTS tags_expertise TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS cases_30d INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS capacidade_mensal INTEGER DEFAULT 10,
ADD COLUMN IF NOT EXISTS geo_latlon POINT;

-- Migrar dados existentes
UPDATE public.lawyers 
SET tags_expertise = CASE 
    WHEN specialties IS NOT NULL THEN string_to_array(specialties, ',')
    ELSE '{}'
END;

UPDATE public.lawyers 
SET geo_latlon = CASE 
    WHEN lat IS NOT NULL AND lng IS NOT NULL THEN point(lng, lat)
    ELSE NULL
END;

-- Criar índices para performance
CREATE INDEX IF NOT EXISTS idx_lawyers_tags_expertise ON public.lawyers USING GIN(tags_expertise);
CREATE INDEX IF NOT EXISTS idx_lawyers_geo_latlon ON public.lawyers USING GIST(geo_latlon);
CREATE INDEX IF NOT EXISTS idx_lawyers_cases_30d ON public.lawyers(cases_30d);
```

### **Estrutura de Testes**

#### **Teste de Integração Ponta-a-Ponta**
```python
# tests/test_integration_full_pipeline.py
import pytest
from backend.services.triage_service import TriageService
from backend.services.match_service import MatchService
from backend.services.offer_service import OfferService

@pytest.mark.asyncio
async def test_full_pipeline():
    """Testa o pipeline completo: triagem → matching → ofertas"""
    
    # 1. Triagem
    case_text = "Preciso de ajuda com processo trabalhista..."
    triage_result = await TriageService.run_triage(case_text)
    
    assert triage_result['area'] == 'Trabalhista'
    assert 'embedding' in triage_result
    
    # 2. Matching
    matches = await MatchService.find_matches(triage_result)
    
    assert len(matches) > 0
    assert all(m['fair_score'] > 0 for m in matches)
    
    # 3. Ofertas
    offers = await OfferService.create_offers(case_id=1, matches=matches)
    
    assert len(offers) > 0
    assert all(o['status'] == 'pending' for o in offers)
```

### **Métricas e Monitoramento**

#### **Métricas Prometheus**
```python
# backend/metrics.py
from prometheus_client import Counter, Histogram, Gauge

# Contadores
triage_requests_total = Counter('triage_requests_total', 'Total triage requests')
matches_found_total = Counter('matches_found_total', 'Total matches found')
offers_created_total = Counter('offers_created_total', 'Total offers created')
contracts_signed_total = Counter('contracts_signed_total', 'Total contracts signed')

# Histogramas para latência
triage_duration = Histogram('triage_duration_seconds', 'Triage processing time')
matching_duration = Histogram('matching_duration_seconds', 'Matching processing time')

# Gauges para estado atual
active_offers = Gauge('active_offers_count', 'Number of active offers')
pending_contracts = Gauge('pending_contracts_count', 'Number of pending contracts')
```

---

## 🔄 **PROCESSO DE EXECUÇÃO**

### **Fase 1: Preparação**
1. **Setup do Ambiente**
   - Configurar variáveis de ambiente
   - Instalar dependências
   - Configurar banco de dados

2. **Backup de Segurança**
   - Backup do banco de dados atual
   - Backup dos arquivos de configuração
   - Documentar estado atual

### **Fase 2: Execução dos Sprints**
1. **Sprint Planning**
   - Refinamento das user stories
   - Estimativa de esforço
   - Definição de critérios de aceitação

2. **Desenvolvimento**
   - Implementação das correções
   - Testes unitários e integração
   - Code review

3. **Validação**
   - Testes em ambiente de staging
   - Validação com dados reais
   - Performance testing

### **Fase 3: Deploy e Monitoramento**
1. **Deploy Gradual**
   - Deploy em ambiente de staging
   - Testes de aceitação
   - Deploy em produção

2. **Monitoramento**
   - Acompanhar métricas
   - Verificar logs
   - Validar funcionamento

### **Fase 4: Documentação Final**
1. **Atualização de Docs**
   - Documentação técnica
   - Guias de operação
   - Runbooks

2. **Transferência de Conhecimento**
   - Treinamento da equipe
   - Documentação de processos
   - Handover completo

---

## 📞 **PRÓXIMOS PASSOS**

### **Imediato (Esta Semana)**
1. **Aprovação do Plano**: Review e aprovação dos sprints
2. **Setup do Ambiente**: Preparar ambiente de desenvolvimento
3. **Priorização**: Confirmar prioridades e recursos

### **Sprint 1 (Próximas 2 Semanas)**
1. **Início Imediato**: Começar com correções críticas
2. **Daily Standups**: Acompanhamento diário
3. **Testes Contínuos**: Validação constante

### **Longo Prazo (Próximos 2 Meses)**
1. **Execução Completa**: Todos os 3 sprints
2. **Otimização Contínua**: Melhorias baseadas em feedback
3. **Expansão**: Novas funcionalidades

---

**📋 Este documento serve como guia completo para a correção e otimização do sistema LITGO5. Cada sprint está detalhado com user stories, critérios de aceitação e documentação técnica necessária para execução bem-sucedida.** 