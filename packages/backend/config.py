"""
Configurações do backend LITGO5
"""
import os
from typing import Optional

from supabase import Client, create_client


class Settings:
    """
    Classe de configurações centralizadas
    """

    # Supabase
    SUPABASE_URL: str = os.getenv("SUPABASE_URL", "")
    SUPABASE_SERVICE_KEY: str = os.getenv("SUPABASE_SERVICE_KEY", "")

    # Database (for direct database connections when needed)
    DATABASE_HOST: str = os.getenv("DATABASE_HOST", "localhost")
    DATABASE_NAME: str = os.getenv("DATABASE_NAME", "litgo5")
    DATABASE_USER: str = os.getenv("DATABASE_USER", "postgres")
    DATABASE_PASSWORD: str = os.getenv("DATABASE_PASSWORD", "")
    DATABASE_PORT: int = int(os.getenv("DATABASE_PORT", "5432"))

    # DocuSign
    USE_DOCUSIGN: bool = os.getenv("USE_DOCUSIGN", "false").lower() == "true"
    DOCUSIGN_BASE_URL: str = os.getenv("DOCUSIGN_BASE_URL", "https://demo.docusign.net")
    DOCUSIGN_API_KEY: str = os.getenv("DOCUSIGN_API_KEY", "")
    DOCUSIGN_ACCOUNT_ID: str = os.getenv("DOCUSIGN_ACCOUNT_ID", "")
    DOCUSIGN_USER_ID: str = os.getenv("DOCUSIGN_USER_ID", "")
    DOCUSIGN_PRIVATE_KEY: str = os.getenv("DOCUSIGN_PRIVATE_KEY", "")

    # OpenAI
    OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY", "")

    # Anthropic
    ANTHROPIC_API_KEY: str = os.getenv("ANTHROPIC_API_KEY", "")

    # Google Gemini
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
    GEMINI_MODEL: str = os.getenv("GEMINI_MODEL", "gemini-pro")
    GEMINI_JUDGE_MODEL: str = os.getenv("GEMINI_JUDGE_MODEL", "gemini-2.0-flash-exp")
    
    # OpenRouter - Unificação de LLMs
    USE_OPENROUTER: bool = os.getenv("USE_OPENROUTER", "false").lower() == "true"
    OPENROUTER_API_KEY: str = os.getenv("OPENROUTER_API_KEY", "")
    OPENROUTER_BASE_URL: str = os.getenv("OPENROUTER_BASE_URL", "https://openrouter.ai/api/v1")
    OPENROUTER_SITE_URL: str = os.getenv("OPENROUTER_SITE_URL", "https://litig-1.com")
    OPENROUTER_APP_NAME: str = os.getenv("OPENROUTER_APP_NAME", "LITIG-1")
    
    # Modelos OpenRouter por serviço
    OPENROUTER_LAWYER_PROFILE_MODEL: str = os.getenv("OPENROUTER_LAWYER_PROFILE_MODEL", "google/gemini-2.5-flash")
    OPENROUTER_CASE_CONTEXT_MODEL: str = os.getenv("OPENROUTER_CASE_CONTEXT_MODEL", "anthropic/claude-sonnet-4-20250514")
    OPENROUTER_LEX9000_MODEL: str = os.getenv("OPENROUTER_LEX9000_MODEL", "x-ai/grok-4")
    OPENROUTER_CLUSTER_LABELING_MODEL: str = os.getenv("OPENROUTER_CLUSTER_LABELING_MODEL", "x-ai/grok-4")
    OPENROUTER_OCR_MODEL: str = os.getenv("OPENROUTER_OCR_MODEL", "openai/gpt-4o-mini")
    OPENROUTER_PARTNERSHIP_MODEL: str = os.getenv("OPENROUTER_PARTNERSHIP_MODEL", "google/gemini-2.5-flash")
    
    # Configurações de resiliência OpenRouter
    OPENROUTER_AUTO_FALLBACK: bool = os.getenv("OPENROUTER_AUTO_FALLBACK", "true").lower() == "true"
    OPENROUTER_TIMEOUT_SECONDS: int = int(os.getenv("OPENROUTER_TIMEOUT_SECONDS", "30"))
    OPENROUTER_MAX_RETRIES: int = int(os.getenv("OPENROUTER_MAX_RETRIES", "2"))
    ENABLE_DIRECT_LLM_FALLBACK: bool = os.getenv("ENABLE_DIRECT_LLM_FALLBACK", "true").lower() == "true"
    
    # LLM Enhanced Matching
    ENABLE_LLM_MATCHING: bool = os.getenv("ENABLE_LLM_MATCHING", "false").lower() == "true"
    MAX_LLM_CANDIDATES: int = int(os.getenv("MAX_LLM_CANDIDATES", "15"))
    TRADITIONAL_WEIGHT: float = float(os.getenv("TRADITIONAL_WEIGHT", "0.6"))
    LLM_WEIGHT: float = float(os.getenv("LLM_WEIGHT", "0.4"))
    LLM_MATCHING_VERSION: str = os.getenv("LLM_MATCHING_VERSION", "v1.0")
    
    # LLM Enhanced Partnerships
    ENABLE_PARTNERSHIP_LLM: bool = os.getenv("ENABLE_PARTNERSHIP_LLM", "false").lower() == "true"

    # Celery
    CELERY_BROKER_URL: str = os.getenv("CELERY_BROKER_URL", "redis://localhost:6379")
    CELERY_RESULT_BACKEND: str = os.getenv(
        "CELERY_RESULT_BACKEND", "redis://localhost:6379")

    # Ambiente
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")
    DEBUG: bool = os.getenv("DEBUG", "false").lower() == "true"

    # URLs
    FRONTEND_URL: str = os.getenv("FRONTEND_URL", "http://localhost:3000")

    # Jusbrasil
    JUSBRASIL_API_URL: str = os.getenv("JUSBRASIL_API_URL", "")
    JUSBRASIL_API_TOKEN: str = os.getenv("JUSBRASIL_API_TOKEN", "")

    @classmethod
    def validate_docusign_config(cls) -> bool:
        """
        Valida se as configurações DocuSign estão completas
        """
        if not cls.USE_DOCUSIGN:
            return True

        required_fields = [
            cls.DOCUSIGN_API_KEY,
            cls.DOCUSIGN_ACCOUNT_ID,
            cls.DOCUSIGN_USER_ID,
            cls.DOCUSIGN_PRIVATE_KEY
        ]

        return all(field.strip() for field in required_fields)

    @classmethod
    def validate_supabase_config(cls) -> bool:
        """
        Valida se as configurações Supabase estão completas
        """
        return bool(cls.SUPABASE_URL and cls.SUPABASE_SERVICE_KEY)

    @classmethod
    def get_docusign_auth_url(cls) -> str:
        """
        Retorna URL de autorização DocuSign
        """
        if cls.ENVIRONMENT == "production":
            return "https://account.docusign.com"
        else:
            return "https://account-d.docusign.com"


# Instância global das configurações
settings = Settings()


def get_settings() -> Settings:
    """
    Função para obter configurações (compatibilidade)
    """
    return settings


# Cliente Supabase singleton
_supabase_client: Optional[Client] = None


def get_supabase_client() -> Client:
    """
    Retorna uma instância do cliente Supabase.
    Usado como dependência do FastAPI.
    """
    global _supabase_client

    if _supabase_client is None:
        if not settings.validate_supabase_config():
            raise ValueError("Configurações do Supabase incompletas")

        _supabase_client = create_client(
            settings.SUPABASE_URL,
            settings.SUPABASE_SERVICE_KEY
        )

    return _supabase_client


def get_database_url() -> str:
    """
    Retorna a URL de conexão com o banco de dados PostgreSQL
    """
    settings = get_settings()
    
    # Construir URL do PostgreSQL
    return f"postgresql://{settings.DATABASE_USER}:{settings.DATABASE_PASSWORD}@{settings.DATABASE_HOST}:{settings.DATABASE_PORT}/{settings.DATABASE_NAME}"

# ===== CONFIGURAÇÕES UNIPILE SDK =====

# Configuração do SDK oficial Python da Unipile
UNIPILE_PREFERRED_SERVICE = os.getenv("UNIPILE_PREFERRED_SERVICE", "sdk_official")  # sdk_official, wrapper_nodejs, auto_fallback
UNIPILE_API_TOKEN = os.getenv("UNIPILE_API_TOKEN", "")
UNIFIED_API_KEY = os.getenv("UNIFIED_API_KEY", "")  # Nome alternativo
UNIPILE_SERVER_REGION = os.getenv("UNIPILE_SERVER_REGION", "north-america")  # north-america, europe, australia
UNIPILE_DSN = os.getenv("UNIPILE_DSN", "api.unipile.com")

# Configurações avançadas do SDK
UNIPILE_ENABLE_FALLBACK = os.getenv("UNIPILE_ENABLE_FALLBACK", "true").lower() == "true"
UNIPILE_HEALTH_CHECK_INTERVAL = int(os.getenv("UNIPILE_HEALTH_CHECK_INTERVAL", "300"))  # 5 minutos
UNIPILE_TIMEOUT_SECONDS = int(os.getenv("UNIPILE_TIMEOUT_SECONDS", "30"))

# Configurações de rate limiting para APIs do Unipile
UNIPILE_RATE_LIMIT_REQUESTS = int(os.getenv("UNIPILE_RATE_LIMIT_REQUESTS", "100"))
UNIPILE_RATE_LIMIT_WINDOW = int(os.getenv("UNIPILE_RATE_LIMIT_WINDOW", "3600"))  # 1 hora

# URLs por região
UNIPILE_REGIONS = {
    "north-america": "https://api.unified.to",
    "europe": "https://api-eu.unified.to", 
    "australia": "https://api-au.unified.to"
}

# Configuração de logging específica do Unipile
UNIPILE_LOG_LEVEL = os.getenv("UNIPILE_LOG_LEVEL", "INFO")
UNIPILE_LOG_REQUESTS = os.getenv("UNIPILE_LOG_REQUESTS", "false").lower() == "true"