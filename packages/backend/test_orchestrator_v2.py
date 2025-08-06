#!/usr/bin/env python3
"""
Teste do Intelligent Triage Orchestrator V2
==========================================

Script para testar a implementação V2 com integração real dos serviços.
"""

import asyncio
import sys
import os

# Adicionar o diretório atual ao path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from services.intelligent_triage_orchestrator_v2 import get_intelligent_triage_orchestrator_v2


async def test_orchestrator_v2():
    """Teste completo do orquestrador V2."""
    print("🧪 TESTE DO ORQUESTRADOR V2 - INTEGRAÇÃO REAL")
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
        
        # Contar serviços disponíveis
        available_services = sum(1 for available in status.values() if available)
        total_services = len(status)
        print(f"\n📈 COBERTURA: {available_services}/{total_services} serviços disponíveis")
        
        # Testar workflow
        print(f"\n🚀 EXECUTANDO WORKFLOW...")
        result = await orchestrator.start_intelligent_triage("test_user_v2_001")
        
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
        
        # Detalhes do processamento
        print(f"\n🔧 DETALHES DO PROCESSAMENTO:")
        steps = result.processing_summary.get('steps_completed', [])
        print(f"   Etapas executadas: {len(steps)}")
        for i, step in enumerate(steps, 1):
            print(f"   {i}. {step}")
        
        # Análise LEX-9000 (se usado)
        if result.lex_analysis:
            print(f"\n🤖 ANÁLISE LEX-9000:")
            lex = result.lex_analysis
            print(f"   Área Principal: {lex.get('classificacao', {}).get('area_principal', 'N/A')}")
            print(f"   Viabilidade: {lex.get('viabilidade', {}).get('classificacao', 'N/A')}")
            print(f"   Confiança: {lex.get('confidence', 0):.2f}")
        
        # Matches encontrados
        if result.matches:
            print(f"\n👥 MATCHES ENCONTRADOS:")
            for i, match in enumerate(result.matches[:3], 1):  # Top 3
                print(f"   {i}. {match.get('name', 'N/A')}")
                print(f"      Especialização: {match.get('specialization', 'N/A')}")
                print(f"      Experiência: {match.get('experience_years', 0)} anos")
                print(f"      Taxa de sucesso: {match.get('success_rate', 0):.1%}")
        
        # Explicações
        if result.explanations:
            print(f"\n📝 EXPLICAÇÕES GERADAS:")
            for i, explanation in enumerate(result.explanations, 1):
                print(f"   {i}. {explanation[:150]}...")
        
        # Erros (se houver)
        if result.error:
            print(f"\n❌ ERRO ENCONTRADO:")
            print(f"   {result.error}")
        
        # Visualização do workflow
        if result.workflow_visualization:
            print(f"\n🎯 VISUALIZAÇÃO DO WORKFLOW:")
            print(result.workflow_visualization)
        
        # Avaliação final
        print(f"\n🎯 AVALIAÇÃO FINAL:")
        if result.success:
            print(f"   ✅ TESTE PASSOU - Orquestrador V2 funcionando corretamente")
            if available_services >= 3:  # Pelo menos 3 serviços essenciais
                print(f"   🚀 PRONTO PARA PRODUÇÃO - {available_services} serviços integrados")
            else:
                print(f"   ⚠️ EM DESENVOLVIMENTO - Apenas {available_services} serviços disponíveis")
        else:
            print(f"   ❌ TESTE FALHOU - Verificar erros acima")
        
        return result
        
    except Exception as e:
        print(f"\n💥 ERRO CRÍTICO NO TESTE: {e}")
        import traceback
        traceback.print_exc()
        return None


if __name__ == "__main__":
    print("🧪 INICIANDO TESTE DO ORQUESTRADOR V2")
    print("=" * 60)
    
    # Executar teste
    result = asyncio.run(test_orchestrator_v2())
    
    if result and result.success:
        print(f"\n🎉 TESTE CONCLUÍDO COM SUCESSO!")
        sys.exit(0)
    else:
        print(f"\n❌ TESTE FALHOU!")
        sys.exit(1) 