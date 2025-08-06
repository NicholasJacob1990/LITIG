# 🗄️ Configuração do Supabase para RAG Jurídico Brasileiro

## ✅ **Sistema RAG Migrado para Supabase**

O sistema RAG jurídico brasileiro foi **atualizado** para usar **Supabase** como banco de vetores na nuvem, oferecendo:

### 🌟 **Vantagens do Supabase:**
- ✅ **Armazenamento na nuvem** - Dados acessíveis de qualquer lugar
- ✅ **Escalabilidade automática** - Cresce conforme a demanda
- ✅ **Backup automático** - Dados sempre protegidos
- ✅ **Performance otimizada** - Busca vetorial nativa com pgvector
- ✅ **Colaboração** - Equipe acessa a mesma base
- ✅ **Fallback inteligente** - Volta para Chroma local se Supabase indisponível

---

## 🚀 **Configuração Passo a Passo:**

### **1. Configurar Supabase**

#### **a) Criar projeto no Supabase:**
1. Acesse https://supabase.com
2. Crie uma conta/faça login
3. Clique em "New Project"
4. Anote a **URL** e **Service Key** (anon/service_role)

#### **b) Executar SQL de configuração:**
1. No dashboard Supabase, vá em "SQL Editor"
2. Execute o conteúdo do arquivo `supabase_setup.sql`:

```sql
-- Habilitar pgvector
CREATE EXTENSION IF NOT EXISTS vector;

-- Criar tabela para documentos jurídicos  
CREATE TABLE legal_documents (
    id BIGSERIAL PRIMARY KEY,
    content TEXT NOT NULL,
    metadata JSONB,
    embedding VECTOR(1536)
);

-- Criar índice para busca eficiente
CREATE INDEX legal_documents_embedding_idx 
ON legal_documents USING ivfflat (embedding vector_cosine_ops);

-- Função de busca por similaridade
CREATE OR REPLACE FUNCTION match_legal_documents (
    query_embedding VECTOR(1536),
    match_threshold FLOAT DEFAULT 0.78,
    match_count INT DEFAULT 5
)
RETURNS TABLE (
    id BIGINT,
    content TEXT, 
    metadata JSONB,
    similarity FLOAT
)
LANGUAGE SQL STABLE
AS $$
SELECT
    legal_documents.id,
    legal_documents.content,
    legal_documents.metadata,
    1 - (legal_documents.embedding <=> query_embedding) AS similarity
FROM legal_documents
WHERE 1 - (legal_documents.embedding <=> query_embedding) > match_threshold
ORDER BY legal_documents.embedding <=> query_embedding
LIMIT match_count;
$$;
```

### **2. Configurar Variáveis de Ambiente**

Adicione no seu arquivo de configuração ou `.env`:

```bash
# Supabase Configuration
SUPABASE_URL="https://seu-projeto.supabase.co"
SUPABASE_SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# OpenAI (já configurado)
OPENAI_API_KEY="sk-..."
```

### **3. Instalar Dependências**

```bash
pip install supabase langchain-community
```

### **4. Atualizar Configuração**

Adicione ao seu `config.py`:

```python
class Settings:
    # Configurações existentes...
    OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY")
    
    # Novas configurações Supabase
    SUPABASE_URL: str = os.getenv("SUPABASE_URL")
    SUPABASE_SERVICE_KEY: str = os.getenv("SUPABASE_SERVICE_KEY")
```

---

## 🧪 **Teste da Configuração:**

Execute o script de teste:

```bash
cd packages/backend/services
python test_supabase_rag.py
```

**Resultado esperado:**
```
🧪 TESTE DO SISTEMA RAG COM SUPABASE
==================================================

🔧 Verificando configuração...
✅ Todas as variáveis de ambiente configuradas

📦 Testando importações...
✅ supabase
✅ langchain_community
✅ langchain_openai

🚀 Testando inicialização...
✅ RAG inicializado - Storage: Supabase (nuvem)
   📚 Inicializando base de conhecimento...
✅ Base de conhecimento inicializada com sucesso

❓ Testando consultas...
🔍 Consulta 1: Quais são os direitos trabalhistas segundo a CLT?
✅ Consulta processada
   ⏱️ Duração: 1.23s
   📄 Resposta: Segundo a CLT, os principais direitos trabalhistas incluem...
   📚 Fontes: 3 documentos
      - CLT (legislacao)
      - CF88 (constituicao)

🎉 Sistema RAG com Supabase funcionando perfeitamente!
```

---

## 🔄 **Uso da Nova Implementação:**

### **Inicialização Automática:**
```python
from brazilian_legal_rag import BrazilianLegalRAG

# Usa Supabase se configurado, senão fallback para Chroma local
rag = BrazilianLegalRAG(use_supabase=True)

# Inicializar base de conhecimento
await rag.initialize_knowledge_base()

# Fazer consultas
result = await rag.query("O que são horas extras segundo a CLT?")
```

### **Verificar Status:**
```python
stats = rag.get_stats()
print(f"Storage: {stats['storage_type']}")
print(f"Supabase ativo: {stats['supabase_enabled']}")
```

---

## 🛡️ **Fallback Inteligente:**

O sistema tem **fallback automático**:

1. **Primeiro**: Tenta usar Supabase se configurado
2. **Fallback**: Usa Chroma local se Supabase não disponível  
3. **Logs**: Informa qual storage está sendo usado

```python
# Exemplo de logs
INFO:BrazilianLegalRAG:✅ Brazilian Legal RAG inicializado com Supabase (nuvem)
# ou
INFO:BrazilianLegalRAG:⚠️ Supabase não configurado, usando Chroma local
```

---

## 📊 **Comparação: Supabase vs Chroma Local**

| Recurso | **Supabase (Novo)** | Chroma Local |
|---------|-------------------|-------------|
| Armazenamento | ☁️ Nuvem | 💾 Local |
| Escalabilidade | ✅ Automática | ⚠️ Limitada |
| Backup | ✅ Automático | 🔧 Manual |
| Colaboração | ✅ Multi-usuário | ❌ Single-user |
| Performance | ⚡ Otimizada | 🏃 Boa |
| Custos | 💰 Por uso | ✅ Zero |
| Configuração | 🔧 Inicial | ✅ Simples |

---

## 🎯 **Próximos Passos:**

1. ✅ **Execute** o SQL de configuração no Supabase
2. ✅ **Configure** as variáveis de ambiente  
3. ✅ **Teste** com `python test_supabase_rag.py`
4. ✅ **Use** o sistema normalmente - fallback automático garante funcionamento

**Resultado**: Sistema RAG jurídico brasileiro agora na nuvem com Supabase! 🎉
