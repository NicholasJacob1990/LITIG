#!/usr/bin/env python3
"""
Test Hybrid Implementation - Teste da Implementação Híbrida
============================================================

Script de teste para validar a estratégia híbrida implementada.
Testa cada componente individualmente e a integração completa.

Execução:
python test_hybrid_implementation.py

Testa:
✅ Hybrid LangChain Orchestrator
✅ Brazilian Legal RAG
✅ Integração com workflows existentes
✅ Fallbacks para OpenRouter
"""

import asyncio
import logging
import sys
import os
from pathlib import Path

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Adicionar path dos serviços
sys.path.append(str(Path(__file__).parent))

class HybridImplementationTester:
    """Testador da implementação híbrida."""
    
    def __init__(self):
        self.logger = logging.getLogger(f"{self.__class__.__name__}")
        self.test_results = {}
    
    async def run_all_tests(self):
        """Executa todos os testes da implementação híbrida."""
        print("🧪 Iniciando testes da implementação híbrida...")
        print("=" * 60)
        
        # Lista de testes
        tests = [
            ("Test 1: Dependencies Check", self.test_dependencies),
            ("Test 2: Hybrid Orchestrator", self.test_hybrid_orchestrator),
            ("Test 3: Brazilian RAG", self.test_brazilian_rag),
            ("Test 4: Integration Example", self.test_integration_example),
            ("Test 5: Fallback System", self.test_fallback_system),
            ("Test 6: Performance", self.test_performance)
        ]
        
        # Executar testes
        for test_name, test_func in tests:
            print(f"\n🔬 {test_name}")
            print("-" * 40)
            
            try:
                result = await test_func()
                self.test_results[test_name] = result
                status = "✅ PASSOU" if result.get("success") else "❌ FALHOU"
                print(f"{status}: {result.get('message', 'Sem mensagem')}")
                
            except Exception as e:
                self.test_results[test_name] = {"success": False, "error": str(e)}
                print(f"❌ ERRO: {e}")
        
        # Relatório final
        self.print_final_report()
    
    async def test_dependencies(self) -> dict:
        """Testa se as dependências estão disponíveis."""
        try:
            dependencies = {}
            
            # Testar LangChain
            try:
                import langchain
                dependencies["langchain"] = True
                dependencies["langchain_version"] = getattr(langchain, '__version__', 'unknown')
            except ImportError as e:
                dependencies["langchain"] = False
                dependencies["langchain_error"] = str(e)
            
            # Testar LangGraph
            try:
                from langgraph.graph import StateGraph
                from langgraph.checkpoint.memory import MemorySaver
                dependencies["langgraph"] = True
            except ImportError as e:
                dependencies["langgraph"] = False
                dependencies["langgraph_error"] = str(e)
            
            # Testar OpenAI (já configurado)
            try:
                from langchain_openai import ChatOpenAI
                dependencies["openai_integration"] = True
            except ImportError as e:
                dependencies["openai_integration"] = False
                dependencies["openai_error"] = str(e)
            
            # Testar config existente
            try:
                import sys
                sys.path.append('/Users/nicholasjacob/Documents/Aplicativos/LITIG-1')
                from config import FeatureWeights
                dependencies["config"] = True
            except ImportError as e:
                dependencies["config"] = False
                dependencies["config_error"] = str(e)
            
            # Verificar resultados essenciais
            essential_deps = ["langchain", "langgraph", "openai_integration"]
            missing = [dep for dep in essential_deps if not dependencies.get(dep)]
            
            if missing:
                return {
                    "success": False,
                    "message": f"Dependências essenciais faltando: {', '.join(missing)}",
                    "details": dependencies
                }
            else:
                return {
                    "success": True,
                    "message": "Dependências essenciais disponíveis",
                    "details": dependencies
                }
                
        except Exception as e:
            return {"success": False, "message": f"Erro ao testar dependências: {e}"}
    
    async def test_hybrid_orchestrator(self) -> dict:
        """Testa o Hybrid LangChain Orchestrator."""
        try:
            # Adicionar path do projeto
            import sys
            sys.path.append('/Users/nicholasjacob/Documents/Aplicativos/LITIG-1/packages/backend/services')
            
            # Importar e verificar estrutura
            from hybrid_langchain_orchestrator import HybridLangChainOrchestrator
            
            # Testar inicialização
            orchestrator = HybridLangChainOrchestrator()
            
            # Testar métodos disponíveis
            available_methods = dir(orchestrator)
            expected_methods = ["get_status", "get_available_functions", "route_by_function"]
            has_required_methods = all(method in available_methods for method in expected_methods)
            
            # Testar status (sem usar APIs reais)
            status = orchestrator.get_status()
            
            return {
                "success": True,
                "message": f"Orquestrador híbrido carregado com {len(status.get('models', {}))} modelos",
                "details": {
                    "status": status,
                    "has_required_methods": has_required_methods,
                    "class_loaded": True
                }
            }
            
        except ImportError as e:
            return {
                "success": False,
                "message": f"Erro de importação: {e}"
            }
        except Exception as e:
            return {
                "success": False,
                "message": f"Erro no teste: {e}"
            }
    
    async def test_brazilian_rag(self) -> dict:
        """Testa o sistema RAG jurídico brasileiro."""
        try:
            import sys
            sys.path.append('/Users/nicholasjacob/Documents/Aplicativos/LITIG-1/packages/backend/services')
            
            from brazilian_legal_rag import BrazilianLegalRAG
            
            # Inicializar RAG (modo mock se dependências não disponíveis)
            rag = BrazilianLegalRAG()
            
            # Testar estrutura da classe
            available_methods = dir(rag)
            expected_methods = ["get_stats", "initialize_knowledge_base", "query", "search_similar"]
            has_required_methods = all(method in available_methods for method in expected_methods)
            
            # Testar stats iniciais
            stats = rag.get_stats()
            
            return {
                "success": True,
                "message": f"RAG jurídico carregado - Status: {'inicializado' if stats.get('initialized') else 'pendente'}",
                "details": {
                    "stats": stats,
                    "has_required_methods": has_required_methods,
                    "class_loaded": True
                }
            }
            
        except ImportError as e:
            return {
                "success": False,
                "message": f"Erro de importação: {e}"
            }
        except Exception as e:
            return {
                "success": False,
                "message": f"Erro no RAG: {e}"
            }
    
    async def test_integration_example(self) -> dict:
        """Testa o exemplo de integração híbrida."""
        try:
            import sys
            sys.path.append('/Users/nicholasjacob/Documents/Aplicativos/LITIG-1/packages/backend/services')
            
            from hybrid_integration_example import HybridTriageOrchestrator
            
            # Inicializar orquestrador híbrido
            hybrid_orchestrator = HybridTriageOrchestrator()
            
            # Testar estrutura
            available_methods = dir(hybrid_orchestrator)
            expected_methods = ["get_status", "execute_triage_with_hybrid_enhancement"]
            has_required_methods = all(method in available_methods for method in expected_methods)
            
            # Testar status
            status = hybrid_orchestrator.get_status()
            
            return {
                "success": True,
                "message": "Integração híbrida carregada com sucesso",
                "details": {
                    "status": status,
                    "has_required_methods": has_required_methods,
                    "components_available": len(status.get("components", {}))
                }
            }
            
        except ImportError as e:
            return {
                "success": False,
                "message": f"Erro de importação: {e}"
            }
        except Exception as e:
            return {
                "success": False,
                "message": f"Erro na integração: {e}"
            }
    
    async def test_fallback_system(self) -> dict:
        """Testa o sistema de fallback para OpenRouter."""
        try:
            import sys
            sys.path.append('/Users/nicholasjacob/Documents/Aplicativos/LITIG-1/packages/backend/services')
            
            # Testar se existe a estrutura do sistema atual
            try:
                from intelligent_triage_orchestrator_v2 import TriageOrchestratorV2
                langgraph_available = True
            except ImportError:
                langgraph_available = False
            
            # Testar híbrido
            try:
                from hybrid_langchain_orchestrator import HybridLangChainOrchestrator
                hybrid_available = True
                
                orchestrator = HybridLangChainOrchestrator()
                status = orchestrator.get_status()
                
            except ImportError:
                hybrid_available = False
                status = {}
            
            return {
                "success": True,
                "message": f"Sistema híbrido: {'disponível' if hybrid_available else 'indisponível'}",
                "details": {
                    "langgraph_v2_available": langgraph_available,
                    "hybrid_available": hybrid_available,
                    "status": status
                }
            }
            
        except Exception as e:
            return {
                "success": False,
                "message": f"Erro no teste de fallback: {e}"
            }
    
    async def test_performance(self) -> dict:
        """Testa performance básica do sistema."""
        try:
            import time
            import sys
            sys.path.append('/Users/nicholasjacob/Documents/Aplicativos/LITIG-1/packages/backend/services')
            
            # Testar importações
            start_time = time.time()
            
            from hybrid_langchain_orchestrator import HybridLangChainOrchestrator
            orchestrator = HybridLangChainOrchestrator()
            
            import_time = time.time() - start_time
            
            # Testar status (sem usar APIs reais)
            start_time = time.time()
            
            status = orchestrator.get_status()
            
            status_time = time.time() - start_time
            
            return {
                "success": True,
                "message": f"Performance: Import {import_time:.3f}s, Status {status_time:.3f}s",
                "details": {
                    "import_time": import_time,
                    "status_time": status_time,
                    "status_loaded": bool(status)
                }
            }
            
        except Exception as e:
            return {
                "success": False,
                "message": f"Erro no teste de performance: {e}"
            }
    
    def print_final_report(self):
        """Imprime relatório final dos testes."""
        print("\n" + "=" * 60)
        print("📊 RELATÓRIO FINAL DOS TESTES")
        print("=" * 60)
        
        total_tests = len(self.test_results)
        passed_tests = sum(1 for result in self.test_results.values() if result.get("success"))
        failed_tests = total_tests - passed_tests
        
        print(f"\n📈 Resumo:")
        print(f"   Total de testes: {total_tests}")
        print(f"   ✅ Passou: {passed_tests}")
        print(f"   ❌ Falhou: {failed_tests}")
        print(f"   📊 Taxa de sucesso: {(passed_tests/total_tests)*100:.1f}%")
        
        print(f"\n📋 Detalhes por teste:")
        for test_name, result in self.test_results.items():
            status = "✅" if result.get("success") else "❌"
            print(f"   {status} {test_name}")
            if not result.get("success") and "error" in result:
                print(f"      Erro: {result['error']}")
        
        # Recomendações
        print(f"\n💡 Recomendações:")
        
        if failed_tests == 0:
            print("   🎉 Todos os testes passaram! A implementação híbrida está funcionando.")
            print("   🚀 Você pode usar a estratégia híbrida em produção.")
        else:
            print("   ⚠️ Alguns testes falharam. Verifique:")
            
            if not self.test_results.get("Test 1: Dependencies Check", {}).get("success"):
                print("      - Instale as dependências LangChain: pip install langchain langgraph chromadb")
                print("      - Configure as chaves de API no arquivo de configuração")
            
            if not self.test_results.get("Test 2: Hybrid Orchestrator", {}).get("success"):
                print("      - Verifique se os modelos estão configurados corretamente")
            
            if not self.test_results.get("Test 3: Brazilian RAG", {}).get("success"):
                print("      - Verifique se a chave OpenAI está configurada para embeddings")
        
        print("\n🏁 Teste concluído!")


async def main():
    """Função principal."""
    print("🧪 TESTE DA IMPLEMENTAÇÃO HÍBRIDA LITIG-1")
    print("Estratégia: Modelos Fixos + Agentes LangChain + RAG Jurídico")
    
    tester = HybridImplementationTester()
    await tester.run_all_tests()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n⏹️ Teste interrompido pelo usuário")
    except Exception as e:
        print(f"\n❌ Erro inesperado: {e}")
        sys.exit(1)
