# -*- coding: utf-8 -*-
"""
observability/__init__.py

Módulo de observabilidade e métricas para o sistema de matching.
"""

from .metrics import (
    MatchingMetrics,
    get_metrics,
    reset_metrics,
    start_metrics_server,
    instrument_function,
    PROMETHEUS_AVAILABLE,
)

__all__ = [
    "MatchingMetrics",
    "get_metrics",
    "reset_metrics", 
    "start_metrics_server",
    "instrument_function",
    "PROMETHEUS_AVAILABLE",
]
 
 