# 🔧 Roadmap de Patches Futuros - Algoritmo v2.6+

## 📋 Melhorias Opcionais para v2.6.1+

### 1. **Validação de Pesos**
```python
# Filtrar apenas chaves conhecidas para evitar pesos "fantasma"
loaded = {k: float(v) for k, v in loaded.items() if k in DEFAULT_WEIGHTS}
```

### 2. **Checksum Estável**
```python
# Usar hashlib para checksums consistentes entre runs
import hashlib
checksum = int(hashlib.sha1(value.tobytes()).hexdigest()[:8], 16)
```

### 3. **No-op Counter para Prometheus**
```python
# Alternativa mais elegante quando Prometheus não disponível
from types import SimpleNamespace

class NoOpCounter:
    def inc(self, *args, **kwargs):
        pass

AVAIL_DEGRADED = prometheus_client.Counter(...) if HAS_PROMETHEUS else NoOpCounter()
```

### 4. **Marcação de Objetos Truncados**
```python
# Evitar re-truncamento em recursão
if isinstance(value, dict) and value.get("_truncated"):
    return value  # Já processado
```

### 5. **Cálculo Real de Soft-skills**
```python
def calculate_soft_skills_from_reviews(reviews: List[str]) -> float:
    """
    Analisar sentimento real dos reviews usando:
    - TextBlob/VADER para análise de sentimento
    - Extração de keywords positivas/negativas
    - Normalização 0-1
    """
    pass
```

## 🧪 Testes de Integração Sugeridos

### 1. **Cache Redis Real**
```bash
# Iniciar Redis local
docker run -d -p 6379:6379 redis:alpine

# Testar hit/miss de cache
python3 scripts/test_redis_cache.py
```

### 2. **Prometheus Real**
```bash
# Iniciar Prometheus
docker run -d -p 9090:9090 prom/prometheus

# Verificar métricas
curl localhost:9090/metrics | grep litgo_availability_degraded_total
```

### 3. **Stress Test**
```python
# Testar com 5000+ advogados
# Medir tempo de resposta e uso de memória
# Verificar se slots realmente economizam memória
```

## 📊 Métricas de Sucesso v2.6

- ✅ **Disponibilidade**: 99.9%+ com fail-open
- ✅ **Latência**: < 200ms para 1000 advogados
- ✅ **Observabilidade**: 100% dos eventos críticos logados
- ✅ **Configurabilidade**: 5 parâmetros ajustáveis sem redeploy
- ✅ **Robustez**: Zero crashes em produção

## 🚀 Próximos Passos

1. **Deploy Staging**: Validar comportamento com tráfego real
2. **Monitoramento**: Dashboard Grafana com métricas chave
3. **A/B Testing**: Criar variantes de pesos para otimização
4. **Documentação**: Atualizar README com novos parâmetros ENV

---

**Status v2.6**: PRONTO PARA PRODUÇÃO ✅

Melhorias listadas são incrementais e não bloqueiam release. 