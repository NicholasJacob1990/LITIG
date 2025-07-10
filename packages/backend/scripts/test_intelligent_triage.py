#!/usr/bin/env python3
"""
Script de Teste da Nova Arquitetura de Triagem Inteligente
===========================================================

Este script demonstra e testa a nova arquitetura conversacional
que evolui as estratégias existentes para um sistema inteligente.

Uso:
    python scripts/test_intelligent_triage.py
"""

import asyncio
import json
import time
from typing import Dict, List
import sys
import os

# Adicionar o diretório raiz ao path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from backend.services.intelligent_interviewer_service import intelligent_interviewer_service
from backend.services.intelligent_triage_orchestrator import intelligent_triage_orchestrator

class IntelligentTriageTestSuite:
    """Suite de testes para a nova arquitetura de triagem inteligente."""
    
    def __init__(self):
        self.test_cases = [
            {
                "name": "Caso Simples - Multa de Trânsito",
                "expected_strategy": "simple",
                "expected_complexity": "low",
                "conversation": [
                    "Recebi uma multa de trânsito por excesso de velocidade",
                    "Foi na Marginal Pinheiros, radar pegou 65 km/h em uma zona de 60 km/h",
                    "Não, não tenho outras multas recentes",
                    "Quero contestar porque acho que o radar estava mal calibrado"
                ]
            },
            {
                "name": "Caso Médio - Questão Trabalhista",
                "expected_strategy": "failover",
                "expected_complexity": "medium",
                "conversation": [
                    "Fui demitido da empresa onde trabalhava há 3 anos",
                    "Eles alegaram justa causa, mas eu discordo completamente",
                    "Disseram que eu faltei muito, mas eu tinha atestados médicos",
                    "Não recebi as verbas rescisórias que tenho direito",
                    "Quero processar a empresa por demissão sem justa causa"
                ]
            },
            {
                "name": "Caso Complexo - Recuperação Judicial",
                "expected_strategy": "ensemble",
                "expected_complexity": "high",
                "conversation": [
                    "Nossa empresa está enfrentando sérias dificuldades financeiras",
                    "Temos dívidas com fornecedores, bancos e também questões trabalhistas",
                    "Somos uma sociedade anônima com 3 sócios e 50 funcionários",
                    "Há também uma disputa de propriedade intelectual com um ex-sócio",
                    "Estamos considerando recuperação judicial para reorganizar as dívidas",
                    "Temos ativos imobilizados e alguns contratos internacionais"
                ]
            }
        ]
    
    async def run_all_tests(self):
        """Executa todos os testes da suite."""
        print("🚀 Iniciando Testes da Nova Arquitetura de Triagem Inteligente")
        print("=" * 70)
        
        results = []
        
        for i, test_case in enumerate(self.test_cases, 1):
            print(f"\n📋 Teste {i}: {test_case['name']}")
            print("-" * 50)
            
            result = await self.run_single_test(test_case)
            results.append(result)
            
            # Aguardar um pouco entre testes
            await asyncio.sleep(2)
        
        # Sumário final
        self.print_summary(results)
        
        return results
    
    async def run_single_test(self, test_case: Dict) -> Dict:
        """Executa um teste individual."""
        start_time = time.time()
        
        try:
            # Iniciar conversa
            case_id, first_message = await intelligent_interviewer_service.start_conversation("test_user")
            print(f"✅ Conversa iniciada: {case_id}")
            print(f"🤖 IA: {first_message}")
            
            # Simular conversa
            for i, user_message in enumerate(test_case["conversation"]):
                print(f"👤 Usuário: {user_message}")
                
                ai_response, is_complete = await intelligent_interviewer_service.continue_conversation(
                    case_id, user_message
                )
                
                print(f"🤖 IA: {ai_response}")
                
                if is_complete:
                    print("✅ Conversa finalizada automaticamente")
                    break
                
                # Mostrar status atual
                status = await intelligent_interviewer_service.get_conversation_status(case_id)
                if status:
                    complexity = status.get("complexity_level", "unknown")
                    confidence = status.get("confidence_score", 0)
                    print(f"📊 Status: Complexidade={complexity}, Confiança={confidence:.2f}")
                
                await asyncio.sleep(1)  # Simular tempo de resposta humana
            
            # Obter resultado final
            triage_result = await intelligent_interviewer_service.get_triage_result(case_id)
            
            if not triage_result:
                # Forçar finalização se necessário
                print("⚠️ Forçando finalização da conversa...")
                orchestration_result = await intelligent_triage_orchestrator.force_complete_conversation(
                    case_id, "test_completion"
                )
                if orchestration_result:
                    triage_result = orchestration_result
            
            # Processar com orquestrador se temos resultado
            if triage_result:
                # Simular processamento do orquestrador
                orchestration_result = await self.simulate_orchestration(triage_result)
                
                # Validar resultado
                validation = self.validate_result(test_case, orchestration_result)
                
                # Limpar recursos
                intelligent_interviewer_service.cleanup_conversation(case_id)
                
                total_time = time.time() - start_time
                
                return {
                    "test_name": test_case["name"],
                    "success": True,
                    "case_id": case_id,
                    "strategy_used": orchestration_result.strategy_used,
                    "complexity_detected": orchestration_result.complexity_level,
                    "confidence_score": orchestration_result.confidence_score,
                    "processing_time": total_time,
                    "validation": validation,
                    "triage_data": orchestration_result.triage_data
                }
            else:
                return {
                    "test_name": test_case["name"],
                    "success": False,
                    "error": "Não foi possível obter resultado da triagem",
                    "processing_time": time.time() - start_time
                }
                
        except Exception as e:
            return {
                "test_name": test_case["name"],
                "success": False,
                "error": str(e),
                "processing_time": time.time() - start_time
            }
    
    async def simulate_orchestration(self, triage_result):
        """Simula o processamento do orquestrador."""
        from backend.services.intelligent_triage_orchestrator import OrchestrationResult
        
        # Simular processamento baseado na estratégia
        processing_time = {
            "simple": 500,    # 500ms para casos simples
            "failover": 2000, # 2s para casos médios
            "ensemble": 5000  # 5s para casos complexos
        }.get(triage_result.strategy_used, 2000)
        
        return OrchestrationResult(
            case_id=triage_result.case_id,
            strategy_used=triage_result.strategy_used,
            complexity_level=triage_result.complexity_level,
            confidence_score=triage_result.confidence_score,
            triage_data=triage_result.triage_data,
            conversation_summary=triage_result.conversation_summary,
            processing_time_ms=processing_time,
            flow_type=f"{triage_result.strategy_used}_flow",
            analysis_details={
                "source": "test_simulation",
                "optimization": f"Teste simulado para estratégia {triage_result.strategy_used}"
            }
        )
    
    def validate_result(self, test_case: Dict, result) -> Dict:
        """Valida se o resultado está correto."""
        validations = {}
        
        # Validar estratégia
        expected_strategy = test_case["expected_strategy"]
        actual_strategy = result.strategy_used
        validations["strategy_correct"] = expected_strategy == actual_strategy
        
        # Validar complexidade
        expected_complexity = test_case["expected_complexity"]
        actual_complexity = result.complexity_level
        validations["complexity_correct"] = expected_complexity == actual_complexity
        
        # Validar confiança (deve ser > 0.5 para ser considerada boa)
        validations["confidence_good"] = result.confidence_score > 0.5
        
        # Validar dados de triagem
        triage_data = result.triage_data
        validations["has_area"] = bool(triage_data.get("area"))
        validations["has_summary"] = bool(triage_data.get("summary"))
        
        # Score geral
        validations["overall_score"] = sum(validations.values()) / len(validations)
        
        return validations
    
    def print_summary(self, results: List[Dict]):
        """Imprime sumário dos resultados."""
        print("\n" + "=" * 70)
        print("📊 SUMÁRIO DOS TESTES")
        print("=" * 70)
        
        total_tests = len(results)
        successful_tests = sum(1 for r in results if r["success"])
        
        print(f"Total de testes: {total_tests}")
        print(f"Sucessos: {successful_tests}")
        print(f"Falhas: {total_tests - successful_tests}")
        print(f"Taxa de sucesso: {successful_tests/total_tests*100:.1f}%")
        
        print("\n📋 DETALHES POR TESTE:")
        print("-" * 70)
        
        for result in results:
            if result["success"]:
                validation = result["validation"]
                print(f"✅ {result['test_name']}")
                print(f"   Estratégia: {result['strategy_used']} (esperada: {validation.get('strategy_correct', 'N/A')})")
                print(f"   Complexidade: {result['complexity_detected']} (esperada: {validation.get('complexity_correct', 'N/A')})")
                print(f"   Confiança: {result['confidence_score']:.2f}")
                print(f"   Tempo: {result['processing_time']:.2f}s")
                print(f"   Score geral: {validation['overall_score']:.2f}")
            else:
                print(f"❌ {result['test_name']}")
                print(f"   Erro: {result['error']}")
                print(f"   Tempo: {result['processing_time']:.2f}s")
            print()
        
        # Estatísticas por estratégia
        print("📈 ESTATÍSTICAS POR ESTRATÉGIA:")
        print("-" * 70)
        
        strategies = {}
        for result in results:
            if result["success"]:
                strategy = result["strategy_used"]
                if strategy not in strategies:
                    strategies[strategy] = {"count": 0, "avg_confidence": 0, "avg_time": 0}
                
                strategies[strategy]["count"] += 1
                strategies[strategy]["avg_confidence"] += result["confidence_score"]
                strategies[strategy]["avg_time"] += result["processing_time"]
        
        for strategy, stats in strategies.items():
            count = stats["count"]
            avg_conf = stats["avg_confidence"] / count
            avg_time = stats["avg_time"] / count
            
            print(f"{strategy.upper()}:")
            print(f"  Casos: {count}")
            print(f"  Confiança média: {avg_conf:.2f}")
            print(f"  Tempo médio: {avg_time:.2f}s")
            print()

async def run_demo_conversation():
    """Demonstração interativa da nova arquitetura."""
    print("\n🎯 DEMONSTRAÇÃO INTERATIVA")
    print("=" * 50)
    print("Digite 'sair' para encerrar a demonstração")
    print()
    
    # Iniciar conversa
    case_id, first_message = await intelligent_interviewer_service.start_conversation("demo_user")
    print(f"🤖 IA: {first_message}")
    
    while True:
        user_input = input("\n👤 Você: ")
        
        if user_input.lower() in ['sair', 'exit', 'quit']:
            print("👋 Encerrando demonstração...")
            break
        
        try:
            ai_response, is_complete = await intelligent_interviewer_service.continue_conversation(
                case_id, user_input
            )
            
            print(f"🤖 IA: {ai_response}")
            
            # Mostrar status
            status = await intelligent_interviewer_service.get_conversation_status(case_id)
            if status:
                complexity = status.get("complexity_level", "unknown")
                confidence = status.get("confidence_score", 0)
                strategy = status.get("strategy_recommended", "unknown")
                print(f"📊 Status: Complexidade={complexity}, Confiança={confidence:.2f}, Estratégia={strategy}")
            
            if is_complete:
                print("\n🎉 Conversa finalizada!")
                
                # Obter resultado
                result = await intelligent_interviewer_service.get_triage_result(case_id)
                if result:
                    print(f"📋 Resultado final:")
                    print(f"   Estratégia: {result.strategy_used}")
                    print(f"   Complexidade: {result.complexity_level}")
                    print(f"   Confiança: {result.confidence_score:.2f}")
                    print(f"   Área: {result.triage_data.get('area', 'N/A')}")
                    print(f"   Resumo: {result.triage_data.get('summary', 'N/A')}")
                
                break
                
        except Exception as e:
            print(f"❌ Erro: {e}")
    
    # Limpar recursos
    intelligent_interviewer_service.cleanup_conversation(case_id)

async def main():
    """Função principal do script de teste."""
    print("🧠 TESTE DA NOVA ARQUITETURA DE TRIAGEM INTELIGENTE")
    print("=" * 60)
    print()
    
    if len(sys.argv) > 1 and sys.argv[1] == "--demo":
        await run_demo_conversation()
    else:
        # Executar suite de testes
        test_suite = IntelligentTriageTestSuite()
        results = await test_suite.run_all_tests()
        
        # Salvar resultados
        with open("test_results.json", "w") as f:
            json.dump(results, f, indent=2, default=str)
        
        print(f"\n💾 Resultados salvos em 'test_results.json'")
        print("\n🎯 Para demonstração interativa, execute:")
        print("   python scripts/test_intelligent_triage.py --demo")

if __name__ == "__main__":
    asyncio.run(main()) 