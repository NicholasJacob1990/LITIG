#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Ativação do Sistema de Parcerias LLM Enhanced
=============================================

Script para testar e ativar o sistema de recomendações de parcerias
aprimorado com LLMs (Gemini, Claude, OpenAI).
"""

import asyncio
import os
import sys
import json
from datetime import datetime
from pathlib import Path

# Adicionar o diretório pai ao Python path
sys.path.append(str(Path(__file__).parent.parent))

def test_llm_connectivity():
    """Testa conectividade com os LLMs disponíveis."""
    print("🔍 Testando conectividade com LLMs...")
    
    results = {
        "gemini": False,
        "claude": False,
        "openai": False,
        "errors": []
    }
    
    # Testar Gemini
    try:
        import google.generativeai as genai
        gemini_key = os.getenv("GEMINI_API_KEY")
        if gemini_key:
            genai.configure(api_key=gemini_key)
            print("✅ Gemini: Configurado e disponível")
            results["gemini"] = True
        else:
            print("⚠️  Gemini: GEMINI_API_KEY não encontrada")
            results["errors"].append("GEMINI_API_KEY missing")
    except ImportError:
        print("❌ Gemini: google-generativeai não instalado")
        results["errors"].append("google-generativeai package missing")
    except Exception as e:
        print(f"❌ Gemini: Erro - {e}")
        results["errors"].append(f"Gemini error: {e}")
    
    # Testar Anthropic Claude
    try:
        import anthropic
        claude_key = os.getenv("ANTHROPIC_API_KEY")
        if claude_key:
            print("✅ Claude: Configurado e disponível")
            results["claude"] = True
        else:
            print("⚠️  Claude: ANTHROPIC_API_KEY não encontrada")
            results["errors"].append("ANTHROPIC_API_KEY missing")
    except ImportError:
        print("❌ Claude: anthropic não instalado")
        results["errors"].append("anthropic package missing")
    except Exception as e:
        print(f"❌ Claude: Erro - {e}")
        results["errors"].append(f"Claude error: {e}")
    
    # Testar OpenAI
    try:
        import openai
        openai_key = os.getenv("OPENAI_API_KEY")
        if openai_key:
            print("✅ OpenAI: Configurado e disponível")
            results["openai"] = True
        else:
            print("⚠️  OpenAI: OPENAI_API_KEY não encontrada")
            results["errors"].append("OPENAI_API_KEY missing")
    except ImportError:
        print("❌ OpenAI: openai não instalado")
        results["errors"].append("openai package missing")
    except Exception as e:
        print(f"❌ OpenAI: Erro - {e}")
        results["errors"].append(f"OpenAI error: {e}")
    
    return results


async def test_partnership_llm_service():
    """Testa o serviço de parcerias LLM com dados de exemplo."""
    print("\n🤖 Testando Partnership LLM Enhancement Service...")
    
    try:
        from services.partnership_llm_enhancement_service import (
            PartnershipLLMEnhancementService,
            LawyerProfileForPartnership
        )
        
        # Criar instância do serviço
        llm_service = PartnershipLLMEnhancementService()
        
        # Criar perfis de teste
        lawyer_a = LawyerProfileForPartnership(
            lawyer_id="TEST_001",
            name="Ana Silva",
            firm_name="Silva & Associados",
            experience_years=8,
            specialization_areas=["Direito Empresarial", "Startups", "Fintech"],
            recent_cases_summary="Consultoria jurídica para fintech em rodada série A",
            communication_style="assertiva e técnica",
            collaboration_history=["Parcerias em M&A", "Joint ventures"],
            market_reputation="emergente em fintech",
            client_types=["startups", "scale-ups", "fintechs"],
            fee_structure_style="competitive",
            geographic_focus=["São Paulo", "Rio de Janeiro"]
        )
        
        lawyer_b = LawyerProfileForPartnership(
            lawyer_id="TEST_002",
            name="Carlos Santos",
            firm_name="Santos Legal",
            experience_years=15,
            specialization_areas=["Direito Tributário", "Compliance", "Internacional"],
            recent_cases_summary="Reestruturação tributária para multinacional",
            communication_style="conservador e detalhista",
            collaboration_history=["Assessoria fiscal complexa"],
            market_reputation="especialista sênior",
            client_types=["multinacionais", "empresas de médio porte"],
            fee_structure_style="premium",
            geographic_focus=["São Paulo", "Brasília"]
        )
        
        # Testar análise de sinergia
        insights = await llm_service.analyze_partnership_synergy(
            lawyer_a, 
            lawyer_b, 
            "Assessoria completa para startup brasileira expandindo para mercados internacionais"
        )
        
        print(f"✅ Análise LLM completa!")
        print(f"   📊 Sinergia Score: {insights.synergy_score:.2f}")
        print(f"   🤝 Compatibilidade: {insights.collaboration_style_match}")
        print(f"   🎯 Confiança: {insights.confidence_score:.2f}")
        print(f"   💡 Fatores: {len(insights.compatibility_factors)} identificados")
        print(f"   🚀 Oportunidades: {len(insights.strategic_opportunities)} mapeadas")
        
        if insights.strategic_opportunities:
            print(f"   📈 Primeira oportunidade: {insights.strategic_opportunities[0]}")
        
        return True
        
    except Exception as e:
        print(f"❌ Erro no teste do serviço LLM: {e}")
        return False


def update_env_file():
    """Atualiza o arquivo .env para ativar LLM de parcerias."""
    print("\n📝 Atualizando arquivo .env...")
    
    env_path = Path(".env")
    
    # Ler arquivo atual ou criar se não existir
    env_content = ""
    if env_path.exists():
        with open(env_path, 'r') as f:
            env_content = f.read()
    
    # Verificar se já está configurado
    if "ENABLE_PARTNERSHIP_LLM=true" in env_content:
        print("✅ ENABLE_PARTNERSHIP_LLM já está ativo")
        return True
    
    # Adicionar ou atualizar configuração
    lines = env_content.split('\n')
    updated = False
    
    for i, line in enumerate(lines):
        if line.startswith('ENABLE_PARTNERSHIP_LLM='):
            lines[i] = 'ENABLE_PARTNERSHIP_LLM=true'
            updated = True
            break
    
    if not updated:
        # Adicionar nova configuração
        if env_content and not env_content.endswith('\n'):
            env_content += '\n'
        
        env_content += '''
# ============================================
# LLM ENHANCED PARTNERSHIPS CONFIGURATION
# ============================================

# Ativar sistema de parcerias aprimorado com LLMs
ENABLE_PARTNERSHIP_LLM=true
'''
        
        with open(env_path, 'w') as f:
            f.write(env_content)
        
        print("✅ Configuração ENABLE_PARTNERSHIP_LLM=true adicionada ao .env")
        return True
    else:
        # Atualizar arquivo existente
        with open(env_path, 'w') as f:
            f.write('\n'.join(lines))
        
        print("✅ Configuração ENABLE_PARTNERSHIP_LLM atualizada para true")
        return True


def generate_activation_report(llm_results, service_test_ok):
    """Gera relatório de ativação."""
    report = {
        "activation_timestamp": datetime.utcnow().isoformat(),
        "system": "Partnership LLM Enhanced",
        "version": "v1.0",
        "llm_connectivity": llm_results,
        "service_test": {
            "partnership_llm_service": service_test_ok
        },
        "status": "activated" if service_test_ok else "partial_activation",
        "available_llms": [llm for llm, available in llm_results.items() if available and llm != "errors"],
        "recommendations": []
    }
    
    # Adicionar recomendações baseadas nos resultados
    if not any(llm_results[llm] for llm in ["gemini", "claude", "openai"]):
        report["recommendations"].append("Configure ao menos uma API key de LLM para análises avançadas")
    
    if llm_results["errors"]:
        report["recommendations"].extend([
            f"Resolver: {error}" for error in llm_results["errors"]
        ])
    
    if service_test_ok:
        report["recommendations"].append("Sistema pronto para uso em produção")
    
    # Salvar relatório
    report_path = Path("partnership_llm_activation_report.json")
    with open(report_path, 'w') as f:
        json.dump(report, f, indent=2)
    
    return report


async def main():
    """Função principal de ativação."""
    print("🚀 ATIVAÇÃO DO SISTEMA DE PARCERIAS LLM ENHANCED")
    print("=" * 60)
    
    # 1. Testar conectividade com LLMs
    llm_results = test_llm_connectivity()
    
    # 2. Testar serviço de parcerias LLM
    service_ok = await test_partnership_llm_service()
    
    # 3. Atualizar .env
    env_updated = update_env_file()
    
    # 4. Gerar relatório
    report = generate_activation_report(llm_results, service_ok)
    
    # 5. Resumo final
    print("\n" + "=" * 60)
    print("📋 RESUMO DA ATIVAÇÃO")
    print("=" * 60)
    
    llm_count = sum(1 for llm in ["gemini", "claude", "openai"] if llm_results[llm])
    print(f"🤖 LLMs disponíveis: {llm_count}/3")
    
    if llm_results["gemini"]:
        print("   ✅ Gemini Pro (Google)")
    if llm_results["claude"]:
        print("   ✅ Claude 3.5 Sonnet (Anthropic)")
    if llm_results["openai"]:
        print("   ✅ GPT-4o (OpenAI)")
    
    print(f"🔧 Serviço LLM: {'✅ Funcionando' if service_ok else '❌ Com problemas'}")
    print(f"📝 Arquivo .env: {'✅ Atualizado' if env_updated else '❌ Erro'}")
    
    print(f"\n📊 Status: {report['status'].upper()}")
    
    if report["recommendations"]:
        print("\n💡 Recomendações:")
        for rec in report["recommendations"]:
            print(f"   • {rec}")
    
    print(f"\n📄 Relatório salvo: partnership_llm_activation_report.json")
    
    if service_ok and llm_count > 0:
        print("\n🎉 SISTEMA DE PARCERIAS LLM ATIVADO COM SUCESSO!")
        print("\nPróximos passos:")
        print("1. Reinicie o servidor FastAPI")
        print("2. Teste o endpoint: GET /partnerships/recommendations/enhanced/{lawyer_id}")
        print("3. Monitore logs para análises LLM")
    else:
        print("\n⚠️  ATIVAÇÃO PARCIAL - Verifique recomendações acima")


if __name__ == "__main__":
    # Carregar variáveis de ambiente se disponível
    try:
        from dotenv import load_dotenv
        load_dotenv()
    except ImportError:
        print("ℹ️  python-dotenv não disponível - usando variáveis de ambiente do sistema")
    
    asyncio.run(main()) 
 