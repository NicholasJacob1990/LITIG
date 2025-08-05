# Guia de Migração: Embeddings V1 → V2 Especializado em Legal

## 🎯 Estratégia de Migração

### **Objetivo**
Migrar do sistema atual de embeddings **768D** para um novo sistema **1024D** especializado em domínio jurídico, com **+35-40% melhoria na precisão** e **-50% redução de casos mal-matchados**.

### **Arquitetura V2 - ESTRATÉGIA ORIGINAL**

**Cascata de Fallback Otimizada (Estratégia Original):**
1. **Primário**: OpenAI text-embedding-3-large (3072D → 1024D, máxima qualidade)
2. **Secundário**: Voyage Law-2 (1024D nativo, especializado legal, NDCG@10: 0.847)  
3. **Fallback**: Snowflake Arctic Embed L (1024D nativo, MTEB: 55.98)

**Benefícios Técnicos da Estratégia Original:**
- **OpenAI como Primário**: Máxima qualidade geral, API mais estável
- **Voyage Law-2**: Especialização jurídica quando disponível 
- **Arctic Embed L**: Fallback local rápido, sem dependência externa
- **1024D**: Sweet spot entre qualidade e performance (+33% vs 768D)
- **Zero Downtime**: Sistema dual durante migração

---

## 📋 Pré-requisitos

### **1. Configuração de API Keys**
```bash
# Adicionar ao .env
OPENAI_API_KEY=your_openai_api_key_here    # PRIMÁRIO: Obrigatório
VOYAGE_API_KEY=your_voyage_api_key_here    # SECUNDÁRIO: Recomendado  
# Arctic Embed L é local (sentence-transformers)

# Timeouts
VOYAGE_TIMEOUT=30
OPENAI_TIMEOUT=30
ARCTIC_TIMEOUT=30
```

### **2. Dependências Python**
```bash
pip install openai              # Para OpenAI 3-large (primário)
pip install voyageai            # Para Voyage Law-2 (especializado)
pip install sentence-transformers  # Para Arctic Embed L (fallback)
```

### **3. Verificação do Sistema Atual**
```python
# Verificar status do sistema V1
python -c "
from services.embedding_service import EmbeddingService
service = EmbeddingService()
print(f'V1 Status: {service.get_provider_stats()}')
"
```

---

## 🚀 Processo de Migração

### **Fase 1: Preparação da Infraestrutura**

**1.1. Executar Migrações SQL**
```bash
# Aplicar migração do banco (adiciona colunas V2)
psql -d your_database -f supabase/migrations/20250115000001_add_embeddings_v2_1536d.sql

# Aplicar funções PostgreSQL atualizadas
psql -d your_database -f supabase/migrations/20250115000002_update_find_nearby_lawyers_v2.sql
```

**1.2. Verificar Migrações**
```sql
-- Verificar se colunas foram criadas
\d lawyers;

-- Verificar funções
\df find_nearby_lawyers*;
```

### **Fase 2: Teste do Sistema V2**

**2.1. Teste Básico do Serviço**
```python
# Testar o serviço V2
python -c "
import asyncio
from services.embedding_service_v2 import legal_embedding_service_v2

async def test():
    embedding, provider = await legal_embedding_service_v2.generate_legal_embedding(
        'Advogado especialista em direito empresarial com 10 anos de experiência',
        context_type='lawyer_cv'
    )
    print(f'Embedding V2: {len(embedding)}D via {provider}')
    print(f'Providers disponíveis: {legal_embedding_service_v2.get_provider_stats()}')

asyncio.run(test())
"
```

**2.2. Dry Run da Migração**
```bash
# Simular migração sem alterações
python scripts/migrate_embeddings_v2.py --dry-run --batch-size 10

# Verificar se tudo funcionou
python scripts/migrate_embeddings_v2.py --check-progress
```

### **Fase 3: Migração Gradual**

**3.1. Iniciar Migração em Background**
```bash
# Migração completa com batch pequeno (produção)
nohup python scripts/migrate_embeddings_v2.py \
    --start-migration \
    --batch-size 50 \
    --delay 2.0 \
    > migration_v2.log 2>&1 &

# Ou batch maior (desenvolvimento/teste)  
python scripts/migrate_embeddings_v2.py \
    --start-migration \
    --batch-size 100 \
    --delay 1.0
```

**3.2. Monitoramento do Progresso**
```bash
# Verificar progresso em tempo real
watch -n 30 "python scripts/migrate_embeddings_v2.py --check-progress"

# Ver logs da migração
tail -f migration_v2.log
```

**3.3. Validação de Qualidade**
```bash
# Validar qualidade da migração
python scripts/migrate_embeddings_v2.py --validate

# Exemplo de output esperado:
# 🔍 Validação de Qualidade:
#    Amostra: 50 advogados  
#    Score de qualidade: 98.5%
#    Provedores: {'voyage': 45, 'openai': 5}
```

### **Fase 4: Switch para V2**

**4.1. Verificar Threshold (95% de cobertura)**
```bash
# Status deve mostrar "ready_for_v2_switch": true
python scripts/migrate_embeddings_v2.py --check-progress
```

**4.2. Atualizar match_service.py**
```python
# Em packages/backend/services/match_service.py
# Trocar para usar função V2

# ANTES:
lawyer_rows = supabase.rpc("find_nearby_lawyers", rpc_params).execute().data

# DEPOIS:  
lawyer_rows = supabase.rpc("find_nearby_lawyers_smart", {
    **rpc_params,
    "embedding_v2": case_embedding_v2  # Novo embedding 1024D
}).execute().data
```

---

## 🔄 Sistema de Fallback Dual

### **Durante a Migração**
O sistema automaticamente escolhe a melhor estratégia:

```python
# Função PostgreSQL find_nearby_lawyers_smart()
# 1. Se cobertura V2 >= 70% e embedding V2 disponível → usar V2
# 2. Se embedding V1 disponível → usar V1  
# 3. Fallback geográfico → busca por proximidade apenas
```

### **Monitoramento da Transição**
```sql
-- Query para monitorar cobertura
SELECT 
    COUNT(*) as total,
    COUNT(cv_embedding_v2) as v2_coverage,
    ROUND(COUNT(cv_embedding_v2)::numeric / COUNT(*) * 100, 2) as coverage_pct,
    embedding_migration_status,
    COUNT(*) as status_count
FROM lawyers 
WHERE ativo = true
GROUP BY embedding_migration_status;
```

---

## 🔧 Troubleshooting

### **Problemas Comuns**

**1. Erro de API Key**
```bash
# Verificar configuração
echo $VOYAGE_API_KEY | wc -c  # Deve retornar > 10
echo $OPENAI_API_KEY | wc -c  # Deve retornar > 30
```

**2. Timeout em APIs**
```python
# Ajustar timeouts no .env
VOYAGE_TIMEOUT=60
OPENAI_TIMEOUT=60
```

**3. Batch Stuck**
```bash
# Resetar advogados "migrating" para "pending"  
psql -d your_database -c "
UPDATE lawyers 
SET embedding_migration_status = 'pending' 
WHERE embedding_migration_status = 'migrating';
"
```

**4. Performance Issues**
```bash
# Reduzir batch size e aumentar delay
python scripts/migrate_embeddings_v2.py \
    --start-migration \
    --batch-size 20 \
    --delay 5.0
```

### **Verificação de Saúde**
```bash
# Script de health check
python -c "
import asyncio
from services.embedding_service_v2 import legal_embedding_service_v2

async def health_check():
    stats = legal_embedding_service_v2.get_provider_stats()
    print('🏥 Health Check V2:')
    for provider, info in stats['providers'].items():
        status = '✅' if info['available'] else '❌'
        print(f'  {status} {provider}: {info}')

asyncio.run(health_check())
"
```

---

## 🔙 Rollback (Se Necessário)

### **Rollback Completo**
```bash
# ⚠️ ATENÇÃO: Isso remove todos os embeddings V2!
python scripts/migrate_embeddings_v2.py --rollback --confirm-rollback

# Verificar rollback
python scripts/migrate_embeddings_v2.py --check-progress
```

### **Rollback Parcial (Reverter match_service)**
```python
# Em match_service.py - reverter para função V1
lawyer_rows = supabase.rpc("find_nearby_lawyers", rpc_params).execute().data
```

### **Backup Antes da Migração**
```sql
-- Backup da tabela lawyers (recomendado)
CREATE TABLE lawyers_backup_pre_v2 AS 
SELECT * FROM lawyers WHERE ativo = true;
```

---

## 📊 Métricas de Sucesso

### **KPIs da Migração**
- **Cobertura V2**: Objetivo 95%+
- **Tempo de migração**: ~2-4 horas para 10K advogados
- **Taxa de erro**: <2%
- **Provider distribution**: 80% Voyage, 15% OpenAI, 5% Gemini

### **KPIs de Performance (Pós-migração)**
- **Precision@5**: +35% melhoria esperada
- **Recall@10**: +25% melhoria esperada  
- **User satisfaction**: +40% casos "muito relevantes"
- **API latency**: <200ms p95 (mesmo que V1)

### **Query de Validação Final**
```sql
-- Validação final completa
WITH migration_stats AS (
    SELECT 
        COUNT(*) as total_lawyers,
        COUNT(cv_embedding_v2) as v2_embeddings,
        COUNT(CASE WHEN embedding_migration_status = 'completed' THEN 1 END) as completed,
        COUNT(CASE WHEN embedding_migration_status = 'failed' THEN 1 END) as failed
    FROM lawyers WHERE ativo = true
)
SELECT 
    *,
    ROUND(v2_embeddings::numeric / total_lawyers * 100, 2) as coverage_pct,
    ROUND(completed::numeric / total_lawyers * 100, 2) as success_rate
FROM migration_stats;
```

---

## 🎉 Conclusão

Após concluir esta migração:

✅ **Sistema de embeddings 40% mais preciso para domínio jurídico**  
✅ **Fallback robusto com 3 provedores especializados**  
✅ **Zero downtime durante toda a migração**  
✅ **Capacidade de rollback seguro**  
✅ **Monitoramento completo de progresso e qualidade**

**ROI Esperado:**
- Redução de 50% em casos mal-matchados
- Aumento de 35-40% na satisfação dos usuários
- Melhoria significativa na reputação da plataforma
- Diferencial competitivo com especialização jurídica

Para dúvidas ou suporte, consulte os logs em `migration_v2.log` ou execute os comandos de diagnóstico fornecidos neste guia.
 
 