#!/usr/bin/env python3
"""
Teste do Sistema RAG Jurídico com Taxonomia Completa
===================================================

Testa a detecção automática de áreas jurídicas e web search
baseado na taxonomia jurídica brasileira expandida.
"""

import asyncio
import sys
from pathlib import Path

# Adicionar path para importar serviços
sys.path.append(str(Path(__file__).parent))

async def test_legal_area_detection():
    """Testa a detecção automática de áreas jurídicas."""
    
    print("🧪 TESTE DE DETECÇÃO DE ÁREAS JURÍDICAS")
    print("=" * 60)
    
    # Casos de teste por área
    test_cases = [
        # Direito Constitucional
        {
            "query": "Quais são os direitos fundamentais na Constituição Federal?",
            "expected_area": "Constitucional",
            "description": "Direitos fundamentais"
        },
        {
            "query": "Como funciona o controle de constitucionalidade pelo STF?",
            "expected_area": "Constitucional", 
            "description": "Controle de constitucionalidade"
        },
        
        # Direito Administrativo
        {
            "query": "Quais são os princípios da licitação pública?",
            "expected_area": "Administrativo",
            "description": "Licitação"
        },
        {
            "query": "Como caracterizar improbidade administrativa?",
            "expected_area": "Administrativo",
            "description": "Improbidade administrativa"
        },
        
        # Direito Tributário
        {
            "query": "Como calcular o ICMS na venda de mercadorias?",
            "expected_area": "Tributário",
            "description": "ICMS"
        },
        {
            "query": "Quais são os princípios do lançamento tributário?",
            "expected_area": "Tributário",
            "description": "Lançamento tributário"
        },
        
        # Direito Penal
        {
            "query": "Quando se configura legítima defesa?",
            "expected_area": "Penal",
            "description": "Legítima defesa"
        },
        {
            "query": "Qual a diferença entre homicídio simples e qualificado?",
            "expected_area": "Penal",
            "description": "Homicídio"
        },
        
        # Direito do Trabalho
        {
            "query": "Como funciona o cálculo de horas extras?",
            "expected_area": "Trabalho",
            "description": "Horas extras"
        },
        {
            "query": "Quais os requisitos da relação de emprego?",
            "expected_area": "Trabalho",
            "description": "Relação de emprego"
        },
        
        # Direito Previdenciário
        {
            "query": "Quais os requisitos para aposentadoria por idade?",
            "expected_area": "Previdenciário",
            "description": "Aposentadoria"
        },
        {
            "query": "Como solicitar auxílio-doença no INSS?",
            "expected_area": "Previdenciário",
            "description": "Auxílio-doença"
        },
        
        # Direito do Consumidor
        {
            "query": "Quais os direitos do consumidor no CDC?",
            "expected_area": "Consumidor",
            "description": "CDC"
        },
        {
            "query": "Como caracterizar propaganda enganosa?",
            "expected_area": "Consumidor",
            "description": "Propaganda enganosa"
        },
        
        # Direito Digital
        {
            "query": "Como funciona a LGPD para proteção de dados?",
            "expected_area": "Digital",
            "description": "LGPD"
        },
        {
            "query": "Quais os direitos no Marco Civil da Internet?",
            "expected_area": "Digital",
            "description": "Marco Civil da Internet"
        },
        
        # Direito Ambiental
        {
            "query": "Como funciona o licenciamento ambiental?",
            "expected_area": "Ambiental",
            "description": "Licenciamento ambiental"
        },
        {
            "query": "O que são áreas de preservação permanente?",
            "expected_area": "Ambiental",
            "description": "APP"
        },
        
        # Direito Eleitoral
        {
            "query": "Como funciona a propaganda eleitoral?",
            "expected_area": "Eleitoral",
            "description": "Propaganda eleitoral"
        },
        {
            "query": "Quais as competências do TSE?",
            "expected_area": "Eleitoral",
            "description": "TSE"
        }
    ]
    
    try:
        # Simular detecção de áreas (sem necessidade do RAG completo)
        from legal_knowledge_base import get_legal_area_weights
        
        legal_areas_taxonomy = get_legal_area_weights()
        
        print(f"\n🏛️ TESTANDO {len(test_cases)} CONSULTAS EM {len(legal_areas_taxonomy)} ÁREAS")
        print("-" * 60)
        
        correct_detections = 0
        
        for i, test_case in enumerate(test_cases, 1):
            query = test_case["query"]
            expected = test_case["expected_area"]
            description = test_case["description"]
            
            print(f"\n📋 Teste {i:2d}: {description}")
            print(f"❓ Query: {query}")
            print(f"🎯 Esperado: {expected}")
            
            # Simular detecção de área
            query_lower = query.lower()
            detected_areas = []
            max_score = 0
            best_area = None
            
            for area_name, terms in legal_areas_taxonomy.items():
                area_score = 0
                matched_terms = []
                
                for term, weight in terms:
                    if term.lower() in query_lower:
                        area_score += weight
                        matched_terms.append(term)
                
                if area_score > 0:
                    detected_areas.append({
                        'area': area_name,
                        'score': area_score,
                        'terms': matched_terms
                    })
                    
                    if area_score > max_score:
                        max_score = area_score
                        best_area = area_name
            
            # Verificar resultado
            if best_area == expected:
                print(f"✅ Detectado: {best_area} (score: {max_score})")
                correct_detections += 1
            else:
                print(f"❌ Detectado: {best_area or 'Nenhuma'} (esperado: {expected})")
                if detected_areas:
                    print(f"   Outras áreas: {[(a['area'], a['score']) for a in detected_areas[:3]]}")
        
        # Resultado final
        accuracy = (correct_detections / len(test_cases)) * 100
        print(f"\n📊 RESULTADO FINAL:")
        print(f"   ✅ Acertos: {correct_detections}/{len(test_cases)}")
        print(f"   🎯 Precisão: {accuracy:.1f}%")
        
        if accuracy >= 80:
            print("🎉 EXCELENTE! Sistema de detecção funcionando muito bem!")
        elif accuracy >= 60:
            print("👍 BOM! Sistema de detecção funcionando adequadamente")
        else:
            print("⚠️ Sistema de detecção precisa de ajustes")
            
    except ImportError as e:
        print(f"❌ Erro de importação: {e}")
        print("💡 Certifique-se de que legal_knowledge_base.py está disponível")
    
    except Exception as e:
        print(f"❌ Erro: {e}")
        import traceback
        traceback.print_exc()

async def test_query_enhancement():
    """Testa o aprimoramento de queries."""
    
    print("\n\n🔍 TESTE DE APRIMORAMENTO DE QUERIES")
    print("=" * 60)
    
    test_queries = [
        "direitos trabalhistas",
        "ICMS mercadorias",
        "legítima defesa",
        "licitação pública",
        "LGPD dados pessoais",
        "aposentadoria INSS"
    ]
    
    try:
        from legal_knowledge_base import get_legal_area_weights
        legal_areas_taxonomy = get_legal_area_weights()
        
        for query in test_queries:
            print(f"\n📝 Query original: '{query}'")
            
            # Simular enhancement
            query_lower = query.lower()
            best_area = None
            max_score = 0
            
            for area_name, terms in legal_areas_taxonomy.items():
                area_score = 0
                for term, weight in terms:
                    if term.lower() in query_lower:
                        area_score += weight
                
                if area_score > max_score:
                    max_score = area_score
                    best_area = area_name
            
            if best_area:
                area_terms = [term for term, _ in legal_areas_taxonomy[best_area][:3]]
                enhanced = f"{query} {best_area.lower()} brasil legislação {' '.join(area_terms)}"
                print(f"🚀 Query aprimorada: '{enhanced}'")
                print(f"🎯 Área detectada: {best_area} (score: {max_score})")
            else:
                enhanced = f"{query} direito brasileiro legislação jurisprudência"
                print(f"🚀 Query genérica: '{enhanced}'")
            
    except Exception as e:
        print(f"❌ Erro: {e}")

if __name__ == "__main__":
    # Executar testes
    asyncio.run(test_legal_area_detection())
    asyncio.run(test_query_enhancement())
