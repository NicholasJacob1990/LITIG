"""
Testes para o algoritmo de match (backend/algoritmo_match.py)
"""
import pytest
import numpy as np
from uuid import uuid4
from unittest.mock import MagicMock

from backend.algoritmo_match import Case, Lawyer, KPI, FeatureCalculator, MatchmakingAlgorithm

# --- Fixtures ---

@pytest.fixture
def sample_case():
    """Caso de exemplo para os testes."""
    return Case(
        id=str(uuid4()),
        area="Trabalhista",
        subarea="Rescisão",
        urgency_h=48,
        coords=( -23.5505, -46.6333),
        summary_embedding=np.random.rand(384)
    )

@pytest.fixture
def sample_kpi():
    """KPI de exemplo para os advogados."""
    return KPI(
        success_rate=0.85,
        cases_30d=15,
        capacidade_mensal=20,
        avaliacao_media=4.7,
        tempo_resposta_h=8,
        cv_score=0.9,
        success_status="V"
    )

@pytest.fixture
def sample_lawyer(sample_kpi):
    """Advogado de exemplo para os testes."""
    return Lawyer(
        id=str(uuid4()),
        nome="Advogado Exemplo",
        tags_expertise=["Trabalhista", "Civil"],
        geo_latlon=(-23.561, -46.656), # ~1.5km de distância do caso
        curriculo_json={"anos_experiencia": 10, "pos_graduacoes": [{"nivel": "mestrado", "area": "Trabalhista"}]},
        kpi=sample_kpi,
        kpi_softskill=0.8,
        review_texts=["Ótimo advogado, muito atencioso e resolveu meu problema rapidamente.", "Excelente profissional!"],
        casos_historicos_embeddings=[np.random.rand(384) for _ in range(5)],
        case_outcomes=[True, True, False, True, True]
    )

# --- Testes do FeatureCalculator ---

def test_feature_calculator_area_match(sample_case, sample_lawyer):
    """Testa o match de área de atuação."""
    calculator = FeatureCalculator(sample_case, sample_lawyer)
    assert calculator.area_match() == 1.0
    
    sample_case.area = "Tributário"
    calculator = FeatureCalculator(sample_case, sample_lawyer)
    assert calculator.area_match() == 0.0

def test_case_similarity(sample_case, sample_lawyer):
    """Testa o cálculo de similaridade de casos."""
    # Garante que o embedding do caso seja idêntico a um dos históricos
    sample_lawyer.casos_historicos_embeddings[0] = sample_case.summary_embedding
    calculator = FeatureCalculator(sample_case, sample_lawyer)
    
    # A similaridade deve ser alta, mas não 1.0 devido à média ponderada
    similarity = calculator.case_similarity()
    assert 0.8 < similarity < 1.0

def test_success_rate(sample_case, sample_lawyer):
    """Testa o cálculo da taxa de sucesso com o multiplicador de status."""
    calculator = FeatureCalculator(sample_case, sample_lawyer)
    assert 0.7 < calculator.success_rate() < 0.8
    
    # Com status 'P' (provisório), a taxa de sucesso deve ser penalizada
    sample_lawyer.kpi.success_status = "P"
    calculator = FeatureCalculator(sample_case, sample_lawyer)
    assert 0.3 < calculator.success_rate() < 0.5
    
    # Com status 'N' (negativo), a taxa de sucesso deve ser 0
    sample_lawyer.kpi.success_status = "N"
    calculator = FeatureCalculator(sample_case, sample_lawyer)
    assert calculator.success_rate() == 0.0

def test_geo_score(sample_case, sample_lawyer):
    """Testa o cálculo do score geográfico."""
    calculator = FeatureCalculator(sample_case, sample_lawyer)
    assert 0.9 < calculator.geo_score() < 0.95
    
    # Movendo o advogado para longe
    sample_lawyer.geo_latlon = (-25.4284, -49.2733) # Curitiba
    calculator = FeatureCalculator(sample_case, sample_lawyer)
    assert calculator.geo_score() == 0.0

def test_qualification_score(sample_case, sample_lawyer):
    """Testa o score de qualificação."""
    calculator = FeatureCalculator(sample_case, sample_lawyer)
    assert 0.3 < calculator.qualification_score() < 0.4
    
    # Sem pós-graduação
    sample_lawyer.curriculo_json["pos_graduacoes"] = []
    calculator = FeatureCalculator(sample_case, sample_lawyer)
    assert calculator.qualification_score() < 0.7

def test_review_score(sample_case, sample_lawyer):
    """Testa o score de review, incluindo o filtro anti-spam."""
    calculator = FeatureCalculator(sample_case, sample_lawyer)
    # Com o filtro de confiança, o valor é menor
    assert 0.3 < calculator.review_score() < 0.4
    
    # Com reviews curtas/spam, o score deve ser penalizado
    sample_lawyer.review_texts = ["ok", "bom", "legal", "recomendo", "muito bom"]
    calculator = FeatureCalculator(sample_case, sample_lawyer)
    assert calculator.review_score() < 0.1

def test_equity_weight():
    """Testa o cálculo do peso de equidade."""
    # Advogado com alta capacidade
    kpi_free = KPI(success_rate=0.8, cases_30d=5, capacidade_mensal=20, avaliacao_media=4.5, tempo_resposta_h=8)
    assert MatchmakingAlgorithm.equity_weight(kpi_free) > 0.7
    
    # Advogado sobrecarregado
    kpi_overloaded = KPI(success_rate=0.8, cases_30d=25, capacidade_mensal=20, avaliacao_media=4.5, tempo_resposta_h=8)
    assert MatchmakingAlgorithm.equity_weight(kpi_overloaded) == pytest.approx(0.05) 