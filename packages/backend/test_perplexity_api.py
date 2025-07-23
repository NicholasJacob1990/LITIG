#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Teste Específico da API Perplexity
==================================
Testa a integração da API Perplexity no algoritmo de matching.
"""

import asyncio
import os
from datetime import datetime
from typing import Dict, List, Any

def print_header(title: str):
    """Imprime um cabeçalho formatado."""
    print("\n" + "=" * 80)
    print(f"🔍 {title}")
    print("=" * 80)

def print_section(title: str):
    """Imprime uma seção formatada."""
    print(f"\n📋 {title}")
    print("-" * 60)

def check_perplexity_environment():
    """Verifica configuração da API Perplexity."""
    print_section("Verificação de Ambiente - Perplexity")
    
    api_key = os.getenv("PERPLEXITY_API_KEY")
    
    if api_key:
        masked_key = f"{api_key[:12]}..." if len(api_key) > 12 else "***"
        print(f"✅ PERPLEXITY_API_KEY: {masked_key}")
        return True
    else:
        print("🔧 PERPLEXITY_API_KEY: NÃO CONFIGURADA")
        print("   Configure com: export PERPLEXITY_API_KEY='pplx-...'")
        return False

async def test_perplexity_integration():
    """Testa a integração Perplexity no algoritmo."""
    print_section("Teste de Integração Perplexity")
    
    try:
        # Importar o algoritmo
        from algoritmo_match import MatchmakingAlgorithm, perplexity_chat
        
        print("✅ Algoritmo importado com sucesso")
        
        # Verificar se perplexity_chat está disponível
        print("✅ Função perplexity_chat disponível")
        
        # Criar instância do algoritmo
        algorithm = MatchmakingAlgorithm()
        print("✅ Instância do algoritmo criada")
        
        # Verificar templates Perplexity
        if hasattr(algorithm, 'templates'):
            templates = algorithm.templates
            print("✅ Templates de prompt disponíveis")
            
            # Testar payload de universidades
            test_universities = ['USP', 'Harvard', 'MIT']
            unis_payload = templates.perplexity_universities_payload(test_universities)
            print(f"✅ Template universidades gerado: {len(unis_payload)} chaves")
            
            # Testar payload de periódicos
            test_journals = ['RDA', 'Harvard Law Review', 'Nature']
            journals_payload = templates.perplexity_journals_payload(test_journals)
            print(f"✅ Template periódicos gerado: {len(journals_payload)} chaves")
            
            return True
        else:
            print("⚠️ Templates não encontrados no algoritmo")
            return False
            
    except ImportError as e:
        print(f"❌ Erro de import: {e}")
        return False
    except Exception as e:
        print(f"❌ Erro geral: {e}")
        return False

async def test_perplexity_api_call():
    """Testa chamada real da API Perplexity (se configurada)."""
    print_section("Teste de Chamada API Perplexity")
    
    api_key = os.getenv("PERPLEXITY_API_KEY")
    if not api_key:
        print("⚠️ API Key não configurada - pulando teste de chamada")
        return False
    
    try:
        from algoritmo_match import perplexity_chat
        
        # Payload de teste simples
        test_payload = {
            "model": "llama-3.1-sonar-small-128k-online",
            "messages": [
                {
                    "role": "system",
                    "content": "Você é um assistente acadêmico especializado em universidades."
                },
                {
                    "role": "user", 
                    "content": "Avalie rapidamente a reputação da USP (Universidade de São Paulo) em uma escala de 1-10."
                }
            ],
            "max_tokens": 100,
            "temperature": 0.3
        }
        
        print("🔄 Fazendo chamada para Perplexity API...")
        start_time = datetime.now()
        
        response = await perplexity_chat(test_payload)
        
        end_time = datetime.now()
        latency = (end_time - start_time).total_seconds() * 1000
        
        if response:
            print(f"✅ Resposta recebida em {latency:.0f}ms")
            
            if 'choices' in response and len(response['choices']) > 0:
                content = response['choices'][0].get('message', {}).get('content', '')
                preview = content[:100] + "..." if len(content) > 100 else content
                print(f"📝 Preview: {preview}")
                
                if 'usage' in response:
                    usage = response['usage']
                    print(f"📊 Tokens: {usage.get('total_tokens', 'N/A')}")
                
                return True
            else:
                print("⚠️ Resposta sem conteúdo válido")
                return False
        else:
            print("❌ Nenhuma resposta recebida")
            return False
            
    except Exception as e:
        print(f"❌ Erro na chamada API: {e}")
        return False

async def test_perplexity_academic_features():
    """Testa features acadêmicas específicas do Perplexity."""
    print_section("Teste de Features Acadêmicas")
    
    try:
        from services.academic_prompt_templates import AcademicPromptTemplates
        
        templates = AcademicPromptTemplates()
        print("✅ Templates acadêmicos carregados")
        
        # Testar diferentes tipos de payload
        test_cases = [
            ("Universidades BR", ['USP', 'UNICAMP', 'UFRJ']),
            ("Universidades Internacional", ['Harvard', 'MIT', 'Stanford']),
            ("Periódicos Jurídicos", ['RDA', 'Revista dos Tribunais', 'Harvard Law Review']),
            ("Periódicos Científicos", ['Nature', 'Science', 'Cell'])
        ]
        
        for test_name, test_data in test_cases:
            print(f"\n🧪 Testando: {test_name}")
            
            if 'Universidades' in test_name:
                payload = templates.perplexity_universities_payload(test_data)
            else:
                payload = templates.perplexity_journals_payload(test_data)
            
            # Verificar estrutura do payload
            required_keys = ['model', 'messages', 'max_tokens', 'temperature']
            missing_keys = [key for key in required_keys if key not in payload]
            
            if not missing_keys:
                print(f"  ✅ Payload válido com {len(payload)} chaves")
                print(f"  📝 Modelo: {payload.get('model', 'N/A')}")
                print(f"  💬 Mensagens: {len(payload.get('messages', []))}")
            else:
                print(f"  ❌ Payload inválido - chaves faltando: {missing_keys}")
        
        return True
        
    except ImportError as e:
        print(f"❌ Erro importando templates: {e}")
        return False
    except Exception as e:
        print(f"❌ Erro geral: {e}")
        return False

async def main():
    """Função principal de teste."""
    print_header("TESTE PERPLEXITY API - ALGORITMO MATCHING v2.8")
    
    # 1. Verificar ambiente
    has_api_key = check_perplexity_environment()
    
    # 2. Testar integração básica
    integration_ok = await test_perplexity_integration()
    
    # 3. Testar features acadêmicas
    academic_ok = await test_perplexity_academic_features()
    
    # 4. Testar chamada API (se configurada)
    api_ok = False
    if has_api_key:
        api_ok = await test_perplexity_api_call()
    
    # Resumo final
    print_header("RESUMO DO TESTE PERPLEXITY")
    
    print(f"🔑 API Key Configurada: {'✅' if has_api_key else '❌'}")
    print(f"🔧 Integração Algoritmo: {'✅' if integration_ok else '❌'}")
    print(f"🎓 Features Acadêmicas: {'✅' if academic_ok else '❌'}")
    print(f"🌐 Chamada API: {'✅' if api_ok else '⚠️ Pulado' if not has_api_key else '❌'}")
    
    # Status geral
    if integration_ok and academic_ok:
        if has_api_key and api_ok:
            print(f"\n🎉 STATUS: PERPLEXITY 100% FUNCIONAL!")
        elif has_api_key:
            print(f"\n⚠️ STATUS: PERPLEXITY INTEGRADO (API com problemas)")
        else:
            print(f"\n🔧 STATUS: PERPLEXITY INTEGRADO (configure API key)")
    else:
        print(f"\n❌ STATUS: PERPLEXITY COM PROBLEMAS")
    
    print(f"\n📝 Configuração necessária:")
    print(f"   export PERPLEXITY_API_KEY='pplx-...'")
    print(f"   Rate limit: 30 req/min")
    print(f"   Endpoint: https://api.perplexity.ai/chat/completions")

if __name__ == "__main__":
    asyncio.run(main()) 