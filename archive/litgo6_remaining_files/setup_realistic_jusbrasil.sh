#!/bin/bash

# Setup para Sistema REALISTA de Integração Jusbrasil
# LITGO5 - Dados factíveis e transparentes

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 SETUP REALISTA - INTEGRAÇÃO JUSBRASIL${NC}"
echo -e "${YELLOW}Dados factíveis com transparência total sobre limitações${NC}"
echo ""

# Verificar se está no diretório correto
if [ ! -f "package.json" ] || [ ! -d "backend" ]; then
    echo -e "${RED}❌ Execute este script no diretório raiz do projeto LITGO5${NC}"
    exit 1
fi

# Função para mostrar menu
show_menu() {
    echo -e "${BLUE}Escolha uma opção:${NC}"
    echo "1. 🗃️  Executar migrações do banco (REALISTA)"
    echo "2. 🔧 Instalar dependências Python"
    echo "3. 🧪 Testar integração REALISTA"
    echo "4. 📊 Executar sincronização manual"
    echo "5. 🔍 Health check do sistema"
    echo "6. 📚 Ver documentação das limitações"
    echo "7. 🏃 Executar TUDO (setup completo)"
    echo "8. ❌ Sair"
    echo ""
}

# Função para executar migrações
run_migrations() {
    echo -e "${YELLOW}🗃️  Executando migrações REALISTAS...${NC}"
    
    # Verificar se PostgreSQL está rodando
    if ! command -v psql &> /dev/null; then
        echo -e "${RED}❌ PostgreSQL não encontrado. Instale o PostgreSQL primeiro.${NC}"
        return 1
    fi
    
    # Verificar variável de ambiente
    if [ -z "$DATABASE_URL" ]; then
        echo -e "${RED}❌ DATABASE_URL não configurada${NC}"
        echo "Configure no .env: DATABASE_URL=postgresql://user:pass@localhost/dbname"
        return 1
    fi
    
    # Executar migração
    echo "Aplicando migração de campos REALISTAS..."
    psql "$DATABASE_URL" -f supabase/migrations/20250707000001_add_realistic_jusbrasil_fields.sql
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Migrações aplicadas com sucesso${NC}"
    else
        echo -e "${RED}❌ Erro ao aplicar migrações${NC}"
        return 1
    fi
}

# Função para instalar dependências
install_dependencies() {
    echo -e "${YELLOW}🔧 Instalando dependências Python...${NC}"
    
    # Verificar se Python está instalado
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}❌ Python 3 não encontrado${NC}"
        return 1
    fi
    
    # Instalar dependências principais
    pip3 install -r requirements.txt
    
    # Dependências específicas para integração realista
    pip3 install \
        fastapi==0.104.1 \
        uvicorn[standard]==0.24.0 \
        aioredis==5.0.1 \
        psycopg2-binary==2.9.9 \
        httpx==0.25.2 \
        tenacity==8.2.3 \
        sentence-transformers==2.2.2 \
        python-dotenv==1.0.0
    
    echo -e "${GREEN}✅ Dependências instaladas${NC}"
}

# Função para testar integração
test_integration() {
    echo -e "${YELLOW}🧪 Testando integração REALISTA...${NC}"
    
    # Testar cliente realista
    python3 -c "
import asyncio
import sys
import os

# Adicionar path do backend
sys.path.append(os.path.join(os.getcwd(), 'backend'))

async def test():
    try:
        from services.jusbrasil_integration_realistic import demo_realistic_integration
        await demo_realistic_integration()
        print('✅ Teste da integração realista: SUCESSO')
    except Exception as e:
        print(f'❌ Teste da integração realista: FALHOU - {e}')
        return False
    return True

result = asyncio.run(test())
sys.exit(0 if result else 1)
"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Integração REALISTA funcionando${NC}"
    else
        echo -e "${RED}❌ Falha na integração REALISTA${NC}"
        return 1
    fi
}

# Função para executar sincronização manual
run_sync() {
    echo -e "${YELLOW}📊 Executando sincronização manual REALISTA...${NC}"
    
    python3 -c "
import asyncio
import sys
import os

sys.path.append(os.path.join(os.getcwd(), 'backend'))

async def sync():
    try:
        from jobs.jusbrasil_sync_realistic import main
        await main()
        print('✅ Sincronização realista: CONCLUÍDA')
    except Exception as e:
        print(f'❌ Sincronização realista: FALHOU - {e}')
        return False
    return True

result = asyncio.run(sync())
sys.exit(0 if result else 1)
"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Sincronização REALISTA concluída${NC}"
    else
        echo -e "${RED}❌ Falha na sincronização${NC}"
        return 1
    fi
}

# Função para health check
health_check() {
    echo -e "${YELLOW}🔍 Verificando saúde do sistema...${NC}"
    
    # Verificar PostgreSQL
    echo "Testando PostgreSQL..."
    if psql "$DATABASE_URL" -c "SELECT 1;" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PostgreSQL: OK${NC}"
    else
        echo -e "${RED}❌ PostgreSQL: FALHA${NC}"
    fi
    
    # Verificar Redis (opcional)
    echo "Testando Redis..."
    if command -v redis-cli &> /dev/null && redis-cli ping > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Redis: OK${NC}"
    else
        echo -e "${YELLOW}⚠️  Redis: INDISPONÍVEL (opcional)${NC}"
    fi
    
    # Verificar dependências Python
    echo "Verificando dependências Python..."
    python3 -c "
try:
    import fastapi, aioredis, psycopg2, httpx, tenacity
    print('✅ Dependências Python: OK')
except ImportError as e:
    print(f'❌ Dependências Python: FALTANDO - {e}')
    exit(1)
"
    
    # Verificar estrutura do banco
    echo "Verificando estrutura do banco..."
    psql "$DATABASE_URL" -c "
    SELECT 
        CASE 
            WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'lawyers' AND column_name = 'estimated_success_rate') 
            THEN '✅ Campos REALISTAS: OK'
            ELSE '❌ Campos REALISTAS: FALTANDO'
        END as status;
    "
}

# Função para mostrar documentação
show_documentation() {
    echo -e "${BLUE}📚 DOCUMENTAÇÃO - LIMITAÇÕES DOS DADOS JUSBRASIL${NC}"
    echo ""
    echo -e "${YELLOW}🚫 LIMITAÇÕES CONHECIDAS DA API JUSBRASIL:${NC}"
    echo "1. ❌ Não categoriza vitórias/derrotas automaticamente"
    echo "2. ❌ Processos em segredo de justiça não são retornados"
    echo "3. ❌ Processos trabalhistas do autor não retornados (anti-discriminação)"
    echo "4. ❌ Apenas processos não atualizados há +4 dias"
    echo "5. ❌ Foco em monitoramento empresarial, não performance de advogados"
    echo ""
    echo -e "${GREEN}✅ DADOS DISPONÍVEIS (REALISTAS):${NC}"
    echo "1. ✅ Volume total de processos por advogado"
    echo "2. ✅ Distribuição por área jurídica"
    echo "3. ✅ Distribuição por tribunal"
    echo "4. ✅ Informações básicas dos processos"
    echo "5. ✅ Valores de ação (quando disponíveis)"
    echo ""
    echo -e "${BLUE}🎯 ESTRATÉGIA REALISTA IMPLEMENTADA:${NC}"
    echo "1. 📊 Coleta apenas dados factíveis"
    echo "2. 🧮 Usa heurísticas para estimar performance"
    echo "3. 🏷️  Calcula scores de especialização por área"
    echo "4. 📈 Determina nível de atividade do advogado"
    echo "5. ⚠️  Transparência total sobre limitações"
    echo ""
    echo -e "${YELLOW}💡 USO RECOMENDADO:${NC}"
    echo "- ✅ Matching por experiência e volume"
    echo "- ✅ Análise de especialização por área"
    echo "- ✅ Avaliação de atividade profissional"
    echo "- ❌ NÃO usar para análise de performance real"
    echo "- ❌ NÃO assumir dados de vitórias/derrotas"
    echo ""
    echo "Pressione ENTER para continuar..."
    read
}

# Função para setup completo
setup_all() {
    echo -e "${BLUE}🏃 EXECUTANDO SETUP COMPLETO REALISTA...${NC}"
    echo ""
    
    echo "1/5 - Instalando dependências..."
    install_dependencies
    echo ""
    
    echo "2/5 - Executando migrações..."
    run_migrations
    echo ""
    
    echo "3/5 - Testando integração..."
    test_integration
    echo ""
    
    echo "4/5 - Executando health check..."
    health_check
    echo ""
    
    echo "5/5 - Executando sincronização de teste..."
    run_sync
    echo ""
    
    echo -e "${GREEN}🎉 SETUP REALISTA CONCLUÍDO COM SUCESSO!${NC}"
    echo ""
    echo -e "${BLUE}📋 PRÓXIMOS PASSOS:${NC}"
    echo "1. Configure JUSBRASIL_API_KEY no .env (se disponível)"
    echo "2. Execute a API: python3 backend/api/main.py"
    echo "3. Acesse a documentação: http://localhost:8000/docs"
    echo "4. Execute testes: python3 test_api.py"
    echo ""
    echo -e "${YELLOW}⚠️  LEMBRE-SE:${NC}"
    echo "- Dados são estimativas, não performance real"
    echo "- Transparência total sobre limitações"
    echo "- Adequado para matching por experiência"
}

# Loop principal
while true; do
    show_menu
    read -p "Digite sua escolha (1-8): " choice
    echo ""
    
    case $choice in
        1)
            run_migrations
            ;;
        2)
            install_dependencies
            ;;
        3)
            test_integration
            ;;
        4)
            run_sync
            ;;
        5)
            health_check
            ;;
        6)
            show_documentation
            ;;
        7)
            setup_all
            ;;
        8)
            echo -e "${GREEN}👋 Obrigado por usar o LITGO5 REALISTA!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Opção inválida. Tente novamente.${NC}"
            ;;
    esac
    echo ""
    echo "Pressione ENTER para continuar..."
    read
    clear
done 