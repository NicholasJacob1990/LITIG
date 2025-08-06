#!/usr/bin/env python3
"""
Script de teste para verificar a configuração OpenRouter e conectividade.
Testa os 4 níveis de fallback conforme implementado no OpenRouterClient.

Executa testes para:
1. Configuração de credenciais
2. Conectividade OpenRouter (Níveis 1-2)  
3. Conectividade APIs diretas (Níveis 3-4)
4. Function calling com modelos atualizados
"""

import asyncio
import os
import sys
from typing import Dict, Any

# Adicionar o diretório atual ao path para importar módulos locais
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from services.openrouter_client import get_openrouter_client
from config import Settings


async def test_configuration() -> Dict[str, Any]:
    """Testa se as configurações estão corretas."""
    print("🔧 TESTANDO CONFIGURAÇÕES...")
    print("=" * 50)
    
    config_results = {
        "openrouter_api_key": bool(Settings.OPENROUTER_API_KEY and Settings.OPENROUTER_API_KEY != "your_openrouter_api_key_here"),
        "gemini_api_key": bool(Settings.GEMINI_API_KEY and Settings.GEMINI_API_KEY != "your_gemini_api_key"),
        "anthropic_api_key": bool(Settings.ANTHROPIC_API_KEY and Settings.ANTHROPIC_API_KEY != ""),
        "openai_api_key": bool(Settings.OPENAI_API_KEY and Settings.OPENAI_API_KEY != ""),
        "base_url": Settings.OPENROUTER_BASE_URL == "https://openrouter.ai/api/v1",
        "fallback_enabled": Settings.ENABLE_DIRECT_LLM_FALLBACK,
    }
    
    print(f"🔑 OpenRouter API Key: {'✅' if config_results['openrouter_api_key'] else '❌'}")
    print(f"🤖 Gemini API Key: {'✅' if config_results['gemini_api_key'] else '❌'}")
    print(f"🧠 Anthropic API Key: {'✅' if config_results['anthropic_api_key'] else '❌'}")
    print(f"🌟 OpenAI API Key: {'✅' if config_results['openai_api_key'] else '❌'}")
    print(f"🌐 Base URL: {'✅' if config_results['base_url'] else '❌'}")
    print(f"🔄 Fallback Direto: {'✅' if config_results['fallback_enabled'] else '❌'}")
    
    # Modelos configurados
    print(f"\n📋 MODELOS CONFIGURADOS:")
    print(f"  • Lawyer Profile: {Settings.OPENROUTER_LAWYER_PROFILE_MODEL}")
    print(f"  • Case Context: {Settings.OPENROUTER_CASE_CONTEXT_MODEL}")
    print(f"  • LEX-9000: {Settings.OPENROUTER_LEX9000_MODEL}")
    print(f"  • Cluster Labeling: {Settings.OPENROUTER_CLUSTER_LABELING_MODEL}")
    print(f"  • OCR: {Settings.OPENROUTER_OCR_MODEL}")
    print(f"  • Partnership: {Settings.OPENROUTER_PARTNERSHIP_MODEL}")
    
    return config_results


async def test_connectivity() -> Dict[str, Any]:
    """Testa conectividade com todos os níveis de fallback."""
    print("\n🌐 TESTANDO CONECTIVIDADE...")
    print("=" * 50)
    
    client = await get_openrouter_client()
    results = await client.test_connectivity()
    
    print(f"📡 OpenRouter Primário: {'✅' if results['openrouter_primary'] else '❌'}")
    print(f"🤖 OpenRouter Auto: {'✅' if results['openrouter_auto'] else '❌'}")
    print(f"💎 Gemini Direto: {'✅' if results['gemini_direct'] else '❌'}")
    print(f"🧠 Claude Direto: {'✅' if results['anthropic_direct'] else '❌'}")
    print(f"🌟 OpenAI Direto: {'✅' if results['openai_direct'] else '❌'}")
    print(f"🎯 Status Geral: {'✅' if results['overall_status'] else '❌'}")
    
    return results


async def test_function_calling() -> Dict[str, Any]:
    """Testa function calling com os novos modelos."""
    print("\n🛠️ TESTANDO FUNCTION CALLING...")
    print("=" * 50)
    
    client = await get_openrouter_client()
    
    # Tool de exemplo simples
    test_tool = {
        "type": "function",
        "function": {
            "name": "extract_case_info",
            "description": "Extract basic information from a legal case description",
            "parameters": {
                "type": "object",
                "properties": {
                    "area": {"type": "string", "description": "Legal area"},
                    "urgency": {"type": "string", "enum": ["low", "medium", "high"]},
                    "complexity": {"type": "string", "enum": ["simple", "medium", "complex"]},
                    "summary": {"type": "string", "description": "Brief summary"}
                },
                "required": ["area", "urgency", "complexity"]
            }
        }
    }
    
    test_messages = [{
        "role": "user", 
        "content": "Analise este caso: Cliente demitido sem justa causa, quer receber verbas rescisórias. Urgente."
    }]
    
    function_results = {}
    
    # Teste com Gemini 2.5 Pro (Lawyer Profile)
    try:
        print("🔄 Testando Gemini 2.5 Pro para análise de perfil...")
        result = await client.chat_completion_with_fallback(
            primary_model=Settings.OPENROUTER_LAWYER_PROFILE_MODEL,
            messages=test_messages,
            tools=[test_tool],
            tool_choice={"type": "function", "function": {"name": "extract_case_info"}},
            max_tokens=500
        )
        
        function_results["gemini_function_calling"] = {
            "success": True,
            "fallback_level": result["fallback_level"],
            "model_used": result["model_used"],
            "provider": result["provider"]
        }
        
        print(f"✅ Gemini Function Calling: Sucesso (Nível {result['fallback_level']})")
        print(f"   Modelo: {result['model_used']}")
        print(f"   Provider: {result['provider']}")
        
    except Exception as e:
        function_results["gemini_function_calling"] = {
            "success": False,
            "error": str(e)
        }
        print(f"❌ Gemini Function Calling: {str(e)}")
    
    # Teste com Grok 4 (LEX-9000) 
    try:
        print("🔄 Testando Grok 4 para análise LEX-9000...")
        result = await client.chat_completion_with_fallback(
            primary_model=Settings.OPENROUTER_LEX9000_MODEL,
            messages=test_messages,
            tools=[test_tool],
            tool_choice={"type": "function", "function": {"name": "extract_case_info"}},
            max_tokens=500
        )
        
        function_results["grok_function_calling"] = {
            "success": True,
            "fallback_level": result["fallback_level"],
            "model_used": result["model_used"],
            "provider": result["provider"]
        }
        
        print(f"✅ Grok Function Calling: Sucesso (Nível {result['fallback_level']})")
        print(f"   Modelo: {result['model_used']}")
        print(f"   Provider: {result['provider']}")
        
    except Exception as e:
        function_results["grok_function_calling"] = {
            "success": False,
            "error": str(e)
        }
        print(f"❌ Grok Function Calling: {str(e)}")
    
    # Teste com Claude Sonnet 4 (Case Context)
    try:
        print("🔄 Testando Claude Sonnet 4 para contexto de caso...")
        result = await client.chat_completion_with_fallback(
            primary_model=Settings.OPENROUTER_CASE_CONTEXT_MODEL,
            messages=test_messages,
            tools=[test_tool],
            tool_choice={"type": "function", "function": {"name": "extract_case_info"}},
            max_tokens=500
        )
        
        function_results["claude_function_calling"] = {
            "success": True,
            "fallback_level": result["fallback_level"],
            "model_used": result["model_used"],
            "provider": result["provider"]
        }
        
        print(f"✅ Claude Function Calling: Sucesso (Nível {result['fallback_level']})")
        print(f"   Modelo: {result['model_used']}")
        print(f"   Provider: {result['provider']}")
        
    except Exception as e:
        function_results["claude_function_calling"] = {
            "success": False,
            "error": str(e)
        }
        print(f"❌ Claude Function Calling: {str(e)}")
    
    return function_results


async def test_fallback_levels() -> Dict[str, Any]:
    """Testa especificamente os níveis de fallback."""
    print("\n🔄 TESTANDO NÍVEIS DE FALLBACK...")
    print("=" * 50)
    
    client = await get_openrouter_client()
    
    # Forçar teste de diferentes níveis usando um modelo inexistente
    test_messages = [{"role": "user", "content": "Teste simples: responda OK"}]
    
    fallback_results = {}
    
    # Teste com modelo válido (deve usar Nível 1)
    try:
        print("🔄 Testando Nível 1 (modelo válido)...")
        result = await client.chat_completion_with_fallback(
            primary_model="gemini-2.5-flash",
            messages=test_messages,
            max_tokens=10
        )
        
        fallback_results["level_1"] = {
            "success": True,
            "fallback_level": result["fallback_level"],
            "model_used": result["model_used"],
            "provider": result["provider"]
        }
        
        print(f"✅ Nível {result['fallback_level']}: {result['model_used']} via {result['provider']}")
        
    except Exception as e:
        fallback_results["level_1"] = {"success": False, "error": str(e)}
        print(f"❌ Nível 1: {str(e)}")
    
    # Temporariamente desabilitar OpenRouter para testar fallback direto
    original_key = client.openrouter_client
    client.openrouter_available = False
    
    try:
        print("🔄 Testando Níveis 3-4 (OpenRouter desabilitado)...")
        result = await client.chat_completion_with_fallback(
            primary_model="any-model",  # Será ignorado nos níveis 3-4
            messages=test_messages,
            max_tokens=10
        )
        
        fallback_results["level_3_4"] = {
            "success": True,
            "fallback_level": result["fallback_level"],
            "model_used": result["model_used"],
            "provider": result["provider"]
        }
        
        print(f"✅ Nível {result['fallback_level']}: {result['model_used']} via {result['provider']}")
        
    except Exception as e:
        fallback_results["level_3_4"] = {"success": False, "error": str(e)}
        print(f"❌ Níveis 3-4: {str(e)}")
    
    finally:
        # Restaurar OpenRouter
        client.openrouter_client = original_key
        client.openrouter_available = bool(original_key)
    
    return fallback_results


async def generate_report(config_results, connectivity_results, function_results, fallback_results):
    """Gera relatório final da configuração."""
    print("\n📊 RELATÓRIO FINAL")
    print("=" * 50)
    
    # Calcular scores
    config_score = sum(config_results.values()) / len(config_results) * 100
    connectivity_score = (
        connectivity_results["openrouter_primary"] * 0.4 +
        connectivity_results["openrouter_auto"] * 0.3 +
        connectivity_results["gemini_direct"] * 0.1 +
        connectivity_results["anthropic_direct"] * 0.1 +
        connectivity_results["openai_direct"] * 0.1
    ) * 100
    
    function_success = sum(1 for r in function_results.values() if r.get("success", False))
    function_score = (function_success / len(function_results)) * 100 if function_results else 0
    
    fallback_success = sum(1 for r in fallback_results.values() if r.get("success", False))
    fallback_score = (fallback_success / len(fallback_results)) * 100 if fallback_results else 0
    
    overall_score = (config_score * 0.3 + connectivity_score * 0.4 + function_score * 0.2 + fallback_score * 0.1)
    
    print(f"📋 Configuração: {config_score:.1f}%")
    print(f"🌐 Conectividade: {connectivity_score:.1f}%")
    print(f"🛠️ Function Calling: {function_score:.1f}%")
    print(f"🔄 Fallback: {fallback_score:.1f}%")
    print(f"🎯 Score Geral: {overall_score:.1f}%")
    
    # Status
    if overall_score >= 80:
        status = "🎉 EXCELENTE - Pronto para produção!"
    elif overall_score >= 60:
        status = "✅ BOM - Funcional com algumas limitações"
    elif overall_score >= 40:
        status = "⚠️ REGULAR - Necessita ajustes"
    else:
        status = "❌ CRÍTICO - Configuração incompleta"
    
    print(f"\n{status}")
    
    # Recomendações
    print(f"\n💡 RECOMENDAÇÕES:")
    
    if not config_results.get("openrouter_api_key", False):
        print("  • Configurar OPENROUTER_API_KEY no .env")
    
    if not connectivity_results.get("openrouter_primary", False):
        print("  • Verificar chave OpenRouter e conectividade")
    
    if function_score < 100:
        print("  • Alguns modelos podem não suportar function calling")
    
    if fallback_score < 100:
        print("  • Configurar chaves de API para fallbacks (Gemini, Claude, OpenAI)")
    
    print(f"\n🚀 A migração OpenRouter está {'PRONTA' if overall_score >= 70 else 'EM PROGRESSO'}!")


async def main():
    """Função principal do teste."""
    print("🔬 TESTE DE CONFIGURAÇÃO OPENROUTER + LANGCHAIN")
    print("=" * 60)
    print("Este script verifica a configuração dos 4 níveis de fallback")
    print("conforme documentado no PLANO_EVOLUCAO_COMPLETO_OPENROUTER_LANGGRAPH.md")
    print("")
    
    try:
        # Executar todos os testes
        config_results = await test_configuration()
        connectivity_results = await test_connectivity()
        function_results = await test_function_calling()
        fallback_results = await test_fallback_levels()
        
        # Gerar relatório final
        await generate_report(config_results, connectivity_results, function_results, fallback_results)
        
    except Exception as e:
        print(f"❌ Erro durante os testes: {str(e)}")
        return 1
    
    return 0


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code) 
 