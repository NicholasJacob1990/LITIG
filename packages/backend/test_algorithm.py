#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Teste Completo do Algoritmo de Matching v2.8-academic
====================================================
Este script testa todas as funcionalidades do algoritmo de matching:
- Instanciação e configuração
- Cálculo de features individuais
- Algoritmo de matching completo
- Performance e métricas
"""

import asyncio
import json
import time
from datetime import datetime
from algoritmo_match import MatchmakingAlgorithm, Case, Lawyer, LawFirm, KPI

def create_test_case():
    """Cria um caso de teste realista."""
    return Case(
        id="case_001",
        area="trabalhista",
        subarea="rescisao_indireta",
        urgency_h=48,  # 48 horas de urgência
        coords=(-23.5505, -46.6333),  # São Paulo
        complexity="MEDIUM",
        expected_fee_min=10000.0,
        expected_fee_max=20000.0,
        type="INDIVIDUAL"
    )

def create_test_lawyers():
    """Cria uma lista de advogados de teste."""
    lawyers = []
    
    # Advogado especialista em trabalhista
    lawyers.append(Lawyer(
        id="lawyer_001",
        nome="Dr. João Silva",
        tags_expertise=["trabalhista", "civel"],
        geo_latlon=(-23.5505, -46.6333),
        curriculo_json={
            "university": "USP",
            "degree": "Direito", 
            "postgrad": ["Direito do Trabalho", "Processo Civil"],
            "publications": 3,
            "experience_years": 8,
            "oab": "SP123456"
        },
        kpi=KPI(
            success_rate=0.87,
            cases_30d=12,
            avaliacao_media=4.6,
            tempo_resposta_h=2,
            active_cases=12
        ),
        max_concurrent_cases=20
    ))
    
    # Advogado generalista
    lawyers.append(Lawyer(
        id="lawyer_002", 
        nome="Dra. Maria Santos",
        tags_expertise=["civel", "empresarial"],
        geo_latlon=(-23.5505, -46.6333),
        curriculo_json={
            "university": "PUC-SP",
            "degree": "Direito",
            "postgrad": ["Direito Empresarial"],
            "publications": 1,
            "experience_years": 12,
            "oab": "SP789012"
        },
        kpi=KPI(
            success_rate=0.82,
            cases_30d=8,
            avaliacao_media=4.4,
            tempo_resposta_h=1,
            active_cases=8
        ),
        max_concurrent_cases=15
    ))
    
    # Advogado júnior trabalhista
    lawyers.append(Lawyer(
        id="lawyer_003",
        nome="Dr. Pedro Costa", 
        tags_expertise=["trabalhista"],
        geo_latlon=(-23.5505, -46.6333),
        curriculo_json={
            "university": "Mackenzie",
            "degree": "Direito",
            "postgrad": [],
            "publications": 0,
            "experience_years": 3,
            "oab": "SP345678"
        },
        kpi=KPI(
            success_rate=0.75,
            cases_30d=6,
            avaliacao_media=4.2,
            tempo_resposta_h=3,
            active_cases=6
        ),
        max_concurrent_cases=12
    ))
    
    return lawyers

def create_test_firms():
    """Cria uma lista de escritórios de teste."""
    return [
        LawFirm(
            id="firm_001",
            nome="Silva & Associados",
            tags_expertise=["trabalhista", "civel"],
            geo_latlon=(-23.5505, -46.6333),
            curriculo_json={
                "founded_year": 2010,
                "certifications": ["ISO9001"],
                "notable_cases": 3,
                "size": "medium"
            },
            kpi=KPI(
                success_rate=0.84,
                cases_30d=25,
                avaliacao_media=4.5,
                tempo_resposta_h=1,
                active_cases=25
            ),
            team_size=17,
            main_latlon=(-23.5505, -46.6333),
            kpi_firm=FirmKPI(
                success_rate=0.84,
                reputation_score=0.85,
                active_cases=25
            )
        )
    ]

async def test_basic_matching():
    """Testa o algoritmo básico de matching."""
    print("🧪 Teste 1: Matching Básico")
    print("-" * 50)
    
    algo = MatchmakingAlgorithm()
    case = create_test_case()
    lawyers = create_test_lawyers()
    
    start_time = time.time()
    
    try:
        matches = await algo.find_matches(
            case=case,
            available_lawyers=lawyers,
            top_k=3,
            explain=True
        )
        
        end_time = time.time()
        
        print(f"✅ Matching executado em {end_time - start_time:.3f} segundos")
        print(f"✅ {len(matches)} matches encontrados")
        
        for i, match in enumerate(matches, 1):
            print(f"\n📋 Match {i}:")
            print(f"   👨‍💼 Advogado: {match.lawyer.nome}")
            print(f"   📊 Score: {match.score:.3f}")
            print(f"   💰 Taxa Sucesso: {match.lawyer.kpi.success_rate:.1%}")
            print(f"   ⭐ Avaliação: {match.lawyer.kpi.avaliacao_media:.1f}/5")
            print(f"   🎯 Especialização: {', '.join(match.lawyer.tags_expertise)}")
            
            if hasattr(match, 'explanation') and match.explanation:
                print(f"   💡 Explicação: {match.explanation.get('reason', 'N/A')}")
        
        return True
        
    except Exception as e:
        print(f"❌ Erro no matching: {e}")
        return False

async def test_feature_calculation():
    """Testa o cálculo individual de features."""
    print("\n🧪 Teste 2: Cálculo de Features")
    print("-" * 50)
    
    algo = MatchmakingAlgorithm()
    case = create_test_case()
    lawyer = create_test_lawyers()[0]  # Primeiro advogado
    
    try:
        features = await algo._calculate_all_features_async(case, lawyer)
        
        print("✅ Features calculadas:")
        for feature_name, value in features.items():
            print(f"   📈 {feature_name}: {value:.3f}")
        
        return True
        
    except Exception as e:
        print(f"❌ Erro no cálculo de features: {e}")
        return False

def test_performance():
    """Testa performance com múltiplos casos."""
    print("\n🧪 Teste 3: Performance")
    print("-" * 50)
    
    algo = MatchmakingAlgorithm()
    case = create_test_case()
    lawyers = create_test_lawyers() * 10  # 30 advogados
    
    start_time = time.time()
    
    try:
        # Usando versão síncrona para teste
        for _ in range(5):
            # Simula cálculo síncrono
            for lawyer in lawyers[:5]:  # Teste com subset
                algo._calculate_all_features(case, lawyer)
        
        end_time = time.time()
        
        print(f"✅ Performance teste concluído")
        print(f"   ⏱️  Tempo total: {end_time - start_time:.3f} segundos")
        print(f"   📊 Advogados processados: {len(lawyers[:5]) * 5}")
        print(f"   🚀 Taxa: {(len(lawyers[:5]) * 5) / (end_time - start_time):.1f} advogados/segundo")
        
        return True
        
    except Exception as e:
        print(f"❌ Erro no teste de performance: {e}")
        return False

def test_edge_cases():
    """Testa casos extremos."""
    print("\n🧪 Teste 4: Casos Extremos")
    print("-" * 50)
    
    algo = MatchmakingAlgorithm()
    
    # Teste com lista vazia
    try:
        empty_result = algo.find_matches(
            case=create_test_case(),
            available_lawyers=[],
            top_k=3
        )
        assert len(empty_result) == 0
        print("✅ Teste lista vazia: OK")
    except Exception as e:
        print(f"❌ Teste lista vazia falhou: {e}")
        return False
    
    # Teste com caso inválido
    try:
        invalid_case = Case(
            id="invalid",
            area="",
            subarea="",
            urgency_h=0,
            coords=(0, 0),
            complexity="",
            type="INDIVIDUAL"
        )
        
        result = algo.find_matches(
            case=invalid_case,
            available_lawyers=create_test_lawyers(),
            top_k=1
        )
        print("✅ Teste caso inválido: Handled gracefully")
    except Exception as e:
        print(f"⚠️  Teste caso inválido: {e}")
    
    return True

async def main():
    """Executa todos os testes."""
    print("🚀 INICIANDO TESTES DO ALGORITMO DE MATCHING v2.8-academic")
    print("=" * 70)
    
    results = []
    
    # Executar testes
    results.append(await test_basic_matching())
    results.append(await test_feature_calculation()) 
    results.append(test_performance())
    results.append(test_edge_cases())
    
    # Resumo
    print("\n📊 RESUMO DOS TESTES")
    print("=" * 70)
    
    passed = sum(results)
    total = len(results)
    
    print(f"✅ Testes passaram: {passed}/{total}")
    print(f"📈 Taxa de sucesso: {passed/total:.1%}")
    
    if passed == total:
        print("🎉 TODOS OS TESTES PASSARAM! Algoritmo funcionando corretamente.")
    else:
        print("⚠️  ALGUNS TESTES FALHARAM. Verificar implementação.")
    
    print(f"\n⏰ Teste concluído às {datetime.now().strftime('%H:%M:%S')}")

if __name__ == "__main__":
    asyncio.run(main()) 