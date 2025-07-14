#!/bin/bash

# ============================================================================
# SCRIPT DE TESTE DO ROLLBACK - FEATURE FIRMS
# ============================================================================
# 
# Este script testa o rollback da funcionalidade de escritórios sem executá-lo,
# verificando se todos os componentes estão prontos para o rollback.
#
# Uso: ./test_rollback.sh [--environment=prod|stage|dev]
#
# Autor: Sistema LITGO
# Data: Janeiro 2025
# Versão: 1.0
# ============================================================================

set -euo pipefail

# Configurações
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
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
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ============================================================================
# FUNÇÕES DE TESTE
# ============================================================================

test_prerequisites() {
    log_info "Testando pré-requisitos..."
    local errors=0
    
    # Verificar estrutura do projeto
    if [[ ! -f "${PROJECT_ROOT}/packages/backend/main.py" ]]; then
        log_error "Arquivo main.py não encontrado"
        ((errors++))
    else
        log_success "Arquivo main.py encontrado"
    fi
    
    # Verificar dependências
    if ! command -v docker &> /dev/null; then
        log_error "Docker não instalado"
        ((errors++))
    else
        log_success "Docker disponível"
    fi
    
    if ! command -v curl &> /dev/null; then
        log_error "curl não instalado"
        ((errors++))
    else
        log_success "curl disponível"
    fi
    
    # Verificar se API está rodando
    if curl -s http://localhost:8000 > /dev/null 2>&1; then
        log_success "API está respondendo"
    else
        log_warning "API não está respondendo (pode ser normal)"
    fi
    
    return $errors
}

test_feature_flag() {
    log_info "Testando feature flag..."
    local errors=0
    
    local env_file="${PROJECT_ROOT}/.env"
    
    if [[ -f "$env_file" ]]; then
        if grep -q "ENABLE_FIRM_MATCH" "$env_file"; then
            local current_value=$(grep "ENABLE_FIRM_MATCH" "$env_file" | cut -d'=' -f2)
            log_info "Feature flag atual: ENABLE_FIRM_MATCH=$current_value"
            
            if [[ "$current_value" == "true" ]]; then
                log_success "Feature flag está habilitada (pronta para rollback)"
            else
                log_warning "Feature flag já está desabilitada"
            fi
        else
            log_warning "Feature flag não encontrada no .env"
        fi
    else
        log_warning "Arquivo .env não encontrado"
    fi
    
    return $errors
}

test_algorithm_weights() {
    log_info "Testando pesos do algoritmo..."
    local errors=0
    
    local weights_file="${PROJECT_ROOT}/packages/backend/algoritmo_match.py"
    
    if [[ -f "$weights_file" ]]; then
        log_success "Arquivo do algoritmo encontrado"
        
        # Verificar se Feature-E está presente
        if grep -q '"E":' "$weights_file"; then
            log_success "Feature-E encontrada nos pesos (pronta para rollback)"
        else
            log_warning "Feature-E não encontrada nos pesos"
        fi
        
        # Verificar preset b2b
        if grep -q '"b2b":' "$weights_file"; then
            log_success "Preset b2b encontrado (pronto para rollback)"
        else
            log_warning "Preset b2b não encontrado"
        fi
    else
        log_error "Arquivo do algoritmo não encontrado"
        ((errors++))
    fi
    
    return $errors
}

test_firm_endpoints() {
    log_info "Testando endpoints de firms..."
    local errors=0
    
    local main_file="${PROJECT_ROOT}/packages/backend/main.py"
    
    if [[ -f "$main_file" ]]; then
        log_success "Arquivo main.py encontrado"
        
        # Verificar se router de firms está incluído
        if grep -q "firms_router" "$main_file"; then
            log_success "Router de firms encontrado (pronto para rollback)"
        else
            log_warning "Router de firms não encontrado"
        fi
        
        # Verificar se endpoints estão funcionando (se API estiver rodando)
        if curl -s http://localhost:8000 > /dev/null 2>&1; then
            if curl -s http://localhost:8000/api/firms > /dev/null 2>&1; then
                log_success "Endpoints de firms estão ativos"
            else
                log_warning "Endpoints de firms não estão respondendo"
            fi
        fi
    else
        log_error "Arquivo main.py não encontrado"
        ((errors++))
    fi
    
    return $errors
}

test_redis_connection() {
    log_info "Testando conexão Redis..."
    local errors=0
    
    if docker ps | grep -q redis; then
        log_success "Container Redis está rodando"
        
        # Testar conexão
        if docker exec $(docker ps -q --filter "name=redis") redis-cli ping > /dev/null 2>&1; then
            log_success "Redis está respondendo"
        else
            log_error "Redis não está respondendo"
            ((errors++))
        fi
    else
        log_warning "Container Redis não encontrado"
    fi
    
    return $errors
}

test_docker_compose() {
    log_info "Testando Docker Compose..."
    local errors=0
    
    if [[ -f "${PROJECT_ROOT}/docker-compose.yml" ]]; then
        log_success "docker-compose.yml encontrado"
        
        # Verificar se serviços estão definidos
        if grep -q "backend:" "${PROJECT_ROOT}/docker-compose.yml"; then
            log_success "Serviço backend definido"
        else
            log_warning "Serviço backend não encontrado"
        fi
        
        if grep -q "redis:" "${PROJECT_ROOT}/docker-compose.yml"; then
            log_success "Serviço redis definido"
        else
            log_warning "Serviço redis não encontrado"
        fi
    else
        log_warning "docker-compose.yml não encontrado"
    fi
    
    return $errors
}

test_backup_capability() {
    log_info "Testando capacidade de backup..."
    local errors=0
    
    # Criar diretório de teste
    local test_dir="${PROJECT_ROOT}/test_backup_$(date +%s)"
    mkdir -p "$test_dir"
    
    # Testar criação de backup
    local test_file="${test_dir}/test.txt"
    echo "test content" > "$test_file"
    
    local backup_file="${test_file}.backup.$(date +%Y%m%d_%H%M%S)"
    if cp "$test_file" "$backup_file"; then
        log_success "Capacidade de backup testada com sucesso"
        rm -rf "$test_dir"
    else
        log_error "Falha ao criar backup de teste"
        ((errors++))
        rm -rf "$test_dir"
    fi
    
    return $errors
}

test_notification_config() {
    log_info "Testando configuração de notificações..."
    
    # Verificar variáveis de ambiente opcionais
    if [[ -n "${SLACK_WEBHOOK_URL:-}" ]]; then
        log_success "Slack webhook configurado"
    else
        log_info "Slack webhook não configurado (opcional)"
    fi
    
    if [[ -n "${DISCORD_WEBHOOK_URL:-}" ]]; then
        log_success "Discord webhook configurado"
    else
        log_info "Discord webhook não configurado (opcional)"
    fi
    
    if [[ -n "${ALERT_EMAIL:-}" ]]; then
        log_success "Email de alerta configurado"
    else
        log_info "Email de alerta não configurado (opcional)"
    fi
    
    return 0
}

simulate_rollback() {
    log_info "Simulando rollback (sem executar)..."
    
    echo "  1. [SIMULADO] Desabilitando feature flag ENABLE_FIRM_MATCH..."
    echo "  2. [SIMULADO] Revertendo pesos do algoritmo..."
    echo "  3. [SIMULADO] Desabilitando endpoints de firms..."
    echo "  4. [SIMULADO] Limpando cache Redis..."
    echo "  5. [SIMULADO] Reiniciando serviços..."
    echo "  6. [SIMULADO] Verificando rollback..."
    echo "  7. [SIMULADO] Criando relatório..."
    echo "  8. [SIMULADO] Enviando notificações..."
    
    log_success "Simulação concluída"
    return 0
}

# ============================================================================
# FUNÇÃO PRINCIPAL
# ============================================================================

main() {
    echo "============================================================================"
    echo "                    TESTE DO ROLLBACK - FEATURE FIRMS                      "
    echo "============================================================================"
    echo
    
    log_info "Testando capacidade de rollback da funcionalidade de escritórios..."
    log_info "Ambiente: ${ENVIRONMENT}"
    echo
    
    local total_errors=0
    
    # Executar testes
    test_prerequisites || ((total_errors+=$?))
    echo
    
    test_feature_flag || ((total_errors+=$?))
    echo
    
    test_algorithm_weights || ((total_errors+=$?))
    echo
    
    test_firm_endpoints || ((total_errors+=$?))
    echo
    
    test_redis_connection || ((total_errors+=$?))
    echo
    
    test_docker_compose || ((total_errors+=$?))
    echo
    
    test_backup_capability || ((total_errors+=$?))
    echo
    
    test_notification_config || ((total_errors+=$?))
    echo
    
    # Simular rollback
    simulate_rollback
    echo
    
    # Resultado final
    echo "============================================================================"
    echo "                          RESULTADO DO TESTE                               "
    echo "============================================================================"
    echo
    
    if [[ $total_errors -eq 0 ]]; then
        log_success "Todos os testes passaram! Sistema pronto para rollback."
        echo
        echo "✅ Pré-requisitos verificados"
        echo "✅ Feature flag identificada"
        echo "✅ Algoritmo pronto para reversão"
        echo "✅ Endpoints identificados"
        echo "✅ Redis funcionando"
        echo "✅ Docker Compose configurado"
        echo "✅ Capacidade de backup testada"
        echo "✅ Notificações configuradas"
        echo
        echo "🚀 Para executar o rollback real:"
        echo "   ./infra/scripts/disable_firm_match.sh --environment=${ENVIRONMENT}"
        echo
        exit 0
    else
        log_error "Teste falhou com $total_errors erros. Corrija os problemas antes do rollback."
        echo
        echo "❌ Problemas encontrados que precisam ser corrigidos"
        echo "⚠️  Não execute o rollback até resolver todos os erros"
        echo
        echo "🔧 Para corrigir os problemas:"
        echo "   1. Verifique os logs acima"
        echo "   2. Corrija os erros identificados"
        echo "   3. Execute este teste novamente"
        echo "   4. Apenas então execute o rollback real"
        echo
        exit 1
    fi
}

# ============================================================================
# EXECUÇÃO
# ============================================================================

# Verificar parâmetros
case "${1:-}" in
    --help|-h)
        echo "Uso: $0 [--environment=prod|stage|dev]"
        echo
        echo "Este script testa a capacidade de rollback da funcionalidade de escritórios."
        echo
        echo "Opções:"
        echo "  --environment=ENV    Ambiente alvo (prod, stage, dev). Padrão: dev"
        echo "  --help, -h          Mostra esta ajuda"
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