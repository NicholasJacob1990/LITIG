# Algoritmo do Sistema de Recomendações LITIG-1

## 📊 Visão Geral

O sistema possui **dois algoritmos principais** de recomendação:

1. **Recomendações de Parcerias** - Baseado em complementaridade de clusters
2. **Recomendações de Advogados** - Matching para casos específicos

## 🤝 1. Algoritmo de Recomendações de Parcerias

### **Objetivo**
Identificar advogados com expertise complementar para formar parcerias estratégicas.

### **Fluxo do Algoritmo**

```python
1. Identificar clusters do advogado-alvo
   ↓
2. Buscar advogados com clusters complementares (não sobrepostos)
   ↓
3. Calcular scores multidimensionais
   ↓
4. Aplicar ML adaptativo (pesos otimizados)
   ↓
5. Ordenar e diversificar resultados
```

### **Componentes do Score Final**

```python
final_score = (
    complementarity * weights.complementarity_weight +    # 50-60%
    momentum * weights.momentum_weight +                   # 20%
    reputation * weights.reputation_weight +               # 10%
    diversity * weights.diversity_weight +                 # 10%
    firm_synergy * weights.firm_synergy_weight            # 10%
)
```

### **Detalhamento dos Componentes**

#### 1. **Complementarity Score (50-60%)**
```python
# Média ponderada por confiança e tamanho do cluster
total_weight = sum(c["confidence"] * min(c["cluster_size"] / 10.0, 1.0) for c in complement_clusters)
total_confidence = sum(c["confidence"] for c in complement_clusters)
complementarity = total_weight / len(complement_clusters)
```

#### 2. **Momentum Score (20%)**
```python
# Média ponderada do momentum dos clusters complementares
weighted_momentum = sum(c["momentum"] * c["confidence"] for c in complement_clusters)
momentum = weighted_momentum / total_confidence
```

#### 3. **Reputation Score (10%)**
```python
# Rating normalizado ou fallback neutro
if info["avg_rating"] and info["avg_rating"] > 0:
    reputation = min(1.0, info["avg_rating"] / 5.0)
else:
    reputation = 0.5  # Fallback neutro
```

#### 4. **Diversity Score (10%)**
```python
# Fórmula logarítmica para valorizar variedade
diversity = min(1.0, math.log(1 + len(complement_clusters)) / math.log(6))
```

#### 5. **Firm Synergy Score (10%)**
Análise complexa de sinergia entre escritórios:

```python
firm_synergy_score = (
    portfolio_gap_score * 0.5 +        # Gaps no portfólio
    strategic_score * 0.3 +            # Complementaridade estratégica
    market_positioning_score * 0.2     # Posicionamento de mercado
)
```

### **Otimizações e Filtros**

1. **Filtros de Qualidade:**
   - Clusters com menos de 3 membros são excluídos
   - Confidence score mínimo configurável (padrão: 0.6)
   - Opcional: excluir advogados do mesmo escritório

2. **Penalidades:**
   - Apenas 1 cluster complementar: -20% no score final
   - Clusters de baixa confiança recebem peso menor

3. **Diversificação:**
   - Máximo 2 advogados do mesmo escritório nas top 10 recomendações
   - Após top 10: máximo 1 por escritório

### **Machine Learning Adaptativo**

O sistema aprende com feedback dos usuários:

```python
# Gradient Descent para otimização de pesos
for epoch in range(100):
    for sample in training_data:
        predicted_score = calculate_predicted_score(sample, weights)
        loss = (predicted_score - actual_score) ** 2
        gradients = calculate_gradients(sample, predicted_score, actual_score)
        # Atualizar pesos baseado nos gradientes
```

**Métricas de Feedback:**
- `accepted`: Parceria aceita
- `contacted`: Advogado contatado
- `rejected`: Rejeitado
- `dismissed`: Descartado

## 👨‍⚖️ 2. Algoritmo de Recomendações de Advogados (Match)

### **Objetivo**
Encontrar os melhores advogados para um caso específico.

### **Fluxo do Algoritmo**

```python
1. Análise do caso (NLP + embeddings)
   ↓
2. Busca vetorial + filtros contextuais
   ↓
3. Enriquecimento multi-fonte
   ↓
4. Scoring multidimensional
   ↓
5. Ranking final com explicações
```

### **Sistema de Scoring**

```python
# Score base (expertise + experiência)
base_score = calculate_base_score(lawyer_data)

# Ajustes contextuais
location_multiplier = calculate_location_score(case_location, lawyer_location)
experience_multiplier = calculate_experience_score(years_of_experience)
success_rate_bonus = calculate_success_bonus(lawyer_stats)

# Score final
final_score = base_score * location_multiplier * experience_multiplier + success_rate_bonus
```

### **Fontes de Dados Integradas**

1. **Dados Internos:**
   - Perfil do advogado
   - Histórico de casos
   - Avaliações de clientes

2. **Escavador API:**
   - Processos históricos
   - Outcomes classificados por NLP
   - Distribuição por tribunais

3. **LinkedIn/Unipile:**
   - Experiência profissional
   - Skills e endorsements
   - Conexões e networking

4. **Perplexity Academic:**
   - Formação acadêmica
   - Publicações científicas
   - Scores de reputação

5. **Deep Research:**
   - Análise contextual avançada
   - Insights de mercado

### **Enriquecimento Social Boost**

```python
# Boost baseado em dados do LinkedIn
if linkedin_data:
    connections_boost = min(1.2, 1 + (connections / 1000) * 0.2)
    endorsements_boost = min(1.1, 1 + (total_endorsements / 100) * 0.1)
    social_boost = (connections_boost + endorsements_boost) / 2
    
    success_rate = base_success_rate * social_boost
```

## 🔄 Fluxo de Consolidação de Dados

```python
async def consolidate_lawyer_data(lawyer_id):
    # 1. Dados internos (sempre disponível)
    internal_data = await get_internal_data(lawyer_id)
    
    # 2. Enriquecimento paralelo
    tasks = [
        fetch_linkedin_data(lawyer_id),
        fetch_escavador_data(oab_number),
        fetch_academic_data(lawyer_name),
        fetch_deep_research(lawyer_context)
    ]
    
    # 3. Aguardar com timeout
    enriched_data = await asyncio.gather(*tasks, return_exceptions=True)
    
    # 4. Consolidar com qualidade score
    consolidated = merge_data_sources(internal_data, enriched_data)
    quality_score = calculate_data_quality(consolidated)
    
    return consolidated, quality_score
```

## 📈 Métricas de Performance

### **Para Parcerias:**
- Taxa de aceitação de recomendações
- Taxa de contato iniciado
- Feedback score médio
- R² score do modelo ML

### **Para Advogados:**
- Taxa de conversão (visualização → contato)
- Satisfação do cliente com match
- Tempo médio para fechar negócio
- Precisão das predições de success rate

## 🎯 Diferenciais do Algoritmo

1. **Multi-fonte com Fallback:**
   - Nunca falha mesmo se APIs externas estiverem down
   - Qualidade degradada graciosamente

2. **Transparência de Dados:**
   - Usuário vê quais fontes foram usadas
   - Confidence score por fonte

3. **ML Adaptativo:**
   - Aprende com comportamento dos usuários
   - Ajusta pesos automaticamente

4. **Contexto Jurídico Brasileiro:**
   - Considera especificidades regionais
   - Valoriza experiência em tribunais específicos

5. **Cache Inteligente:**
   - TTL diferenciado por fonte
   - Atualização incremental

---

*Documentação técnica completa do algoritmo de recomendações LITIG-1*