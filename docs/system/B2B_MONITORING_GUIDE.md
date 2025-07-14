# 📊 Guia de Monitoramento B2B Law Firms

Este documento detalha a configuração e uso do sistema de monitoramento para o sistema B2B Law Firms.

## 🎯 Objetivos do Monitoramento

### Métricas Principais
- **Latência de Ranking B2B**: P99 < 200ms
- **Taxa de Sucesso B2B**: > 70% de contratos aceitos na primeira oferta
- **Disponibilidade da API**: > 99.9%
- **Freshness dos Dados**: KPIs atualizados < 24h

### Componentes Monitorados
1. **Algoritmo de Matching B2B**
2. **Feature-E (Firm Reputation)**
3. **Conflict Scan**
4. **Endpoints de Escritórios**
5. **Sistema de Parcerias**

## 🚨 Alertas Configurados

### Alertas Críticos (Resposta Imediata)

#### B2BRankingHighLatency
- **Condição**: P99 latência > 200ms por 3 minutos
- **Impacto**: Experiência do usuário degradada
- **Ação**: Verificar performance do algoritmo two-pass

#### B2BMatchingFailure
- **Condição**: Taxa de erro > 5% por 2 minutos
- **Impacto**: Falha no matching B2B
- **Ação**: Verificar logs do algoritmo e conexões de banco

### Alertas de Warning

#### B2BSuccessRateLow
- **Condição**: Taxa de sucesso < 70% por 15 minutos
- **Impacto**: Qualidade dos matches baixa
- **Ação**: Revisar pesos do algoritmo e dados de entrada

#### FirmEndpointHighLatency
- **Condição**: P95 latência > 1s por 5 minutos
- **Impacto**: API lenta para escritórios
- **Ação**: Verificar queries de banco e cache

#### FirmDataStale
- **Condição**: KPIs não atualizados > 24h
- **Impacto**: Dados desatualizados no ranking
- **Ação**: Verificar jobs de sincronização

## 📈 Métricas Detalhadas

### Métricas de Performance

```prometheus
# Latência do ranking B2B
litgo_match_rank_duration_seconds_bucket{entity="firm"}

# Taxa de sucesso B2B
match_b2b_success_rate

# Erros na Feature-E
feature_e_calculation_errors_total

# Timeouts no conflict scan
conflict_scan_timeout_total
```

### Métricas de Negócio

```prometheus
# Casos corporativos criados
corporate_cases_created_total

# Matches de escritórios gerados
firm_matches_generated_total

# Contratos com escritórios criados
firm_contracts_created_total

# Propostas de parceria
partnership_proposals_sent_total
partnership_proposals_accepted_total
```

### Métricas de Dados

```prometheus
# Freshness dos KPIs
firm_kpis_last_updated_timestamp

# Número de escritórios ativos
firm_kpis_active_cases

# Taxa de sucesso por escritório
firm_kpis_success_rate
```

## 🔧 Configuração

### Pré-requisitos
- Prometheus rodando na porta 9090
- Grafana rodando na porta 3000
- Backend com métricas habilitadas
- Alertmanager configurado

### Instalação Automática
```bash
# Executar script de configuração
./infra/scripts/setup_b2b_monitoring.sh

# Verificar status
curl http://localhost:9090/api/v1/status/config
curl http://localhost:3000/api/health
```

### Configuração Manual

#### 1. Configurar Prometheus
```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "alerts.yml"

scrape_configs:
  - job_name: 'litgo-backend'
    static_configs:
      - targets: ['localhost:8080']
    metrics_path: '/metrics'
    scrape_interval: 15s
```

#### 2. Configurar Alertmanager
```yaml
# alertmanager.yml
global:
  smtp_smarthost: 'localhost:587'
  smtp_from: 'alerts@litgo.com'

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'
  routes:
  - match:
      component: b2b_ranking
    receiver: 'b2b-team'

receivers:
- name: 'b2b-team'
  slack_configs:
  - api_url: 'YOUR_SLACK_WEBHOOK_URL'
    channel: '#b2b-alerts'
    title: 'B2B Law Firms Alert'
    text: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'
```

#### 3. Importar Dashboard
```bash
# Importar via API
curl -X POST \
  -H "Content-Type: application/json" \
  -d @infra/grafana/dashboards/b2b_law_firms_dashboard.json \
  http://admin:admin@localhost:3000/api/dashboards/db
```

## 📊 Dashboards

### Dashboard Principal: B2B Law Firms
**URL**: http://localhost:3000/d/b2b_law_firms_dashboard

#### Painéis Principais
1. **B2B Ranking Latency (P99)** - Latência crítica do ranking
2. **B2B Success Rate** - Taxa de sucesso dos matches
3. **Firm vs Lawyer Matches** - Distribuição de matches
4. **Active Firms Count** - Número de escritórios ativos
5. **B2B Ranking Latency Over Time** - Tendência de latência
6. **Firm API Endpoints Performance** - Performance dos endpoints
7. **Feature-E Calculation Errors** - Erros na Feature-E
8. **Conflict Scan Performance** - Performance do conflict scan
9. **Firm KPIs Data Freshness** - Freshness dos dados
10. **B2B Funnel Metrics** - Métricas do funil B2B
11. **Top Performing Firms** - Escritórios com melhor performance
12. **Partnership Activity** - Atividade de parcerias

#### Filtros Disponíveis
- **Período**: 1h, 6h, 24h, 7d, 30d
- **Escritório**: Filtrar por escritório específico
- **Tipo de Caso**: Corporativo, individual
- **Região**: Filtrar por localização

## 🔍 Troubleshooting

### Problemas Comuns

#### 1. Latência Alta no Ranking B2B
```bash
# Verificar queries lentas
curl http://localhost:8080/metrics | grep rank_duration

# Verificar logs do algoritmo
tail -f /var/log/litgo/matching.log | grep "two_pass"

# Verificar conexões de banco
curl http://localhost:8080/health/db
```

#### 2. Taxa de Sucesso Baixa
```bash
# Verificar distribuição de scores
curl http://localhost:8080/api/explain/match_id

# Verificar pesos do algoritmo
curl http://localhost:8080/api/algorithm/weights

# Verificar dados de entrada
curl http://localhost:8080/api/firms/stats
```

#### 3. Dados Desatualizados
```bash
# Verificar jobs de sincronização
curl http://localhost:8080/api/jobs/status

# Forçar atualização de KPIs
curl -X POST http://localhost:8080/api/firms/sync-kpis

# Verificar logs de sincronização
tail -f /var/log/litgo/sync.log
```

### Comandos Úteis

```bash
# Verificar status dos alertas
curl http://localhost:9093/api/v1/alerts

# Silenciar alerta temporariamente
curl -X POST http://localhost:9093/api/v1/silences \
  -d '{"matchers":[{"name":"alertname","value":"B2BRankingHighLatency"}],"startsAt":"2024-01-01T00:00:00Z","endsAt":"2024-01-01T01:00:00Z","createdBy":"admin","comment":"Manutenção programada"}'

# Testar alerta
curl -X POST http://localhost:9093/api/v1/alerts \
  -d '[{"labels":{"alertname":"B2BTestAlert","severity":"info"},"annotations":{"summary":"Teste de alerta B2B"}}]'
```

## 📋 Checklist de Monitoramento

### Configuração Inicial
- [ ] Prometheus configurado e rodando
- [ ] Grafana configurado e rodando
- [ ] Alertmanager configurado
- [ ] Dashboard B2B importado
- [ ] Alertas B2B configurados
- [ ] Notificações configuradas (Slack/Email)

### Verificação Diária
- [ ] Verificar alertas ativos
- [ ] Revisar métricas de latência
- [ ] Verificar taxa de sucesso B2B
- [ ] Conferir freshness dos dados
- [ ] Revisar logs de erro

### Verificação Semanal
- [ ] Analisar tendências de performance
- [ ] Revisar top performing firms
- [ ] Verificar atividade de parcerias
- [ ] Ajustar thresholds se necessário
- [ ] Atualizar documentação

### Verificação Mensal
- [ ] Revisar capacidade de armazenamento
- [ ] Analisar padrões de uso
- [ ] Otimizar consultas lentas
- [ ] Revisar alertas e notificações
- [ ] Planejar melhorias

## 🚀 Próximos Passos

### Melhorias Planejadas
1. **Alertas Preditivos**: Usar ML para prever problemas
2. **Dashboards Personalizados**: Por região e tipo de caso
3. **Métricas de Negócio**: ROI, conversão, retenção
4. **Integração com APM**: Traces distribuídos
5. **Alertas Inteligentes**: Redução de falsos positivos

### Integrações Futuras
- **DataDog**: Para APM avançado
- **Sentry**: Para tracking de erros
- **New Relic**: Para monitoramento de infraestrutura
- **PagerDuty**: Para escalação de alertas

## 📞 Contatos

### Equipe Responsável
- **Backend Team**: backend@litgo.com
- **DevOps Team**: devops@litgo.com
- **B2B Product Team**: b2b@litgo.com

### Escalação
1. **Nível 1**: Slack #b2b-alerts
2. **Nível 2**: Email backend@litgo.com
3. **Nível 3**: Phone +55 11 99999-9999

### Documentação
- **Runbooks**: https://wiki.litgo.com/runbooks/
- **API Docs**: https://api.litgo.com/docs
- **Architecture**: https://wiki.litgo.com/architecture/ 