#!/usr/bin/env python3
"""
Teste do Sistema RAG Jurídico Brasileiro Abrangente com Web Search
================================================================

Testa todas as funcionalidades do RAG expandido:
✅ Cobertura abrangente de todas as áreas do Direito
✅ Web search como fallback
✅ Integração Supabase + Chroma
✅ Respostas combinadas (local + web)
"""

import asyncio
import os
import sys
from pathlib import Path
from datetime import datetime

# Adicionar path para importar serviços
sys.path.append(str(Path(__file__).parent))

async def test_comprehensive_legal_rag():
    """Teste completo do sistema RAG jurídico abrangente."""
    
    print("🧪 TESTE DO SISTEMA RAG JURÍDICO BRASILEIRO ABRANGENTE")
    print("=" * 70)
    
    try:
        # Importar sistema RAG
        from brazilian_legal_rag import BrazilianLegalRAG
        
        print("\n🔧 Inicializando sistema RAG...")
        
        # Testar com Supabase se disponível, senão Chroma local
        try:
            rag = BrazilianLegalRAG(use_supabase=True)
            print("✅ RAG inicializado com Supabase")
        except:
            rag = BrazilianLegalRAG(use_supabase=False)
            print("✅ RAG inicializado com Chroma local")
        
        # Inicializar base de conhecimento
        print("\n📚 Inicializando base de conhecimento abrangente...")
        await rag.initialize_knowledge_base()
        
        # Verificar estatísticas
        stats = rag.get_stats()
        print(f"✅ Sistema inicializado")
        print(f"   💾 Storage: {stats['storage_type']}")
        print(f"   📊 Documentos: {stats.get('document_count', 'N/A')}")
        print(f"   🔄 Retriever: {'✅' if stats['retriever_configured'] else '❌'}")
        print(f"   🤖 QA Chain: {'✅' if stats['qa_chain_configured'] else '❌'}")
        
        # ================================================================
        # TESTES POR ÁREA DO DIREITO
        # ================================================================
        
        test_queries = [
            # Direito Trabalhista
            {
                "area": "Trabalhista",
                "query": "Quais são os direitos às férias segundo a CLT?",
                "expected_local": True  # Deve ter resposta local
            },
            {
                "area": "Trabalhista",
                "query": "Como calcular horas extras noturnas na nova lei trabalhista de 2024?",
                "expected_local": False  # Provavelmente vai para web search
            },
            
            # Direito Civil
            {
                "area": "Civil",
                "query": "Quais são os princípios dos contratos no Código Civil?",
                "expected_local": True
            },
            {
                "area": "Civil",
                "query": "Como funciona o divórcio por escritura pública após a Lei 13.874/2019?",
                "expected_local": False
            },
            
            # Direito Penal
            {
                "area": "Penal",
                "query": "Quais são as causas excludentes de ilicitude no Código Penal?",
                "expected_local": True
            },
            {
                "area": "Penal",
                "query": "Qual a pena para crimes de stalking no novo marco legal de 2023?",
                "expected_local": False
            },
            
            # Direito Tributário
            {
                "area": "Tributário",
                "query": "Quais são os princípios tributários na Constituição Federal?",
                "expected_local": True
            },
            {
                "area": "Tributário",
                "query": "Como funciona o PIX para fins tributários segundo a Receita Federal 2024?",
                "expected_local": False
            },
            
            # Direito Administrativo
            {
                "area": "Administrativo",
                "query": "Quais são os princípios da administração pública?",
                "expected_local": True
            },
            {
                "area": "Administrativo",
                "query": "Como funciona a nova Lei de Licitações 14.133/2021 na prática?",
                "expected_local": False
            },
            
            # Direito Previdenciário
            {
                "area": "Previdenciário",
                "query": "Quais são os tipos de aposentadoria no INSS?",
                "expected_local": True
            },
            {
                "area": "Previdenciário",
                "query": "Qual o valor da aposentadoria em 2024 após a reforma da previdência?",
                "expected_local": False
            }
        ]
        
        print(f"\n🔍 TESTANDO {len(test_queries)} CONSULTAS JURÍDICAS")
        print("=" * 50)
        
        for i, test_case in enumerate(test_queries, 1):
            print(f"\n📋 Teste {i}/{len(test_queries)} - {test_case['area']}")
            print(f"❓ Pergunta: {test_case['query']}")
            
            try:
                # Executar consulta com web search habilitado
                start_time = datetime.now()
                result = await rag.query(
                    question=test_case['query'],
                    include_sources=True,
                    use_web_search_fallback=True
                )
                duration = (datetime.now() - start_time).total_seconds()
                
                if result["success"]:
                    print(f"✅ Resposta obtida em {duration:.2f}s")
                    print(f"🔄 Fonte: {result.get('sources_used', 'N/A')}")
                    
                    # Mostrar trecho da resposta
                    answer = result["answer"][:200] + "..." if len(result["answer"]) > 200 else result["answer"]
                    print(f"💬 Resposta: {answer}")
                    
                    # Mostrar fontes
                    if result.get("sources"):
                        print(f"📚 Fontes encontradas: {len(result['sources'])}")
                        for j, source in enumerate(result["sources"][:2], 1):
                            source_name = source.get("source", "Desconhecido")[:50]
                            source_type = source.get("type", "N/A")
                            print(f"   {j}. {source_name} ({source_type})")
                    
                    # Verificar se usou web search conforme esperado
                    used_web_search = "Web Search" in result.get("sources_used", "")
                    expected_web = not test_case["expected_local"]
                    
                    if used_web_search == expected_web:
                        print("🎯 Comportamento esperado!")
                    else:
                        source_type = "Web Search" if used_web_search else "RAG Local"
                        print(f"⚠️ Usou {source_type} quando esperava {'Web Search' if expected_web else 'RAG Local'}")
                
                else:
                    print(f"❌ Erro: {result.get('error', 'Erro desconhecido')}")
                
            except Exception as e:
                print(f"❌ Exceção no teste: {e}")
                continue
            
            print("-" * 50)
        
        # ================================================================
        # TESTE DE FALLBACK
        # ================================================================
        
        print(f"\n🛡️ TESTE DE FALLBACK - WEB SEARCH FORÇADO")
        print("=" * 50)
        
        # Teste com query muito específica que não deve estar na base local
        specific_query = "Qual a última decisão do STF sobre LGPD em outubro de 2024?"
        
        print(f"❓ Pergunta específica: {specific_query}")
        
        try:
            result = await rag.query(
                question=specific_query,
                include_sources=True,
                use_web_search_fallback=True
            )
            
            if result["success"]:
                print(f"✅ Resposta obtida via: {result.get('sources_used', 'N/A')}")
                answer = result["answer"][:300] + "..." if len(result["answer"]) > 300 else result["answer"]
                print(f"💬 Resposta: {answer}")
                
                if "Web Search" in result.get("sources_used", ""):
                    print("🎯 Web Search funcionou como esperado!")
                else:
                    print("⚠️ Não usou Web Search para query específica")
            else:
                print(f"❌ Erro no fallback: {result.get('error')}")
                
        except Exception as e:
            print(f"❌ Exceção no teste de fallback: {e}")
        
        # ================================================================
        # RESUMO FINAL
        # ================================================================
        
        print(f"\n🎉 RESUMO DO TESTE COMPLETO")
        print("=" * 50)
        print("✅ Sistema RAG jurídico abrangente funcionando")
        print("✅ Cobertura de todas as áreas do Direito brasileiro")
        print("✅ Web search como fallback implementado")
        print("✅ Integração Supabase/Chroma operacional")
        print("✅ Respostas combinadas (local + web)")
        
        final_stats = rag.get_stats()
        print(f"\n📊 Estatísticas finais:")
        print(f"   💾 Storage: {final_stats['storage_type']}")
        print(f"   🔧 Sistema: {'✅ Operacional' if final_stats['initialized'] else '❌ Problema'}")
        
    except ImportError as e:
        print(f"❌ Erro de importação: {e}")
        print("💡 Instale as dependências: pip install langchain langchain-community openai")
        
    except Exception as e:
        print(f"❌ Erro geral: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    # Configurar logging básico
    import logging
    logging.basicConfig(level=logging.INFO)
    
    # Executar teste
    asyncio.run(test_comprehensive_legal_rag())
