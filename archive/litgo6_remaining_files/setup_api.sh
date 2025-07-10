#!/bin/bash

# setup_api.sh
# Script para configurar e iniciar a API FastAPI do LITGO5

echo "🚀 LITGO5 API Setup Script"
echo "=========================="
echo

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log colorido
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Verificar se Python está disponível
if ! command -v python3 &> /dev/null; then
    log_error "Python 3 não encontrado. Instale Python 3.8+ primeiro."
    exit 1
fi

log_success "Python 3 encontrado: $(python3 --version)"

# Verificar se pip está disponível
if ! command -v pip3 &> /dev/null; then
    log_error "pip3 não encontrado. Instale pip primeiro."
    exit 1
fi

log_success "pip3 encontrado: $(pip3 --version)"

# Verificar se Docker está disponível
if ! command -v docker &> /dev/null; then
    log_warning "Docker não encontrado. Instalação manual necessária."
    DOCKER_AVAILABLE=false
else
    log_success "Docker encontrado: $(docker --version)"
    DOCKER_AVAILABLE=true
fi

# Verificar se docker-compose está disponível
if ! command -v docker-compose &> /dev/null; then
    log_warning "docker-compose não encontrado. Instalação manual necessária."
    COMPOSE_AVAILABLE=false
else
    log_success "docker-compose encontrado: $(docker-compose --version)"
    COMPOSE_AVAILABLE=true
fi

echo

# Opções de instalação
echo "📋 Opções de Instalação:"
echo "1) 🐳 Docker (Recomendado) - Instala tudo automaticamente"
echo "2) 🐍 Python Local - Instala dependências localmente"
echo "3) 🧪 Apenas Testes - Executa testes da API"
echo "4) 📖 Documentação - Abre documentação da API"
echo

read -p "Escolha uma opção (1-4): " choice

case $choice in
    1)
        if [ "$DOCKER_AVAILABLE" = false ] || [ "$COMPOSE_AVAILABLE" = false ]; then
            log_error "Docker ou docker-compose não disponível. Instale primeiro:"
            echo "  - Docker: https://docs.docker.com/get-docker/"
            echo "  - docker-compose: https://docs.docker.com/compose/install/"
            exit 1
        fi
        
        log_info "Iniciando instalação com Docker..."
        
        # Parar containers existentes
        log_info "Parando containers existentes..."
        docker-compose -f docker-compose.api.yml down 2>/dev/null || true
        
        # Build e start dos serviços
        log_info "Construindo e iniciando serviços..."
        docker-compose -f docker-compose.api.yml up -d --build
        
        if [ $? -eq 0 ]; then
            log_success "API iniciada com sucesso!"
            echo
            echo "🌐 Serviços disponíveis:"
            echo "  - API: http://localhost:8000"
            echo "  - Swagger: http://localhost:8000/docs"
            echo "  - ReDoc: http://localhost:8000/redoc"
            echo "  - Flower: http://localhost:5555"
            echo
            echo "🧪 Para testar a API:"
            echo "  python3 test_api.py"
            echo
            echo "📊 Para verificar logs:"
            echo "  docker-compose -f docker-compose.api.yml logs -f api"
        else
            log_error "Erro ao iniciar serviços. Verifique logs:"
            echo "  docker-compose -f docker-compose.api.yml logs"
        fi
        ;;
        
    2)
        log_info "Instalando dependências Python localmente..."
        
        # Criar ambiente virtual se não existir
        if [ ! -d "venv_api" ]; then
            log_info "Criando ambiente virtual..."
            python3 -m venv venv_api
        fi
        
        # Ativar ambiente virtual
        log_info "Ativando ambiente virtual..."
        source venv_api/bin/activate
        
        # Instalar dependências
        log_info "Instalando dependências..."
        pip install -r requirements.txt
        
        if [ $? -eq 0 ]; then
            log_success "Dependências instaladas com sucesso!"
            echo
            echo "🚀 Para iniciar a API:"
            echo "  source venv_api/bin/activate"
            echo "  uvicorn backend.api.main:app --reload"
            echo
            echo "📋 Requisitos para execução:"
            echo "  - PostgreSQL com pgvector rodando na porta 5432"
            echo "  - Redis rodando na porta 6379"
            echo "  - Variáveis de ambiente configuradas"
        else
            log_error "Erro ao instalar dependências. Verifique requirements.txt"
        fi
        ;;
        
    3)
        log_info "Executando testes da API..."
        
        # Verificar se httpx está instalado
        if ! python3 -c "import httpx" 2>/dev/null; then
            log_info "Instalando httpx para testes..."
            pip3 install httpx
        fi
        
        # Executar testes
        python3 test_api.py
        ;;
        
    4)
        log_info "Abrindo documentação da API..."
        
        # Verificar se a API está rodando
        if curl -s http://localhost:8000/health > /dev/null 2>&1; then
            log_success "API está rodando!"
            
            # Tentar abrir no navegador
            if command -v open &> /dev/null; then
                open http://localhost:8000/docs
            elif command -v xdg-open &> /dev/null; then
                xdg-open http://localhost:8000/docs
            else
                echo "🌐 Acesse manualmente: http://localhost:8000/docs"
            fi
        else
            log_error "API não está rodando. Inicie primeiro:"
            echo "  docker-compose -f docker-compose.api.yml up"
        fi
        ;;
        
    *)
        log_error "Opção inválida. Escolha 1-4."
        exit 1
        ;;
esac

echo
echo "📖 Documentação completa: API_FASTAPI_COMPLETA.md"
echo "🤝 Suporte: Verifique os logs para troubleshooting"
echo
echo "🎉 Setup concluído!" 