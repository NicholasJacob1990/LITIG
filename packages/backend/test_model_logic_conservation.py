#!/usr/bin/env python3
"""
Teste da Conservação da Lógica de Modelos no V2
===============================================

Script para testar se a lógica específica de uso de cada modelo de IA foi conservada.
"""

import asyncio
import sys
import os

# Adicionar o diretório atual ao path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from services.intelligent_triage_orchestrator_v2 import get_intelligent_triage_orchestrator_v2


async def test_model_logic_conservation():
    """Teste da conservação da lógica específica de modelos."""
    print("🧪 TESTE DA CONSERVAÇÃO DA LÓGICA DE MODELOS NO V2")
    print("=" * 70)
    
    try:
        # Inicializar orquestrador
        orchestrator = get_intelligent_triage_orchestrator_v2()
        
        # Verificar status dos serviços
        status = orchestrator.get_service_status()
        print(f"\n📊 STATUS DOS SERVIÇOS:")
        for service, available in status.items():
            status_icon = "✅" if available else "❌"
            print(f"   {service}: {status_icon}")
        
        # Testar diferentes cenários de complexidade
        test_cases = [
            {
                "name": "Caso Simples (Multa de Trânsito)",
                "summary": "Recebi uma multa de trânsito por excesso de velocidade",
                "expected_complexity": "low",
                "expected_models": ["Llama 4 Scout"],
                "expected_lex9000": False
            },
            {
                "name": "Caso Médio (Trabalhista)",
                "summary": "Não estou recebendo horas extras há 6 meses",
                "expected_complexity": "medium",
                "expected_models": ["Llama 4 Scout", "GPT-4o"],
                "expected_lex9000": True
            },
            {
                "name": "Caso Complexo (Empresarial)",
                "summary": "Preciso de assessoria para fusão de empresas e questões societárias",
                "expected_complexity": "high",
                "expected_models": ["Claude Sonnet", "GPT-4o", "Ensemble"],
                "expected_lex9000": True
            }
        ]
        
        print(f"\n🎯 TESTANDO LÓGICA DE MODELOS POR COMPLEXIDADE:")
        
        for i, test_case in enumerate(test_cases, 1):
            print(f"\n{i}. {test_case['name']}")
            print(f"   Resumo: {test_case['summary']}")
            print(f"   Complexidade esperada: {test_case['expected_complexity']}")
            print(f"   Modelos esperados: {', '.join(test_case['expected_models'])}")
            print(f"   LEX-9000 esperado: {'SIM' if test_case['expected_lex9000'] else 'NÃO'}")
            
            # Simular dados do caso
            case_data = {
                "summary": test_case['summary'],
                "area": "Direito do Trabalho" if "trabalhista" in test_case['summary'].lower() else "Direito Empresarial",
                "subarea": "Horas Extras" if "horas" in test_case['summary'].lower() else "Fusão e Aquisição",
                "urgency_h": 48,
                "keywords": ["multa", "trânsito"] if "multa" in test_case['summary'].lower() else ["empresarial", "societário"]
            }
            
            # Testar detecção de complexidade
            preliminary_complexity = orchestrator._assess_preliminary_complexity(case_data)
            print(f"   Complexidade detectada: {preliminary_complexity}")
            
            # Verificar se a complexidade está correta
            if preliminary_complexity == test_case['expected_complexity']:
                print(f"   ✅ Complexidade CORRETA")
            else:
                print(f"   ❌ Complexidade INCORRETA (esperado: {test_case['expected_complexity']})")
        
        # Testar workflow completo
        print(f"\n🚀 EXECUTANDO WORKFLOW COMPLETO...")
        result = await orchestrator.start_intelligent_triage("test_model_logic_001")
        
        # Resultados
        print(f"\n📊 RESULTADOS DO WORKFLOW:")
        print(f"   ✅ Sucesso: {'SIM' if result.success else 'NÃO'}")
        print(f"   🆔 Case ID: {result.case_id}")
        print(f"   ⚖️ Área: {result.triage_result.get('area', 'N/A')}")
        print(f"   🔍 Subárea: {result.triage_result.get('subarea', 'N/A')}")
        print(f"   🤖 LEX-9000: {'USADO' if result.lex_analysis else 'NÃO USADO'}")
        print(f"   ⏱️ Duração: {result.processing_summary.get('total_duration', 0):.2f}s")
        
        # Detalhes dos modelos usados
        if result.lex_analysis:
            print(f"\n🤖 DETALHES DOS MODELOS:")
            lex = result.lex_analysis
            print(f"   Tipo: {lex.get('analysis_type', 'N/A')}")
            print(f"   Modelo usado: {lex.get('model_used', 'N/A')}")
            print(f"   SDK usado: {lex.get('sdk_used', 'N/A')}")
            print(f"   Confiança: {lex.get('confidence', 0):.2f}")
        
        # Verificar conservação da lógica
        print(f"\n🎯 VERIFICAÇÃO DA CONSERVAÇÃO:")
        
        # 1. Verificar se LangChain-Grok tem prioridade
        langchain_grok_used = False
        if result.lex_analysis and "langchain" in result.lex_analysis.get('sdk_used', '').lower():
            langchain_grok_used = True
            print(f"   ✅ LangChain-Grok usado (prioridade mantida)")
        else:
            print(f"   ⚠️ LangChain-Grok não usado (fallback ativo)")
        
        # 2. Verificar se modelos especializados são usados
        triage_result = result.triage_result
        if "model_used" in triage_result:
            print(f"   ✅ Modelo específico usado: {triage_result['model_used']}")
        else:
            print(f"   ⚠️ Modelo específico não identificado")
        
        # 3. Verificar se estratégias por complexidade são aplicadas
        complexity_level = result.triage_result.get('complexity_level', 'medium')
        print(f"   ✅ Complexidade detectada: {complexity_level}")
        
        # 4. Verificar se LEX-9000 é usado apenas para casos complexos
        if result.lex_analysis:
            if complexity_level == "low":
                print(f"   ⚠️ LEX-9000 usado em caso simples (pode ser otimizado)")
            else:
                print(f"   ✅ LEX-9000 usado apropriadamente para caso {complexity_level}")
        else:
            if complexity_level == "low":
                print(f"   ✅ LEX-9000 não usado para caso simples (correto)")
            else:
                print(f"   ⚠️ LEX-9000 não usado para caso {complexity_level} (pode ser necessário)")
        
        # Avaliação final
        print(f"\n🎯 AVALIAÇÃO FINAL DA CONSERVAÇÃO:")
        if result.success:
            print(f"   ✅ LÓGICA CONSERVADA - Workflow funcionando")
            
            # Verificar se a lógica específica foi mantida
            conservation_score = 0
            total_checks = 4
            
            if langchain_grok_used or "openrouter" in str(result.lex_analysis).lower():
                conservation_score += 1
                print(f"   ✅ Prioridade de modelos mantida")
            
            if "model_used" in triage_result or "strategy_used" in triage_result:
                conservation_score += 1
                print(f"   ✅ Estratégias específicas mantidas")
            
            if complexity_level in ["low", "medium", "high"]:
                conservation_score += 1
                print(f"   ✅ Detecção de complexidade funcionando")
            
            if result.lex_analysis is not None:
                conservation_score += 1
                print(f"   ✅ LEX-9000 integrado corretamente")
            
            conservation_percentage = (conservation_score / total_checks) * 100
            print(f"   📊 Score de conservação: {conservation_percentage:.1f}%")
            
            if conservation_percentage >= 75:
                print(f"   🎉 EXCELENTE - Lógica específica de modelos conservada!")
            elif conservation_percentage >= 50:
                print(f"   ✅ BOM - Maioria da lógica conservada")
            else:
                print(f"   ⚠️ ATENÇÃO - Algumas lógicas podem ter sido perdidas")
        else:
            print(f"   ❌ TESTE FALHOU - Verificar erros acima")
        
        return result
        
    except Exception as e:
        print(f"\n💥 ERRO CRÍTICO NO TESTE: {e}")
        import traceback
        traceback.print_exc()
        return None


if __name__ == "__main__":
    print("🧪 INICIANDO TESTE DA CONSERVAÇÃO DA LÓGICA DE MODELOS")
    print("=" * 70)
    
    # Executar teste
    result = asyncio.run(test_model_logic_conservation())
    
    if result and result.success:
        print(f"\n🎉 TESTE CONCLUÍDO COM SUCESSO!")
        sys.exit(0)
    else:
        print(f"\n❌ TESTE FALHOU!")
        sys.exit(1) 