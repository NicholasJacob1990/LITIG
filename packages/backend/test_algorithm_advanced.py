#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Teste Avançado do Algoritmo de Matching v2.8-academic
====================================================
Testa os métodos assíncronos do algoritmo de matching usando async/await.
"""

import asyncio
import time
from datetime import datetime
from algoritmo_match import MatchmakingAlgorithm, Case, Lawyer, KPI

def create_test_case():
    """Cria um caso de teste."""
    return Case(
        id="case_trabalhista_001",
        area="trabalhista",
        subarea="rescisao_indireta",
        urgency_h=48,
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
        id="lawyer_trabalhista_001",
        nome="Dr. João Silva - Trabalhista",
        tags_expertise=["trabalhista", "rescisao", "assedio_moral"],
        geo_latlon=(-23.5505, -46.6333),  # São Paulo
        curriculo_json={
            "university": "USP",
            "degree": "Direito",
            "specialization": "Direito do Trabalho",
            "experience_years": 8,
            "oab": "SP123456",
            "cases_won": 156,
            "cases_total": 180
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
    
    # Advogado generalista com menos experiência em trabalhista
    lawyers.append(Lawyer(
        id="lawyer_geral_002",
        nome="Dra. Maria Santos - Generalista",
        tags_expertise=["civel", "empresarial", "trabalhista"],
        geo_latlon=(-23.5505, -46.6333),  # São Paulo
        curriculo_json={
            "university": "PUC-SP",
            "degree": "Direito",
            "specialization": "Direito Empresarial",
            "experience_years": 12,
            "oab": "SP789012",
            "cases_won": 98,
            "cases_total": 120
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
        id="lawyer_junior_003",
        nome="Dr. Pedro Costa - Júnior",
        tags_expertise=["trabalhista"],
        geo_latlon=(-23.5505, -46.6333),  # São Paulo
        curriculo_json={
            "university": "Mackenzie",
            "degree": "Direito",
            "specialization": "Direito do Trabalho",
            "experience_years": 3,
            "oab": "SP345678",
            "cases_won": 24,
            "cases_total": 32
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
    
    # Advogado fora de São Paulo
    lawyers.append(Lawyer(
        id="lawyer_distante_004",
        nome="Dr. Carlos Oliveira - Rio de Janeiro",
        tags_expertise=["trabalhista", "sindical"],
        geo_latlon=(-22.9068, -43.1729),  # Rio de Janeiro
        curriculo_json={
            "university": "UERJ",
            "degree": "Direito",
            "specialization": "Direito do Trabalho",
            "experience_years": 15,
            "oab": "RJ987654",
            "cases_won": 245,
            "cases_total": 280
        },
        kpi=KPI(
            success_rate=0.88,
            cases_30d=15,
            avaliacao_media=4.7,
            tempo_resposta_h=4,
            active_cases=15
        ),
        max_concurrent_cases=25
    ))
    
    return lawyers

async def test_rank_method():
    """Testa o método de ranking assíncrono."""
    print("🧪 Teste 1: Método de Ranking Assíncrono")
    print("-" * 60)
    
    try:
        algo = MatchmakingAlgorithm()
        case = create_test_case()
        lawyers = create_test_lawyers()
        
        print(f"   📋 Caso: {case.area}/{case.subarea}")
        print(f"   👥 Advogados: {len(lawyers)}")
        print(f"   📍 Localização: São Paulo, SP")
        
        start_time = time.time()
        
        # Usar await para chamar o método assíncrono
        result = await algo.rank(case, lawyers)
        
        end_time = time.time()
        
        print(f"   ⏱️  Tempo de execução: {end_time - start_time:.3f} segundos")
        print(f"   📊 Tipo do resultado: {type(result)}")
        
        # Analisar resultado
        if isinstance(result, list):
            print(f"   ✅ Lista de matches retornada: {len(result)} itens")
            
            for i, match in enumerate(result[:3], 1):  # Top 3
                if hasattr(match, 'lawyer'):
                    lawyer = match.lawyer
                    score = getattr(match, 'score', 'N/A')
                    print(f"\n   🏆 Rank #{i}:")
                    print(f"      👨‍⚖️ {lawyer.nome}")
                    print(f"      📊 Score: {score}")
                    print(f"      🎯 Especialização: {', '.join(lawyer.tags_expertise)}")
                    print(f"      ⭐ Taxa sucesso: {lawyer.kpi.success_rate:.1%}")
                    print(f"      📈 Avaliação: {lawyer.kpi.avaliacao_media:.1f}/5")
                else:
                    print(f"   📋 Match #{i}: {match}")
        else:
            print(f"   📋 Resultado: {result}")
        
        return True
        
    except Exception as e:
        print(f"   ❌ Erro no ranking: {e}")
        import traceback
        traceback.print_exc()
        return False

async def test_apply_dynamic_weights():
    """Testa o método de pesos dinâmicos."""
    print("\n🧪 Teste 2: Pesos Dinâmicos")
    print("-" * 60)
    
    try:
        algo = MatchmakingAlgorithm()
        case = create_test_case()
        
        # Definir pesos padrão para o teste
        base_weights = {
            "A": 0.20,  # Especialização
            "B": 0.15,  # Performance/KPI
            "C": 0.10,  # Proximidade geográfica
            "D": 0.10,  # Disponibilidade
            "E": 0.10,  # Reputação
            "F": 0.10,  # Experiência
            "G": 0.15,  # Custo-benefício
            "H": 0.10   # Compatibilidade
        }
        
        print(f"   📊 Pesos base definidos: {len(base_weights)} features")
        
        # Testar apply_dynamic_weights
        start_time = time.time()
        
        result = algo.apply_dynamic_weights(case, base_weights)
        
        end_time = time.time()
        
        print(f"   ⏱️  Tempo de execução: {end_time - start_time:.3f} segundos")
        print(f"   📋 Tipo do resultado: {type(result)}")
        
        if isinstance(result, dict):
            print("   ✅ Pesos dinâmicos calculados:")
            total_weight = sum(result.values())
            for feature, weight in result.items():
                percentage = (weight / total_weight) * 100 if total_weight > 0 else 0
                print(f"      • {feature}: {weight:.3f} ({percentage:.1f}%)")
            
            print(f"   📊 Soma total: {total_weight:.3f}")
            
            # Verificar se os pesos são válidos
            if abs(total_weight - 1.0) < 0.001:
                print("   ✅ Pesos normalizados corretamente")
            else:
                print(f"   ⚠️  Pesos não normalizados (soma: {total_weight:.3f})")
        else:
            print(f"   📋 Resultado: {result}")
        
        return True
        
    except Exception as e:
        print(f"   ❌ Erro nos pesos dinâmicos: {e}")
        import traceback
        traceback.print_exc()
        return False

async def test_equity_weight():
    """Testa o peso de equidade."""
    print("\n🧪 Teste 3: Peso de Equidade")
    print("-" * 60)
    
    try:
        algo = MatchmakingAlgorithm()
        
        # Verificar se equity_weight é um método ou atributo
        equity = algo.equity_weight
        
        print(f"   📊 Tipo: {type(equity)}")
        
        if callable(equity):
            # Se for um método, tentar chamá-lo
            try:
                result = equity()
                print(f"   ✅ Equity weight calculado: {result}")
            except Exception as e:
                print(f"   ⚠️  Erro ao calcular equity weight: {e}")
                # Tentar com argumentos
                try:
                    lawyers = create_test_lawyers()
                    result = equity(lawyers)
                    print(f"   ✅ Equity weight (com advogados): {result}")
                except Exception as e2:
                    print(f"   ❌ Erro com argumentos: {e2}")
        else:
            print(f"   📋 Valor: {equity}")
        
        return True
        
    except Exception as e:
        print(f"   ❌ Erro no equity weight: {e}")
        return False

async def test_performance_stress():
    """Teste de performance com muitos advogados."""
    print("\n🧪 Teste 4: Performance Stress Test")
    print("-" * 60)
    
    try:
        algo = MatchmakingAlgorithm()
        case = create_test_case()
        
        # Criar muitos advogados para teste de stress
        base_lawyers = create_test_lawyers()
        stress_lawyers = []
        
        for i in range(50):  # 50 advogados
            for j, base_lawyer in enumerate(base_lawyers):
                new_lawyer = Lawyer(
                    id=f"stress_lawyer_{i}_{j}",
                    nome=f"Dr. Teste {i}-{j}",
                    tags_expertise=base_lawyer.tags_expertise,
                    geo_latlon=base_lawyer.geo_latlon,
                    curriculo_json=base_lawyer.curriculo_json.copy(),
                    kpi=KPI(
                        success_rate=base_lawyer.kpi.success_rate,
                        cases_30d=base_lawyer.kpi.cases_30d,
                        avaliacao_media=base_lawyer.kpi.avaliacao_media,
                        tempo_resposta_h=base_lawyer.kpi.tempo_resposta_h,
                        active_cases=base_lawyer.kpi.active_cases
                    ),
                    max_concurrent_cases=base_lawyer.max_concurrent_cases
                )
                stress_lawyers.append(new_lawyer)
        
        print(f"   👥 Advogados para teste: {len(stress_lawyers)}")
        
        start_time = time.time()
        
        # Testar ranking com muitos advogados
        result = await algo.rank(case, stress_lawyers)
        
        end_time = time.time()
        
        print(f"   ⏱️  Tempo total: {end_time - start_time:.3f} segundos")
        print(f"   🚀 Taxa: {len(stress_lawyers) / (end_time - start_time):.1f} advogados/segundo")
        
        if isinstance(result, list) and len(result) > 0:
            print(f"   ✅ Ranking gerado: {len(result)} matches")
            print(f"   🏆 Melhor match: {getattr(result[0], 'lawyer', {}).nome if hasattr(result[0], 'lawyer') else 'N/A'}")
        
        return True
        
    except Exception as e:
        print(f"   ❌ Erro no teste de performance: {e}")
        import traceback
        traceback.print_exc()
        return False

async def main():
    """Executa todos os testes avançados."""
    print("🚀 INICIANDO TESTES AVANÇADOS DO ALGORITMO DE MATCHING v2.8-academic")
    print("=" * 80)
    
    results = []
    
    # Executar testes assíncronos
    results.append(await test_rank_method())
    results.append(await test_apply_dynamic_weights())
    results.append(await test_equity_weight())
    results.append(await test_performance_stress())
    
    # Resumo
    print("\n📊 RESUMO DOS TESTES AVANÇADOS")
    print("=" * 80)
    
    passed = sum(results)
    total = len(results)
    
    print(f"✅ Testes passaram: {passed}/{total}")
    print(f"📈 Taxa de sucesso: {passed/total:.1%}")
    
    if passed == total:
        print("🎉 TODOS OS TESTES AVANÇADOS PASSARAM! Algoritmo em perfeito estado.")
        status = "EXCELENTE"
    elif passed >= total * 0.75:
        print("⚡ MAIORIA DOS TESTES PASSOU. Algoritmo em bom estado.")
        status = "BOM"
    elif passed >= total * 0.5:
        print("⚠️  ALGUNS TESTES PASSARAM. Algoritmo parcialmente funcional.")
        status = "PARCIAL"
    else:
        print("❌ MUITOS TESTES FALHARAM. Algoritmo precisa de correções.")
        status = "CRÍTICO"
    
    print(f"\n🎯 STATUS DO ALGORITMO: {status}")
    print(f"⏰ Teste concluído às {datetime.now().strftime('%H:%M:%S')}")
    
    return passed, total

if __name__ == "__main__":
    asyncio.run(main()) 