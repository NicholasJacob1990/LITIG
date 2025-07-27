#!/usr/bin/env python3
"""
Script de teste para verificar se o juiz Gemini está funcionando corretamente.
"""

import asyncio
import json
import os
import sys
from dotenv import load_dotenv

# Adicionar o diretório pai ao path para importar os módulos
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services.triage_service import TriageService

load_dotenv()

async def test_gemini_judge():
    """Testa o juiz Gemini com um caso de exemplo."""
    
    print("🧪 Testando Juiz Gemini Pro 2.5...")
    
    # Verificar se a API key está configurada
    gemini_api_key = os.getenv("GEMINI_API_KEY")
    if not gemini_api_key:
        print("❌ GEMINI_API_KEY não encontrada no arquivo .env")
        print("   Adicione: GEMINI_API_KEY=your_api_key_here")
        return False
    
    try:
        # Inicializar o serviço de triagem
        triage_service = TriageService()
        
        # Caso de teste: Disputa trabalhista
        test_text = """
        Fui demitido sem justa causa após 5 anos de trabalho. A empresa não pagou 
        minhas férias vencidas, 13º salário e não me deu aviso prévio. Também 
        não recebi o FGTS e multa de 40%. Quero processar a empresa.
        """
        
        # Resultados simulados de dois modelos diferentes
        result1 = {
            "area": "Trabalhista",
            "subarea": "Rescisão de Contrato",
            "urgency_h": 72,
            "summary": "Demissão sem justa causa com verbas rescisórias em atraso",
            "keywords": ["demissão", "verbas rescisórias", "férias", "13º salário"],
            "sentiment": "Negativo"
        }
        
        result2 = {
            "area": "Trabalhista", 
            "subarea": "Verbas Rescisórias",
            "urgency_h": 48,
            "summary": "Funcionário demitido sem receber verbas rescisórias",
            "keywords": ["verbas rescisórias", "demissão", "FGTS", "multa"],
            "sentiment": "Negativo"
        }
        
        print(f"📝 Caso de teste: {test_text[:100]}...")
        print(f"🔍 Resultado 1: {result1['area']} - {result1['subarea']}")
        print(f"🔍 Resultado 2: {result2['area']} - {result2['subarea']}")
        print("🤖 Acionando juiz Gemini...")
        
        # Testar o juiz Gemini
        start_time = asyncio.get_event_loop().time()
        
        final_decision = await triage_service._judge_results(test_text, result1, result2)
        
        end_time = asyncio.get_event_loop().time()
        processing_time = (end_time - start_time) * 1000
        
        print(f"✅ Juiz Gemini funcionando!")
        print(f"⏱️  Tempo de processamento: {processing_time:.2f}ms")
        print(f"🎯 Decisão final: {final_decision['area']} - {final_decision['subarea']}")
        print(f"📊 Resumo: {final_decision.get('summary', 'N/A')}")
        print(f"🚨 Urgência: {final_decision.get('urgency_h', 'N/A')} horas")
        
        return True
        
    except Exception as e:
        print(f"❌ Erro no teste: {e}")
        print(f"   Tipo de erro: {type(e).__name__}")
        return False

async def test_gemini_connectivity():
    """Testa a conectividade básica com a API do Gemini."""
    
    print("🔌 Testando conectividade com Gemini...")
    
    try:
        import google.generativeai as genai
        
        gemini_api_key = os.getenv("GEMINI_API_KEY")
        if not gemini_api_key:
            print("❌ GEMINI_API_KEY não encontrada")
            return False
        
        genai.configure(api_key=gemini_api_key)
        
        # Testar com um prompt simples
        model = genai.GenerativeModel("gemini-2.0-flash-exp")
        
        response = await asyncio.wait_for(
            model.generate_content_async("Responda apenas 'OK' se estiver funcionando."),
            timeout=10
        )
        
        if "OK" in response.text:
            print("✅ Conectividade com Gemini OK!")
            return True
        else:
            print(f"⚠️  Resposta inesperada: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Erro de conectividade: {e}")
        return False

async def main():
    """Função principal do teste."""
    
    print("🚀 Iniciando testes do Juiz Gemini Pro 2.5")
    print("=" * 50)
    
    # Teste 1: Conectividade
    connectivity_ok = await test_gemini_connectivity()
    
    if not connectivity_ok:
        print("\n❌ Falha na conectividade. Verifique:")
        print("   1. GEMINI_API_KEY está configurada")
        print("   2. Conexão com internet")
        print("   3. API key é válida")
        return
    
    print()
    
    # Teste 2: Juiz
    judge_ok = await test_gemini_judge()
    
    print("\n" + "=" * 50)
    
    if judge_ok:
        print("🎉 Todos os testes passaram!")
        print("✅ Juiz Gemini Pro 2.5 está funcionando corretamente")
    else:
        print("❌ Alguns testes falharam")
        print("🔧 Verifique a configuração e tente novamente")

if __name__ == "__main__":
    asyncio.run(main()) 