#!/usr/bin/env python3
"""
Script para Ativar Sistema de Matching Aprimorado com LLMs
=========================================================

Este script ativa progressivamente o sistema LLM enhanced no ambiente.
"""

import asyncio
import os
import sys
from pathlib import Path
from typing import Dict, Any

# Adicionar backend ao path
backend_path = Path(__file__).parent.parent
sys.path.insert(0, str(backend_path))

from services.enhanced_match_service import EnhancedMatchService
from services.lawyer_profile_analysis_service import LawyerProfileAnalysisService
from services.case_context_analysis_service import CaseContextAnalysisService
from config import Settings

async def test_llm_connectivity():
    """Testa conectividade com todas as APIs LLM"""
    
    print("🔌 Testando conectividade com LLMs...")
    
    settings = Settings()
    results = {}
    
    # Teste Gemini
    if settings.GEMINI_API_KEY:
        try:
            import google.generativeai as genai
            genai.configure(api_key=settings.GEMINI_API_KEY)
            model = genai.GenerativeModel("gemini-pro")
            
            response = await asyncio.wait_for(
                model.generate_content_async("Responda apenas 'OK'"),
                timeout=10
            )
            
            if "OK" in response.text:
                results['gemini'] = "✅ Conectado"
            else:
                results['gemini'] = "⚠️ Resposta inesperada"
                
        except Exception as e:
            results['gemini'] = f"❌ Erro: {e}"
    else:
        results['gemini'] = "❌ API key não configurada"
    
    # Teste Claude
    if settings.ANTHROPIC_API_KEY:
        try:
            import anthropic
            client = anthropic.AsyncAnthropic(api_key=settings.ANTHROPIC_API_KEY)
            
            message = await client.messages.create(
                model="claude-3-5-sonnet-20240620",
                max_tokens=10,
                messages=[{"role": "user", "content": "Responda apenas 'OK'"}]
            )
            
            if "OK" in message.content[0].text:
                results['claude'] = "✅ Conectado"
            else:
                results['claude'] = "⚠️ Resposta inesperada"
                
        except Exception as e:
            results['claude'] = f"❌ Erro: {e}"
    else:
        results['claude'] = "❌ API key não configurada"
    
    # Teste OpenAI
    if settings.OPENAI_API_KEY:
        try:
            import openai
            client = openai.AsyncOpenAI(api_key=settings.OPENAI_API_KEY)
            
            response = await client.chat.completions.create(
                model="gpt-4o",
                max_tokens=10,
                messages=[{"role": "user", "content": "Responda apenas 'OK'"}]
            )
            
            if "OK" in response.choices[0].message.content:
                results['openai'] = "✅ Conectado"
            else:
                results['openai'] = "⚠️ Resposta inesperada"
                
        except Exception as e:
            results['openai'] = f"❌ Erro: {e}"
    else:
        results['openai'] = "❌ API key não configurada"
    
    # Mostrar resultados
    print("\n📊 Resultados da conectividade:")
    for llm, status in results.items():
        print(f"  {llm.capitalize()}: {status}")
    
    # Verificar se pelo menos um LLM está funcionando
    working_llms = [llm for llm, status in results.items() if "✅" in status]
    
    if working_llms:
        print(f"\n🎉 {len(working_llms)} LLM(s) funcionando: {', '.join(working_llms)}")
        return True
    else:
        print("\n❌ Nenhum LLM está funcionando. Verifique as configurações.")
        return False

async def test_enhanced_matching():
    """Testa o sistema de matching aprimorado"""
    
    print("\n🧪 Testando sistema de matching aprimorado...")
    
    # Dados de teste
    test_case = {
        'id': 'test-case-001',
        'area': 'Empresarial',
        'subarea': 'Startups',
        'summary': 'Startup de fintech precisa de assessoria para rodada de investimento',
        'urgency_h': 48,
        'expected_fee_max': 50000,
        'expected_fee_min': 20000,
        'latitude': -23.5505,
        'longitude': -46.6333,
        'client_type': 'startup',
        'complexity': 'high'
    }
    
    try:
        # Inicializar serviços
        enhanced_service = EnhancedMatchService()
        
        print("  📝 Analisando caso com LLM...")
        
        # Teste análise de caso
        case_analysis_service = CaseContextAnalysisService()
        case_insights = await case_analysis_service.analyze_case_context(test_case)
        
        print(f"    ✅ Fatores de complexidade: {case_insights.complexity_factors}")
        print(f"    ✅ Expertises necessárias: {case_insights.required_expertise}")
        print(f"    ✅ Probabilidade de sucesso: {case_insights.success_probability:.2f}")
        
        print("  🤖 Testando análise de perfil de advogado...")
        
        # Dados mock de advogado para teste
        test_lawyer = {
            'id': 'lawyer-001',
            'nome': 'Ana Silva',
            'oab_numero': '123456',
            'uf': 'SP',
            'curriculo_json': {
                'anos_experiencia': 8,
                'graduacao': {'instituicao': 'USP', 'ano': 2015},
                'pos_graduacoes': [
                    {'nivel': 'mestrado', 'instituicao': 'FGV', 'area': 'Direito Empresarial'}
                ],
                'publicacoes': [
                    {'titulo': 'Startups e Regulamentação', 'journal': 'Revista Direito Empresarial'}
                ]
            },
            'tags_expertise': ['startups', 'venture capital', 'direito empresarial'],
            'reviews': [
                'Excelente advogada, muito atenciosa e conhece bem startups',
                'Assessoria impecável na nossa rodada de investimento'
            ],
            'kpi': {
                'success_rate': 0.85,
                'reputacao': 0.90
            }
        }
        
        # Teste análise de advogado
        lawyer_analysis_service = LawyerProfileAnalysisService()
        lawyer_insights = await lawyer_analysis_service.analyze_lawyer_profile(test_lawyer)
        
        print(f"    ✅ Nível de expertise: {lawyer_insights.expertise_level:.2f}")
        print(f"    ✅ Especialidades detectadas: {lawyer_insights.niche_specialties}")
        print(f"    ✅ Estilo de comunicação: {lawyer_insights.communication_style}")
        
        print("  🎯 Calculando compatibilidade LLM...")
        
        # Teste compatibilidade
        compatibility = await lawyer_analysis_service._calculate_llm_compatibility(
            test_case, test_lawyer, lawyer_insights
        )
        
        print(f"    ✅ Score de compatibilidade LLM: {compatibility:.2f}")
        
        print("\n🎉 Sistema de matching aprimorado funcionando perfeitamente!")
        return True
        
    except Exception as e:
        print(f"\n❌ Erro no teste de matching: {e}")
        return False

async def activate_llm_matching():
    """Ativa o sistema LLM enhanced"""
    
    print("🚀 Ativando Sistema de Matching Aprimorado com LLMs")
    print("=" * 60)
    
    # Verificar configurações
    settings = Settings()
    
    print("📋 Verificando configurações...")
    
    required_configs = {
        'GEMINI_API_KEY': settings.GEMINI_API_KEY,
        'ANTHROPIC_API_KEY': settings.ANTHROPIC_API_KEY,
        'OPENAI_API_KEY': settings.OPENAI_API_KEY
    }
    
    configured_apis = []
    for config, value in required_configs.items():
        if value:
            print(f"  ✅ {config}: Configurado")
            configured_apis.append(config)
        else:
            print(f"  ⚠️ {config}: Não configurado")
    
    if not configured_apis:
        print("\n❌ Nenhuma API LLM configurada. Configure pelo menos uma:")
        print("   export GEMINI_API_KEY=your_key")
        print("   export ANTHROPIC_API_KEY=your_key") 
        print("   export OPENAI_API_KEY=your_key")
        return False
    
    print(f"\n📊 {len(configured_apis)} API(s) LLM configurada(s)")
    
    # Testar conectividade
    connectivity_ok = await test_llm_connectivity()
    
    if not connectivity_ok:
        print("\n❌ Falha na conectividade. Corrija os problemas antes de continuar.")
        return False
    
    # Testar sistema completo
    matching_ok = await test_enhanced_matching()
    
    if not matching_ok:
        print("\n❌ Falha no sistema de matching. Verifique os logs.")
        return False
    
    # Ativar no ambiente
    print("\n🔧 Ativando configurações...")
    
    # Criar/atualizar arquivo de configuração
    config_updates = {
        'ENABLE_LLM_MATCHING': 'true',
        'MAX_LLM_CANDIDATES': '15', 
        'TRADITIONAL_WEIGHT': '0.6',
        'LLM_WEIGHT': '0.4',
        'LLM_MATCHING_VERSION': 'v1.0'
    }
    
    env_file = Path('.env')
    if env_file.exists():
        # Ler arquivo existente
        with open(env_file, 'r') as f:
            lines = f.readlines()
        
        # Atualizar configurações
        updated_lines = []
        updated_keys = set()
        
        for line in lines:
            if '=' in line and not line.strip().startswith('#'):
                key = line.split('=')[0].strip()
                if key in config_updates:
                    updated_lines.append(f"{key}={config_updates[key]}\n")
                    updated_keys.add(key)
                else:
                    updated_lines.append(line)
            else:
                updated_lines.append(line)
        
        # Adicionar novas configurações
        if updated_keys != set(config_updates.keys()):
            updated_lines.append("\n# LLM Enhanced Matching Configuration\n")
            for key, value in config_updates.items():
                if key not in updated_keys:
                    updated_lines.append(f"{key}={value}\n")
        
        # Escrever arquivo atualizado
        with open(env_file, 'w') as f:
            f.writelines(updated_lines)
        
        print("  ✅ Arquivo .env atualizado")
    else:
        # Criar novo arquivo
        with open(env_file, 'w') as f:
            f.write("# LLM Enhanced Matching Configuration\n")
            for key, value in config_updates.items():
                f.write(f"{key}={value}\n")
        
        print("  ✅ Arquivo .env criado")
    
    print("\n✅ Sistema LLM Enhanced ATIVADO com sucesso!")
    print("\n📋 Próximos passos:")
    print("  1. Reinicie o servidor backend")
    print("  2. Use endpoint /enhanced-matches para testes") 
    print("  3. Monitore métricas de performance")
    print("  4. Colete feedback dos usuários")
    
    return True

async def main():
    """Função principal"""
    
    success = await activate_llm_matching()
    
    if success:
        print("\n🎉 ATIVAÇÃO CONCLUÍDA COM SUCESSO!")
        print("Sistema de recomendações aprimorado com LLMs está ativo.")
    else:
        print("\n❌ FALHA NA ATIVAÇÃO")
        print("Corrija os problemas e tente novamente.")
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main()) 