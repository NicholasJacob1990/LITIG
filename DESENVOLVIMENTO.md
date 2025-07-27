# 🚀 LITIG-1 - Guia de Desenvolvimento

## Pré-requisitos

- **Docker** e **Docker Compose** instalados
- **Git** configurado
- Editor de código (VS Code recomendado)

## 🎯 Opções de Ambiente de Desenvolvimento

Você tem **duas opções** para rodar o ambiente de desenvolvimento:

### 📦 Opção A: Ambiente Local Completo (Recomendado)
- PostgreSQL e Redis rodando em contêineres locais
- **100% offline** após o primeiro build
- Mais rápido e estável para desenvolvimento

### ☁️ Opção B: Híbrido com Supabase
- Banco de dados gerenciado pelo Supabase
- Redis no Upstash ou similar
- Ideal para testar integrações específicas do Supabase

---

## 🚀 Setup Rápido - Opção A (Local Completo)

### 1. Clonar e Configurar

```bash
git clone <seu-repositorio>
cd LITIG-1

# Copiar exemplo de configuração
cp packages/backend/.env.dev.example packages/backend/.env.dev
```

### 2. Configurar Variáveis de Ambiente

Edite `packages/backend/.env.dev` e adicione suas chaves de API reais:

```bash
# Essenciais para funcionar
OPENAI_API_KEY=sk-your-real-openai-key
PERPLEXITY_API_KEY=pplx-your-real-perplexity-key
ANTHROPIC_API_KEY=sk-ant-your-real-anthropic-key

# As outras podem ficar com valores de exemplo inicialmente
```

### 3. Iniciar o Ambiente

```bash
# Primeira execução (vai fazer build das imagens)
docker-compose -f docker-compose.dev.yml up --build

# Execuções seguintes (mais rápido)
docker-compose -f docker-compose.dev.yml up
```

### 4. Aplicar Migrações

Em outro terminal:

```bash
# Aplicar migrações do banco
docker-compose -f docker-compose.dev.yml exec api alembic upgrade head
```

### 5. Acessar a Aplicação

- **API**: http://localhost:8000
- **Documentação Swagger**: http://localhost:8000/docs
- **Admin do Banco (Adminer)**: http://localhost:8080
- **Monitoramento Celery (Flower)**: http://localhost:5555

---

## ☁️ Setup - Opção B (Supabase)

### 1. Configurar Supabase

1. Acesse [Supabase](https://supabase.com)
2. Crie um novo projeto
3. Vá em **Settings > Database** e copie a connection string
4. Vá em **Settings > API** e copie as chaves

### 2. Configurar Redis (Upstash)

1. Acesse [Upstash](https://upstash.com)
2. Crie um banco Redis
3. Copie a URL de conexão

### 3. Configurar Ambiente

```bash
# Copiar exemplo do Supabase
cp packages/backend/.env.supabase.example packages/backend/.env.dev

# Editar com suas credenciais reais
nano packages/backend/.env.dev
```

### 4. Iniciar

```bash
docker-compose -f docker-compose.supabase.yml up --build
```

### 5. Aplicar Migrações

```bash
docker-compose -f docker-compose.supabase.yml exec api alembic upgrade head
```

---

## 🛠️ Comandos Úteis de Desenvolvimento

### Gerenciamento do Ambiente

```bash
# Parar todos os serviços
docker-compose -f docker-compose.dev.yml down

# Parar e remover volumes (reset completo)
docker-compose -f docker-compose.dev.yml down -v

# Ver logs em tempo real
docker-compose -f docker-compose.dev.yml logs -f api

# Ver logs específicos do worker
docker-compose -f docker-compose.dev.yml logs -f worker

# Rebuild apenas a API
docker-compose -f docker-compose.dev.yml up --build api
```

### Banco de Dados

```bash
# Conectar ao PostgreSQL
docker-compose -f docker-compose.dev.yml exec database psql -U litigo -d litigo_dev

# Criar nova migração
docker-compose -f docker-compose.dev.yml exec api alembic revision -m "sua_descricao"

# Aplicar migrações
docker-compose -f docker-compose.dev.yml exec api alembic upgrade head

# Voltar migração
docker-compose -f docker-compose.dev.yml exec api alembic downgrade -1
```

### Celery

```bash
# Executar job específico
docker-compose -f docker-compose.dev.yml exec worker celery -A celery_app.celery_app call case_match_retrain.auto_retrain_case_matching_task

# Limpar fila
docker-compose -f docker-compose.dev.yml exec worker celery -A celery_app.celery_app purge

# Status dos workers
docker-compose -f docker-compose.dev.yml exec worker celery -A celery_app.celery_app status
```

### Testes

```bash
# Executar todos os testes
docker-compose -f docker-compose.dev.yml exec api pytest

# Testes com coverage
docker-compose -f docker-compose.dev.yml exec api pytest --cov=. --cov-report=html

# Teste específico
docker-compose -f docker-compose.dev.yml exec api pytest tests/test_case_feedback.py -v
```

---

## 🔍 Monitoramento e Debug

### URLs de Monitoramento

| Serviço | URL | Descrição |
|---------|-----|-----------|
| API Docs | http://localhost:8000/docs | Documentação interativa da API |
| Health Check | http://localhost:8000/health | Status de saúde da aplicação |
| Adminer | http://localhost:8080 | Interface web para PostgreSQL |
| Flower | http://localhost:5555 | Monitoramento do Celery |
| Redis CLI | `docker exec -it litigo-redis-dev redis-cli` | Console do Redis |

### Logs Estruturados

```bash
# Ver todos os logs
docker-compose -f docker-compose.dev.yml logs -f

# Filtrar por serviço
docker-compose -f docker-compose.dev.yml logs -f api worker

# Buscar por termo específico
docker-compose -f docker-compose.dev.yml logs | grep "ERROR"
```

---

## 🎨 Desenvolvimento com Hot Reload

O ambiente está configurado para **hot reload**:

- ✅ **API FastAPI**: Reinicia automaticamente quando você salva um arquivo `.py`
- ✅ **Celery Workers**: Também recarregam automaticamente
- ✅ **Volume Mapping**: Suas alterações locais aparecem instantaneamente no contêiner

### Workflow Típico

1. Edite código no seu editor favorito
2. Salve o arquivo
3. A API reinicia automaticamente (~2-3 segundos)
4. Teste no navegador/Postman

---

## 🐛 Troubleshooting

### Problemas Comuns

**Erro: "Port already in use"**
```bash
# Verificar o que está usando a porta
lsof -i :8000

# Parar todos os contêineres
docker-compose -f docker-compose.dev.yml down
```

**Erro: "Database connection failed"**
```bash
# Verificar se o PostgreSQL está rodando
docker-compose -f docker-compose.dev.yml ps

# Ver logs do banco
docker-compose -f docker-compose.dev.yml logs database
```

**Erro: "Module not found"**
```bash
# Rebuild com cache limpo
docker-compose -f docker-compose.dev.yml build --no-cache api
```

**Celery não está processando jobs**
```bash
# Verificar status
docker-compose -f docker-compose.dev.yml exec worker celery -A celery_app.celery_app inspect active

# Reiniciar worker
docker-compose -f docker-compose.dev.yml restart worker
```

### Reset Completo

Se tudo der errado:

```bash
# Parar tudo e remover volumes
docker-compose -f docker-compose.dev.yml down -v

# Remover imagens antigas
docker system prune -f

# Rebuild do zero
docker-compose -f docker-compose.dev.yml up --build
```

---

## 📊 Testando o AutoML

Após o ambiente estar rodando, você pode testar o sistema AutoML:

### 1. Criar Feedback de Teste

```bash
curl -X POST "http://localhost:8000/api/feedback/case" \
  -H "Content-Type: application/json" \
  -d '{
    "case_id": "test_case_1",
    "lawyer_id": "test_lawyer_1", 
    "client_id": "test_client_1",
    "hired": true,
    "client_satisfaction": 4.5,
    "case_success": true,
    "case_area": "Trabalhista",
    "lawyer_rank_position": 1,
    "total_candidates": 5,
    "match_score": 0.85,
    "preset_used": "balanced"
  }'
```

### 2. Verificar Métricas

```bash
curl "http://localhost:8000/api/feedback/metrics"
```

### 3. Forçar Retreinamento (Admin)

```bash
curl -X POST "http://localhost:8000/api/feedback/optimize" \
  -H "Content-Type: application/json" \
  -d '{"force_optimization": true}'
```

---

## 🚀 Próximos Passos

Com o ambiente funcionando, você pode:

1. **Implementar Fase 2**: Expandir XAI na UI
2. **Implementar Fase 3**: Adicionar LLM reranking
3. **Preparar Produção**: Configurar CI/CD e deploy

**Happy coding! 🎉** 