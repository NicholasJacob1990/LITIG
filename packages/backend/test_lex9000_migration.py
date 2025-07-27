#!/usr/bin/env python3
"""
Teste de Migração LEX-9000 V1 → V2
==================================

Compara funcionamento entre:
- V1: GPT-4o + JSON parsing manual
- V2: Grok 4 + Function Calling + 4 níveis fallback

Executa os mesmos dados de teste em ambas versões e compara resultados.
"""

import asyncio
import json
import sys
import time
from typing import Dict, Any

# Adicionar path
sys.path.append('.')

try:
    from services.lex9000_integration_service import LEX9000IntegrationService
    from services.lex9000_integration_service_v2 import LEX9000IntegrationServiceV2
except ImportError as e:
    print(f"❌ Erro de import: {e}")
    print("Execute do diretório packages/backend/")
    sys.exit(1)


class LEX9000MigrationTester:
    """Testa migração do LEX-9000 V1 para V2."""
    
    def __init__(self):
        self.v1_service = LEX9000IntegrationService()
        self.v2_service = LEX9000IntegrationServiceV2()
        
        # Dados de teste representativos
        self.test_cases = [
            {
                "name": "Caso Trabalhista Simples",
                "data": {
                    "case_id": "test_001",
                    "user_id": "user_test",
                    "case_type": "Direito Trabalhista",
                    "complexity_level": "medium",
                    "urgency_indicators": ["prazo_prescricional"],
                    "final_summary": "Cliente trabalhou por 2 anos sem registro em carteira, foi demitido sem justa causa e não recebeu verbas rescisórias. Há evidências de trabalho (mensagens, testemunhas) e o prazo prescricional ainda não expirou.",
                    "messages": [
                        {"role": "assistant", "content": "Olá! Vou ajudá-lo com sua questão trabalhista. Pode me contar o que aconteceu?"},
                        {"role": "user", "content": "Trabalhei 2 anos numa empresa sem carteira assinada. Fui demitido e não recebi nada."},
                        {"role": "assistant", "content": "Entendo. Você tem alguma prova de que trabalhou lá? Mensagens, testemunhas, etc.?"},
                        {"role": "user", "content": "Sim, tenho prints de WhatsApp do chefe e colegas que podem testemunhar."},
                        {"role": "assistant", "content": "Perfeito. Quando foi a demissão? É importante para verificar prazos."},
                        {"role": "user", "content": "Foi há 6 meses."}
                    ]
                }
            },
            {
                "name": "Caso Civil Complexo", 
                "data": {
                    "case_id": "test_002",
                    "user_id": "user_test_2",
                    "case_type": "Direito Civil",
                    "complexity_level": "complex",
                    "urgency_indicators": ["valor_alto", "medida_urgente"],
                    "final_summary": "Contrato de compra e venda de imóvel com vício oculto descoberto após a escritura. Valor de R$ 500.000. Vendedor se recusa a reparar ou ressarcir. Há necessidade de perícia técnica e o caso envolve múltiplas partes incluindo construtora e corretora.",
                    "messages": [
                        {"role": "assistant", "content": "Vou analisar sua questão civil. Qual é o problema?"},
                        {"role": "user", "content": "Comprei um apartamento de 500 mil e descobri rachadura estrutural grave."},
                        {"role": "assistant", "content": "Quando descobriu o problema e o que o vendedor disse?"},
                        {"role": "user", "content": "Descobri 3 meses após a compra. O vendedor disse que não sabia e se recusa a pagar o reparo."},
                        {"role": "assistant", "content": "Há laudo técnico confirmando que é vício oculto?"},
                        {"role": "user", "content": "Sim, engenheiro confirmou que é problema estrutural anterior à venda."}
                    ]
                }
            }
        ]
    
    async def test_single_case(self, test_case: Dict[str, Any]) -> Dict[str, Any]:
        """Testa um caso específico em ambas versões."""
        
        case_name = test_case["name"]
        case_data = test_case["data"]
        
        print(f"\n🧪 TESTANDO: {case_name}")
        print("=" * 50)
        
        results = {
            "case_name": case_name,
            "v1_result": None,
            "v2_result": None,
            "v1_error": None,
            "v2_error": None,
            "v1_time": 0,
            "v2_time": 0,
            "comparison": {}
        }
        
        # Teste V1 (versão atual)
        print("🔄 Testando V1 (GPT-4o + JSON parsing)...")
        v1_start = time.time()
        try:
            v1_result = await self.v1_service.analyze_complex_case(case_data)
            results["v1_result"] = v1_result
            results["v1_time"] = time.time() - v1_start
            print(f"✅ V1 concluído em {results['v1_time']:.2f}s")
        except Exception as e:
            results["v1_error"] = str(e)
            results["v1_time"] = time.time() - v1_start
            print(f"❌ V1 falhou: {e}")
        
        # Teste V2 (nova versão)
        print("🔄 Testando V2 (Grok 4 + Function Calling)...")
        v2_start = time.time()
        try:
            v2_result = await self.v2_service.analyze_complex_case(case_data)
            results["v2_result"] = v2_result
            results["v2_time"] = time.time() - v2_start
            print(f"✅ V2 concluído em {results['v2_time']:.2f}s")
        except Exception as e:
            results["v2_error"] = str(e)
            results["v2_time"] = time.time() - v2_start
            print(f"❌ V2 falhou: {e}")
        
        # Comparar resultados
        if results["v1_result"] and results["v2_result"]:
            results["comparison"] = self._compare_results(
                results["v1_result"], 
                results["v2_result"]
            )
        
        return results
    
    def _compare_results(self, v1_result, v2_result) -> Dict[str, Any]:
        """Compara resultados das duas versões."""
        
        comparison = {
            "structure_compatible": True,
            "confidence_diff": 0,
            "time_improvement": 0,
            "quality_assessment": "unknown",
            "details": {}
        }
        
        try:
            # Comparar estrutura básica
            v1_keys = set(dir(v1_result))
            v2_keys = set(dir(v2_result))
            
            comparison["structure_compatible"] = v1_keys.issubset(v2_keys)
            
            # Comparar confiança
            if hasattr(v1_result, 'confidence_score') and hasattr(v2_result, 'confidence_score'):
                comparison["confidence_diff"] = v2_result.confidence_score - v1_result.confidence_score
            
            # Comparar campos específicos
            comparison["details"] = {
                "v1_classificacao": getattr(v1_result, 'classificacao', {}),
                "v2_classificacao": getattr(v2_result, 'classificacao', {}),
                "v1_urgencia": getattr(v1_result, 'urgencia', {}),
                "v2_urgencia": getattr(v2_result, 'urgencia', {}),
                "v2_metadata": getattr(v2_result, 'processing_metadata', {})
            }
            
            # Avaliar qualidade
            if hasattr(v2_result, 'fallback_level'):
                if v2_result.fallback_level == 1:
                    comparison["quality_assessment"] = "optimal"
                elif v2_result.fallback_level <= 2:
                    comparison["quality_assessment"] = "good"
                else:
                    comparison["quality_assessment"] = "degraded"
            
        except Exception as e:
            comparison["error"] = str(e)
        
        return comparison
    
    async def run_all_tests(self) -> Dict[str, Any]:
        """Executa todos os testes de migração."""
        
        print("🚀 INICIANDO TESTES DE MIGRAÇÃO LEX-9000")
        print("=" * 60)
        print("Comparando V1 (atual) vs V2 (nova)")
        print("V1: GPT-4o + JSON parsing manual")
        print("V2: Grok 4 + Function Calling + 4 níveis fallback")
        print("")
        
        all_results = {
            "summary": {
                "total_tests": len(self.test_cases),
                "v1_successes": 0,
                "v2_successes": 0,
                "v1_failures": 0,
                "v2_failures": 0,
                "avg_v1_time": 0,
                "avg_v2_time": 0,
                "compatibility_score": 0
            },
            "test_results": []
        }
        
        # Executar todos os casos de teste
        for test_case in self.test_cases:
            result = await self.test_single_case(test_case)
            all_results["test_results"].append(result)
            
            # Atualizar estatísticas
            if result["v1_result"]:
                all_results["summary"]["v1_successes"] += 1
            else:
                all_results["summary"]["v1_failures"] += 1
            
            if result["v2_result"]:
                all_results["summary"]["v2_successes"] += 1
            else:
                all_results["summary"]["v2_failures"] += 1
        
        # Calcular médias
        all_results["summary"]["avg_v1_time"] = sum(
            r["v1_time"] for r in all_results["test_results"]
        ) / len(all_results["test_results"])
        
        all_results["summary"]["avg_v2_time"] = sum(
            r["v2_time"] for r in all_results["test_results"]
        ) / len(all_results["test_results"])
        
        # Calcular score de compatibilidade
        compatible_tests = sum(
            1 for r in all_results["test_results"] 
            if r.get("comparison", {}).get("structure_compatible", False)
        )
        all_results["summary"]["compatibility_score"] = compatible_tests / len(all_results["test_results"])
        
        return all_results
    
    def print_final_report(self, results: Dict[str, Any]):
        """Imprime relatório final da migração."""
        
        print("\n" + "=" * 60)
        print("📊 RELATÓRIO FINAL DE MIGRAÇÃO")
        print("=" * 60)
        
        summary = results["summary"]
        
        print(f"\n🎯 RESULTADOS GERAIS:")
        print(f"   📝 Total de testes: {summary['total_tests']}")
        print(f"   ✅ V1 sucessos: {summary['v1_successes']}/{summary['total_tests']}")
        print(f"   ✅ V2 sucessos: {summary['v2_successes']}/{summary['total_tests']}")
        print(f"   ❌ V1 falhas: {summary['v1_failures']}")
        print(f"   ❌ V2 falhas: {summary['v2_failures']}")
        
        print(f"\n⏱️ PERFORMANCE:")
        print(f"   🕐 Tempo médio V1: {summary['avg_v1_time']:.2f}s")
        print(f"   🕐 Tempo médio V2: {summary['avg_v2_time']:.2f}s")
        
        if summary['avg_v1_time'] > 0:
            improvement = ((summary['avg_v1_time'] - summary['avg_v2_time']) / summary['avg_v1_time']) * 100
            print(f"   📈 Melhoria: {improvement:+.1f}%")
        
        print(f"\n🔗 COMPATIBILIDADE:")
        print(f"   📊 Score: {summary['compatibility_score']:.1%}")
        
        print(f"\n📋 DETALHES POR TESTE:")
        for result in results["test_results"]:
            case_name = result["case_name"]
            v1_status = "✅" if result["v1_result"] else "❌"
            v2_status = "✅" if result["v2_result"] else "❌"
            
            print(f"   {v1_status}{v2_status} {case_name}")
            
            if result.get("comparison"):
                comp = result["comparison"]
                quality = comp.get("quality_assessment", "unknown")
                conf_diff = comp.get("confidence_diff", 0)
                
                print(f"      🎯 Qualidade V2: {quality}")
                print(f"      📊 Diferença confiança: {conf_diff:+.2f}")
        
        print(f"\n🏆 RECOMENDAÇÃO:")
        
        if summary["v2_successes"] >= summary["v1_successes"]:
            if summary["compatibility_score"] >= 0.8:
                print("   🚀 MIGRAÇÃO APROVADA!")
                print("   ✅ V2 demonstra performance igual ou superior")
                print("   ✅ Compatibilidade estrutural mantida")
                print("   ✅ Pronto para deploy em produção")
            else:
                print("   ⚠️ MIGRAÇÃO COM RESSALVAS")
                print("   ✅ Performance adequada")
                print("   ⚠️ Verificar compatibilidade estrutural")
                print("   🔧 Ajustes recomendados antes do deploy")
        else:
            print("   ❌ MIGRAÇÃO NÃO RECOMENDADA")
            print("   ❌ V2 apresenta performance inferior")
            print("   🔧 Necessários ajustes antes de prosseguir")


async def main():
    """Função principal."""
    tester = LEX9000MigrationTester()
    
    try:
        # Executar todos os testes
        results = await tester.run_all_tests()
        
        # Gerar relatório
        tester.print_final_report(results)
        
        # Salvar resultados em arquivo
        timestamp = int(time.time())
        filename = f"lex9000_migration_test_{timestamp}.json"
        
        with open(filename, "w") as f:
            # Converter dataclasses para dict para serialização
            serializable_results = json.loads(json.dumps(results, default=str))
            json.dump(serializable_results, f, indent=2)
        
        print(f"\n💾 Resultados salvos em: {filename}")
        
        # Código de saída baseado no sucesso
        if results["summary"]["v2_successes"] >= results["summary"]["v1_successes"]:
            return 0  # Sucesso
        else:
            return 1  # Falha
        
    except Exception as e:
        print(f"\n❌ Erro durante os testes: {str(e)}")
        return 1


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code) 
 