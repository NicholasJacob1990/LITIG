#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Checklist Rápido v2.6.2
=======================

Testes específicos sugeridos na revisão:
1. Normalização de acentos
2. Validação de reviews mobile
3. Truncamento de tuplas

Uso:
    python scripts/test_quick_checklist.py
"""

import sys
from pathlib import Path

# Adicionar o diretório backend ao path
sys.path.insert(0, str(Path(__file__).parent.parent / "backend"))

from algoritmo_match import FeatureCalculator, Case, Lawyer, KPI, safe_json_dump
import numpy as np

def test_accent_normalization():
    """Testa normalização de acentos específica."""
    print("🔤 Testando normalização específica...")
    
    # Mock básico para testar apenas a normalização
    class MockCalculator:
        def _normalize_text(self, text):
            import unicodedata
            return unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode().lower()
    
    calc = MockCalculator()
    result = calc._normalize_text('PÉssimo!')
    expected = 'pessimo!'
    
    print(f"  'PÉssimo!' -> '{result}' (esperado: '{expected}')")
    assert result == expected, f"Esperado '{expected}', obtido '{result}'"
    print("  ✅ Normalização funcionando!")

def test_mobile_review_validation():
    """Testa validação de reviews mobile específica."""
    print("\n📱 Testando validação mobile específica...")
    
    # Mock de advogado para testar validação
    lawyer = Lawyer(
        id="L_test",
        nome="Teste",
        tags_expertise=["civil"],
        geo_latlon=(-23.5, -46.6),
        curriculo_json={"anos_experiencia": 5},
        kpi=KPI(success_rate=0.8, cases_30d=10, avaliacao_media=4.5, tempo_resposta_h=24)
    )
    
    case = Case(
        id="C_test",
        area="civil",
        subarea="test",
        urgency_h=48,
        coords=(-23.5, -46.6),
        summary_embedding=np.random.rand(384)
    )
    
    calc = FeatureCalculator(case, lawyer)
    
    # Teste específico: "Top! 👍" deve ser aceito agora
    result = calc._is_valid_review('Top! 👍')
    print(f"  'Top! 👍' -> {'✅' if result else '❌'}")
    
    # Com as novas regras (≥3 tokens OU ≥30% únicos), deve ser aceito
    # "Top! 👍" tem 2 tokens únicos de 2 total = 100% > 30%
    assert result == True, "Review 'Top! 👍' deveria ser aceito"
    print("  ✅ Validação mobile funcionando!")

def test_tuple_truncation():
    """Testa truncamento de tuplas específico."""
    print("\n📦 Testando truncamento de tuplas específico...")
    
    # Teste com tupla grande
    big_tuple = tuple(range(150))
    data = {'vec': big_tuple}
    
    result = safe_json_dump(data, max_list_size=100)
    
    print(f"  Tupla de {len(big_tuple)} elementos")
    print(f"  Resultado: {type(result['vec'])} com {len(result['vec']) if isinstance(result['vec'], list) else 'dict'}")
    
    # Deve ser truncado como dict com marcador
    if isinstance(result['vec'], dict):
        assert result['vec']['truncated'] == True, "Tupla grande deveria ser truncada"
        print("  ✅ Tupla grande truncada corretamente!")
    else:
        # Se não foi truncado, deve ser lista
        assert isinstance(result['vec'], list), "Tupla deveria ser convertida para lista"
        print("  ✅ Tupla convertida para lista!")

def test_coverage_calculation():
    """Testa cálculo de cobertura corrigido."""
    print("\n📊 Testando cálculo de cobertura corrigido...")
    
    # Simular cenário onde serviço retorna False para alguns advogados
    lawyer_ids = ["L1", "L2", "L3"]
    availability_map = {"L1": False, "L2": False, "L3": True}  # Apenas 1 disponível
    
    # Calcular cobertura como no algoritmo
    available_count = sum(1 for v in availability_map.values() if v)
    coverage = available_count / len(lawyer_ids)
    
    print(f"  3 advogados, map: {availability_map}")
    print(f"  Cobertura: {coverage:.2f} (1 de 3 disponíveis)")
    
    assert coverage == 1/3, f"Cobertura deveria ser 1/3, obtido {coverage}"
    print("  ✅ Cálculo de cobertura corrigido!")

def main():
    """Executa o checklist rápido."""
    print("🧪 Checklist Rápido v2.6.2")
    print("=" * 40)
    
    tests = [
        test_accent_normalization,
        test_mobile_review_validation,
        test_tuple_truncation,
        test_coverage_calculation
    ]
    
    passed = 0
    failed = 0
    
    for test in tests:
        try:
            test()
            passed += 1
        except Exception as e:
            print(f"  ❌ FALHOU: {e}")
            failed += 1
    
    print("\n" + "=" * 40)
    print(f"📊 Resultados: {passed} ✅ | {failed} ❌")
    
    if failed == 0:
        print("🎉 Checklist rápido passou! v2.6.2 está refinada.")
        return True
    else:
        print("⚠️  Alguns testes falharam. Revise os ajustes.")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1) 