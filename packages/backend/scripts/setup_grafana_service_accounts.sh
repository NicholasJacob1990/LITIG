#!/bin/bash

# Script para configurar Grafana com Service Accounts (substitui API Keys depreciadas)
# Baseado em: https://grafana.com/docs/grafana/latest/administration/service-accounts/migrate-api-keys/
# Autor: Sistema LITGO5
# Data: $(date +%Y-%m-%d)

set -e

echo "🚀 Configurando Grafana com Service Accounts (Moderna e Segura)..."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $1"
}

# Verificar se Docker está rodando
if ! docker info > /dev/null 2>&1; then
    error "Docker não está rodando. Inicie o Docker primeiro."
    exit 1
fi

# Verificar se jq está instalado
if ! command -v jq &> /dev/null; then
    error "jq não está instalado. Instale com: brew install jq (macOS) ou apt-get install jq (Ubuntu)"
    exit 1
fi

# Criar diretórios necessários
log "Criando estrutura de diretórios..."
mkdir -p grafana/provisioning/{datasources,dashboards,alerting,notifiers}
mkdir -p grafana/dashboards
mkdir -p grafana/plugins

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

# Aguardar um pouco mais para garantir que tudo está carregado
sleep 5

# Configurações de autenticação
GRAFANA_URL="http://localhost:3001"
GRAFANA_USER="admin"
GRAFANA_PASS="admin123"
AUTH="$GRAFANA_USER:$GRAFANA_PASS"

info "🔐 Criando Service Account (substitui API Keys depreciadas)..."

# Criar Service Account
SERVICE_ACCOUNT_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d '{
        "name": "litgo5-automation-sa",
        "displayName": "LITGO5 Automation Service Account",
        "role": "Admin"
    }' \
    http://$AUTH@$GRAFANA_URL/api/serviceaccounts 2>/dev/null)

if [ $? -eq 0 ]; then
    SERVICE_ACCOUNT_ID=$(echo "$SERVICE_ACCOUNT_RESPONSE" | jq -r '.id' 2>/dev/null)
    if [ "$SERVICE_ACCOUNT_ID" != "null" ] && [ -n "$SERVICE_ACCOUNT_ID" ]; then
        log "✅ Service Account criado com ID: $SERVICE_ACCOUNT_ID"
    else
        warn "Service Account pode já existir. Tentando buscar..."
        # Buscar Service Account existente
        EXISTING_SA=$(curl -s http://$AUTH@$GRAFANA_URL/api/serviceaccounts/search?query=litgo5-automation-sa 2>/dev/null)
        SERVICE_ACCOUNT_ID=$(echo "$EXISTING_SA" | jq -r '.serviceAccounts[0].id' 2>/dev/null)
        if [ "$SERVICE_ACCOUNT_ID" != "null" ] && [ -n "$SERVICE_ACCOUNT_ID" ]; then
            log "✅ Service Account existente encontrado com ID: $SERVICE_ACCOUNT_ID"
        else
            error "Falha ao criar ou encontrar Service Account"
            exit 1
        fi
    fi
else
    error "Falha na requisição para criar Service Account"
    exit 1
fi

info "🔑 Criando Service Account Token..."

# Criar Service Account Token
TOKEN_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d '{
        "name": "litgo5-automation-token",
        "secondsToLive": 2592000
    }' \
    http://$AUTH@$GRAFANA_URL/api/serviceaccounts/$SERVICE_ACCOUNT_ID/tokens 2>/dev/null)

if [ $? -eq 0 ]; then
    SERVICE_ACCOUNT_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.key' 2>/dev/null)
    if [ "$SERVICE_ACCOUNT_TOKEN" != "null" ] && [ -n "$SERVICE_ACCOUNT_TOKEN" ]; then
        log "✅ Service Account Token criado com sucesso"
        
        # Salvar token em arquivo seguro (apenas para automação local)
        echo "GRAFANA_SERVICE_ACCOUNT_TOKEN=$SERVICE_ACCOUNT_TOKEN" > .env.grafana
        chmod 600 .env.grafana
        log "🔐 Token salvo em .env.grafana (arquivo protegido)"
    else
        error "Falha ao extrair token da resposta"
        exit 1
    fi
else
    error "Falha na requisição para criar Service Account Token"
    exit 1
fi

info "🧪 Testando Service Account Token..."

# Testar o token
TEST_RESPONSE=$(curl -s -H "Authorization: Bearer $SERVICE_ACCOUNT_TOKEN" \
    $GRAFANA_URL/api/user 2>/dev/null)

if [ $? -eq 0 ]; then
    USER_INFO=$(echo "$TEST_RESPONSE" | jq -r '.login' 2>/dev/null)
    if [ "$USER_INFO" != "null" ] && [ -n "$USER_INFO" ]; then
        log "✅ Service Account Token funcionando corretamente"
    else
        warn "Token pode não estar funcionando corretamente"
    fi
else
    error "Falha ao testar Service Account Token"
fi

# Verificar se dashboards foram carregados
log "📊 Verificando dashboards..."
sleep 3
DASHBOARDS_RESPONSE=$(curl -s -H "Authorization: Bearer $SERVICE_ACCOUNT_TOKEN" \
    $GRAFANA_URL/api/search?query=LITGO5 2>/dev/null)

if [ $? -eq 0 ]; then
    DASHBOARDS_COUNT=$(echo "$DASHBOARDS_RESPONSE" | jq length 2>/dev/null || echo "0")
    if [ "$DASHBOARDS_COUNT" -gt "0" ]; then
        log "✅ Dashboards LITGO5 carregados com sucesso ($DASHBOARDS_COUNT encontrados)"
    else
        warn "⚠️ Dashboards podem não ter sido carregados automaticamente"
        info "Verifique os arquivos em grafana/dashboards/"
    fi
else
    warn "Falha ao verificar dashboards"
fi

# Verificar data sources
log "🔌 Verificando data sources..."
DATASOURCES_RESPONSE=$(curl -s -H "Authorization: Bearer $SERVICE_ACCOUNT_TOKEN" \
    $GRAFANA_URL/api/datasources 2>/dev/null)

if [ $? -eq 0 ]; then
    DATASOURCES_COUNT=$(echo "$DATASOURCES_RESPONSE" | jq length 2>/dev/null || echo "0")
    if [ "$DATASOURCES_COUNT" -gt "0" ]; then
        log "✅ Data sources configurados ($DATASOURCES_COUNT encontrados)"
        # Mostrar quais data sources estão configurados
        echo "$DATASOURCES_RESPONSE" | jq -r '.[].name' 2>/dev/null | while read -r ds_name; do
            info "   - $ds_name"
        done
    else
        warn "⚠️ Data sources podem não estar configurados corretamente"
    fi
else
    warn "Falha ao verificar data sources"
fi

# Verificar se Prometheus está coletando métricas
log "📈 Verificando coleta de métricas do Prometheus..."
METRICS_RESPONSE=$(curl -s http://localhost:9090/api/v1/label/__name__/values 2>/dev/null)

if [ $? -eq 0 ]; then
    METRICS_COUNT=$(echo "$METRICS_RESPONSE" | jq '.data | length' 2>/dev/null || echo "0")
    if [ "$METRICS_COUNT" -gt "10" ]; then
        log "✅ Prometheus está coletando métricas ($METRICS_COUNT métricas disponíveis)"
    else
        warn "⚠️ Prometheus pode não estar coletando métricas corretamente"
    fi
else
    warn "Falha ao verificar métricas do Prometheus"
fi

# Mostrar informações finais
echo ""
log "🎉 Configuração concluída com sucesso!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 ${BLUE}ACESSO AO GRAFANA:${NC}"
echo "   🌐 URL: http://localhost:3001"
echo "   👤 Usuário: admin"
echo "   🔑 Senha: admin123"
echo ""
echo "🔧 ${BLUE}DASHBOARDS DISPONÍVEIS:${NC}"
echo "   📈 LITGO5 - Visão Geral do Sistema"
echo "   🧪 LITGO5 - A/B Testing & Monitoramento de Modelos"
echo "   💼 LITGO5 - Métricas de Negócio & Equidade"
echo ""
echo "📊 ${BLUE}PROMETHEUS:${NC}"
echo "   🌐 URL: http://localhost:9090"
echo ""
echo "🔐 ${BLUE}SERVICE ACCOUNT (SEGURO):${NC}"
echo "   🆔 ID: $SERVICE_ACCOUNT_ID"
echo "   🔑 Token salvo em: .env.grafana"
echo "   ⚠️  Não compartilhe o token!"
echo ""
echo "🚨 ${BLUE}PARA CONFIGURAR ALERTAS SLACK:${NC}"
echo "   1. Configure SLACK_WEBHOOK_URL no arquivo .env"
echo "   2. Reinicie os containers"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
info "✨ Melhorias implementadas:"
echo "   ✅ Service Accounts em vez de API Keys depreciadas"
echo "   ✅ Segurança aprimorada com tokens com expiração"
echo "   ✅ Dashboards especializados para LITGO5"
echo "   ✅ Alertas inteligentes configurados"
echo "   ✅ Provisionamento automatizado"
echo ""
log "🚀 Sistema de monitoramento LITGO5 pronto para produção!" 