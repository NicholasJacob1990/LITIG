# 🔍 Edge Cases Tracking - v2.6.2

## 📋 Melhorias Identificadas para Próximo Patch

### 1. **Soft-skills - Contagem de Frequência**

**Situação Atual:**
```python
positive_count = sum(1 for kw in positive_keywords if kw in review_lower)
```
- Conta apenas presença (0 ou 1)
- "Excelente, excelente, excelente" = 1 ponto

**Melhoria Proposta:**
```python
positive_count = sum(review_lower.count(kw) for kw in positive_keywords)
```
- Conta frequência real
- "Excelente, excelente, excelente" = 3 pontos

### 2. **Normalização de Acentos e Variações**

**Situação Atual:**
- "não recomendo" ✅ (detectado)
- "nao recomendo" ❌ (sem acento, não detectado)
- "não recomendaria" ❌ (variação não detectada)

**Melhoria Proposta:**
```python
import unicodedata, re

def _normalize_text(txt: str) -> str:
    """Remove acentos e normaliza texto para matching."""
    return unicodedata.normalize("NFKD", txt).encode("ascii", "ignore").decode()

# Uso no cálculo
review_norm = _normalize_text(review_lower)
positive_count = sum(1 for kw in positive_keywords 
                    if _normalize_text(kw) in review_norm)

# Padrões regex para variações
negative_patterns = [
    r'\bnao\s+recomend',  # Com e sem acento
    r'\bnunca\s+mais',
    r'\bpessim[oa]',      # Com e sem acento  
    r'\bhorr[ii]vel'
]
```

### 3. **Métrica de Recuperação**

**Situação Atual:**
- Counter incrementa quando entra em modo degradado
- Não há métrica quando sai do modo degradado

**Melhoria Proposta:**
```python
# Gauge ao invés de Counter
AVAILABILITY_MODE = prometheus_client.Gauge(
    'litgo_availability_mode',
    'Current availability mode (0=normal, 1=degraded)'
)

# Histogram para duração
DEGRADED_DURATION = prometheus_client.Histogram(
    'litgo_degraded_duration_seconds',
    'Duration of degraded mode episodes'
)
```

### 4. **Isolamento de Presets**

**Situação Atual:**
```python
PRESET_WEIGHTS = {
    "balanced": DEFAULT_WEIGHTS  # Mesma referência!
}
```

**Melhoria Proposta:**
```python
PRESET_WEIGHTS = {
    "balanced": DEFAULT_WEIGHTS.copy()  # Cópia isolada
}
```

### 5. **Circuit Breaker para Respostas Parciais**

**Situação Atual:**
- Em modo normal, IDs não retornados assumem `True`
- Pode alocar advogados sem verificar agenda real

**Melhoria Proposta:**
```python
# Detectar respostas parciais
response_coverage = len(availability_map) / len(lawyer_ids)

if response_coverage < 0.8:  # Menos de 80% dos IDs retornados
    # Ativar circuit breaker
    degraded_mode = True
    CIRCUIT_BREAKER_TRIPS.inc()
```

### 6. **Cache de Soft-skills**

**Situação Atual:**
- Recalcula a cada ranking
- Desperdício se reviews não mudaram

**Melhoria Proposta:**
```python
# Cache com TTL de 1h
SOFT_SKILLS_CACHE = {}

def get_cached_soft_skill(lawyer_id: str, reviews_hash: str) -> Optional[float]:
    key = f"{lawyer_id}:{reviews_hash}"
    if key in SOFT_SKILLS_CACHE:
        score, timestamp = SOFT_SKILLS_CACHE[key]
        if time.time() - timestamp < 3600:  # 1h TTL
            return score
    return None
```

### 7. **TTL de Cache vs Mudança de Endereço**

**Situação Atual:**
- TTL 6h pode causar erro se advogado muda endereço frequentemente
- Especialmente problemático para advogados "express" que atendem múltiplas regiões

**Melhoria Proposta:**
```python
# TTL diferenciado por tipo de feature
CACHE_TTL_GEOGRAPHIC = 3600  # 1h para features geográficas
CACHE_TTL_QUALIFICATION = 21600  # 6h para qualificação

async def invalidate_cache_on_address_change(lawyer_id: str, new_cep: str):
    old_cep = await get_cached_cep(lawyer_id)
    if old_cep != new_cep:
        await cache.delete(f"match:cache:{lawyer_id}")
```

### 8. **Truncamento de Tuplas**

**Situação Atual:**
- `safe_json_dump` trunca apenas `list`
- Tuplas grandes passam sem limite

**Melhoria Proposta:**
```python
elif isinstance(value, (list, tuple)) and len(value) > max_list_size:
    # Trunca listas E tuplas grandes
    out[key] = {
        "_truncated": True,
        "truncated": True,
        "size": len(value),
        "sample": value[:10]
    }
```

### 9. **Limite de Reviews Mobile**

**Situação Atual:**
- Limite de 20 chars pode ser severo para mobile
- "Top!" (4 chars) e "Muito bom 👍" (12 chars) são rejeitados

**Melhoria Proposta:**
```python
# Limite mais flexível + variedade de tokens
MIN_CHARS = 10
MIN_TOKEN_VARIETY = 0.4  # 40% de tokens únicos

def is_valid_review(text: str) -> bool:
    if len(text.strip()) < MIN_CHARS:
        return False
    
    tokens = text.split()
    if len(tokens) < 2:
        return False
        
    unique_ratio = len(set(tokens)) / len(tokens)
    return unique_ratio >= MIN_TOKEN_VARIETY
```

## 🧪 Testes Específicos para Edge Cases

### Test Case 1: Frequência de Keywords
```python
reviews = ["Excelente advogado, excelente mesmo, super excelente!"]
# v2.6.1: score ≈ 0.6
# v2.6.2: score ≈ 0.9 (conta 3x "excelente")
```

### Test Case 2: Variações Negativas
```python
reviews = ["Não recomendaria este profissional"]
# v2.6.1: score = 0.5 (neutro, não detecta)
# v2.6.2: score ≈ 0.2 (detecta padrão regex)
```

### Test Case 3: Circuit Breaker
```python
# Serviço retorna apenas 50% dos IDs
availability_map = {"L1": True}  # Faltam L2, L3
# v2.6.1: L2 e L3 permitidos (fail-open)
# v2.6.2: Modo degradado ativado (circuit breaker)
```

### Test Case 4: Normalização de Acentos
```python
reviews = ["Nao recomendo este profissional"]
# v2.6.1: score = 0.5 (neutro, não detecta sem acento)
# v2.6.2: score ≈ 0.2 (detecta variação normalizada)
```

### Test Case 5: Tuplas Grandes
```python
big_tuple = tuple(range(200))
data = {"embeddings": big_tuple}
result = safe_json_dump(data)
# v2.6.1: passa sem truncar
# v2.6.2: trunca com marcador "_truncated"
```

### Test Case 6: Reviews Mobile
```python
mobile_reviews = ["Top!", "Muito bom 👍", "Recomendo"]
# v2.6.1: todos rejeitados (<20 chars)
# v2.6.2: "Muito bom 👍" e "Recomendo" aceitos (>10 chars, 2+ tokens)
```

## 📊 Métricas de Sucesso

| Métrica | v2.6.1 | v2.6.2 (Meta) |
|---------|--------|---------------|
| Precisão soft-skills | 70% | 85% |
| Falsos positivos disponibilidade | ~5% | <1% |
| Tempo cálculo soft-skills | 5ms/lawyer | 0.5ms (cache) |
| Detecção instabilidade | Não | Sim (circuit breaker) |
| Cobertura normalização acentos | 70% | 95% |
| Reviews mobile aceitos | 20% | 60% |
| Tamanho logs truncamento | 100KB+ | <10KB |

## 🚀 Roadmap

1. **v2.6.2** (Próxima semana)
   - Implementar contagem de frequência
   - Adicionar circuit breaker básico

2. **v2.7.0** (Próximo mês)
   - Integração com TextBlob/spaCy
   - Cache distribuído de soft-skills
   - Dashboard de métricas

## 📝 Notas

- Todos os edge cases são não-bloqueantes
- v2.6.1 está estável para produção
- Melhorias são incrementais e retrocompatíveis 