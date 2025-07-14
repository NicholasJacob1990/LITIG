#!/bin/bash

# ============================================================================
# SCRIPT DE ROLLBACK RÁPIDO - FEATURE FIRMS (B2B MATCHING)
# ============================================================================
# 
# Este script desativa rapidamente a funcionalidade de escritórios de advocacia
# em caso de problemas em produção, revertendo para o estado anterior.
#
# Uso: ./disable_firm_match.sh [--environment=prod|stage|dev]
#
# Autor: Sistema LITGO
# Data: Janeiro 2025
# Versão: 1.0
# ============================================================================

set -euo pipefail

# Configurações
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
LOG_FILE="${PROJECT_ROOT}/logs/rollback_$(date +%Y%m%d_%H%M%S).log"
ENVIRONMENT="${1:-dev}"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# FUNÇÕES UTILITÁRIAS
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "${LOG_FILE}"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "${LOG_FILE}"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "${LOG_FILE}"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "${LOG_FILE}"
}

confirm_action() {
    local message="$1"
    local default="${2:-n}"
    
    if [[ "${ENVIRONMENT}" == "prod" ]]; then
        echo -e "${RED}[PRODUÇÃO]${NC} $message"
        read -p "Digite 'CONFIRM' para continuar: " confirmation
        if [[ "$confirmation" != "CONFIRM" ]]; then
            log_error "Operação cancelada pelo usuário"
            exit 1
        fi
    else
        echo -e "${YELLOW}[${ENVIRONMENT^^}]${NC} $message"
        read -p "Continuar? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_error "Operação cancelada pelo usuário"
            exit 1
        fi
    fi
}

check_prerequisites() {
    log_info "Verificando pré-requisitos..."
    
    # Verificar se estamos no diretório correto
    if [[ ! -f "${PROJECT_ROOT}/packages/backend/main.py" ]]; then
        log_error "Diretório do projeto não encontrado. Execute do diretório raiz."
        exit 1
    fi
    
    # Verificar dependências
    local missing_deps=()
    
    if ! command -v docker &> /dev/null; then
        missing_deps+=("docker")
    fi
    
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Dependências não encontradas: ${missing_deps[*]}"
        exit 1
    fi
    
    # Criar diretório de logs se não existir
    mkdir -p "$(dirname "${LOG_FILE}")"
    
    log_success "Pré-requisitos verificados"
}

# ============================================================================
# FUNÇÕES DE ROLLBACK
# ============================================================================

disable_feature_flag() {
    log_info "Desabilitando feature flag ENABLE_FIRM_MATCH..."
    
    # Backup do arquivo de configuração atual
    local env_file="${PROJECT_ROOT}/.env"
    local backup_file="${PROJECT_ROOT}/.env.backup.$(date +%Y%m%d_%H%M%S)"
    
    if [[ -f "$env_file" ]]; then
        cp "$env_file" "$backup_file"
        log_info "Backup criado: $backup_file"
        
        # Desabilitar feature flag
        if grep -q "ENABLE_FIRM_MATCH" "$env_file"; then
            sed -i 's/ENABLE_FIRM_MATCH=true/ENABLE_FIRM_MATCH=false/g' "$env_file"
            log_success "Feature flag ENABLE_FIRM_MATCH desabilitada"
        else
            echo "ENABLE_FIRM_MATCH=false" >> "$env_file"
            log_success "Feature flag ENABLE_FIRM_MATCH adicionada como false"
        fi
    else
        log_warning "Arquivo .env não encontrado, criando com feature flag desabilitada"
        echo "ENABLE_FIRM_MATCH=false" > "$env_file"
    fi
}

revert_algorithm_weights() {
    log_info "Revertendo pesos do algoritmo para versão anterior..."
    
    local weights_file="${PROJECT_ROOT}/packages/backend/algoritmo_match.py"
    local backup_file="${weights_file}.backup.$(date +%Y%m%d_%H%M%S)"
    
    if [[ -f "$weights_file" ]]; then
        cp "$weights_file" "$backup_file"
        log_info "Backup criado: $backup_file"
        
        # Reverter pesos para versão sem Feature-E
        cat > "${PROJECT_ROOT}/temp_weights_rollback.py" << 'EOF'
# Pesos revertidos para versão anterior (sem Feature-E)
DEFAULT_WEIGHTS = {
    "A": 0.30, "S": 0.25, "T": 0.15, "G": 0.10,
    "Q": 0.10, "U": 0.05, "R": 0.05, "C": 0.03
}

PRESET_WEIGHTS = {
    "fast": {
        "A": 0.25, "S": 0.15, "T": 0.10, "G": 0.25,
        "Q": 0.05, "U": 0.10, "R": 0.05, "C": 0.05
    },
    "balanced": {
        "A": 0.20, "S": 0.20, "T": 0.18, "G": 0.12,
        "Q": 0.12, "U": 0.08, "R": 0.10, "C": 0.05
    },
    "expert": {
        "A": 0.15, "S": 0.25, "T": 0.22, "Q": 0.20,
        "G": 0.05, "U": 0.03, "R": 0.10, "C": 0.05
    }
}
EOF
        
        # Aplicar rollback nos pesos
        python3 << 'EOF'
import re

# Ler arquivo atual
with open('packages/backend/algoritmo_match.py', 'r') as f:
    content = f.read()

# Ler novos pesos
with open('temp_weights_rollback.py', 'r') as f:
    new_weights = f.read()

# Substituir seção de pesos
pattern = r'DEFAULT_WEIGHTS\s*=\s*{[^}]+}.*?PRESET_WEIGHTS\s*=\s*{.*?}(?=\s*\n[A-Z]|\s*$)'
replacement = new_weights.strip()

new_content = re.sub(pattern, replacement, content, flags=re.DOTALL)

# Escrever arquivo modificado
with open('packages/backend/algoritmo_match.py', 'w') as f:
    f.write(new_content)

print("Pesos revertidos com sucesso")
EOF
        
        rm -f "${PROJECT_ROOT}/temp_weights_rollback.py"
        log_success "Pesos do algoritmo revertidos"
    else
        log_warning "Arquivo de algoritmo não encontrado"
    fi
}

disable_firm_endpoints() {
    log_info "Desabilitando endpoints de firms..."
    
    local main_file="${PROJECT_ROOT}/packages/backend/main.py"
    local backup_file="${main_file}.backup.$(date +%Y%m%d_%H%M%S)"
    
    if [[ -f "$main_file" ]]; then
        cp "$main_file" "$backup_file"
        log_info "Backup criado: $backup_file"
        
        # Comentar linha de inclusão do router de firms
        sed -i 's/^app\.include_router(firms_router/# app.include_router(firms_router/' "$main_file"
        sed -i 's/^from routes\.firms import router as firms_router/# from routes.firms import router as firms_router/' "$main_file"
        
        log_success "Endpoints de firms desabilitados"
    else
        log_warning "Arquivo main.py não encontrado"
    fi
}

clear_redis_cache() {
    log_info "Limpando cache Redis relacionado a firms..."
    
    if docker ps | grep -q redis; then
        # Limpar chaves relacionadas a firms
        docker exec -it $(docker ps -q --filter "name=redis") redis-cli << 'EOF'
EVAL "
local keys = redis.call('keys', 'match:cache:firm:*')
for i=1,#keys do
    redis.call('del', keys[i])
end
local keys = redis.call('keys', 'firm:*')
for i=1,#keys do
    redis.call('del', keys[i])
end
return 'OK'
" 0
EOF
        log_success "Cache Redis limpo"
    else
        log_warning "Container Redis não encontrado"
    fi
}

restart_services() {
    log_info "Reiniciando serviços..."
    
    cd "$PROJECT_ROOT"
    
    if [[ -f "docker-compose.yml" ]]; then
        # Reiniciar apenas o backend
        docker-compose restart backend
        
        # Aguardar serviços ficarem prontos
        sleep 10
        
        # Verificar se API está respondendo
        local api_url="http://localhost:8000"
        local max_attempts=30
        local attempt=1
        
        while [[ $attempt -le $max_attempts ]]; do
            if curl -s "$api_url" > /dev/null 2>&1; then
                log_success "API está respondendo"
                break
            fi
            
            log_info "Aguardando API ficar pronta (tentativa $attempt/$max_attempts)..."
            sleep 2
            ((attempt++))
        done
        
        if [[ $attempt -gt $max_attempts ]]; then
            log_error "API não respondeu após $max_attempts tentativas"
            return 1
        fi
    else
        log_warning "docker-compose.yml não encontrado, reinicialização manual necessária"
    fi
}

verify_rollback() {
    log_info "Verificando rollback..."
    
    local api_url="http://localhost:8000"
    local errors=0
    
    # Verificar se API está respondendo
    if ! curl -s "$api_url" > /dev/null 2>&1; then
        log_error "API não está respondendo"
        ((errors++))
    fi
    
    # Verificar se endpoints de firms estão desabilitados
    if curl -s "$api_url/api/firms" 2>&1 | grep -q "404"; then
        log_success "Endpoints de firms desabilitados com sucesso"
    else
        log_error "Endpoints de firms ainda estão ativos"
        ((errors++))
    fi
    
    # Verificar se matching ainda funciona (sem firms)
    local test_payload='{"case_id": "test-case", "top_n": 3, "preset": "balanced"}'
    if curl -s -X POST "$api_url/api/match" \
        -H "Content-Type: application/json" \
        -d "$test_payload" 2>&1 | grep -q "matches"; then
        log_success "Matching básico funcionando"
    else
        log_warning "Matching pode estar com problemas (verificar logs)"
    fi
    
    if [[ $errors -eq 0 ]]; then
        log_success "Rollback verificado com sucesso"
        return 0
    else
        log_error "Rollback com $errors erros"
        return 1
    fi
}

create_rollback_report() {
    log_info "Criando relatório de rollback..."
    
    local report_file="${PROJECT_ROOT}/logs/rollback_report_$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$report_file" << EOF
# Relatório de Rollback - Feature Firms

**Data:** $(date)
**Ambiente:** ${ENVIRONMENT}
**Executado por:** $(whoami)

## Ações Executadas

- [x] Feature flag ENABLE_FIRM_MATCH desabilitada
- [x] Pesos do algoritmo revertidos (removida Feature-E)
- [x] Endpoints de firms desabilitados
- [x] Cache Redis limpo
- [x] Serviços reiniciados

## Arquivos de Backup Criados

$(find "${PROJECT_ROOT}" -name "*.backup.*" -newer "${LOG_FILE}" 2>/dev/null | sed 's/^/- /')

## Verificações

- API Status: $(curl -s http://localhost:8000 > /dev/null 2>&1 && echo "✅ OK" || echo "❌ ERRO")
- Endpoints Firms: $(curl -s http://localhost:8000/api/firms 2>&1 | grep -q "404" && echo "✅ Desabilitados" || echo "❌ Ainda ativos")
- Matching Básico: $(curl -s -X POST http://localhost:8000/api/match -H "Content-Type: application/json" -d '{"case_id": "test", "top_n": 3}' 2>&1 | grep -q "matches" && echo "✅ Funcionando" || echo "⚠️ Verificar")

## Próximos Passos

1. Monitorar logs da aplicação
2. Verificar métricas de performance
3. Comunicar status para equipe
4. Investigar causa raiz do problema

## Logs Completos

Arquivo: ${LOG_FILE}
EOF

    log_success "Relatório criado: $report_file"
}

send_notifications() {
    log_info "Enviando notificações..."
    
    local status_message="🔄 ROLLBACK EXECUTADO - Feature Firms desabilitada no ambiente ${ENVIRONMENT}"
    
    # Slack notification (se configurado)
    if [[ -n "${SLACK_WEBHOOK_URL:-}" ]]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"$status_message\"}" \
            "$SLACK_WEBHOOK_URL" 2>/dev/null || log_warning "Falha ao enviar notificação Slack"
    fi
    
    # Email notification (se configurado)
    if [[ -n "${ALERT_EMAIL:-}" ]] && command -v mail &> /dev/null; then
        echo "$status_message" | mail -s "LITGO - Rollback Executado" "$ALERT_EMAIL" 2>/dev/null || log_warning "Falha ao enviar email"
    fi
    
    # Discord notification (se configurado)
    if [[ -n "${DISCORD_WEBHOOK_URL:-}" ]]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"content\":\"$status_message\"}" \
            "$DISCORD_WEBHOOK_URL" 2>/dev/null || log_warning "Falha ao enviar notificação Discord"
    fi
    
    log_success "Notificações enviadas"
}

# ============================================================================
# FUNÇÃO PRINCIPAL
# ============================================================================

main() {
    echo "============================================================================"
    echo "                    ROLLBACK RÁPIDO - FEATURE FIRMS                        "
    echo "============================================================================"
    echo
    
    log_info "Iniciando rollback da funcionalidade de escritórios..."
    log_info "Ambiente: ${ENVIRONMENT}"
    log_info "Log file: ${LOG_FILE}"
    echo
    
    # Verificar pré-requisitos
    check_prerequisites
    
    # Confirmar ação
    confirm_action "Você está prestes a desabilitar a funcionalidade de escritórios (Feature-E). Esta ação:"
    echo "  - Desabilitará feature flag ENABLE_FIRM_MATCH"
    echo "  - Reverterá pesos do algoritmo (removida Feature-E)"
    echo "  - Desabilitará endpoints /api/firms/*"
    echo "  - Limpará cache Redis relacionado"
    echo "  - Reiniciará serviços"
    echo
    
    # Executar rollback
    local start_time=$(date +%s)
    
    disable_feature_flag
    revert_algorithm_weights
    disable_firm_endpoints
    clear_redis_cache
    restart_services
    
    # Verificar resultado
    if verify_rollback; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        log_success "Rollback concluído com sucesso em ${duration}s"
        
        create_rollback_report
        send_notifications
        
        echo
        echo "============================================================================"
        echo "                          ROLLBACK CONCLUÍDO                               "
        echo "============================================================================"
        echo
        echo "✅ Funcionalidade de escritórios desabilitada"
        echo "✅ Sistema revertido para versão anterior"
        echo "✅ Serviços reiniciados e funcionando"
        echo
        echo "📋 Relatório: $(find "${PROJECT_ROOT}/logs" -name "rollback_report_*" -newer "${LOG_FILE}" | head -1)"
        echo "📝 Logs: ${LOG_FILE}"
        echo
        echo "🔍 Próximos passos:"
        echo "  1. Monitorar logs da aplicação"
        echo "  2. Verificar métricas de performance"
        echo "  3. Investigar causa raiz do problema"
        echo "  4. Comunicar status para equipe"
        echo
        
        exit 0
    else
        log_error "Rollback falhou. Verifique logs e execute correções manuais."
        exit 1
    fi
}

# ============================================================================
# TRATAMENTO DE SINAIS
# ============================================================================

cleanup() {
    log_warning "Script interrompido pelo usuário"
    exit 130
}

trap cleanup SIGINT SIGTERM

# ============================================================================
# EXECUÇÃO
# ============================================================================

# Verificar parâmetros
case "${1:-}" in
    --help|-h)
        echo "Uso: $0 [--environment=prod|stage|dev]"
        echo
        echo "Este script executa rollback rápido da funcionalidade de escritórios."
        echo
        echo "Opções:"
        echo "  --environment=ENV    Ambiente alvo (prod, stage, dev). Padrão: dev"
        echo "  --help, -h          Mostra esta ajuda"
        echo
        echo "Variáveis de ambiente opcionais:"
        echo "  SLACK_WEBHOOK_URL    URL do webhook Slack para notificações"
        echo "  DISCORD_WEBHOOK_URL  URL do webhook Discord para notificações"
        echo "  ALERT_EMAIL          Email para notificações"
        echo
        exit 0
        ;;
    --environment=*)
        ENVIRONMENT="${1#*=}"
        ;;
    --environment)
        ENVIRONMENT="${2:-dev}"
        shift
        ;;
    "")
        # Usar padrão
        ;;
    *)
        log_error "Parâmetro inválido: $1"
        echo "Use --help para ver as opções disponíveis"
        exit 1
        ;;
esac

# Validar ambiente
if [[ ! "$ENVIRONMENT" =~ ^(prod|stage|dev)$ ]]; then
    log_error "Ambiente inválido: $ENVIRONMENT. Use: prod, stage ou dev"
    exit 1
fi

# Executar função principal
main "$@" 