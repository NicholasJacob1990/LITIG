# LangChain: Otimização Conservadora - Plano Final

## 🎯 **OBJETIVO CLARO**
Usar LangChain como **interface melhorada** para os modelos já configurados, sem adicionar novos provedores.

---

## 📋 **MODELOS EXISTENTES NO APP**

| Função | Modelo Atual | LangChain Interface |
|---------|-------------|-------------------|
| **OCR** | `openai/gpt-4o-mini` | `ChatOpenAI(model="gpt-4o-mini")` |
| **Caso** | `anthropic/claude-sonnet-4` | `ChatAnthropic(model="claude-4.0-sonnet")` |
| **Perfil** | `google/gemini-2.5-flash` | `ChatGoogleGenerativeAI(model="gemini-2.5-flash")` |
| **LEX9000** | `xai/grok-4` | `ChatXAI(model="grok-4")` |
| **Triagem** | `meta-llama/Llama-4-Scout` | `ChatOpenAI(base_url="together", model="llama-4-scout")` |
| **Autorouter** | `openrouter/auto` | `ChatOpenAI(base_url="openrouter", model="auto")` |

---

## 🚀 **IMPLEMENTAÇÃO SIMPLES**

### **1. Interface LangChain Unificada**
```python
class SimpleLangChainOrchestrator:
    def __init__(self):
        # Usar APENAS modelos já configurados
        self.models = {
            "ocr": ChatOpenAI(model="gpt-4o-mini"),
            "case": ChatAnthropic(model="claude-4.0-sonnet-20250401"),
            "profile": ChatGoogleGenerativeAI(model="gemini-2.5-flash"),
            "lex9000": ChatXAI(model="grok-4"),
            "triage": ChatOpenAI(
                base_url="https://api.together.xyz/v1",
                model="meta-llama/Llama-4-Scout"
            )
        }
    
    async def route_by_function(self, function: str, prompt: str):
        """Roteamento simples por função."""
        if function in self.models:
            return await self.models[function].ainvoke(prompt)
        
        # Fallback para sistema existente
        return await self.openrouter_client.chat_completion_with_fallback(
            primary_model="openrouter/auto",
            messages=[{"role": "user", "content": prompt}]
        )
```

### **2. Agente Jurídico com Memória**
```python
from langchain.agents import AgentExecutor, create_openai_functions_agent
from langchain.memory import ConversationBufferMemory

class SimpleLegalAgent:
    def __init__(self):
        # Usar GPT-4o (já configurado) como base
        self.llm = ChatOpenAI(model="gpt-4o")
        
        # Memória persistente
        self.memory = ConversationBufferMemory(return_messages=True)
        
        # Tools jurídicas básicas
        self.tools = [
            Tool(
                name="analyze_case",
                func=lambda q: self.orchestrator.route_by_function("case", q),
                description="Analisa caso jurídico usando Claude"
            ),
            Tool(
                name="extract_document", 
                func=lambda q: self.orchestrator.route_by_function("ocr", q),
                description="Extrai texto de documentos usando GPT-4o-mini"
            )
        ]
        
        # Agente simples
        self.agent = create_openai_functions_agent(
            llm=self.llm,
            tools=self.tools,
            memory=self.memory
        )
```

### **3. RAG Jurídico Básico**
```python
from langchain.vectorstores import Chroma
from langchain.embeddings import OpenAIEmbeddings

class SimpleLegalRAG:
    def __init__(self):
        # Usar OpenAI embeddings (já configurado)
        self.embeddings = OpenAIEmbeddings(model="text-embedding-3-small")
        
        # Vector store simples
        self.legal_db = Chroma(
            collection_name="legal_docs_br",
            embedding_function=self.embeddings
        )
        
        # LLM para respostas (já configurado)
        self.llm = ChatOpenAI(model="gpt-4o")
    
    async def answer_with_context(self, question: str):
        """Resposta com contexto jurídico."""
        # Buscar documentos relevantes
        docs = self.legal_db.similarity_search(question, k=3)
        context = "\n".join([doc.page_content for doc in docs])
        
        # Prompt com contexto
        prompt = f"Contexto jurídico:\n{context}\n\nPergunta: {question}"
        return await self.llm.ainvoke(prompt)
```

---

## 📊 **BENEFÍCIOS PRÁTICOS**

| Aspecto | Antes | Depois |
|---------|-------|--------|
| **Interface** | APIs separadas | LangChain unificado |
| **Memória** | Stateless | Persistente entre sessões |
| **Tools** | Hardcoded | Agentes com function calling |
| **RAG** | Sem contexto | Base jurídica especializada |
| **Modelos** | Fixos | Roteamento inteligente |
| **Complexidade** | Alta | Simplificada |

---

## 🛠️ **PLANO DE IMPLEMENTAÇÃO (5 SEMANAS)**

### **Semana 1-2: Interface LangChain**
- ✅ Implementar `SimpleLangChainOrchestrator`
- ✅ Testar com modelos existentes
- ✅ Validar compatibilidade

### **Semana 3: Agentes com Memória**
- ✅ Implementar `SimpleLegalAgent`
- ✅ Configurar tools jurídicas
- ✅ Testar function calling

### **Semana 4: RAG Jurídico**
- ✅ Implementar `SimpleLegalRAG`
- ✅ Configurar base de documentos
- ✅ Testar respostas com contexto

### **Semana 5: Integração e Testes**
- ✅ Integrar com sistema existente
- ✅ Testes A/B vs. implementação atual
- ✅ Validação de performance

---

## ✅ **CONCLUSÃO**

**Esta é a abordagem mais inteligente:**
- **Zero risco** - usar apenas modelos já testados
- **Funcionalidades avançadas** - agentes, memória, RAG
- **Implementação simples** - sem over-engineering
- **Compatibilidade total** - mantém sistema existente

**Resultado: LangChain otimiza o que já funciona, sem adicionar complexidade desnecessária.** 🎯 