#!/usr/bin/env python3
"""
Script de Verificação de Disponibilidade de Modelos - LITIG-1
=============================================================

Verifica se todos os IDs de modelo do plano de evolução estão disponíveis
e funcionando corretamente no OpenRouter.

Baseado em: PLANO_EVOLUCAO_COMPLETO_OPENROUTER_LANGGRAPH.md
"""

import asyncio
import json
import os
import sys
from typing import Dict, List, Tuple
import time

# Adicionar o diretório pai ao path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

try:
    import openai
    from config import Settings
except ImportError as e:
    print(f"❌ Erro de importação: {e}")
    print("Execute: pip3 install --break-system-packages openai python-dotenv")
    sys.exit(1)

class ModelAvailabilityChecker:
    """Verificador de disponibilidade de modelos conforme plano de evolução."""
    
    def __init__(self):
        self.settings = Settings()
        
        # IDs de modelos conforme PLANO_EVOLUCAO_COMPLETO (Julho 2025)
        self.models_to_check = {
            "gemini_25_pro": {
                "id": "google/gemini-2.5-pro",
                "service": "Lawyer Profile Analysis + Partnership Enhancement",
                "cost_input": 1.25,
                "cost_output": 10.0,
                "context": "1M tokens"
            },
            "claude_sonnet_4": {
                "id": "anthropic/claude-sonnet-4", 
                "service": "Case Context Analysis",
                "cost_input": 3.0,
                "cost_output": 15.0,
                "context": "200k tokens"
            },
            "grok_4": {
                "id": "x-ai/grok-4",
                "service": "LEX-9000 + Cluster Labeling", 
                "cost_input": 3.0,
                "cost_output": 15.0,
                "context": "256k tokens"
            },
            "gpt_41_mini": {
                "id": "openai/gpt-4.1-mini",
                "service": "OCR Validation",
                "cost_input": 0.40,
                "cost_output": 1.60,
                "context": "1M tokens"
            },
            "openrouter_auto": {
                "id": "openrouter/auto",
                "service": "Fallback Automático (Nível 2)",
                "cost_input": "variável",
                "cost_output": "variável"
            }
        }
        
        # Inicializar clientes
        self.openrouter_client = None
        self.direct_clients = {}
        self._init_clients()
    
    def _init_clients(self):
        """Inicializa clientes OpenRouter e diretos."""
        
        # Cliente OpenRouter
        if self.settings.OPENROUTER_API_KEY:
            self.openrouter_client = openai.AsyncOpenAI(
                base_url="https://openrouter.ai/api/v1",
                api_key=self.settings.OPENROUTER_API_KEY,
                default_headers={
                    "HTTP-Referer": "https://litig-1.com",
                    "X-Title": "LITIG-1"
                }
            )
            print("🌐 Cliente OpenRouter inicializado")
        else:
            print("⚠️ OPENROUTER_API_KEY não configurada")
        
        # Clientes diretos para fallback (Níveis 3-4)
        if self.settings.GEMINI_API_KEY:
            print("✅ GEMINI_API_KEY configurada")
            # Cliente direto seria inicializado aqui
        
        if self.settings.ANTHROPIC_API_KEY:
            print("✅ ANTHROPIC_API_KEY configurada")
        else:
            print("⚠️ ANTHROPIC_API_KEY não configurada")
        
        if self.settings.OPENAI_API_KEY:
            print("✅ OPENAI_API_KEY configurada")
        else:
            print("⚠️ OPENAI_API_KEY não configurada")
    
    async def check_model_availability(self, model_key: str, model_info: Dict) -> Dict:
        """Verifica se um modelo específico está disponível."""
        
        model_id = model_info["id"]
        start_time = time.time()
        
        result = {
            "model_key": model_key,
            "model_id": model_id,
            "service": model_info["service"],
            "available": False,
            "response_time_ms": 0,
            "error": None,
            "test_response": None
        }
        
        if not self.openrouter_client:
            result["error"] = "Cliente OpenRouter não inicializado"
            return result
        
        try:
            # Teste básico com prompt mínimo
            test_messages = [
                {
                    "role": "user", 
                    "content": "Responda apenas: OK"
                }
            ]
            
            # Headers especiais para Claude 4
            kwargs = {"max_tokens": 10}
            if "headers" in model_info:
                kwargs["extra_headers"] = model_info["headers"]
            
            response = await asyncio.wait_for(
                self.openrouter_client.chat.completions.create(
                    model=model_id,
                    messages=test_messages,
                    **kwargs
                ),
                timeout=30
            )
            
            response_time = int((time.time() - start_time) * 1000)
            
            result.update({
                "available": True,
                "response_time_ms": response_time,
                "test_response": response.choices[0].message.content[:50]
            })
            
            print(f"✅ {model_key} ({model_id}) - DISPONÍVEL ({response_time}ms)")
            
        except asyncio.TimeoutError:
            result["error"] = "Timeout (>30s)"
            print(f"⏱️ {model_key} ({model_id}) - TIMEOUT")
            
        except Exception as e:
            result["error"] = str(e)
            print(f"❌ {model_key} ({model_id}) - ERRO: {e}")
        
        return result
    
    async def test_function_calling(self, model_key: str, model_info: Dict) -> Dict:
        """Testa Function Calling em um modelo específico."""
        
        if not self.openrouter_client:
            return {"error": "Cliente não inicializado"}
        
        # Tool de teste simples
        test_tool = {
            "type": "function",
            "function": {
                "name": "extract_test_data",
                "description": "Extract simple test data",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "status": {
                            "type": "string",
                            "enum": ["success", "failure"],
                            "description": "Test status"
                        },
                        "confidence": {
                            "type": "number",
                            "minimum": 0,
                            "maximum": 1,
                            "description": "Confidence score"
                        }
                    },
                    "required": ["status", "confidence"]
                }
            }
        }
        
        result = {
            "model_key": model_key,
            "function_calling_supported": False,
            "error": None,
            "parsed_result": None
        }
        
        try:
            model_id = model_info["id"]
            
            # Headers especiais para Claude 4
            kwargs = {"max_tokens": 100}
            if "headers" in model_info:
                kwargs["extra_headers"] = model_info["headers"]
            
            response = await asyncio.wait_for(
                self.openrouter_client.chat.completions.create(
                    model=model_id,
                    messages=[{
                        "role": "user", 
                        "content": "Use the function to return status='success' and confidence=0.95"
                    }],
                    tools=[test_tool],
                    tool_choice={"type": "function", "function": {"name": "extract_test_data"}},
                    **kwargs
                ),
                timeout=30
            )
            
            # Verificar se retornou function call
            if response.choices[0].message.tool_calls:
                tool_call = response.choices[0].message.tool_calls[0]
                parsed_args = json.loads(tool_call.function.arguments)
                
                result.update({
                    "function_calling_supported": True,
                    "parsed_result": parsed_args
                })
                
                print(f"🛠️ {model_key} - Function Calling OK: {parsed_args}")
            else:
                result["error"] = "Não retornou function call"
                print(f"❌ {model_key} - Function Calling FALHOU")
                
        except Exception as e:
            result["error"] = str(e)
            print(f"❌ {model_key} - Function Calling ERRO: {e}")
        
        return result
    
    async def check_all_models(self) -> Dict:
        """Verifica todos os modelos do plano."""
        
        print("🔬 VERIFICAÇÃO DE MODELOS - PLANO DE EVOLUÇÃO LITIG-1")
        print("=" * 60)
        print("Verificando disponibilidade conforme PLANO_EVOLUCAO_COMPLETO_OPENROUTER_LANGGRAPH.md")
        print("")
        
        availability_results = []
        function_calling_results = []
        
        # Testar disponibilidade básica
        print("📡 TESTANDO DISPONIBILIDADE BÁSICA...")
        print("-" * 40)
        
        for model_key, model_info in self.models_to_check.items():
            result = await self.check_model_availability(model_key, model_info)
            availability_results.append(result)
            
            # Pequena pausa entre testes
            await asyncio.sleep(1)
        
        print("")
        
        # Testar Function Calling nos modelos disponíveis
        print("🛠️ TESTANDO FUNCTION CALLING...")
        print("-" * 40)
        
        available_models = [r for r in availability_results if r["available"]]
        
        for result in available_models:
            if result["model_key"] != "openrouter_auto":  # Auto não precisa de function calling
                model_info = self.models_to_check[result["model_key"]]
                fc_result = await self.test_function_calling(result["model_key"], model_info)
                function_calling_results.append(fc_result)
                
                await asyncio.sleep(1)
        
        return {
            "timestamp": time.time(),
            "availability_results": availability_results,
            "function_calling_results": function_calling_results,
            "summary": self._generate_summary(availability_results, function_calling_results)
        }
    
    def _generate_summary(self, availability_results: List, function_calling_results: List) -> Dict:
        """Gera resumo dos testes."""
        
        total_models = len(availability_results)
        available_models = len([r for r in availability_results if r["available"]])
        
        total_fc_tests = len(function_calling_results)
        working_fc = len([r for r in function_calling_results if r["function_calling_supported"]])
        
        # Calcular score de saúde
        availability_score = (available_models / total_models) * 100
        fc_score = (working_fc / total_fc_tests) * 100 if total_fc_tests > 0 else 0
        overall_score = (availability_score + fc_score) / 2
        
        return {
            "availability": {
                "total": total_models,
                "available": available_models,
                "percentage": availability_score
            },
            "function_calling": {
                "total": total_fc_tests,
                "working": working_fc,
                "percentage": fc_score
            },
            "overall_health_score": overall_score,
            "status": "excellent" if overall_score >= 90 else "good" if overall_score >= 70 else "needs_attention"
        }
    
    async def generate_report(self, results: Dict):
        """Gera relatório final formatado."""
        
        print("\n" + "=" * 60)
        print("📊 RELATÓRIO FINAL DE VERIFICAÇÃO")
        print("=" * 60)
        
        summary = results["summary"]
        
        print(f"\n🎯 SCORE GERAL DE SAÚDE: {summary['overall_health_score']:.1f}%")
        print(f"📶 Status: {summary['status'].upper()}")
        
        print(f"\n📡 DISPONIBILIDADE DE MODELOS:")
        print(f"   ✅ Disponíveis: {summary['availability']['available']}/{summary['availability']['total']}")
        print(f"   📊 Taxa: {summary['availability']['percentage']:.1f}%")
        
        print(f"\n🛠️ FUNCTION CALLING:")
        print(f"   ✅ Funcionando: {summary['function_calling']['working']}/{summary['function_calling']['total']}")
        print(f"   📊 Taxa: {summary['function_calling']['percentage']:.1f}%")
        
        print(f"\n📋 DETALHES POR MODELO:")
        for result in results["availability_results"]:
            status = "✅" if result["available"] else "❌"
            print(f"   {status} {result['model_key']} - {result['service']}")
            if result["error"]:
                print(f"      ⚠️ Erro: {result['error']}")
        
        print(f"\n🔧 RECOMENDAÇÕES:")
        
        if summary["overall_health_score"] >= 90:
            print("   🚀 Sistema pronto para migração!")
            print("   ✅ Todos os modelos funcionando conforme esperado")
        elif summary["overall_health_score"] >= 70:
            print("   ⚠️ Sistema funcional, mas com algumas limitações")
            print("   🔧 Verificar modelos com falha antes da migração")
        else:
            print("   🚨 Sistema requer atenção antes da migração")
            print("   ❌ Múltiplos modelos indisponíveis")
        
        # Verificar configurações específicas
        if not self.settings.OPENROUTER_API_KEY:
            print("   🔑 Configure OPENROUTER_API_KEY no .env")
        
        if not self.settings.ANTHROPIC_API_KEY:
            print("   🔑 Configure ANTHROPIC_API_KEY para fallback direto")
        
        if not self.settings.OPENAI_API_KEY:
            print("   🔑 Configure OPENAI_API_KEY para fallback direto")

async def main():
    """Função principal."""
    checker = ModelAvailabilityChecker()
    
    try:
        results = await checker.check_all_models()
        await checker.generate_report(results)
        
        # Salvar relatório em arquivo
        timestamp = int(time.time())
        report_file = f"model_availability_report_{timestamp}.json"
        
        with open(report_file, "w") as f:
            json.dump(results, f, indent=2)
        
        print(f"\n💾 Relatório salvo em: {report_file}")
        
        return 0 if results["summary"]["overall_health_score"] >= 70 else 1
        
    except Exception as e:
        print(f"\n❌ Erro durante verificação: {str(e)}")
        return 1

if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code) 
 