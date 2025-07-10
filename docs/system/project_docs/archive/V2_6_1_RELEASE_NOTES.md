# 🚀 Release Notes - Algoritmo v2.6.1

## 📋 Melhorias Implementadas

### 1. **Análise Real de Soft-skills** ✨
- **Antes**: Dependia apenas de score externo `kpi_softskill`
- **Agora**: Calcula automaticamente a partir de keywords nos reviews quando score externo = 0
- **Keywords positivas**: atencioso, dedicado, profissional, competente, eficiente, etc.
- **Keywords negativas**: desatento, negligente, despreparado, incompetente, etc.
- **Boost de consistência**: +0.1 se média > 0.7 com 3+ reviews

### 2. **No-op Counter Elegante** 🎯
```python
# Antes
try:
    AVAIL_DEGRADED.inc()
except:
    pass

# Agora
AVAIL_DEGRADED.inc()  # Sempre funciona, sem try/except
```
- Classe `NoOpCounter` quando Prometheus não disponível
- Interface idêntica ao Counter real
- Elimina verificações `if AVAIL_DEGRADED:`

### 3. **Validação de Pesos** 🛡️
```python
# Filtra automaticamente chaves desconhecidas
loaded = {k: float(v) for k, v in loaded.items() if k in DEFAULT_WEIGHTS}
```
- Previne "pesos fantasma" em arquivos JSON
- Aceita apenas as 8 features conhecidas: A, S, T, G, Q, U, R, C
- Aplicado em `load_weights()` e `load_experimental_weights()`

### 4. **Checksum Estável** 🔐
```python
# Antes
"checksum": hash(value.tobytes()) % 1000000  # Varia entre runs

# Agora  
checksum = int(hashlib.sha1(value.tobytes()).hexdigest()[:8], 16)
```
- Usa `hashlib.sha1` para consistência
- Mesmo array → mesmo checksum sempre
- Facilita debug e comparação de logs

### 5. **Prevenção de Re-truncamento** 🔄
```python
# Marca objetos já processados
if isinstance(value, dict) and value.get("_truncated"):
    out[key] = value  # Não reprocessa
    continue
```
- Campo `_truncated` previne processamento duplo
- Melhora performance em estruturas aninhadas
- Mantém integridade dos dados truncados

## 🧪 Como Testar

```bash
# Rodar testes específicos da v2.6.1
python3 scripts/test_v26_1_improvements.py

# Testar com configurações customizadas
MIN_EPSILON=0.015 python3 backend/algoritmo_match.py

# Verificar soft-skills calculados
# Criar advogado com kpi_softskill=0 e reviews positivos
```

## 📊 Impacto

| Métrica | Antes | Depois |
|---------|-------|--------|
| Soft-skills sem score | 0.0 (fixo) | 0.0-1.0 (calculado) |
| Logs com arrays grandes | 100KB+ | <10KB (truncados) |
| Pesos fantasma | Aceitos | Filtrados |
| Checksum variável | Sim | Não |
| Código try/except Prometheus | Necessário | Eliminado |

## 🔧 Configurações

Todas as configurações da v2.6 continuam disponíveis:
- `OVERLOAD_FLOOR`: Piso para advogados lotados (default: 0.01)
- `MIN_EPSILON`: Limite inferior ε-cluster (default: 0.02)
- `AVAIL_TIMEOUT`: Timeout para disponibilidade (default: 1.5s)
- `DIVERSITY_TAU`: Threshold de diversidade (default: 0.30)
- `DIVERSITY_LAMBDA`: Boost de diversidade (default: 0.05)

## 🚀 Próximas Melhorias (v2.6.2+)

1. **Análise de sentimento avançada**: Integração com TextBlob/VADER
2. **Cache de soft-skills**: Evitar recálculo a cada ranking
3. **Métricas de keywords**: Dashboard com palavras mais frequentes
4. **Validação de reviews**: Detecção de spam/fake reviews

## ✅ Status

**v2.6.1 PRONTA PARA PRODUÇÃO**

Todas as melhorias são incrementais e retrocompatíveis. Não há breaking changes. 