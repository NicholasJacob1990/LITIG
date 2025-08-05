# -*- coding: utf-8 -*-
"""
di/__init__.py

Módulo de Dependency Injection para o sistema de matching.
"""

from .container import (
    DIContainer,
    get_container,
    reset_container,
    inject
)

from .setup import (
    setup_di_container,
    get_service,
    get_service_optional,
    get_redis_cache,
    get_logger,
    get_matching_orchestrator,
    get_ranking_facade,
    get_feedback_facade
)

__all__ = [
    # Container
    "DIContainer",
    "get_container",
    "reset_container",
    "inject",
    
    # Setup and helpers
    "setup_di_container",
    "get_service",
    "get_service_optional",
    
    # Service shortcuts
    "get_redis_cache",
    "get_logger",
    "get_matching_orchestrator",
    "get_ranking_facade",
    "get_feedback_facade",
]
 
 