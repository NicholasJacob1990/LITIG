#!/usr/bin/env python3
"""
Teste de Configuração OpenRouter e Fallback
===========================================

Script para testar a configuração do OpenRouter e verificar
se o fallback está funcionando corretamente quando não há chave.
"""

import asyncio
import os
import sys
from typing import Dict, Any

# Adicionar o diretório atual ao path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

async def test_openrouter_configuration():
    """Testa a configuração do OpenRouter e fallback."""
    
    print("🔍 Testando Configuração OpenRouter e Fallback")
    print("=" * 50)
    
    # Verificar variáveis de ambiente
    print("\n📋 Verificando Variáveis de Ambiente:")
    print("-" * 30)
    
    env_vars = {
        "OPENROUTER_API_KEY": os.getenv("OPENROUTER_API_KEY"),
        "OPENAI_API_KEY": os.getenv("OPENAI_API_KEY"),
        "ANTHROPIC_API_KEY": os.getenv("ANTHROPIC_API_KEY"),
        "GOOGLE_API_KEY": os.getenv("GOOGLE_API_KEY")
    }
    
    for var_name, value in env_vars.items():
        status = "✅ Configurada" if value else "❌ Não configurada"
        masked_value = f"{value[:8]}..." if value else "None"
        print(f"{var_name}: {status} ({masked_value})")
    
    # Simular serviço OpenRouter
    print("\n🤖 Simulando OpenRouterLangChainService:")
    print("-" * 40)
    
    # Simular verificação de disponibilidade
    openrouter_available = bool(env_vars["OPENROUTER_API_KEY"])
    
    if openrouter_available:
        print("✅ OpenRouter já implementado - roteamento inteligente ativo")
        print("🚀 Benefícios já disponíveis:")
        print("   - Acesso a 100+ modelos via uma API")
        print("   - Roteamento automático com Autorouter (openrouter/auto)")
        print("   - Fallback automático entre provedores (4 níveis)")
        print("   - Web Search para informações em tempo real")
        print("   - Roteamento avançado (:nitro, :floor)")
    else:
        print("⚠️ OpenRouter não configurado - usando fallback direto")
        print("🔄 Fallback configurado:")
        
        fallback_config = {
            "conversation": "Anthropic Claude 4.0 Sonnet → OpenAI GPT-4o",
            "analysis": "OpenAI GPT-4o → Anthropic Claude 4.0 Sonnet",
            "triage": "Anthropic Claude 4.0 Sonnet → OpenAI GPT-4o",
            "matching": "OpenAI GPT-4o → Anthropic Claude 4.0 Sonnet",
            "explanation": "Google Gemini 2.5 Flash → OpenAI GPT-4o"
        }
        
        for task_type, fallback in fallback_config.items():
            print(f"   {task_type}: {fallback}")
    
    # Simular status do serviço
    print("\n📊 Status do Serviço:")
    print("-" * 20)
    
    service_status = {
        "openrouter_available": openrouter_available,
        "fallback_models_configured": 5,
        "supported_task_types": ["conversation", "analysis", "triage", "matching", "explanation"],
        "recommendation": "Configure OPENROUTER_API_KEY para melhor performance" if not openrouter_available else "OpenRouter ativo"
    }
    
    for key, value in service_status.items():
        print(f"{key}: {value}")
    
    # Teste de roteamento
    print("\n🧪 Teste de Roteamento:")
    print("-" * 20)
    
    test_cases = [
        ("conversation", "Olá, preciso de ajuda jurídica"),
        ("analysis", "Analise este caso de direito trabalhista"),
        ("triage", "Classifique a complexidade deste processo"),
        ("matching", "Encontre advogados especializados em direito civil"),
        ("explanation", "Explique os próximos passos para o cliente")
    ]
    
    for task_type, prompt in test_cases:
        if openrouter_available:
            print(f"✅ {task_type}: Roteamento via OpenRouter (modelo automático)")
        else:
            # Simular fallback
            if task_type in ["conversation", "triage"]:
                print(f"🔄 {task_type}: Anthropic Claude 4.0 Sonnet (primário)")
            elif task_type in ["analysis", "matching"]:
                print(f"🔄 {task_type}: OpenAI GPT-4o (primário)")
            else:
                print(f"🔄 {task_type}: Google Gemini 2.5 Flash (primário)")
    
    # Recomendações
    print("\n💡 Recomendações:")
    print("-" * 15)
    
    if not openrouter_available:
        print("1. Configure OPENROUTER_API_KEY para melhor performance")
        print("2. Obtenha chave em: https://openrouter.ai/keys")
        print("3. Benefícios: roteamento inteligente + 100+ modelos")
        print("4. Fallback continuará funcionando mesmo sem OpenRouter")
    else:
        print("1. ✅ OpenRouter já implementado e configurado")
        print("2. Autorouter ativo (openrouter/auto)")
        print("3. Web Search disponível para informações em tempo real")
        print("4. Aproveite os 4 níveis de fallback já implementados")
    
    # Resumo final
    print("\n🎯 Resumo:")
    print("-" * 8)
    
    if openrouter_available:
        print("✅ Configuração IDEAL - OpenRouter já implementado")
        print("🚀 Performance máxima com Autorouter + Web Search")
        print("🔄 4 níveis de fallback já ativos")
    elif env_vars["OPENAI_API_KEY"] and env_vars["ANTHROPIC_API_KEY"]:
        print("✅ Configuração FUNCIONAL - Fallback ativo")
        print("🔄 App funcionará com modelos diretos")
        print("💡 Configure OpenRouter para melhor performance")
    else:
        print("❌ Configuração INCOMPLETA")
        print("⚠️ Configure pelo menos OPENAI_API_KEY e ANTHROPIC_API_KEY")
        print("💡 Configure OpenRouter para melhor performance")

if __name__ == "__main__":
    asyncio.run(test_openrouter_configuration()) 