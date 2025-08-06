# 🌥️ Chroma Cloud Configuration - Sistema RAG Jurídico

Agora o sistema RAG jurídico brasileiro suporta **Chroma na nuvem** como alternativa ao armazenamento local!

## 🔄 **Arquitetura Híbrida de Storage**

O sistema agora oferece 3 opções de armazenamento vetorial:

1. **🥇 Supabase (nuvem)** - Preferencial
2. **☁️ Chroma Cloud (nuvem)** - Nova opção na nuvem  
3. **💻 Chroma Local** - Fallback local

## ⚙️ **Configuração Chroma Cloud**

### 1. **Variáveis de Configuração**

Adicione as seguintes variáveis ao seu `config.py`:

```python
class Settings:
    # OpenAI (obrigatório)
    OPENAI_API_KEY = "sk-your-openai-api-key"
    
    # 🌥️ Chroma Cloud
    CHROMA_HOST = "your-chroma-instance.com"
    CHROMA_PORT = 8000
    CHROMA_SSL = True
    CHROMA_HEADERS = {
        "Authorization": "Bearer your-api-token"
    }
```

### 2. **Inicialização**

```python
from brazilian_legal_rag import BrazilianLegalRAG

# Usar Chroma Cloud
rag = BrazilianLegalRAG(
    use_supabase=False,        # Desabilitar Supabase
    use_chroma_cloud=True      # ✅ Habilitar Chroma Cloud
)

# Inicializar base de conhecimento na nuvem
await rag.initialize_knowledge_base()
```

## 🔧 **Ordem de Fallback**

O sistema segue esta ordem de prioridade:

```
1. Supabase (se configurado)
   ↓
2. Chroma Cloud (se configurado e Supabase indisponível)
   ↓ 
3. Chroma Local (fallback final)
```

## 📊 **Verificar Status**

```python
stats = rag.get_stats()
print(f"Storage: {stats['storage_type']}")
# Saída: "Chroma Cloud (nuvem)"
```

## 🚀 **Vantagens do Chroma Cloud**

- ✅ **Escalabilidade**: Não limitado pela capacidade local
- ✅ **Disponibilidade**: Acesso de qualquer lugar
- ✅ **Performance**: Infraestrutura otimizada na nuvem
- ✅ **Backup**: Dados seguros e replicados
- ✅ **Colaboração**: Múltiplas instâncias compartilham mesma base

## 🔍 **Logs de Debug**

```bash
✅ Brazilian Legal RAG inicializado com Chroma Cloud (nuvem)
☁️ Inicializando base de conhecimento Chroma Cloud...
📄 1250 chunks criados para Chroma Cloud
☁️ Base de conhecimento Chroma Cloud inicializada
✅ Base de conhecimento jurídica inicializada com Chroma
```

## 📋 **Dependências**

Para usar Chroma Cloud, instale:

```bash
pip install chromadb langchain-chroma
```

## 🎯 **Exemplo Completo**

Veja `config_chroma_cloud_example.py` para configuração completa de exemplo.

---

**🏛️ Sistema RAG Jurídico Brasileiro agora com suporte total à nuvem!**
