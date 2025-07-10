"""
Testes para o módulo metrics
"""
import pytest
from unittest.mock import patch, MagicMock
from contextlib import contextmanager
from backend.metrics import (
    triage_requests_total,
    matches_found_total,
    offers_created_total,
    contracts_signed_total,
    notifications_sent_total,
    job_executions_total,
    api_requests_total,
    fallback_usage_total,
    cache_hits_total,
    cache_misses_total,
    ab_test_exposure_total,
    ab_test_conversions_total,
    model_retrain_total,
    model_alert_total,
    triage_duration,
    matching_duration,
    notification_duration,
    external_api_duration,
    database_query_duration,
    active_offers,
    pending_contracts,
    system_health,
    lawyers_available,
    queue_size,
    cache_hit_rate,
    equity_distribution,
    average_lawyer_load,
    ab_test_performance_gauge,
    model_performance_gauge,
    model_drift_gauge,
    system_info,
    update_system_health,
    calculate_gini_coefficient
)


def test_counter_metrics():
    """Testa métricas de contador"""
    # Incrementar contador com labels corretos
    triage_requests_total.labels(status="success", strategy="openai").inc()
    initial_value = triage_requests_total.labels(status="success", strategy="openai")._value.get()
    
    triage_requests_total.labels(status="success", strategy="openai").inc()
    assert triage_requests_total.labels(status="success", strategy="openai")._value.get() == initial_value + 1
    
    # Testar outros contadores
    matches_found_total.labels(preset="balanced", case_complexity="medium").inc()
    offers_created_total.labels(case_area="Trabalhista").inc()
    contracts_signed_total.labels(fee_type="success", case_area="Civil").inc()
    cache_hits_total.inc()
    cache_misses_total.inc()


def test_labeled_counter_metrics():
    """Testa métricas de contador com labels"""
    # Testar notification com diferentes tipos - labels corretos: type, status
    notifications_sent_total.labels(type="email", status="success").inc()
    notifications_sent_total.labels(type="push", status="success").inc()
    notifications_sent_total.labels(type="push", status="failed").inc()
    
    # Testar job execution com diferentes jobs - labels corretos: job_name, status
    job_executions_total.labels(job_name="daily_report", status="success").inc()
    job_executions_total.labels(job_name="weekly_summary", status="success").inc()
    job_executions_total.labels(job_name="equity_calculation", status="failed").inc()
    
    # Testar API requests com diferentes métodos e endpoints - labels corretos: method, endpoint, status_code
    api_requests_total.labels(method="GET", endpoint="/api/cases", status_code="200").inc()
    api_requests_total.labels(method="POST", endpoint="/api/triage", status_code="201").inc()
    api_requests_total.labels(method="PUT", endpoint="/api/offers/123", status_code="200").inc()
    
    # Testar fallback usage - labels corretos: service, reason
    fallback_usage_total.labels(service="openai", reason="timeout").inc()
    fallback_usage_total.labels(service="docusign", reason="error").inc()


def test_ab_test_metrics():
    """Testa métricas de teste A/B"""
    # Exposição em teste A/B - labels corretos: test_id, group
    ab_test_exposure_total.labels(test_id="matching_v2", group="control").inc()
    ab_test_exposure_total.labels(test_id="matching_v2", group="treatment").inc()
    
    # Conversões em teste A/B - labels corretos: test_id, group
    ab_test_conversions_total.labels(test_id="matching_v2", group="control").inc()
    ab_test_conversions_total.labels(test_id="matching_v2", group="treatment").inc()


def test_model_metrics():
    """Testa métricas de modelo"""
    # Retreino de modelo - labels corretos: trigger
    model_retrain_total.labels(trigger="scheduled").inc()
    model_retrain_total.labels(trigger="manual").inc()
    
    # Alertas de modelo - labels corretos: model_type, alert_type, level
    model_alert_total.labels(model_type="ltr", alert_type="drift", level="high").inc()
    model_alert_total.labels(model_type="sentiment", alert_type="performance", level="medium").inc()


def test_histogram_metrics():
    """Testa métricas de histograma"""
    # Duração de triagem - labels corretos: strategy
    triage_duration.labels(strategy="openai").observe(1.5)
    triage_duration.labels(strategy="anthropic").observe(2.3)
    triage_duration.labels(strategy="openai").observe(0.8)
    
    # Duração de matching - labels corretos: preset, num_candidates
    matching_duration.labels(preset="balanced", num_candidates="10-50").observe(0.5)
    matching_duration.labels(preset="fast", num_candidates="1-10").observe(0.7)
    
    # Duração de notificação - labels corretos: type
    notification_duration.labels(type="email").observe(0.3)
    notification_duration.labels(type="push").observe(0.1)
    
    # Duração de API externa - labels corretos: service, operation
    external_api_duration.labels(service="openai", operation="embedding").observe(1.2)
    external_api_duration.labels(service="docusign", operation="sign").observe(2.5)
    
    # Duração de query de banco - labels corretos: operation, table
    database_query_duration.labels(operation="select", table="cases").observe(0.05)
    database_query_duration.labels(operation="insert", table="offers").observe(0.08)
    database_query_duration.labels(operation="update", table="lawyers").observe(0.06)


def test_gauge_metrics():
    """Testa métricas de gauge"""
    # Definir valores de gauge - sem labels
    active_offers.set(42)
    assert active_offers._value.get() == 42
    
    pending_contracts.set(15)
    assert pending_contracts._value.get() == 15
    
    system_health.set(85.5)
    assert system_health._value.get() == 85.5
    
    # Gauges com labels corretos
    lawyers_available.labels(area="Trabalhista").set(120)
    queue_size.labels(queue_name="triage").set(25)
    queue_size.labels(queue_name="matching").set(10)
    
    cache_hit_rate.labels(cache_type="redis").set(0.92)
    assert cache_hit_rate.labels(cache_type="redis")._value.get() == 0.92
    
    # Gauges sem labels
    equity_distribution.set(0.35)
    assert equity_distribution._value.get() == 0.35
    
    average_lawyer_load.labels(area="Civil").set(0.75)
    assert average_lawyer_load.labels(area="Civil")._value.get() == 0.75


def test_labeled_gauge_metrics():
    """Testa métricas de gauge com labels"""
    # Performance de teste A/B - labels corretos: test_id, group
    ab_test_performance_gauge.labels(test_id="matching_v2", group="control").set(0.65)
    ab_test_performance_gauge.labels(test_id="matching_v2", group="treatment").set(0.72)
    
    # Performance de modelo - labels corretos: model_type, metric
    model_performance_gauge.labels(model_type="ltr", metric="accuracy").set(0.89)
    model_performance_gauge.labels(model_type="ltr", metric="precision").set(0.91)
    model_performance_gauge.labels(model_type="ltr", metric="recall").set(0.87)
    
    # Drift de modelo - labels corretos: model_type, feature
    model_drift_gauge.labels(model_type="ltr", feature="area_feature").set(0.05)
    model_drift_gauge.labels(model_type="ltr", feature="geo_feature").set(0.12)


def test_system_info_metric():
    """Testa métrica de informação do sistema"""
    # Atualizar informações do sistema
    system_info.info({
        "version": "2.3.0",
        "environment": "staging",
        "ltr_enabled": "true",
        "algorithm_version": "v2.3"
    })


@contextmanager
def track_time(histogram):
    """Context manager para medir tempo de execução."""
    import time
    start_time = time.time()
    try:
        yield
    finally:
        duration = time.time() - start_time
        histogram.observe(duration)


def test_helper_functions():
    """Testa funções auxiliares"""
    # Testar track_time com context manager
    with track_time(triage_duration.labels(strategy="openai")):
        import time
        time.sleep(0.01)
    
    # Testar calculate_gini_coefficient
    values = [100, 100, 100, 100]  # Distribuição perfeita
    gini = calculate_gini_coefficient(values)
    assert gini == 0.0
    
    values = [1, 0, 0, 0]  # Distribuição totalmente desigual
    gini = calculate_gini_coefficient(values)
    assert gini == 0.75  # Valor correto para esta distribuição
    
    values = [100, 150, 200, 250]  # Distribuição parcial
    gini = calculate_gini_coefficient(values)
    assert 0 < gini < 1


def test_metric_edge_cases():
    """Testa casos extremos das métricas"""
    # Valores negativos (devem ser aceitos para alguns casos)
    system_health.set(-10)  # Sistema com problemas
    
    # Valores zero
    active_offers.set(0)
    pending_contracts.set(0)
    cache_hit_rate.labels(cache_type="redis").set(0.0)
    
    # Valores máximos
    system_health.set(100)
    cache_hit_rate.labels(cache_type="redis").set(1.0)
    average_lawyer_load.labels(area="Civil").set(1.0)
    
    # Strings vazias em labels
    notifications_sent_total.labels(type="", status="success").inc()
    job_executions_total.labels(job_name="", status="success").inc()
    
    # Múltiplas atualizações rápidas
    for i in range(100):
        triage_requests_total.labels(status="success", strategy="openai").inc()
        if i % 2 == 0:
            cache_hits_total.inc()
        else:
            cache_misses_total.inc()


def test_histogram_buckets():
    """Testa buckets de histogramas"""
    # Testar valores em diferentes buckets
    durations = [0.001, 0.01, 0.1, 1.0, 10.0, 60.0]
    
    for duration in durations:
        triage_duration.labels(strategy="openai").observe(duration)
        matching_duration.labels(preset="balanced", num_candidates="10-50").observe(duration)
        notification_duration.labels(type="email").observe(duration)
        external_api_duration.labels(service="openai", operation="embedding").observe(duration)
        database_query_duration.labels(operation="select", table="test_table").observe(duration)


def test_metric_reset():
    """Testa reset de métricas (simulado)"""
    # Definir valores
    active_offers.set(50)
    pending_contracts.set(20)
    
    # "Reset" definindo para 0
    active_offers.set(0)
    pending_contracts.set(0)
    
    assert active_offers._value.get() == 0
    assert pending_contracts._value.get() == 0


def test_queue_size_by_type():
    """Testa tamanho de fila por tipo"""
    queue_names = ["triage", "matching", "notification", "contract", "review"]
    
    for i, queue_name in enumerate(queue_names):
        queue_size.labels(queue_name=queue_name).set(i * 10)


def test_performance_metrics_calculation():
    """Testa cálculo de métricas de performance"""
    # Simular cálculo de hit rate
    hits = 920
    total = 1000
    hit_rate_value = hits / total
    cache_hit_rate.labels(cache_type="redis").set(hit_rate_value)
    
    # Simular cálculo de Gini
    # (valores fictícios para teste)
    gini = 0.42
    equity_distribution.set(gini)
    
    # Simular carga média
    total_capacity = 500
    total_load = 375
    avg_load = total_load / total_capacity
    average_lawyer_load.labels(area="Civil").set(avg_load) 