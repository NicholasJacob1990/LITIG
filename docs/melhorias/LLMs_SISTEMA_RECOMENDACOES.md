# LLMs no Sistema de Recomendações LITIG-1

## 📋 Resumo Executivo

O sistema de recomendações LITIG-1 utiliza **múltiplas LLMs** para diferentes funções, com destaque para **GPT-4o (OpenAI)** como principal modelo para rotulagem de clusters e **Gemini** como modelo secundário para embeddings e análise.

## 🤖 LLMs Identificadas no Sistema

### 1. **GPT-4o (OpenAI)** - Principal
**Uso:** Rotulagem automática de clusters
- **Arquivo:** `services/cluster_labeling_service.py`
- **Função:** Gerar rótulos profissionais para clusters de casos e advogados
- **Configuração:** `OPENAI_API_KEY` necessária
- **Modelo específico:** `gpt-4o`
- **Temperatura:** 0.2 (baixa para consistência)

### 2. **Gemini (Google)** - Secundário
**Uso:** Embeddings e análise
- **Modelos configurados:**
  - `gemini-pro` - Modelo padrão
  - `gemini-2.0-flash-exp` - Modelo de juiz para triagem
- **Configuração:** `GEMINI_API_KEY` necessária
- **Função:** Geração de embeddings quando disponível (cascata: Gemini → OpenAI → Local)

### 3. **Claude 3.5 Sonnet** - Triagem
**Uso:** Sistema de triagem inteligente
- **Arquivo:** `triage_service.py`
- **Função:** Extração de informações estruturadas de textos
- **Modelo:** `claude-3-5-sonnet-20240620`

### 4. **Perplexity (Llama 3.1)** - Pesquisa Acadêmica
**Uso:** Enriquecimento de dados acadêmicos
- **Modelo:** `llama-3.1-sonar-large-128k-online`
- **Função:** Busca e análise de informações acadêmicas de advogados
- **Configuração:** `PERPLEXITY_API_KEY` necessária

## 📊 Sistema de Recomendações de Parcerias

### **PartnershipRecommendationService**
- **Sem LLM direta** - usa algoritmo baseado em scores
- **Machine Learning adaptativo** via `PartnershipMLService`
- **Aprendizado por feedback** sem necessidade de LLM

### **Algoritmo de Scoring (sem LLM):**
```python
# Pesos do algoritmo
- Complementarity Score: 50-60%
- Momentum Score: 20%
- Reputation Score: 10%
- Diversity Score: 10%
- Firm Synergy Score: 10%
```

### **Otimização ML (sem LLM):**
- Gradient descent para ajuste de pesos
- Baseado em feedback dos usuários
- Armazenamento em `partnership_weights.json`

## 🔍 Sistema de Recomendações de Advogados

### **Algoritmo Match (algoritmo_match.py)**
- **OpenAI Deep Research API** para enriquecimento
  - Configuração: `OPENAI_DEEP_KEY`
  - Endpoint: `https://api.openai.com/v1/responses`
- **Sem LLM direta** no matching principal
- Sistema híbrido com scoring tradicional

## 🏷️ Rotulagem de Clusters - Detalhe da Implementação

### **ClusterLabelingService** - Uso de GPT-4o:

```python
# Prompts especializados para casos
'system': "Você é um especialista em Direito brasileiro..."
'user': """Analise os seguintes casos jurídicos brasileiros e gere um rótulo preciso...
DIRETRIZES:
- Máximo 4 palavras
- Uso de terminologia jurídica brasileira apropriada
- Foque na área jurídica, não em aspectos processuais
- Seja específico sobre o nicho"""

# Prompts especializados para advogados
'system': "Você é um especialista em análise profissional jurídica..."
'user': """Analise os seguintes perfis de advogados brasileiros...
DIRETRIZES:
- Máximo 4 palavras
- Foque na especialização profissional
- Use terminologia do mercado jurídico
- Identifique o nicho específico"""
```

## ⚙️ Configurações Necessárias

### Variáveis de Ambiente (env.example):
```bash
# OpenAI - Principal para rotulagem
OPENAI_API_KEY=your_openai_api_key

# Google Gemini - Embeddings e análise
GEMINI_API_KEY=your_gemini_api_key
GEMINI_MODEL=gemini-pro
GEMINI_JUDGE_MODEL=gemini-2.0-flash-exp

# Perplexity - Pesquisa acadêmica
PERPLEXITY_API_KEY=your_perplexity_api_key
PERPLEXITY_MODEL=llama-3.1-sonar-large-128k-online

# LLM Enhanced Matching
ENABLE_LLM_MATCHING=true
MAX_LLM_CANDIDATES=15
LLM_WEIGHT=0.4
```

## 📈 Fluxo de Uso das LLMs

1. **Clusterização:**
   - Embeddings: Gemini (preferencial) → OpenAI → Local
   - Rotulagem: GPT-4o exclusivamente

2. **Recomendações de Parceria:**
   - Sem LLM direta
   - ML adaptativo baseado em feedback

3. **Enriquecimento de Dados:**
   - Perplexity para dados acadêmicos
   - OpenAI Deep Research para análise aprofundada

4. **Triagem:**
   - Claude 3.5 Sonnet para extração estruturada

## 🎯 Conclusão

O sistema utiliza uma **abordagem multi-LLM estratégica**:
- **GPT-4o** como workhorse principal para rotulagem semântica
- **Gemini** para embeddings de alta qualidade
- **Claude** para triagem inteligente
- **Perplexity/Llama** para pesquisa acadêmica
- **Sem LLM** nas recomendações de parceria (usa ML tradicional)

Esta arquitetura permite flexibilidade, redundância e otimização de custos, usando cada LLM onde ela é mais eficaz.

---

*Análise realizada em: 2025-07-25*