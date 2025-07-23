# Preset Econômico - Guia Completo

## 🎯 **Visão Geral**

O preset `economic` otimiza o algoritmo de matching para **casos com orçamento limitado**, priorizando proximidade geográfica, urgência e custo-benefício sobre qualificação premium.

## 📊 **Distribuição de Pesos**

```python
"economic": {
    "A": 0.17,  # 17% - Área de atuação (compatibilidade)
    "S": 0.12,  # 12% - Similaridade de casos  
    "T": 0.07,  #  7% - Taxa de sucesso
    "G": 0.17,  # 17% - Geografia (proximidade) ← ALTO
    "Q": 0.04,  #  4% - Qualificação (reduzido) ← BAIXO
    "U": 0.17,  # 17% - Urgência (velocidade) ← ALTO
    "R": 0.05,  #  5% - Reviews
    "C": 0.05,  #  5% - Soft skills
    "P": 0.12,  # 12% - Preço (aderência) ← MÉDIO
    "E": 0.00,  #  0% - Reputação firma (independentes) ← ZERO
    "M": 0.04   #  4% - Maturidade profissional
}
```

## 🧠 **Filosofia do Preset**

### **Prioridades Altas (34%)**
- **Geografia (17%)**: Reduz custos de deslocamento
- **Urgência (17%)**: Velocidade de resposta crítica

### **Prioridades Médias (29%)**
- **Área (17%)**: Compatibilidade fundamental
- **Preço (12%)**: Aderência ao orçamento

### **Prioridades Baixas (37%)**
- **Qualificação (4%)**: Reduzida para controlar custos
- **Reputação Firma (0%)**: Foco em advogados independentes

## 🚀 **Ativação Automática**

O sistema detecta automaticamente casos econômicos:

```python
# Detecção baseada no orçamento máximo
if case.expected_fee_max < 1500:  # R$ 1.500 threshold
    preset = "economic"
```

### **Exemplo de Log**
```json
{
  "event": "Auto-activated economic preset",
  "case_id": "caso123",
  "max_budget": 1200,
  "threshold": 1500
}
```

## 📋 **Casos de Uso Ideais**

### ✅ **Quando Usar Economic**
- Orçamento limitado (< R$ 1.500)
- Casos rotineiros (contratos simples, consultas)
- Clientes pessoa física
- Urgência alta com budget baixo
- Preferência por advogados locais

### ❌ **Quando NÃO Usar**
- Casos complexos (M&A, litígios grandes)
- Orçamento alto disponível
- Necessidade de expertise específica
- Casos corporativos estratégicos

## 🎯 **Ativação Manual**

```python
# Uso explícito do preset
matcher = MatchmakingAlgorithm()
ranking = await matcher.rank(
    case, lawyers,
    top_n=5,
    preset="economic"  # ← Especificar explicitamente
)
```

## 📊 **Impacto no Ranking**

### **Advogado Próximo + Rápido + Barato**
```python
# Exemplo de scores com preset econômico
features = {
    "G": 0.95,  # Muito próximo geograficamente
    "U": 0.90,  # Resposta rápida (8h vs 24h solicitado)  
    "P": 0.85,  # Taxa dentro do orçamento
    "Q": 0.40,  # Qualificação média (5 anos exp)
    "A": 0.80   # Área compatível
}

# Cálculo LTR com preset econômico
score_ltr = (0.95*0.17 + 0.90*0.17 + 0.85*0.12 + 
             0.40*0.04 + 0.80*0.17) = 0.648

# vs preset balanced (Q seria 0.40*0.07 = mais peso)
score_balanced = 0.612

# Advogado próximo+rápido VENCE no preset econômico!
```

### **Advogado Premium + Distante + Caro**
```python
features = {
    "G": 0.30,  # Distante geograficamente
    "U": 0.40,  # Resposta lenta  
    "P": 0.20,  # Taxa acima do orçamento
    "Q": 0.95,  # Qualificação excelente (20 anos exp)
    "A": 0.90   # Área muito compatível
}

# Score econômico penaliza distância e custo
score_economic = 0.402

# Score balanced valorizaria mais a qualificação
score_balanced = 0.478

# Advogado premium PERDE no preset econômico!
```

## 🔍 **Validação e Monitoramento**

### **Logs Estruturados**
```json
{
  "case_id": "caso123",
  "lawyer_id": "adv456",
  "preset": "economic",
  "scores": {
    "ltr": 0.648,
    "features": {"G": 0.95, "U": 0.90, "P": 0.85},
    "delta": {"G": 0.162, "U": 0.153, "P": 0.102}
  },
  "auto_detected": true,
  "budget_threshold": 1500
}
```

### **Métricas de Sucesso**
- **Custo médio por caso**: Deve ser < R$ 1.200
- **Distância média**: Deve ser < 15km  
- **Tempo resposta**: Deve ser < 12h
- **Satisfação cliente**: Manter > 4.0/5.0

## ⚙️ **Configuração Avançada**

### **Ajustar Threshold**
```python
# No código do algoritmo
ECONOMIC_THRESHOLD = float(os.getenv("ECONOMIC_THRESHOLD", "1500"))

if case.expected_fee_max < ECONOMIC_THRESHOLD:
    preset = "economic"
```

### **Personalizar Pesos**
```python
# Criar variação do preset econômico
"economic_rural": {
    "G": 0.25,  # Geografia ainda mais importante (zona rural)
    "U": 0.15,  # Urgência menos crítica
    "P": 0.15,  # Preço mais importante
    # ... outros ajustes
}
```

## 🧪 **Testes de Validação**

### **Teste 1: Detecção Automática**
```python
case_low_budget = Case(
    expected_fee_max=1200  # < 1500
)
ranking = await matcher.rank(case_low_budget, lawyers, preset="balanced")
assert ranking[0].scores["preset"] == "economic"
```

### **Teste 2: Distribuição de Pesos**
```python
weights = load_preset("economic")
assert weights["G"] + weights["U"] > 0.3  # Geografia + Urgência > 30%
assert weights["Q"] < 0.1  # Qualificação < 10%
assert weights["E"] == 0.0  # Firma = 0%
```

### **Teste 3: Ranking Correto**
```python
# Advogado próximo+barato deve vencer premium+caro
local_lawyer = create_lawyer(geo_score=0.9, price_score=0.8, qual_score=0.4)
premium_lawyer = create_lawyer(geo_score=0.3, price_score=0.2, qual_score=0.9)

ranking = await matcher.rank(case, [local_lawyer, premium_lawyer], preset="economic")
assert ranking[0] == local_lawyer
```

## 📈 **Roadmap**

- [ ] **economic_plus**: Meio-termo entre economic e balanced
- [ ] **economic_rural**: Otimizado para regiões remotas  
- [ ] **economic_urgente**: Máxima priorização de urgência
- [ ] **Threshold dinâmico**: Baseado em região/salário mínimo local
- [ ] **ML tuning**: Otimização automática de pesos por feedback

---

**💡 O preset econômico democratiza o acesso à justiça, priorizando proximidade e agilidade sobre prestígio!** ⚖️ 