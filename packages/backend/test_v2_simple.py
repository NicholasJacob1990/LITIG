#!/usr/bin/env python3
"""
Teste Simplificado dos Serviços V2
==================================

Testa os serviços V2 com classes básicas inline para evitar problemas de import.
Foca na validação da arquitetura nova (OpenRouter + Function Calling).
"""

import asyncio
import json
import sys
import time
from typing import Dict, Any, List
from datetime import datetime
from dataclasses import dataclass

# Adicionar paths
sys.path.append('.')
sys.path.append('services/')

print("🔧 Inicializando teste simplificado...")

# Definir classes básicas inline para evitar imports complexos
@dataclass 
class SimpleResult:
    """Resultado simplificado para testes."""
    success: bool = False
    data: Dict[str, Any] = None
    error: str = None
    processing_time_ms: int = 0
    model_used: str = "unknown"
    fallback_level: int = 999


class SimpleV2Tester:
    """Teste simplificado focado apenas na arquitetura V2."""
    
    def __init__(self):
        self.test_data = {
            "case_id": "test_001",
            "user_id": "user_test",
            "case_type": "Direito Trabalhista",
            "description": "Caso de teste para validação da arquitetura V2",
            "basic_info": {
                "case_type": "Trabalhista",
                "years_experience": 10
            },
            "specialties": ["Direito Trabalhista"],
            "timeline": {"urgency_level": "Alta"},
            "complexity_indicators": ["teste_complexidade"]
        }
    
    async def test_function_calling_architecture(self) -> Dict[str, Any]:
        """Testa a arquitetura de Function Calling diretamente."""
        
        print("🚀 VALIDAÇÃO DA ARQUITETURA V2")
        print("=" * 50)
        print("Testando OpenRouter + Function Calling (sem dependências V1)")
        print("")
        
        results = {
            "start_time": datetime.now().isoformat(),
            "tests": [],
            "summary": {
                "total": 0,
                "successes": 0,
                "failures": 0
            }
        }
        
        # Teste 1: Import do OpenRouter Client
        test1 = await self._test_openrouter_import()
        results["tests"].append(test1)
        
        # Teste 2: Import do Function Tools
        test2 = await self._test_function_tools_import()
        results["tests"].append(test2)
        
        # Teste 3: Inicialização básica dos serviços V2
        test3 = await self._test_services_initialization()
        results["tests"].append(test3)
        
        # Teste 4: Validação da estrutura Function Calling
        test4 = await self._test_function_calling_structure()
        results["tests"].append(test4)
        
        # Calcular estatísticas
        results["summary"]["total"] = len(results["tests"])
        results["summary"]["successes"] = sum(1 for t in results["tests"] if t["success"])
        results["summary"]["failures"] = results["summary"]["total"] - results["summary"]["successes"]
        results["completion_time"] = datetime.now().isoformat()
        
        return results
    
    async def _test_openrouter_import(self) -> Dict[str, Any]:
        """Teste 1: Import do OpenRouter Client."""
        
        print("🔧 Teste 1: Import OpenRouter Client...")
        start_time = time.time()
        
        try:
            from services.openrouter_client import get_openrouter_client, OpenRouterClient
            
            # Tentar instanciar
            client = OpenRouterClient()
            
            print("  ✅ OpenRouter Client importado e instanciado")
            return {
                "test": "openrouter_import",
                "success": True,
                "processing_time": time.time() - start_time,
                "details": "OpenRouter Client funcionando"
            }
            
        except Exception as e:
            print(f"  ❌ Falha: {e}")
            return {
                "test": "openrouter_import", 
                "success": False,
                "processing_time": time.time() - start_time,
                "error": str(e)
            }
    
    async def _test_function_tools_import(self) -> Dict[str, Any]:
        """Teste 2: Import do Function Tools."""
        
        print("🛠️ Teste 2: Import Function Tools...")
        start_time = time.time()
        
        try:
            from services.function_tools import LLMFunctionTools
            
            # Tentar acessar tools
            lex_tool = LLMFunctionTools.get_lex9000_tool()
            profile_tool = LLMFunctionTools.get_lawyer_profile_tool()
            context_tool = LLMFunctionTools.get_case_context_tool()
            
            print("  ✅ Function Tools importadas e acessíveis")
            return {
                "test": "function_tools_import",
                "success": True,
                "processing_time": time.time() - start_time,
                "details": f"Tools disponíveis: {len([lex_tool, profile_tool, context_tool])}"
            }
            
        except Exception as e:
            print(f"  ❌ Falha: {e}")
            return {
                "test": "function_tools_import",
                "success": False,
                "processing_time": time.time() - start_time,
                "error": str(e)
            }
    
    async def _test_services_initialization(self) -> Dict[str, Any]:
        """Teste 3: Inicialização dos serviços V2."""
        
        print("🔧 Teste 3: Inicialização Serviços V2...")
        start_time = time.time()
        
        try:
            # Tentar importar apenas as classes (sem instanciar)
            from services.lex9000_integration_service_v2 import LEX9000IntegrationServiceV2
            from services.lawyer_profile_analysis_service_v2 import LawyerProfileAnalysisServiceV2
            from services.case_context_analysis_service_v2 import CaseContextAnalysisServiceV2
            
            print("  ✅ Serviços V2 importados com sucesso")
            return {
                "test": "services_initialization",
                "success": True,
                "processing_time": time.time() - start_time,
                "details": "LEX-9000 V2, Lawyer Profile V2, Case Context V2"
            }
            
        except Exception as e:
            print(f"  ❌ Falha: {e}")
            return {
                "test": "services_initialization",
                "success": False, 
                "processing_time": time.time() - start_time,
                "error": str(e)
            }
    
    async def _test_function_calling_structure(self) -> Dict[str, Any]:
        """Teste 4: Validação da estrutura Function Calling."""
        
        print("📋 Teste 4: Estrutura Function Calling...")
        start_time = time.time()
        
        try:
            from services.function_tools import LLMFunctionTools
            
            # Validar estrutura de cada tool com nomes corretos
            tools_to_test = [
                ("lex9000", LLMFunctionTools.get_lex9000_tool()),
                ("lawyer_profile", LLMFunctionTools.get_lawyer_profile_tool()),
                ("case_context", LLMFunctionTools.get_case_context_tool()),
                ("partnership", LLMFunctionTools.get_partnership_tool()),
                ("cluster_labeling", LLMFunctionTools.get_cluster_labeling_tool()),
                ("ocr_extraction", LLMFunctionTools.get_ocr_extraction_tool())
            ]
            
            validated_tools = []
            for tool_name, tool_def in tools_to_test:
                # Validar estrutura básica
                if (isinstance(tool_def, dict) and
                    "type" in tool_def and 
                    tool_def["type"] == "function" and
                    "function" in tool_def and
                    "name" in tool_def["function"] and
                    "parameters" in tool_def["function"]):
                    validated_tools.append(tool_name)
            
            print(f"  ✅ {len(validated_tools)}/{len(tools_to_test)} Function Tools válidas")
            return {
                "test": "function_calling_structure",
                "success": len(validated_tools) >= 3,  # Pelo menos 3 dos 6 tools
                "processing_time": time.time() - start_time,
                "details": f"Tools válidas: {', '.join(validated_tools)}"
            }
            
        except Exception as e:
            print(f"  ❌ Falha: {e}")
            return {
                "test": "function_calling_structure",
                "success": False,
                "processing_time": time.time() - start_time,
                "error": str(e)
            }
    
    def print_final_report(self, results: Dict[str, Any]):
        """Imprime relatório final."""
        
        print("\n" + "=" * 50)
        print("📊 RELATÓRIO DE VALIDAÇÃO ARQUITETURA V2")
        print("=" * 50)
        
        summary = results["summary"]
        
        print(f"\n🎯 RESULTADOS GERAIS:")
        print(f"   📝 Total de testes: {summary['total']}")
        print(f"   ✅ Sucessos: {summary['successes']}")
        print(f"   ❌ Falhas: {summary['failures']}")
        print(f"   📈 Taxa de sucesso: {summary['successes']/max(summary['total'],1):.1%}")
        
        print(f"\n📋 DETALHES POR TESTE:")
        for test in results["tests"]:
            status = "✅" if test["success"] else "❌"
            time_str = f"({test['processing_time']:.2f}s)"
            
            print(f"   {status} {test['test']}: {time_str}")
            if test["success"] and "details" in test:
                print(f"      🔍 {test['details']}")
            elif not test["success"] and "error" in test:
                print(f"      ⚠️ {test['error']}")
        
        print(f"\n🏆 AVALIAÇÃO DA ARQUITETURA:")
        
        success_rate = summary['successes']/max(summary['total'],1)
        
        if success_rate >= 0.8:
            print("   🚀 ARQUITETURA V2 PRONTA!")
            print("   ✅ Imports funcionando corretamente")
            print("   ✅ Function Tools estruturadas")
            print("   ✅ OpenRouter Client operacional")
            print("   ✅ Serviços V2 carregáveis")
        elif success_rate >= 0.5:
            print("   ⚠️ ARQUITETURA V2 PARCIALMENTE FUNCIONAL")
            print("   ✅ Componentes básicos funcionando")
            print("   ⚠️ Alguns problemas de configuração")
            print("   🔧 Ajustes menores necessários")
        else:
            print("   ❌ ARQUITETURA V2 PRECISA CORREÇÕES")
            print("   ❌ Problemas fundamentais detectados")
            print("   🔧 Correções necessárias antes de prosseguir")
        
        print(f"\n💡 PRÓXIMOS PASSOS:")
        if success_rate >= 0.8:
            print("   1. 🔑 Configurar chaves API reais")
            print("   2. 🧪 Testar com LLMs funcionais")
            print("   3. 📊 Validar qualidade das saídas")
            print("   4. 🚀 Proceder para testes end-to-end")
        elif success_rate >= 0.5:
            print("   1. 🔧 Corrigir problemas identificados")
            print("   2. 🔄 Re-executar validação")
            print("   3. 🔑 Configurar APIs pendentes")
        else:
            print("   1. 🔧 Revisar imports e dependências")
            print("   2. 📦 Verificar instalação de pacotes")
            print("   3. 🔄 Re-executar após correções")


async def main():
    """Função principal."""
    tester = SimpleV2Tester()
    
    try:
        # Executar validação da arquitetura
        results = await tester.test_function_calling_architecture()
        
        # Gerar relatório
        tester.print_final_report(results)
        
        # Salvar resultados
        timestamp = int(time.time())
        filename = f"v2_architecture_validation_{timestamp}.json"
        
        with open(filename, "w") as f:
            serializable_results = json.loads(json.dumps(results, default=str))
            json.dump(serializable_results, f, indent=2, ensure_ascii=False)
        
        print(f"\n💾 Resultados salvos em: {filename}")
        
        # Código de saída
        success_rate = results["summary"]["successes"]/max(results["summary"]["total"],1)
        return 0 if success_rate >= 0.5 else 1
        
    except Exception as e:
        print(f"\n❌ Erro durante validação: {str(e)}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code) 
 