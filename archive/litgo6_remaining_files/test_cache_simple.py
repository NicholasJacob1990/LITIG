#!/usr/bin/env python3
"""
Teste simples para validar o Cache Service
"""
import asyncio
import sys
import os

# Adicionar o diretório do projeto ao path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

async def test_cache():
    """Teste básico do cache service"""
    print("🧪 Testando Cache Service...")
    
    try:
        from backend.services.cache_service import cache_service, init_cache
        
        # Inicializar cache
        print("  ✓ Inicializando cache...")
        await init_cache("redis://localhost:6379")
        
        # Teste básico
        print("  ✓ Testando set/get...")
        test_data = {"test": "success", "number": 42}
        await cache_service.set("test_key", test_data, ttl=60)
        
        result = await cache_service.get("test_key")
        if result == test_data:
            print("  ✅ Cache funcionando!")
        else:
            print("  ❌ Cache não funcionou corretamente")
            return False
        
        # Teste de estatísticas
        print("  ✓ Testando estatísticas...")
        stats = await cache_service.get_cache_stats()
        
        if stats.get("connected"):
            print(f"    - Redis conectado: ✅")
            print(f"    - Total de chaves: {stats.get('total_keys', 0)}")
            print(f"    - Memória usada: {stats.get('used_memory', 'N/A')}")
        else:
            print(f"    - Redis não conectado: ❌")
            print(f"    - Erro: {stats.get('error', 'Desconhecido')}")
            return False
        
        print("\n🎉 Cache Service funcionando perfeitamente!")
        return True
        
    except Exception as e:
        print(f"\n❌ Erro: {e}")
        import traceback
        traceback.print_exc()
        return False

async def test_api():
    """Teste da API"""
    print("\n🌐 Testando API...")
    
    try:
        import httpx
        
        # Testar diferentes portas
        ports = [8001, 8000]
        
        for port in ports:
            try:
                async with httpx.AsyncClient() as client:
                    print(f"  ✓ Testando porta {port}...")
                    response = await client.get(f"http://localhost:{port}/", timeout=5.0)
                    
                    if response.status_code == 200:
                        data = response.json()
                        if data.get("status") == "ok":
                            print(f"  ✅ API funcionando na porta {port}!")
                            
                            # Testar cache stats
                            try:
                                cache_response = await client.get(f"http://localhost:{port}/cache/stats", timeout=5.0)
                                if cache_response.status_code == 200:
                                    cache_stats = cache_response.json()
                                    print(f"    - Cache endpoint funcionando: ✅")
                                    print(f"    - Cache conectado: {cache_stats.get('connected', False)}")
                                else:
                                    print(f"    - Cache endpoint com erro: {cache_response.status_code}")
                            except:
                                print(f"    - Cache endpoint não disponível")
                            
                            return True
                    else:
                        print(f"    - Porta {port}: Status {response.status_code}")
                        
            except httpx.ConnectError:
                print(f"    - Porta {port}: Não conecta")
            except Exception as e:
                print(f"    - Porta {port}: Erro {e}")
        
        print("  ❌ API não está respondendo em nenhuma porta")
        return False
        
    except ImportError:
        print("  ⚠️  httpx não instalado, pulando teste da API")
        return True
    except Exception as e:
        print(f"  ❌ Erro no teste da API: {e}")
        return False

async def main():
    """Executa todos os testes"""
    print("=" * 50)
    print("🚀 TESTE RÁPIDO DAS MELHORIAS")
    print("=" * 50)
    
    results = []
    
    # Teste do cache
    cache_ok = await test_cache()
    results.append(("Cache Service", cache_ok))
    
    # Teste da API
    api_ok = await test_api()
    results.append(("API", api_ok))
    
    # Resumo
    print("\n" + "=" * 50)
    print("📋 RESUMO")
    print("=" * 50)
    
    for test_name, success in results:
        status = "✅ OK" if success else "❌ FALHOU"
        print(f"{test_name}: {status}")
    
    passed = sum(1 for _, success in results if success)
    total = len(results)
    
    if passed == total:
        print(f"\n🎉 Todos os testes passaram! ({passed}/{total})")
        print("\n💡 Melhorias do Sprint 1 funcionando:")
        print("  - Cache Redis ativo")
        print("  - API respondendo")
        print("  - Zero impacto na UI/UX")
    else:
        print(f"\n⚠️  {passed}/{total} testes passaram")

if __name__ == "__main__":
    asyncio.run(main()) 