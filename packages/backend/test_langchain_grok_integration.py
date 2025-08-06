#!/usr/bin/env python3
"""
Teste da Integração LangChain-Grok no V2
========================================

Script para testar a integração do LangChain-Grok nos agentes do V2.
"""

import asyncio
import sys
import os

# Adicionar o diretório atual ao path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from services.intelligent_triage_orchestrator_v2 import get_intelligent_triage_orchestrator_v2


async def test_langchain_grok_integration():
    """Teste da integração LangChain-Grok."""
    print("🧪 TESTE DA INTEGRAÇÃO LANGCHAIN-GROK NO V2")
    print("=" * 60)
    
    try:
        # Inicializar orquestrador
        orchestrator = get_intelligent_triage_orchestrator_v2()
        
        # Verificar status dos serviços
        status = orchestrator.get_service_status()
        print(f"\n📊 STATUS DOS SERVIÇOS:")
        for service, available in status.items():
            status_icon = "✅" if available else "❌"
            print(f"   {service}: {status_icon}")
        
        # Verificar especificamente LangChain-Grok
        langchain_grok_available = status.get("langchain_grok_available", False)
        langchain_grok_service = status.get("langchain_grok_service", False)
        
        print(f"\n🤖 LANGCHAIN-GROK:")
        print(f"   SDK disponível: {'✅' if langchain_grok_available else '❌'}")
        print(f"   Serviço inicializado: {'✅' if langchain_grok_service else '❌'}")
        
        if langchain_grok_available and langchain_grok_service:
            print(f"   🚀 LangChain-Grok está funcionando!")
        elif langchain_grok_available and not langchain_grok_service:
            print(f"   ⚠️ SDK disponível mas serviço não inicializado")
        else:
            print(f"   ❌ LangChain-Grok não disponível")
        
        # Testar workflow
        print(f"\n🚀 EXECUTANDO WORKFLOW COM LANGCHAIN-GROK...")
        result = await orchestrator.start_intelligent_triage("test_langchain_grok_001")
        
        # Resultados
        print(f"\n📊 RESULTADOS DO TESTE:")
        print(f"   ✅ Sucesso: {'SIM' if result.success else 'NÃO'}")
        print(f"   🆔 Case ID: {result.case_id}")
        print(f"   ⚖️ Área: {result.triage_result.get('area', 'N/A')}")
        print(f"   🔍 Subárea: {result.triage_result.get('subarea', 'N/A')}")
        print(f"   👥 Matches: {len(result.matches)} encontrados")
        print(f"   🤖 LEX-9000: {'USADO' if result.lex_analysis else 'NÃO USADO'}")
        print(f"   ✨ LLM Enhancement: {'USADO' if result.processing_summary.get('llm_enhancement_used') else 'NÃO USADO'}")
        print(f"   ⏱️ Duração: {result.processing_summary.get('total_duration', 0):.2f}s")
        
        # Detalhes do LEX-9000 (se usado)
        if result.lex_analysis:
            print(f"\n🤖 ANÁLISE LEX-9000:")
            lex = result.lex_analysis
            print(f"   Tipo: {lex.get('analysis_type', 'N/A')}")
            print(f"   Modelo usado: {lex.get('model_used', 'N/A')}")
            print(f"   SDK usado: {lex.get('sdk_used', 'N/A')}")
            print(f"   Confiança: {lex.get('confidence', 0):.2f}")
            
            # Verificar se usou LangChain-Grok
            if "langchain" in lex.get('sdk_used', '').lower():
                print(f"   🎉 LANGCHAIN-GROK FOI USADO!")
            elif "openrouter" in lex.get('sdk_used', '').lower():
                print(f"   🔄 OpenRouter foi usado (fallback)")
            else:
                print(f"   ⚠️ Simulação foi usada")
        
        # Detalhes do processamento
        print(f"\n🔧 DETALHES DO PROCESSAMENTO:")
        steps = result.processing_summary.get('steps_completed', [])
        print(f"   Etapas executadas: {len(steps)}")
        for i, step in enumerate(steps, 1):
            print(f"   {i}. {step}")
        
        # Avaliação final
        print(f"\n🎯 AVALIAÇÃO FINAL:")
        if result.success:
            print(f"   ✅ TESTE PASSOU - Integração funcionando")
            
            # Verificar se LangChain-Grok foi usado
            if result.lex_analysis and "langchain" in result.lex_analysis.get('sdk_used', '').lower():
                print(f"   🚀 LANGCHAIN-GROK ATIVO - Agentes usando Grok via LangChain!")
            elif langchain_grok_available:
                print(f"   ⚠️ LangChain-Grok disponível mas não foi usado")
            else:
                print(f"   ❌ LangChain-Grok não disponível")
        else:
            print(f"   ❌ TESTE FALHOU - Verificar erros acima")
        
        return result
        
    except Exception as e:
        print(f"\n💥 ERRO CRÍTICO NO TESTE: {e}")
        import traceback
        traceback.print_exc()
        return None


if __name__ == "__main__":
    print("🧪 INICIANDO TESTE DA INTEGRAÇÃO LANGCHAIN-GROK")
    print("=" * 60)
    
    # Executar teste
    result = asyncio.run(test_langchain_grok_integration())
    
    if result and result.success:
        print(f"\n🎉 TESTE CONCLUÍDO COM SUCESSO!")
        sys.exit(0)
    else:
        print(f"\n❌ TESTE FALHOU!")
        sys.exit(1) 