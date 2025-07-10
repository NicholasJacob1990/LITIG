#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
test_api.py

Script de teste para demonstrar como usar a API FastAPI de matching jurídico.
Baseado nos exemplos dos links sobre teste de APIs FastAPI.
"""

import asyncio
import json
import time
from datetime import datetime

import httpx


# Configuração da API
API_BASE_URL = "http://localhost:8000"
HEADERS = {"Content-Type": "application/json"}

# Exemplos de requisições
EXAMPLE_REQUESTS = {
    "caso_trabalhista": {
        "case": {
            "title": "Rescisão Indireta por Assédio Moral",
            "description": "Cliente sofreu assédio moral por 6 meses, com provas documentais e testemunhas. Necessita rescisão indireta e indenização por danos morais. Supervisor constantemente desqualificava o trabalho em público, sobrecarregava com tarefas impossíveis e fazia comentários depreciativos sobre a capacidade profissional.",
            "area": "Trabalhista",
            "subarea": "Rescisão",
            "urgency_hours": 48,
            "coordinates": {
                "latitude": -23.5505,
                "longitude": -46.6333
            },
            "complexity": "MEDIUM",
            "estimated_value": 25000.0
        },
        "top_n": 5,
        "preset": "balanced",
        "include_jusbrasil_data": True
    },
    
    "caso_civil": {
        "case": {
            "title": "Danos Morais por Negativação Indevida",
            "description": "Cliente teve nome negativado por dívida já quitada. Possui comprovante de pagamento e precisa de liminar para retirada do nome dos órgãos de proteção ao crédito, além de indenização por danos morais.",
            "area": "Civil",
            "subarea": "Danos Morais",
            "urgency_hours": 24,
            "coordinates": {
                "latitude": -22.9068,
                "longitude": -43.1729
            },
            "complexity": "LOW",
            "estimated_value": 10000.0
        },
        "top_n": 3,
        "preset": "fast",
        "include_jusbrasil_data": True
    },
    
    "caso_complexo": {
        "case": {
            "title": "Recuperação Judicial Empresarial",
            "description": "Empresa de médio porte com dificuldades financeiras causadas pela pandemia. Precisa de recuperação judicial para renegociar dívidas com fornecedores e manter atividades. Possui 150 funcionários e dívidas de R$ 5 milhões.",
            "area": "Empresarial",
            "subarea": "Recuperação Judicial",
            "urgency_hours": 168,  # 1 semana
            "coordinates": {
                "latitude": -25.4284,
                "longitude": -49.2733
            },
            "complexity": "HIGH",
            "estimated_value": 500000.0
        },
        "top_n": 3,
        "preset": "expert",
        "include_jusbrasil_data": True
    }
}


async def test_health_check():
    """Testa health check da API"""
    print("🏥 Testando Health Check...")
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(f"{API_BASE_URL}/health")
            
            if response.status_code == 200:
                data = response.json()
                print(f"✅ API está saudável: {data['status']}")
                print(f"   - Redis: {data['services']['redis']}")
                print(f"   - PostgreSQL: {data['services']['postgresql']}")
                return True
            else:
                print(f"❌ Health check falhou: {response.status_code}")
                return False
                
        except Exception as e:
            print(f"❌ Erro na conexão: {e}")
            return False


async def test_matching(case_name: str, request_data: dict):
    """Testa endpoint de matching"""
    print(f"\n🤖 Testando Matching: {case_name}")
    print("=" * 60)
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        try:
            start_time = time.time()
            
            response = await client.post(
                f"{API_BASE_URL}/api/match",
                json=request_data,
                headers=HEADERS
            )
            
            execution_time = (time.time() - start_time) * 1000
            
            if response.status_code == 200:
                data = response.json()
                
                print(f"✅ Matching concluído em {execution_time:.1f}ms")
                print(f"📋 Case ID: {data['case_id']}")
                print(f"👥 Advogados avaliados: {data['total_lawyers_evaluated']}")
                print(f"⚡ Tempo execução: {data['execution_time_ms']:.1f}ms")
                print(f"🎯 Algoritmo: {data['algorithm_version']}")
                print(f"🔧 Preset: {data['preset_used']}")
                
                # Mostrar top 3 advogados
                print(f"\n🏆 Top {min(3, len(data['lawyers']))} Advogados:")
                for i, lawyer in enumerate(data['lawyers'][:3], 1):
                    scores = lawyer['scores']
                    print(f"\n   {i}. {lawyer['nome']}")
                    print(f"      💯 Score Final: {scores['fair_score']:.3f}")
                    print(f"      📍 Distância: {lawyer['distancia_km']:.1f}km")
                    print(f"      ⭐ Success Rate: {scores['success_rate']:.2%}")
                    print(f"      🎯 Similaridade: {scores['case_similarity']:.2%}")
                    
                    if scores.get('jusbrasil_data'):
                        jb = scores['jusbrasil_data']
                        print(f"      📊 Jusbrasil: {jb['victories']}/{jb['total_cases']} vitórias")
                
                # Mostrar breakdown de features
                if data['lawyers']:
                    delta = data['lawyers'][0]['scores']['delta']
                    print(f"\n📊 Breakdown Features (Top 1):")
                    features_names = {
                        'A': 'Área Match', 'S': 'Similaridade', 'T': 'Taxa Sucesso',
                        'G': 'Geográfico', 'Q': 'Qualificação', 'U': 'Urgência',
                        'R': 'Reviews', 'C': 'Soft Skills'
                    }
                    for feature, contribution in delta.items():
                        name = features_names.get(feature, feature)
                        print(f"      {feature} ({name}): {contribution:.3f}")
                
                return True
                
            else:
                print(f"❌ Erro no matching: {response.status_code}")
                print(f"   Resposta: {response.text}")
                return False
                
        except Exception as e:
            print(f"❌ Erro na requisição: {e}")
            return False


async def test_list_lawyers():
    """Testa endpoint de listagem de advogados"""
    print(f"\n👥 Testando Listagem de Advogados...")
    
    async with httpx.AsyncClient() as client:
        try:
            # Teste básico
            response = await client.get(f"{API_BASE_URL}/api/lawyers?limit=5")
            
            if response.status_code == 200:
                data = response.json()
                print(f"✅ Listagem concluída")
                print(f"   📊 Total encontrados: {data['total']}")
                print(f"   📄 Retornados: {len(data['lawyers'])}")
                
                # Mostrar primeiros advogados
                for lawyer in data['lawyers'][:3]:
                    print(f"   👤 {lawyer['nome']} ({lawyer.get('uf', 'N/A')})")
                
                return True
            else:
                print(f"❌ Erro na listagem: {response.status_code}")
                return False
                
        except Exception as e:
            print(f"❌ Erro na requisição: {e}")
            return False


async def test_api_root():
    """Testa endpoint raiz da API"""
    print("🏠 Testando endpoint raiz...")
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(f"{API_BASE_URL}/")
            
            if response.status_code == 200:
                data = response.json()
                print(f"✅ {data['message']}")
                print(f"   📖 Documentação: {API_BASE_URL}{data['docs']}")
                return True
            else:
                print(f"❌ Erro: {response.status_code}")
                return False
                
        except Exception as e:
            print(f"❌ Erro na conexão: {e}")
            return False


async def run_performance_test():
    """Teste de performance com múltiplas requisições"""
    print(f"\n⚡ Teste de Performance...")
    
    request_data = EXAMPLE_REQUESTS["caso_trabalhista"]
    num_requests = 5
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        start_time = time.time()
        
        # Fazer requisições paralelas
        tasks = []
        for i in range(num_requests):
            task = client.post(
                f"{API_BASE_URL}/api/match",
                json=request_data,
                headers=HEADERS
            )
            tasks.append(task)
        
        try:
            responses = await asyncio.gather(*tasks)
            total_time = (time.time() - start_time) * 1000
            
            successful = sum(1 for r in responses if r.status_code == 200)
            
            print(f"📊 Resultados do Teste de Performance:")
            print(f"   🚀 {num_requests} requisições em {total_time:.1f}ms")
            print(f"   ✅ Sucessos: {successful}/{num_requests}")
            print(f"   ⚡ Média por requisição: {total_time/num_requests:.1f}ms")
            
            return successful == num_requests
            
        except Exception as e:
            print(f"❌ Erro no teste de performance: {e}")
            return False


async def main():
    """Função principal dos testes"""
    print("🧪 LITGO5 API Test Suite")
    print("=" * 50)
    print(f"🌐 API Base URL: {API_BASE_URL}")
    print(f"🕐 Iniciado em: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Lista de testes
    tests = [
        ("Health Check", test_health_check()),
        ("API Root", test_api_root()),
        ("List Lawyers", test_list_lawyers()),
        ("Matching - Trabalhista", test_matching("Caso Trabalhista", EXAMPLE_REQUESTS["caso_trabalhista"])),
        ("Matching - Civil", test_matching("Caso Civil", EXAMPLE_REQUESTS["caso_civil"])),
        ("Matching - Complexo", test_matching("Caso Complexo", EXAMPLE_REQUESTS["caso_complexo"])),
        ("Performance Test", run_performance_test()),
    ]
    
    # Executar testes
    results = []
    for test_name, test_coro in tests:
        try:
            result = await test_coro
            results.append((test_name, result))
        except Exception as e:
            print(f"❌ Erro no teste '{test_name}': {e}")
            results.append((test_name, False))
    
    # Sumário dos resultados
    print(f"\n📊 SUMÁRIO DOS TESTES")
    print("=" * 50)
    
    passed = 0
    for test_name, result in results:
        status = "✅ PASSOU" if result else "❌ FALHOU"
        print(f"{status} - {test_name}")
        if result:
            passed += 1
    
    print(f"\n🎯 Resultado Final: {passed}/{len(results)} testes passaram")
    
    if passed == len(results):
        print("🎉 Todos os testes passaram! API está funcionando perfeitamente.")
    else:
        print("⚠️  Alguns testes falharam. Verifique a configuração da API.")
    
    return passed == len(results)


if __name__ == "__main__":
    print("💡 Para executar os testes:")
    print("   1. Inicie a API: docker-compose -f docker-compose.api.yml up")
    print("   2. Execute: python test_api.py")
    print("   3. Acesse documentação: http://localhost:8000/docs")
    print()
    
    # Executar testes
    success = asyncio.run(main())
    exit(0 if success else 1) 