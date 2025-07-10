#!/bin/bash

# Setup para Sistema HÍBRIDO de Integração (Escavador + Jusbrasil)
# LITGO5 - Dados ricos com fallback transparente

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 SETUP HÍBRIDO - INTEGRAÇÃO ESCAVADOR + JUSBRASIL${NC}"
echo -e "${YELLOW}Fonte de dados primária: Escavador (dados ricos), Fallback: Jusbrasil (cobertura)${NC}"
echo ""

# 1. Instalar dependências
echo -e "${YELLOW}🔧 (1/5) Instalando dependências Python...${NC}"
pip3 install -r requirements.txt
pip3 install escavador==0.9.2
echo -e "${GREEN}✅ Dependências instaladas.${NC}\n"

# 2. Executar migrações do banco
echo -e "${YELLOW}🗃️  (2/5) Executando migrações do banco de dados...${NC}"
if [ -z "$DATABASE_URL" ]; then
    echo -e "${RED}❌ ERRO: DATABASE_URL não configurada no .env${NC}"
    exit 1
fi
echo "Aplicando migração realista do Jusbrasil (fallback)..."
psql "$DATABASE_URL" -f supabase/migrations/20250707000001_add_realistic_jusbrasil_fields.sql
echo "Aplicando migração híbrida do Escavador (primária)..."
psql "$DATABASE_URL" -f supabase/migrations/20250708000000_add_hybrid_escavador_fields.sql
echo -e "${GREEN}✅ Migrações aplicadas com sucesso.${NC}\n"

# 3. Testar integração com Escavador
echo -e "${YELLOW}🧪 (3/5) Testando integração com a API do Escavador...${NC}"
if [ -z "$ESCAVADOR_API_KEY" ]; then
    echo -e "${YELLOW}⚠️  AVISO: ESCAVADOR_API_KEY não configurada. O teste usará dados simulados.${NC}"
fi
python3 -c "
import asyncio, sys, os
sys.path.append(os.getcwd())
async def test():
    try:
        from backend.services.escavador_integration import main
        await main()
        print('✅ Teste da integração Escavador: SUCESSO')
    except Exception as e:
        print(f'❌ Teste da integração Escavador: FALHOU - {e}')
        return False
    return True
if not asyncio.run(test()): exit(1)
"
echo -e "${GREEN}✅ Teste da integração com Escavador concluído.${NC}\n"

# 4. Testar integração Híbrida
echo -e "${YELLOW}🔄 (4/5) Testando integração HÍBRIDA...${NC}"
python3 -c "
import asyncio, sys, os
sys.path.append(os.getcwd())
async def test():
    try:
        from backend.services.hybrid_integration import main
        await main()
        print('✅ Teste da integração híbrida: SUCESSO')
    except Exception as e:
        print(f'❌ Teste da integração híbrida: FALHOU - {e}')
        return False
    return True
if not asyncio.run(test()): exit(1)
"
echo -e "${GREEN}✅ Teste da integração híbrida concluído.${NC}\n"

# 5. Health check final
echo -e "${YELLOW}🔍 (5/5) Verificando saúde geral do sistema...${NC}"
python3 -c "
import asyncio, sys, os
sys.path.append(os.getcwd())
from backend.api.main import health_check
async def run_health_check():
    class MockRedis:
        async def ping(self): pass
    
    # Simula a dependência do Redis
    async def get_redis_mock():
        return MockRedis()

    # Injeta a dependência mockada
    app.dependency_overrides[get_redis] = get_redis_mock

    health = await health_check(redis=await get_redis_mock())
    print(f'Status: {health.status}')
    for service, status in health.services.items():
        print(f'  - {service}: {status}')
    if health.status != 'healthy':
        raise Exception('Health check falhou')

try:
    from backend.api.main import app, get_redis
    asyncio.run(run_health_check())
    print('✅ Health check da API: SUCESSO')
except Exception as e:
    print(f'❌ Health check da API: FALHOU - {e}')
    exit(1)
"
echo -e "${GREEN}✅ Health check concluído.${NC}\n"


echo -e "${GREEN}🎉 SETUP HÍBRIDO CONCLUÍDO COM SUCESSO!${NC}"
echo ""
echo -e "${BLUE}📋 PRÓXIMOS PASSOS:${NC}"
echo "1. Configure ESCAVADOR_API_KEY e JUSBRASIL_API_KEY no .env"
echo "2. Execute a API: uvicorn backend.api.main:app --reload"
echo "3. Acesse a documentação: http://localhost:8000/docs"
echo ""
echo -e "${YELLOW}⚠️  LEMBRE-SE: A qualidade dos dados depende da disponibilidade das chaves de API.${NC}" 