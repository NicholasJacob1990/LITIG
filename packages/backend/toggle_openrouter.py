#!/usr/bin/env python3
"""
Script para ativar/desativar OpenRouter no LITIG-1
Implementa a estratégia de feature flag conforme análise de viabilidade.

Uso:
    python3 toggle_openrouter.py --enable   # Ativa OpenRouter
    python3 toggle_openrouter.py --disable  # Desativa OpenRouter (usa apenas APIs diretas)
    python3 toggle_openrouter.py --status   # Mostra status atual
"""

import os
import sys
import argparse
import asyncio
from pathlib import Path

# Adicionar o diretório atual ao path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from config import Settings
from services.openrouter_client import get_openrouter_client


def update_env_file(enable_openrouter: bool):
    """Atualiza .env com a configuração USE_OPENROUTER."""
    env_file = Path(".env")
    
    if not env_file.exists():
        print("❌ Arquivo .env não encontrado. Criando...")
        with open(env_file, "w") as f:
            f.write(f"USE_OPENROUTER={'true' if enable_openrouter else 'false'}\n")
        return
    
    # Ler arquivo existente
    with open(env_file, "r") as f:
        lines = f.readlines()
    
    # Procurar e atualizar linha USE_OPENROUTER
    found = False
    for i, line in enumerate(lines):
        if line.startswith("USE_OPENROUTER="):
            lines[i] = f"USE_OPENROUTER={'true' if enable_openrouter else 'false'}\n"
            found = True
            break
    
    # Se não encontrou, adicionar no final
    if not found:
        lines.append(f"USE_OPENROUTER={'true' if enable_openrouter else 'false'}\n")
    
    # Escrever arquivo atualizado
    with open(env_file, "w") as f:
        f.writelines(lines)


async def test_current_config():
    """Testa a configuração atual e mostra qual nível de fallback está ativo."""
    print("🔍 TESTANDO CONFIGURAÇÃO ATUAL...")
    print("=" * 50)
    
    try:
        client = await get_openrouter_client()
        
        # Teste simples
        test_messages = [{"role": "user", "content": "Responda apenas: OK"}]
        
        result = await client.chat_completion_with_fallback(
            primary_model="google/gemini-1.5-pro",
            messages=test_messages,
            max_tokens=10
        )
        
        print(f"✅ Teste bem-sucedido!")
        print(f"   🤖 Modelo usado: {result['model_used']}")
        print(f"   🔄 Nível de fallback: {result['fallback_level']}")
        print(f"   🌐 Provider: {result['provider']}")
        print(f"   ⏱️ Tempo: {result['processing_time_ms']}ms")
        
        # Interpretar resultado
        if result['fallback_level'] <= 2:
            print(f"\n🌐 OpenRouter ATIVO - usando níveis 1-2")
        else:
            print(f"\n🔒 APIs DIRETAS - usando níveis 3-4")
            
    except Exception as e:
        print(f"❌ Erro no teste: {str(e)}")


def show_status():
    """Mostra o status atual da configuração."""
    print("📊 STATUS ATUAL DO OPENROUTER")
    print("=" * 50)
    
    print(f"🔧 USE_OPENROUTER: {Settings.USE_OPENROUTER}")
    print(f"🔑 OPENROUTER_API_KEY: {'✅ Configurada' if Settings.OPENROUTER_API_KEY else '❌ Não configurada'}")
    print(f"🤖 GEMINI_API_KEY: {'✅ Configurada' if Settings.GEMINI_API_KEY else '❌ Não configurada'}")
    print(f"🧠 ANTHROPIC_API_KEY: {'✅ Configurada' if Settings.ANTHROPIC_API_KEY else '❌ Não configurada'}")
    print(f"🌟 OPENAI_API_KEY: {'✅ Configurada' if Settings.OPENAI_API_KEY else '❌ Não configurada'}")
    
    print(f"\n📋 CONFIGURAÇÃO ATUAL:")
    if Settings.USE_OPENROUTER and Settings.OPENROUTER_API_KEY:
        print("🌐 OpenRouter ATIVADO - usando níveis 1-2 + fallback 3-4")
    elif Settings.USE_OPENROUTER and not Settings.OPENROUTER_API_KEY:
        print("⚠️ OpenRouter HABILITADO mas sem chave - usando apenas níveis 3-4")
    else:
        print("🔒 OpenRouter DESABILITADO - usando apenas APIs diretas (níveis 3-4)")
    
    print(f"\n🛡️ BENEFÍCIOS DA CONFIGURAÇÃO ATUAL:")
    if Settings.USE_OPENROUTER:
        print("  • ✅ Acesso a 200+ modelos via OpenRouter")
        print("  • ✅ Roteamento automático com openrouter/auto")
        print("  • ⚠️ Taxa adicional de 5% nos custos")
        print("  • ⚠️ Dados podem ser usados para treinamento (free tier)")
    else:
        print("  • ✅ Economia de 5% nos custos")
        print("  • ✅ Controle total sobre privacidade/LGPD")
        print("  • ✅ Latência direta (sem proxy)")
        print("  • ❌ Sem roteamento automático")


def enable_openrouter():
    """Ativa o OpenRouter."""
    print("🌐 ATIVANDO OPENROUTER...")
    print("=" * 40)
    
    update_env_file(True)
    
    print("✅ OpenRouter ativado!")
    print("\n🔄 Para aplicar as mudanças:")
    print("   1. Reinicie o servidor Python")
    print("   2. Ou use: source .env && python3 seu_script.py")
    print("\n📋 Comportamento esperado:")
    print("   • Nível 1-2: OpenRouter (primário + auto)")
    print("   • Nível 3-4: APIs diretas (fallback)")
    print("\n⚠️ IMPORTANTE:")
    print("   • Configure OPENROUTER_API_KEY no .env")
    print("   • Dados podem ser usados para treinamento (free tier)")
    print("   • Taxa adicional de 5% nos custos")


def disable_openrouter():
    """Desativa o OpenRouter."""
    print("🔒 DESATIVANDO OPENROUTER...")
    print("=" * 40)
    
    update_env_file(False)
    
    print("✅ OpenRouter desativado!")
    print("\n🔄 Para aplicar as mudanças:")
    print("   1. Reinicie o servidor Python")
    print("   2. Ou use: source .env && python3 seu_script.py")
    print("\n📋 Comportamento esperado:")
    print("   • Apenas APIs diretas (níveis 3-4)")
    print("   • Economia de 5% nos custos")
    print("   • Controle total sobre privacidade")
    print("\n✅ BENEFÍCIOS:")
    print("   • ✅ Compliance LGPD garantido")
    print("   • ✅ Latência otimizada")
    print("   • ✅ Zero vendor lock-in")


async def main():
    """Função principal."""
    parser = argparse.ArgumentParser(description="Toggle OpenRouter no LITIG-1")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--enable", action="store_true", help="Ativa OpenRouter")
    group.add_argument("--disable", action="store_true", help="Desativa OpenRouter")
    group.add_argument("--status", action="store_true", help="Mostra status atual")
    group.add_argument("--test", action="store_true", help="Testa configuração atual")
    
    args = parser.parse_args()
    
    print("🔧 LITIG-1 OPENROUTER TOGGLE")
    print("=" * 60)
    
    if args.enable:
        enable_openrouter()
    elif args.disable:
        disable_openrouter()
    elif args.status:
        show_status()
    elif args.test:
        await test_current_config()


if __name__ == "__main__":
    asyncio.run(main()) 
 