#!/usr/bin/env python3
"""
Demonstração do Algoritmo de Matching LITGO v2.8.1-adapter

Este arquivo contém exemplos de uso do algoritmo de matching,
incluindo criação de dados de teste e execução de demos.
"""

import asyncio
import time
from datetime import datetime
from typing import Dict, List, Optional

import numpy as np

# Imports do algoritmo principal
from LITGO6.backend.algoritmo_match import (
    Case, Lawyer, KPI, DiversityMeta, ProfessionalMaturityData,
    MatchmakingAlgorithm, EMBEDDING_DIM, algorithm_version
)


def make_lawyer_v2(id_num: int, exp: int, succ: float, load: int,
                   titles: List[Dict], soft_skill: float = 0.5,
                   kpi_subarea: Optional[Dict[str, float]] = None,
                   case_outcomes: Optional[List[bool]] = None,
                   success_status: str = "N",
                   diversity: Optional[DiversityMeta] = None) -> Lawyer:
    """
    Cria um advogado de teste com dados realistas.
    
    Args:
        id_num: Número identificador
        exp: Anos de experiência
        succ: Taxa de sucesso (0-1)
        load: Carga de trabalho (casos/mês)
        titles: Lista de títulos acadêmicos
        soft_skill: Score de soft skills (0-1)
        kpi_subarea: KPIs por subárea
        case_outcomes: Resultados de casos anteriores
        success_status: Status de sucesso ("V", "P", "N")
        diversity: Metadados de diversidade
        
    Returns:
        Objeto Lawyer configurado para testes
    """
    return Lawyer(
        id=f"ADV{id_num}",
        nome=f"Advogado {id_num}",
        tags_expertise=["civil", "criminal", "trabalhista"],
        geo_latlon=(-23.5505, -46.6333),
        curriculo_json={
            "anos_experiencia": exp,
            "pos_graduacoes": titles,
            "num_publicacoes": 5,
        },
        kpi=KPI(
            success_rate=succ,
            cases_30d=load,
            avaliacao_media=4.5,
            tempo_resposta_h=24,
            cv_score=0.8,
            success_status=success_status,
            active_cases=load//2,
        ),
        max_concurrent_cases=20,
        diversity=diversity,
        kpi_subarea=kpi_subarea or {},
        kpi_softskill=soft_skill,
        case_outcomes=case_outcomes or [True, False, True],
        review_texts=[f"Review {i + 1} for lawyer {id_num}" for i in range(5)],
        casos_historicos_embeddings=[
            np.random.rand(EMBEDDING_DIM) for _ in range(3)],
        maturity_data=ProfessionalMaturityData(
            experience_years=exp,
            network_strength=100,
            reputation_signals=50,
            responsiveness_hours=24
        )
    )


def create_demo_case() -> Case:
    """Cria um caso de teste com complexidade alta."""
    return Case(
        id="caso_v2_demo",
        area="Trabalhista",
        subarea="Rescisão",
        urgency_h=48,
        coords=(-23.5505, -46.6333),
        complexity="HIGH",
        summary_embedding=np.random.rand(EMBEDDING_DIM),
        expected_fee_min=5000.0,
        expected_fee_max=15000.0
    )


def create_demo_lawyers() -> List[Lawyer]:
    """Cria uma lista de advogados de teste com perfis diversos."""
    return [
        make_lawyer_v2(
            1, exp=15, succ=0.95, load=18,
            titles=[{"nivel": "mestrado", "area": "Trabalhista"}],
            soft_skill=0.8, case_outcomes=[True, True, True, False],
            success_status="V", 
            diversity=DiversityMeta(gender="F", ethnicity="parda")
        ),
        make_lawyer_v2(
            2, exp=12, succ=0.88, load=10,
            titles=[{"nivel": "lato", "area": "Trabalhista"}],
            soft_skill=0.6, case_outcomes=[True, False, True, True],
            success_status="P", 
            diversity=DiversityMeta(gender="M", ethnicity="branca", pcd=True)
        ),
        make_lawyer_v2(
            3, exp=20, succ=0.92, load=15,
            titles=[{"nivel": "doutorado", "area": "Trabalhista"}],
            soft_skill=0.9, case_outcomes=[True, True, True, True],
            success_status="V", 
            diversity=DiversityMeta(gender="M", ethnicity="branca", orientation="G")
        ),
        make_lawyer_v2(
            4, exp=8, succ=0.85, load=12,
            titles=[{"nivel": "lato", "area": "Civil"}],
            soft_skill=0.7, case_outcomes=[True, True, False, True],
            success_status="V", 
            diversity=DiversityMeta(gender="F", ethnicity="negra", lgbtqia=True)
        ),
        make_lawyer_v2(
            5, exp=25, succ=0.98, load=20,
            titles=[{"nivel": "doutorado", "area": "Trabalhista"}],
            soft_skill=0.95, case_outcomes=[True, True, True, True, True],
            success_status="V", 
            diversity=DiversityMeta(gender="M", ethnicity="indigena")
        )
    ]


async def demo_basic_matching():
    """Demonstração básica do algoritmo de matching."""
    print(f"🚀 Demo Básico do Algoritmo de Match {algorithm_version}")
    print("=" * 70)

    # Criar dados de teste
    case = create_demo_case()
    lawyers = create_demo_lawyers()

    # Inicializar algoritmo
    matcher = MatchmakingAlgorithm()

    # Executar matching com preset "expert" para caso complexo
    ranking = await matcher.rank(case, lawyers, top_n=3, preset="expert")

    # Exibir resultados
    print(f"\n—— Resultado do Ranking {algorithm_version} ——")
    for pos, adv in enumerate(ranking, 1):
        scores = adv.scores
        feats = scores["features"]
        delta = scores["delta"]

        print(f"\n{pos}º {adv.nome}")
        print(f"  Score Final: {scores['fair_base']:.3f} | LTR: {scores['ltr']:.3f} | Equity: {scores.get('equity_raw', 0):.3f}")
        print(f"  Features: A={feats['A']:.2f} S={feats['S']:.2f} T={feats['T']:.2f} G={feats['G']:.2f}")
        print(f"           Q={feats['Q']:.2f} U={feats['U']:.2f} R={feats['R']:.2f} C={feats['C']:.2f}")
        print(f"           E={feats['E']:.2f} P={feats['P']:.2f} M={feats['M']:.2f}")
        print(f"  Delta: {delta}")
        print(f"  Preset: {scores['preset']} | Complexity: {scores['complexity']}")
        print(f"  Degraded Mode: {'SIM' if scores.get('degraded_mode', False) else 'NÃO'}")
        print(f"  Last offered: {datetime.fromtimestamp(adv.last_offered_at).isoformat()}")

    print(f"\n📊 Observações {algorithm_version}:")
    print("• Algoritmo refatorado com Clean Architecture")
    print("• Injeção de dependências implementada")
    print("• Feature-M (Maturity) com padrão Adapter")
    print("• Logs estruturados com versionamento")
    print("• Fairness multi-dimensional")


async def demo_preset_comparison():
    """Demonstração comparando diferentes presets."""
    print(f"\n🔄 Demo Comparação de Presets {algorithm_version}")
    print("=" * 70)

    case = create_demo_case()
    lawyers = create_demo_lawyers()
    matcher = MatchmakingAlgorithm()

    presets = ["fast", "expert", "balanced", "economic", "b2b"]
    
    for preset in presets:
        print(f"\n--- Preset: {preset.upper()} ---")
        ranking = await matcher.rank(case, lawyers, top_n=2, preset=preset)
        
        for pos, adv in enumerate(ranking, 1):
            scores = adv.scores
            print(f"{pos}º {adv.nome} - Score: {scores['fair_base']:.3f} | LTR: {scores['ltr']:.3f}")


async def demo_dependency_injection():
    """Demonstração de injeção de dependências com mocks."""
    print(f"\n🔧 Demo Injeção de Dependências {algorithm_version}")
    print("=" * 70)

    # Mock services para demonstração
    class MockAvailabilityService:
        async def __call__(self, lawyer_ids):
            # Simula que apenas alguns advogados estão disponíveis
            return {lid: lid.endswith(('1', '3', '5')) for lid in lawyer_ids}

    class MockConflictService:
        def __call__(self, case, lawyer):
            # Simula conflito para advogados com ID par
            return lawyer.id.endswith(('2', '4'))

    class MockCache:
        async def get_static_feats(self, lawyer_id):
            return None  # Sempre miss para demo
        
        async def set_static_feats(self, lawyer_id, features):
            print(f"  📝 Cache: Salvando features para {lawyer_id}")

    # Inicializar com serviços mockados
    matcher = MatchmakingAlgorithm(
        availability_service=MockAvailabilityService(),
        conflict_service=MockConflictService(),
        cache_service=MockCache()
    )

    case = create_demo_case()
    lawyers = create_demo_lawyers()

    print("Executando matching com serviços mockados...")
    ranking = await matcher.rank(case, lawyers, top_n=3, preset="balanced")

    print(f"\nResultado ({len(ranking)} advogados selecionados):")
    for pos, adv in enumerate(ranking, 1):
        conflict_status = "✓ Sem conflito" if not adv.scores.get("conflict", False) else "⚠ Conflito"
        print(f"{pos}º {adv.nome} - {conflict_status}")


async def main():
    """Função principal que executa todas as demonstrações."""
    print("🎯 LITGO Matching Algorithm - Demonstrações")
    print("=" * 70)
    
    try:
        await demo_basic_matching()
        await demo_preset_comparison()
        await demo_dependency_injection()
        
        print(f"\n✅ Todas as demonstrações executadas com sucesso!")
        print(f"📋 Versão do algoritmo: {algorithm_version}")
        
    except Exception as e:
        print(f"\n❌ Erro durante a demonstração: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    asyncio.run(main()) 