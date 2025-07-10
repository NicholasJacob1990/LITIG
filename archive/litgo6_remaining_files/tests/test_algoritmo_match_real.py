"""
Testes para o módulo algoritmo_match real
"""
import pytest
import numpy as np
from unittest.mock import Mock, patch, MagicMock
from pathlib import Path
from backend.algoritmo_match import (
    load_weights, load_preset, haversine, cosine_similarity,
    Case, KPI, Lawyer, FeatureCalculator, MatchmakingAlgorithm,
    DEFAULT_WEIGHTS, PRESET_WEIGHTS
)


def test_load_weights_default():
    """Testa carregamento de pesos padrão"""
    with patch('pathlib.Path.exists', return_value=False):
        weights = load_weights()
        assert weights == DEFAULT_WEIGHTS
        assert 'A' in weights
        assert 'S' in weights
        assert sum(weights.values()) == pytest.approx(1.03)  # Soma com feature C


def test_load_weights_from_file():
    """Testa carregamento de pesos de arquivo"""
    mock_weights = {
        'A': 0.25, 'S': 0.20, 'T': 0.15, 'G': 0.10,
        'Q': 0.10, 'U': 0.10, 'R': 0.05, 'C': 0.05
    }
    
    with patch('pathlib.Path.exists', return_value=True):
        with patch('builtins.open', mock_open(read_data=json.dumps(mock_weights))):
            weights = load_weights()
            assert weights == mock_weights
            assert sum(weights.values()) == pytest.approx(1.0)


def test_load_preset():
    """Testa carregamento de presets"""
    fast_preset = load_preset('fast')
    assert fast_preset == PRESET_WEIGHTS['fast']
    assert fast_preset['A'] == 0.40
    
    expert_preset = load_preset('expert')
    assert expert_preset == PRESET_WEIGHTS['expert']
    assert expert_preset['Q'] == 0.15
    
    # Preset inexistente retorna DEFAULT_WEIGHTS
    unknown_preset = load_preset('unknown')
    assert unknown_preset == DEFAULT_WEIGHTS


def test_haversine():
    """Testa cálculo de distância haversine"""
    # São Paulo para Rio de Janeiro
    sp = (-23.5505, -46.6333)
    rj = (-22.9068, -43.1729)
    
    dist = haversine(sp, rj)
    assert 350 < dist < 370  # ~357 km
    
    # Mesma localização
    assert haversine(sp, sp) == pytest.approx(0.0)


def test_cosine_similarity():
    """Testa similaridade de cosseno"""
    vec1 = np.array([1, 0, 0])
    vec2 = np.array([0, 1, 0])
    vec3 = np.array([1, 0, 0])
    
    assert cosine_similarity(vec1, vec3) == pytest.approx(1.0)
    assert cosine_similarity(vec1, vec2) == pytest.approx(0.0)


def test_case_dataclass():
    """Testa dataclass Case"""
    case = Case(
        id="case123",
        area="Trabalhista",
        subarea="Rescisão",
        urgency_h=48,
        coords=(-23.5505, -46.6333),
        complexity="HIGH"
    )
    assert case.id == "case123"
    assert case.area == "Trabalhista"
    assert case.complexity == "HIGH"
    assert case.summary_embedding.shape == (384,)


def test_lawyer_dataclass():
    """Testa dataclass Lawyer"""
    kpi = KPI(
        success_rate=0.85,
        cases_30d=10,
        avaliacao_media=4.5,
        tempo_resposta_h=12,
        cv_score=0.8
    )
    
    lawyer = Lawyer(
        id="lawyer123",
        nome="Dr. Teste",
        tags_expertise=["Trabalhista", "Civil"],
        geo_latlon=(-23.5505, -46.6333),
        curriculo_json={"anos_experiencia": 10},
        kpi=kpi,
        kpi_softskill=0.75
    )
    
    assert lawyer.id == "lawyer123"
    assert lawyer.kpi.success_rate == 0.85
    assert lawyer.kpi_softskill == 0.75
    assert isinstance(lawyer.case_outcomes, list)


class TestFeatureCalculator:
    """Testes para o FeatureCalculator"""
    
    @pytest.fixture
    def sample_case(self):
        return Case(
            id="test_case",
            area="Trabalhista",
            subarea="Rescisão",
            urgency_h=48,
            coords=(-23.5505, -46.6333),
            complexity="MEDIUM",
            summary_embedding=np.random.rand(384)
        )
    
    @pytest.fixture
    def sample_lawyer(self):
        return Lawyer(
            id="test_lawyer",
            nome="Dr. Teste",
            tags_expertise=["Trabalhista", "Civil"],
            geo_latlon=(-23.5505, -46.6333),
            curriculo_json={
                "anos_experiencia": 10,
                "pos_graduacoes": [
                    {"nivel": "mestrado", "area": "Direito Trabalhista"}
                ],
                "num_publicacoes": 5
            },
            kpi=KPI(
                success_rate=0.85,
                cases_30d=10,
                avaliacao_media=4.5,
                tempo_resposta_h=12,
                cv_score=0.8
            ),
            kpi_subarea={"Trabalhista/Rescisão": 0.90},
            kpi_softskill=0.75,
            case_outcomes=[True, True, False, True],
            casos_historicos_embeddings=[np.random.rand(384) for _ in range(3)]
        )
    
    def test_area_match(self, sample_case, sample_lawyer):
        """Testa match de área"""
        calc = FeatureCalculator(sample_case, sample_lawyer)
        assert calc.area_match() == 1.0
        
        # Teste sem match
        sample_lawyer.tags_expertise = ["Civil"]
        calc2 = FeatureCalculator(sample_case, sample_lawyer)
        assert calc2.area_match() == 0.0
    
    def test_geo_score(self, sample_case, sample_lawyer):
        """Testa score geográfico"""
        calc = FeatureCalculator(sample_case, sample_lawyer)
        # Mesma localização
        assert calc.geo_score() == pytest.approx(1.0)
        
        # Localização distante
        sample_lawyer.geo_latlon = (-22.9068, -43.1729)  # Rio
        calc2 = FeatureCalculator(sample_case, sample_lawyer)
        assert calc2.geo_score() < 0.1
    
    def test_all_features(self, sample_case, sample_lawyer):
        """Testa cálculo de todas as features"""
        calc = FeatureCalculator(sample_case, sample_lawyer)
        features = calc.all()
        
        assert "A" in features
        assert "S" in features
        assert "T" in features
        assert "G" in features
        assert "Q" in features
        assert "U" in features
        assert "R" in features
        assert "C" in features
        
        # Verificar ranges
        for feat, value in features.items():
            assert 0 <= value <= 1, f"Feature {feat} fora do range [0,1]: {value}"


class TestMatchmakingAlgorithm:
    """Testes para o MatchmakingAlgorithm"""
    
    def test_equity_weight(self):
        """Testa cálculo de peso de equidade"""
        kpi_low_load = KPI(
            success_rate=0.8, cases_30d=5,
            avaliacao_media=4.0, tempo_resposta_h=12
        )
        assert MatchmakingAlgorithm.equity_weight(kpi_low_load, 20) == 0.75
        
        kpi_overload = KPI(
            success_rate=0.8, cases_30d=25,
            avaliacao_media=4.0, tempo_resposta_h=12
        )
        assert MatchmakingAlgorithm.equity_weight(kpi_overload, 20) == 0.05
    
    def test_apply_dynamic_weights(self):
        """Testa aplicação de pesos dinâmicos"""
        base_weights = DEFAULT_WEIGHTS.copy()
        
        # Caso complexo
        case_high = Case(
            id="high", area="Civil", subarea="Contratos",
            urgency_h=72, coords=(0, 0), complexity="HIGH"
        )
        weights_high = MatchmakingAlgorithm.apply_dynamic_weights(case_high, base_weights)
        assert weights_high["Q"] > base_weights["Q"]
        assert weights_high["T"] > base_weights["T"]
        assert sum(weights_high.values()) == pytest.approx(1.0)
        
        # Caso simples
        case_low = Case(
            id="low", area="Civil", subarea="Contratos",
            urgency_h=24, coords=(0, 0), complexity="LOW"
        )
        weights_low = MatchmakingAlgorithm.apply_dynamic_weights(case_low, base_weights)
        assert weights_low["U"] > base_weights["U"]
        assert weights_low["G"] > base_weights["G"]
        assert sum(weights_low.values()) == pytest.approx(1.0)
    
    @pytest.mark.asyncio
    async def test_rank_basic(self):
        """Testa ranking básico de advogados"""
        # Criar caso de teste
        case = Case(
            id="test_case",
            area="Trabalhista",
            subarea="Rescisão",
            urgency_h=48,
            coords=(-23.5505, -46.6333),
            complexity="MEDIUM"
        )
        
        # Criar advogados de teste
        lawyers = []
        for i in range(3):
            kpi = KPI(
                success_rate=0.7 + i * 0.1,
                cases_30d=5 + i * 3,
                avaliacao_media=4.0 + i * 0.2,
                tempo_resposta_h=12 - i * 2,
                cv_score=0.7 + i * 0.1
            )
            lawyer = Lawyer(
                id=f"lawyer_{i}",
                nome=f"Dr. Teste {i}",
                tags_expertise=["Trabalhista"] if i < 2 else ["Civil"],
                geo_latlon=(-23.5505, -46.6333),
                curriculo_json={"anos_experiencia": 5 + i * 5},
                kpi=kpi,
                kpi_softskill=0.6 + i * 0.1
            )
            lawyers.append(lawyer)
        
        # Mock do cache Redis
        with patch('backend.algoritmo_match.cache.get_static_feats', return_value=None):
            with patch('backend.algoritmo_match.cache.set_static_feats', return_value=None):
                algo = MatchmakingAlgorithm()
                ranked = await algo.rank(case, lawyers, top_n=2)
                
                assert len(ranked) == 2
                assert all(hasattr(lw, 'scores') for lw in ranked)
                assert all('fair' in lw.scores for lw in ranked)
                assert all('features' in lw.scores for lw in ranked)
                assert all('delta' in lw.scores for lw in ranked)


# Helpers para mock
from unittest.mock import mock_open
import json 