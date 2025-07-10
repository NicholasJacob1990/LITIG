#!/usr/bin/env python3
"""
Teste do Cache Service Simplificado
"""
import asyncio
import sys
import os

# Adicionar o diretório do projeto ao path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

async def test_simple_cache():
    """Teste do cache service simplificado"""
    print("🧪 Testando Cache Service Simplificado...")
    
    try:
        from backend.services.cache_service_simple import simple_cache_service, init_simple_cache
        
        # Inicializar cache
        print("  ✓ Inicializando cache...")
        await init_simple_cache("redis://localhost:6379")
        
        # Teste básico
        print("  ✓ Testando set/get...")
        test_data = {"test": "success", "number": 42, "list": [1, 2, 3]}
        await simple_cache_service.set("test_key", test_data, ttl=60)
        
        result = await simple_cache_service.get("test_key")
        if result == test_data:
            print("  ✅ Cache básico funcionando!")
        else:
            print(f"  ❌ Cache falhou. Esperado: {test_data}, Recebido: {result}")
            return False
        
        # Teste de perfil de advogado
        print("  ✓ Testando cache de advogado...")
        lawyer_data = {
            "id": "lawyer_123",
            "name": "Dr. João Silva",
            "rating": 4.5,
            "specialties": ["Trabalhista", "Civil"]
        }
        await simple_cache_service.set_lawyer_profile("lawyer_123", lawyer_data)
        cached_lawyer = await simple_cache_service.get_lawyer_profile("lawyer_123")
        
        if cached_lawyer == lawyer_data:
            print("  ✅ Cache de advogado funcionando!")
        else:
            print("  ❌ Cache de advogado falhou")
            return False
        
        # Teste de estatísticas
        print("  ✓ Testando estatísticas...")
        stats = await simple_cache_service.get_cache_stats()
        
        if stats.get("connected"):
            print(f"    - Redis conectado: ✅")
            print(f"    - Total de chaves: {stats.get('total_keys', 0)}")
            print(f"    - Memória usada: {stats.get('used_memory', 'N/A')}")
            print(f"    - Versão Redis: {stats.get('redis_version', 'N/A')}")
        else:
            print(f"    - Redis não conectado: ❌")
            print(f"    - Erro: {stats.get('error', 'Desconhecido')}")
            return False
        
        print("\n🎉 Cache Service Simplificado funcionando perfeitamente!")
        return True
        
    except Exception as e:
        print(f"\n❌ Erro: {e}")
        import traceback
        traceback.print_exc()
        return False

async def main():
    """Executa o teste"""
    print("=" * 60)
    print("🚀 TESTE DO CACHE SERVICE SIMPLIFICADO")
    print("=" * 60)
    
    success = await test_simple_cache()
    
    print("\n" + "=" * 60)
    print("📋 RESULTADO")
    print("=" * 60)
    
    if success:
        print("✅ Cache Service funcionando!")
        print("\n💡 Isso significa que:")
        print("  - Redis está conectado")
        print("  - Cache set/get funcionando")
        print("  - Métodos específicos funcionando")
        print("  - Estatísticas disponíveis")
        print("\n🚀 Sprint 1 - Cache implementado com sucesso!")
    else:
        print("❌ Cache Service com problemas")
        print("\n🔧 Possíveis soluções:")
        print("  - Verificar se Redis está rodando: docker ps")
        print("  - Verificar conexão: redis-cli ping")
        print("  - Verificar porta: lsof -i :6379")

if __name__ == "__main__":
    asyncio.run(main()) 