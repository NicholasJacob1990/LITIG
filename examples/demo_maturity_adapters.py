#!/usr/bin/env python3
"""
Demonstração dos Adaptadores de Maturidade Profissional

Este exemplo mostra como usar o padrão Adapter implementado para
dados de maturidade profissional, permitindo trocar entre diferentes
APIs (Unipile, LinkedIn, etc.) sem modificar o algoritmo principal.
"""

import os
import sys
from pathlib import Path

# Adicionar path do backend
sys.path.insert(0, str(Path(__file__).parent.parent / "packages" / "backend"))

from maturity_adapters import (
    convert_raw_to_maturity_data,
    get_maturity_adapter,
    ProfessionalMaturityData,
    ADAPTER_MAP
)

def demo_unipile_adapter():
    """Demonstra o adaptador Unipile."""
    print("🔌 Demonstração: Adaptador Unipile")
    print("=" * 50)
    
    # Dados simulados da API Unipile
    unipile_data = {
        "linkedin_experience_years": 8.5,
        "linkedin_connections": 650,
        "linkedin_recommendations_received": 12,
        "email_responsiveness_hours": 6.0
    }
    
    # Configurar provider
    os.environ["MATURITY_PROVIDER"] = "unipile"
    
    # Converter usando o adaptador
    maturity_data = convert_raw_to_maturity_data(unipile_data)
    
    print(f"📊 Dados convertidos:")
    print(f"   • Experiência: {maturity_data.experience_years} anos")
    print(f"   • Rede: {maturity_data.network_strength} conexões")
    print(f"   • Reputação: {maturity_data.reputation_signals} sinais")
    print(f"   • Responsividade: {maturity_data.responsiveness_hours}h")
    print()

def demo_linkedin_adapter():
    """Demonstra o adaptador LinkedIn API."""
    print("🔗 Demonstração: Adaptador LinkedIn API")
    print("=" * 50)
    
    # Dados simulados da API LinkedIn
    linkedin_data = {
        "profile": {
            "experience_total_years": 12.0,
            "connections_count": 1200,
            "recommendations_received": 18
        },
        "activity": {
            "avg_response_time_hours": 4.5
        }
    }
    
    # Configurar provider
    os.environ["MATURITY_PROVIDER"] = "linkedin_api"
    
    # Converter usando o adaptador
    maturity_data = convert_raw_to_maturity_data(linkedin_data)
    
    print(f"📊 Dados convertidos:")
    print(f"   • Experiência: {maturity_data.experience_years} anos")
    print(f"   • Rede: {maturity_data.network_strength} conexões")
    print(f"   • Reputação: {maturity_data.reputation_signals} sinais")
    print(f"   • Responsividade: {maturity_data.responsiveness_hours}h")
    print()

def demo_custom_adapter():
    """Demonstra o adaptador personalizado."""
    print("⚙️ Demonstração: Adaptador Personalizado")
    print("=" * 50)
    
    # Dados de uma API personalizada
    custom_data = {
        "professional_data": {
            "xp_total_anos": 15.0,
            "conexoes_total": 800,
            "recomendacoes": 25
        },
        "communication_kpis": {
            "tempo_medio_resposta_h": 2.0
        }
    }
    
    # Configurar provider
    os.environ["MATURITY_PROVIDER"] = "custom_api"
    
    # Converter usando o adaptador
    maturity_data = convert_raw_to_maturity_data(custom_data)
    
    print(f"📊 Dados convertidos:")
    print(f"   • Experiência: {maturity_data.experience_years} anos")
    print(f"   • Rede: {maturity_data.network_strength} conexões")
    print(f"   • Reputação: {maturity_data.reputation_signals} sinais")
    print(f"   • Responsividade: {maturity_data.responsiveness_hours}h")
    print()

def demo_mock_adapter():
    """Demonstra o adaptador mock para testes."""
    print("🧪 Demonstração: Adaptador Mock (Testes)")
    print("=" * 50)
    
    # Configurar provider
    os.environ["MATURITY_PROVIDER"] = "mock"
    
    # Converter usando o adaptador (dados mock fixos)
    maturity_data = convert_raw_to_maturity_data({})
    
    print(f"📊 Dados convertidos (mock):")
    print(f"   • Experiência: {maturity_data.experience_years} anos")
    print(f"   • Rede: {maturity_data.network_strength} conexões")
    print(f"   • Reputação: {maturity_data.reputation_signals} sinais")
    print(f"   • Responsividade: {maturity_data.responsiveness_hours}h")
    print()

def demo_adapter_factory():
    """Demonstra o padrão Factory para seleção de adaptadores."""
    print("🏭 Demonstração: Factory Pattern")
    print("=" * 50)
    
    print("📋 Adaptadores disponíveis:")
    for provider_name, adapter_func in ADAPTER_MAP.items():
        print(f"   • {provider_name}: {adapter_func.__name__}")
    
    print()
    print("🔄 Testando troca dinâmica de adaptadores:")
    
    # Dados de teste
    test_data = {"test": "data"}
    
    for provider in ["unipile", "linkedin_api", "custom_api", "mock"]:
        os.environ["MATURITY_PROVIDER"] = provider
        adapter = get_maturity_adapter()
        result = adapter(test_data)
        print(f"   • {provider}: {result.experience_years} anos de experiência")
    
    print()

def demo_integration_with_algorithm():
    """Demonstra integração com o algoritmo de matching."""
    print("🎯 Demonstração: Integração com Algoritmo")
    print("=" * 50)
    
    # Simular dados de um advogado
    from algoritmo_match import Lawyer, KPI, ProfessionalMaturityData
    
    # Dados brutos da API
    raw_data = {
        "linkedin_experience_years": 7.0,
        "linkedin_connections": 450,
        "linkedin_recommendations_received": 8,
        "email_responsiveness_hours": 12.0
    }
    
    # Configurar adaptador
    os.environ["MATURITY_PROVIDER"] = "unipile"
    
    # Converter para estrutura padronizada
    maturity_data = convert_raw_to_maturity_data(raw_data)
    
    # Criar objeto Lawyer com dados de maturidade
    lawyer = Lawyer(
        id="ADV001",
        nome="Dr. João Silva",
        tags_expertise=["civil", "comercial"],
        geo_latlon=(-23.5505, -46.6333),
        curriculo_json={"anos_experiencia": 7},
        kpi=KPI(
            success_rate=0.85,
            cases_30d=15,
            avaliacao_media=4.5,
            tempo_resposta_h=8
        ),
        maturity_data=maturity_data  # ✅ Dados padronizados
    )
    
    print(f"👨‍⚖️ Advogado: {lawyer.nome}")
    print(f"📊 Maturidade Profissional:")
    print(f"   • Experiência: {lawyer.maturity_data.experience_years} anos")
    print(f"   • Rede: {lawyer.maturity_data.network_strength} conexões")
    print(f"   • Reputação: {lawyer.maturity_data.reputation_signals} sinais")
    print(f"   • Responsividade: {lawyer.maturity_data.responsiveness_hours}h")
    
    # Simular cálculo de Feature-M
    print(f"\n🔢 Feature-M calculada seria baseada nestes dados padronizados")
    print(f"   (independente da API de origem)")
    print()

def main():
    """Executa todas as demonstrações."""
    print("🎯 DEMONSTRAÇÃO: Adaptadores de Maturidade Profissional")
    print("=" * 60)
    print("Este demo mostra como o padrão Adapter permite trocar")
    print("entre diferentes APIs sem modificar o algoritmo principal.\n")
    
    # Executar demonstrações
    demo_unipile_adapter()
    demo_linkedin_adapter()
    demo_custom_adapter()
    demo_mock_adapter()
    demo_adapter_factory()
    demo_integration_with_algorithm()
    
    print("✅ Todas as demonstrações concluídas!")
    print("\n📝 Para usar em produção:")
    print("   1. Configure MATURITY_PROVIDER no .env")
    print("   2. Use convert_raw_to_maturity_data() para converter dados")
    print("   3. Atribua ao campo maturity_data do Lawyer")
    print("   4. Feature-M será calculada automaticamente")

if __name__ == "__main__":
    main() 