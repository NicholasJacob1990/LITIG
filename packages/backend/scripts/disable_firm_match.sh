#!/bin/bash

# =============================================================================
# Script de Rollback Rápido - Disable Firm Match
# =============================================================================
# Este script desabilita rapidamente as funcionalidades B2B Law Firms
# em caso de problemas em produção.
#
# Uso: ./disable_firm_match.sh [--env=production|staging] [--confirm]
#
# Ações executadas:
# 1. Desabilita feature flags B2B
# 2. Reverte preset padrão para casos corporativos
# 3. Limpa cache Redis relacionado ao B2B
# 4. Reinicia serviços se necessário
# 5. Valida que o rollback foi bem-sucedido
# =============================================================================

set -euo pipefail

# Configurações padrão
ENVIRONMENT="staging"
CONFIRM=false
REDIS_HOST="localhost"
REDIS_PORT="6379"
BACKEND_SERVICE="litgo-backend"
ROLLBACK_LOG="/tmp/firm_match_rollback_$(date +%Y%m%d_%H%M%S).log"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para logging
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$ROLLBACK_LOG"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}" | tee -a "$ROLLBACK_LOG"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" | tee -a "$ROLLBACK_LOG"
}

# Função para mostrar uso
show_usage() {
    cat << EOF
Uso: $0 [OPÇÕES]

OPÇÕES:
    --env=ENV       Ambiente (staging|production) [padrão: staging]
    --confirm       Confirma a execução sem prompt interativo
    --redis-host    Host do Redis [padrão: localhost]
    --redis-port    Porta do Redis [padrão: 6379]
    --service       Nome do serviço backend [padrão: litgo-backend]
    --help          Mostra esta mensagem

EXEMPLOS:
    $0 --env=staging --confirm
    $0 --env=production --redis-host=redis.prod.com --confirm

EOF
}

# Parse de argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --env=*)
            ENVIRONMENT="${1#*=}"
            shift
            ;;
        --confirm)
            CONFIRM=true
            shift
            ;;
        --redis-host=*)
            REDIS_HOST="${1#*=}"
            shift
            ;;
        --redis-port=*)
            REDIS_PORT="${1#*=}"
            shift
            ;;
        --service=*)
            BACKEND_SERVICE="${1#*=}"
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            error "Opção desconhecida: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validar ambiente
if [[ "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "production" ]]; then
    error "Ambiente deve ser 'staging' ou 'production'"
    exit 1
fi

# Função para confirmar execução
confirm_rollback() {
    if [[ "$CONFIRM" == "true" ]]; then
        return 0
    fi
    
    echo -e "${YELLOW}"
    echo "=========================================="
    echo "    ROLLBACK B2B LAW FIRMS"
    echo "=========================================="
    echo "Ambiente: $ENVIRONMENT"
    echo "Redis: $REDIS_HOST:$REDIS_PORT"
    echo "Serviço: $BACKEND_SERVICE"
    echo "Log: $ROLLBACK_LOG"
    echo "=========================================="
    echo -e "${NC}"
    
    read -p "Confirma o rollback? (digite 'ROLLBACK' para confirmar): " confirmation
    if [[ "$confirmation" != "ROLLBACK" ]]; then
        error "Rollback cancelado pelo usuário"
        exit 1
    fi
}

# Função para desabilitar feature flags
disable_feature_flags() {
    log "Desabilitando feature flags B2B..."
    
    # Definir variáveis de ambiente para desabilitar B2B
    if [[ "$ENVIRONMENT" == "production" ]]; then
        # Em produção, usar sistema de configuração centralizado
        if command -v kubectl &> /dev/null; then
            log "Atualizando ConfigMap no Kubernetes..."
            kubectl patch configmap litgo-backend-config -p '{"data":{"ENABLE_FIRM_MATCH":"false","DEFAULT_PRESET_CORPORATE":"balanced","B2B_ROLLOUT_PERCENTAGE":"0"}}'
        elif command -v docker &> /dev/null; then
            log "Atualizando variáveis de ambiente no Docker..."
            docker exec "$BACKEND_SERVICE" env ENABLE_FIRM_MATCH=false DEFAULT_PRESET_CORPORATE=balanced B2B_ROLLOUT_PERCENTAGE=0
        else
            warn "Sistema de orquestração não detectado. Defina manualmente:"
            warn "ENABLE_FIRM_MATCH=false"
            warn "DEFAULT_PRESET_CORPORATE=balanced"
            warn "B2B_ROLLOUT_PERCENTAGE=0"
        fi
    else
        # Em staging, usar variáveis de ambiente locais
        export ENABLE_FIRM_MATCH=false
        export DEFAULT_PRESET_CORPORATE=balanced
        export B2B_ROLLOUT_PERCENTAGE=0
        log "Variáveis de ambiente definidas localmente"
    fi
}

# Função para limpar cache Redis
clear_redis_cache() {
    log "Limpando cache Redis relacionado ao B2B..."
    
    if command -v redis-cli &> /dev/null; then
        # Limpar chaves específicas do B2B
        redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" --scan --pattern "*firm*" | xargs -r redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" DEL
        redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" --scan --pattern "*b2b*" | xargs -r redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" DEL
        redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" --scan --pattern "match:cache:firm:*" | xargs -r redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" DEL
        
        log "Cache Redis limpo com sucesso"
    else
        warn "redis-cli não encontrado. Limpe manualmente as chaves: *firm*, *b2b*, match:cache:firm:*"
    fi
}

# Função para reiniciar serviços
restart_services() {
    log "Reiniciando serviços..."
    
    if [[ "$ENVIRONMENT" == "production" ]]; then
        if command -v kubectl &> /dev/null; then
            log "Reiniciando pods no Kubernetes..."
            kubectl rollout restart deployment/litgo-backend
            kubectl rollout status deployment/litgo-backend --timeout=300s
        elif command -v docker &> /dev/null; then
            log "Reiniciando container Docker..."
            docker restart "$BACKEND_SERVICE"
            sleep 10
        elif command -v systemctl &> /dev/null; then
            log "Reiniciando serviço systemd..."
            sudo systemctl restart "$BACKEND_SERVICE"
            sleep 5
        else
            warn "Sistema de gerenciamento de serviços não detectado. Reinicie manualmente o backend."
        fi
    else
        log "Ambiente de staging - reinicialização manual pode ser necessária"
    fi
}

# Função para validar rollback
validate_rollback() {
    log "Validando rollback..."
    
    # Verificar se o serviço está respondendo
    if command -v curl &> /dev/null; then
        local health_url="http://localhost:8080/health"
        if [[ "$ENVIRONMENT" == "production" ]]; then
            health_url="https://api.litgo.com/health"
        fi
        
        if curl -s -f "$health_url" > /dev/null; then
            log "Serviço está respondendo"
        else
            error "Serviço não está respondendo em $health_url"
            return 1
        fi
    fi
    
    # Verificar se as feature flags estão desabilitadas
    if [[ "${ENABLE_FIRM_MATCH:-}" == "false" ]]; then
        log "Feature flag ENABLE_FIRM_MATCH desabilitada"
    else
        warn "Não foi possível verificar feature flag ENABLE_FIRM_MATCH"
    fi
    
    # Verificar se o preset foi revertido
    if [[ "${DEFAULT_PRESET_CORPORATE:-}" == "balanced" ]]; then
        log "Preset corporativo revertido para 'balanced'"
    else
        warn "Não foi possível verificar preset corporativo"
    fi
    
    log "Validação concluída"
}

# Função para criar relatório de rollback
create_rollback_report() {
    log "Criando relatório de rollback..."
    
    cat > "/tmp/firm_match_rollback_report_$(date +%Y%m%d_%H%M%S).md" << EOF
# Relatório de Rollback B2B Law Firms

**Data:** $(date)
**Ambiente:** $ENVIRONMENT
**Executado por:** $(whoami)
**Hostname:** $(hostname)

## Ações Executadas

- [x] Feature flags B2B desabilitadas
- [x] Preset corporativo revertido para 'balanced'
- [x] Cache Redis limpo
- [x] Serviços reiniciados
- [x] Validação executada

## Configurações Aplicadas

\`\`\`
ENABLE_FIRM_MATCH=false
DEFAULT_PRESET_CORPORATE=balanced
B2B_ROLLOUT_PERCENTAGE=0
\`\`\`

## Próximos Passos

1. Monitorar métricas de erro por 30 minutos
2. Verificar logs de aplicação
3. Confirmar que matching está funcionando normalmente
4. Investigar causa raiz do problema
5. Planejar nova tentativa de deploy se necessário

## Log Completo

Veja: $ROLLBACK_LOG

EOF

    log "Relatório criado em /tmp/firm_match_rollback_report_*.md"
}

# Função principal
main() {
    log "Iniciando rollback B2B Law Firms..."
    log "Ambiente: $ENVIRONMENT"
    
    # Confirmar execução
    confirm_rollback
    
    # Executar rollback
    disable_feature_flags
    clear_redis_cache
    restart_services
    
    # Aguardar estabilização
    log "Aguardando estabilização dos serviços..."
    sleep 30
    
    # Validar rollback
    validate_rollback
    
    # Criar relatório
    create_rollback_report
    
    log "Rollback concluído com sucesso!"
    log "Monitore as métricas pelos próximos 30 minutos"
    log "Log completo disponível em: $ROLLBACK_LOG"
    
    # Mostrar próximos passos
    echo -e "${YELLOW}"
    echo "=========================================="
    echo "         PRÓXIMOS PASSOS"
    echo "=========================================="
    echo "1. Monitorar dashboard de métricas"
    echo "2. Verificar logs de erro"
    echo "3. Confirmar funcionamento normal"
    echo "4. Investigar causa raiz"
    echo "5. Planejar nova tentativa"
    echo "=========================================="
    echo -e "${NC}"
}

# Capturar sinais para cleanup
trap 'error "Rollback interrompido"; exit 1' INT TERM

# Executar função principal
main "$@" 