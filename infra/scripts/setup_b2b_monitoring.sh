#!/bin/bash

# 📊 Setup B2B Monitoring - Prometheus & Grafana
# Script para configurar monitoramento completo da funcionalidade B2B

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
PROMETHEUS_CONFIG="infra/prometheus/prometheus.yml"
GRAFANA_DASHBOARD="infra/grafana/dashboards/b2b_dashboard.json"
ALERTS_CONFIG="infra/prometheus/alerts.yml"

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Função para verificar dependências
check_dependencies() {
    log "Verificando dependências..."
    
    # Verificar se Docker está instalado
    if ! command -v docker &> /dev/null; then
        error "Docker não está instalado. Instale o Docker primeiro."
        exit 1
    fi
    
    # Verificar se Docker Compose está instalado
    if ! command -v docker-compose &> /dev/null; then
        error "Docker Compose não está instalado. Instale o Docker Compose primeiro."
        exit 1
    fi
    
    success "Dependências verificadas"
}

# Função para configurar Prometheus
setup_prometheus() {
    log "Configurando Prometheus para monitoramento B2B..."
    
    # Criar diretório se não existir
    mkdir -p infra/prometheus
    
    # Atualizar configuração do Prometheus
    cat > "$PROMETHEUS_CONFIG" << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "alerts.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  - job_name: 'litgo-backend'
    static_configs:
      - targets: ['backend:8080']
    metrics_path: '/metrics'
    scrape_interval: 10s
    
  - job_name: 'litgo-b2b-metrics'
    static_configs:
      - targets: ['backend:8080']
    metrics_path: '/api/metrics/b2b'
    scrape_interval: 30s
    
  - job_name: 'redis'
    static_configs:
      - targets: ['redis:6379']
    metrics_path: '/metrics'
    
  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres:5432']
    metrics_path: '/metrics'
EOF

    success "Prometheus configurado"
}

# Função para configurar alertas
setup_alerts() {
    log "Configurando alertas B2B..."
    
    cat > "$ALERTS_CONFIG" << 'EOF'
groups:
  - name: b2b_alerts
    rules:
      # Alerta para latência alta no matching B2B
      - alert: B2BMatchingHighLatency
        expr: histogram_quantile(0.99, rate(litgo_match_duration_seconds_bucket{preset="b2b"}[5m])) > 0.2
        for: 2m
        labels:
          severity: warning
          component: matching
          feature: b2b
        annotations:
          summary: "Latência alta no matching B2B"
          description: "Latência P99 do matching B2B está em {{ $value }}s (limite: 200ms)"
          
      # Alerta para taxa de sucesso baixa no B2B
      - alert: B2BSuccessRateLow
        expr: rate(litgo_match_success_total{entity="firm"}[10m]) / rate(litgo_match_total{entity="firm"}[10m]) < 0.7
        for: 5m
        labels:
          severity: critical
          component: matching
          feature: b2b
        annotations:
          summary: "Taxa de sucesso B2B baixa"
          description: "Taxa de sucesso do matching B2B está em {{ $value | humanizePercentage }} (meta: >70%)"
          
      # Alerta para erro alto na Feature-E
      - alert: FeatureEErrorRate
        expr: rate(litgo_feature_e_error_total[5m]) > 0.1
        for: 1m
        labels:
          severity: warning
          component: algorithm
          feature: feature_e
        annotations:
          summary: "Alta taxa de erro na Feature-E"
          description: "Feature-E (Firm Reputation) com {{ $value | humanizePercentage }} de erro"
          
      # Alerta para cache miss alto no Redis
      - alert: B2BCacheMissHigh
        expr: rate(litgo_cache_miss_total{entity="firm"}[5m]) / rate(litgo_cache_requests_total{entity="firm"}[5m]) > 0.3
        for: 3m
        labels:
          severity: warning
          component: cache
          feature: b2b
        annotations:
          summary: "Cache miss alto para escritórios"
          description: "Cache miss rate para escritórios: {{ $value | humanizePercentage }} (limite: 30%)"
          
      # Alerta para escritórios sem KPIs
      - alert: FirmsWithoutKPIs
        expr: litgo_firms_without_kpis > 0
        for: 1m
        labels:
          severity: warning
          component: data_quality
          feature: b2b
        annotations:
          summary: "Escritórios sem KPIs"
          description: "{{ $value }} escritórios estão sem KPIs configurados"
          
      # Alerta para falha na migration
      - alert: B2BMigrationFailure
        expr: litgo_migration_status{type="b2b"} == 0
        for: 0m
        labels:
          severity: critical
          component: migration
          feature: b2b
        annotations:
          summary: "Falha na migração B2B"
          description: "Migration B2B falhou - verificar logs imediatamente"
EOF

    success "Alertas configurados"
}

# Função para configurar dashboard do Grafana
setup_grafana_dashboard() {
    log "Configurando dashboard B2B no Grafana..."
    
    mkdir -p infra/grafana/dashboards
    
    cat > "$GRAFANA_DASHBOARD" << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "LITGO B2B Monitoring",
    "tags": ["b2b", "matching", "firms"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "B2B Matching Success Rate",
        "type": "stat",
        "targets": [
          {
            "expr": "rate(litgo_match_success_total{entity=\"firm\"}[10m]) / rate(litgo_match_total{entity=\"firm\"}[10m])",
            "legendFormat": "Success Rate"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percentunit",
            "min": 0,
            "max": 1,
            "thresholds": {
              "steps": [
                {"color": "red", "value": 0},
                {"color": "yellow", "value": 0.6},
                {"color": "green", "value": 0.7}
              ]
            }
          }
        },
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0}
      },
      {
        "id": 2,
        "title": "B2B Matching Latency (P99)",
        "type": "stat",
        "targets": [
          {
            "expr": "histogram_quantile(0.99, rate(litgo_match_duration_seconds_bucket{preset=\"b2b\"}[5m]))",
            "legendFormat": "P99 Latency"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "s",
            "thresholds": {
              "steps": [
                {"color": "green", "value": 0},
                {"color": "yellow", "value": 0.1},
                {"color": "red", "value": 0.2}
              ]
            }
          }
        },
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
      },
      {
        "id": 3,
        "title": "Feature-E Performance",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(litgo_feature_e_calculation_total[5m])",
            "legendFormat": "Calculations/sec"
          },
          {
            "expr": "rate(litgo_feature_e_error_total[5m])",
            "legendFormat": "Errors/sec"
          }
        ],
        "yAxes": [
          {"label": "Operations/sec", "min": 0}
        ],
        "gridPos": {"h": 8, "w": 24, "x": 0, "y": 8}
      },
      {
        "id": 4,
        "title": "Firm Cache Performance",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(litgo_cache_hits_total{entity=\"firm\"}[5m])",
            "legendFormat": "Cache Hits/sec"
          },
          {
            "expr": "rate(litgo_cache_miss_total{entity=\"firm\"}[5m])",
            "legendFormat": "Cache Misses/sec"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 16}
      },
      {
        "id": 5,
        "title": "Active Firms by KPI Status",
        "type": "piechart",
        "targets": [
          {
            "expr": "litgo_firms_with_kpis",
            "legendFormat": "With KPIs"
          },
          {
            "expr": "litgo_firms_without_kpis",
            "legendFormat": "Without KPIs"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 16}
      },
      {
        "id": 6,
        "title": "B2B Algorithm Two-Pass Performance",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.50, rate(litgo_b2b_firm_ranking_duration_seconds_bucket[5m]))",
            "legendFormat": "P50 Firm Ranking"
          },
          {
            "expr": "histogram_quantile(0.50, rate(litgo_b2b_lawyer_ranking_duration_seconds_bucket[5m]))",
            "legendFormat": "P50 Lawyer Ranking"
          },
          {
            "expr": "histogram_quantile(0.99, rate(litgo_b2b_total_duration_seconds_bucket[5m]))",
            "legendFormat": "P99 Total B2B"
          }
        ],
        "yAxes": [
          {"label": "Duration (seconds)", "min": 0}
        ],
        "gridPos": {"h": 8, "w": 24, "x": 0, "y": 24}
      },
      {
        "id": 7,
        "title": "Firm Reputation Distribution",
        "type": "histogram",
        "targets": [
          {
            "expr": "litgo_firm_reputation_score",
            "legendFormat": "Reputation Score"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 32}
      },
      {
        "id": 8,
        "title": "B2B Matching Requests Over Time",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(litgo_match_total{preset=\"b2b\"}[5m])",
            "legendFormat": "B2B Requests/sec"
          },
          {
            "expr": "rate(litgo_match_total{preset=\"balanced\"}[5m])",
            "legendFormat": "Regular Requests/sec"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 32}
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "30s"
  }
}
EOF

    success "Dashboard do Grafana configurado"
}

# Função para configurar Docker Compose
setup_docker_compose() {
    log "Configurando Docker Compose para monitoramento..."
    
    cat > "infra/docker-compose.monitoring.yml" << 'EOF'
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: litgo-prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus:/etc/prometheus
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'
    restart: unless-stopped
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:latest
    container_name: litgo-grafana
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
      - ./grafana/dashboards:/var/lib/grafana/dashboards
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin123
      - GF_USERS_ALLOW_SIGN_UP=false
    restart: unless-stopped
    networks:
      - monitoring

  alertmanager:
    image: prom/alertmanager:latest
    container_name: litgo-alertmanager
    ports:
      - "9093:9093"
    volumes:
      - ./alertmanager:/etc/alertmanager
    command:
      - '--config.file=/etc/alertmanager/config.yml'
      - '--storage.path=/alertmanager'
      - '--web.external-url=http://localhost:9093'
    restart: unless-stopped
    networks:
      - monitoring

  redis-exporter:
    image: oliver006/redis_exporter:latest
    container_name: litgo-redis-exporter
    ports:
      - "9121:9121"
    environment:
      - REDIS_ADDR=redis:6379
    restart: unless-stopped
    networks:
      - monitoring

  postgres-exporter:
    image: prometheuscommunity/postgres-exporter:latest
    container_name: litgo-postgres-exporter
    ports:
      - "9187:9187"
    environment:
      - DATA_SOURCE_NAME=postgresql://postgres:password@postgres:5432/litgo5?sslmode=disable
    restart: unless-stopped
    networks:
      - monitoring

volumes:
  prometheus_data:
  grafana_data:

networks:
  monitoring:
    driver: bridge
EOF

    success "Docker Compose configurado"
}

# Função para configurar Alertmanager
setup_alertmanager() {
    log "Configurando Alertmanager..."
    
    mkdir -p infra/alertmanager
    
    cat > "infra/alertmanager/config.yml" << 'EOF'
global:
  smtp_smarthost: 'localhost:587'
  smtp_from: 'alerts@litgo.com'

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'

receivers:
  - name: 'web.hook'
    webhook_configs:
      - url: 'http://backend:8080/api/alerts/webhook'
        send_resolved: true
        
  - name: 'email-alerts'
    email_configs:
      - to: 'admin@litgo.com'
        subject: 'LITGO B2B Alert: {{ .GroupLabels.alertname }}'
        body: |
          {{ range .Alerts }}
          Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          Labels: {{ .Labels }}
          {{ end }}

  - name: 'slack-alerts'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
        channel: '#alerts'
        title: 'LITGO B2B Alert'
        text: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'cluster', 'service']
EOF

    success "Alertmanager configurado"
}

# Função para criar métricas customizadas no backend
setup_backend_metrics() {
    log "Configurando métricas customizadas no backend..."
    
    cat > "packages/backend/monitoring/b2b_metrics.py" << 'EOF'
"""
Métricas customizadas para monitoramento B2B
"""
from prometheus_client import Counter, Histogram, Gauge, Info
import time
from functools import wraps

# Contadores
b2b_match_total = Counter(
    'litgo_match_total',
    'Total de matches executados',
    ['entity', 'preset', 'complexity']
)

b2b_match_success_total = Counter(
    'litgo_match_success_total',
    'Matches bem-sucedidos',
    ['entity', 'preset']
)

feature_e_calculation_total = Counter(
    'litgo_feature_e_calculation_total',
    'Cálculos da Feature-E executados'
)

feature_e_error_total = Counter(
    'litgo_feature_e_error_total',
    'Erros na Feature-E'
)

# Histogramas
b2b_match_duration = Histogram(
    'litgo_match_duration_seconds',
    'Duração do matching',
    ['preset', 'entity'],
    buckets=[0.001, 0.005, 0.01, 0.05, 0.1, 0.2, 0.5, 1.0, 2.0, 5.0]
)

b2b_firm_ranking_duration = Histogram(
    'litgo_b2b_firm_ranking_duration_seconds',
    'Duração do ranking de escritórios no B2B',
    buckets=[0.001, 0.005, 0.01, 0.05, 0.1, 0.2, 0.5]
)

b2b_lawyer_ranking_duration = Histogram(
    'litgo_b2b_lawyer_ranking_duration_seconds',
    'Duração do ranking de advogados no B2B',
    buckets=[0.001, 0.005, 0.01, 0.05, 0.1, 0.2, 0.5]
)

b2b_total_duration = Histogram(
    'litgo_b2b_total_duration_seconds',
    'Duração total do algoritmo B2B two-pass',
    buckets=[0.001, 0.005, 0.01, 0.05, 0.1, 0.2, 0.5, 1.0]
)

# Gauges
firms_with_kpis = Gauge(
    'litgo_firms_with_kpis',
    'Número de escritórios com KPIs configurados'
)

firms_without_kpis = Gauge(
    'litgo_firms_without_kpis',
    'Número de escritórios sem KPIs'
)

firm_reputation_score = Gauge(
    'litgo_firm_reputation_score',
    'Score de reputação dos escritórios',
    ['firm_id', 'firm_name']
)

# Cache metrics
cache_hits_total = Counter(
    'litgo_cache_hits_total',
    'Cache hits',
    ['entity', 'operation']
)

cache_miss_total = Counter(
    'litgo_cache_miss_total',
    'Cache misses',
    ['entity', 'operation']
)

cache_requests_total = Counter(
    'litgo_cache_requests_total',
    'Total cache requests',
    ['entity', 'operation']
)

# Migration metrics
migration_status = Gauge(
    'litgo_migration_status',
    'Status da migração (1=sucesso, 0=falha)',
    ['type', 'version']
)

# Decorador para medir duração
def measure_duration(metric, labels=None):
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            start_time = time.time()
            try:
                result = await func(*args, **kwargs)
                return result
            finally:
                duration = time.time() - start_time
                if labels:
                    metric.labels(**labels).observe(duration)
                else:
                    metric.observe(duration)
        return wrapper
    return decorator

# Decorador para contar operações
def count_operation(metric, labels=None):
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            try:
                result = await func(*args, **kwargs)
                if labels:
                    metric.labels(**labels).inc()
                else:
                    metric.inc()
                return result
            except Exception as e:
                # Não incrementar contador em caso de erro
                raise
        return wrapper
    return decorator

# Função para atualizar métricas de escritórios
async def update_firm_metrics(db_session):
    """Atualiza métricas relacionadas aos escritórios"""
    from sqlalchemy import text
    
    # Contar escritórios com e sem KPIs
    result = await db_session.execute(text("""
        SELECT 
            COUNT(CASE WHEN fk.firm_id IS NOT NULL THEN 1 END) as with_kpis,
            COUNT(CASE WHEN fk.firm_id IS NULL THEN 1 END) as without_kpis
        FROM law_firms lf
        LEFT JOIN firm_kpis fk ON lf.id = fk.firm_id
    """))
    
    row = result.fetchone()
    if row:
        firms_with_kpis.set(row.with_kpis)
        firms_without_kpis.set(row.without_kpis)
    
    # Atualizar scores de reputação
    result = await db_session.execute(text("""
        SELECT lf.id, lf.name, fk.reputation_score
        FROM law_firms lf
        JOIN firm_kpis fk ON lf.id = fk.firm_id
        WHERE fk.reputation_score IS NOT NULL
    """))
    
    for row in result:
        firm_reputation_score.labels(
            firm_id=row.id,
            firm_name=row.name
        ).set(row.reputation_score)
EOF

    success "Métricas customizadas configuradas"
}

# Função para testar configuração
test_monitoring() {
    log "Testando configuração de monitoramento..."
    
    # Verificar se arquivos foram criados
    local files=(
        "$PROMETHEUS_CONFIG"
        "$GRAFANA_DASHBOARD"
        "$ALERTS_CONFIG"
        "infra/docker-compose.monitoring.yml"
        "infra/alertmanager/config.yml"
    )
    
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            success "Arquivo $file criado"
        else
            error "Arquivo $file não encontrado"
            return 1
        fi
    done
    
    # Validar sintaxe do Prometheus
    if command -v promtool &> /dev/null; then
        if promtool check config "$PROMETHEUS_CONFIG"; then
            success "Configuração do Prometheus válida"
        else
            error "Configuração do Prometheus inválida"
            return 1
        fi
    else
        warning "promtool não encontrado, pulando validação"
    fi
    
    success "Configuração de monitoramento testada"
}

# Função para iniciar serviços
start_monitoring() {
    log "Iniciando serviços de monitoramento..."
    
    cd infra
    docker-compose -f docker-compose.monitoring.yml up -d
    
    # Aguardar serviços ficarem prontos
    sleep 10
    
    # Verificar se serviços estão rodando
    if curl -s http://localhost:9090/-/healthy > /dev/null; then
        success "Prometheus rodando em http://localhost:9090"
    else
        error "Prometheus não está respondendo"
    fi
    
    if curl -s http://localhost:3000/api/health > /dev/null; then
        success "Grafana rodando em http://localhost:3000"
    else
        error "Grafana não está respondendo"
    fi
    
    success "Serviços de monitoramento iniciados"
}

# Função para mostrar informações finais
show_info() {
    log "Configuração de monitoramento B2B concluída!"
    echo
    echo "🔗 URLs dos serviços:"
    echo "  • Prometheus: http://localhost:9090"
    echo "  • Grafana: http://localhost:3000 (admin/admin123)"
    echo "  • Alertmanager: http://localhost:9093"
    echo
    echo "📊 Dashboards disponíveis:"
    echo "  • LITGO B2B Monitoring"
    echo
    echo "🚨 Alertas configurados:"
    echo "  • B2BMatchingHighLatency (>200ms)"
    echo "  • B2BSuccessRateLow (<70%)"
    echo "  • FeatureEErrorRate (>10%)"
    echo "  • B2BCacheMissHigh (>30%)"
    echo "  • FirmsWithoutKPIs"
    echo
    echo "📈 Métricas principais:"
    echo "  • litgo_match_total{entity='firm'}"
    echo "  • litgo_match_duration_seconds{preset='b2b'}"
    echo "  • litgo_feature_e_calculation_total"
    echo "  • litgo_firms_with_kpis"
    echo
    echo "🔧 Comandos úteis:"
    echo "  • Parar: docker-compose -f infra/docker-compose.monitoring.yml down"
    echo "  • Logs: docker-compose -f infra/docker-compose.monitoring.yml logs -f"
    echo "  • Restart: docker-compose -f infra/docker-compose.monitoring.yml restart"
}

# Função principal
main() {
    log "🚀 Iniciando configuração de monitoramento B2B..."
    
    check_dependencies
    setup_prometheus
    setup_alerts
    setup_grafana_dashboard
    setup_docker_compose
    setup_alertmanager
    setup_backend_metrics
    test_monitoring
    
    # Perguntar se deve iniciar os serviços
    echo
    read -p "Deseja iniciar os serviços de monitoramento agora? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        start_monitoring
    fi
    
    show_info
    
    success "Setup de monitoramento B2B concluído com sucesso!"
}

# Executar função principal
main "$@" 