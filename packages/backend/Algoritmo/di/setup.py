# -*- coding: utf-8 -*-
"""
di/setup.py

Configuração automática do DI container com todos os serviços do sistema.
"""

import logging
from .container import get_container
from ..config import settings
from ..services import create_redis_cache, create_academic_enricher
from ..core import create_ranking_facade, create_feedback_facade, create_matching_orchestrator


def setup_di_container(
    redis_url: str = None,
    db_session=None,
    logger=None,
    **kwargs
) -> None:
    """
    Configura o container de DI com todos os serviços padrão.
    
    Args:
        redis_url: URL do Redis (opcional, usa settings se não fornecido)
        db_session: Sessão do banco de dados (opcional)
        logger: Logger principal (opcional, cria um se não fornecido)
        **kwargs: Configurações adicionais
    """
    container = get_container()
    
    # ===============================
    # Configurações Base
    # ===============================
    
    # Logger padrão
    if logger is None:
        logger = logging.getLogger("matching_system")
        logger.setLevel(logging.INFO)
    
    container.register_singleton("logger", logger)
    container.register_singleton("audit_logger", logger)  # Alias
    
    # Settings
    container.register_singleton("settings", settings)
    
    # DB Session (se fornecida)
    if db_session:
        container.register_singleton("db_session", db_session)
    
    # ===============================
    # Services Layer
    # ===============================
    
    # Redis Cache
    redis_url = redis_url or settings.redis_url
    container.register_factory(
        "redis_cache", 
        lambda: create_redis_cache(redis_url)
    )
    
    # Academic Enricher
    def create_academic_enricher_with_deps():
        cache = container.get_optional("redis_cache")
        logger = container.get_optional("logger")
        return create_academic_enricher(
            cache=cache,
            uni_ttl_h=settings.uni_rank_ttl_h,
            jour_ttl_h=settings.jour_rank_ttl_h,
            audit_logger=logger
        )
    
    container.register_factory("academic_enricher", create_academic_enricher_with_deps)
    
    # ===============================
    # Core Facades
    # ===============================
    
    # Ranking Facade
    def create_ranking_facade_with_deps():
        cache = container.get_optional("redis_cache")
        db_session = container.get_optional("db_session")
        logger = container.get_optional("logger")
        return create_ranking_facade(
            cache=cache,
            db_session=db_session,
            logger=logger
        )
    
    container.register_factory("ranking_facade", create_ranking_facade_with_deps)
    
    # Feedback Facade
    def create_feedback_facade_with_deps():
        cache = container.get_optional("redis_cache")
        db_session = container.get_optional("db_session")
        logger = container.get_optional("logger")
        return create_feedback_facade(
            cache=cache,
            db_session=db_session,
            logger=logger
        )
    
    container.register_factory("feedback_facade", create_feedback_facade_with_deps)
    
    # ===============================
    # Main Orchestrator
    # ===============================
    
    def create_orchestrator_with_deps():
        cache = container.get_optional("redis_cache")
        db_session = container.get_optional("db_session")
        logger = container.get_optional("logger")
        return create_matching_orchestrator(
            cache=cache,
            db_session=db_session,
            logger=logger
        )
    
    container.register_factory("matching_orchestrator", create_orchestrator_with_deps)
    
    # Log de configuração
    logger.info("DI container configured with services", {
        "services": list(container.list_services().keys()),
        "redis_url": redis_url,
        "has_db_session": db_session is not None
    })


def get_service(name: str):
    """
    Helper function para obter um serviço do container.
    
    Args:
        name: Nome do serviço
        
    Returns:
        Instância do serviço
    """
    return get_container().get(name)


def get_service_optional(name: str):
    """
    Helper function para obter um serviço opcional do container.
    
    Args:
        name: Nome do serviço
        
    Returns:
        Instância do serviço ou None
    """
    return get_container().get_optional(name)


# Aliases convenientes para os principais serviços
def get_redis_cache():
    """Obtém o cache Redis."""
    return get_service_optional("redis_cache")


def get_logger():
    """Obtém o logger principal."""
    return get_service_optional("logger")


def get_matching_orchestrator():
    """Obtém o orchestrator principal."""
    return get_service("matching_orchestrator")


def get_ranking_facade():
    """Obtém a facade de ranking."""
    return get_service("ranking_facade")


def get_feedback_facade():
    """Obtém a facade de feedback."""
    return get_service("feedback_facade")
 
 