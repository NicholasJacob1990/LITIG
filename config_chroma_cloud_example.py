#!/usr/bin/env python3
"""
Exemplo de Configuração para Chroma Cloud no Sistema RAG Jurídico
================================================================

Configuração para usar Chroma como banco vetorial na nuvem ao invés de local.
"""

# Configurações do Chroma Cloud
class Settings:
    """Configurações de exemplo para Chroma Cloud."""
    
    # OpenAI (obrigatório)
    OPENAI_API_KEY = "sk-your-openai-api-key-here"
    
    # Chroma Cloud - Configure estas variáveis para usar na nuvem
    CHROMA_HOST = "your-chroma-instance.com"  # Host do seu Chroma Cloud
    CHROMA_PORT = 8000  # Porta padrão do Chroma
    CHROMA_SSL = True  # Use SSL/HTTPS
    CHROMA_HEADERS = {
        "Authorization": "Bearer your-chroma-api-token",  # Se necessário
        "X-Chroma-Token": "your-auth-token"  # Token de autenticação se aplicável
    }
    
    # Supabase (opcional - será usado como fallback se Chroma Cloud falhar)
    SUPABASE_URL = "https://your-project.supabase.co"
    SUPABASE_SERVICE_KEY = "your-supabase-service-key"

# Exemplo de uso
if __name__ == "__main__":
    from brazilian_legal_rag import BrazilianLegalRAG
    
    # Inicializar RAG com Chroma Cloud
    rag = BrazilianLegalRAG(
        use_supabase=False,        # Desabilitar Supabase
        use_chroma_cloud=True      # Habilitar Chroma Cloud
    )
    
    print("🌥️ Sistema RAG configurado para usar Chroma Cloud!")
    print(f"📊 Stats: {rag.get_stats()}")
