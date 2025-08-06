# Modelos do App - Ordem de Uso e Cascata

## 🎯 **ARQUITETURA DE 4 NÍVEIS DE FALLBACK**

O app usa uma **arquitetura robusta de 4 níveis** com fallback automático:

---

## 🚀 **NÍVEL 1: MODELO PRIMÁRIO VIA OPENROUTER**

### **Modelos Configurados por Serviço:**

| Serviço | Modelo Primário | Provedor | Função |
|---------|----------------|----------|--------|
| **Lawyer Profile** | `google/gemini-2.5-flash` | Google | Análise de perfil de advogado |
| **Case Context** | `anthropic/claude-sonnet-4-20250514` | Anthropic | Análise de contexto de caso |
| **LEX-9000** | `x-ai/grok-4` | xAI | Análise jurídica complexa |
| **Cluster Labeling** | `x-ai/grok-4` | xAI | Rotulagem de clusters |
| **OCR** | `openai/gpt-4o-mini` | OpenAI | Processamento de documentos |
| **Partnership** | `google/gemini-2.5-flash` | Google | Análise de parcerias |

### **Características:**
- ✅ **Web Search** habilitado (se configurado)
- ✅ **Function calling** estruturado
- ✅ **Timeout configurável** (30s padrão)
- ✅ **Headers extras** para funcionalidades avançadas

---

## 🔄 **NÍVEL 2: AUTOROUTER VIA OPENROUTER**

### **Modelo:** `openrouter/auto`

### **Características:**
- ✅ **Roteamento inteligente** automático
- ✅ **Seleção automática** do melhor modelo
- ✅ **Fallback automático** entre provedores
- ✅ **Otimização** de custo-benefício

### **Estratégias Disponíveis:**
```python
autorouter_strategies = {
    "speed": "openrouter/auto:nitro",      # Máxima velocidade
    "cost": "openrouter/auto:floor",       # Mínimo custo
    "quality": "openrouter/auto",          # Melhor qualidade
    "legal": "openrouter/auto:legal",      # Especializado jurídico
    "regional": "openrouter/auto:br"       # Modelos brasileiros
}
```

---

## 🔧 **NÍVEL 3: CASCATA DIRETA (APIS NATIVAS)**

### **3a. Gemini Direto**
- **Modelo:** `gemini-2.5-flash`
- **Provedor:** Google
- **Timeout:** 30s
- **Função:** Análise geral e processamento

### **3b. Claude Sonnet 4 Direto**
- **Modelo:** `claude-3-5-sonnet-20241022`
- **Provedor:** Anthropic
- **Timeout:** 30s
- **Função:** Análise complexa e conversação

---

## 🛡️ **NÍVEL 4: FALLBACK FINAL**

### **OpenAI/Grok Direto**
- **Modelo:** `gpt-4o`
- **Provedor:** OpenAI
- **Timeout:** 30s
- **Função:** Fallback universal

---

## 🎯 **MODELOS ESPECÍFICOS POR SERVIÇO**

### **1. TriageService - Triagem de Casos**

#### **Estratégia Simples (Baixa Complexidade):**
```python
# Primário: Llama 4 Scout (custo mínimo)
SIMPLE_TRIAGE_MODEL_LLAMA = "meta-llama/Llama-4-Scout"

# Fallback: Claude Haiku
SIMPLE_TRIAGE_MODEL_CLAUDE_FALLBACK = "claude-3-haiku-20240307"
```

#### **Estratégia Padrão (Failover):**
```python
# Primário: Llama 4 Scout
DEFAULT_TRIAGE_MODEL_LLAMA = "meta-llama/Llama-4-Scout"

# Fallback: GPT-4o
DEFAULT_TRIAGE_MODEL_OPENAI_FALLBACK = "gpt-4o"
```

#### **Estratégia Ensemble (Alta Complexidade):**
```python
# Ensemble: Claude Sonnet 4 + GPT-4o
ENSEMBLE_MODEL_ANTHROPIC = "claude-4.0-sonnet-20250401"
ENSEMBLE_MODEL_OPENAI = "gpt-4o"
```

#### **Juiz (Decisão Final):**
```python
# Juiz: Gemini Pro 2.5
JUDGE_MODEL = "gemini-2.0-flash-exp"

# Fallback: GPT-4o
JUDGE_MODEL_OPENAI_FALLBACK = "gpt-4o"
```

### **2. IntelligentInterviewerService - Entrevistadora**

```python
# Primário: Claude Sonnet
INTERVIEWER_MODEL = "claude-3-5-sonnet-20240620"

# Fallback: Llama 4 Scout
INTERVIEWER_MODEL_LLAMA_FALLBACK = "meta-llama/Llama-4-Scout"
```

### **3. LEX9000IntegrationService - Análise Jurídica**

```python
# Primário: Grok 4 via OpenRouter
LEX9000_MODEL = "x-ai/grok-4"

# Fallback: GPT-4o
LEX9000_FALLBACK = "gpt-4o"
```

---

## 📊 **ORDEM DE EXECUÇÃO DETALHADA**

### **Fluxo Completo:**

1. **NÍVEL 1** - Modelo Primário via OpenRouter
   - Tenta o modelo específico configurado para o serviço
   - Se falhar → Nível 2

2. **NÍVEL 2** - Autorouter (`openrouter/auto`)
   - Roteamento inteligente automático
   - Se falhar → Nível 3

3. **NÍVEL 3** - Cascata Direta
   - **3a:** Gemini direto (`gemini-2.5-flash`)
   - Se falhar → **3b:** Claude direto (`claude-3-5-sonnet`)
   - Se falhar → Nível 4

4. **NÍVEL 4** - Fallback Final
   - OpenAI direto (`gpt-4o`)
   - Se falhar → Erro final

### **Exemplo de Execução:**

```python
# 1. Tenta LEX-9000 com Grok 4 via OpenRouter
result = await openrouter_client.chat_completion_with_fallback(
    primary_model="x-ai/grok-4",
    messages=messages
)

# Se falhar, automaticamente tenta:
# 2. openrouter/auto (roteamento inteligente)
# 3a. Gemini direto
# 3b. Claude direto  
# 4. OpenAI direto
```

---

## 🎯 **CONFIGURAÇÕES ESPECÍFICAS**

### **Timeouts:**
- **OpenRouter:** 30s (configurável)
- **Diretos:** 30s fixo
- **Web Search:** +10s adicional

### **Retries:**
- **OpenRouter:** 2 tentativas
- **Diretos:** 1 tentativa
- **Autorouter:** 1 tentativa

### **Web Search:**
- **Habilitado:** Nível 1 apenas
- **Headers:** `X-Enable-Web-Search`
- **Fontes:** Configuráveis

---

## 📈 **MÉTRICAS DE PERFORMANCE**

### **Velocidade Esperada:**
- **Nível 1:** 1-3s (com Web Search)
- **Nível 2:** 1-2s (Autorouter)
- **Nível 3:** 2-4s (APIs diretas)
- **Nível 4:** 2-3s (OpenAI)

### **Custo Estimado:**
- **Grok 4:** $0.10/1M tokens
- **Claude Sonnet:** $3.00/1M tokens
- **GPT-4o:** $2.50/1M tokens
- **Gemini:** $0.50/1M tokens
- **Llama 4:** $0.20/1M tokens

---

## 🚀 **RESUMO EXECUTIVO**

### **Ordem de Prioridade:**

1. **Modelo Específico** via OpenRouter (melhor qualidade)
2. **Autorouter** via OpenRouter (inteligente)
3. **Gemini Direto** (rápido)
4. **Claude Direto** (qualidade)
5. **OpenAI Direto** (universal)

### **Características:**
- ✅ **4 níveis de fallback** automático
- ✅ **Web Search** para informações atualizadas
- ✅ **Function calling** estruturado
- ✅ **Timeout configurável** e robusto
- ✅ **Logs detalhados** para debugging

**O sistema garante máxima resiliência e qualidade, com fallback automático entre 5+ provedores diferentes! 🚀** 