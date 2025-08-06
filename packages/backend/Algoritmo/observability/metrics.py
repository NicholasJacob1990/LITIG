# -*- coding: utf-8 -*-
"""
observability/metrics.py

Sistema de métricas Prometheus para o sistema de matching jurídico.
"""

import time
from functools import wraps
from typing import Dict, Optional, Callable, Any
from contextlib import contextmanager


# Mock classes para quando prometheus_client não estiver disponível
class MockCounter:
    def __init__(self, *args, **kwargs):
        pass
    
    def inc(self, *args, **kwargs):
        pass
    
    def labels(self, **kwargs):
        return self


class MockHistogram:
    def __init__(self, *args, **kwargs):
        pass
    
    def observe(self, *args, **kwargs):
        pass
    
    def time(self):
        return MockTimeContext()
    
    def labels(self, **kwargs):
        return self


class MockTimeContext:
    def __enter__(self):
        return self
    
    def __exit__(self, *args):
        pass


class MockGauge:
    def __init__(self, *args, **kwargs):
        pass
    
    def set(self, *args, **kwargs):
        pass
    
    def inc(self, *args, **kwargs):
        pass
    
    def dec(self, *args, **kwargs):
        pass
    
    def labels(self, **kwargs):
        return self


# Tentar importar prometheus_client
try:
    from prometheus_client import Counter, Histogram, Gauge, start_http_server
    PROMETHEUS_AVAILABLE = True
except ImportError:
    Counter = MockCounter
    Histogram = MockHistogram
    Gauge = MockGauge
    PROMETHEUS_AVAILABLE = False
    
    def start_http_server(*args, **kwargs):
        pass


class MatchingMetrics:
    """
    Sistema centralizado de métricas para o algoritmo de matching.
    
    Coleta métricas de:
    - Latência de operações
    - Cache hit/miss rates
    - Throughput de requests
    - Erros e falhas
    - Performance de features
    """
    
    def __init__(self):
        """Inicializa todas as métricas."""
        
        # ===============================
        # Request Metrics
        # ===============================
        
        self.requests_total = Counter(
            'matching_requests_total',
            'Total number of matching requests',
            ['operation', 'status', 'preset']
        )
        
        self.request_duration = Histogram(
            'matching_request_duration_seconds',
            'Duration of matching requests',
            ['operation', 'preset'],
            buckets=[0.1, 0.5, 1.0, 2.0, 5.0, 10.0]
        )
        
        # ===============================
        # Cache Metrics
        # ===============================
        
        self.cache_operations = Counter(
            'matching_cache_operations_total',
            'Total cache operations',
            ['cache_type', 'operation', 'status']
        )
        
        self.cache_hit_ratio = Gauge(
            'matching_cache_hit_ratio',
            'Cache hit ratio',
            ['cache_type']
        )
        
        # ===============================
        # Feature Calculation Metrics
        # ===============================
        
        self.feature_calculation_duration = Histogram(
            'matching_feature_calculation_duration_seconds',
            'Duration of feature calculations',
            ['feature_type', 'strategy'],
            buckets=[0.01, 0.05, 0.1, 0.5, 1.0]
        )
        
        self.features_calculated = Counter(
            'matching_features_calculated_total',
            'Total features calculated',
            ['feature_type', 'strategy']
        )
        
        # ===============================
        # Ranking Metrics
        # ===============================
        
        self.lawyers_ranked = Counter(
            'matching_lawyers_ranked_total',
            'Total lawyers ranked',
            ['preset', 'case_type']
        )
        
        self.ranking_duration = Histogram(
            'matching_ranking_duration_seconds',
            'Duration of lawyer ranking',
            ['preset', 'case_type'],
            buckets=[0.1, 0.5, 1.0, 2.0, 5.0]
        )
        
        # ===============================
        # Error Metrics
        # ===============================
        
        self.errors_total = Counter(
            'matching_errors_total',
            'Total errors in matching system',
            ['component', 'error_type']
        )
        
        # ===============================
        # Business Metrics
        # ===============================
        
        self.matches_created = Counter(
            'matching_matches_created_total',
            'Total matches created',
            ['case_area', 'preset']
        )
        
        self.feedback_recorded = Counter(
            'matching_feedback_recorded_total',
            'Total feedback records',
            ['outcome_type', 'satisfaction_level']
        )
        
        # ===============================
        # System Health Metrics
        # ===============================
        
        self.active_requests = Gauge(
            'matching_active_requests',
            'Number of active matching requests'
        )
        
        self.service_availability = Gauge(
            'matching_service_availability',
            'Service availability status',
            ['service_name']
        )
    
    def record_request(self, operation: str, preset: str = "balanced"):
        """Context manager para registrar uma request."""
        return RequestMetricsContext(self, operation, preset)
    
    def record_cache_hit(self, cache_type: str):
        """Registra cache hit."""
        self.cache_operations.labels(
            cache_type=cache_type, 
            operation="get", 
            status="hit"
        ).inc()
    
    def record_cache_miss(self, cache_type: str):
        """Registra cache miss."""
        self.cache_operations.labels(
            cache_type=cache_type, 
            operation="get", 
            status="miss"
        ).inc()
    
    def record_cache_set(self, cache_type: str, success: bool = True):
        """Registra operação de set no cache."""
        status = "success" if success else "error"
        self.cache_operations.labels(
            cache_type=cache_type, 
            operation="set", 
            status=status
        ).inc()
    
    def record_feature_calculation(self, feature_type: str, strategy: str):
        """Context manager para timing de cálculo de features."""
        return FeatureMetricsContext(self, feature_type, strategy)
    
    def record_error(self, component: str, error_type: str):
        """Registra um erro."""
        self.errors_total.labels(
            component=component, 
            error_type=error_type
        ).inc()
    
    def record_match_created(self, case_area: str, preset: str):
        """Registra criação de match."""
        self.matches_created.labels(
            case_area=case_area, 
            preset=preset
        ).inc()
    
    def record_feedback(self, outcome_type: str, satisfaction_level: str):
        """Registra feedback de outcome."""
        self.feedback_recorded.labels(
            outcome_type=outcome_type, 
            satisfaction_level=satisfaction_level
        ).inc()
    
    def set_service_availability(self, service_name: str, available: bool):
        """Define disponibilidade de um serviço."""
        self.service_availability.labels(service_name=service_name).set(1 if available else 0)
    
    def update_cache_hit_ratio(self, cache_type: str, ratio: float):
        """Atualiza ratio de hit do cache."""
        self.cache_hit_ratio.labels(cache_type=cache_type).set(ratio)


class RequestMetricsContext:
    """Context manager para métricas de request."""
    
    def __init__(self, metrics: MatchingMetrics, operation: str, preset: str):
        self.metrics = metrics
        self.operation = operation
        self.preset = preset
        self.start_time = None
        
    def __enter__(self):
        self.start_time = time.time()
        self.metrics.active_requests.inc()
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        duration = time.time() - self.start_time
        status = "error" if exc_type else "success"
        
        # Registrar métricas
        self.metrics.requests_total.labels(
            operation=self.operation,
            status=status,
            preset=self.preset
        ).inc()
        
        self.metrics.request_duration.labels(
            operation=self.operation,
            preset=self.preset
        ).observe(duration)
        
        self.metrics.active_requests.dec()


class FeatureMetricsContext:
    """Context manager para métricas de features."""
    
    def __init__(self, metrics: MatchingMetrics, feature_type: str, strategy: str):
        self.metrics = metrics
        self.feature_type = feature_type
        self.strategy = strategy
        self.start_time = None
    
    def __enter__(self):
        self.start_time = time.time()
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        duration = time.time() - self.start_time
        
        # Registrar métricas
        self.metrics.feature_calculation_duration.labels(
            feature_type=self.feature_type,
            strategy=self.strategy
        ).observe(duration)
        
        if not exc_type:  # Apenas se não houve erro
            self.metrics.features_calculated.labels(
                feature_type=self.feature_type,
                strategy=self.strategy
            ).inc()


# Singleton global de métricas
_metrics_instance: Optional[MatchingMetrics] = None


def get_metrics() -> MatchingMetrics:
    """Obtém a instância global de métricas."""
    global _metrics_instance
    if _metrics_instance is None:
        _metrics_instance = MatchingMetrics()
    return _metrics_instance


def reset_metrics():
    """Reseta as métricas (útil para testes)."""
    global _metrics_instance
    _metrics_instance = None


def start_metrics_server(port: int = 8000):
    """
    Inicia servidor HTTP para expor métricas Prometheus.
    
    Args:
        port: Porta para o servidor (default: 8000)
    """
    if PROMETHEUS_AVAILABLE:
        start_http_server(port)
        return True
    return False


# Decorator para instrumentação automática
def instrument_function(operation: str, component: str = "matching"):
    """
    Decorator para instrumentar funções automaticamente.
    
    Args:
        operation: Nome da operação
        component: Componente do sistema
    """
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        async def async_wrapper(*args, **kwargs):
            metrics = get_metrics()
            
            with metrics.record_request(operation):
                try:
                    return await func(*args, **kwargs)
                except Exception as e:
                    metrics.record_error(component, type(e).__name__)
                    raise
        
        @wraps(func)
        def sync_wrapper(*args, **kwargs):
            metrics = get_metrics()
            
            with metrics.record_request(operation):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    metrics.record_error(component, type(e).__name__)
                    raise
        
        # Detectar se é async function
        import asyncio
        if asyncio.iscoroutinefunction(func):
            return async_wrapper
        else:
            return sync_wrapper
    
    return decorator
 
 