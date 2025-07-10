#!/bin/bash

# Script para configurar Grafana avançado para LITGO5
# Autor: Sistema LITGO5
# Data: $(date +%Y-%m-%d)

set -e

echo "🚀 Configurando Grafana Avançado para LITGO5..."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para log
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

# Verificar se Docker está rodando
if ! docker info > /dev/null 2>&1; then
    error "Docker não está rodando. Inicie o Docker primeiro."
    exit 1
fi

# Criar diretórios necessários
log "Criando estrutura de diretórios..."
mkdir -p grafana/provisioning/{datasources,dashboards,alerting,notifiers}
mkdir -p grafana/dashboards
mkdir -p grafana/plugins

# Verificar se os arquivos de configuração existem
if [ ! -f "grafana/provisioning/datasources/prometheus.yml" ]; then
    warn "Arquivo de configuração do Prometheus não encontrado. Criando..."
    # Arquivo já foi criado anteriormente
fi

# Parar containers existentes se estiverem rodando
log "Parando containers existentes..."
docker-compose -f docker-compose.observability.yml down 2>/dev/null || true

# Construir e iniciar containers
log "Iniciando containers do Grafana e Prometheus..."
docker-compose -f docker-compose.observability.yml up -d

# Aguardar Grafana estar pronto
log "Aguardando Grafana inicializar..."
timeout=60
counter=0
while [ $counter -lt $timeout ]; do
    if curl -s http://localhost:3001/api/health > /dev/null 2>&1; then
        log "Grafana está pronto!"
        break
    fi
    sleep 2
    counter=$((counter + 2))
done

if [ $counter -ge $timeout ]; then
    error "Timeout aguardando Grafana inicializar"
    exit 1
fi

# Configurar API Key para automação (opcional)
log "Configurando API Key para automação..."
API_KEY=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d '{"name":"litgo5-automation","role":"Admin"}' \
    http://admin:admin123@localhost:3001/api/auth/keys | jq -r '.key' 2>/dev/null || echo "")

if [ -n "$API_KEY" ]; then
    log "API Key criada com sucesso"
    echo "GRAFANA_API_KEY=$API_KEY" >> .env.local
else
    warn "Não foi possível criar API Key automaticamente"
fi

# Verificar se dashboards foram carregados
log "Verificando dashboards..."
sleep 5
DASHBOARDS=$(curl -s -H "Authorization: Bearer $API_KEY" \
    http://localhost:3001/api/search?query=LITGO5 2>/dev/null | jq length 2>/dev/null || echo "0")

if [ "$DASHBOARDS" -gt "0" ]; then
    log "Dashboards LITGO5 carregados com sucesso ($DASHBOARDS encontrados)"
else
    warn "Dashboards podem não ter sido carregados automaticamente"
fi

# Verificar data sources
log "Verificando data sources..."
DATASOURCES=$(curl -s -H "Authorization: Bearer $API_KEY" \
    http://localhost:3001/api/datasources 2>/dev/null | jq length 2>/dev/null || echo "0")

if [ "$DATASOURCES" -gt "0" ]; then
    log "Data sources configurados ($DATASOURCES encontrados)"
else
    warn "Data sources podem não estar configurados corretamente"
fi

# Mostrar informações finais
log "✅ Configuração concluída!"
echo ""
echo "📊 Acesso ao Grafana:"
echo "   URL: http://localhost:3001"
echo "   Usuário: admin"
echo "   Senha: admin123"
echo ""
echo "🔧 Dashboards disponíveis:"
echo "   - LITGO5 - Visão Geral do Sistema"
echo "   - LITGO5 - A/B Testing & Monitoramento de Modelos"
echo "   - LITGO5 - Métricas de Negócio & Equidade"
echo ""
echo "📈 Prometheus:"
echo "   URL: http://localhost:9090"
echo ""
echo "🚨 Para configurar alertas Slack:"
echo "   1. Configure SLACK_WEBHOOK_URL no arquivo .env"
echo "   2. Reinicie os containers"
echo ""

# Verificar se Prometheus está coletando métricas
log "Verificando coleta de métricas..."
METRICS=$(curl -s http://localhost:9090/api/v1/label/__name__/values 2>/dev/null | jq '.data | length' 2>/dev/null || echo "0")

if [ "$METRICS" -gt "10" ]; then
    log "Prometheus está coletando métricas ($METRICS métricas disponíveis)"
else
    warn "Prometheus pode não estar coletando métricas corretamente"
fi

log "🎉 Setup do Grafana Avançado concluído com sucesso!" 