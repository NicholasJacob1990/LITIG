# 🚀 SPRINT 1: CORREÇÕES CRÍTICAS - PLANO DETALHADO

> **Duração:** 2 semanas (10 dias úteis)  
> **Objetivo:** Fazer o sistema funcionar ponta-a-ponta  
> **Prioridade:** P0 - Crítico para produção  

## 📋 VISÃO GERAL

Este sprint foca nas **correções críticas** que impedem o sistema de funcionar completamente. Após este sprint, o pipeline completo deve funcionar do início ao fim: Triagem → Matching → Ofertas → Contratos.

## 🎯 OBJETIVOS DO SPRINT

### Principais Entregas
1. **Sistema Funcionando Ponta-a-Ponta**: Pipeline completo operacional
2. **Notificações Funcionando**: Advogados recebem ofertas via push/email
3. **Jobs Automatizados**: Execução automática de tarefas críticas
4. **Testes Atualizados**: Cobertura de testes sincronizada com código

### Métricas de Sucesso
- [ ] Pipeline completo funciona sem erro
- [ ] Notificações chegam aos advogados
- [ ] Jobs rodam automaticamente
- [ ] Testes principais passando (>80%)

## 📊 ÉPICOS E USER STORIES

### 🔧 EPIC 1.1: Correção Schema-Código
**Problema:** Código usa campos que não existem na tabela `lawyers`

#### US-1.1.1: Criar migração para adicionar campos faltantes
**Como** desenvolvedor  
**Quero** adicionar os campos necessários na tabela lawyers  
**Para que** o algoritmo de matching funcione corretamente  

**Critérios de Aceitação:**
- [ ] Campo `tags_expertise` adicionado como array de strings
- [ ] Campo `cases_30d` adicionado como integer com default 0
- [ ] Campo `capacidade_mensal` adicionado como integer com default 10
- [ ] Campo `geo_latlon` adicionado como point para queries geográficas
- [ ] Índices criados para performance
- [ ] Migração testada em ambiente de desenvolvimento

**Implementação:**
```sql
-- supabase/migrations/20250125000000_add_matching_fields.sql
ALTER TABLE public.lawyers 
ADD COLUMN IF NOT EXISTS tags_expertise TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS cases_30d INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS capacidade_mensal INTEGER DEFAULT 10,
ADD COLUMN IF NOT EXISTS geo_latlon POINT;

-- Criar índices
CREATE INDEX IF NOT EXISTS idx_lawyers_tags_expertise ON public.lawyers USING GIN(tags_expertise);
CREATE INDEX IF NOT EXISTS idx_lawyers_geo_latlon ON public.lawyers USING GIST(geo_latlon);
CREATE INDEX IF NOT EXISTS idx_lawyers_cases_30d ON public.lawyers(cases_30d);
```

**Estimativa:** 1 dia

#### US-1.1.2: Implementar mapeamento de campos existentes
**Como** desenvolvedor  
**Quero** migrar dados existentes para os novos campos  
**Para que** não haja perda de dados históricos  

**Critérios de Aceitação:**
- [ ] Dados de `specialties` migrados para `tags_expertise`
- [ ] Coordenadas `lat`/`lng` convertidas para `geo_latlon`
- [ ] Função de mapeamento criada e testada
- [ ] Dados validados após migração

**Implementação:**
```sql
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
```

**Estimativa:** 1 dia

#### US-1.1.3: Testar integração ponta-a-ponta
**Como** desenvolvedor  
**Quero** validar que o algoritmo funciona com os novos campos  
**Para que** o matching seja executado corretamente  

**Critérios de Aceitação:**
- [ ] Teste de matching completo executado
- [ ] Filtros geográficos funcionando
- [ ] Features calculadas corretamente
- [ ] Scores gerados sem erro

**Implementação:**
```python
# tests/test_integration_matching.py
@pytest.mark.asyncio
async def test_full_matching_pipeline():
    # Criar caso de teste
    case_data = {
        "area": "Trabalhista",
        "embedding": [0.1, 0.2, ...],
        "urgency": "high"
    }
    
    # Executar matching
    matches = await MatchService.find_matches(case_data)
    
    # Validar resultados
    assert len(matches) > 0
    assert all(m['fair_score'] > 0 for m in matches)
```

**Estimativa:** 1 dia

---

### 📱 EPIC 1.2: Implementação de Notificações
**Problema:** Funções de notificação não estão implementadas

#### US-1.2.1: Implementar send_push_notification
**Como** sistema  
**Quero** enviar notificações push via OneSignal  
**Para que** advogados sejam notificados sobre novas ofertas  

**Critérios de Aceitação:**
- [ ] Função `send_push_notification` implementada
- [ ] Integração OneSignal funcionando
- [ ] Tratamento de erros implementado
- [ ] Retry com backoff exponencial
- [ ] Testes unitários passando

**Implementação:**
```python
# backend/services/notify_service.py
async def send_push_notification(user_id: str, title: str, message: str, data: dict = None):
    """Envia notificação push via OneSignal"""
    try:
        onesignal_client = OneSignalClient(
            app_id=ONESIGNAL_APP_ID,
            rest_api_key=ONESIGNAL_REST_API_KEY
        )
        
        notification = {
            "include_external_user_ids": [user_id],
            "headings": {"en": title},
            "contents": {"en": message},
            "data": data or {}
        }
        
        response = await onesignal_client.send_notification(notification)
        logger.info(f"Push notification sent to {user_id}: {response}")
        return True
        
    except Exception as e:
        logger.error(f"Failed to send push notification: {e}")
        return False
```

**Estimativa:** 1.5 dias

#### US-1.2.2: Implementar send_email_notification
**Como** sistema  
**Quero** enviar notificações por email via SendGrid  
**Para que** haja fallback quando push notification falha  

**Critérios de Aceitação:**
- [ ] Função `send_email_notification` implementada
- [ ] Integração SendGrid funcionando
- [ ] Template de email criado
- [ ] Tratamento de erros implementado
- [ ] Testes unitários passando

**Implementação:**
```python
async def send_email_notification(email: str, subject: str, content: str):
    """Envia notificação por email via SendGrid"""
    try:
        sg = SendGridAPIClient(api_key=SENDGRID_API_KEY)
        
        message = Mail(
            from_email=FROM_EMAIL,
            to_emails=email,
            subject=subject,
            html_content=content
        )
        
        response = await sg.send(message)
        logger.info(f"Email sent to {email}: {response.status_code}")
        return True
        
    except Exception as e:
        logger.error(f"Failed to send email: {e}")
        return False
```

**Estimativa:** 1 dia

#### US-1.2.3: Configurar credenciais e testar envio
**Como** desenvolvedor  
**Quero** configurar as credenciais das APIs  
**Para que** as notificações sejam enviadas corretamente  

**Critérios de Aceitação:**
- [ ] Credenciais OneSignal configuradas
- [ ] Credenciais SendGrid configuradas
- [ ] Teste de envio real executado
- [ ] Notificações chegando aos destinatários

**Implementação:**
```bash
# .env
ONESIGNAL_APP_ID=your_app_id
ONESIGNAL_REST_API_KEY=your_rest_api_key
SENDGRID_API_KEY=your_sendgrid_key
FROM_EMAIL=noreply@litgo.com
```

**Estimativa:** 0.5 dias

---

### ⏰ EPIC 1.3: Configuração de Agendamento
**Problema:** Jobs não rodam automaticamente

#### US-1.3.1: Adicionar Celery Beat ao docker-compose
**Como** desenvolvedor  
**Quero** configurar o scheduler Celery Beat  
**Para que** jobs sejam executados automaticamente  

**Critérios de Aceitação:**
- [ ] Serviço celery-beat adicionado ao docker-compose
- [ ] Configuração correta de dependências
- [ ] Volumes mapeados corretamente
- [ ] Serviço iniciando sem erro

**Implementação:**
```yaml
# docker-compose.yml
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
```

**Estimativa:** 0.5 dias

#### US-1.3.2: Configurar periodic tasks
**Como** desenvolvedor  
**Quero** configurar tarefas periódicas no Celery  
**Para que** jobs críticos sejam executados regularmente  

**Critérios de Aceitação:**
- [ ] Job `expire_offers` configurado para rodar de hora em hora
- [ ] Job `jusbrasil_sync` configurado para rodar diariamente às 3h
- [ ] Job `update_review_kpi` configurado para rodar diariamente às 4h
- [ ] Configuração testada e funcionando

**Implementação:**
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

**Estimativa:** 1 dia

#### US-1.3.3: Testar execução automática
**Como** desenvolvedor  
**Quero** validar que jobs são executados automaticamente  
**Para que** o sistema funcione sem intervenção manual  

**Critérios de Aceitação:**
- [ ] Jobs executando nos horários configurados
- [ ] Logs de execução sendo gerados
- [ ] Resultados dos jobs validados
- [ ] Monitoramento básico funcionando

**Estimativa:** 0.5 dias

---

### 🧪 EPIC 1.4: Correção de Testes
**Problema:** Testes desatualizados com código atual

#### US-1.4.1: Atualizar testes da Fase 1 (triagem)
**Como** desenvolvedor  
**Quero** corrigir testes da triagem  
**Para que** reflitam a implementação atual  

**Critérios de Aceitação:**
- [ ] Referências a `run_triage_async_task` removidas
- [ ] Testes usando `run_full_triage_flow_task`
- [ ] Todos os testes da triagem passando
- [ ] Cobertura de testes mantida

**Implementação:**
```python
# tests/test_triage.py
@pytest.mark.asyncio
async def test_triage_full_flow():
    # Atualizar para usar a task correta
    result = await run_full_triage_flow_task.apply_async(
        args=["Preciso de ajuda com processo trabalhista"]
    )
    
    assert result.status == 'SUCCESS'
    assert 'area' in result.result
```

**Estimativa:** 1 dia

#### US-1.4.2: Atualizar testes da Fase 7 (offers)
**Como** desenvolvedor  
**Quero** sincronizar testes das ofertas  
**Para que** reflitam a implementação atual  

**Critérios de Aceitação:**
- [ ] Testes de expiração de ofertas funcionando
- [ ] Testes de criação de ofertas atualizados
- [ ] Todos os testes das ofertas passando
- [ ] Cobertura de testes mantida

**Estimativa:** 1 dia

## 📅 CRONOGRAMA DETALHADO

### Semana 1 (Dias 1-5)
| Dia | Atividade | Responsável | Status |
|:---:|:---|:---|:---:|
| 1 | US-1.1.1: Criar migração campos | Dev Backend | ⏳ |
| 1 | US-1.1.2: Mapear campos existentes | Dev Backend | ⏳ |
| 2 | US-1.1.3: Testar integração | Dev Backend | ⏳ |
| 2 | US-1.2.1: Implementar push notification | Dev Backend | ⏳ |
| 3 | US-1.2.1: Continuar push notification | Dev Backend | ⏳ |
| 3 | US-1.2.2: Implementar email notification | Dev Backend | ⏳ |
| 4 | US-1.2.3: Configurar credenciais | Dev Backend | ⏳ |
| 4 | US-1.3.1: Configurar Celery Beat | DevOps | ⏳ |
| 5 | US-1.3.2: Configurar periodic tasks | Dev Backend | ⏳ |

### Semana 2 (Dias 6-10)
| Dia | Atividade | Responsável | Status |
|:---:|:---|:---|:---:|
| 6 | US-1.3.3: Testar execução automática | Dev Backend | ⏳ |
| 7 | US-1.4.1: Atualizar testes triagem | Dev Backend | ⏳ |
| 8 | US-1.4.2: Atualizar testes offers | Dev Backend | ⏳ |
| 9 | Testes de integração completos | QA | ⏳ |
| 10 | Validação final e documentação | Tech Lead | ⏳ |

## 🧪 ESTRATÉGIA DE TESTES

### Testes Unitários
- [ ] Cada função implementada tem testes unitários
- [ ] Cobertura mínima de 80%
- [ ] Mocks para APIs externas (OneSignal, SendGrid)

### Testes de Integração
- [ ] Pipeline completo testado ponta-a-ponta
- [ ] Notificações testadas com contas reais
- [ ] Jobs testados com dados reais

### Testes de Aceitação
- [ ] Cenários de usuário validados
- [ ] Performance básica validada
- [ ] Logs e métricas funcionando

## 🚀 CRITÉRIOS DE ACEITAÇÃO DO SPRINT

### Funcionalidades Básicas
- [ ] **Pipeline Completo**: Triagem → Matching → Ofertas → Contratos funcionando
- [ ] **Notificações**: Advogados recebem push notifications e emails
- [ ] **Jobs Automáticos**: Ofertas expiram automaticamente, KPIs são atualizados
- [ ] **Dados Corretos**: Algoritmo usa campos corretos da tabela lawyers

### Qualidade
- [ ] **Testes Passando**: >80% dos testes unitários passando
- [ ] **Logs Estruturados**: Todas as operações logadas em JSON
- [ ] **Tratamento de Erros**: Fallbacks funcionando corretamente
- [ ] **Performance**: Latência <5s para operações críticas

### Operação
- [ ] **Docker Compose**: Todos os serviços sobem corretamente
- [ ] **Configuração**: Variáveis de ambiente documentadas
- [ ] **Monitoramento**: Logs disponíveis para debug
- [ ] **Rollback**: Processo de rollback documentado

## 🔧 CONFIGURAÇÃO DE AMBIENTE

### Variáveis de Ambiente Necessárias
```bash
# APIs de Notificação
ONESIGNAL_APP_ID=your_app_id
ONESIGNAL_REST_API_KEY=your_rest_api_key
SENDGRID_API_KEY=your_sendgrid_key
FROM_EMAIL=noreply@litgo.com

# Celery
CELERY_BROKER_URL=redis://localhost:6379
CELERY_RESULT_BACKEND=redis://localhost:6379

# Banco de Dados
SUPABASE_URL=your_supabase_url
SUPABASE_SERVICE_KEY=your_service_key
```

### Comandos de Deploy
```bash
# Executar migrações
supabase db push

# Iniciar serviços
docker-compose up -d

# Verificar jobs
celery -A backend.celery_app inspect active

# Monitorar logs
docker-compose logs -f celery-beat
```

## 📊 MÉTRICAS DE SUCESSO

### Métricas Técnicas
- **Uptime**: >99% dos serviços funcionando
- **Latência**: <5s para operações críticas
- **Taxa de Erro**: <1% nas operações
- **Cobertura de Testes**: >80%

### Métricas de Negócio
- **Notificações Entregues**: >95% das notificações chegam
- **Ofertas Processadas**: 100% das ofertas são processadas
- **Jobs Executados**: 100% dos jobs executam no horário
- **Pipeline Completo**: 100% dos casos passam pelo pipeline

## 🎯 DEFINIÇÃO DE PRONTO

Uma user story está pronta quando:
- [ ] Código implementado e testado
- [ ] Testes unitários passando
- [ ] Testes de integração validados
- [ ] Documentação atualizada
- [ ] Code review aprovado
- [ ] Deploy em staging validado
- [ ] Critérios de aceitação atendidos

## 📞 PRÓXIMOS PASSOS

### Após Sprint 1
1. **Validação em Produção**: Deploy gradual e monitoramento
2. **Sprint 2**: Melhorias operacionais e observabilidade
3. **Otimizações**: Baseadas no feedback do Sprint 1

### Riscos e Mitigações
- **Risco**: Migração de dados falha
  - **Mitigação**: Backup completo antes da migração
- **Risco**: APIs externas indisponíveis
  - **Mitigação**: Implementar fallbacks desde o início
- **Risco**: Performance degradada
  - **Mitigação**: Monitoramento contínuo e rollback rápido

---

**🎯 Este sprint é crítico para o sucesso do projeto. Foco total na execução e qualidade das entregas.** 