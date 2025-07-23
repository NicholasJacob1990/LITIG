# -*- coding: utf-8 -*-
"""
Exemplo Prático: Pipeline de Enriquecimento + Algoritmo de Ranking
================================================================
Demonstra como usar a pipeline completa na prática.
"""

import asyncio
import json
from typing import List
import sys
import os

# Adicionar path para imports
sys.path.append(os.path.dirname(os.path.dirname(__file__)))

# Mock das classes para demonstração
class MockCase:
    def __init__(self, id: str, area: str, expected_fee_max: float = None):
        self.id = id
        self.area = area
        self.subarea = "Contratos"
        self.urgency_h = 48
        self.coords = (-23.5505, -46.6333)
        self.complexity = "MEDIUM"
        self.expected_fee_max = expected_fee_max
        self.radius_km = 50

class MockLawyer:
    def __init__(self, id: str, nome: str, experiencia: int = 5):
        self.id = id
        self.nome = nome
        self.tags_expertise = ["civil", "empresarial"]
        self.geo_latlon = (-23.5505, -46.6333)
        self.curriculo_json = {
            "anos_experiencia": experiencia,
            "pos_graduacoes": []
        }
        self.scores = {}
        self.avg_hourly_fee = 250.0
        self.maturity_data = None

# Função principal de demonstração
async def demo_complete_enrichment_pipeline():
    """Demonstra o uso completo da pipeline de enriquecimento."""
    
    print("🚀 DEMO: Pipeline Completa de Enriquecimento")
    print("=" * 60)
    
    # CENÁRIO 1: Caso com orçamento baixo (preset econômico automático)
    print("\n📋 CENÁRIO 1: Caso com Orçamento Baixo")
    case_economico = MockCase(
        id="CASO_ECO_001",
        area="Direito Civil",
        expected_fee_max=1200.0  # < R$ 1.500 → preset econômico
    )
    
    lawyers_economico = [
        MockLawyer("ADV_LOCAL_001", "Dr. João Silva", 8),
        MockLawyer("ADV_PREMIUM_001", "Dr. Carlos Premium", 20),
        MockLawyer("ADV_JUNIOR_001", "Dra. Ana Júnior", 3)
    ]
    
    print(f"Caso: {case_economico.id} ({case_economico.area})")
    print(f"Orçamento máximo: R$ {case_economico.expected_fee_max:,.2f}")
    print(f"Candidatos: {len(lawyers_economico)} advogados")
    
    # Simular resultado do preset econômico
    print("\n🎯 Resultado esperado com preset econômico:")
    print("   1º Dr. João Silva (experiência média, local, preço justo)")
    print("   2º Dra. Ana Júnior (junior, mas econômica)")
    print("   3º Dr. Carlos Premium (caro, penalizado pelo preset)")
    
    # CENÁRIO 2: Caso corporativo complexo
    print("\n📋 CENÁRIO 2: Caso Corporativo Complexo")
    case_corporativo = MockCase(
        id="CASO_CORP_001", 
        area="Direito Empresarial",
        expected_fee_max=15000.0  # Orçamento alto
    )
    
    lawyers_corporativo = [
        MockLawyer("ADV_BOUTIQUE_001", "Dr. Roberto Especialista", 15),
        MockLawyer("ADV_GENERALIST_001", "Dr. Pedro Generalista", 10),
        MockLawyer("ADV_SENIOR_001", "Dra. Marina Sênior", 25)
    ]
    
    print(f"Caso: {case_corporativo.id} ({case_corporativo.area})")
    print(f"Orçamento máximo: R$ {case_corporativo.expected_fee_max:,.2f}")
    print(f"Candidatos: {len(lawyers_corporativo)} advogados")
    
    print("\n🎯 Resultado esperado com preset balanced/expert:")
    print("   1º Dra. Marina Sênior (experiência + qualificação)")
    print("   2º Dr. Roberto Especialista (especialização)")
    print("   3º Dr. Pedro Generalista (experiência adequada)")
    
    # EXEMPLO DE ENRIQUECIMENTO
    print("\n📊 EXEMPLO: Dados Enriquecidos por Feature")
    print("-" * 50)
    
    # Simular dados enriquecidos para Dr. João Silva
    enriched_data = {
        "publications": [
            {"journal": "Revista Brasileira de Direito Civil", "qualis_level": "A1", "score": 1.0},
            {"journal": "Revista de Direito Privado", "qualis_level": "B1", "score": 0.5}
        ],
        "academic_degree": {
            "level": "mestrado",
            "numeric_level": 3,
            "has_advanced_degree": True
        },
        "practical_experience": {
            "area_mentions": 15,
            "estimated_years": 8,
            "experience_score": 0.85,
            "has_relevant_experience": True
        },
        "multidisciplinary": {
            "other_areas_mentioned": {"engenharia": 2, "economia": 1},
            "multidisciplinary_score": 0.3,
            "is_multidisciplinary": True
        },
        "complex_cases": {
            "complex_themes": {"arbitragem": 3, "compliance": 1},
            "complexity_score": 0.4,
            "handles_complex_cases": True
        },
        "fee_information": {
            "monetary_values_found": ["R$ 250"],
            "preferred_fee_type": "hora",
            "has_fee_info": True
        },
        "reputation": {
            "reputation_signals": {"awards": 1, "rankings": 1, "media_mentions": 2},
            "reputation_score_normalized": 0.4,
            "has_strong_reputation": False
        }
    }
    
    print("Dr. João Silva - Dados Enriquecidos:")
    
    feature_mapping = {
        "publications": "S - Publicações QUALIS",
        "academic_degree": "T - Titulação Acadêmica", 
        "practical_experience": "E - Experiência Prática",
        "multidisciplinary": "M - Multidisciplinaridade",
        "complex_cases": "C - Casos Complexos",
        "fee_information": "P - Informações de Preço",
        "reputation": "R - Reputação Profissional"
    }
    
    for key, description in feature_mapping.items():
        data = enriched_data[key]
        if key == "publications":
            print(f"   📚 {description}: {len(data)} publicações encontradas")
            for pub in data:
                print(f"      • {pub['journal']} (Qualis {pub['qualis_level']})")
        elif key == "academic_degree":
            print(f"   🎓 {description}: {data['level'].title()} (nível {data['numeric_level']})")
        elif key == "practical_experience":
            print(f"   💼 {description}: {data['estimated_years']} anos, score {data['experience_score']:.2f}")
        elif key == "multidisciplinary":
            areas = ', '.join(data['other_areas_mentioned'].keys())
            print(f"   🔄 {description}: {areas}, score {data['multidisciplinary_score']:.2f}")
        elif key == "complex_cases":
            themes = ', '.join(data['complex_themes'].keys())
            print(f"   ⚖️ {description}: {themes}, score {data['complexity_score']:.2f}")
        elif key == "fee_information":
            values = ', '.join(data['monetary_values_found'])
            print(f"   💰 {description}: {values} ({data['preferred_fee_type']})")
        elif key == "reputation":
            signals = sum(data['reputation_signals'].values())
            print(f"   🏆 {description}: {signals} sinais, score {data['reputation_score_normalized']:.2f}")
    
    # IMPACTO NO RANKING
    print("\n📈 IMPACTO NO ALGORITMO DE RANKING")
    print("-" * 40)
    
    print("ANTES do enriquecimento:")
    print("   • Dados limitados (nome, área, experiência básica)")
    print("   • Features S, E, M, C, P, R com valores padrão/zero")
    print("   • Ranking baseado em ~30% das variáveis disponíveis")
    
    print("\nAPÓS o enriquecimento:")
    print("   • Perfil 360º completo do advogado")
    print("   • Todas as features alimentadas com dados reais")
    print("   • Ranking baseado em 100% das variáveis do algoritmo")
    print("   • Decisões mais justas e explicáveis")
    
    # EXEMPLO DE USO DA PIPELINE
    print("\n💻 CÓDIGO DE EXEMPLO DE USO")
    print("-" * 35)
    
    usage_code = '''
# 1. Importar pipeline completa
from services.complete_matching_pipeline import complete_lawyer_matching

# 2. Executar matching com enriquecimento
result = await complete_lawyer_matching(
    case=case_economico,
    candidate_lawyers=lawyers_economico,
    preset="balanced",  # Será auto-detectado como "economic"
    enrich_profiles=True,
    use_openai=True,
    use_perplexity=True
)

# 3. Acessar resultados
top_lawyer = result.ranked_lawyers[0]
enrichment_stats = result.get_enrichment_summary()
feature_coverage = result.get_feature_coverage()

# 4. Logs estruturados automáticos
print(f"Melhor advogado: {top_lawyer.nome}")
print(f"Score final: {top_lawyer.scores['fair_base']:.3f}")
print(f"Taxa de enriquecimento: {enrichment_stats['success_rate']:.1%}")
'''
    
    print(usage_code)
    
    # BENEFÍCIOS FINAIS
    print("\n🎯 BENEFÍCIOS DA PIPELINE COMPLETA")
    print("-" * 38)
    
    benefits = [
        "✅ Cobertura 100% das features do algoritmo",
        "✅ Dados enriquecidos em tempo real via APIs",
        "✅ Preset econômico para democratizar acesso",
        "✅ Fallback robusto (OpenAI → Perplexity → cache)",
        "✅ Parsing inteligente de relatórios",
        "✅ Logs estruturados para observabilidade",
        "✅ Controle de concorrência e rate limiting",
        "✅ Cache de 24h para performance",
        "✅ Conformidade com specs oficiais OpenAI",
        "✅ Explicabilidade completa das decisões"
    ]
    
    for benefit in benefits:
        print(f"   {benefit}")
    
    print("\n🚀 RESULTADO: Sistema de matching mais justo, preciso e transparente!")
    print("💡 Próximo passo: Deploy em produção com monitoramento ativo")


# Exemplo de configuração para produção
def production_config_example():
    """Exemplo de configuração para ambiente de produção."""
    
    config = {
        # APIs de enriquecimento
        "OPENAI_API_KEY": "sk-...",
        "PERPLEXITY_API_KEY": "pplx-...",
        
        # Controle de tráfego
        "MAX_CONCURRENT_ENRICHMENT": 5,
        "ENRICHMENT_TIMEOUT_SEC": 60,
        "CACHE_TTL_HOURS": 24,
        
        # Preset econômico
        "ECONOMIC_THRESHOLD": 1500.0,
        "AUTO_DETECT_ECONOMIC": True,
        
        # Observabilidade
        "STRUCTURED_LOGS": True,
        "PROMETHEUS_METRICS": True,
        "ENRICHMENT_AUDIT_LOG": True,
        
        # Fallback e resiliência
        "FALLBACK_TO_CACHE": True,
        "FAIL_OPEN_ON_ERROR": True,
        "RETRY_ATTEMPTS": 3
    }
    
    return config


if __name__ == "__main__":
    print("🎬 Executando demonstração da pipeline...")
    asyncio.run(demo_complete_enrichment_pipeline())
    
    print("\n⚙️ Configuração para produção:")
    config = production_config_example()
    for key, value in config.items():
        print(f"   {key}={value}")
    
    print("\n✨ Pipeline pronta para transformar o matching jurídico!") 