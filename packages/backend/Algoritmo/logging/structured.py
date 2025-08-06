# -*- coding: utf-8 -*-
"""
logging/structured.py

Sistema de logging estruturado para o sistema de matching jurídico.
"""

import json
import logging
import sys
from datetime import datetime
from typing import Dict, Any, Optional, Union
from enum import Enum


class LogLevel(Enum):
    """Níveis de log estruturado."""
    DEBUG = "debug"
    INFO = "info"
    WARNING = "warning"
    ERROR = "error"
    CRITICAL = "critical"


class StructuredLogger:
    """
    Logger estruturado com suporte a contexto e métricas.
    
    Produz logs em formato JSON com campos padronizados para facilitar
    análise e monitoramento em produção.
    """
    
    def __init__(self, name: str, level: Union[str, int] = logging.INFO):
        """
        Inicializa o logger estruturado.
        
        Args:
            name: Nome do logger
            level: Nível de log
        """
        self.logger = logging.getLogger(name)
        self.logger.setLevel(level)
        
        # Configurar handler se não existir
        if not self.logger.handlers:
            handler = logging.StreamHandler(sys.stdout)
            formatter = StructuredFormatter()
            handler.setFormatter(formatter)
            self.logger.addHandler(handler)
    
    def debug(self, message: str, context: Optional[Dict[str, Any]] = None, **kwargs):
        """Log de debug."""
        self._log(LogLevel.DEBUG, message, context, **kwargs)
    
    def info(self, message: str, context: Optional[Dict[str, Any]] = None, **kwargs):
        """Log de informação."""
        self._log(LogLevel.INFO, message, context, **kwargs)
    
    def warning(self, message: str, context: Optional[Dict[str, Any]] = None, **kwargs):
        """Log de warning."""
        self._log(LogLevel.WARNING, message, context, **kwargs)
    
    def error(self, message: str, context: Optional[Dict[str, Any]] = None, **kwargs):
        """Log de erro."""
        self._log(LogLevel.ERROR, message, context, **kwargs)
    
    def critical(self, message: str, context: Optional[Dict[str, Any]] = None, **kwargs):
        """Log crítico."""
        self._log(LogLevel.CRITICAL, message, context, **kwargs)
    
    def _log(self, level: LogLevel, message: str, context: Optional[Dict[str, Any]] = None, **kwargs):
        """
        Executa o log estruturado.
        
        Args:
            level: Nível do log
            message: Mensagem principal
            context: Contexto adicional
            **kwargs: Campos adicionais
        """
        # Combinar contexto e kwargs
        extra_data = {}
        if context:
            extra_data.update(context)
        if kwargs:
            extra_data.update(kwargs)
        
        # Mapear níveis
        log_method = {
            LogLevel.DEBUG: self.logger.debug,
            LogLevel.INFO: self.logger.info,
            LogLevel.WARNING: self.logger.warning,
            LogLevel.ERROR: self.logger.error,
            LogLevel.CRITICAL: self.logger.critical,
        }[level]
        
        # Executar log com dados estruturados
        log_method(message, extra={'structured_data': extra_data})


class StructuredFormatter(logging.Formatter):
    """Formatter que produz logs em formato JSON estruturado."""
    
    def format(self, record: logging.LogRecord) -> str:
        """
        Formata o log record em JSON estruturado.
        
        Args:
            record: Record do logging
            
        Returns:
            String JSON formatada
        """
        # Campos base
        log_data = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "level": record.levelname.lower(),
            "logger": record.name,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno,
        }
        
        # Adicionar contexto estruturado se disponível
        if hasattr(record, 'structured_data') and record.structured_data:
            log_data["context"] = record.structured_data
        
        # Adicionar exception info se disponível
        if record.exc_info:
            log_data["exception"] = self.formatException(record.exc_info)
        
        # Serializar para JSON
        try:
            return json.dumps(log_data, ensure_ascii=False, separators=(',', ':'))
        except (TypeError, ValueError) as e:
            # Fallback se não conseguir serializar
            fallback_data = {
                "timestamp": datetime.utcnow().isoformat() + "Z",
                "level": "error",
                "message": f"Failed to serialize log data: {e}",
                "original_message": str(record.getMessage())
            }
            return json.dumps(fallback_data, ensure_ascii=False, separators=(',', ':'))


# Singletons para loggers principais
_main_logger: Optional[StructuredLogger] = None
_audit_logger: Optional[StructuredLogger] = None


def get_main_logger() -> StructuredLogger:
    """Obtém o logger principal do sistema."""
    global _main_logger
    if _main_logger is None:
        _main_logger = StructuredLogger("matching_system", logging.INFO)
    return _main_logger


def get_audit_logger() -> StructuredLogger:
    """Obtém o logger de auditoria."""
    global _audit_logger
    if _audit_logger is None:
        _audit_logger = StructuredLogger("matching_audit", logging.INFO)
    return _audit_logger


def create_logger(name: str, level: Union[str, int] = logging.INFO) -> StructuredLogger:
    """
    Cria um logger estruturado customizado.
    
    Args:
        name: Nome do logger
        level: Nível de log
        
    Returns:
        Logger estruturado
    """
    return StructuredLogger(name, level)


# Helpers para migração de prints
def log_fallback(message: str, level: str = "info", **context):
    """
    Helper para migração gradual de prints para logs.
    
    Args:
        message: Mensagem a ser logada
        level: Nível do log (info, warning, error, etc.)
        **context: Contexto adicional
    """
    logger = get_main_logger()
    
    log_method = {
        "debug": logger.debug,
        "info": logger.info,
        "warning": logger.warning,
        "error": logger.error,
        "critical": logger.critical,
    }.get(level.lower(), logger.info)
    
    log_method(message, context)


# Aliases para compatibilidade
def log_info(message: str, **context):
    """Log de informação."""
    log_fallback(message, "info", **context)


def log_warning(message: str, **context):
    """Log de warning."""
    log_fallback(message, "warning", **context)


def log_error(message: str, **context):
    """Log de erro."""
    log_fallback(message, "error", **context)


def log_debug(message: str, **context):
    """Log de debug."""
    log_fallback(message, "debug", **context)
 
 