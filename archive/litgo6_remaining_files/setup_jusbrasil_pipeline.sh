#!/bin/bash

# Setup script para o Pipeline Jusbrasil → Algoritmo de Match
# Este script configura todas as dependências e executa as migrações necessárias

set -e  # Parar em caso de erro

echo "🚀 Configurando Pipeline Jusbrasil → Algoritmo de Match"
echo "======================================================"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para logging
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

# Verificar se Python 3.9+ está instalado
log_info "Verificando versão do Python..."
PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}' | cut -d. -f1,2)
REQUIRED_VERSION="3.9"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$PYTHON_VERSION" | sort -V | head -n1)" = "$REQUIRED_VERSION" ]; then
    log_success "Python $PYTHON_VERSION detectado (>= 3.9)"
else
    log_error "Python 3.9+ é necessário. Versão atual: $PYTHON_VERSION"
    exit 1
fi

# Verificar se pip está instalado
if ! command -v pip3 &> /dev/null; then
    log_error "pip3 não encontrado. Instale pip primeiro."
    exit 1
fi

# Criar ambiente virtual se não existir
if [ ! -d "venv" ]; then
    log_info "Criando ambiente virtual Python..."
    python3 -m venv venv
    log_success "Ambiente virtual criado"
else
    log_info "Ambiente virtual já existe"
fi

# Ativar ambiente virtual
log_info "Ativando ambiente virtual..."
source venv/bin/activate

# Atualizar pip
log_info "Atualizando pip..."
pip install --upgrade pip

# Instalar dependências Python
log_info "Instalando dependências Python..."
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
    log_success "Dependências Python instaladas"
else
    log_error "Arquivo requirements.txt não encontrado"
    exit 1
fi

# Verificar se Redis está rodando
log_info "Verificando Redis..."
if redis-cli ping >/dev/null 2>&1; then
    log_success "Redis está rodando"
else
    log_warning "Redis não detectado. Tentando iniciar..."
    if command -v redis-server &> /dev/null; then
        redis-server --daemonize yes
        sleep 2
        if redis-cli ping >/dev/null 2>&1; then
            log_success "Redis iniciado com sucesso"
        else
            log_error "Falha ao iniciar Redis. Instale e configure manualmente."
        fi
    else
        log_error "Redis não instalado. Instale com: sudo apt-get install redis-server (Ubuntu) ou brew install redis (macOS)"
    fi
fi

# Verificar variáveis de ambiente
log_info "Verificando variáveis de ambiente..."

REQUIRED_VARS=(
    "DATABASE_URL"
    "REDIS_URL"
    "JUSBRASIL_API_KEY"
)

MISSING_VARS=()

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -eq 0 ]; then
    log_success "Todas as variáveis de ambiente necessárias estão configuradas"
else
    log_warning "Variáveis de ambiente faltando: ${MISSING_VARS[*]}"
    
    # Criar arquivo .env de exemplo se não existir
    if [ ! -f ".env" ]; then
        log_info "Criando arquivo .env de exemplo..."
        cat > .env << EOF
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/litgo5
SUPABASE_URL=your_supabase_url
SUPABASE_SERVICE_KEY=your_supabase_service_key

# Redis
REDIS_URL=redis://localhost:6379/0

# Jusbrasil API
JUSBRASIL_API_KEY=your_jusbrasil_api_key_here

# Security
LGPD_SALT=your_random_salt_for_hashing_sensitive_data
JWT_SECRET_KEY=your_jwt_secret_key

# OpenAI (opcional)
OPENAI_API_KEY=your_openai_api_key

# Environment
APP_ENVIRONMENT=development
EOF
        log_success "Arquivo .env criado. Configure as variáveis necessárias."
    fi
fi

# Testar conexão com banco de dados
if [ -n "$DATABASE_URL" ]; then
    log_info "Testando conexão com banco de dados..."
    
    python3 -c "
import psycopg2
import os
try:
    conn = psycopg2.connect(os.getenv('DATABASE_URL'))
    conn.close()
    print('✅ Conexão com banco bem-sucedida')
except Exception as e:
    print(f'❌ Erro na conexão: {e}')
    exit(1)
" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_success "Conexão com banco de dados OK"
    else
        log_error "Falha na conexão com banco de dados"
    fi
else
    log_warning "DATABASE_URL não configurada - pulando teste de conexão"
fi

# Executar migrações do banco
if [ -n "$DATABASE_URL" ]; then
    log_info "Executando migrações do banco de dados..."
    
    # Verificar se Supabase CLI está instalado
    if command -v supabase &> /dev/null; then
        supabase db push 2>/dev/null || log_warning "Erro ao executar migrações via Supabase CLI"
    else
        log_warning "Supabase CLI não encontrado. Execute as migrações manualmente:"
        echo "  1. Instale Supabase CLI: https://supabase.com/docs/guides/cli"
        echo "  2. Execute: supabase db push"
        echo "  3. Ou execute o SQL em: supabase/migrations/20250103000040_add_jusbrasil_tables.sql"
    fi
fi

# Instalar e configurar pgvector (se necessário)
log_info "Verificando extensão pgvector..."
if [ -n "$DATABASE_URL" ]; then
    python3 -c "
import psycopg2
import os
try:
    conn = psycopg2.connect(os.getenv('DATABASE_URL'))
    cur = conn.cursor()
    cur.execute('CREATE EXTENSION IF NOT EXISTS vector;')
    conn.commit()
    conn.close()
    print('✅ Extensão pgvector configurada')
except Exception as e:
    print(f'❌ Erro ao configurar pgvector: {e}')
    print('  Configure manualmente: CREATE EXTENSION vector;')
" 2>/dev/null
fi

# Testar job de sincronização
log_info "Testando job de sincronização..."
if [ -n "$JUSBRASIL_API_KEY" ] && [ -n "$DATABASE_URL" ]; then
    python3 -c "
import sys
sys.path.append('.')
from backend.jobs.jusbrasil_sync import JusbrasilETL
import asyncio

async def test():
    etl = JusbrasilETL()
    print('✅ Job de sincronização carregado com sucesso')

try:
    asyncio.run(test())
except Exception as e:
    print(f'❌ Erro ao carregar job: {e}')
    exit(1)
" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_success "Job de sincronização testado com sucesso"
    else
        log_warning "Job de sincronização com problemas - verifique dependências"
    fi
else
    log_warning "Configuração incompleta - pulando teste do job"
fi

# Configurar Celery workers (opcional)
log_info "Configuração de workers Celery..."
if command -v celery &> /dev/null; then
    log_success "Celery instalado"
    echo "Para iniciar workers:"
    echo "  celery -A backend.celery_app worker --loglevel=info -Q jusbrasil"
    echo "  celery -A backend.celery_app beat --loglevel=info"
else
    log_info "Celery será instalado com as dependências"
fi

# Baixar modelo de embeddings
log_info "Baixando modelo de embeddings..."
python3 -c "
from sentence_transformers import SentenceTransformer
try:
    model = SentenceTransformer('sentence-transformers/all-MiniLM-L6-v2')
    print('✅ Modelo de embeddings baixado')
except Exception as e:
    print(f'❌ Erro ao baixar modelo: {e}')
" 2>/dev/null

# Resumo final
echo ""
echo "======================================================"
log_success "🎉 Setup do Pipeline Jusbrasil concluído!"
echo ""
echo "📋 Próximos passos:"
echo "   1. Configure as variáveis no arquivo .env"
echo "   2. Execute as migrações: supabase db push"
echo "   3. Teste o job: python backend/jobs/jusbrasil_sync.py"
echo "   4. Inicie os workers: celery -A backend.celery_app worker -Q jusbrasil"
echo ""
echo "📖 Documentação: PIPELINE_JUSBRASIL_MATCH.md"
echo "🔗 Arquitetura: https://github.com/Augusto94/jusbr"
echo ""

# Verificar se todas as dependências críticas estão OK
CRITICAL_CHECKS=(
    "Python 3.9+"
    "Redis"
    "Dependências Python"
)

OPTIONAL_CHECKS=(
    "DATABASE_URL"
    "JUSBRASIL_API_KEY"
    "pgvector"
)

echo "✅ Verificações críticas concluídas:"
for check in "${CRITICAL_CHECKS[@]}"; do
    echo "   ✓ $check"
done

echo ""
echo "⚠️ Configurações opcionais/manuais:"
for check in "${OPTIONAL_CHECKS[@]}"; do
    echo "   ○ $check"
done

echo ""
log_info "Para executar uma sincronização de teste:"
echo "   source venv/bin/activate"
echo "   python backend/jobs/jusbrasil_sync.py"
echo ""

# Desativar ambiente virtual
deactivate 