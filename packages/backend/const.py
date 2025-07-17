"""
Constantes centralizadas do algoritmo de matching.
"""

# Versão do algoritmo para versionamento e auditoria
algorithm_version = "v2.8.1-adapter"

# Outras constantes que podem ser centralizadas
DEFAULT_TIMEOUT = 2.0
DEFAULT_CACHE_TTL = 21600  # 6 horas

# Versão da API
api_version = "v3.0-hybrid"

# Configurações de SLA padronizadas
OFFER_SLA_HOURS = 24  # SLA padrão de 24 horas para todas as ofertas

# Configurações de cache
CACHE_TTL_SECONDS = {
    "static_features": 21600,  # 6 horas
    "availability": 300,       # 5 minutos
    "hybrid_data": 7200,       # 2 horas
}

# Configurações de timeout
TIMEOUT_SECONDS = {
    "conflict_scan": 2.0,
    "availability_check": 1.5,
    "api_request": 10.0,
    "hybrid_sync": 30.0,
}

# Configurações de batch processing
BATCH_SIZES = {
    "lawyer_sync": 50,
    "notification_send": 100,
    "embedding_processing": 25,
}

# Configurações de qualidade de dados
DATA_QUALITY_THRESHOLDS = {
    "minimum_confidence": 0.7,
    "freshness_hours": 24,
    "sync_coverage": 0.8,
}

# Configurações de transparência (rebalanceadas com Escavador em primeiro lugar + Unipile)
TRANSPARENCY_SOURCES = {
    "escavador": {
        "weight": 0.30,  # Primeiro lugar
        "ttl_hours": 8,
        "confidence_base": 0.80,
    },
    "unipile": {
        "weight": 0.20,  # Nova fonte - dados de comunicação/email
        "ttl_hours": 4,
        "confidence_base": 0.75,
    },
    "jusbrasil": {
        "weight": 0.25,  # Reduzido de 0.35
        "ttl_hours": 6,
        "confidence_base": 0.85,
    },
    "cnj": {
        "weight": 0.15,  # Reduzido de 0.25
        "ttl_hours": 24,
        "confidence_base": 0.90,
    },
    "oab": {
        "weight": 0.07,  # Reduzido de 0.10
        "ttl_hours": 12,
        "confidence_base": 0.95,
    },
    "internal": {
        "weight": 0.03,  # Reduzido de 0.05
        "ttl_hours": 2,
        "confidence_base": 0.80,
    },
}

# Status de sincronização
SYNC_STATUS = {
    "PENDING": "pending",
    "SUCCESS": "success",
    "ERROR": "error",
    "PARTIAL": "partial",
}

# Tipos de entidade
ENTITY_TYPES = {
    "LAWYER": "lawyer",
    "LAW_FIRM": "law_firm",
    "CASE": "case",
}

# Prioridades de notificação
NOTIFICATION_PRIORITIES = {
    "LOW": "low",
    "INFO": "info",
    "WARNING": "warning",
    "ERROR": "error",
    "CRITICAL": "critical",
}

# Configurações de log
LOG_LEVELS = {
    "DEBUG": "DEBUG",
    "INFO": "INFO",
    "WARNING": "WARNING",
    "ERROR": "ERROR",
    "CRITICAL": "CRITICAL",
}

# Configurações de métricas
METRICS_CONFIG = {
    "enabled": True,
    "prometheus_port": 8000,
    "collect_interval": 60,
} 