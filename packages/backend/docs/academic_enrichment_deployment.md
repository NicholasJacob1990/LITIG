# Academic Enrichment - Guia de Deployment

## 🎯 **Configurações Disponíveis**

O Academic Enrichment oferece **4 níveis de configuração** com fallback gracioso:

### **Nível 0: Desabilitado (Padrão)**
```bash
# Não instalar dependências
# pip install aiohttp aiolimiter unidecode  # ← NÃO executar

# Ou não configurar APIs
export PERPLEXITY_API_KEY=""
export OPENAI_DEEP_KEY=""
```
**Resultado:**
- ✅ Sistema funciona normalmente
- ✅ Feature Q usa lógica original (experiência + títulos + publicações)
- ✅ Zero latência adicional
- ✅ Zero custos de API

### **Nível 1: Apenas Perplexity (Recomendado MVP)**
```bash
# Instalar dependências
pip install aiohttp aiolimiter unidecode

# Configurar apenas Perplexity
export PERPLEXITY_API_KEY="your_perplexity_key"
export OPENAI_DEEP_KEY=""  # Não necessário
```
**Resultado:**
- ✅ Universidades avaliadas por ranking QS/CAPES
- ✅ Periódicos avaliados por Qualis/SJR
- ✅ Custo baixo (~$50-100/mês)
- ✅ Latência aceitável (+300-800ms primeira vez)
- ⚠️ Sem fallback para periódicos não resolvidos

### **Nível 2: Apenas Deep Research (Nicho)**
```bash
# Instalar dependências
pip install aiohttp aiolimiter unidecode

# Configurar apenas OpenAI
export PERPLEXITY_API_KEY=""  # Não necessário
export OPENAI_DEEP_KEY="your_openai_key"
```
**Resultado:**
- ✅ Precisão máxima para casos especiais
- ⚠️ Muito caro ($20/task)
- ⚠️ Muito lento (5-15 min/item)
- ❌ Não recomendado para uso geral

### **Nível 3: Híbrido (Premium)**
```bash
# Instalar dependências
pip install aiohttp aiolimiter unidecode

# Configurar ambas APIs
export PERPLEXITY_API_KEY="your_perplexity_key"
export OPENAI_DEEP_KEY="your_openai_key"
```
**Resultado:**
- ✅ Cobertura máxima (Perplexity + fallback Deep Research)
- ✅ Otimização de custos (Deep Research só quando necessário)
- ✅ Qualidade premium para casos top-tier
- ⚠️ Custo médio-alto (~$200-500/mês)

## 📊 **Matriz de Decisão**

| Cenário | Config Recomendada | Custo/Mês | Latência | Cobertura |
|---------|-------------------|------------|----------|-----------|
| **MVP/Teste** | Nível 0 | $0 | 0ms | Básica |
| **Produção B2C** | Nível 1 | $50-100 | +500ms | 90% |
| **Casos Especiais** | Nível 2 | $300-2000 | +10min | 100% |
| **Premium B2B** | Nível 3 | $200-500 | +500ms | 100% |

## 🚀 **Estratégia de Rollout**

### **Fase 1: Validation (Semanas 1-2)**
```bash
# Deploy sem APIs para validar estabilidade
export PERPLEXITY_API_KEY=""
export OPENAI_DEEP_KEY=""
```
- Monitorar logs: "Academic enrichment desabilitado"
- Validar que algoritmo funciona normalmente
- Baseline de performance sem enriquecimento

### **Fase 2: MVP (Semanas 3-4)**
```bash
# Ativar apenas Perplexity
export PERPLEXITY_API_KEY="pplx-xxx"
```
- Monitorar custos e latência
- Avaliar melhoria no matching
- Cache hit rate após aquecimento

### **Fase 3: Premium (Mês 2+)**
```bash
# Adicionar Deep Research para casos premium
export OPENAI_DEEP_KEY="sk-xxx"
```
- Configurar flag de feature para casos B2B
- Monitorar uso do fallback
- ROI de casos high-value

## 🔧 **Configuração Avançada**

### **TTL do Cache**
```bash
# Padrão: 30 dias (720 horas)
export UNI_RANK_TTL_H="720"    # Universidades
export JOUR_RANK_TTL_H="720"   # Periódicos

# Deep Research timeouts (conforme spec oficial OpenAI)
export DEEP_POLL_SECS="10"     # intervalo entre polls (padrão 10s)
export DEEP_MAX_MIN="15"       # timeout máximo (padrão 15 min)

# Desenvolvimento: cache curto
export UNI_RANK_TTL_H="1"      # 1 hora para testes
export JOUR_RANK_TTL_H="1"
```

### **Rate Limiting**
```python
# Em academic_prompt_templates.py
API_CONFIGS = {
    "perplexity": {
        "max_batch_size": 15,
        "rate_limit_per_min": 30,  # Ajustar conforme plano
        "timeout_seconds": 30
    }
}
```

### **Feature Flags por Cliente**
```python
# Para rollout gradual
def should_enrich_academic_data(user_id: str, case_type: str) -> bool:
    # Apenas casos B2B premium inicialmente
    if case_type == "CORPORATE" and user_id in PREMIUM_USERS:
        return True
    return False
```

## 📈 **Monitoramento**

### **Métricas Chave**
```python
# KPIs para acompanhar
metrics = {
    "cache_hit_rate": redis_hits / total_requests,
    "api_coverage": resolved_items / total_items,
    "cost_per_case": monthly_cost / cases_processed,
    "latency_p95": percentile(response_times, 95),
    "quality_improvement": new_matching_score / old_matching_score
}
```

### **Alertas**
```bash
# CloudWatch/Grafana alerts
- API error rate > 5%
- Cache hit rate < 70%
- Latency P95 > 2s
- Monthly cost > $500
```

### **Logs Estruturados**
```json
{
  "event": "academic_enrichment_result",
  "universities_resolved": 5,
  "journals_resolved": 3,
  "cache_hits": 2,
  "api_calls": 1,
  "total_latency_ms": 450,
  "cost_estimate": 0.15
}
```

## ✅ **Checklist de Deploy**

### **Pré-Deploy**
- [ ] Dependências instaladas (`aiohttp`, `aiolimiter`, `unidecode`)
- [ ] APIs configuradas conforme nível escolhido
- [ ] Redis funcionando
- [ ] Testes passando
- [ ] Monitoring configurado

### **Deploy**
- [ ] Deploy em staging primeiro
- [ ] Validar logs de fallback
- [ ] Testar casos com/sem cache
- [ ] Verificar métricas de latência
- [ ] Aprovar custos estimados

### **Pós-Deploy**
- [ ] Monitorar primeiras 24h
- [ ] Avaliar cache hit rate após 48h
- [ ] Revisar custos semanais
- [ ] Coletar feedback de qualidade
- [ ] Planejar próximo nível se necessário

---

**💡 Recomendação:** Comece com **Nível 1 (Apenas Perplexity)** para 95% dos casos. É o melhor custo-benefício! 