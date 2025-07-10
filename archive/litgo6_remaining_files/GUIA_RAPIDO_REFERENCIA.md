# �� Guia Rápido de Referência - LITGO5

## 📋 Comandos Essenciais

### 🐳 Docker (Recomendado)
```bash
# Iniciar todos os serviços
docker-compose up

# Rebuild após mudanças
docker-compose up --build

# Parar serviços
docker-compose down

# Ver logs
docker-compose logs -f api
docker-compose logs -f worker
```

### 🔧 Desenvolvimento Local
```bash
# Backend
cd backend
source venv/bin/activate
uvicorn main:app --reload

# Worker Celery
celery -A celery_app worker --loglevel=info

# Frontend
npx expo start

# Redis
docker run -p 6379:6379 redis:alpine
```

### 🧪 Testes
```bash
# Backend
cd backend
python -m pytest tests/ -v --cov

# Frontend
npm test

# Teste específico
python -m pytest tests/test_match.py -v
```

## 📡 Endpoints Principais

### Triagem
```bash
# Iniciar triagem
curl -X POST http://localhost:8000/api/triage \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"texto_cliente": "Meu caso...", "coords": [-23.55, -46.63]}'

# Verificar status
curl http://localhost:8000/api/triage/status/{task_id} \
  -H "Authorization: Bearer $TOKEN"
```

### Match
```bash
# Buscar advogados
curl -X POST http://localhost:8000/api/match \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"case_id": "case-123", "k": 5}'
```

### Explicações
```bash
# Gerar explicações
curl -X POST http://localhost:8000/api/explain \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"case_id": "case-123", "lawyer_ids": ["lw-001"]}'
```

## 🔑 Variáveis de Ambiente Críticas

```bash
# Supabase
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_SERVICE_KEY=eyJhbGc...

# IA
ANTHROPIC_API_KEY=sk-ant-api03...
OPENAI_API_KEY=sk-proj-...

# Redis
REDIS_URL=redis://localhost:6379/0

# DocuSign (Opcional)
USE_DOCUSIGN=true
DOCUSIGN_API_KEY=xxx
DOCUSIGN_ACCOUNT_ID=xxx

# Frontend
EXPO_PUBLIC_API_URL=http://localhost:8000
```

## 📊 Estrutura de Diretórios

```
LITGO5/
├── app/              # Telas React Native
├── components/       # Componentes UI
├── backend/          # API Python/FastAPI
│   ├── main.py      # Entry point
│   ├── algoritmo_match.py
│   └── services/
├── supabase/        # Migrations SQL
├── docs/            # Documentação extra
└── tests/           # Testes automatizados
```

## �� Algoritmo - Features e Pesos

| Feature | Peso | Descrição |
|---------|------|-----------|
| **A** | 30% | Compatibilidade de área |
| **S** | 25% | Similaridade de casos |
| **T** | 15% | Taxa de sucesso |
| **G** | 10% | Proximidade geográfica |
| **Q** | 10% | Qualificação/Experiência |
| **U** | 5% | Urgência/Disponibilidade |
| **R** | 5% | Rating/Avaliações |

## 🐛 Debugging Rápido

### Backend não inicia
```bash
# Verificar portas
lsof -i :8000
lsof -i :6379

# Verificar env
python -c "from backend.config import settings; print(settings)"

# Logs detalhados
ENVIRONMENT=development uvicorn main:app --log-level debug
```

### Worker não processa
```bash
# Verificar Redis
redis-cli ping

# Verificar filas
celery -A celery_app inspect active

# Purgar filas
celery -A celery_app purge -f
```

### Frontend não conecta
```bash
# Verificar API URL
echo $EXPO_PUBLIC_API_URL

# Testar conexão
curl http://localhost:8000/

# Limpar cache Expo
expo start -c
```

## 📈 Métricas de Performance

### Targets
- **Triagem**: < 3s (P95)
- **Match**: < 1s (P95)
- **API Response**: < 200ms (P95)
- **Uptime**: > 99.9%

### Monitoramento
```bash
# CPU/Memory
docker stats

# Logs estruturados
docker-compose logs api | jq .

# Redis info
redis-cli info stats
```

## 🔒 Checklist de Segurança

- [ ] JWT configurado
- [ ] HTTPS em produção
- [ ] Rate limiting ativo
- [ ] CORS configurado
- [ ] Secrets em .env
- [ ] SQL injection prevenido
- [ ] Logs sem dados sensíveis

## 📱 Deploy Rápido

### Backend (Cloud Run)
```bash
gcloud run deploy litgo-api \
  --source . \
  --region us-central1 \
  --allow-unauthenticated
```

### Frontend (Expo)
```bash
# Build
eas build --platform all --profile production

# Submit
eas submit --platform ios
eas submit --platform android
```

## 📞 Links Úteis

- **API Docs**: http://localhost:8000/docs
- **Supabase**: https://app.supabase.com
- **DocuSign**: https://admin.docusign.com
- **Expo**: https://expo.dev

---

**Dica**: Use `Ctrl+F` para buscar rapidamente neste guia!

### 4. Executando Jobs Manuais

#### Job de Sincronização do Jusbrasil
```bash
# Sincroniza a taxa de sucesso dos advogados
python3 backend/jobs/jusbrasil_sync.py
```

#### Job de Expiração de Ofertas
```bash
# Expira ofertas que não foram respondidas no prazo
python3 backend/jobs/expire_offers.py
```

#### Job de Atualização de KPIs de Review
```bash
# Calcula e atualiza a avaliação média dos advogados
python3 backend/jobs/update_review_kpi.py
```

### 5. Pipeline de Learning-to-Rank (LTR)

#### Passo 1: Gerar Dataset a partir dos Logs
```bash
# Processa logs/audit.log e cria data/ltr_dataset.parquet
python3 backend/jobs/ltr_export.py
```

#### Passo 2: Treinar Modelo e Gerar Novos Pesos
```bash
# Treina o modelo LGBMRanker e gera backend/models/ltr_weights.json
python3 backend/jobs/ltr_train.py
```

#### Passo 3: Recarregar Pesos em Tempo Real (Opcional)
```bash
# Força o servidor a recarregar os pesos do arquivo JSON sem reiniciar
curl -X POST http://localhost:8000/api/internal/reload_weights
```

### 6. Stack de Observabilidade
```bash
# Inicia Prometheus e Grafana
docker-compose -f docker-compose.observability.yml up -d
```
Acesse:
- **Prometheus**: `http://localhost:9090`
- **Grafana**: `http://localhost:3001` (admin/admin)
