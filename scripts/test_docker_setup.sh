#!/bin/bash

# =============================================================================
# LITIG-1 - Script de Teste do Ambiente Docker
# =============================================================================
# Testa se a configuração Docker está funcionando corretamente

set -e  # Parar se qualquer comando falhar

echo "🚀 LITIG-1 - Teste do Ambiente Docker"
echo "======================================"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para imprimir mensagens coloridas
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Verificar pré-requisitos
echo "🔍 Verificando pré-requisitos..."

if ! command -v docker &> /dev/null; then
    print_error "Docker não está instalado!"
    exit 1
fi
print_status "Docker encontrado: $(docker --version)"

if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose não está instalado!"
    exit 1
fi
print_status "Docker Compose encontrado: $(docker-compose --version)"

# Verificar se está no diretório correto
if [ ! -f "docker-compose.dev.yml" ]; then
    print_error "Arquivo docker-compose.dev.yml não encontrado! Execute este script na raiz do projeto."
    exit 1
fi
print_status "Arquivos Docker encontrados"

# Verificar arquivo .env.dev
if [ ! -f "packages/backend/.env.dev" ]; then
    print_warning "Arquivo .env.dev não encontrado. Criando a partir do exemplo..."
    
    if [ -f "packages/backend/.env.dev.example" ]; then
        cp packages/backend/.env.dev.example packages/backend/.env.dev
        print_status "Arquivo .env.dev criado"
        print_warning "IMPORTANTE: Edite packages/backend/.env.dev com suas chaves de API reais!"
    else
        print_error "Arquivo .env.dev.example não encontrado!"
        exit 1
    fi
else
    print_status "Arquivo .env.dev encontrado"
fi

# Testar build das imagens
echo ""
echo "🔨 Testando build das imagens Docker..."

if docker-compose -f docker-compose.dev.yml build --quiet; then
    print_status "Build das imagens concluído com sucesso"
else
    print_error "Falha no build das imagens"
    exit 1
fi

# Iniciar serviços
echo ""
echo "🚀 Iniciando serviços..."

# Parar qualquer instância anterior
docker-compose -f docker-compose.dev.yml down > /dev/null 2>&1 || true

# Iniciar em background
if docker-compose -f docker-compose.dev.yml up -d; then
    print_status "Serviços iniciados"
else
    print_error "Falha ao iniciar serviços"
    exit 1
fi

# Aguardar serviços ficarem prontos
echo ""
echo "⏳ Aguardando serviços ficarem prontos..."

sleep 10

# Verificar se os contêineres estão rodando
CONTAINERS=("litigo-postgres-dev" "litigo-redis-dev" "litigo-api-dev")

for container in "${CONTAINERS[@]}"; do
    if docker ps --format "table {{.Names}}" | grep -q "$container"; then
        print_status "Contêiner $container está rodando"
    else
        print_error "Contêiner $container não está rodando"
        print_warning "Logs do $container:"
        docker-compose -f docker-compose.dev.yml logs "$container" | tail -10
    fi
done

# Testar conectividade dos serviços
echo ""
echo "🔍 Testando conectividade dos serviços..."

# Testar PostgreSQL
if docker-compose -f docker-compose.dev.yml exec -T database pg_isready -U litigo > /dev/null 2>&1; then
    print_status "PostgreSQL está acessível"
else
    print_error "PostgreSQL não está acessível"
fi

# Testar Redis
if docker-compose -f docker-compose.dev.yml exec -T redis redis-cli -a redispassword ping > /dev/null 2>&1; then
    print_status "Redis está acessível"
else
    print_error "Redis não está acessível"
fi

# Testar API
echo "🌐 Testando endpoints da API..."

# Aguardar mais um pouco para a API estar pronta
sleep 5

# Teste do health check
if curl -s -f http://localhost:8000/health > /dev/null 2>&1; then
    print_status "API Health Check passou"
else
    print_warning "API Health Check falhou - pode ser normal na primeira execução"
fi

# Teste da documentação
if curl -s -f http://localhost:8000/docs > /dev/null 2>&1; then
    print_status "Documentação da API está acessível"
else
    print_warning "Documentação da API não está acessível"
fi

# Testar migração do banco
echo ""
echo "📊 Testando migrações do banco..."

if docker-compose -f docker-compose.dev.yml exec -T api alembic upgrade head > /dev/null 2>&1; then
    print_status "Migrações aplicadas com sucesso"
else
    print_warning "Falha ao aplicar migrações - verifique os logs"
fi

# Mostrar informações úteis
echo ""
echo "📋 Informações úteis:"
echo "====================="
echo "🌐 API:                 http://localhost:8000"
echo "📚 Documentação:        http://localhost:8000/docs"
echo "🏥 Health Check:        http://localhost:8000/health"
echo "🗄️  Admin do Banco:      http://localhost:8080"
echo "🌸 Monitor Celery:      http://localhost:5555"
echo ""
echo "📋 Comandos úteis:"
echo "=================="
echo "# Ver logs:"
echo "docker-compose -f docker-compose.dev.yml logs -f"
echo ""
echo "# Parar ambiente:"
echo "docker-compose -f docker-compose.dev.yml down"
echo ""
echo "# Reset completo:"
echo "docker-compose -f docker-compose.dev.yml down -v"

# Teste opcional com monitoramento
if docker ps --format "table {{.Names}}" | grep -q "litigo-flower-dev"; then
    print_status "Flower (monitoramento Celery) está rodando"
else
    print_warning "Flower não está rodando. Para habilitá-lo:"
    echo "docker-compose -f docker-compose.dev.yml --profile monitoring up -d"
fi

echo ""
print_status "Teste do ambiente Docker concluído!"
print_warning "Não esqueça de configurar suas chaves de API em packages/backend/.env.dev"

# Manter rodando ou parar?
read -p "Deseja manter o ambiente rodando? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "🛑 Parando serviços..."
    docker-compose -f docker-compose.dev.yml down
    print_status "Ambiente parado"
else
    print_status "Ambiente mantido rodando"
    echo "Use 'docker-compose -f docker-compose.dev.yml down' para parar"
fi 