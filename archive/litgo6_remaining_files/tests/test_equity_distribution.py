"""
Testes para validar distribuição justa de casos entre advogados.
Verifica se advogados com menos casos recebem mais ofertas.
"""
import pytest
import numpy as np
from typing import List, Dict
from unittest.mock import Mock, patch

from backend.algoritmo_match import Lawyer, Case, KPI, MatchmakingAlgorithm


def create_test_lawyer(
    id: str,
    cases_30d: int,
    capacidade_mensal: int,
    success_rate: float = 0.8
) -> Lawyer:
    """Cria advogado de teste com parâmetros específicos."""
    return Lawyer(
        id=id,
        nome=f"Advogado {id}",
        tags_expertise=["Trabalhista"],
        geo_latlon=(-23.5505, -46.6333),
        curriculo_json={"anos_experiencia": 5},
        kpi=KPI(
            success_rate=success_rate,
            cases_30d=cases_30d,
            capacidade_mensal=capacidade_mensal,
            avaliacao_media=4.5,
            tempo_resposta_h=12,
            cv_score=0.7
        ),
        casos_historicos_embeddings=[np.random.rand(384) for _ in range(3)]
    )


def create_test_case() -> Case:
    """Cria caso de teste."""
    return Case(
        id="test_case_1",
        area="Trabalhista",
        subarea="Rescisão",
        urgency_h=48,
        coords=(-23.5505, -46.6333),
        complexity="MEDIUM",
        summary_embedding=np.random.rand(384)
    )


def count_lawyer_in_matches(lawyer_id: str, match_results: List[Dict]) -> int:
    """Conta quantas vezes um advogado aparece nos matches."""
    count = 0
    for result in match_results:
        for match in result["matches"]:
            if match.id == lawyer_id:
                count += 1
    return count


@pytest.mark.asyncio
async def test_fair_distribution():
    """Testa se advogados com menos casos recebem mais ofertas."""
    # Criar advogados com diferentes cargas
    lawyer_low_load = create_test_lawyer("lawyer_1", cases_30d=2, capacidade_mensal=10)
    lawyer_medium_load = create_test_lawyer("lawyer_2", cases_30d=5, capacidade_mensal=10)
    lawyer_high_load = create_test_lawyer("lawyer_3", cases_30d=8, capacidade_mensal=10)
    
    lawyers = [lawyer_low_load, lawyer_medium_load, lawyer_high_load]
    case = create_test_case()
    
    algo = MatchmakingAlgorithm()
    
    # Executar matching múltiplas vezes
    match_results = []
    for _ in range(10):
        matches = await algo.rank(case, lawyers, top_n=2)
        match_results.append({"matches": matches})
    
    # Contar aparições
    low_count = count_lawyer_in_matches("lawyer_1", match_results)
    medium_count = count_lawyer_in_matches("lawyer_2", match_results)
    high_count = count_lawyer_in_matches("lawyer_3", match_results)
    
    # Advogado com menor carga deve aparecer mais vezes
    assert low_count > high_count, f"Low load: {low_count}, High load: {high_count}"
    assert low_count >= medium_count, f"Low load: {low_count}, Medium load: {medium_count}"
    assert medium_count >= high_count, f"Medium load: {medium_count}, High load: {high_count}"


@pytest.mark.asyncio
async def test_capacity_limit():
    """Testa se advogados no limite de capacidade recebem menos ofertas."""
    # Advogado no limite de capacidade
    lawyer_at_limit = create_test_lawyer("lawyer_1", cases_30d=10, capacidade_mensal=10)
    # Advogado com capacidade disponível
    lawyer_available = create_test_lawyer("lawyer_2", cases_30d=3, capacidade_mensal=10)
    
    lawyers = [lawyer_at_limit, lawyer_available]
    case = create_test_case()
    
    algo = MatchmakingAlgorithm()
    matches = await algo.rank(case, lawyers, top_n=2)
    
    # Advogado com capacidade disponível deve vir primeiro
    assert matches[0].id == "lawyer_2"
    assert matches[1].id == "lawyer_1"
    
    # Verificar scores de equidade
    assert matches[0].scores["equity"] > matches[1].scores["equity"]


@pytest.mark.asyncio
async def test_round_robin_on_tie():
    """Testa round-robin quando há empate nos scores."""
    # Criar advogados idênticos
    lawyers = []
    for i in range(3):
        lawyer = create_test_lawyer(f"lawyer_{i}", cases_30d=5, capacidade_mensal=10)
        # Simular diferentes last_offered_at
        lawyer.last_offered_at = 1000000000 + (i * 3600)  # 1 hora de diferença
        lawyers.append(lawyer)
    
    case = create_test_case()
    algo = MatchmakingAlgorithm()
    
    # Executar matching
    matches = await algo.rank(case, lawyers, top_n=3)
    
    # Advogado com last_offered_at mais antigo deve vir primeiro
    assert matches[0].id == "lawyer_0"  # Mais antigo
    assert matches[1].id == "lawyer_1"
    assert matches[2].id == "lawyer_2"  # Mais recente


@pytest.mark.asyncio
async def test_equity_weight_calculation():
    """Testa cálculo do peso de equidade."""
    algo = MatchmakingAlgorithm()
    
    # Teste 1: Advogado com capacidade disponível
    kpi1 = KPI(
        success_rate=0.8,
        cases_30d=3,
        capacidade_mensal=10,
        avaliacao_media=4.5,
        tempo_resposta_h=12
    )
    weight1 = algo.equity_weight(kpi1)
    assert weight1 == 0.7  # 1 - (3/10) = 0.7
    
    # Teste 2: Advogado no limite
    kpi2 = KPI(
        success_rate=0.8,
        cases_30d=10,
        capacidade_mensal=10,
        avaliacao_media=4.5,
        tempo_resposta_h=12
    )
    weight2 = algo.equity_weight(kpi2)
    assert weight2 == 0.05  # OVERLOAD_FLOOR
    
    # Teste 3: Advogado acima do limite
    kpi3 = KPI(
        success_rate=0.8,
        cases_30d=15,
        capacidade_mensal=10,
        avaliacao_media=4.5,
        tempo_resposta_h=12
    )
    weight3 = algo.equity_weight(kpi3)
    assert weight3 == 0.05  # OVERLOAD_FLOOR


@pytest.mark.asyncio
async def test_distribution_metrics():
    """Testa métricas de distribuição (Coeficiente de Gini)."""
    # Criar 10 advogados com diferentes cargas
    lawyers = []
    case_counts = [2, 3, 3, 4, 5, 5, 6, 7, 8, 9]  # Distribuição desigual
    
    for i, count in enumerate(case_counts):
        lawyer = create_test_lawyer(f"lawyer_{i}", cases_30d=count, capacidade_mensal=10)
        lawyers.append(lawyer)
    
    # Calcular coeficiente de Gini
    def gini_coefficient(values):
        """Calcula coeficiente de Gini (0 = perfeita igualdade, 1 = máxima desigualdade)."""
        sorted_values = sorted(values)
        n = len(values)
        cumsum = np.cumsum(sorted_values)
        return (n + 1 - 2 * np.sum(cumsum) / cumsum[-1]) / n
    
    gini = gini_coefficient(case_counts)
    assert gini < 0.3, f"Coeficiente de Gini muito alto: {gini}"
    
    # Simular distribuição após matching
    case = create_test_case()
    algo = MatchmakingAlgorithm()
    
    # Executar vários matches
    for _ in range(20):
        matches = await algo.rank(case, lawyers, top_n=3)
        # Atualizar contagem simulada
        for match in matches:
            idx = int(match.id.split("_")[1])
            case_counts[idx] += 1
    
    # Verificar se distribuição melhorou
    new_gini = gini_coefficient(case_counts)
    assert new_gini <= gini, "Distribuição não melhorou após matching com equidade"


if __name__ == "__main__":
    import asyncio
    
    # Executar testes
    asyncio.run(test_fair_distribution())
    asyncio.run(test_capacity_limit())
    asyncio.run(test_round_robin_on_tie())
    asyncio.run(test_equity_weight_calculation())
    asyncio.run(test_distribution_metrics())
    
    print("✅ Todos os testes de equidade passaram!") 