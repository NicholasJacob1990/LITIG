# -*- coding: utf-8 -*-
"""
Testes para o preset econômico do algoritmo de matching.
Valida detecção automática e aplicação correta dos pesos.
"""

import pytest
import numpy as np
from algoritmo_match import (
    MatchmakingAlgorithm, Case, Lawyer, KPI, 
    load_preset, PRESET_WEIGHTS
)


class TestEconomicPreset:
    """Testes para funcionalidade do preset econômico."""
    
    def test_economic_preset_exists(self):
        """Verifica se o preset economic está definido e soma 1.0."""
        economic_weights = PRESET_WEIGHTS.get("economic")
        assert economic_weights is not None, "Preset 'economic' não encontrado"
        
        total = sum(economic_weights.values())
        assert abs(total - 1.0) < 1e-6, f"Preset 'economic' não soma 1.0 (soma={total:.6f})"
        
        # Verificar pesos específicos do preset econômico
        assert economic_weights["G"] == 0.17, "Geografia deve ter peso alto no preset econômico"
        assert economic_weights["U"] == 0.17, "Urgência deve ter peso alto no preset econômico"
        assert economic_weights["P"] == 0.12, "Preço deve ter peso médio no preset econômico"
        assert economic_weights["Q"] == 0.04, "Qualificação deve ter peso baixo no preset econômico"
    
    def test_load_preset_economic(self):
        """Testa carregamento específico do preset econômico."""
        weights = load_preset("economic")
        
        # Verificar características do preset econômico
        assert weights["G"] > weights["Q"], "Geografia deve pesar mais que qualificação"
        assert weights["U"] > weights["S"], "Urgência deve pesar mais que similaridade"
        assert weights["P"] > 0, "Preço deve ter peso positivo"
        assert weights["E"] == 0.0, "Reputação da firma deve ser zero (advogados independentes)"
    
    @pytest.mark.asyncio
    async def test_economic_preset_application(self):
        """Testa aplicação prática do preset econômico no ranking."""
        # Setup: caso e advogados de teste
        case = Case(
            id="caso_economico",
            area="Civil",
            subarea="Contrato",
            urgency_h=24,
            coords=(-23.5505, -46.6333),
            expected_fee_max=800.0  # Orçamento baixo
        )
        
        lawyer = Lawyer(
            id="ADV_ECONOMIC",
            nome="Advogado Econômico",
            tags_expertise=["civil"],
            geo_latlon=(-23.5505, -46.6333),
            curriculo_json={"anos_experiencia": 5},
            kpi=KPI(
                success_rate=0.8,
                cases_30d=10,
                avaliacao_media=4.0,
                tempo_resposta_h=12,
                active_cases=3
            ),
            avg_hourly_fee=150.0  # Taxa compatível com orçamento
        )
        
        matcher = MatchmakingAlgorithm()
        ranking = await matcher.rank(
            case, [lawyer], 
            top_n=1, 
            preset="economic"
        )
        
        assert len(ranking) == 1
        ranked_lawyer = ranking[0]
        
        # Verificar se preset foi aplicado
        assert ranked_lawyer.scores["preset"] == "economic"
        
        # Verificar pesos específicos aplicados
        delta = ranked_lawyer.scores["delta"]
        features = ranked_lawyer.scores["features"]
        
        # Geografia deve ter peso alto (0.17)
        expected_geo_delta = features["G"] * 0.17
        assert abs(delta["G"] - expected_geo_delta) < 1e-6
        
        # Urgência deve ter peso alto (0.17)  
        expected_urgency_delta = features["U"] * 0.17
        assert abs(delta["U"] - expected_urgency_delta) < 1e-6
        
        # Qualificação deve ter peso baixo (0.04)
        expected_qual_delta = features["Q"] * 0.04
        assert abs(delta["Q"] - expected_qual_delta) < 1e-6
    
    @pytest.mark.asyncio
    async def test_automatic_economic_detection(self):
        """Testa detecção automática do preset econômico baseado no orçamento."""
        # Caso com orçamento baixo (< 1500)
        case_low_budget = Case(
            id="caso_automatico",
            area="Trabalhista", 
            subarea="Rescisão",
            urgency_h=48,
            coords=(-23.5505, -46.6333),
            expected_fee_max=1200.0  # Abaixo do threshold
        )
        
        lawyer = Lawyer(
            id="ADV_AUTO",
            nome="Advogado Auto",
            tags_expertise=["trabalhista"],
            geo_latlon=(-23.5505, -46.6333),
            curriculo_json={"anos_experiencia": 3},
            kpi=KPI(
                success_rate=0.75,
                cases_30d=8,
                avaliacao_media=4.2,
                tempo_resposta_h=18,
                active_cases=2
            )
        )
        
        matcher = MatchmakingAlgorithm()
        
        # Usar preset "balanced" mas deve auto-detectar "economic"
        ranking = await matcher.rank(
            case_low_budget, [lawyer],
            top_n=1,
            preset="balanced"  # Não especifica econômico explicitamente
        )
        
        # Deve ter detectado automaticamente o preset econômico
        assert ranking[0].scores["preset"] == "economic"
    
    @pytest.mark.asyncio 
    async def test_no_automatic_detection_high_budget(self):
        """Verifica que orçamento alto não ativa preset econômico."""
        case_high_budget = Case(
            id="caso_premium",
            area="Empresarial",
            subarea="M&A", 
            urgency_h=72,
            coords=(-23.5505, -46.6333),
            expected_fee_max=15000.0  # Acima do threshold
        )
        
        lawyer = Lawyer(
            id="ADV_PREMIUM", 
            nome="Advogado Premium",
            tags_expertise=["empresarial"],
            geo_latlon=(-23.5505, -46.6333),
            curriculo_json={"anos_experiencia": 15},
            kpi=KPI(
                success_rate=0.95,
                cases_30d=5,
                avaliacao_media=4.8,
                tempo_resposta_h=6,
                active_cases=1
            )
        )
        
        matcher = MatchmakingAlgorithm()
        ranking = await matcher.rank(
            case_high_budget, [lawyer],
            top_n=1,
            preset="balanced"
        )
        
        # Deve manter o preset balanced (não econômico)
        assert ranking[0].scores["preset"] == "balanced"
    
    def test_economic_preset_weight_distribution(self):
        """Verifica distribuição adequada de pesos no preset econômico."""
        weights = load_preset("economic")
        
        # Pesos geográficos e de urgência devem ser altos (proximidade e velocidade)
        high_priority = weights["G"] + weights["U"]  # 0.17 + 0.17 = 0.34
        assert high_priority > 0.3, "Geografia + Urgência devem ter peso total > 30%"
        
        # Preço deve ter peso significativo
        assert weights["P"] >= 0.10, "Preço deve ter pelo menos 10% de peso"
        
        # Qualificação deve ter peso reduzido (custo-benefício)
        assert weights["Q"] <= 0.05, "Qualificação deve ter peso baixo no modo econômico"
        
        # Reputação da firma deve ser zero (foco em advogados independentes)
        assert weights["E"] == 0.0, "Reputação da firma deve ser zero no modo econômico"


if __name__ == "__main__":
    pytest.main([__file__, "-v"]) 