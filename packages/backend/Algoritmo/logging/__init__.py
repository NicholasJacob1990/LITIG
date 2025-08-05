# -*- coding: utf-8 -*-
"""
logging/__init__.py

Módulo de logging estruturado para o sistema de matching.
"""

from .structured import (
    StructuredLogger,
    StructuredFormatter,
    LogLevel,
    get_main_logger,
    get_audit_logger,
    create_logger,
    log_fallback,
    log_info,
    log_warning,
    log_error,
    log_debug,
)

__all__ = [
    "StructuredLogger",
    "StructuredFormatter", 
    "LogLevel",
    "get_main_logger",
    "get_audit_logger",
    "create_logger",
    "log_fallback",
    "log_info",
    "log_warning",
    "log_error",
    "log_debug",
]
 
 