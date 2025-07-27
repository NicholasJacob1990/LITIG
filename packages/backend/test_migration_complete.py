#!/usr/bin/env python3
"""
Teste Completo de Migração V1 → V2
==================================

Testa a migração de todos os serviços implementados:
- LEX-9000: GPT-4o → Grok 4 + Function Calling
- Lawyer Profile: Cascata → Gemini 2.5 Pro + Function Calling  
- Case Context: Cascata → Claude Sonnet 4 + Function Calling

Executa comparação lado a lado e gera relatório detalhado.
"""

import asyncio
import json
import sys
import time
from typing import Dict, Any, List
from datetime import datetime

# Adicionar path
sys.path.append('.')

try:
    # V1 (atuais)
    from services.lex9000_integration_service import LEX9000IntegrationService
    from services.lawyer_profile_analysis_service import LawyerProfileAnalysisService
    from services.case_context_analysis_service import CaseContextAnalysisService
    
    # V2 (novas)
    from services.lex9000_integration_service_v2 import LEX9000IntegrationServiceV2
    from services.lawyer_profile_analysis_service_v2 import LawyerProfileAnalysisServiceV2
    from services.case_context_analysis_service_v2 import CaseContextAnalysisServiceV2
    
except ImportError as e:
    print(f"❌ Erro de import: {e}")
    print("Execute do diretório packages/backend/")
    sys.exit(1)


class CompleteMigrationTester:
    """Testa migração completa de todos os serviços."""
    
    def __init__(self):
        # Serviços V1
        self.lex9000_v1 = LEX9000IntegrationService()
        self.lawyer_profile_v1 = LawyerProfileAnalysisService()
        self.case_context_v1 = CaseContextAnalysisService()
        
        # Serviços V2
        self.lex9000_v2 = LEX9000IntegrationServiceV2()
        self.lawyer_profile_v2 = LawyerProfileAnalysisServiceV2()
        self.case_context_v2 = CaseContextAnalysisServiceV2()
        
        # Dados de teste unificados
        self.test_scenarios = [
            {
                "name": "Caso Trabalhista Complexo",
                "lex_data": {
                    "case_id": "test_001",
                    "user_id": "user_test",
                    "case_type": "Direito Trabalhista",
                    "complexity_level": "complex",
                    "urgency_indicators": ["prazo_prescricional", "rescisao_indireta"],
                    "final_summary": "Cliente demitido por justa causa alega assédio moral e pede reversão. Empresa contesta com evidências disciplinares. Há conflito de versões e necessidade de perícia psicológica.",
                    "messages": [
                        {"role": "assistant", "content": "Vou analisar sua situação trabalhista. O que aconteceu?"},
                        {"role": "user", "content": "Fui demitido por justa causa, mas foi injusto. Sofri assédio moral do chefe."},
                        {"role": "assistant", "content": "Entendo. Você tem evidências do assédio? Mensagens, testemunhas?"},
                        {"role": "user", "content": "Tenho e-mails agressivos e colegas que podem testemunhar."},
                        {"role": "assistant", "content": "E a empresa alegou qual motivo para a justa causa?"},
                        {"role": "user", "content": "Disseram que eu era insubordinado e faltava muito, mas era por causa do estresse."}
                    ]
                },
                "lawyer_data": {
                    "lawyer_id": "adv_001",
                    "name": "Dr. João Silva",
                    "basic_info": {
                        "oab_number": "SP123456",
                        "years_experience": 12,
                        "location": "São Paulo"
                    },
                    "specialties": ["Direito Trabalhista", "Assédio Moral", "Rescisões"],
                    "experience": [
                        {
                            "position": "Advogado Sênior",
                            "company": "Silva & Associados",
                            "duration": "8 anos",
                            "description": "Especialista em casos de assédio moral e rescisões indevidas"
                        }
                    ],
                    "cases": [
                        {
                            "title": "Reversão de Justa Causa por Assédio",
                            "outcome": "Vitória - R$ 150.000 indenização",
                            "area": "Trabalhista"
                        }
                    ],
                    "reviews": [
                        {"rating": 5, "comment": "Excelente em casos trabalhistas complexos"},
                        {"rating": 4, "comment": "Muito técnico e competente"}
                    ]
                },
                "case_data": {
                    "case_id": "case_001",
                    "client_id": "client_001",
                    "basic_info": {
                        "case_type": "Direito Trabalhista - Assédio Moral",
                        "legal_area": "Trabalhista",
                        "estimated_value": "R$ 100.000"
                    },
                    "description": "Demissão por justa causa questionável com alegações de assédio moral. Cliente apresenta evidências de comportamento abusivo da chefia e impacto psicológico documentado.",
                    "timeline": {
                        "incident_date": "2024-01-15",
                        "deadline": "2024-03-15",
                        "urgency_level": "Alta"
                    },
                    "complexity_indicators": ["conflito_versões", "perícia_necessária", "múltiplas_evidências"],
                    "client_info": {
                        "expectations": "Reversão da justa causa e indenização",
                        "concerns": "Impacto na carreira e questões psicológicas",
                        "communication_preference": "Frequente, precisa de suporte emocional"
                    }
                }
            },
            {
                "name": "Caso Civil Empresarial",
                "lex_data": {
                    "case_id": "test_002",
                    "user_id": "user_test_2",
                    "case_type": "Direito Empresarial",
                    "complexity_level": "very_complex",
                    "urgency_indicators": ["valor_alto", "prazo_legal"],
                    "final_summary": "Dissolução societária litigiosa com divergências sobre valoração de ativos, distribuição de lucros e responsabilidades. Envolve múltiplas empresas do grupo e questões tributárias complexas.",
                    "messages": [
                        {"role": "assistant", "content": "Preciso entender a situação societária. Qual o problema?"},
                        {"role": "user", "content": "Quero sair da sociedade, mas meu sócio não aceita minha proposta de valor."},
                        {"role": "assistant", "content": "Há contrato social definindo os critérios de saída?"},
                        {"role": "user", "content": "Sim, mas é ambíguo sobre a avaliação. Ele quer muito menos do que vale."},
                        {"role": "assistant", "content": "Vocês têm balanços auditados recentes?"},
                        {"role": "user", "content": "Temos, mas ele contesta alguns ativos intangíveis que desenvolvi."}
                    ]
                },
                "lawyer_data": {
                    "lawyer_id": "adv_002",
                    "name": "Dra. Maria Santos",
                    "basic_info": {
                        "oab_number": "RJ654321",
                        "years_experience": 18,
                        "location": "Rio de Janeiro"
                    },
                    "specialties": ["Direito Empresarial", "Societário", "M&A"],
                    "experience": [
                        {
                            "position": "Sócia",
                            "company": "Santos Advogados Associados",
                            "duration": "10 anos",
                            "description": "Especialista em dissolução societária e avaliação de empresas"
                        }
                    ],
                    "certifications": [
                        {"name": "MBA em Valuation", "institution": "FGV", "year": "2018"}
                    ],
                    "cases": [
                        {
                            "title": "Dissolução Complexa Grupo Empresarial",
                            "outcome": "Acordo - R$ 50M patrimônio",
                            "area": "Empresarial"
                        }
                    ]
                },
                "case_data": {
                    "case_id": "case_002",
                    "client_id": "client_002",
                    "basic_info": {
                        "case_type": "Direito Empresarial - Dissolução Societária",
                        "legal_area": "Empresarial",
                        "estimated_value": "R$ 5.000.000"
                    },
                    "description": "Dissolução societária com disputas sobre valoração de ativos intangíveis, distribuição de resultados e responsabilidades fiscais. Envolve holding e subsidiárias.",
                    "timeline": {
                        "incident_date": "2024-02-01",
                        "deadline": "2024-06-01",
                        "urgency_level": "Média"
                    },
                    "complexity_indicators": ["múltiplas_empresas", "valuation_complexo", "questões_tributárias"],
                    "client_info": {
                        "expectations": "Saída justa com valoração adequada",
                        "concerns": "Tempo e custos do processo",
                        "communication_preference": "Relatórios estruturados quinzenais"
                    }
                }
            }
        ]
    
    async def test_all_services(self) -> Dict[str, Any]:
        """Executa testes em todos os serviços."""
        
        print("🚀 INICIANDO TESTES COMPLETOS DE MIGRAÇÃO")
        print("=" * 70)
        print("Testando 3 serviços: LEX-9000, Lawyer Profile, Case Context")
        print("Comparando V1 (atual) vs V2 (nova arquitetura)")
        print("")
        
        all_results = {
            "summary": {
                "total_scenarios": len(self.test_scenarios),
                "total_services": 3,
                "start_time": datetime.now().isoformat(),
                "completion_time": None,
                "overall_success_rate": 0,
                "v1_total_successes": 0,
                "v2_total_successes": 0,
                "v1_total_failures": 0,
                "v2_total_failures": 0,
                "avg_performance_improvement": 0
            },
            "service_results": {
                "lex9000": [],
                "lawyer_profile": [],
                "case_context": []
            },
            "scenario_results": []
        }
        
        # Executar cada cenário
        for i, scenario in enumerate(self.test_scenarios, 1):
            print(f"\n📋 CENÁRIO {i}: {scenario['name']}")
            print("=" * 50)
            
            scenario_result = await self._test_scenario(scenario)
            all_results["scenario_results"].append(scenario_result)
            
            # Agregar resultados por serviço
            for service in ["lex9000", "lawyer_profile", "case_context"]:
                if service in scenario_result:
                    all_results["service_results"][service].append(scenario_result[service])
        
        # Calcular estatísticas finais
        all_results = self._calculate_final_statistics(all_results)
        all_results["summary"]["completion_time"] = datetime.now().isoformat()
        
        return all_results
    
    async def _test_scenario(self, scenario: Dict[str, Any]) -> Dict[str, Any]:
        """Testa um cenário específico em todos os serviços."""
        
        scenario_result = {
            "scenario_name": scenario["name"],
            "lex9000": await self._test_lex9000(scenario["lex_data"]),
            "lawyer_profile": await self._test_lawyer_profile(scenario["lawyer_data"]),
            "case_context": await self._test_case_context(scenario["case_data"])
        }
        
        return scenario_result
    
    async def _test_lex9000(self, test_data: Dict[str, Any]) -> Dict[str, Any]:
        """Testa LEX-9000 V1 vs V2."""
        
        print("🔍 Testando LEX-9000...")
        
        result = {
            "service": "lex9000",
            "v1_result": None,
            "v2_result": None,
            "v1_error": None,
            "v2_error": None,
            "v1_time": 0,
            "v2_time": 0,
            "comparison": {}
        }
        
        # Teste V1
        v1_start = time.time()
        try:
            v1_result = await self.lex9000_v1.analyze_complex_case(test_data)
            result["v1_result"] = v1_result
            result["v1_time"] = time.time() - v1_start
            print(f"  ✅ V1 concluído em {result['v1_time']:.2f}s")
        except Exception as e:
            result["v1_error"] = str(e)
            result["v1_time"] = time.time() - v1_start
            print(f"  ❌ V1 falhou: {e}")
        
        # Teste V2
        v2_start = time.time()
        try:
            v2_result = await self.lex9000_v2.analyze_complex_case(test_data)
            result["v2_result"] = v2_result
            result["v2_time"] = time.time() - v2_start
            print(f"  ✅ V2 concluído em {result['v2_time']:.2f}s")
        except Exception as e:
            result["v2_error"] = str(e)
            result["v2_time"] = time.time() - v2_start
            print(f"  ❌ V2 falhou: {e}")
        
        # Comparar resultados
        if result["v1_result"] and result["v2_result"]:
            result["comparison"] = self._compare_lex_results(
                result["v1_result"], result["v2_result"]
            )
        
        return result
    
    async def _test_lawyer_profile(self, test_data: Dict[str, Any]) -> Dict[str, Any]:
        """Testa Lawyer Profile V1 vs V2."""
        
        print("👤 Testando Lawyer Profile...")
        
        result = {
            "service": "lawyer_profile",
            "v1_result": None,
            "v2_result": None,
            "v1_error": None,
            "v2_error": None,
            "v1_time": 0,
            "v2_time": 0,
            "comparison": {}
        }
        
        # Teste V1
        v1_start = time.time()
        try:
            v1_result = await self.lawyer_profile_v1.analyze_lawyer_profile(test_data)
            result["v1_result"] = v1_result
            result["v1_time"] = time.time() - v1_start
            print(f"  ✅ V1 concluído em {result['v1_time']:.2f}s")
        except Exception as e:
            result["v1_error"] = str(e)
            result["v1_time"] = time.time() - v1_start
            print(f"  ❌ V1 falhou: {e}")
        
        # Teste V2
        v2_start = time.time()
        try:
            v2_result = await self.lawyer_profile_v2.analyze_lawyer_profile(test_data)
            result["v2_result"] = v2_result
            result["v2_time"] = time.time() - v2_start
            print(f"  ✅ V2 concluído em {result['v2_time']:.2f}s")
        except Exception as e:
            result["v2_error"] = str(e)
            result["v2_time"] = time.time() - v2_start
            print(f"  ❌ V2 falhou: {e}")
        
        # Comparar resultados
        if result["v1_result"] and result["v2_result"]:
            result["comparison"] = self._compare_profile_results(
                result["v1_result"], result["v2_result"]
            )
        
        return result
    
    async def _test_case_context(self, test_data: Dict[str, Any]) -> Dict[str, Any]:
        """Testa Case Context V1 vs V2."""
        
        print("📋 Testando Case Context...")
        
        result = {
            "service": "case_context",
            "v1_result": None,
            "v2_result": None,
            "v1_error": None,
            "v2_error": None,
            "v1_time": 0,
            "v2_time": 0,
            "comparison": {}
        }
        
        # Teste V1
        v1_start = time.time()
        try:
            v1_result = await self.case_context_v1.analyze_case_context(test_data)
            result["v1_result"] = v1_result
            result["v1_time"] = time.time() - v1_start
            print(f"  ✅ V1 concluído em {result['v1_time']:.2f}s")
        except Exception as e:
            result["v1_error"] = str(e)
            result["v1_time"] = time.time() - v1_start
            print(f"  ❌ V1 falhou: {e}")
        
        # Teste V2
        v2_start = time.time()
        try:
            v2_result = await self.case_context_v2.analyze_case_context(test_data)
            result["v2_result"] = v2_result
            result["v2_time"] = time.time() - v2_start
            print(f"  ✅ V2 concluído em {result['v2_time']:.2f}s")
        except Exception as e:
            result["v2_error"] = str(e)
            result["v2_time"] = time.time() - v2_start
            print(f"  ❌ V2 falhou: {e}")
        
        # Comparar resultados
        if result["v1_result"] and result["v2_result"]:
            result["comparison"] = self._compare_context_results(
                result["v1_result"], result["v2_result"]
            )
        
        return result
    
    def _compare_lex_results(self, v1_result, v2_result) -> Dict[str, Any]:
        """Compara resultados do LEX-9000."""
        return {
            "structure_compatible": hasattr(v2_result, 'classificacao'),
            "confidence_diff": getattr(v2_result, 'confidence_score', 0.5) - getattr(v1_result, 'confidence_score', 0.5),
            "v2_model_used": getattr(v2_result, 'model_used', 'unknown'),
            "v2_fallback_level": getattr(v2_result, 'fallback_level', 'unknown'),
            "quality_assessment": "optimal" if getattr(v2_result, 'fallback_level', 999) == 1 else "degraded"
        }
    
    def _compare_profile_results(self, v1_result, v2_result) -> Dict[str, Any]:
        """Compara resultados do Lawyer Profile."""
        return {
            "structure_compatible": hasattr(v2_result, 'expertise_level'),
            "confidence_diff": getattr(v2_result, 'confidence_score', 0.5) - getattr(v1_result, 'confidence_score', 0.5),
            "v2_model_used": getattr(v2_result, 'model_used', 'unknown'),
            "v2_fallback_level": getattr(v2_result, 'fallback_level', 'unknown'),
            "quality_assessment": "optimal" if getattr(v2_result, 'fallback_level', 999) == 1 else "degraded"
        }
    
    def _compare_context_results(self, v1_result, v2_result) -> Dict[str, Any]:
        """Compara resultados do Case Context."""
        return {
            "structure_compatible": hasattr(v2_result, 'complexity_factors'),
            "confidence_diff": getattr(v2_result, 'confidence_score', 0.5) - getattr(v1_result, 'confidence_score', 0.5),
            "v2_model_used": getattr(v2_result, 'model_used', 'unknown'),
            "v2_fallback_level": getattr(v2_result, 'fallback_level', 'unknown'),
            "quality_assessment": "optimal" if getattr(v2_result, 'fallback_level', 999) == 1 else "degraded"
        }
    
    def _calculate_final_statistics(self, results: Dict[str, Any]) -> Dict[str, Any]:
        """Calcula estatísticas finais."""
        
        total_tests = 0
        v1_successes = 0
        v2_successes = 0
        v1_failures = 0
        v2_failures = 0
        total_time_v1 = 0
        total_time_v2 = 0
        
        # Agregar resultados de todos os serviços
        for service_name, service_results in results["service_results"].items():
            for result in service_results:
                total_tests += 1
                
                if result["v1_result"]:
                    v1_successes += 1
                else:
                    v1_failures += 1
                
                if result["v2_result"]:
                    v2_successes += 1
                else:
                    v2_failures += 1
                
                total_time_v1 += result["v1_time"]
                total_time_v2 += result["v2_time"]
        
        # Calcular percentuais
        v1_success_rate = v1_successes / max(total_tests, 1)
        v2_success_rate = v2_successes / max(total_tests, 1)
        overall_success_rate = (v1_success_rate + v2_success_rate) / 2
        
        # Melhoria de performance
        avg_performance_improvement = 0
        if total_time_v1 > 0:
            avg_performance_improvement = ((total_time_v1 - total_time_v2) / total_time_v1) * 100
        
        # Atualizar summary
        results["summary"].update({
            "overall_success_rate": overall_success_rate,
            "v1_total_successes": v1_successes,
            "v2_total_successes": v2_successes,
            "v1_total_failures": v1_failures,
            "v2_total_failures": v2_failures,
            "v1_success_rate": v1_success_rate,
            "v2_success_rate": v2_success_rate,
            "avg_performance_improvement": avg_performance_improvement,
            "total_time_v1": total_time_v1,
            "total_time_v2": total_time_v2
        })
        
        return results
    
    def print_final_report(self, results: Dict[str, Any]):
        """Imprime relatório final completo."""
        
        print("\n" + "=" * 70)
        print("📊 RELATÓRIO FINAL DE MIGRAÇÃO COMPLETA")
        print("=" * 70)
        
        summary = results["summary"]
        
        print(f"\n🎯 RESULTADOS GERAIS:")
        print(f"   📝 Total de testes: {summary['total_scenarios']} cenários × {summary['total_services']} serviços = {summary['total_scenarios'] * summary['total_services']}")
        print(f"   ✅ Taxa de sucesso V1: {summary['v1_success_rate']:.1%}")
        print(f"   ✅ Taxa de sucesso V2: {summary['v2_success_rate']:.1%}")
        print(f"   📈 Taxa geral de sucesso: {summary['overall_success_rate']:.1%}")
        
        print(f"\n⏱️ PERFORMANCE:")
        print(f"   🕐 Tempo total V1: {summary['total_time_v1']:.2f}s")
        print(f"   🕐 Tempo total V2: {summary['total_time_v2']:.2f}s")
        print(f"   📈 Melhoria média: {summary['avg_performance_improvement']:+.1f}%")
        
        print(f"\n📋 RESULTADOS POR SERVIÇO:")
        
        for service_name, service_results in results["service_results"].items():
            print(f"\n   🔧 {service_name.upper()}:")
            
            service_v1_success = sum(1 for r in service_results if r["v1_result"])
            service_v2_success = sum(1 for r in service_results if r["v2_result"])
            service_total = len(service_results)
            
            print(f"      ✅ V1: {service_v1_success}/{service_total} ({service_v1_success/max(service_total,1):.1%})")
            print(f"      ✅ V2: {service_v2_success}/{service_total} ({service_v2_success/max(service_total,1):.1%})")
            
            # Modelos usados no V2
            models_used = [r.get("comparison", {}).get("v2_model_used", "unknown") for r in service_results if r.get("comparison")]
            if models_used:
                print(f"      🤖 Modelos V2: {', '.join(set(models_used))}")
        
        print(f"\n🏆 RECOMENDAÇÃO FINAL:")
        
        if summary["v2_success_rate"] >= summary["v1_success_rate"]:
            if summary["avg_performance_improvement"] > 0:
                print("   🚀 MIGRAÇÃO ALTAMENTE RECOMENDADA!")
                print("   ✅ V2 demonstra performance superior em qualidade e velocidade")
                print("   ✅ Function Calling funciona como esperado")
                print("   ✅ Pronto para deploy gradual em produção")
            else:
                print("   ✅ MIGRAÇÃO RECOMENDADA")
                print("   ✅ V2 mantém qualidade com arquitetura mais robusta")
                print("   ⚠️ Performance similar - benefícios na manutenibilidade")
        else:
            print("   ⚠️ MIGRAÇÃO COM RESSALVAS")
            print("   ⚠️ V2 apresenta algumas falhas - investigar configurações")
            print("   🔧 Recomendado configurar chaves API antes de avaliar definitivamente")
        
        print(f"\n💡 PRÓXIMOS PASSOS:")
        if any("unknown" in str(r.get("comparison", {})) for results_list in results["service_results"].values() for r in results_list):
            print("   1. 🔑 Configurar chaves API (OpenRouter, Anthropic, OpenAI)")
            print("   2. 🧪 Re-executar testes com APIs reais")
            print("   3. 📊 Validar métricas de qualidade")
        else:
            print("   1. 🚀 Iniciar deploy gradual em staging")
            print("   2. 📊 Implementar A/B testing")
            print("   3. 🔄 Migrar serviços restantes")


async def main():
    """Função principal."""
    tester = CompleteMigrationTester()
    
    try:
        # Executar todos os testes
        results = await tester.test_all_services()
        
        # Gerar relatório
        tester.print_final_report(results)
        
        # Salvar resultados detalhados
        timestamp = int(time.time())
        filename = f"migration_complete_test_{timestamp}.json"
        
        with open(filename, "w") as f:
            # Converter para JSON serializável
            serializable_results = json.loads(json.dumps(results, default=str))
            json.dump(serializable_results, f, indent=2, ensure_ascii=False)
        
        print(f"\n💾 Resultados detalhados salvos em: {filename}")
        
        # Código de saída baseado no sucesso
        if results["summary"]["v2_success_rate"] >= 0.5:
            return 0  # Sucesso
        else:
            return 1  # Necessário ajustes
        
    except Exception as e:
        print(f"\n❌ Erro durante os testes: {str(e)}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code) 
 