#!/usr/bin/env python3
"""
Testes das melhorias implementadas na v2.6.1
"""
import asyncio
import json
import os
import sys
import tempfile
from pathlib import Path

# Adiciona o diretório raiz ao path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Import após adicionar ao path
from backend.algoritmo_match import (
    FeatureCalculator, Case, Lawyer, KPI,
    safe_json_dump, load_weights, load_experimental_weights,
    HAS_PROMETHEUS, AVAIL_DEGRADED
)
import numpy as np


def test_soft_skills_calculation():
    """Testa cálculo de soft-skills a partir de reviews"""
    print("\n🧪 Teste 1: Cálculo de Soft-skills")
    
    # Caso de teste
    case = Case(
        id="test_soft",
        area="Civil",
        subarea="Contratos",
        urgency_h=24,
        coords=(-23.5, -46.6),
        complexity="MEDIUM"
    )
    
    # Advogado com reviews positivos
    lawyer_positive = Lawyer(
        id="L1",
        nome="Advogado Positivo",
        tags_expertise=["Civil"],
        geo_latlon=(-23.5, -46.6),
        curriculo_json={"anos_experiencia": 10},
        kpi=KPI(success_rate=0.8, cases_30d=10, avaliacao_media=4.5,
                tempo_resposta_h=12, active_cases=5),  # Sem score externo
        kpi_softskill=0,  # Sem score externo
        review_texts=[
            "Advogado muito atencioso e dedicado, sempre disponível para esclarecer dúvidas.",
            "Profissional competente e organizado. Recomendo fortemente!",
            "Excelente comunicação, muito claro e transparente em todo o processo.",
            "Pontual e responsável, resolveu meu caso com agilidade."
        ]
    )
    
    # Advogado com reviews mistos
    lawyer_mixed = Lawyer(
        id="L2",
        nome="Advogado Misto",
        tags_expertise=["Civil"],
        geo_latlon=(-23.5, -46.6),
        curriculo_json={"anos_experiencia": 8},
        kpi=KPI(success_rate=0.7, cases_30d=15, avaliacao_media=3.5,
                tempo_resposta_h=24, active_cases=8),
        kpi_softskill=0,
        review_texts=[
            "Competente mas um pouco desorganizado com prazos.",
            "Bom profissional, porém demorado para responder mensagens.",
            "Resolveu o caso mas poderia ser mais comunicativo."
        ]
    )
    
    # Calcula soft-skills
    calc_positive = FeatureCalculator(case, lawyer_positive)
    calc_mixed = FeatureCalculator(case, lawyer_mixed)
    
    score_positive = calc_positive.soft_skill()
    score_mixed = calc_mixed.soft_skill()
    
    print(f"  Advogado Positivo: {score_positive:.3f} (esperado > 0.7)")
    print(f"  Advogado Misto: {score_mixed:.3f} (esperado 0.4-0.6)")
    
    assert score_positive > 0.7, "Score positivo deveria ser alto"
    assert 0.4 <= score_mixed <= 0.6, "Score misto deveria ser médio"
    print("  ✅ Cálculo de soft-skills funcionando!")


def test_weights_validation():
    """Testa validação de pesos com chaves extras"""
    print("\n🧪 Teste 2: Validação de Pesos")
    
    with tempfile.TemporaryDirectory() as tmpdir:
        # Arquivo com chaves extras
        weights_file = Path(tmpdir) / "ltr_weights.json"
        weights_file.write_text(json.dumps({
            "A": 0.3, "S": 0.2, "T": 0.15, "G": 0.1,
            "Q": 0.1, "U": 0.05, "R": 0.05, "C": 0.05,
            "CHAVE_FANTASMA": 0.99,  # Não deveria entrar
            "OUTRA_INVALIDA": 0.5
        }))
        
        # Mock do caminho
        from unittest.mock import patch
        with patch('backend.algoritmo_match.WEIGHTS_FILE', weights_file):
            weights = load_weights()
            
            # Verifica que chaves fantasma foram filtradas
            assert "CHAVE_FANTASMA" not in weights
            assert "OUTRA_INVALIDA" not in weights
            assert len(weights) == 8  # Apenas as 8 features válidas
            
            print(f"  ✅ Chaves filtradas: {len(weights)} features válidas")
            print(f"  ✅ Chaves fantasma removidas com sucesso")


def test_safe_json_truncation():
    """Testa truncamento melhorado com checksum estável"""
    print("\n🧪 Teste 3: Truncamento com Checksum Estável")
    
    # Array grande
    big_array = np.random.rand(500)
    
    # Dados com arrays aninhados
    data = {
        "embeddings": big_array,
        "nested": {
            "another_array": np.random.rand(200),
            "small": [1, 2, 3]
        }
    }
    
    # Primeira conversão
    result1 = safe_json_dump(data)
    
    # Segunda conversão (deveria ter mesmo checksum)
    result2 = safe_json_dump(data)
    
    # Verifica checksums
    checksum1 = result1["embeddings"]["checksum"]
    checksum2 = result2["embeddings"]["checksum"]
    
    print(f"  Checksum 1: {checksum1}")
    print(f"  Checksum 2: {checksum2}")
    assert checksum1 == checksum2, "Checksums deveriam ser idênticos"
    
    # Verifica marcador _truncated
    assert result1["embeddings"]["_truncated"] == True
    assert result1["nested"]["another_array"]["_truncated"] == True
    
    # Testa re-processamento (não deveria re-truncar)
    result3 = safe_json_dump(result1)  # Passa resultado já truncado
    assert result3["embeddings"] == result1["embeddings"]  # Idêntico, não reprocessado
    
    print("  ✅ Checksum estável funcionando")
    print("  ✅ Prevenção de re-truncamento ativa")


def test_noop_counter():
    """Testa NoOpCounter quando Prometheus não disponível"""
    print("\n🧪 Teste 4: No-op Counter")
    
    if HAS_PROMETHEUS:
        print("  ⚠️  Prometheus disponível, testando com mock...")
        
    # Testa que AVAIL_DEGRADED sempre existe e é chamável
    try:
        AVAIL_DEGRADED.inc()
        AVAIL_DEGRADED.inc(1)
        AVAIL_DEGRADED.inc(amount=5)
        print("  ✅ AVAIL_DEGRADED.inc() não causa erros")
    except Exception as e:
        print(f"  ❌ Erro ao chamar inc(): {e}")
        raise
    
    # Verifica tipo
    if not HAS_PROMETHEUS:
        assert AVAIL_DEGRADED.__class__.__name__ == "NoOpCounter"
        print("  ✅ NoOpCounter ativo quando Prometheus ausente")
    else:
        print("  ✅ Counter Prometheus real ativo")


async def main():
    print("=" * 60)
    print("🚀 Testes v2.6.1 - Melhorias Implementadas")
    print("=" * 60)
    
    # Teste 1: Soft-skills
    test_soft_skills_calculation()
    
    # Teste 2: Validação de pesos
    test_weights_validation()
    
    # Teste 3: Truncamento melhorado
    test_safe_json_truncation()
    
    # Teste 4: No-op Counter
    test_noop_counter()
    
    print("\n" + "=" * 60)
    print("✅ Todas as melhorias v2.6.1 testadas com sucesso!")
    print("=" * 60)
    
    print("\n📋 Resumo das Melhorias:")
    print("1. ✅ Soft-skills calculados a partir de keywords em reviews")
    print("2. ✅ Pesos filtrados para evitar chaves fantasma")
    print("3. ✅ Checksum estável com hashlib.sha1")
    print("4. ✅ Prevenção de re-truncamento com _truncated")
    print("5. ✅ NoOpCounter elegante quando sem Prometheus")


if __name__ == "__main__":
    from unittest.mock import patch
    asyncio.run(main()) 