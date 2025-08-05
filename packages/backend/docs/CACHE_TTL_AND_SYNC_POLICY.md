# Política de Cache e Atualizações - Sistema Escavador

## ⏰ Tempos de Armazenamento (TTL - Time To Live)

### 📊 Resumo Geral
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     REDIS       │    │   POSTGRESQL    │    │   LIMPEZA       │
│    1 HORA       │───▶│    24 HORAS     │───▶│   7 DIAS        │
│  Cache Rápido   │    │ Cache Persistente│    │ Exclusão Final  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### 🎯 Configurações Detalhadas

#### 1. **Redis (Cache Rápido)**
- **TTL**: `1 hora (3600 segundos)`
- **Propósito**: Acesso ultra-rápido (50-200ms)
- **Localização**: `services/process_cache_service.py:33`
```python
self.redis_ttl_seconds = 3600  # 1 hora no Redis
```

#### 2. **PostgreSQL (Cache Persistente)**
- **TTL Válido**: `24 horas`
- **TTL Máximo**: `7 dias`
- **Propósito**: Funcionamento offline e dados históricos
- **Localização**: `services/process_cache_service.py:34`
```python
self.db_ttl_hours = 24  # 24 horas no banco considera válido
self.db_max_age_days = 7  # 7 dias máximo no banco
```

#### 3. **Limpeza Automática**
- **Movimentações**: Excluídas após `7 dias`
- **Status Cache**: Excluído após `1 dia` de expiração
- **Função**: `clean_expired_process_cache()`
```sql
-- Limpar movimentações antigas (mais de 7 dias)
DELETE FROM public.process_movements
WHERE fetched_from_api_at < NOW() - INTERVAL '7 days';

-- Limpar status cache expirado  
DELETE FROM public.process_status_cache
WHERE cache_valid_until < NOW() - INTERVAL '1 day';
```

## 🔄 Frequência de Atualizações

### 📅 Job de Sincronização Automática

#### **Configuração Principal**
```python
# jobs/process_cache_sync_job.py
self.sync_interval_minutes = 30      # Executa a cada 30 minutos
self.batch_size = 10                 # Processa 10 processos por vez
self.max_daily_syncs = 200          # Limite diário de sincronizações
self.priority_threshold_hours = 2    # Prioriza se expira em 2h
```

#### **Cronograma de Execução**
| Frequência | Ação | Detalhes |
|------------|------|----------|
| **A cada 30 minutos** | Verificação geral | Job principal rodando em background |
| **A cada 2 horas** | Sincronização prioritária | Processos prestes a expirar |
| **A cada 6 horas** | Sincronização padrão | Processos sem sync recente |
| **Diariamente** | Limpeza automática | Remove dados expirados |

### 🎯 Critérios de Atualização

#### **Prioridade Alta** (A cada 2 horas)
```sql
-- Processos expirando em 2 horas
WHERE cache_valid_until BETWEEN NOW() AND NOW() + INTERVAL '2 hours'
```

#### **Prioridade Normal** (A cada 6 horas)  
```sql
-- Processos sem sync há 6+ horas
WHERE last_api_sync < NOW() - INTERVAL '6 hours'
```

#### **Processos Ativos** (Últimos 7 dias)
```sql
-- Apenas processos recentemente acessados
WHERE fetched_from_api_at > NOW() - INTERVAL '7 days'
```

## 📈 Estratégia de Cache Inteligente

### 🔍 Fluxo de Busca
1. **Redis** → Se encontrado: retorna em 50-200ms
2. **PostgreSQL** → Se encontrado e válido (< 24h): retorna em 200-500ms
3. **API Escavador** → Busca dados frescos: 2-5s

### 💾 Fluxo de Armazenamento
1. **Dados da API** → Salvos simultaneamente no Redis + PostgreSQL
2. **TTL Redis** → 1 hora para acesso rápido
3. **TTL PostgreSQL** → 24 horas para dados válidos, 7 dias para backup offline

### 🎛️ Configurações por Tipo de Dado

#### **Movimentações Processuais**
```python
# Configuração específica
data_freshness_hours = 24  # Válido por 24 horas
redis_ttl = 3600          # 1 hora no Redis  
max_age_days = 7          # 7 dias no PostgreSQL
```

#### **Status de Processo**
```sql
-- Tabela: process_status_cache
cache_valid_until = NOW() + INTERVAL '24 hours'  -- Válido 24h
last_api_sync = NOW()                             -- Última sync
```

## ⚙️ Configuração Personalizável

### 🔧 Variáveis de Ambiente
```bash
# TTL do Escavador (horas)
ESCAVADOR_CACHE_TTL_HOURS=12

# Intervalo do job (minutos)  
SYNC_INTERVAL_MINUTES=30

# Limite diário de sincronizações
MAX_DAILY_SYNCS=200

# TTL padrão (segundos)
CACHE_TTL_SECONDS=21600  # 6 horas
```

### 📊 TTL por Fonte de Dados
```python
# config/const.py
CACHE_TTL_SECONDS = {
    "escavador_processes": 8 * 3600,    # 8 horas
    "escavador_movements": 4 * 3600,    # 4 horas  
    "escavador_documents": 6 * 3600,    # 6 horas
    "process_status": 24 * 3600,        # 24 horas
    "lawyer_curriculum": 12 * 3600,     # 12 horas
}
```

## 📊 Monitoramento e Métricas

### 🎯 KPIs do Sistema
- **Cache Hit Rate**: 85-95% esperado
- **Tempo de Resposta Redis**: 50-200ms
- **Tempo de Resposta PostgreSQL**: 200-500ms  
- **Economia de API Calls**: 90%+
- **Uptime Offline**: 100% com dados cached

### 📈 Logs de Monitoramento
```python
# Exemplos de logs gerados
logger.info(f"✅ Cache hit (Redis): CNJ {cnj} - 87ms")
logger.info(f"💾 Cache hit (PostgreSQL): CNJ {cnj} - 234ms")  
logger.info(f"🌐 API call: CNJ {cnj} - 3.2s")
logger.info(f"🔄 Sync job: 15 processos atualizados em 45s")
```

## 🚨 Situações Especiais

### 📴 Funcionamento Offline
```python
# Quando API indisponível
if api_error:
    # Busca dados mesmo expirados
    fallback_data = await get_from_database(cnj, include_expired=True)
    if fallback_data:
        logger.warning(f"⚠️ Usando dados expirados (offline): CNJ {cnj}")
        return fallback_data
```

### 🔄 Force Refresh
```python
# Força atualização imediata
await client.get_detailed_process_movements(cnj, force_refresh=True)
# Ignora cache e busca direto da API
```

### 🧹 Limpeza Manual
```python
# Executar limpeza manual
await database.execute("SELECT clean_expired_process_cache()")
```

## 📝 Resumo Executivo

| Aspecto | Configuração | Benefício |
|---------|-------------|-----------|
| **Redis TTL** | 1 hora | Respostas ultra-rápidas |
| **PostgreSQL TTL** | 24 horas válido, 7 dias máximo | Funcionamento offline |
| **Sync Job** | A cada 30 minutos | Dados sempre atualizados |
| **Priorização** | Expirando em 2h = prioridade | Evita expiração |
| **Limpeza** | Automática diária | Performance otimizada |
| **Offline** | Dados expirados aceitos | 100% uptime |

### 🎯 **Resultado Final**
- **90%+ menos consultas à API** do Escavador
- **10-20x mais rápido** que consultas diretas
- **100% funcionamento offline** com dados cached
- **Atualizações automáticas** em background
- **Limpeza automática** para performance otimizada 