"""
Módulo de métricas Prometheus para monitoramento do sistema LITGO5.
Inclui contadores, histogramas e gauges para métricas técnicas e de negócio.
"""
import time
from functools import wraps
from typing import Any, Callable

from prometheus_client import Counter, Gauge, Histogram, Info

# =============================================================================
# CONTADORES - Métricas que só aumentam
# =============================================================================

# Métricas de requisições
triage_requests_total = Counter(
    'triage_requests_total',
    'Total de requisições de triagem',
    ['status', 'strategy']  # Labels: success/error, strategy usada
)

matches_found_total = Counter(
    'matches_found_total',
    'Total de matches encontrados',
    ['preset', 'case_complexity']  # Labels: preset usado, complexidade do caso
)

offers_created_total = Counter(
    'offers_created_total',
    'Total de ofertas criadas',
    ['case_area']  # Label: área do caso
)

contracts_signed_total = Counter(
    'contracts_signed_total',
    'Total de contratos assinados',
    ['fee_type', 'case_area']  # Labels: tipo de honorário, área
)

notifications_sent_total = Counter(
    'notifications_sent_total',
    'Total de notificações enviadas',
    ['type', 'status']  # Labels: push/email, success/failed
)

# Métricas de jobs
job_executions_total = Counter(
    'job_executions_total',
    'Total de execuções de jobs',
    ['job_name', 'status']  # Labels: nome do job, success/failed
)

# Métricas de API
api_requests_total = Counter(
    'api_requests_total',
    'Total de requisições à API',
    ['method', 'endpoint', 'status_code']
)

# Métricas de fallback
fallback_usage_total = Counter(
    'fallback_usage_total',
    'Total de uso de fallbacks',
    ['service', 'reason']  # Labels: openai/docusign, timeout/error
)

# Métricas de cache
cache_hits_total = Counter(
    'cache_hits_total',
    'Total de hits no cache de matching'
)

cache_misses_total = Counter(
    'cache_misses_total',
    'Total de misses no cache de matching'
)

# Métricas de A/B Testing
ab_test_exposure_total = Counter(
    'ab_test_exposure_total',
    'Total de exposições em testes A/B',
    ['test_id', 'group']  # Labels: ID do teste, grupo (control/treatment)
)

ab_test_conversions_total = Counter(
    'ab_test_conversions_total',
    'Total de conversões em testes A/B',
    ['test_id', 'group']  # Labels: ID do teste, grupo (control/treatment)
)

model_retrain_total = Counter(
    'model_retrain_total',
    'Total de retreinos de modelo',
    ['trigger']  # Label: scheduled/manual/drift
)

model_alert_total = Counter(
    'model_alert_total',
    'Total de alertas de modelo',
    # Labels: tipo do modelo, tipo de alerta, nível
    ['model_type', 'alert_type', 'level']
)

# =============================================================================
# HISTOGRAMAS - Métricas de latência/duração
# =============================================================================

triage_duration = Histogram(
    'triage_duration_seconds',
    'Tempo de processamento de triagem',
    ['strategy'],  # Label: estratégia usada
    buckets=(0.1, 0.5, 1, 2, 5, 10, 30, 60)
)

matching_duration = Histogram(
    'matching_duration_seconds',
    'Tempo de processamento de matching',
    ['preset', 'num_candidates'],  # Labels: preset, número de candidatos
    buckets=(0.05, 0.1, 0.25, 0.5, 1, 2, 5)
)

notification_duration = Histogram(
    'notification_duration_seconds',
    'Tempo de envio de notificação',
    ['type'],  # Label: push/email
    buckets=(0.1, 0.5, 1, 2, 5, 10)
)

external_api_duration = Histogram(
    'external_api_duration_seconds',
    'Tempo de resposta de APIs externas',
    ['service', 'operation'],  # Labels: openai/docusign, operação
    buckets=(0.1, 0.5, 1, 2, 5, 10, 30)
)

database_query_duration = Histogram(
    'database_query_duration_seconds',
    'Tempo de execução de queries',
    ['operation', 'table'],  # Labels: select/update/insert, tabela
    buckets=(0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1)
)

# =============================================================================
# GAUGES - Métricas que podem subir ou descer
# =============================================================================

active_offers = Gauge(
    'active_offers_count',
    'Número de ofertas ativas no momento'
)

pending_contracts = Gauge(
    'pending_contracts_count',
    'Número de contratos pendentes de assinatura'
)

system_health = Gauge(
    'system_health_score',
    'Score de saúde geral do sistema (0-100)'
)

lawyers_available = Gauge(
    'lawyers_available_count',
    'Número de advogados disponíveis',
    ['area']  # Label: área de atuação
)

queue_size = Gauge(
    'queue_size',
    'Tamanho das filas de processamento',
    ['queue_name']  # Label: nome da fila
)

cache_hit_rate = Gauge(
    'cache_hit_rate',
    'Taxa de acerto do cache (0-1)',
    ['cache_type']  # Label: redis/local
)

# Métricas de equidade
equity_distribution = Gauge(
    'equity_distribution_gini',
    'Coeficiente de Gini da distribuição de casos (0-1)'
)

average_lawyer_load = Gauge(
    'average_lawyer_load_percent',
    'Carga média dos advogados (%)',
    ['area']  # Label: área de atuação
)

# Métricas de A/B Testing e Monitoramento
ab_test_performance_gauge = Gauge(
    'ab_test_performance_gauge',
    'Performance dos grupos em testes A/B',
    ['test_id', 'group']  # Labels: ID do teste, grupo (control/treatment)
)

model_performance_gauge = Gauge(
    'model_performance_gauge',
    'Métricas de performance dos modelos',
    ['model_type', 'metric']  # Labels: tipo do modelo, métrica (mse/r2/ndcg)
)

model_drift_gauge = Gauge(
    'model_drift_gauge',
    'Score de drift das features dos modelos',
    ['model_type', 'feature']  # Labels: tipo do modelo, feature
)

# =============================================================================
# INFO - Métricas de informação/versão
# =============================================================================

system_info = Info(
    'litgo_system',
    'Informações do sistema LITGO5'
)

# Definir informações do sistema
system_info.info({
    'version': '2.2.0',
    'environment': 'production',
    'algorithm_version': 'v2.2',
    'ltr_enabled': 'true'
})

# =============================================================================
# DECORADORES AUXILIARES
# =============================================================================


def track_time(histogram: Histogram, **labels):
    """Decorador para medir tempo de execução."""
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        async def async_wrapper(*args, **kwargs) -> Any:
            start_time = time.time()
            try:
                result = await func(*args, **kwargs)
                return result
            finally:
                duration = time.time() - start_time
                histogram.labels(**labels).observe(duration)

        @wraps(func)
        def sync_wrapper(*args, **kwargs) -> Any:
            start_time = time.time()
            try:
                result = func(*args, **kwargs)
                return result
            finally:
                duration = time.time() - start_time
                histogram.labels(**labels).observe(duration)

        # Retornar wrapper apropriado baseado no tipo da função
        import asyncio
        if asyncio.iscoroutinefunction(func):
            return async_wrapper
        else:
            return sync_wrapper

    return decorator


def track_request(counter: Counter, **labels):
    """Decorador para contar requisições."""
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        async def async_wrapper(*args, **kwargs) -> Any:
            try:
                result = await func(*args, **kwargs)
                counter.labels(status='success', **labels).inc()
                return result
            except Exception as e:
                counter.labels(status='error', **labels).inc()
                raise

        @wraps(func)
        def sync_wrapper(*args, **kwargs) -> Any:
            try:
                result = func(*args, **kwargs)
                counter.labels(status='success', **labels).inc()
                return result
            except Exception as e:
                counter.labels(status='error', **labels).inc()
                raise

        # Retornar wrapper apropriado
        import asyncio
        if asyncio.iscoroutinefunction(func):
            return async_wrapper
        else:
            return sync_wrapper

    return decorator


# =============================================================================
# FUNÇÕES AUXILIARES
# =============================================================================

def update_system_health():
    """Atualiza o score de saúde do sistema baseado em várias métricas."""
    health_score = 100.0

    # Penalizar por alta taxa de erro
    # (implementação simplificada - em produção seria mais sofisticada)

    # Penalizar por muitas ofertas expirando
    # Penalizar por alta latência
    # Penalizar por baixa taxa de cache

    system_health.set(health_score)


def calculate_gini_coefficient(values: list) -> float:
    """Calcula o coeficiente de Gini para medir desigualdade."""
    if not values or len(values) == 0:
        return 0.0

    sorted_values = sorted(values)
    n = len(values)
    cumsum = 0
    for i, value in enumerate(sorted_values):
        cumsum += (2 * (i + 1) - n - 1) * value

    return cumsum / (n * sum(sorted_values)) if sum(sorted_values) > 0 else 0.0


# =============================================================================
# EXEMPLO DE USO
# =============================================================================

if __name__ == "__main__":
    # Exemplo de uso das métricas

    # Incrementar contador
    triage_requests_total.labels(status='success', strategy='openai').inc()

    # Observar duração
    with triage_duration.labels(strategy='openai').time():
        # Simular processamento
        import time
        time.sleep(0.5)

    # Atualizar gauge
    active_offers.set(42)

    # Usar decoradores
    @track_time(matching_duration, preset='balanced', num_candidates='10-50')
    @track_request(matches_found_total, preset='balanced', case_complexity='medium')
    async def example_matching():
        # Simular matching
        import asyncio
        await asyncio.sleep(0.1)
        return ["match1", "match2", "match3"]

    print("✅ Métricas Prometheus configuradas!")
