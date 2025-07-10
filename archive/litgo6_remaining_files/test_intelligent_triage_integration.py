#!/usr/bin/env python3
"""
Script de Teste da Integração Completa da Triagem Inteligente
==============================================================

Este script demonstra:
1. Início de conversa inteligente
2. Detecção automática de complexidade
3. Integração com LEX-9000 para casos complexos
4. Resultado final com análise completa
"""

import asyncio
import json
from datetime import datetime
from backend.services.intelligent_triage_orchestrator import intelligent_triage_orchestrator

async def test_simple_case():
    """Testa um caso simples."""
    print("\n" + "="*60)
    print("TESTE 1: CASO SIMPLES")
    print("="*60)
    
    # Iniciar triagem
    result = await intelligent_triage_orchestrator.start_intelligent_triage("user_123")
    case_id = result["case_id"]
    print(f"\n✅ Triagem iniciada: {case_id}")
    print(f"🤖 IA: {result['message']}")
    
    # Simular conversa simples
    messages = [
        "Quero consultar sobre pensão alimentícia",
        "Meu ex-marido não está pagando há 3 meses",
        "O valor é R$ 1.500 por mês",
        "Tenho a sentença judicial e os comprovantes"
    ]
    
    for msg in messages:
        print(f"\n👤 Usuário: {msg}")
        response = await intelligent_triage_orchestrator.continue_intelligent_triage(case_id, msg)
        print(f"🤖 IA: {response['message']}")
        
        if response["status"] == "completed":
            print("\n✅ Conversa finalizada!")
            break
    
    # Obter resultado
    final_result = await intelligent_triage_orchestrator.get_orchestration_result(case_id)
    if final_result:
        print(f"\n📊 RESULTADO FINAL:")
        print(f"- Estratégia: {final_result.strategy_used}")
        print(f"- Complexidade: {final_result.complexity_level}")
        print(f"- Confiança: {final_result.confidence_score:.2f}")
        print(f"- Tipo de fluxo: {final_result.flow_type}")
        print(f"- LEX-9000 usado: {final_result.analysis_details.get('lex9000_enhanced', False)}")
        
        # Mostrar dados extraídos
        if "aspectos_legais" in final_result.triage_data:
            print(f"\n📋 Aspectos Legais (LEX-9000):")
            print(json.dumps(final_result.triage_data["aspectos_legais"], indent=2, ensure_ascii=False))
    
    # Limpar
    intelligent_triage_orchestrator.cleanup_orchestration(case_id)

async def test_complex_case():
    """Testa um caso complexo que ativa o LEX-9000."""
    print("\n" + "="*60)
    print("TESTE 2: CASO COMPLEXO")
    print("="*60)
    
    # Iniciar triagem
    result = await intelligent_triage_orchestrator.start_intelligent_triage("user_456")
    case_id = result["case_id"]
    print(f"\n✅ Triagem iniciada: {case_id}")
    print(f"🤖 IA: {result['message']}")
    
    # Simular conversa complexa
    messages = [
        "Preciso de ajuda com um caso trabalhista complexo",
        "Fui demitido após denunciar assédio moral e desvio de verbas na empresa",
        "Trabalho há 8 anos, era gerente de TI, salário de R$ 15.000",
        "Tenho gravações, e-mails e testemunhas. A empresa é multinacional",
        "Também descobri que não recolhiam FGTS corretamente",
        "Sofri retaliações após a denúncia e fui demitido por justa causa falsa"
    ]
    
    for msg in messages:
        print(f"\n👤 Usuário: {msg}")
        response = await intelligent_triage_orchestrator.continue_intelligent_triage(case_id, msg)
        print(f"🤖 IA: {response['message']}")
        
        # Mostrar detecção de complexidade em tempo real
        if response.get("complexity_hint"):
            print(f"   [Complexidade detectada: {response['complexity_hint']}]")
        
        if response["status"] == "completed":
            print("\n✅ Conversa finalizada!")
            break
    
    # Obter resultado
    final_result = await intelligent_triage_orchestrator.get_orchestration_result(case_id)
    if final_result:
        print(f"\n📊 RESULTADO FINAL:")
        print(f"- Estratégia: {final_result.strategy_used}")
        print(f"- Complexidade: {final_result.complexity_level}")
        print(f"- Confiança: {final_result.confidence_score:.2f}")
        print(f"- Tipo de fluxo: {final_result.flow_type}")
        print(f"- Tempo de processamento: {final_result.processing_time_ms}ms")
        
        # Verificar análise LEX-9000
        if "lex9000_analysis" in final_result.triage_data:
            lex_data = final_result.triage_data["lex9000_analysis"]
            print(f"\n🔍 ANÁLISE LEX-9000 COMPLETA:")
            print(f"- Confiança LEX-9000: {lex_data['confidence_score']:.2f}")
            print(f"- Tempo LEX-9000: {lex_data['processing_time_ms']}ms")
            
            print(f"\n📑 Classificação Jurídica:")
            print(json.dumps(lex_data["classificacao"], indent=2, ensure_ascii=False))
            
            print(f"\n⚖️ Análise de Viabilidade:")
            print(json.dumps(lex_data["analise_viabilidade"], indent=2, ensure_ascii=False))
            
            print(f"\n🚨 Urgência:")
            print(json.dumps(lex_data["urgencia"], indent=2, ensure_ascii=False))
            
            print(f"\n📚 Aspectos Técnicos:")
            print(json.dumps(lex_data["aspectos_tecnicos"], indent=2, ensure_ascii=False))
            
            print(f"\n💡 Recomendações:")
            print(json.dumps(lex_data["recomendacoes"], indent=2, ensure_ascii=False))
    
    # Limpar
    intelligent_triage_orchestrator.cleanup_orchestration(case_id)

async def test_force_completion():
    """Testa finalização forçada."""
    print("\n" + "="*60)
    print("TESTE 3: FINALIZAÇÃO FORÇADA")
    print("="*60)
    
    # Iniciar triagem
    result = await intelligent_triage_orchestrator.start_intelligent_triage("user_789")
    case_id = result["case_id"]
    print(f"\n✅ Triagem iniciada: {case_id}")
    
    # Enviar apenas uma mensagem
    response = await intelligent_triage_orchestrator.continue_intelligent_triage(
        case_id, 
        "Tenho um problema mas não sei explicar direito..."
    )
    print(f"🤖 IA: {response['message']}")
    
    # Forçar finalização
    print("\n⏹️ Forçando finalização...")
    forced_result = await intelligent_triage_orchestrator.force_complete_conversation(
        case_id, 
        "timeout_usuario"
    )
    
    if forced_result:
        print(f"\n📊 RESULTADO FORÇADO:")
        print(f"- Estratégia: {forced_result.strategy_used}")
        print(f"- Complexidade: {forced_result.complexity_level}")
        print(f"- Motivo: {forced_result.triage_data.get('completion_reason')}")
    
    # Limpar
    intelligent_triage_orchestrator.cleanup_orchestration(case_id)

async def main():
    """Executa todos os testes."""
    print("\n🚀 INICIANDO TESTES DA TRIAGEM INTELIGENTE COM LEX-9000")
    print(f"📅 {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    try:
        # Teste 1: Caso Simples
        await test_simple_case()
        
        # Teste 2: Caso Complexo
        await test_complex_case()
        
        # Teste 3: Finalização Forçada
        await test_force_completion()
        
        print("\n✅ TODOS OS TESTES CONCLUÍDOS COM SUCESSO!")
        
    except Exception as e:
        print(f"\n❌ ERRO NOS TESTES: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(main()) 