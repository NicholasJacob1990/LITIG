# 🚀 Guia de CI/CD - LITGO5

Este documento detalha o pipeline completo de CI/CD (Integração Contínua / Deploy Contínuo) do LITGO5, incluindo configuração, estratégias de deploy e monitoramento.

## 📋 Índice

1. [Visão Geral](#-visão-geral)
2. [Configuração do Pipeline](#-configuração-do-pipeline)
3. [Estratégias de Deploy](#-estratégias-de-deploy)
4. [Ambientes](#-ambientes)
5. [Monitoramento e Alertas](#-monitoramento-e-alertas)
6. [Rollback e Recuperação](#-rollback-e-recuperação)
7. [Boas Práticas](#-boas-práticas)

## 🎯 Visão Geral

O LITGO5 utiliza um pipeline de CI/CD robusto e automatizado que garante:

- **Qualidade:** Testes automatizados em múltiplas camadas
- **Segurança:** Verificações de vulnerabilidades e compliance
- **Confiabilidade:** Deploy progressivo com rollback automático
- **Performance:** Otimização automática de builds e deploys

### 🏗️ Arquitetura do Pipeline

```mermaid
graph TB
    A[Push/PR] --> B[GitHub Actions]
    B --> C[Build & Test]
    C --> D[Security Scan]
    D --> E[Deploy Staging]
    E --> F[E2E Tests]
    F --> G[Deploy Production]
    G --> H[Health Check]
    H --> I[Monitoring]
    
    I --> J{Health OK?}
    J -->|Não| K[Auto Rollback]
    J -->|Sim| L[Complete]
    
    K --> M[Notification]
    L --> N[Success Notification]
```

## ⚙️ Configuração do Pipeline

### 1. Estrutura de Workflows

```
.github/
├── workflows/
│   ├── ci.yml              # Integração Contínua
│   ├── cd-staging.yml      # Deploy Staging
│   ├── cd-production.yml   # Deploy Produção
│   ├── security-scan.yml   # Verificações de Segurança
│   └── cleanup.yml         # Limpeza de Recursos
├── actions/
│   ├── setup-node/        # Action personalizada Node.js
│   ├── setup-python/      # Action personalizada Python
│   └── deploy-app/        # Action personalizada Deploy
└── CODEOWNERS             # Revisores obrigatórios
```

### 2. Workflow de CI (`.github/workflows/ci.yml`)

```yaml
name: CI - Integração Contínua

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

env:
  NODE_VERSION: '18'
  PYTHON_VERSION: '3.10'

jobs:
  # === Frontend Tests ===
  frontend-test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [18, 20]
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run ESLint
        run: npm run lint
      
      - name: Run TypeScript check
        run: npm run type-check
      
      - name: Run unit tests
        run: npm run test:unit
      
      - name: Run component tests
        run: npm run test:component
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage/lcov.info

  # === Backend Tests ===
  backend-test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: litgo5_test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
      
      redis:
        image: redis:7-alpine
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'
      
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt
          pip install -r requirements-dev.txt
      
      - name: Run Black formatter check
        run: black --check backend/
      
      - name: Run isort check
        run: isort --check-only backend/
      
      - name: Run flake8
        run: flake8 backend/
      
      - name: Run mypy
        run: mypy backend/
      
      - name: Run pytest
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost:5432/litgo5_test
          REDIS_URL: redis://localhost:6379/0
          TESTING: true
        run: |
          pytest backend/tests/ -v --cov=backend --cov-report=xml
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage.xml

  # === Security Scan ===
  security-scan:
    runs-on: ubuntu-latest
    needs: [frontend-test, backend-test]
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          format: 'sarif'
          output: 'trivy-results.sarif'
      
      - name: Upload Trivy scan results
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-results.sarif'
      
      - name: Snyk Security Scan
        uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --severity-threshold=high
      
      - name: Python Security Scan
        run: |
          pip install safety bandit
          safety check
          bandit -r backend/ -f json

  # === Build Docker Images ===
  build-images:
    runs-on: ubuntu-latest
    needs: [frontend-test, backend-test, security-scan]
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Login to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Build and push API image
        uses: docker/build-push-action@v5
        with:
          context: .
          file: Dockerfile.api
          push: true
          tags: |
            ghcr.io/${{ github.repository }}/api:${{ github.sha }}
            ghcr.io/${{ github.repository }}/api:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max
      
      - name: Build Expo for Web
        run: |
          npm ci
          npx expo export:web
          
      - name: Build and push Web image
        uses: docker/build-push-action@v5
        with:
          context: .
          file: Dockerfile.web
          push: true
          tags: |
            ghcr.io/${{ github.repository }}/web:${{ github.sha }}
            ghcr.io/${{ github.repository }}/web:latest
```

### 3. Workflow de Deploy Staging (`.github/workflows/cd-staging.yml`)

```yaml
name: CD - Deploy Staging

on:
  push:
    branches: [ develop ]
  workflow_dispatch:

jobs:
  deploy-staging:
    runs-on: ubuntu-latest
    environment: staging
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Deploy to Staging
        uses: ./.github/actions/deploy-app
        with:
          environment: staging
          api-image: ghcr.io/${{ github.repository }}/api:${{ github.sha }}
          web-image: ghcr.io/${{ github.repository }}/web:${{ github.sha }}
          deploy-key: ${{ secrets.STAGING_DEPLOY_KEY }}
          
      - name: Run E2E Tests
        run: |
          npm ci
          npx playwright test --config=playwright.staging.config.ts
          
      - name: Health Check
        run: |
          curl -f https://staging-api.litgo5.com/health || exit 1
          
      - name: Notify Success
        uses: 8398a7/action-slack@v3
        with:
          status: success
          webhook_url: ${{ secrets.SLACK_WEBHOOK }}
          text: "🚀 Deploy staging concluído com sucesso!"
```

### 4. Workflow de Deploy Produção (`.github/workflows/cd-production.yml`)

```yaml
name: CD - Deploy Production

on:
  push:
    branches: [ main ]
  release:
    types: [ published ]

jobs:
  deploy-production:
    runs-on: ubuntu-latest
    environment: production
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Create deployment
        id: deployment
        uses: actions/github-script@v6
        with:
          script: |
            const deployment = await github.rest.repos.createDeployment({
              owner: context.repo.owner,
              repo: context.repo.repo,
              ref: context.sha,
              environment: 'production',
              description: 'Deploy to production'
            });
            return deployment.data.id;
      
      - name: Deploy with Blue-Green Strategy
        uses: ./.github/actions/deploy-app
        with:
          environment: production
          strategy: blue-green
          api-image: ghcr.io/${{ github.repository }}/api:${{ github.sha }}
          web-image: ghcr.io/${{ github.repository }}/web:${{ github.sha }}
          deploy-key: ${{ secrets.PRODUCTION_DEPLOY_KEY }}
          
      - name: Smoke Tests
        run: |
          # Testes básicos de funcionalidade
          curl -f https://api.litgo5.com/health
          curl -f https://litgo5.com
          
      - name: Database Migration
        run: |
          # Executar migrações se necessário
          kubectl exec -n litgo5 deployment/api -- python manage.py migrate
          
      - name: Switch Traffic
        run: |
          # Alternar tráfego para nova versão
          kubectl patch service/api-service -p '{"spec":{"selector":{"version":"blue"}}}'
          
      - name: Monitor Health
        run: |
          # Monitorar métricas por 5 minutos
          sleep 300
          curl -f https://api.litgo5.com/health
          
      - name: Update deployment status
        uses: actions/github-script@v6
        with:
          script: |
            await github.rest.repos.createDeploymentStatus({
              owner: context.repo.owner,
              repo: context.repo.repo,
              deployment_id: ${{ steps.deployment.outputs.result }},
              state: 'success',
              environment_url: 'https://litgo5.com'
            });
```

## 📱 Estratégias de Deploy

### 1. Blue-Green Deployment

```yaml
# kubernetes/blue-green-deployment.yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: litgo5-api
spec:
  replicas: 5
  strategy:
    blueGreen:
      activeService: api-active
      previewService: api-preview
      autoPromotionEnabled: false
      scaleDownDelaySeconds: 30
      prePromotionAnalysis:
        templates:
        - templateName: success-rate
        args:
        - name: service-name
          value: api-preview
      postPromotionAnalysis:
        templates:
        - templateName: success-rate
        args:
        - name: service-name
          value: api-active
```

### 2. Canary Deployment

```yaml
# kubernetes/canary-deployment.yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: litgo5-web
spec:
  replicas: 10
  strategy:
    canary:
      steps:
      - setWeight: 20
      - pause: {duration: 10m}
      - setWeight: 40
      - pause: {duration: 10m}
      - setWeight: 60
      - pause: {duration: 10m}
      - setWeight: 80
      - pause: {duration: 10m}
      analysis:
        templates:
        - templateName: success-rate
        - templateName: latency
        args:
        - name: service-name
          value: web-canary
```

### 3. Feature Flags

```python
# backend/config/feature_flags.py
from typing import Dict, Any
import os

class FeatureFlags:
    def __init__(self):
        self.flags = {
            "intelligent_triage_v2": os.getenv("FEATURE_INTELLIGENT_TRIAGE_V2", "false").lower() == "true",
            "algorithm_v2_6": os.getenv("FEATURE_ALGORITHM_V2_6", "true").lower() == "true",
            "real_time_notifications": os.getenv("FEATURE_REAL_TIME_NOTIFICATIONS", "true").lower() == "true",
            "advanced_analytics": os.getenv("FEATURE_ADVANCED_ANALYTICS", "false").lower() == "true",
        }
    
    def is_enabled(self, flag_name: str, user_id: str = None) -> bool:
        """
        Verifica se uma feature flag está habilitada.
        Suporta rollout gradual baseado em user_id.
        """
        if flag_name not in self.flags:
            return False
            
        base_enabled = self.flags[flag_name]
        
        # Rollout gradual baseado em hash do user_id
        if user_id and base_enabled:
            import hashlib
            user_hash = int(hashlib.md5(user_id.encode()).hexdigest(), 16)
            rollout_percentage = os.getenv(f"ROLLOUT_{flag_name.upper()}", "100")
            return (user_hash % 100) < int(rollout_percentage)
            
        return base_enabled

# Uso no código
feature_flags = FeatureFlags()

if feature_flags.is_enabled("intelligent_triage_v2", user_id):
    # Usar nova versão da triagem
    pass
```

## 🌍 Ambientes

### 1. Desenvolvimento (Local)

```bash
# docker-compose.dev.yml
version: '3.8'
services:
  api:
    build:
      context: .
      dockerfile: Dockerfile.api
      target: development
    volumes:
      - ./backend:/app
    environment:
      - ENVIRONMENT=development
      - DEBUG=true
      - RELOAD=true
```

### 2. Staging

```yaml
# kubernetes/staging/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../base

patchesStrategicMerge:
  - deployment-patch.yaml
  - service-patch.yaml

configMapGenerator:
  - name: app-config
    literals:
      - ENVIRONMENT=staging
      - DEBUG=false
      - REDIS_URL=redis://redis-staging:6379
```

### 3. Produção

```yaml
# kubernetes/production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../base

patchesStrategicMerge:
  - deployment-patch.yaml
  - service-patch.yaml
  - hpa-patch.yaml

configMapGenerator:
  - name: app-config
    literals:
      - ENVIRONMENT=production
      - DEBUG=false
      - REDIS_URL=redis://redis-cluster:6379
```

## 📊 Monitoramento e Alertas

### 1. Métricas de Deploy

```python
# backend/monitoring/deployment_metrics.py
from prometheus_client import Counter, Histogram, Gauge
import time

# Métricas de deploy
DEPLOYMENT_COUNTER = Counter('deployments_total', 'Total deployments', ['environment', 'status'])
DEPLOYMENT_DURATION = Histogram('deployment_duration_seconds', 'Deployment duration')
ROLLBACK_COUNTER = Counter('rollbacks_total', 'Total rollbacks', ['environment', 'reason'])

class DeploymentMonitor:
    def __init__(self):
        self.start_time = None
    
    def start_deployment(self, environment: str):
        self.start_time = time.time()
        DEPLOYMENT_COUNTER.labels(environment=environment, status='started').inc()
    
    def finish_deployment(self, environment: str, success: bool):
        if self.start_time:
            duration = time.time() - self.start_time
            DEPLOYMENT_DURATION.observe(duration)
            
        status = 'success' if success else 'failed'
        DEPLOYMENT_COUNTER.labels(environment=environment, status=status).inc()
```

### 2. Alertas do Prometheus

```yaml
# prometheus/alerts.yml
groups:
- name: deployment
  rules:
  - alert: DeploymentFailed
    expr: increase(deployments_total{status="failed"}[5m]) > 0
    for: 0m
    labels:
      severity: critical
    annotations:
      summary: "Deployment failed"
      description: "Deployment failed in {{ $labels.environment }}"
      
  - alert: HighRollbackRate
    expr: rate(rollbacks_total[1h]) > 0.1
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High rollback rate detected"
      description: "Rollback rate is {{ $value }} per hour"
      
  - alert: LongDeploymentTime
    expr: deployment_duration_seconds > 600
    for: 0m
    labels:
      severity: warning
    annotations:
      summary: "Deployment taking too long"
      description: "Deployment duration is {{ $value }} seconds"
```

### 3. Slack Notifications

```yaml
# .github/workflows/notifications.yml
name: Notifications

on:
  deployment_status:

jobs:
  notify:
    runs-on: ubuntu-latest
    steps:
      - name: Notify Slack
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          webhook_url: ${{ secrets.SLACK_WEBHOOK }}
          custom_payload: |
            {
              attachments: [{
                color: '${{ job.status }}' === 'success' ? 'good' : 'danger',
                title: `Deployment ${context.payload.deployment.environment}`,
                text: `Status: ${{ github.event.deployment_status.state }}`,
                fields: [{
                  title: 'Environment',
                  value: '${{ github.event.deployment.environment }}',
                  short: true
                }, {
                  title: 'Ref',
                  value: '${{ github.event.deployment.ref }}',
                  short: true
                }]
              }]
            }
```

## 🔄 Rollback e Recuperação

### 1. Rollback Automático

```bash
#!/bin/bash
# scripts/auto-rollback.sh

# Verificar health da aplicação
if ! curl -f https://api.litgo5.com/health; then
    echo "Health check failed, initiating rollback..."
    
    # Buscar última versão estável
    LAST_STABLE=$(kubectl get deployment api -o jsonpath='{.metadata.annotations.deployment\.kubernetes\.io/revision}')
    PREVIOUS_VERSION=$((LAST_STABLE - 1))
    
    # Fazer rollback
    kubectl rollout undo deployment/api --to-revision=$PREVIOUS_VERSION
    
    # Aguardar rollback completar
    kubectl rollout status deployment/api --timeout=300s
    
    # Verificar se rollback foi bem-sucedido
    if curl -f https://api.litgo5.com/health; then
        echo "Rollback successful"
        # Notificar equipe
        curl -X POST $SLACK_WEBHOOK \
             -H 'Content-type: application/json' \
             --data '{"text":"🚨 Rollback automático executado com sucesso!"}'
    else
        echo "Rollback failed, manual intervention required"
        # Alertar para intervenção manual
        curl -X POST $SLACK_WEBHOOK \
             -H 'Content-type: application/json' \
             --data '{"text":"🆘 Rollback automático falhou! Intervenção manual necessária."}'
    fi
fi
```

### 2. Procedimento de Rollback Manual

```bash
# 1. Verificar versões disponíveis
kubectl rollout history deployment/api

# 2. Fazer rollback para versão específica
kubectl rollout undo deployment/api --to-revision=3

# 3. Monitorar progresso
kubectl rollout status deployment/api --watch

# 4. Verificar logs
kubectl logs -f deployment/api

# 5. Executar testes de smoke
curl -f https://api.litgo5.com/health
```

### 3. Rollback de Banco de Dados

```python
# scripts/database_rollback.py
import subprocess
import datetime
import os

def rollback_database(backup_timestamp: str):
    """
    Faz rollback do banco de dados para um backup específico.
    """
    try:
        # Parar aplicação
        subprocess.run(['kubectl', 'scale', 'deployment/api', '--replicas=0'], check=True)
        
        # Restaurar backup
        restore_command = [
            'pg_restore',
            '--host', os.getenv('DB_HOST'),
            '--port', os.getenv('DB_PORT'),
            '--username', os.getenv('DB_USER'),
            '--dbname', os.getenv('DB_NAME'),
            '--clean',
            '--if-exists',
            f'backups/backup_{backup_timestamp}.sql'
        ]
        subprocess.run(restore_command, check=True)
        
        # Reiniciar aplicação
        subprocess.run(['kubectl', 'scale', 'deployment/api', '--replicas=3'], check=True)
        
        print(f"Database rollback to {backup_timestamp} completed successfully")
        
    except subprocess.CalledProcessError as e:
        print(f"Database rollback failed: {e}")
        raise
```

## 🎯 Boas Práticas

### 1. Branching Strategy

```mermaid
graph LR
    A[main] --> B[release/v1.2.0]
    A --> C[hotfix/urgent-fix]
    B --> D[feature/new-algorithm]
    B --> E[feature/ui-improvement]
    D --> F[PR]
    E --> G[PR]
    F --> B
    G --> B
    B --> A
    C --> A
```

### 2. Semantic Versioning

```json
{
  "name": "litgo5",
  "version": "1.2.3",
  "scripts": {
    "release": "standard-version",
    "release:minor": "standard-version --release-as minor",
    "release:major": "standard-version --release-as major"
  }
}
```

### 3. Conventional Commits

```bash
# Formato: <tipo>(<escopo>): <descrição>

feat(api): adicionar endpoint de time tracking
fix(ui): corrigir bug no chat de casos
docs(readme): atualizar instruções de setup
test(algorithm): adicionar testes unitários
refactor(backend): otimizar consultas do banco
perf(matching): melhorar performance do algoritmo
```

### 4. Quality Gates

```yaml
# .github/workflows/quality-gates.yml
name: Quality Gates

on:
  pull_request:
    branches: [ main ]

jobs:
  quality-check:
    runs-on: ubuntu-latest
    steps:
      - name: Code Coverage Gate
        run: |
          COVERAGE=$(cat coverage.xml | grep -o 'line-rate="[^"]*"' | cut -d'"' -f2)
          if (( $(echo "$COVERAGE < 0.80" | bc -l) )); then
            echo "❌ Coverage $COVERAGE is below 80%"
            exit 1
          fi
          echo "✅ Coverage $COVERAGE meets requirements"
      
      - name: Performance Gate
        run: |
          # Executar testes de performance
          npm run test:performance
          
      - name: Security Gate
        run: |
          # Executar verificações de segurança
          npm audit --audit-level=high
```

### 5. Disaster Recovery

```bash
#!/bin/bash
# scripts/disaster-recovery.sh

# Plano de recuperação de desastres
echo "🚨 Iniciando procedimento de recuperação de desastres..."

# 1. Verificar status dos serviços
kubectl get pods -n litgo5

# 2. Restaurar do backup mais recente
./scripts/restore-from-backup.sh

# 3. Verificar integridade dos dados
python scripts/data-integrity-check.py

# 4. Executar testes de smoke
npm run test:smoke

# 5. Notificar equipe
curl -X POST $SLACK_WEBHOOK \
     -H 'Content-type: application/json' \
     --data '{"text":"✅ Procedimento de recuperação de desastres concluído"}'
```

## 📈 Métricas de Sucesso

- **Deployment Frequency:** Meta: 3-5 deploys por semana
- **Lead Time:** Meta: < 2 horas (da mudança até produção)
- **Change Failure Rate:** Meta: < 10%
- **Mean Time to Recovery:** Meta: < 1 hora

## 🔗 Links Úteis

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Argo Rollouts](https://argoproj.github.io/argo-rollouts/)
- [Prometheus Alerting](https://prometheus.io/docs/alerting/latest/)
- [Conventional Commits](https://www.conventionalcommits.org/) 