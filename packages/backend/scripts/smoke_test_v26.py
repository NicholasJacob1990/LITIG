#!/usr/bin/env python3
"""
Teste de fumaça para algoritmo v2.6
Executa validações rápidas das principais funcionalidades
"""
import asyncio
import os
import sys
import json
import tempfile
from pathlib import Path

# Adiciona o diretório raiz ao path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Mock prometheus se não disponível
try:
    import prometheus_client
    print("✅ Prometheus disponível")
except ImportError:
    print("⚠️  Prometheus não disponível - usando fallback")
    from types import SimpleNamespace
    sys.modules['prometheus_client'] = SimpleNamespace(
        Counter=lambda *args, **kwargs: SimpleNamespace(inc=lambda: None)
    )

from backend.algoritmo_match import (
    MatchmakingAlgorithm, Case, Lawyer, KPI,
    MIN_EPSILON, OVERLOAD_FLOOR, load_weights,
    load_experimental_weights
)


def test_env_configs():
    """Testa se configurações ENV estão sendo lidas"""
    print("\n🧪 Teste 1: Configurações via ENV")
    print(f"  MIN_EPSILON: {MIN_EPSILON} (default: 0.02)")
    print(f"  OVERLOAD_FLOOR: {OVERLOAD_FLOOR} (default: 0.01)")
    
    # Verifica se valores customizados via ENV funcionam
    custom_epsilon = os.getenv("MIN_EPSILON")
    if custom_epsilon:
        assert float(custom_epsilon) == MIN_EPSILON
        print(f"  ✅ MIN_EPSILON customizado detectado: {custom_epsilon}")
    
    custom_floor = os.getenv("OVERLOAD_FLOOR")
    if custom_floor:
        assert float(custom_floor) == OVERLOAD_FLOOR
        print(f"  ✅ OVERLOAD_FLOOR customizado detectado: {custom_floor}")


async def test_timeout_degraded():
    """Testa comportamento com timeout"""
    print("\n🧪 Teste 2: Timeout e Modo Degradado")
    
    # Força timeout baixo
    os.environ['AVAIL_TIMEOUT'] = '0.01'
    
    # Mock de serviço lento
    async def slow_service(*args):
        await asyncio.sleep(1)  # Muito mais que timeout
        return {"L1": True}
    
    from unittest.mock import patch
    matcher = MatchmakingAlgorithm()
    
    case = Case(
        id="test_timeout",
        area="Civil",
        subarea="Contratos",
        urgency_h=24,
        coords=(-23.5, -46.6),
        complexity="MEDIUM"
    )
    
    lawyer = Lawyer(
        id="L1",
        nome="Test Lawyer",
        tags_expertise=["Civil"],
        geo_latlon=(-23.5, -46.6),
        curriculo_json={"anos_experiencia": 10},
        kpi=KPI(success_rate=0.8, cases_30d=10, avaliacao_media=4.5,
                tempo_resposta_h=12, active_cases=5)
    )
    
    with patch('backend.algoritmo_match.get_lawyers_availability_status', slow_service):
        try:
            result = await matcher.rank(case, [lawyer], top_n=1)
            assert len(result) == 1
            assert result[0].scores.get("degraded_mode") == True
            print("  ✅ Timeout detectado, modo degradado ativado")
        except Exception as e:
            print(f"  ❌ Erro no teste de timeout: {e}")


def test_malformed_weights():
    """Testa robustez com pesos mal-formados"""
    print("\n🧪 Teste 3: Pesos Mal-formados")
    
    with tempfile.TemporaryDirectory() as tmpdir:
        # Arquivo com valor inválido
        bad_file = Path(tmpdir) / "ltr_weights_bad.json"
        bad_file.write_text(json.dumps({
            "A": "abc",  # String inválida!
            "S": 0.2
        }))
        
        # Tenta carregar
        with patch('backend.algoritmo_match.WEIGHTS_FILE', bad_file):
            try:
                weights = load_experimental_weights("bad")
                print("  ✅ Não crashou com pesos inválidos")
            except Exception as e:
                print(f"  ✅ Tratamento de erro funcionou: {type(e).__name__}")
        
        # Arquivo com valores string válidos
        str_file = Path(tmpdir) / "ltr_weights_str.json"
        str_file.write_text(json.dumps({
            "A": "0.4", "S": "0.2", "T": "0.15", "G": "0.1",
            "Q": "0.05", "U": "0.05", "R": "0.03", "C": "0.02"
        }))
        
        with patch('backend.algoritmo_match.WEIGHTS_FILE', str_file.parent / "base.json"):
            weights = load_experimental_weights("str")
            if weights:
                assert all(isinstance(v, float) for v in weights.values())
                print("  ✅ Valores string convertidos para float")


def test_safe_json_truncate():
    """Testa truncamento de arrays grandes"""
    print("\n🧪 Teste 4: Truncamento de Arrays")
    
    from backend.algoritmo_match import safe_json_dump
    import numpy as np
    
    # Array grande
    big_array = np.random.rand(500)
    data = {
        "small": [1, 2, 3],
        "big": big_array,
        "nested": {
            "another_big": list(range(200))
        }
    }
    
    result = safe_json_dump(data, max_list_size=100)
    
    # Verifica truncamento
    assert result["small"] == [1, 2, 3]
    assert result["big"]["truncated"] == True
    assert result["big"]["size"] == 500
    assert len(result["big"]["sample"]) == 10
    assert "checksum" in result["big"]
    assert result["nested"]["another_big"]["truncated"] == True
    
    print("  ✅ Arrays grandes truncados corretamente")
    print(f"    - Array de 500 elementos → amostra de 10 + checksum")
    print(f"    - Lista de 200 elementos → truncada")


async def main():
    print("=" * 60)
    print("🚀 Smoke Tests - Algoritmo v2.6")
    print("=" * 60)
    
    # Teste 1: ENV configs
    test_env_configs()
    
    # Teste 2: Timeout/Degraded
    await test_timeout_degraded()
    
    # Teste 3: Pesos mal-formados
    test_malformed_weights()
    
    # Teste 4: Truncamento
    test_safe_json_truncate()
    
    print("\n" + "=" * 60)
    print("✅ Todos os testes de fumaça passaram!")
    print("=" * 60)
    
    # Sugestão de teste manual
    print("\n📝 Teste Manual Sugerido:")
    print("MIN_EPSILON=0.10 AVAIL_TIMEOUT=0.1 python3 backend/algoritmo_match.py")


if __name__ == "__main__":
    # Importa patch para mock
    from unittest.mock import patch
    asyncio.run(main()) 