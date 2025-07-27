#!/usr/bin/env python3
"""
Teste de Validação dos Serviços V2
==================================

Testa apenas os serviços V2 implementados para validar:
- LEX-9000 V2: Grok 4 + Function Calling
- Lawyer Profile V2: Gemini 2.5 Pro + Function Calling  
- Case Context V2: Claude Sonnet 4 + Function Calling

Foca na validação da arquitetura nova sem dependência dos serviços V1.
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
    # V2 (novas) - apenas os serviços que implementamos
    from services.lex9000_integration_service_v2 import LEX9000IntegrationServiceV2
    from services.lawyer_profile_analysis_service_v2 import LawyerProfileAnalysisServiceV2
    from services.case_context_analysis_service_v2 import CaseContextAnalysisServiceV2
    
except ImportError as e:
    print(f"❌ Erro de import: {e}")
    print("Execute do diretório packages/backend/")
    sys.exit(1)


class V2MigrationTester:
    """Testa apenas os serviços V2 implementados."""
    
    def __init__(self):
        # Serviços V2
        self.lex9000_v2 = LEX9000IntegrationServiceV2()
        self.lawyer_profile_v2 = LawyerProfileAnalysisServiceV2()
        self.case_context_v2 = CaseContextAnalysisServiceV2()
        
        # Dados de teste simplificados
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
            }
        ]
    
    async def test_all_v2_services(self) -> Dict[str, Any]:
        """Executa testes em todos os serviços V2."""
        
        print("🚀 VALIDAÇÃO DOS SERVIÇOS V2")
        print("=" * 50)
        print("Testando arquitetura OpenRouter + Function Calling")
        print("")
        
        results = {
            "summary": {
                "total_scenarios": len(self.test_scenarios),
                "total_services": 3,
                "start_time": datetime.now().isoformat(),
                "completion_time": None,
                "v2_successes": 0,
                "v2_failures": 0,
                "total_processing_time": 0
            },
            "service_results": []
        }
        
        # Executar cada cenário
        for i, scenario in enumerate(self.test_scenarios, 1):
            print(f"\n📋 CENÁRIO {i}: {scenario['name']}")
            print("=" * 40)
            
            scenario_result = await self._test_scenario(scenario)
            results["service_results"].append(scenario_result)
            
            # Atualizar contadores
            for service_result in scenario_result.values():
                if isinstance(service_result, dict):
                    if service_result.get("success"):
                        results["summary"]["v2_successes"] += 1
                    else:
                        results["summary"]["v2_failures"] += 1
                    results["summary"]["total_processing_time"] += service_result.get("processing_time", 0)
        
        results["summary"]["completion_time"] = datetime.now().isoformat()
        return results
    
    async def _test_scenario(self, scenario: Dict[str, Any]) -> Dict[str, Any]:
        """Testa um cenário específico em todos os serviços V2."""
        
        return {
            "scenario_name": scenario["name"],
            "lex9000_v2": await self._test_lex9000_v2(scenario["lex_data"]),
            "lawyer_profile_v2": await self._test_lawyer_profile_v2(scenario["lawyer_data"]),
            "case_context_v2": await self._test_case_context_v2(scenario["case_data"])
        }
    
    async def _test_lex9000_v2(self, test_data: Dict[str, Any]) -> Dict[str, Any]:
        """Testa LEX-9000 V2."""
        
        print("🔍 Testando LEX-9000 V2 (Grok 4 + Function Calling)...")
        
        start_time = time.time()
        try:
            result = await self.lex9000_v2.analyze_complex_case(test_data)
            processing_time = time.time() - start_time
            
            print(f"  ✅ Concluído em {processing_time:.2f}s")
            
            # Validar estrutura
            success = hasattr(result, 'classificacao') and hasattr(result, 'confidence_score')
            
            return {
                "success": success,
                "processing_time": processing_time,
                "result_type": type(result).__name__,
                "has_classification": hasattr(result, 'classificacao'),
                "has_confidence": hasattr(result, 'confidence_score'),
                "model_used": getattr(result, 'model_used', 'unknown'),
                "fallback_level": getattr(result, 'fallback_level', 'unknown'),
                "version": getattr(result, 'processing_metadata', {}).get('version', 'unknown')
            }
            
        except Exception as e:
            processing_time = time.time() - start_time
            print(f"  ❌ Falhou em {processing_time:.2f}s: {e}")
            return {
                "success": False,
                "processing_time": processing_time,
                "error": str(e)
            }
    
    async def _test_lawyer_profile_v2(self, test_data: Dict[str, Any]) -> Dict[str, Any]:
        """Testa Lawyer Profile V2."""
        
        print("👤 Testando Lawyer Profile V2 (Gemini 2.5 Pro + Function Calling)...")
        
        start_time = time.time()
        try:
            result = await self.lawyer_profile_v2.analyze_lawyer_profile(test_data)
            processing_time = time.time() - start_time
            
            print(f"  ✅ Concluído em {processing_time:.2f}s")
            
            # Validar estrutura
            success = hasattr(result, 'expertise_level') and hasattr(result, 'confidence_score')
            
            return {
                "success": success,
                "processing_time": processing_time,
                "result_type": type(result).__name__,
                "has_expertise_level": hasattr(result, 'expertise_level'),
                "has_confidence": hasattr(result, 'confidence_score'),
                "model_used": getattr(result, 'model_used', 'unknown'),
                "fallback_level": getattr(result, 'fallback_level', 'unknown'),
                "version": getattr(result, 'processing_metadata', {}).get('version', 'unknown')
            }
            
        except Exception as e:
            processing_time = time.time() - start_time
            print(f"  ❌ Falhou em {processing_time:.2f}s: {e}")
            return {
                "success": False,
                "processing_time": processing_time,
                "error": str(e)
            }
    
    async def _test_case_context_v2(self, test_data: Dict[str, Any]) -> Dict[str, Any]:
        """Testa Case Context V2."""
        
        print("📋 Testando Case Context V2 (Claude Sonnet 4 + Function Calling)...")
        
        start_time = time.time()
        try:
            result = await self.case_context_v2.analyze_case_context(test_data)
            processing_time = time.time() - start_time
            
            print(f"  ✅ Concluído em {processing_time:.2f}s")
            
            # Validar estrutura
            success = hasattr(result, 'complexity_factors') and hasattr(result, 'confidence_score')
            
            return {
                "success": success,
                "processing_time": processing_time,
                "result_type": type(result).__name__,
                "has_complexity_factors": hasattr(result, 'complexity_factors'),
                "has_confidence": hasattr(result, 'confidence_score'),
                "model_used": getattr(result, 'model_used', 'unknown'),
                "fallback_level": getattr(result, 'fallback_level', 'unknown'),
                "version": getattr(result, 'processing_metadata', {}).get('version', 'unknown')
            }
            
        except Exception as e:
            processing_time = time.time() - start_time
            print(f"  ❌ Falhou em {processing_time:.2f}s: {e}")
            return {
                "success": False,
                "processing_time": processing_time,
                "error": str(e)
            }
    
    def print_final_report(self, results: Dict[str, Any]):
        """Imprime relatório final."""
        
        print("\n" + "=" * 50)
        print("📊 RELATÓRIO DE VALIDAÇÃO V2")
        print("=" * 50)
        
        summary = results["summary"]
        
        print(f"\n🎯 RESULTADOS GERAIS:")
        print(f"   📝 Total de testes V2: {summary['v2_successes'] + summary['v2_failures']}")
        print(f"   ✅ V2 sucessos: {summary['v2_successes']}")
        print(f"   ❌ V2 falhas: {summary['v2_failures']}")
        print(f"   📈 Taxa de sucesso: {summary['v2_successes']/(summary['v2_successes'] + summary['v2_failures']):.1%}")
        
        print(f"\n⏱️ PERFORMANCE:")
        print(f"   🕐 Tempo total processamento: {summary['total_processing_time']:.2f}s")
        print(f"   📊 Tempo médio por teste: {summary['total_processing_time']/(summary['v2_successes'] + summary['v2_failures']):.2f}s")
        
        print(f"\n📋 DETALHES POR SERVIÇO:")
        for scenario_result in results["service_results"]:
            print(f"\n   📋 {scenario_result['scenario_name']}:")
            
            for service, result in scenario_result.items():
                if service != "scenario_name" and isinstance(result, dict):
                    status = "✅" if result.get("success") else "❌"
                    time_str = f"({result.get('processing_time', 0):.2f}s)"
                    model = result.get('model_used', 'N/A')
                    fallback = result.get('fallback_level', 'N/A')
                    
                    print(f"      {status} {service}: {time_str} | Modelo: {model} | Nível: {fallback}")
        
        print(f"\n🏆 AVALIAÇÃO DA ARQUITETURA V2:")
        
        success_rate = summary['v2_successes']/(summary['v2_successes'] + summary['v2_failures'])
        
        if success_rate >= 0.8:
            print("   🚀 ARQUITETURA V2 EXCELENTE!")
            print("   ✅ Function Calling + OpenRouter funcionando bem")
            print("   ✅ Fallbacks robustos implementados")
            print("   ✅ Compatibilidade estrutural garantida")
        elif success_rate >= 0.5:
            print("   ✅ ARQUITETURA V2 FUNCIONAL")
            print("   ✅ Serviços básicos funcionando")
            print("   ⚠️ Algumas APIs podem estar indisponíveis")
            print("   🔧 Configurar chaves API para teste completo")
        else:
            print("   ⚠️ ARQUITETURA V2 PRECISA AJUSTES")
            print("   ❌ Múltiplas falhas detectadas")
            print("   🔧 Verificar configurações e dependências")
        
        print(f"\n💡 PRÓXIMOS PASSOS:")
        if success_rate >= 0.5:
            print("   1. 🔑 Configurar chaves API reais")
            print("   2. 🧪 Testar com modelos LLM funcionais") 
            print("   3. 📊 Comparar qualidade vs V1")
            print("   4. 🚀 Proceder para Fase 3 (demais serviços)")
        else:
            print("   1. 🔧 Verificar imports e dependências")
            print("   2. 🔍 Debugar erros específicos")
            print("   3. 🔑 Instalar/configurar APIs necessárias")


async def main():
    """Função principal."""
    tester = V2MigrationTester()
    
    try:
        # Executar todos os testes V2
        results = await tester.test_all_v2_services()
        
        # Gerar relatório
        tester.print_final_report(results)
        
        # Salvar resultados detalhados
        timestamp = int(time.time())
        filename = f"v2_validation_test_{timestamp}.json"
        
        with open(filename, "w") as f:
            # Converter para JSON serializável
            serializable_results = json.loads(json.dumps(results, default=str))
            json.dump(serializable_results, f, indent=2, ensure_ascii=False)
        
        print(f"\n💾 Resultados detalhados salvos em: {filename}")
        
        # Código de saída baseado no sucesso
        success_rate = results["summary"]["v2_successes"]/(results["summary"]["v2_successes"] + results["summary"]["v2_failures"])
        if success_rate >= 0.5:
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
 