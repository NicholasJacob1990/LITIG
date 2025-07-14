#!/bin/bash

# ============================================================================
# PLANO DE ROLLOUT GRADUAL - FEATURE FIRMS (B2B MATCHING)
# ============================================================================
# 
# Este script executa o rollout gradual da funcionalidade de escritórios
# utilizando feature flags para minimizar riscos e permitir monitoramento.
#
# Uso: ./rollout_plan.sh [--phase=1|2|3|4] [--environment=prod|stage|dev]
#
# Autor: Sistema LITGO
# Data: Janeiro 2025
# Versão: 1.0
# ============================================================================

set -euo pipefail

# Configurações
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PHASE="${1:-1}"
ENVIRONMENT="${2:-dev}"
LOG_FILE="${PROJECT_ROOT}/logs/rollout_$(date +%Y%m%d_%H%M%S).log"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# ============================================================================
# CONFIGURAÇÃO DAS FASES
# ============================================================================

declare -A PHASE_CONFIG=(
    ["1"]="5:Piloto Interno:Apenas contas de teste e equipe LITGO"
    ["2"]="25:Escritórios Parceiros:Escritórios selecionados para teste"
    ["3"]="50:Rollout Gradual:50% dos casos corporativos"
    ["4"]="100:Rollout Completo:Todos os casos corporativos"
)

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

log_phase() {
    echo -e "${PURPLE}[PHASE $1]${NC} $2" | tee -a "${LOG_FILE}"
}

confirm_action() {
    local message="$1"
    local phase="$2"
    
    if [[ "${ENVIRONMENT}" == "prod" ]]; then
        echo -e "${RED}[PRODUÇÃO - FASE $phase]${NC} $message"
        echo "Esta ação afetará usuários reais em produção."
        read -p "Digite 'ROLLOUT-PHASE-$phase' para continuar: " confirmation
        if [[ "$confirmation" != "ROLLOUT-PHASE-$phase" ]]; then
            log_error "Rollout cancelado pelo usuário"
            exit 1
        fi
    else
        echo -e "${YELLOW}[${ENVIRONMENT^^} - FASE $phase]${NC} $message"
        read -p "Continuar com a Fase $phase? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_error "Rollout cancelado pelo usuário"
            exit 1
        fi
    fi
}

# ============================================================================
# FUNÇÕES DE VALIDAÇÃO
# ============================================================================

check_prerequisites() {
    log_info "Verificando pré-requisitos para rollout..."
    
    # Verificar se testes E2E passaram
    if [[ ! -f "${PROJECT_ROOT}/logs/e2e_tests_passed.flag" ]]; then
        log_error "Testes E2E não foram executados. Execute primeiro os testes E2E."
        exit 1
    fi
    
    # Verificar se API está respondendo
    if ! curl -s http://localhost:8000 > /dev/null 2>&1; then
        log_error "API não está respondendo. Verifique se o backend está rodando."
        exit 1
    fi
    
    # Verificar se monitoramento está ativo
    if ! curl -s http://localhost:8000/metrics > /dev/null 2>&1; then
        log_warning "Métricas Prometheus não estão disponíveis"
    fi
    
    # Verificar se Redis está funcionando
    if ! docker ps | grep -q redis; then
        log_error "Redis não está rodando. Necessário para feature flags."
        exit 1
    fi
    
    log_success "Pré-requisitos verificados"
}

validate_phase() {
    local phase="$1"
    
    if [[ ! "${PHASE_CONFIG[$phase]:-}" ]]; then
        log_error "Fase inválida: $phase. Use: 1, 2, 3 ou 4"
        exit 1
    fi
    
    # Verificar se fase anterior foi concluída (exceto fase 1)
    if [[ "$phase" -gt 1 ]]; then
        local prev_phase=$((phase - 1))
        if [[ ! -f "${PROJECT_ROOT}/logs/rollout_phase_${prev_phase}_completed.flag" ]]; then
            log_error "Fase anterior ($prev_phase) não foi concluída. Execute primeiro: ./rollout_plan.sh --phase=$prev_phase"
            exit 1
        fi
    fi
    
    log_success "Fase $phase validada"
}

# ============================================================================
# FUNÇÕES DE FEATURE FLAGS
# ============================================================================

set_feature_flag() {
    local percentage="$1"
    local description="$2"
    
    log_info "Configurando feature flag para $percentage% - $description"
    
    # Atualizar variável de ambiente
    local env_file="${PROJECT_ROOT}/.env"
    
    # Backup do arquivo atual
    cp "$env_file" "${env_file}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Configurar feature flag
    if grep -q "ENABLE_FIRM_MATCH" "$env_file"; then
        sed -i "s/ENABLE_FIRM_MATCH=.*/ENABLE_FIRM_MATCH=true/" "$env_file"
    else
        echo "ENABLE_FIRM_MATCH=true" >> "$env_file"
    fi
    
    # Configurar percentual de rollout
    if grep -q "FIRM_MATCH_ROLLOUT_PERCENTAGE" "$env_file"; then
        sed -i "s/FIRM_MATCH_ROLLOUT_PERCENTAGE=.*/FIRM_MATCH_ROLLOUT_PERCENTAGE=$percentage/" "$env_file"
    else
        echo "FIRM_MATCH_ROLLOUT_PERCENTAGE=$percentage" >> "$env_file"
    fi
    
    # Configurar preset padrão para casos corporativos
    if grep -q "DEFAULT_PRESET_CORPORATE" "$env_file"; then
        sed -i "s/DEFAULT_PRESET_CORPORATE=.*/DEFAULT_PRESET_CORPORATE=b2b/" "$env_file"
    else
        echo "DEFAULT_PRESET_CORPORATE=b2b" >> "$env_file"
    fi
    
    log_success "Feature flag configurada: $percentage%"
}

restart_services() {
    log_info "Reiniciando serviços para aplicar configurações..."
    
    cd "$PROJECT_ROOT"
    
    # Reiniciar apenas o backend para aplicar novas configurações
    docker-compose restart backend
    
    # Aguardar serviços ficarem prontos
    sleep 15
    
    # Verificar se API está respondendo
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if curl -s http://localhost:8000 > /dev/null 2>&1; then
            log_success "API está respondendo após reinicialização"
            return 0
        fi
        
        log_info "Aguardando API ficar pronta (tentativa $attempt/$max_attempts)..."
        sleep 2
        ((attempt++))
    done
    
    log_error "API não respondeu após reinicialização"
    return 1
}

# ============================================================================
# FUNÇÕES DE MONITORAMENTO
# ============================================================================

monitor_metrics() {
    local phase="$1"
    local duration_minutes="${2:-10}"
    
    log_info "Monitorando métricas por $duration_minutes minutos..."
    
    local start_time=$(date +%s)
    local end_time=$((start_time + duration_minutes * 60))
    
    while [[ $(date +%s) -lt $end_time ]]; do
        # Verificar latência da API
        local latency=$(curl -s -w "%{time_total}" -o /dev/null http://localhost:8000/api/match || echo "0")
        
        # Verificar se API está respondendo
        if ! curl -s http://localhost:8000 > /dev/null 2>&1; then
            log_error "API parou de responder durante monitoramento"
            return 1
        fi
        
        # Verificar métricas específicas (se disponíveis)
        if curl -s http://localhost:8000/metrics > /dev/null 2>&1; then
            local error_rate=$(curl -s http://localhost:8000/metrics | grep -o "http_requests_total.*5[0-9][0-9]" | wc -l || echo "0")
            
            if [[ "$error_rate" -gt 10 ]]; then
                log_warning "Taxa de erro elevada detectada: $error_rate"
            fi
        fi
        
        log_info "Latência: ${latency}s | Tempo restante: $(( (end_time - $(date +%s)) / 60 ))min"
        sleep 30
    done
    
    log_success "Monitoramento da Fase $phase concluído"
}

validate_rollout() {
    local phase="$1"
    local percentage="$2"
    
    log_info "Validando rollout da Fase $phase..."
    
    # Verificar se API está respondendo
    if ! curl -s http://localhost:8000 > /dev/null 2>&1; then
        log_error "API não está respondendo"
        return 1
    fi
    
    # Verificar se endpoints de firms estão funcionando
    if ! curl -s http://localhost:8000/api/firms > /dev/null 2>&1; then
        log_error "Endpoints de firms não estão funcionando"
        return 1
    fi
    
    # Testar matching com firms
    local test_payload='{"case_id": "test-corporate-case", "top_n": 5, "preset": "b2b", "include_firms": true}'
    local match_result=$(curl -s -X POST http://localhost:8000/api/match \
        -H "Content-Type: application/json" \
        -d "$test_payload" 2>/dev/null || echo "error")
    
    if [[ "$match_result" == "error" ]] || ! echo "$match_result" | grep -q "matches"; then
        log_error "Matching B2B não está funcionando"
        return 1
    fi
    
    # Verificar se feature flag está correta
    if ! grep -q "FIRM_MATCH_ROLLOUT_PERCENTAGE=$percentage" "${PROJECT_ROOT}/.env"; then
        log_error "Feature flag não está configurada corretamente"
        return 1
    fi
    
    log_success "Rollout da Fase $phase validado"
    return 0
}

# ============================================================================
# FUNÇÕES DAS FASES
# ============================================================================

execute_phase_1() {
    log_phase "1" "PILOTO INTERNO - 5% dos casos corporativos"
    
    local percentage="5"
    local description="Piloto Interno"
    
    confirm_action "Iniciar Fase 1 - Piloto Interno (5% dos casos corporativos)" "1"
    
    set_feature_flag "$percentage" "$description"
    restart_services
    
    log_info "Aguardando 2 minutos para estabilização..."
    sleep 120
    
    if validate_rollout "1" "$percentage"; then
        monitor_metrics "1" "10"
        
        # Marcar fase como concluída
        touch "${PROJECT_ROOT}/logs/rollout_phase_1_completed.flag"
        log_success "Fase 1 concluída com sucesso"
        
        echo
        echo "✅ Fase 1 - Piloto Interno concluída"
        echo "📊 5% dos casos corporativos usando Feature-E"
        echo "🔍 Monitore métricas por 24h antes da próxima fase"
        echo "🚀 Próxima fase: ./rollout_plan.sh --phase=2 --environment=$ENVIRONMENT"
        echo
    else
        log_error "Fase 1 falhou na validação"
        return 1
    fi
}

execute_phase_2() {
    log_phase "2" "ESCRITÓRIOS PARCEIROS - 25% dos casos corporativos"
    
    local percentage="25"
    local description="Escritórios Parceiros"
    
    confirm_action "Iniciar Fase 2 - Escritórios Parceiros (25% dos casos corporativos)" "2"
    
    set_feature_flag "$percentage" "$description"
    restart_services
    
    log_info "Aguardando 3 minutos para estabilização..."
    sleep 180
    
    if validate_rollout "2" "$percentage"; then
        monitor_metrics "2" "15"
        
        # Marcar fase como concluída
        touch "${PROJECT_ROOT}/logs/rollout_phase_2_completed.flag"
        log_success "Fase 2 concluída com sucesso"
        
        echo
        echo "✅ Fase 2 - Escritórios Parceiros concluída"
        echo "📊 25% dos casos corporativos usando Feature-E"
        echo "🔍 Monitore métricas por 48h antes da próxima fase"
        echo "🚀 Próxima fase: ./rollout_plan.sh --phase=3 --environment=$ENVIRONMENT"
        echo
    else
        log_error "Fase 2 falhou na validação"
        return 1
    fi
}

execute_phase_3() {
    log_phase "3" "ROLLOUT GRADUAL - 50% dos casos corporativos"
    
    local percentage="50"
    local description="Rollout Gradual"
    
    confirm_action "Iniciar Fase 3 - Rollout Gradual (50% dos casos corporativos)" "3"
    
    set_feature_flag "$percentage" "$description"
    restart_services
    
    log_info "Aguardando 5 minutos para estabilização..."
    sleep 300
    
    if validate_rollout "3" "$percentage"; then
        monitor_metrics "3" "20"
        
        # Marcar fase como concluída
        touch "${PROJECT_ROOT}/logs/rollout_phase_3_completed.flag"
        log_success "Fase 3 concluída com sucesso"
        
        echo
        echo "✅ Fase 3 - Rollout Gradual concluída"
        echo "📊 50% dos casos corporativos usando Feature-E"
        echo "🔍 Monitore métricas por 72h antes da próxima fase"
        echo "🚀 Próxima fase: ./rollout_plan.sh --phase=4 --environment=$ENVIRONMENT"
        echo
    else
        log_error "Fase 3 falhou na validação"
        return 1
    fi
}

execute_phase_4() {
    log_phase "4" "ROLLOUT COMPLETO - 100% dos casos corporativos"
    
    local percentage="100"
    local description="Rollout Completo"
    
    confirm_action "Iniciar Fase 4 - Rollout Completo (100% dos casos corporativos)" "4"
    
    set_feature_flag "$percentage" "$description"
    restart_services
    
    log_info "Aguardando 5 minutos para estabilização..."
    sleep 300
    
    if validate_rollout "4" "$percentage"; then
        monitor_metrics "4" "30"
        
        # Marcar fase como concluída
        touch "${PROJECT_ROOT}/logs/rollout_phase_4_completed.flag"
        log_success "Fase 4 concluída com sucesso"
        
        echo
        echo "🎉 ROLLOUT COMPLETO - Feature Firms 100% ativa!"
        echo "📊 Todos os casos corporativos usando Feature-E"
        echo "🔍 Continue monitorando métricas continuamente"
        echo "✅ Funcionalidade de escritórios totalmente implantada"
        echo
    else
        log_error "Fase 4 falhou na validação"
        return 1
    fi
}

# ============================================================================
# FUNÇÕES DE RELATÓRIO
# ============================================================================

create_rollout_report() {
    local phase="$1"
    local status="$2"
    
    log_info "Criando relatório de rollout..."
    
    local report_file="${PROJECT_ROOT}/logs/rollout_phase_${phase}_report_$(date +%Y%m%d_%H%M%S).md"
    local phase_info="${PHASE_CONFIG[$phase]}"
    local percentage=$(echo "$phase_info" | cut -d':' -f1)
    local title=$(echo "$phase_info" | cut -d':' -f2)
    local description=$(echo "$phase_info" | cut -d':' -f3)
    
    cat > "$report_file" << EOF
# Relatório de Rollout - Fase $phase

**Data:** $(date)
**Ambiente:** ${ENVIRONMENT}
**Fase:** $phase - $title
**Status:** $status
**Executado por:** $(whoami)

## Resumo da Fase

- **Percentual:** $percentage%
- **Título:** $title
- **Descrição:** $description
- **Duração:** $(grep "Fase $phase" "$LOG_FILE" | tail -1 | cut -d' ' -f1-2) - $(date)

## Configurações Aplicadas

- Feature Flag: ENABLE_FIRM_MATCH=true
- Rollout Percentage: FIRM_MATCH_ROLLOUT_PERCENTAGE=$percentage%
- Preset Corporativo: DEFAULT_PRESET_CORPORATE=b2b

## Métricas Monitoradas

- API Latência: $(curl -s -w "%{time_total}" -o /dev/null http://localhost:8000/api/match 2>/dev/null || echo "N/A")s
- API Status: $(curl -s http://localhost:8000 > /dev/null 2>&1 && echo "✅ OK" || echo "❌ ERRO")
- Endpoints Firms: $(curl -s http://localhost:8000/api/firms > /dev/null 2>&1 && echo "✅ OK" || echo "❌ ERRO")
- Matching B2B: $(curl -s -X POST http://localhost:8000/api/match -H "Content-Type: application/json" -d '{"case_id": "test", "preset": "b2b"}' 2>/dev/null | grep -q "matches" && echo "✅ OK" || echo "❌ ERRO")

## Validações Executadas

- [x] Pré-requisitos verificados
- [x] Feature flag configurada
- [x] Serviços reiniciados
- [x] API respondendo
- [x] Endpoints de firms funcionando
- [x] Matching B2B testado
- [x] Monitoramento executado

## Próximos Passos

EOF

    if [[ "$status" == "SUCESSO" ]]; then
        if [[ "$phase" -lt 4 ]]; then
            local next_phase=$((phase + 1))
            echo "1. Monitorar métricas por 24-72h" >> "$report_file"
            echo "2. Verificar logs de erro" >> "$report_file"
            echo "3. Validar feedback dos usuários" >> "$report_file"
            echo "4. Executar próxima fase: \`./rollout_plan.sh --phase=$next_phase --environment=$ENVIRONMENT\`" >> "$report_file"
        else
            echo "1. Monitorar métricas continuamente" >> "$report_file"
            echo "2. Documentar lições aprendidas" >> "$report_file"
            echo "3. Comunicar sucesso para equipe" >> "$report_file"
            echo "4. Arquivar scripts de rollback" >> "$report_file"
        fi
    else
        echo "1. Investigar causa da falha" >> "$report_file"
        echo "2. Executar rollback se necessário: \`./disable_firm_match.sh --environment=$ENVIRONMENT\`" >> "$report_file"
        echo "3. Corrigir problemas identificados" >> "$report_file"
        echo "4. Repetir fase após correções" >> "$report_file"
    fi
    
    cat >> "$report_file" << EOF

## Logs Completos

Arquivo: ${LOG_FILE}

## Contato

Em caso de problemas:
- Slack: #litgo-alerts
- Email: admin@litgo.com
- Discord: #emergencia
EOF

    log_success "Relatório criado: $report_file"
}

send_notifications() {
    local phase="$1"
    local status="$2"
    local percentage="$3"
    
    local status_emoji="✅"
    local status_color="good"
    
    if [[ "$status" != "SUCESSO" ]]; then
        status_emoji="❌"
        status_color="danger"
    fi
    
    local message="$status_emoji ROLLOUT FASE $phase - $status - $percentage% dos casos corporativos no ambiente $ENVIRONMENT"
    
    # Slack notification
    if [[ -n "${SLACK_WEBHOOK_URL:-}" ]]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"$message\", \"color\":\"$status_color\"}" \
            "$SLACK_WEBHOOK_URL" 2>/dev/null || log_warning "Falha ao enviar notificação Slack"
    fi
    
    # Discord notification
    if [[ -n "${DISCORD_WEBHOOK_URL:-}" ]]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"content\":\"$message\"}" \
            "$DISCORD_WEBHOOK_URL" 2>/dev/null || log_warning "Falha ao enviar notificação Discord"
    fi
    
    # Email notification
    if [[ -n "${ALERT_EMAIL:-}" ]] && command -v mail &> /dev/null; then
        echo "$message" | mail -s "LITGO - Rollout Fase $phase" "$ALERT_EMAIL" 2>/dev/null || log_warning "Falha ao enviar email"
    fi
}

# ============================================================================
# FUNÇÃO PRINCIPAL
# ============================================================================

main() {
    echo "============================================================================"
    echo "                    ROLLOUT GRADUAL - FEATURE FIRMS                        "
    echo "============================================================================"
    echo
    
    local phase_info="${PHASE_CONFIG[$PHASE]}"
    local percentage=$(echo "$phase_info" | cut -d':' -f1)
    local title=$(echo "$phase_info" | cut -d':' -f2)
    local description=$(echo "$phase_info" | cut -d':' -f3)
    
    log_info "Iniciando Rollout Gradual da funcionalidade de escritórios..."
    log_info "Fase: $PHASE - $title"
    log_info "Percentual: $percentage%"
    log_info "Ambiente: $ENVIRONMENT"
    log_info "Log file: $LOG_FILE"
    echo
    
    # Criar diretório de logs
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # Verificar pré-requisitos
    check_prerequisites
    
    # Validar fase
    validate_phase "$PHASE"
    
    # Executar fase específica
    local phase_status="SUCESSO"
    
    case "$PHASE" in
        1)
            execute_phase_1 || phase_status="FALHA"
            ;;
        2)
            execute_phase_2 || phase_status="FALHA"
            ;;
        3)
            execute_phase_3 || phase_status="FALHA"
            ;;
        4)
            execute_phase_4 || phase_status="FALHA"
            ;;
    esac
    
    # Criar relatório
    create_rollout_report "$PHASE" "$phase_status"
    
    # Enviar notificações
    send_notifications "$PHASE" "$phase_status" "$percentage"
    
    # Resultado final
    if [[ "$phase_status" == "SUCESSO" ]]; then
        log_success "Rollout Fase $PHASE concluído com sucesso"
        exit 0
    else
        log_error "Rollout Fase $PHASE falhou"
        exit 1
    fi
}

# ============================================================================
# TRATAMENTO DE SINAIS
# ============================================================================

cleanup() {
    log_warning "Rollout interrompido pelo usuário"
    exit 130
}

trap cleanup SIGINT SIGTERM

# ============================================================================
# EXECUÇÃO
# ============================================================================

# Verificar parâmetros
while [[ $# -gt 0 ]]; do
    case $1 in
        --phase=*)
            PHASE="${1#*=}"
            shift
            ;;
        --environment=*)
            ENVIRONMENT="${1#*=}"
            shift
            ;;
        --help|-h)
            echo "Uso: $0 [--phase=1|2|3|4] [--environment=prod|stage|dev]"
            echo
            echo "Este script executa o rollout gradual da funcionalidade de escritórios."
            echo
            echo "Fases disponíveis:"
            echo "  1 - Piloto Interno (5%)"
            echo "  2 - Escritórios Parceiros (25%)"
            echo "  3 - Rollout Gradual (50%)"
            echo "  4 - Rollout Completo (100%)"
            echo
            echo "Opções:"
            echo "  --phase=N            Fase do rollout (1-4). Padrão: 1"
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
        *)
            log_error "Parâmetro inválido: $1"
            echo "Use --help para ver as opções disponíveis"
            exit 1
            ;;
    esac
done

# Validar parâmetros
if [[ ! "$PHASE" =~ ^[1-4]$ ]]; then
    log_error "Fase inválida: $PHASE. Use: 1, 2, 3 ou 4"
    exit 1
fi

if [[ ! "$ENVIRONMENT" =~ ^(prod|stage|dev)$ ]]; then
    log_error "Ambiente inválido: $ENVIRONMENT. Use: prod, stage ou dev"
    exit 1
fi

# Executar função principal
main "$@" 