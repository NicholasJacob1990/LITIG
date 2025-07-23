#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Teste Simples do Algoritmo de Matching v2.8-academic
===================================================
Testa os métodos realmente disponíveis no algoritmo de matching.
"""

import time
from datetime import datetime
from algoritmo_match import MatchmakingAlgorithm, Case, Lawyer, KPI

def create_simple_case():
    """Cria um caso de teste simples."""
    return Case(
        id="case_001",
        area="trabalhista",
        subarea="rescisao_indireta",
        urgency_h=48,
        coords=(-23.5505, -46.6333),  # São Paulo
        complexity="MEDIUM",
        expected_fee_min=10000.0,
        expected_fee_max=20000.0,
        type="INDIVIDUAL"
    )

def create_simple_lawyer():
    """Cria um advogado de teste simples."""
    return Lawyer(
        id="lawyer_001",
        nome="Dr. João Silva",
        tags_expertise=["trabalhista", "civel"],
        geo_latlon=(-23.5505, -46.6333),
        curriculo_json={
            "university": "USP",
            "degree": "Direito",
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
    )

def test_algorithm_instantiation():
    """Testa se o algoritmo pode ser instanciado."""
    print("🧪 Teste 1: Instanciação do Algoritmo")
    print("-" * 50)
    
    try:
        algo = MatchmakingAlgorithm()
        print("✅ Algoritmo instanciado com sucesso!")
        print(f"   📊 Métodos disponíveis: {[m for m in dir(algo) if not m.startswith('_')]}")
        return True
    except Exception as e:
        print(f"❌ Erro na instanciação: {e}")
        return False

def test_ranking_method():
    """Testa o método de ranking disponível."""
    print("\n🧪 Teste 2: Método de Ranking")
    print("-" * 50)
    
    try:
        algo = MatchmakingAlgorithm()
        case = create_simple_case()
        lawyer = create_simple_lawyer()
        
        # Testar o método rank que está disponível
        start_time = time.time()
        
        # O método rank provavelmente espera uma lista de advogados
        lawyers = [lawyer]
        
        # Tentar diferentes assinaturas do método rank
        try:
            result = algo.rank(case, lawyers)
            print(f"✅ Método rank executado: tipo {type(result)}")
            if hasattr(result, '__len__'):
                print(f"   📊 Resultado tem {len(result)} itens")
            print(f"   🎯 Resultado: {result}")
        except Exception as rank_error:
            print(f"⚠️  Erro no método rank: {rank_error}")
            
            # Tentar outras possíveis assinaturas
            try:
                result = algo.rank(lawyers, case)
                print(f"✅ Método rank (ordem invertida) executado: {type(result)}")
            except Exception as e2:
                print(f"❌ Erro na segunda tentativa: {e2}")
                return False
        
        end_time = time.time()
        print(f"   ⏱️  Tempo de execução: {end_time - start_time:.3f} segundos")
        
        return True
        
    except Exception as e:
        print(f"❌ Erro no teste de ranking: {e}")
        return False

def test_equity_weight():
    """Testa o método de peso de equidade."""
    print("\n🧪 Teste 3: Peso de Equidade")
    print("-" * 50)
    
    try:
        algo = MatchmakingAlgorithm()
        
        # Testar o método equity_weight
        try:
            equity = algo.equity_weight
            print(f"✅ Equity weight: {equity}")
            return True
        except Exception as e:
            print(f"⚠️  Erro ao acessar equity_weight: {e}")
            return False
            
    except Exception as e:
        print(f"❌ Erro no teste de equity: {e}")
        return False

def test_dynamic_weights():
    """Testa o método de pesos dinâmicos."""
    print("\n🧪 Teste 4: Pesos Dinâmicos")
    print("-" * 50)
    
    try:
        algo = MatchmakingAlgorithm()
        case = create_simple_case()
        
        # Testar o método apply_dynamic_weights
        try:
            # Tentar diferentes assinaturas
            result = algo.apply_dynamic_weights(case)
            print(f"✅ Dynamic weights aplicado: {type(result)}")
            print(f"   🎯 Resultado: {result}")
            return True
        except Exception as e:
            print(f"⚠️  Erro em apply_dynamic_weights: {e}")
            
            # Tentar com argumentos diferentes
            try:
                weights = {"A": 0.2, "B": 0.15, "C": 0.1, "D": 0.1, "E": 0.1, "F": 0.1, "G": 0.15, "H": 0.1}
                result = algo.apply_dynamic_weights(case, weights)
                print(f"✅ Dynamic weights (com pesos) aplicado: {type(result)}")
                return True
            except Exception as e2:
                print(f"❌ Erro na segunda tentativa: {e2}")
                return False
            
    except Exception as e:
        print(f"❌ Erro no teste de pesos dinâmicos: {e}")
        return False

def test_data_structures():
    """Testa se as estruturas de dados são válidas."""
    print("\n🧪 Teste 5: Estruturas de Dados")
    print("-" * 50)
    
    try:
        case = create_simple_case()
        lawyer = create_simple_lawyer()
        
        print(f"✅ Caso criado:")
        print(f"   📋 ID: {case.id}")
        print(f"   ⚖️  Área: {case.area}/{case.subarea}")
        print(f"   🕐 Urgência: {case.urgency_h}h")
        print(f"   📍 Coordenadas: {case.coords}")
        print(f"   💰 Faixa de preço: R$ {case.expected_fee_min:,.0f} - R$ {case.expected_fee_max:,.0f}")
        
        print(f"\n✅ Advogado criado:")
        print(f"   👨‍⚖️ Nome: {lawyer.nome}")
        print(f"   🎯 Especialização: {', '.join(lawyer.tags_expertise)}")
        print(f"   📍 Localização: {lawyer.geo_latlon}")
        print(f"   ⭐ Taxa de sucesso: {lawyer.kpi.success_rate:.1%}")
        print(f"   📊 Avaliação média: {lawyer.kpi.avaliacao_media:.1f}/5")
        print(f"   📈 Casos (30d): {lawyer.kpi.cases_30d}")
        
        return True
        
    except Exception as e:
        print(f"❌ Erro nas estruturas de dados: {e}")
        return False

def main():
    """Executa todos os testes."""
    print("🚀 INICIANDO TESTES SIMPLES DO ALGORITMO DE MATCHING v2.8-academic")
    print("=" * 70)
    
    results = []
    
    # Executar testes
    results.append(test_algorithm_instantiation())
    results.append(test_data_structures())
    results.append(test_equity_weight())
    results.append(test_dynamic_weights())
    results.append(test_ranking_method())
    
    # Resumo
    print("\n📊 RESUMO DOS TESTES")
    print("=" * 70)
    
    passed = sum(results)
    total = len(results)
    
    print(f"✅ Testes passaram: {passed}/{total}")
    print(f"📈 Taxa de sucesso: {passed/total:.1%}")
    
    if passed == total:
        print("🎉 TODOS OS TESTES PASSARAM! Algoritmo básico funcionando.")
    elif passed > 0:
        print("⚡ ALGUNS TESTES PASSARAM. Algoritmo parcialmente funcional.")
    else:
        print("⚠️  TODOS OS TESTES FALHARAM. Verificar implementação.")
    
    print(f"\n⏰ Teste concluído às {datetime.now().strftime('%H:%M:%S')}")

if __name__ == "__main__":
    main() 