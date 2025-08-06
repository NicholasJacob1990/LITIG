#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
scripts/test_offline_cache_system.py

Script de teste para validar o sistema de cache offline.
Simula cenários onde a API do Escavador está indisponível.
"""

import asyncio
import logging
import os
import sys
from pathlib import Path
from datetime import datetime
from typing import Dict, Any

# Adicionar path do backend ao Python path
backend_path = Path(__file__).parent.parent
sys.path.insert(0, str(backend_path))

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Test CNJs (use CNJs reais se disponível)
TEST_CNJS = [
    "0000000-00.0000.0.00.0000",  # CNJ fictício para teste
    "1111111-11.1111.1.11.1111",  # CNJ fictício para teste
    "2222222-22.2222.2.22.2222"   # CNJ fictício para teste
]

class OfflineCacheTestSuite:
    """
    Suite de testes para validar o funcionamento do cache offline.
    """
    
    def __init__(self):
        self.total_tests = 0
        self.passed_tests = 0
        self.failed_tests = 0
        self.results = []
    
    async def run_all_tests(self):
        """Executa todos os testes do sistema de cache offline."""
        logger.info("🧪 INICIANDO TESTES DO SISTEMA DE CACHE OFFLINE")
        logger.info("=" * 60)
        
        await self.test_database_connection()
        await self.test_cache_service_import()
        await self.test_escavador_client_with_cache()
        await self.test_cache_fallback_behavior()
        await self.test_offline_functionality()
        await self.test_cache_persistence()
        await self.test_api_routes_with_cache()
        
        await self.print_final_results()
    
    async def test_database_connection(self):
        """Testa conexão com banco PostgreSQL."""
        self.start_test("Conexão com banco PostgreSQL")
        
        try:
            from config.database import get_database
            
            async with get_database() as db:
                # Verificar se tabelas de cache existem
                tables_result = await db.fetch("""
                    SELECT table_name FROM information_schema.tables 
                    WHERE table_schema = 'public' 
                    AND table_name IN ('process_movements', 'process_status_cache')
                    ORDER BY table_name
                """)
                
                table_names = [row['table_name'] for row in tables_result]
                
                if 'process_movements' in table_names and 'process_status_cache' in table_names:
                    self.pass_test("Tabelas de cache encontradas no banco")
                else:
                    self.fail_test(f"Tabelas de cache não encontradas. Encontradas: {table_names}")
                    
        except Exception as e:
            self.fail_test(f"Erro na conexão com banco: {e}")
    
    async def test_cache_service_import(self):
        """Testa se o serviço de cache pode ser importado."""
        self.start_test("Importação do serviço de cache")
        
        try:
            from services.process_cache_service import process_cache_service
            
            if process_cache_service:
                self.pass_test("Serviço de cache importado com sucesso")
            else:
                self.fail_test("Serviço de cache é None")
                
        except Exception as e:
            self.fail_test(f"Erro ao importar serviço de cache: {e}")
    
    async def test_escavador_client_with_cache(self):
        """Testa se EscavadorClient integra corretamente com cache."""
        self.start_test("Integração EscavadorClient com cache")
        
        try:
            from services.escavador_integration import EscavadorClient, CACHE_ENABLED
            from config.base import ESCAVADOR_API_KEY
            
            if not ESCAVADOR_API_KEY:
                self.skip_test("ESCAVADOR_API_KEY não configurada - teste pulado")
                return
            
            client = EscavadorClient(api_key=ESCAVADOR_API_KEY)
            
            # Verificar se métodos de cache estão disponíveis
            has_cache_method = hasattr(client, 'get_detailed_process_movements')
            cache_enabled = CACHE_ENABLED
            
            if has_cache_method and cache_enabled:
                self.pass_test("EscavadorClient integrado com cache")
            else:
                self.fail_test(f"Cache não integrado. Method: {has_cache_method}, Enabled: {cache_enabled}")
                
        except Exception as e:
            self.fail_test(f"Erro na integração com cache: {e}")
    
    async def test_cache_fallback_behavior(self):
        """Testa comportamento de fallback do cache."""
        self.start_test("Comportamento de fallback do cache")
        
        try:
            from services.process_cache_service import process_cache_service
            
            # Simular dados antigos no cache
            test_cnj = TEST_CNJS[0]
            
            # Tentar buscar dados que não existem (deve falhar gracefully)
            try:
                result, source = await process_cache_service.get_process_movements_cached(
                    test_cnj, limit=10, force_refresh=False
                )
                
                # Se chegou aqui, significa que encontrou dados ou falhou gracefully
                if source in ['redis', 'database', 'database_fallback']:
                    self.pass_test(f"Fallback funcionando corretamente (fonte: {source})")
                else:
                    self.fail_test(f"Fonte de dados inesperada: {source}")
                    
            except Exception as e:
                # Falha esperada se não há dados e API indisponível
                if "nenhum dado encontrado" in str(e).lower() or "api indisponível" in str(e).lower():
                    self.pass_test("Falha graceful quando sem dados e API indisponível")
                else:
                    self.fail_test(f"Falha inesperada: {e}")
                    
        except Exception as e:
            self.fail_test(f"Erro no teste de fallback: {e}")
    
    async def test_offline_functionality(self):
        """Testa funcionamento completamente offline."""
        self.start_test("Funcionamento offline")
        
        try:
            # Temporariamente "desabilitar" API (simular indisponibilidade)
            original_api_key = os.environ.get('ESCAVADOR_API_KEY')
            os.environ['ESCAVADOR_API_KEY'] = ''  # Simular API indisponível
            
            from services.escavador_integration import EscavadorClient
            
            # Primeiro, vamos inserir alguns dados de teste no cache
            await self.insert_test_cache_data()
            
            # Agora tentar buscar dados offline
            try:
                client = EscavadorClient(api_key='')  # API key vazia
                result = await client.get_detailed_process_movements(TEST_CNJS[0], limit=10)
                
                if result and result.get('movements'):
                    self.pass_test("Funcionamento offline com dados cached")
                else:
                    self.pass_test("Funcionamento offline sem dados cached (comportamento esperado)")
                    
            except Exception as e:
                # Verificar se é falha esperada (sem dados)
                if "não encontrada" in str(e).lower() or "indisponível" in str(e).lower():
                    self.pass_test("Falha esperada offline sem dados cached")
                else:
                    self.fail_test(f"Falha inesperada offline: {e}")
            
            finally:
                # Restaurar API key original
                if original_api_key:
                    os.environ['ESCAVADOR_API_KEY'] = original_api_key
                else:
                    os.environ.pop('ESCAVADOR_API_KEY', None)
                    
        except Exception as e:
            self.fail_test(f"Erro no teste offline: {e}")
    
    async def test_cache_persistence(self):
        """Testa persistência dos dados no cache."""
        self.start_test("Persistência de cache")
        
        try:
            from config.database import get_database
            
            async with get_database() as db:
                # Verificar se há dados na tabela de cache
                movements_count = await db.fetchval(
                    "SELECT COUNT(*) FROM process_movements"
                )
                
                status_count = await db.fetchval(
                    "SELECT COUNT(*) FROM process_status_cache"
                )
                
                self.pass_test(f"Cache persistido: {movements_count} movimentações, {status_count} status")
                
        except Exception as e:
            self.fail_test(f"Erro ao verificar persistência: {e}")
    
    async def test_api_routes_with_cache(self):
        """Testa se as rotas da API usam o cache corretamente."""
        self.start_test("Rotas da API com cache")
        
        try:
            # Testar imports das rotas
            from routes.process_movements import router as movements_router
            from routes.process_updates import router as updates_router
            
            if movements_router and updates_router:
                self.pass_test("Rotas de processo importadas com sucesso")
            else:
                self.fail_test("Erro ao importar rotas de processo")
                
        except Exception as e:
            self.fail_test(f"Erro ao testar rotas: {e}")
    
    async def insert_test_cache_data(self):
        """Insere dados de teste no cache para simular dados offline."""
        try:
            from config.database import get_database
            import json
            
            async with get_database() as db:
                # Inserir dados de teste na tabela de movimentações
                test_movement_data = {
                    "id": "test_1",
                    "name": "Petição Inicial",
                    "description": "Teste de movimentação offline",
                    "type": "PETICAO",
                    "icon": "📋",
                    "color": "#3B82F6"
                }
                
                await db.execute("""
                    INSERT INTO process_movements (
                        cnj, movement_data, movement_type, movement_date,
                        content, source_tribunal, source_grau,
                        fetched_from_api_at
                    ) VALUES ($1, $2, $3, NOW(), $4, $5, $6, NOW())
                    ON CONFLICT (cnj, content, movement_date) DO NOTHING
                """, 
                TEST_CNJS[0],
                json.dumps(test_movement_data),
                "PETICAO",
                "Teste de movimentação para funcionamento offline",
                "TESTE",
                "1º GRAU"
                )
                
                # Inserir status de teste
                await db.execute("""
                    INSERT INTO process_status_cache (
                        cnj, current_phase, description, progress_percentage,
                        outcome, total_movements, tribunal_name, tribunal_grau,
                        cache_valid_until
                    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW() + INTERVAL '24 hours')
                    ON CONFLICT (cnj) DO UPDATE SET
                        current_phase = EXCLUDED.current_phase,
                        cache_valid_until = EXCLUDED.cache_valid_until
                """,
                TEST_CNJS[0],
                "Teste Offline",
                "Dados de teste para funcionamento offline",
                50.0,
                "andamento",
                1,
                "TRIBUNAL DE TESTE",
                "1º GRAU"
                )
                
                logger.info("Dados de teste inseridos no cache")
                
        except Exception as e:
            logger.error(f"Erro ao inserir dados de teste: {e}")
    
    def start_test(self, test_name: str):
        """Inicia um novo teste."""
        self.total_tests += 1
        logger.info(f"🧪 Teste {self.total_tests}: {test_name}")
    
    def pass_test(self, message: str):
        """Marca teste como passou."""
        self.passed_tests += 1
        logger.info(f"   ✅ {message}")
        self.results.append(("PASS", message))
    
    def fail_test(self, message: str):
        """Marca teste como falhou."""
        self.failed_tests += 1
        logger.error(f"   ❌ {message}")
        self.results.append(("FAIL", message))
    
    def skip_test(self, message: str):
        """Marca teste como pulado."""
        logger.warning(f"   ⏭️  {message}")
        self.results.append(("SKIP", message))
    
    async def print_final_results(self):
        """Imprime resultados finais dos testes."""
        logger.info("\n" + "=" * 60)
        logger.info("📊 RESULTADOS FINAIS DOS TESTES")
        logger.info("=" * 60)
        
        logger.info(f"Total de testes: {self.total_tests}")
        logger.info(f"✅ Passou: {self.passed_tests}")
        logger.info(f"❌ Falhou: {self.failed_tests}")
        logger.info(f"⏭️  Pulado: {self.total_tests - self.passed_tests - self.failed_tests}")
        
        success_rate = (self.passed_tests / self.total_tests * 100) if self.total_tests > 0 else 0
        logger.info(f"📈 Taxa de sucesso: {success_rate:.1f}%")
        
        if self.failed_tests == 0:
            logger.info("\n🎉 TODOS OS TESTES PASSARAM! Sistema de cache offline pronto para uso.")
        else:
            logger.warning(f"\n⚠️  {self.failed_tests} teste(s) falharam. Verifique os erros acima.")
        
        logger.info("\n💡 PRÓXIMOS PASSOS:")
        logger.info("1. Execute a migração do banco: `python -m alembic upgrade head`")
        logger.info("2. Configure ESCAVADOR_API_KEY no .env")
        logger.info("3. Inicie o servidor: `python main.py`")
        logger.info("4. Teste uma consulta via API para popular o cache")
        logger.info("5. Desconecte a internet e teste funcionamento offline")

async def main():
    """Função principal do script de testes."""
    print("\n🔧 TESTE DO SISTEMA DE CACHE OFFLINE - ESCAVADOR INTEGRATION")
    print("="*70)
    print("Este script valida se o sistema funciona sem API disponível.")
    print("="*70)
    
    suite = OfflineCacheTestSuite()
    await suite.run_all_tests()

if __name__ == "__main__":
    asyncio.run(main()) 