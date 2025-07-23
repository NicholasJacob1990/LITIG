#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Teste de Migração Unipile - Script de Verificação
=================================================

Script para testar a migração do wrapper Node.js para o SDK oficial Python,
verificando a camada de compatibilidade e funcionalidades.

Funcionalidades testadas:
- Health check dos serviços
- Listagem de contas/conexões
- Operações de calendário (se disponível)
- Operações de email/messaging (se disponível)
- Switching entre serviços
- Performance comparison
"""

import asyncio
import logging
import time
from datetime import datetime
from typing import Dict, Any, List

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Importar serviços
try:
    from packages.backend.services.unipile_compatibility_layer import (
        get_unipile_service, 
        ServiceType
    )
    COMPATIBILITY_AVAILABLE = True
except ImportError as e:
    logger.error(f"Camada de compatibilidade não disponível: {e}")
    COMPATIBILITY_AVAILABLE = False

try:
    from packages.backend.services.unipile_official_sdk import UnipileOfficialSDK
    SDK_OFFICIAL_AVAILABLE = True
except ImportError as e:
    logger.warning(f"SDK oficial não disponível: {e}")
    SDK_OFFICIAL_AVAILABLE = False

try:
    from packages.backend.services.unipile_sdk_wrapper import UnipileSDKWrapper
    WRAPPER_NODEJS_AVAILABLE = True
except ImportError as e:
    logger.warning(f"Wrapper Node.js não disponível: {e}")
    WRAPPER_NODEJS_AVAILABLE = False


class MigrationTester:
    """Testador de migração Unipile."""
    
    def __init__(self):
        self.results = []
        self.start_time = datetime.now()
    
    async def run_all_tests(self):
        """Executa todos os testes de migração."""
        logger.info("🚀 Iniciando testes de migração Unipile...")
        
        # Teste 1: Verificar disponibilidade dos serviços
        await self.test_service_availability()
        
        # Teste 2: Health check dos serviços
        await self.test_health_checks()
        
        # Teste 3: Teste da camada de compatibilidade
        if COMPATIBILITY_AVAILABLE:
            await self.test_compatibility_layer()
        
        # Teste 4: Comparação de performance
        await self.test_performance_comparison()
        
        # Teste 5: Teste de switching entre serviços
        if COMPATIBILITY_AVAILABLE:
            await self.test_service_switching()
        
        # Teste 6: Teste de funcionalidades específicas
        await self.test_specific_functionalities()
        
        # Gerar relatório final
        self.generate_final_report()
    
    async def test_service_availability(self):
        """Testa disponibilidade dos serviços."""
        logger.info("📋 Testando disponibilidade dos serviços...")
        
        test_result = {
            "test_name": "service_availability",
            "timestamp": datetime.now().isoformat(),
            "results": {
                "compatibility_layer": COMPATIBILITY_AVAILABLE,
                "sdk_official": SDK_OFFICIAL_AVAILABLE,
                "wrapper_nodejs": WRAPPER_NODEJS_AVAILABLE
            }
        }
        
        logger.info(f"✅ Camada de compatibilidade: {'Disponível' if COMPATIBILITY_AVAILABLE else 'Não disponível'}")
        logger.info(f"✅ SDK oficial: {'Disponível' if SDK_OFFICIAL_AVAILABLE else 'Não disponível'}")
        logger.info(f"✅ Wrapper Node.js: {'Disponível' if WRAPPER_NODEJS_AVAILABLE else 'Não disponível'}")
        
        self.results.append(test_result)
    
    async def test_health_checks(self):
        """Testa health check de todos os serviços."""
        logger.info("🏥 Testando health checks...")
        
        health_results = {}
        
        # Teste SDK oficial
        if SDK_OFFICIAL_AVAILABLE:
            try:
                import os
                api_key = os.getenv("UNIPILE_API_TOKEN") or os.getenv("UNIFIED_API_KEY")
                if api_key:
                    sdk = UnipileOfficialSDK(api_key=api_key)
                    start_time = time.time()
                    health = await sdk.health_check()
                    response_time = (time.time() - start_time) * 1000
                    
                    health_results["sdk_official"] = {
                        "status": health.get("status"),
                        "response_time_ms": response_time,
                        "success": health.get("success", False) or health.get("status") == "healthy"
                    }
                else:
                    health_results["sdk_official"] = {
                        "status": "no_api_key",
                        "success": False
                    }
            except Exception as e:
                health_results["sdk_official"] = {
                    "status": "error",
                    "error": str(e),
                    "success": False
                }
        
        # Teste wrapper Node.js
        if WRAPPER_NODEJS_AVAILABLE:
            try:
                wrapper = UnipileSDKWrapper()
                start_time = time.time()
                health = await wrapper.health_check()
                response_time = (time.time() - start_time) * 1000
                
                health_results["wrapper_nodejs"] = {
                    "status": health.get("status"),
                    "response_time_ms": response_time,
                    "success": health.get("success", False)
                }
            except Exception as e:
                health_results["wrapper_nodejs"] = {
                    "status": "error",
                    "error": str(e),
                    "success": False
                }
        
        # Teste camada de compatibilidade
        if COMPATIBILITY_AVAILABLE:
            try:
                service = get_unipile_service()
                start_time = time.time()
                health = await service.health_check()
                response_time = (time.time() - start_time) * 1000
                
                health_results["compatibility_layer"] = {
                    "status": health.get("status"),
                    "response_time_ms": response_time,
                    "success": health.get("status") in ["healthy", "ok"],
                    "service_used": health.get("service_used")
                }
            except Exception as e:
                health_results["compatibility_layer"] = {
                    "status": "error",
                    "error": str(e),
                    "success": False
                }
        
        test_result = {
            "test_name": "health_checks",
            "timestamp": datetime.now().isoformat(),
            "results": health_results
        }
        
        for service, result in health_results.items():
            status = "✅" if result.get("success") else "❌"
            logger.info(f"{status} {service}: {result.get('status')} ({result.get('response_time_ms', 0):.1f}ms)")
        
        self.results.append(test_result)
    
    async def test_compatibility_layer(self):
        """Testa funcionalidades da camada de compatibilidade."""
        logger.info("🔄 Testando camada de compatibilidade...")
        
        try:
            service = get_unipile_service()
            
            # Teste 1: Listar contas
            start_time = time.time()
            accounts = await service.list_accounts()
            accounts_time = (time.time() - start_time) * 1000
            
            # Teste 2: Health check
            start_time = time.time()
            health = await service.health_check()
            health_time = (time.time() - start_time) * 1000
            
            # Teste 3: Métricas
            start_time = time.time()
            metrics = await service.get_service_metrics()
            metrics_time = (time.time() - start_time) * 1000
            
            test_result = {
                "test_name": "compatibility_layer",
                "timestamp": datetime.now().isoformat(),
                "results": {
                    "accounts": {
                        "count": len(accounts),
                        "response_time_ms": accounts_time,
                        "success": True
                    },
                    "health": {
                        "status": health.get("status"),
                        "service_used": health.get("service_used"),
                        "response_time_ms": health_time,
                        "success": health.get("status") in ["healthy", "ok"]
                    },
                    "metrics": {
                        "response_time_ms": metrics_time,
                        "preferred_service": metrics.get("preferred_service"),
                        "success": True
                    }
                }
            }
            
            logger.info(f"✅ Contas: {len(accounts)} encontradas ({accounts_time:.1f}ms)")
            logger.info(f"✅ Health: {health.get('status')} via {health.get('service_used')} ({health_time:.1f}ms)")
            logger.info(f"✅ Métricas: Serviço preferido {metrics.get('preferred_service')} ({metrics_time:.1f}ms)")
            
        except Exception as e:
            test_result = {
                "test_name": "compatibility_layer",
                "timestamp": datetime.now().isoformat(),
                "results": {
                    "error": str(e),
                    "success": False
                }
            }
            logger.error(f"❌ Erro na camada de compatibilidade: {e}")
        
        self.results.append(test_result)
    
    async def test_performance_comparison(self):
        """Compara performance entre serviços."""
        logger.info("⚡ Testando comparação de performance...")
        
        performance_results = {}
        
        # Testar cada serviço individualmente se disponível
        services_to_test = []
        
        if SDK_OFFICIAL_AVAILABLE:
            try:
                import os
                api_key = os.getenv("UNIPILE_API_TOKEN") or os.getenv("UNIFIED_API_KEY")
                if api_key:
                    sdk = UnipileOfficialSDK(api_key=api_key)
                    services_to_test.append(("sdk_official", sdk))
            except:
                pass
        
        if WRAPPER_NODEJS_AVAILABLE:
            try:
                wrapper = UnipileSDKWrapper()
                services_to_test.append(("wrapper_nodejs", wrapper))
            except:
                pass
        
        # Executar testes de performance
        for service_name, service in services_to_test:
            try:
                # Executar health check 3 vezes e calcular média
                times = []
                for i in range(3):
                    start_time = time.time()
                    await service.health_check()
                    times.append((time.time() - start_time) * 1000)
                
                avg_time = sum(times) / len(times)
                min_time = min(times)
                max_time = max(times)
                
                performance_results[service_name] = {
                    "avg_response_time_ms": avg_time,
                    "min_response_time_ms": min_time,
                    "max_response_time_ms": max_time,
                    "tests_count": len(times),
                    "success": True
                }
                
                logger.info(f"⚡ {service_name}: Avg {avg_time:.1f}ms (Min: {min_time:.1f}ms, Max: {max_time:.1f}ms)")
                
            except Exception as e:
                performance_results[service_name] = {
                    "error": str(e),
                    "success": False
                }
                logger.error(f"❌ {service_name}: {e}")
        
        test_result = {
            "test_name": "performance_comparison",
            "timestamp": datetime.now().isoformat(),
            "results": performance_results
        }
        
        self.results.append(test_result)
    
    async def test_service_switching(self):
        """Testa switching entre serviços."""
        logger.info("🔄 Testando switching entre serviços...")
        
        try:
            service = get_unipile_service()
            
            switching_results = {}
            
            # Testar switch para cada tipo de serviço
            service_types = [ServiceType.AUTO_FALLBACK, ServiceType.SDK_OFFICIAL, ServiceType.WRAPPER_NODEJS]
            
            for service_type in service_types:
                try:
                    # Switch para o serviço
                    switch_result = await service.switch_service(service_type)
                    
                    # Testar health check após switch
                    health = await service.health_check()
                    
                    switching_results[service_type.value] = {
                        "switch_success": True,
                        "health_status": health.get("status"),
                        "service_used": health.get("service_used"),
                        "switch_timestamp": switch_result.get("timestamp")
                    }
                    
                    logger.info(f"✅ Switch para {service_type.value}: {health.get('service_used')}")
                    
                except Exception as e:
                    switching_results[service_type.value] = {
                        "switch_success": False,
                        "error": str(e)
                    }
                    logger.error(f"❌ Erro no switch para {service_type.value}: {e}")
            
            test_result = {
                "test_name": "service_switching",
                "timestamp": datetime.now().isoformat(),
                "results": switching_results
            }
            
        except Exception as e:
            test_result = {
                "test_name": "service_switching",
                "timestamp": datetime.now().isoformat(),
                "results": {
                    "error": str(e),
                    "success": False
                }
            }
            logger.error(f"❌ Erro no teste de switching: {e}")
        
        self.results.append(test_result)
    
    async def test_specific_functionalities(self):
        """Testa funcionalidades específicas se houver conexões."""
        logger.info("🧪 Testando funcionalidades específicas...")
        
        functionality_results = {}
        
        if COMPATIBILITY_AVAILABLE:
            try:
                service = get_unipile_service()
                
                # Teste de listagem de contas (sempre disponível)
                accounts = await service.list_accounts()
                functionality_results["list_accounts"] = {
                    "count": len(accounts),
                    "success": True
                }
                
                # Se há contas, testar outras funcionalidades
                if accounts:
                    first_account = accounts[0]
                    account_id = first_account.id if hasattr(first_account, 'id') else first_account.get("id")
                    
                    if account_id:
                        # Teste listagem de eventos de calendário
                        try:
                            events = await service.list_calendar_events(account_id)
                            functionality_results["calendar_events"] = {
                                "count": len(events),
                                "success": True
                            }
                            logger.info(f"📅 Calendário: {len(events)} eventos encontrados")
                        except Exception as e:
                            functionality_results["calendar_events"] = {
                                "error": str(e),
                                "success": False
                            }
                        
                        # Teste listagem de emails
                        try:
                            emails = await service.list_emails(account_id)
                            functionality_results["emails"] = {
                                "count": len(emails),
                                "success": True
                            }
                            logger.info(f"📧 Emails: {len(emails)} mensagens encontradas")
                        except Exception as e:
                            functionality_results["emails"] = {
                                "error": str(e),
                                "success": False
                            }
                else:
                    functionality_results["note"] = "Nenhuma conta disponível para testes específicos"
                
                logger.info(f"✅ Contas: {len(accounts)} encontradas")
                
            except Exception as e:
                functionality_results = {
                    "error": str(e),
                    "success": False
                }
                logger.error(f"❌ Erro nos testes específicos: {e}")
        
        test_result = {
            "test_name": "specific_functionalities",
            "timestamp": datetime.now().isoformat(),
            "results": functionality_results
        }
        
        self.results.append(test_result)
    
    def generate_final_report(self):
        """Gera relatório final dos testes."""
        end_time = datetime.now()
        total_time = (end_time - self.start_time).total_seconds()
        
        logger.info("=" * 80)
        logger.info("📊 RELATÓRIO FINAL DE MIGRAÇÃO UNIPILE")
        logger.info("=" * 80)
        
        logger.info(f"⏱️ Tempo total de execução: {total_time:.2f}s")
        logger.info(f"🧪 Testes executados: {len(self.results)}")
        
        # Resumir resultados por teste
        for result in self.results:
            test_name = result["test_name"]
            logger.info(f"\n📋 {test_name.replace('_', ' ').title()}:")
            
            if "results" in result:
                if isinstance(result["results"], dict):
                    for key, value in result["results"].items():
                        if isinstance(value, dict) and "success" in value:
                            status = "✅" if value["success"] else "❌"
                            logger.info(f"   {status} {key}")
                        else:
                            logger.info(f"   📌 {key}: {value}")
        
        # Recomendações finais
        logger.info("\n🎯 RECOMENDAÇÕES:")
        
        # Verificar se migração é viável
        if COMPATIBILITY_AVAILABLE:
            logger.info("✅ Camada de compatibilidade ativa - migração gradual possível")
            
            if SDK_OFFICIAL_AVAILABLE and WRAPPER_NODEJS_AVAILABLE:
                logger.info("✅ Ambos os serviços disponíveis - fallback garantido")
            elif SDK_OFFICIAL_AVAILABLE:
                logger.info("⚠️ Apenas SDK oficial disponível - verificar configuração")
            elif WRAPPER_NODEJS_AVAILABLE:
                logger.info("⚠️ Apenas wrapper Node.js disponível - instalar SDK oficial")
        else:
            logger.info("❌ Camada de compatibilidade não disponível - revisar configuração")
        
        logger.info("\n🚀 PRÓXIMOS PASSOS:")
        logger.info("1. Configurar variáveis de ambiente (UNIPILE_API_TOKEN)")
        logger.info("2. Testar endpoints /api/v2/unipile/* em staging")
        logger.info("3. Migrar rotas gradualmente para v2")
        logger.info("4. Monitorar performance em produção")
        logger.info("5. Remover wrapper Node.js quando estável")
        
        logger.info("=" * 80)


async def main():
    """Função principal."""
    tester = MigrationTester()
    await tester.run_all_tests()


if __name__ == "__main__":
    asyncio.run(main()) 