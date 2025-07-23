# Academic Enrichment - Estratégia de Deployment

## Fase 1: MVP (Apenas Perplexity)
```bash
export PERPLEXITY_API_KEY="your_key"
# Não configurar OPENAI_DEEP_KEY
```

**Benefícios:**
- Custo controlado (~$50-100/mês)
- Latência baixa (300-800ms)
- Cobertura 90%+ das instituições
- ROI imediato no matching

## Fase 2: Premium (Ambas APIs)
```bash
export PERPLEXITY_API_KEY="your_key"
export OPENAI_DEEP_KEY="your_key"
```

**Quando adicionar:**
- Volume alto de casos premium
- Necessidade de cobertura 100%
- Budget para $500+/mês
- Casos B2B com advogados top-tier

## Monitoramento
```python
# Métricas para decisão
cache_hit_rate = redis_hits / total_requests
perplexity_coverage = resolved_by_perplexity / total_items
deep_research_usage = fallback_calls / total_requests
cost_per_case = monthly_api_cost / cases_ranked
```
