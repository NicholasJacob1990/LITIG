# Configuração da Nova Arquitetura de Triagem Inteligente

## 📋 Pré-requisitos

### 🔑 Chaves de API Necessárias

Adicione as seguintes variáveis ao seu arquivo `.env`:

```bash
# Anthropic (Claude) - OBRIGATÓRIO
ANTHROPIC_API_KEY=sk-ant-api03-...

# OpenAI (opcional, para estratégias ensemble)
OPENAI_API_KEY=sk-...

# Configurações existentes (manter)
SUPABASE_URL=...
SUPABASE_SERVICE_KEY=...
REDIS_URL=redis://localhost:6379/0
```

### 📦 Dependências

```bash
# Instalar nova dependência
pip install anthropic==0.8.1

# Ou atualizar tudo
pip install -r requirements.txt
```

## ⚙️ Configuração do Backend

### 1. Variáveis de Ambiente

```bash
# .env
# ===== Triagem Inteligente =====
ANTHROPIC_API_KEY=sk-ant-api03-...
OPENAI_API_KEY=sk-...

# Configurações opcionais
JUDGE_MODEL_PROVIDER=anthropic  # ou 'openai'
SIMPLE_MODEL_CLAUDE=claude-3-haiku-20240307
ENSEMBLE_MODEL_CLAUDE=claude-3-5-sonnet-20240620
JUDGE_MODEL_ANTHROPIC=claude-3-opus-20240229
JUDGE_MODEL_OPENAI=gpt-4-turbo

# Rate limiting
INTELLIGENT_TRIAGE_RATE_LIMIT=30  # requests per minute
CONVERSATION_RATE_LIMIT=60        # requests per minute
```

### 2. Inicialização dos Serviços

```python
# backend/main.py
from fastapi import FastAPI
from backend.routes.intelligent_triage_routes import router as intelligent_triage_router

app = FastAPI()

# Incluir as novas rotas
app.include_router(intelligent_triage_router)
```

### 3. Configuração do Redis (Opcional)

Para conversas persistentes em produção:

```bash
# Docker Compose
redis:
  image: redis:7-alpine
  ports:
    - "6379:6379"
  command: redis-server --appendonly yes
  volumes:
    - redis_data:/data
```

## 🚀 Configuração do Frontend

### 1. Importar Serviços

```typescript
// lib/services/intelligentTriage.ts já está criado
import { intelligentTriageService, useIntelligentTriage } from '@/lib/services/intelligentTriage';
```

### 2. Configurar Rotas

```typescript
// app/_layout.tsx ou router principal
// As rotas já estão criadas:
// - app/intelligent-triage.tsx
// - app/triage-result.tsx
```

### 3. Variáveis de Ambiente Frontend

```bash
# .env.local
EXPO_PUBLIC_API_URL=http://localhost:8000
# ou sua URL de produção
```

## 🔧 Configuração de Produção

### 1. Configurações de Performance

```python
# backend/services/intelligent_interviewer_service.py
# Configurações já otimizadas:

# Modelos por uso:
# - Conversa: claude-3-5-sonnet (qualidade)
# - Avaliação: claude-3-haiku (velocidade)
# - Análise simples: claude-3-5-sonnet
# - Juiz: claude-3-opus (precisão máxima)
```

### 2. Configurações de Memória

```python
# Para produção, usar Redis:
class IntelligentInterviewerService:
    def __init__(self):
        # Em produção, substituir por Redis
        self.active_conversations = RedisDict("conversations:")
```

### 3. Configurações de Rate Limiting

```python
# backend/routes/intelligent_triage_routes.py
# Já configurado com limites apropriados:

@router.post("/start")
@limiter.limit("30/minute")  # 30 conversas por minuto

@router.post("/continue")
@limiter.limit("60/minute")  # 60 mensagens por minuto
```

## 🧪 Testando a Configuração

### 1. Teste Básico de API

```bash
# Testar health check
curl http://localhost:8000/api/v2/triage/health

# Resposta esperada:
{
  "status": "healthy",
  "timestamp": "2025-01-03T...",
  "active_orchestrations": 0,
  "active_conversations": 0,
  "service_version": "2.0.0"
}
```

### 2. Teste de Conversa

```bash
# Iniciar conversa
curl -X POST http://localhost:8000/api/v2/triage/start \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"user_id": "test_user"}'

# Continuar conversa
curl -X POST http://localhost:8000/api/v2/triage/continue \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "case_id": "CASE_ID_RETORNADO",
    "message": "Recebi uma multa de trânsito"
  }'
```

### 3. Script de Teste Automatizado

```bash
# Executar suite de testes
python scripts/test_intelligent_triage.py

# Demonstração interativa
python scripts/test_intelligent_triage.py --demo
```

## 🔍 Monitoramento e Logs

### 1. Logs Estruturados

```python
# Os serviços já incluem logging detalhado:
import logging

# Configurar logger para triagem inteligente
logger = logging.getLogger("intelligent_triage")
logger.setLevel(logging.INFO)

# Logs incluem:
# - Início/fim de conversas
# - Detecção de complexidade
# - Estratégias acionadas
# - Tempos de processamento
# - Erros e fallbacks
```

### 2. Métricas

```python
# Métricas automáticas disponíveis:
GET /api/v2/triage/stats

# Retorna:
{
  "totals": {
    "active_orchestrations": 5,
    "active_conversations": 8
  },
  "by_status": {
    "interviewing": 8,
    "completed": 15,
    "error": 1
  },
  "by_complexity": {
    "low": 10,
    "medium": 8,
    "high": 6
  }
}
```

### 3. Alertas

```python
# Configurar alertas para:
# - Taxa de erro > 5%
# - Tempo de resposta > 10s
# - Uso de API > 80% do limite
# - Conversas órfãs > 1h
```

## 🔄 Migração do Sistema Atual

### 1. Estratégia de Migração Gradual

```python
# Fase 1: Coexistência (ATUAL)
# - API v1 mantida funcionando
# - API v2 disponível em paralelo
# - Frontend com opção de escolha

# Fase 2: Migração Gradual
# - Redirecionar % dos usuários para v2
# - A/B testing para comparar performance
# - Monitorar métricas de qualidade

# Fase 3: Migração Completa
# - Todos os novos casos usam v2
# - v1 apenas para casos legados
# - Preparar deprecação da v1
```

### 2. Fallbacks Automáticos

```python
# Sistema já inclui fallbacks:
# 1. Se IA Entrevistadora falha → Sistema antigo
# 2. Se Anthropic falha → OpenAI (se disponível)
# 3. Se ambas falham → Análise regex básica
# 4. Se orquestrador falha → Triagem direta
```

### 3. Dados Compatíveis

```python
# Estrutura de dados compatível:
# - Mesmas tabelas do banco
# - Mesmos campos de saída
# - Mesmo formato de matching
# - APIs podem ser intercambiáveis
```

## 🎯 Otimizações Recomendadas

### 1. Cache Inteligente

```python
# Implementar cache para:
# - Respostas da IA para perguntas similares
# - Avaliações de complexidade recorrentes
# - Dados de advogados (features estáticas)
```

### 2. Batch Processing

```python
# Para alta escala:
# - Processar múltiplas avaliações em batch
# - Queue de conversas para otimizar uso de API
# - Pré-computar features estáticas
```

### 3. Fine-tuning

```python
# Melhorias baseadas em dados reais:
# - Coletar feedback dos usuários
# - Analisar conversas bem-sucedidas
# - Ajustar prompts baseado em padrões
# - Treinar modelos específicos do domínio
```

## 🛡️ Segurança e Privacidade

### 1. Proteção de Dados

```python
# Medidas implementadas:
# - Rate limiting por usuário
# - Validação de entrada
# - Sanitização de dados
# - Logs sem informações sensíveis
# - Cleanup automático de conversas
```

### 2. Controle de Acesso

```python
# Autenticação obrigatória:
# - Todas as rotas requerem token válido
# - Validação de usuário em cada request
# - Isolamento de dados por usuário
```

### 3. LGPD/GDPR

```python
# Conformidade:
# - Dados processados apenas para o propósito
# - Retenção mínima necessária
# - Cleanup automático após processamento
# - Logs anonimizados
```

## 📊 Métricas de Sucesso

### 1. Métricas Técnicas

- **Latência**: < 2s para casos simples, < 5s para complexos
- **Precisão**: > 90% na detecção de complexidade
- **Disponibilidade**: > 99.5% uptime
- **Taxa de erro**: < 2%

### 2. Métricas de Negócio

- **Economia de custos**: 70% redução em casos simples
- **Satisfação do usuário**: > 4.5/5 na experiência
- **Conversão**: > 80% completam a triagem
- **Qualidade**: > 95% dos resultados são úteis

### 3. Métricas de Produto

- **Tempo de triagem**: Redução de 60% vs formulário
- **Dados coletados**: 40% mais campos preenchidos
- **Abandono**: < 10% das conversas abandonadas
- **Retorno**: > 60% dos usuários usam novamente

---

## ✅ Checklist de Configuração

### Backend
- [ ] Variáveis de ambiente configuradas
- [ ] Dependências instaladas
- [ ] Rotas incluídas no app principal
- [ ] Redis configurado (produção)
- [ ] Logs configurados
- [ ] Rate limiting ativo

### Frontend
- [ ] Serviços importados
- [ ] Rotas configuradas
- [ ] Variáveis de ambiente definidas
- [ ] Componentes testados

### Produção
- [ ] Health checks funcionando
- [ ] Métricas sendo coletadas
- [ ] Alertas configurados
- [ ] Backup/recovery testado
- [ ] Documentação atualizada

### Testes
- [ ] Suite de testes executada
- [ ] Demonstração interativa testada
- [ ] A/B testing configurado
- [ ] Monitoramento ativo

---

**Status**: ✅ **Pronto para Produção**  
**Versão**: 2.0.0  
**Última atualização**: Janeiro 2025 