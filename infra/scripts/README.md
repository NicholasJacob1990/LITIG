# Scripts de Rollback - Feature Firms (B2B Matching)

Este diretório contém scripts para rollback rápido da funcionalidade de escritórios de advocacia (Feature-E) em caso de problemas em produção.

## 📋 Visão Geral

A funcionalidade de escritórios introduz:
- **Feature-E**: Reputação do escritório no algoritmo de matching
- **Algoritmo Two-Pass**: Ranking em dois passos para casos B2B
- **Endpoints `/api/firms/*`**: CRUD de escritórios e KPIs
- **Preset `b2b`**: Pesos otimizados para casos corporativos

## 🔧 Scripts Disponíveis

### 1. `test_rollback.sh` - Teste de Rollback

**Propósito**: Testa se o sistema está pronto para rollback sem executá-lo.

```bash
# Testar ambiente de desenvolvimento
./infra/scripts/test_rollback.sh

# Testar ambiente de produção
./infra/scripts/test_rollback.sh --environment=prod
```

**O que testa**:
- ✅ Pré-requisitos (Docker, curl, estrutura do projeto)
- ✅ Feature flag `ENABLE_FIRM_MATCH`
- ✅ Pesos do algoritmo (Feature-E, preset b2b)
- ✅ Endpoints de firms no código
- ✅ Conexão Redis
- ✅ Configuração Docker Compose
- ✅ Capacidade de backup
- ✅ Configuração de notificações

### 2. `disable_firm_match.sh` - Rollback Rápido

**Propósito**: Executa rollback completo da funcionalidade de escritórios.

```bash
# Rollback em desenvolvimento
./infra/scripts/disable_firm_match.sh

# Rollback em produção (requer confirmação)
./infra/scripts/disable_firm_match.sh --environment=prod
```

**O que faz**:
1. 🔄 Desabilita feature flag `ENABLE_FIRM_MATCH=false`
2. ⚖️ Reverte pesos do algoritmo (remove Feature-E)
3. 🚫 Desabilita endpoints `/api/firms/*`
4. 🧹 Limpa cache Redis relacionado a firms
5. 🔄 Reinicia serviços (Docker Compose)
6. ✅ Verifica se rollback foi bem-sucedido
7. 📊 Cria relatório detalhado
8. 📢 Envia notificações (Slack, Discord, Email)

## 🚀 Uso Recomendado

### Em Caso de Emergência

```bash
# 1. Primeiro, teste se o rollback pode ser executado
./infra/scripts/test_rollback.sh --environment=prod

# 2. Se o teste passou, execute o rollback
./infra/scripts/disable_firm_match.sh --environment=prod
```

### Para Desenvolvimento

```bash
# Teste local
./infra/scripts/test_rollback.sh

# Rollback local (sem confirmação)
./infra/scripts/disable_firm_match.sh
```

## ⚙️ Configuração

### Variáveis de Ambiente Opcionais

Para receber notificações automáticas, configure:

```bash
# Slack
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

# Discord
export DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/YOUR/WEBHOOK/URL"

# Email
export ALERT_EMAIL="admin@litgo.com"
```

### Estrutura de Arquivos Esperada

```
LITIG-1/
├── packages/backend/
│   ├── main.py                 # Arquivo principal da API
│   ├── algoritmo_match.py      # Algoritmo de matching
│   └── routes/firms.py         # Endpoints de firms
├── .env                        # Variáveis de ambiente
├── docker-compose.yml          # Configuração Docker
└── infra/scripts/
    ├── disable_firm_match.sh   # Script de rollback
    ├── test_rollback.sh        # Script de teste
    └── README.md               # Este arquivo
```

## 📊 Monitoramento

### Logs

Todos os scripts geram logs detalhados:

```bash
# Logs do rollback
tail -f logs/rollback_YYYYMMDD_HHMMSS.log

# Relatórios
cat logs/rollback_report_YYYYMMDD_HHMMSS.md
```

### Arquivos de Backup

O rollback cria backups automáticos:

```bash
# Exemplos de arquivos de backup criados
.env.backup.20250121_143022
packages/backend/main.py.backup.20250121_143023
packages/backend/algoritmo_match.py.backup.20250121_143024
```

## 🔍 Verificação Pós-Rollback

### 1. Status da API

```bash
# Verificar se API está respondendo
curl http://localhost:8000

# Deve retornar: {"status": "ok", "message": "Bem-vindo à API LITGO!"}
```

### 2. Endpoints de Firms Desabilitados

```bash
# Deve retornar 404
curl http://localhost:8000/api/firms

# Deve retornar: {"detail": "Not Found"}
```

### 3. Matching Básico Funcionando

```bash
# Testar matching sem firms
curl -X POST http://localhost:8000/api/match \
  -H "Content-Type: application/json" \
  -d '{"case_id": "test-case", "top_n": 3, "preset": "balanced"}'

# Deve retornar lista de matches (apenas advogados)
```

### 4. Feature Flag Desabilitada

```bash
# Verificar .env
grep ENABLE_FIRM_MATCH .env

# Deve mostrar: ENABLE_FIRM_MATCH=false
```

## 🛠️ Solução de Problemas

### Problema: Script não executa

```bash
# Verificar permissões
ls -la infra/scripts/

# Tornar executável se necessário
chmod +x infra/scripts/*.sh
```

### Problema: API não responde após rollback

```bash
# Verificar logs do Docker
docker-compose logs backend

# Reiniciar manualmente
docker-compose restart backend
```

### Problema: Redis não encontrado

```bash
# Verificar containers
docker ps | grep redis

# Iniciar Redis se necessário
docker-compose up -d redis
```

### Problema: Backup falhou

```bash
# Verificar espaço em disco
df -h

# Verificar permissões de escrita
ls -la logs/
```

## 🔄 Reversão do Rollback

Para reverter o rollback e reativar a funcionalidade:

```bash
# 1. Restaurar feature flag
sed -i 's/ENABLE_FIRM_MATCH=false/ENABLE_FIRM_MATCH=true/g' .env

# 2. Restaurar arquivos de backup
cp packages/backend/main.py.backup.TIMESTAMP packages/backend/main.py
cp packages/backend/algoritmo_match.py.backup.TIMESTAMP packages/backend/algoritmo_match.py

# 3. Reiniciar serviços
docker-compose restart backend
```

## 📞 Contato de Emergência

Em caso de problemas críticos:

1. **Slack**: Canal `#litgo-alerts`
2. **Email**: `admin@litgo.com`
3. **Discord**: Canal `emergencia`

## 📚 Documentação Adicional

- [Plano de Implementação B2B](../../docs/system/B2B_IMPLEMENTATION_PLAN.md)
- [Guia de Monitoramento](../../docs/system/B2B_MONITORING_GUIDE.md)
- [Documentação da API](../../LITGO6/openapi.yaml)

---

**Última atualização**: Janeiro 2025  
**Versão**: 1.0  
**Autor**: Sistema LITGO 