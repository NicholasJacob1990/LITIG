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
