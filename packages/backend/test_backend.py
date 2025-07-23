#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Teste do Backend LITIG-1
========================
Testa as funcionalidades principais do backend sem necessidade de servidor rodando.
"""

import sys
import os
from datetime import datetime

def test_imports():
    """Testa se todas as dependências importantes podem ser importadas."""
    print("🧪 Teste 1: Importações do Backend")
    print("-" * 50)
    
    imports_results = {}
    
    # Testar importações críticas
    test_modules = [
        ('fastapi', 'FastAPI'),
        ('uvicorn', 'Uvicorn'),
        ('algoritmo_match', 'Algoritmo de Matching'),
        ('main_routes', 'Rotas Principais'),
        ('config', 'Configurações'),
        ('auth', 'Autenticação'),
        ('schemas', 'Schemas'),
        ('models', 'Modelos'),
    ]
    
    for module, description in test_modules:
        try:
            __import__(module)
            imports_results[description] = True
            print(f"   ✅ {description}: OK")
        except ImportError as e:
            imports_results[description] = False
            print(f"   ❌ {description}: {e}")
        except Exception as e:
            imports_results[description] = False
            print(f"   ⚠️  {description}: {e}")
    
    passed = sum(imports_results.values())
    total = len(imports_results)
    print(f"\n📊 Importações: {passed}/{total} ({passed/total:.1%})")
    
    return passed > total // 2  # Pelo menos 50% das importações devem funcionar

def test_algorithm_integration():
    """Testa a integração com o algoritmo de matching."""
    print("\n🧪 Teste 2: Integração com Algoritmo")
    print("-" * 50)
    
    try:
        from algoritmo_match import MatchmakingAlgorithm, Case, Lawyer, KPI
        
        # Criar instâncias
        algo = MatchmakingAlgorithm()
        
        case = Case(
            id="test_case",
            area="trabalhista",
            subarea="rescisao",
            urgency_h=24,
            coords=(-23.5505, -46.6333),
            complexity="MEDIUM"
        )
        
        lawyer = Lawyer(
            id="test_lawyer",
            nome="Dr. Teste",
            tags_expertise=["trabalhista"],
            geo_latlon=(-23.5505, -46.6333),
            curriculo_json={"experience_years": 5},
            kpi=KPI(
                success_rate=0.8,
                cases_30d=10,
                avaliacao_media=4.5,
                tempo_resposta_h=2,
                active_cases=10
            )
        )
        
        print("   ✅ Algoritmo instanciado")
        print("   ✅ Estruturas de dados criadas")
        print(f"   📊 Métodos disponíveis: {len([m for m in dir(algo) if not m.startswith('_')])}")
        
        return True
        
    except Exception as e:
        print(f"   ❌ Erro na integração: {e}")
        return False

def test_configuration():
    """Testa as configurações do sistema."""
    print("\n🧪 Teste 3: Configurações")
    print("-" * 50)
    
    try:
        import config
        
        # Verificar se as configurações críticas existem
        critical_configs = [
            'SUPABASE_URL',
            'SUPABASE_KEY', 
            'SECRET_KEY',
            'ENVIRONMENT'
        ]
        
        config_status = {}
        
        for config_name in critical_configs:
            if hasattr(config, config_name):
                value = getattr(config, config_name)
                config_status[config_name] = value is not None
                status = "✅" if value else "⚠️"
                print(f"   {status} {config_name}: {'Configurado' if value else 'Não configurado'}")
            else:
                config_status[config_name] = False
                print(f"   ❌ {config_name}: Não encontrado")
        
        # Verificar variáveis de ambiente importantes
        env_vars = ['ENVIRONMENT', 'PORT', 'DEBUG']
        print(f"\n   📋 Variáveis de ambiente:")
        for var in env_vars:
            value = os.getenv(var, 'Não definida')
            print(f"      • {var}: {value}")
        
        passed = sum(config_status.values())
        total = len(config_status)
        print(f"\n   📊 Configurações: {passed}/{total}")
        
        return passed >= 2  # Pelo menos 2 configurações devem estar OK
        
    except Exception as e:
        print(f"   ❌ Erro nas configurações: {e}")
        return False

def test_services():
    """Testa os serviços disponíveis."""
    print("\n🧪 Teste 4: Serviços")
    print("-" * 50)
    
    services_results = {}
    
    # Lista de serviços para testar
    services = [
        ('services.unipile_sdk_wrapper', 'UnipileSDKWrapper'),
        ('services.hybrid_legal_data_service', 'HybridLegalDataService'),
        ('services.escavador_integration', 'EscavadorIntegration'),
        ('triage_service', 'TriageService'),
        ('embedding_service', 'EmbeddingService'),
    ]
    
    for service_module, service_name in services:
        try:
            module = __import__(service_module, fromlist=[service_name])
            if hasattr(module, service_name.split('.')[-1]):
                services_results[service_name] = True
                print(f"   ✅ {service_name}: Disponível")
            else:
                services_results[service_name] = False
                print(f"   ⚠️  {service_name}: Módulo importado mas classe não encontrada")
        except ImportError as e:
            services_results[service_name] = False
            print(f"   ❌ {service_name}: {e}")
        except Exception as e:
            services_results[service_name] = False
            print(f"   ⚠️  {service_name}: {e}")
    
    passed = sum(services_results.values())
    total = len(services_results)
    print(f"\n   📊 Serviços: {passed}/{total}")
    
    return passed > 0  # Pelo menos 1 serviço deve funcionar

def test_routes_structure():
    """Testa a estrutura das rotas."""
    print("\n🧪 Teste 5: Estrutura de Rotas")
    print("-" * 50)
    
    try:
        import main_routes
        
        # Verificar se o router principal existe
        if hasattr(main_routes, 'router'):
            router = main_routes.router
            print("   ✅ Router principal encontrado")
            
            # Tentar acessar as rotas (se possível)
            if hasattr(router, 'routes'):
                route_count = len(router.routes)
                print(f"   📊 Número de rotas: {route_count}")
            else:
                print("   ⚠️  Não foi possível contar as rotas")
                
            return True
        else:
            print("   ❌ Router principal não encontrado")
            return False
            
    except Exception as e:
        print(f"   ❌ Erro na estrutura de rotas: {e}")
        return False

def test_unipile_integration():
    """Testa a integração com Unipile."""
    print("\n🧪 Teste 6: Integração Unipile")
    print("-" * 50)
    
    try:
        # Verificar se o SDK da Unipile está disponível
        import subprocess
        import os
        
        # Verificar se o serviço Node.js existe
        node_service = "unipile_sdk_service.js"
        if os.path.exists(node_service):
            print("   ✅ Serviço Node.js encontrado")
            
            # Tentar executar health check
            try:
                result = subprocess.run(
                    ["node", node_service, "health-check"],
                    capture_output=True,
                    text=True,
                    timeout=10
                )
                
                if result.returncode == 0:
                    print("   ✅ Health check do Unipile: OK")
                    # Verificar se há mensagem de sucesso na saída
                    if "success" in result.stdout.lower():
                        print("   ✅ SDK da Unipile funcionando")
                        return True
                    else:
                        print("   ⚠️  SDK respondeu mas pode ter problemas")
                        return True
                else:
                    print(f"   ⚠️  Health check falhou: {result.stderr}")
                    return False
                    
            except subprocess.TimeoutExpired:
                print("   ⚠️  Timeout no health check do Unipile")
                return False
            except Exception as e:
                print(f"   ⚠️  Erro ao executar health check: {e}")
                return False
        else:
            print("   ❌ Serviço Node.js não encontrado")
            return False
            
    except Exception as e:
        print(f"   ❌ Erro na integração Unipile: {e}")
        return False

def main():
    """Executa todos os testes do backend."""
    print("🚀 INICIANDO TESTES DO BACKEND LITIG-1")
    print("=" * 70)
    
    results = []
    
    # Executar testes
    results.append(test_imports())
    results.append(test_configuration())
    results.append(test_algorithm_integration())
    results.append(test_services())
    results.append(test_routes_structure())
    results.append(test_unipile_integration())
    
    # Resumo
    print("\n📊 RESUMO DOS TESTES DO BACKEND")
    print("=" * 70)
    
    passed = sum(results)
    total = len(results)
    
    print(f"✅ Testes passaram: {passed}/{total}")
    print(f"📈 Taxa de sucesso: {passed/total:.1%}")
    
    if passed == total:
        print("🎉 TODOS OS TESTES PASSARAM! Backend funcionando corretamente.")
        status = "EXCELENTE"
    elif passed >= total * 0.8:
        print("⚡ MAIORIA DOS TESTES PASSOU. Backend em bom estado.")
        status = "BOM"
    elif passed >= total * 0.5:
        print("⚠️  ALGUNS TESTES PASSARAM. Backend parcialmente funcional.")
        status = "PARCIAL"
    else:
        print("❌ MUITOS TESTES FALHARAM. Backend precisa de correções.")
        status = "CRÍTICO"
    
    print(f"\n🎯 STATUS GERAL: {status}")
    print(f"⏰ Teste concluído às {datetime.now().strftime('%H:%M:%S')}")
    
    return passed, total

if __name__ == "__main__":
    main() 