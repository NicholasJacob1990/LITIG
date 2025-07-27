#!/usr/bin/env python3
"""
Teste de Imports Corrigidos - Serviços V2
=========================================

Testa especificamente se os imports relativos foram corrigidos e se 
todos os serviços V2 podem ser importados e instanciados corretamente.
"""

import asyncio
import json
import sys
import time
from typing import Dict, Any
from datetime import datetime

# Adicionar paths
sys.path.append('.')
sys.path.append('services/')

print("🔧 Teste de Imports Corrigidos - Serviços V2")
print("=" * 50)

class ImportFixTester:
    """Testa se os imports relativos foram corrigidos."""
    
    def __init__(self):
        self.results = {
            "start_time": datetime.now().isoformat(),
            "tests": [],
            "summary": {"total": 0, "successes": 0, "failures": 0}
        }
    
    async def test_all_imports(self) -> Dict[str, Any]:
        """Executa todos os testes de import."""
        
        print("🔍 Testando imports dos serviços V2...\n")
        
        # Lista de serviços para testar
        services_to_test = [
            ("OpenRouter Client", "services.openrouter_client", "OpenRouterClient"),
            ("Function Tools", "services.function_tools", "LLMFunctionTools"),
            ("LEX-9000 V2", "services.lex9000_integration_service_v2", "LEX9000IntegrationServiceV2"),
            ("Lawyer Profile V2", "services.lawyer_profile_analysis_service_v2", "LawyerProfileAnalysisServiceV2"),
            ("Case Context V2", "services.case_context_analysis_service_v2", "CaseContextAnalysisServiceV2")
        ]
        
        for service_name, module_path, class_name in services_to_test:
            result = await self._test_single_import(service_name, module_path, class_name)
            self.results["tests"].append(result)
        
        # Teste de instanciação
        if all(test["import_success"] for test in self.results["tests"][-3:]):  # Últimos 3 são os serviços V2
            instantiation_result = await self._test_instantiation()
            self.results["tests"].append(instantiation_result)
        
        # Calcular estatísticas
        self.results["summary"]["total"] = len(self.results["tests"])
        self.results["summary"]["successes"] = sum(1 for t in self.results["tests"] if t.get("import_success", False) or t.get("instantiation_success", False))
        self.results["summary"]["failures"] = self.results["summary"]["total"] - self.results["summary"]["successes"]
        self.results["completion_time"] = datetime.now().isoformat()
        
        return self.results
    
    async def _test_single_import(self, service_name: str, module_path: str, class_name: str) -> Dict[str, Any]:
        """Testa import de um serviço específico."""
        
        print(f"📦 Testando {service_name}...")
        start_time = time.time()
        
        try:
            # Tentar importar o módulo
            module = __import__(module_path, fromlist=[class_name])
            
            # Tentar acessar a classe
            service_class = getattr(module, class_name)
            
            processing_time = time.time() - start_time
            print(f"   ✅ Importado com sucesso ({processing_time:.3f}s)")
            
            return {
                "service": service_name,
                "module_path": module_path,
                "class_name": class_name,
                "import_success": True,
                "processing_time": processing_time,
                "details": f"Classe {class_name} acessível"
            }
            
        except ImportError as e:
            processing_time = time.time() - start_time
            print(f"   ❌ Erro de import ({processing_time:.3f}s): {e}")
            
            return {
                "service": service_name,
                "module_path": module_path,
                "class_name": class_name,
                "import_success": False,
                "processing_time": processing_time,
                "error": str(e),
                "error_type": "ImportError"
            }
            
        except Exception as e:
            processing_time = time.time() - start_time
            print(f"   ❌ Erro inesperado ({processing_time:.3f}s): {e}")
            
            return {
                "service": service_name,
                "module_path": module_path,
                "class_name": class_name,
                "import_success": False,
                "processing_time": processing_time,
                "error": str(e),
                "error_type": type(e).__name__
            }
    
    async def _test_instantiation(self) -> Dict[str, Any]:
        """Testa instanciação dos serviços V2."""
        
        print("🏗️ Testando instanciação dos serviços V2...")
        start_time = time.time()
        
        try:
            # Importar as classes
            from services.lex9000_integration_service_v2 import LEX9000IntegrationServiceV2
            from services.lawyer_profile_analysis_service_v2 import LawyerProfileAnalysisServiceV2
            from services.case_context_analysis_service_v2 import CaseContextAnalysisServiceV2
            
            # Tentar instanciar (sem chamar métodos async)
            lex_service = LEX9000IntegrationServiceV2()
            profile_service = LawyerProfileAnalysisServiceV2()
            context_service = CaseContextAnalysisServiceV2()
            
            processing_time = time.time() - start_time
            print(f"   ✅ Todos os serviços instanciados com sucesso ({processing_time:.3f}s)")
            
            return {
                "service": "Instanciação Serviços V2",
                "instantiation_success": True,
                "processing_time": processing_time,
                "details": "LEX-9000, Lawyer Profile, Case Context V2 instanciados"
            }
            
        except Exception as e:
            processing_time = time.time() - start_time
            print(f"   ❌ Erro na instanciação ({processing_time:.3f}s): {e}")
            
            return {
                "service": "Instanciação Serviços V2",
                "instantiation_success": False,
                "processing_time": processing_time,
                "error": str(e),
                "error_type": type(e).__name__
            }
    
    def print_final_report(self, results: Dict[str, Any]):
        """Imprime relatório final."""
        
        print("\n" + "=" * 50)
        print("📊 RELATÓRIO DE IMPORTS CORRIGIDOS")
        print("=" * 50)
        
        summary = results["summary"]
        
        print(f"\n🎯 RESULTADOS GERAIS:")
        print(f"   📝 Total de testes: {summary['total']}")
        print(f"   ✅ Sucessos: {summary['successes']}")
        print(f"   ❌ Falhas: {summary['failures']}")
        
        if summary['total'] > 0:
            success_rate = summary['successes'] / summary['total']
            print(f"   📈 Taxa de sucesso: {success_rate:.1%}")
        else:
            success_rate = 0
        
        print(f"\n📋 DETALHES POR TESTE:")
        for test in results["tests"]:
            if test.get("import_success") or test.get("instantiation_success"):
                status = "✅"
                detail = test.get("details", "")
            else:
                status = "❌"
                detail = test.get("error", "Erro desconhecido")
            
            time_str = f"({test['processing_time']:.3f}s)"
            print(f"   {status} {test['service']}: {time_str}")
            if detail:
                print(f"      🔍 {detail}")
        
        print(f"\n🏆 AVALIAÇÃO DOS IMPORTS:")
        
        if success_rate >= 0.9:
            print("   🚀 IMPORTS 100% CORRIGIDOS!")
            print("   ✅ Todos os serviços V2 funcionando")
            print("   ✅ Imports relativos resolvidos")
            print("   ✅ Instanciação bem-sucedida")
            print("   ✅ Pronto para testes end-to-end")
        elif success_rate >= 0.8:
            print("   ✅ IMPORTS MAJORITARIAMENTE CORRIGIDOS")
            print("   ✅ Maioria dos serviços funcionando")
            print("   ⚠️ Pequenos ajustes restantes")
        elif success_rate >= 0.5:
            print("   ⚠️ IMPORTS PARCIALMENTE CORRIGIDOS")
            print("   ✅ Alguns serviços funcionando")
            print("   🔧 Ajustes necessários")
        else:
            print("   ❌ IMPORTS PRECISAM CORREÇÃO")
            print("   ❌ Problemas fundamentais persistem")
            print("   🔧 Revisão completa necessária")
        
        print(f"\n💡 PRÓXIMOS PASSOS:")
        if success_rate >= 0.9:
            print("   1. 🎉 Celebrar! Imports 100% funcionais")
            print("   2. 🧪 Executar testes end-to-end completos")
            print("   3. 🔑 Configurar chaves API para testes reais")
            print("   4. 🚀 Proceder para próxima fase")
        elif success_rate >= 0.8:
            print("   1. 🔧 Corrigir últimos problemas identificados")
            print("   2. 🔄 Re-executar teste")
            print("   3. 🎯 Buscar 100% de sucesso")
        else:
            print("   1. 🔍 Analisar erros específicos")
            print("   2. 🔧 Aplicar correções direcionadas")
            print("   3. 📦 Verificar estrutura de módulos")


async def main():
    """Função principal."""
    tester = ImportFixTester()
    
    try:
        # Executar todos os testes
        results = await tester.test_all_imports()
        
        # Gerar relatório
        tester.print_final_report(results)
        
        # Salvar resultados
        timestamp = int(time.time())
        filename = f"import_fix_test_{timestamp}.json"
        
        with open(filename, "w") as f:
            serializable_results = json.loads(json.dumps(results, default=str))
            json.dump(serializable_results, f, indent=2, ensure_ascii=False)
        
        print(f"\n💾 Resultados salvos em: {filename}")
        
        # Código de saída baseado no sucesso
        success_rate = results["summary"]["successes"] / max(results["summary"]["total"], 1)
        return 0 if success_rate >= 0.9 else 1
        
    except Exception as e:
        print(f"\n❌ Erro durante os testes: {str(e)}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code) 
 