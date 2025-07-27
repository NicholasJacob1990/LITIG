# 🚀 GUIA RÁPIDO: CONFIGURAÇÃO DE CHAVES API

**Para iniciar a execução do PLANO_EVOLUCAO_COMPLETO_OPENROUTER_LANGGRAPH.md**

## 🔑 **CHAVES NECESSÁRIAS**

### **1. OpenRouter (PRIMÁRIA) - Unifica todos os modelos**
```bash
# Vá para: https://openrouter.ai/keys
# Crie uma conta (gratuita)
# Gere uma chave API
OPENROUTER_API_KEY=sk-or-v1-xxxxxxxxxxxx
```

### **2. APIs Diretas (FALLBACK) - Para níveis 3-4**
```bash
# Gemini (Google AI Studio): https://makersuite.google.com/app/apikey
GEMINI_API_KEY=AIxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Claude (Anthropic): https://console.anthropic.com/account/keys  
ANTHROPIC_API_KEY=sk-ant-xxxxxxxxxxxxxxxxxxxxxxxxxx

# OpenAI: https://platform.openai.com/api-keys
OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

## ⚙️ **COMO CONFIGURAR**

### **Opção 1: Arquivo .env (Recomendado)**
```bash
# No diretório packages/backend/
echo "OPENROUTER_API_KEY=sua_chave_aqui" >> .env
echo "GEMINI_API_KEY=sua_chave_aqui" >> .env  
echo "ANTHROPIC_API_KEY=sua_chave_aqui" >> .env
echo "OPENAI_API_KEY=sua_chave_aqui" >> .env
```

### **Opção 2: Variáveis de Ambiente**
```bash
export OPENROUTER_API_KEY=sua_chave_aqui
export GEMINI_API_KEY=sua_chave_aqui
export ANTHROPIC_API_KEY=sua_chave_aqui
export OPENAI_API_KEY=sua_chave_aqui
```

## 🧪 **TESTE APÓS CONFIGURAÇÃO**
```bash
cd packages/backend
python3 scripts/check_model_availability.py
```

## 💰 **CUSTOS ESTIMADOS (USD por 1M tokens)**

| Modelo | Input | Output | Uso Recomendado |
|--------|-------|--------|-----------------|
| **Grok 4** | $3.00 | $15.00 | LEX-9000 + Clusters |
| **Gemini 2.5 Pro** | $1.25 | $10.00 | Profiles + Partnerships |
| **Claude Sonnet 4** | $3.00 | $15.00 | Case Context |
| **GPT-4.1-mini** | $0.40 | $1.60 | OCR + Docs |

**💡 Estimativa mensal:** $20-50 USD para desenvolvimento/testes

## 🎯 **PRIORIDADE DE CONFIGURAÇÃO**

### **MÍNIMO VIÁVEL:**
1. ✅ `OPENROUTER_API_KEY` (obrigatória)
2. ✅ `GEMINI_API_KEY` (já configurada)

### **PARA PRODUÇÃO:**
3. 🔧 `ANTHROPIC_API_KEY` (fallback robusto)
4. 🔧 `OPENAI_API_KEY` (fallback final)

## 📞 **SUPORTE**

- **OpenRouter**: https://openrouter.ai/docs
- **Gemini**: https://ai.google.dev/docs
- **Claude**: https://docs.anthropic.com
- **OpenAI**: https://platform.openai.com/docs

---

**✨ Após configurar, execute:**
```bash
python3 scripts/check_model_availability.py
```

**🎯 Meta:** Score de saúde **>90%** para prosseguir com a migração! 
 