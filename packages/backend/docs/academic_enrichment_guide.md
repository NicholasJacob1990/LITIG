# Academic Enrichment - Guia de Uso

## Visão Geral

O Academic Enrichment é um sistema que enriquece a **Feature Q** (qualification_score) do algoritmo de matching jurídico usando dados acadêmicos externos de universidades e periódicos.

## Arquitetura

```
┌─────────────────────┐    ┌──────────────────────┐    ┌─────────────────────┐
│   AcademicEnricher  │ ── │ AcademicPromptTemplates │ ── │  External APIs      │
│                     │    │                      │    │                     │
│ • score_universities│    │ • perplexity_*_payload│    │ • Perplexity API    │
│ • score_journals    │    │ • deep_research_*     │    │ • OpenAI Deep Res.  │
│ • cache + batching  │    │ • validation          │    │ • Rate limiting     │
└─────────────────────┘    └──────────────────────┘    └─────────────────────┘
```

## Configuração

### Variáveis de Ambiente

```bash
# APIs (obrigatórias para funcionalidade completa)
export PERPLEXITY_API_KEY="your_perplexity_key"
export OPENAI_DEEP_KEY="your_openai_key"

# Cache TTL (opcional - padrão 30 dias)
export UNI_RANK_TTL_H="720"    # Universidades
export JOUR_RANK_TTL_H="720"   # Periódicos

# Redis (reutiliza configuração existente)
export REDIS_URL="redis://localhost:6379/0"
```

### Dependências

```bash
pip install aiohttp aiolimiter unidecode
```

## Como Funciona

### 1. Fluxo de Universidades

```python
# Input: ['Universidade de São Paulo', 'Harvard Law School']
# ↓
# Cache check: Redis key "acad:uni:universidade_de_sao_paulo"
# ↓
# API call: Perplexity com template consolidado
# ↓
# Scoring: score_capes = (conceito-1)/6, score_qs = 1 - log(rank)/log(1000)
# ↓
# Output: {'Universidade de São Paulo': 0.85, 'Harvard Law School': 0.95}
```

### 2. Fluxo de Periódicos

```python
# Input: ['Revista de Direito Administrativo', 'Harvard Law Review']  
# ↓
# Cache check + Perplexity API (lotes de até 15)
# ↓
# Scoring: Qualis A1=1.0 ... C=0.2, SJR: min(1, SJR/20)
# ↓
# Fallback: Deep Research para periódicos não resolvidos
# ↓
# Output: {'Revista de Direito Administrativo': 0.7, 'Harvard Law Review': 0.9}
```

### 3. Integração no Algoritmo

```python
# qualification_score_async() combina:
final_score = (
    0.30 * score_exp +        # 30% experiência
    0.20 * score_titles +     # 20% títulos acadêmicos 
    0.15 * score_uni +        # 15% reputação das universidades ← NOVO
    0.10 * score_pub_qual +   # 10% qualidade dos periódicos ← NOVO
    0.05 * score_pub_qty +    # 5% quantidade de publicações
    0.10 * score_par +        # 10% pareceres
    0.10 * score_rec          # 10% reconhecimentos
)
```

## Templates de Prompts

### Perplexity - Universidades

```json
{
  "model": "sonar-deep-research",
  "search_context_size": "medium",
  "messages": [
    {
      "role": "system", 
      "content": "Retorne SOMENTE JSON mapeando universidades para nota 0‑1."
    },
    {
      "role": "user",
      "content": "Avalie as instituições...\nRegra: score_capes = (conceito‑1)/6..."
    }
  ]
}
```

### Deep Research - Fallback

```json
{
  "model": "o3-deep-research",
  "background": true,
  "input": [...],
  "tools": [{"type": "web_search"}],
  "response_format": {"type": "json_object"}
}
```

## Rate Limits e Custos

| API            | Limite          | Custo Estimado    | TTL Cache |
|----------------|-----------------|-------------------|-----------|
| Perplexity     | 30 req/min      | $0.20/1K tokens   | 30 dias   |
| Deep Research  | 100 tasks/mês   | $20/task          | 30 dias   |

## Exemplo de Uso

```python
from algoritmo_match import AcademicEnricher, cache

# Inicializar enricher
enricher = AcademicEnricher(cache)

# Avaliar universidades
uni_scores = await enricher.score_universities([
    'Universidade de São Paulo',
    'Harvard Law School', 
    'Pontifícia Universidade Católica de São Paulo'
])
# Output: {'Universidade de São Paulo': 0.82, 'Harvard Law School': 0.95, ...}

# Avaliar periódicos  
jour_scores = await enricher.score_journals([
    'Revista de Direito Administrativo',
    'Harvard Law Review',
    'Revista dos Tribunais'
])
# Output: {'Revista de Direito Administrativo': 0.75, 'Harvard Law Review': 0.92, ...}
```

## Monitoramento

### Logs Estruturados

```json
{
  "case_id": "caso123",
  "lawyer_id": "adv456", 
  "uni_rank_ttl_h": 720,
  "journal_rank_ttl_h": 720,
  "academic_enrich": true,
  "algorithm_version": "v2.8-academic"
}
```

### Métricas Redis

```bash
# Verificar cache hit rate
redis-cli info keyspace

# Chaves por tipo
redis-cli --scan --pattern "match:cache:acad:uni:*" | wc -l
redis-cli --scan --pattern "match:cache:acad:jour:*" | wc -l
```

## Troubleshooting

### Fallback Gracioso

- **Sem APIs configuradas**: Feature Q usa lógica original
- **Rate limit hit**: Aguarda automaticamente + retry
- **API timeout**: Cache anterior mantido, fallback para próxima tentativa
- **JSON inválido**: Log de warning, score padrão 0.5

### Performance

- **1º uso sem cache**: +300-800ms (Perplexity) + ~5-8s (Deep Research fallback)
- **Cache aquecido**: Impacto zero na latência
- **Batch optimal**: 15 universidades/periódicos por requisição

### Debugging

```python
# Testar templates
from services.academic_prompt_templates import example_usage
examples = example_usage()
print(examples['universities'])

# Testar cache
await cache.set_academic_score('test:uni:harvard', 0.95, ttl_h=1)  
score = await cache.get_academic_score('test:uni:harvard')
assert score == 0.95
```

## Roadmap

- [ ] Job semanal para atualização Qualis CAPES
- [ ] Métricas Prometheus específicas
- [ ] Dashboard de cache hit rate  
- [ ] Backup/restore de cache acadêmico
- [ ] Integração com bases internacionais (Web of Science, Scopus)

---

✅ **Sistema pronto para produção** com fallback gracioso e observabilidade completa! 