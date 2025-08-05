#!/usr/bin/env python3
"""
Demo: Embeddings Enriquecidos - CV + KPIs + Performance

Demonstra a diferença prática entre embeddings tradicionais e enriquecidos
para o matching de advogados com casos jurídicos.

Mostra:
1. Comparação lado a lado de similaridades
2. Impacto dos KPIs na relevância
3. Performance dos diferentes templates
4. Análise de qualidade dos dados
"""
import asyncio
import sys
import os
import json
import time
from datetime import datetime

# Adicionar path do backend
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

print("🎯 DEMO: EMBEDDINGS ENRIQUECIDOS")
print("=" * 60)
print("Demonstração prática da diferença entre embeddings tradicionais")
print("e embeddings enriquecidos (CV + KPIs + Performance)")
print()


async def demo_enriched_vs_standard():
    """Demonstra diferença entre embeddings padrão e enriquecidos."""
    
    print("📊 COMPARAÇÃO: PADRÃO vs ENRIQUECIDO")
    print("-" * 40)
    
    try:
        from services.embedding_service_v2 import legal_embedding_service_v2
        from services.enriched_embedding_service import LawyerProfile, enriched_embedding_service
        
        # Exemplo de advogado com dados ricos
        exemplo_advogado = LawyerProfile(
            id="demo-001",
            nome="Dr. João Silva",
            cv_text="Advogado especialista em direito empresarial com 15 anos de experiência. Formado pela USP, mestre em direito comercial, atuação em grandes corporações.",
            tags_expertise=["direito empresarial", "direito comercial", "contratos"],
            kpi={
                "taxa_sucesso": 0.92,
                "avaliacao_media": 4.8,
                "casos_30d": 15,
                "capacidade_mensal": 25
            },
            kpi_subarea={
                "direito empresarial": {"success_rate": 0.95, "total_cases": 120},
                "contratos": {"success_rate": 0.88, "total_cases": 80}
            },
            total_cases=250,
            publications=["Direito Comercial Moderno", "Contratos Empresariais", "Aspectos Jurídicos de M&A"],
            education="Graduação USP, Mestrado em Direito Comercial",
            professional_experience="15 anos em escritórios de grande porte",
            city="São Paulo",
            state="SP",
            interaction_score=0.85
        )
        
        # Texto do caso para comparação
        caso_texto = "Empresa precisa de assessoria para aquisição de outra companhia, incluindo due diligence jurídica e estruturação contratual."
        
        print(f"👨‍💼 Advogado: {exemplo_advogado.nome}")
        print(f"🎯 Especialização: {', '.join(exemplo_advogado.tags_expertise)}")
        print(f"📈 Taxa de sucesso: {exemplo_advogado.kpi['taxa_sucesso']:.1%}")
        print(f"⭐ Avaliação: {exemplo_advogado.kpi['avaliacao_media']:.1f}/5.0")
        print(f"📚 Publicações: {len(exemplo_advogado.publications)}")
        print()
        
        print(f"📋 Caso: {caso_texto}")
        print()
        
        # 1. Embedding padrão (só CV)
        print("🔄 Gerando embedding padrão (só CV)...")
        start_time = time.time()
        
        cv_embedding, cv_provider = await legal_embedding_service_v2.generate_legal_embedding(
            exemplo_advogado.cv_text, "lawyer_cv"
        )
        
        cv_time = time.time() - start_time
        print(f"✅ Embedding padrão: {len(cv_embedding)}D via {cv_provider} ({cv_time:.2f}s)")
        
        # 2. Embedding enriquecido (CV + KPIs + contexto)
        print("🔄 Gerando embedding enriquecido (CV + KPIs + performance)...")
        start_time = time.time()
        
        enriched_embedding, enriched_provider, metadata = await enriched_embedding_service.generate_enriched_embedding(
            exemplo_advogado, "balanced"
        )
        
        enriched_time = time.time() - start_time
        print(f"✅ Embedding enriquecido: {len(enriched_embedding)}D via {enriched_provider} ({enriched_time:.2f}s)")
        print(f"📝 Template usado: {metadata['template_type']}")
        print(f"📄 Documento gerado: {metadata['document_length']} caracteres")
        print()
        
        # 3. Embedding do caso
        print("🔄 Gerando embedding do caso...")
        case_embedding, case_provider = await legal_embedding_service_v2.generate_legal_embedding(
            caso_texto, "case"
        )
        print(f"✅ Embedding do caso: {len(case_embedding)}D via {case_provider}")
        print()
        
        # 4. Calcular similaridades
        from Algoritmo.utils.math_utils import cosine_similarity
        
        similarity_standard = cosine_similarity(case_embedding, cv_embedding)
        similarity_enriched = cosine_similarity(case_embedding, enriched_embedding)
        
        print("📊 RESULTADOS DA COMPARAÇÃO:")
        print(f"   📋 Similaridade padrão (só CV): {similarity_standard:.4f}")
        print(f"   🧠 Similaridade enriquecida (CV+KPIs): {similarity_enriched:.4f}")
        
        improvement = ((similarity_enriched - similarity_standard) / similarity_standard) * 100 if similarity_standard > 0 else 0
        print(f"   📈 Melhoria: {improvement:+.1f}%")
        
        if improvement > 0:
            print(f"   ✅ Embedding enriquecido é MELHOR para este match!")
        else:
            print(f"   ⚠️  Embedding padrão teve melhor performance neste caso")
        
        print()
        
        return {
            "standard_similarity": similarity_standard,
            "enriched_similarity": similarity_enriched,
            "improvement_percent": improvement,
            "metadata": metadata
        }
        
    except Exception as e:
        print(f"❌ Erro na demonstração: {e}")
        return None


async def demo_templates_comparison():
    """Demonstra diferentes templates de enriquecimento."""
    
    print("📝 COMPARAÇÃO DE TEMPLATES")
    print("-" * 40)
    
    try:
        from services.enriched_embedding_service import LawyerProfile, enriched_embedding_service
        
        # Advogado com perfil rico para testar todos os templates
        advogado_completo = LawyerProfile(
            id="demo-002",
            nome="Dra. Maria Santos",
            cv_text="Sócia em escritório de grande porte especializada em direito tributário. 20 anos de experiência, atuação em grandes multinacionais.",
            tags_expertise=["direito tributário", "planejamento tributário", "contencioso fiscal"],
            kpi={
                "taxa_sucesso": 0.89,
                "avaliacao_media": 4.9,
                "casos_30d": 8,
                "capacidade_mensal": 12
            },
            kpi_subarea={
                "direito tributário": {"success_rate": 0.91, "total_cases": 180},
                "contencioso fiscal": {"success_rate": 0.87, "total_cases": 95}
            },
            total_cases=320,
            publications=["Manual de Direito Tributário", "Planejamento Fiscal Corporativo", "Contencioso Tributário", "Reforma Tributária", "Elisão Fiscal"],
            education="Graduação PUC-SP, Mestrado em Direito Tributário USP, Especialização em Tax Law Harvard",
            professional_experience="20 anos como sócia, especialização em grandes corporações multinacionais",
            city="São Paulo",
            state="SP",
            interaction_score=0.92
        )
        
        templates = ["balanced", "performance_focused", "expertise_focused", "complete"]
        resultados = {}
        
        for template in templates:
            print(f"🔄 Testando template '{template}'...")
            start_time = time.time()
            
            embedding, provider, metadata = await enriched_embedding_service.generate_enriched_embedding(
                advogado_completo, template
            )
            
            processing_time = time.time() - start_time
            
            resultados[template] = {
                "provider": provider,
                "processing_time": processing_time,
                "document_length": metadata["document_length"],
                "metadata": metadata
            }
            
            print(f"   ✅ {len(embedding)}D via {provider} ({processing_time:.2f}s)")
            print(f"   📄 Documento: {metadata['document_length']} caracteres")
        
        print()
        print("📊 RESUMO DOS TEMPLATES:")
        for template, dados in resultados.items():
            print(f"   📝 {template:20}: {dados['document_length']:4d} chars, {dados['processing_time']:.2f}s")
        
        # Recomendar template baseado no perfil
        print()
        print("🎯 RECOMENDAÇÃO DE TEMPLATE:")
        
        data_quality_score = len([k for k, v in advogado_completo.kpi.items() if v and v != 0])
        expertise_score = len(advogado_completo.tags_expertise)
        publications_score = len(advogado_completo.publications)
        
        if data_quality_score >= 5 and advogado_completo.total_cases > 20:
            recommended = "performance_focused"
            reason = "Rico em KPIs e histórico de casos"
        elif expertise_score >= 3 and publications_score >= 3:
            recommended = "expertise_focused"
            reason = "Forte especialização e produção acadêmica"
        elif data_quality_score >= 3 and expertise_score >= 2:
            recommended = "complete"
            reason = "Perfil completo com dados abundantes"
        else:
            recommended = "balanced"
            reason = "Template padrão para perfis equilibrados"
        
        print(f"   🎯 Recomendado: '{recommended}'")
        print(f"   💡 Razão: {reason}")
        
        return resultados
        
    except Exception as e:
        print(f"❌ Erro na comparação de templates: {e}")
        return None


async def demo_data_quality_analysis():
    """Demonstra análise de qualidade dos dados."""
    
    print("📈 ANÁLISE DE QUALIDADE DOS DADOS")
    print("-" * 40)
    
    try:
        from services.enriched_embedding_service import LawyerProfile
        from Algoritmo.features.enriched_semantic import EnrichedSemanticFeatures
        from Algoritmo.models.domain import Case, Lawyer
        
        # Simular advogados com diferentes níveis de qualidade de dados
        profiles = [
            {
                "nome": "Perfil Rico",
                "profile": LawyerProfile(
                    id="quality-high", nome="Dr. Alto Qualidade",
                    cv_text="Extenso currículo com 500+ caracteres descrevendo experiência detalhada...",
                    tags_expertise=["area1", "area2", "area3", "area4"],
                    kpi={"taxa_sucesso": 0.9, "avaliacao_media": 4.8, "casos_30d": 15, "capacidade_mensal": 20, "response_time": 2},
                    kpi_subarea={"area1": {"success_rate": 0.92}},
                    total_cases=100, publications=["pub1", "pub2", "pub3", "pub4"],
                    education="Educação completa", professional_experience="Experiência rica",
                    city="São Paulo", state="SP"
                )
            },
            {
                "nome": "Perfil Médio", 
                "profile": LawyerProfile(
                    id="quality-med", nome="Dr. Médio",
                    cv_text="CV básico com informações essenciais",
                    tags_expertise=["area1", "area2"],
                    kpi={"taxa_sucesso": 0.8, "casos_30d": 5},
                    kpi_subarea={}, total_cases=30, publications=["pub1"],
                    education="", professional_experience="",
                    city="Rio de Janeiro", state="RJ"
                )
            },
            {
                "nome": "Perfil Básico",
                "profile": LawyerProfile(
                    id="quality-low", nome="Dr. Básico",
                    cv_text="CV mínimo",
                    tags_expertise=["area1"],
                    kpi={"casos_30d": 1}, kpi_subarea={},
                    total_cases=5, publications=[],
                    education="", professional_experience="",
                    city="", state=""
                )
            }
        ]
        
        print("Analisando qualidade dos dados para diferentes perfis:")
        print()
        
        for profile_info in profiles:
            nome = profile_info["nome"]
            profile = profile_info["profile"]
            
            # Usar EnrichedSemanticFeatures para calcular qualidade
            # (simulando Case e Lawyer para o cálculo)
            mock_case = type('Case', (), {})()
            mock_lawyer = type('Lawyer', (), {
                'kpi': profile.kpi,
                'tags_expertise': profile.tags_expertise,
                'cv_text': profile.cv_text,
                'total_cases': profile.total_cases,
                'publications': profile.publications
            })()
            
            feature_calc = EnrichedSemanticFeatures(mock_case, mock_lawyer)
            quality_score = feature_calc._calculate_data_quality_score()
            
            print(f"👤 {nome}:")
            print(f"   📊 Score de qualidade: {quality_score:.2f}")
            print(f"   📋 KPIs: {len(profile.kpi)} campos")
            print(f"   🎯 Especializações: {len(profile.tags_expertise)}")
            print(f"   📄 CV: {len(profile.cv_text)} caracteres")
            print(f"   📚 Publicações: {len(profile.publications)}")
            print(f"   ⚖️  Total de casos: {profile.total_cases}")
            
            # Determinar elegibilidade para embeddings enriquecidos
            if quality_score > 0.7:
                elegibilidade = "ALTO - Ideal para embeddings enriquecidos"
            elif quality_score > 0.5:
                elegibilidade = "MÉDIO - Benefício moderado"
            elif quality_score > 0.3:
                elegibilidade = "BAIXO - Benefício limitado"
            else:
                elegibilidade = "MUITO BAIXO - Usar embedding padrão"
            
            print(f"   🎯 Elegibilidade: {elegibilidade}")
            print()
        
        return True
        
    except Exception as e:
        print(f"❌ Erro na análise de qualidade: {e}")
        return False


async def demo_performance_benchmarks():
    """Demonstra benchmarks de performance."""
    
    print("⚡ BENCHMARKS DE PERFORMANCE")
    print("-" * 40)
    
    try:
        from services.embedding_service_v2 import legal_embedding_service_v2
        from services.enriched_embedding_service import LawyerProfile, enriched_embedding_service
        
        # Texto padrão para benchmark
        cv_text = "Advogado especialista em direito civil com 10 anos de experiência em contratos e responsabilidade civil."
        
        # Perfil padrão para benchmark
        profile = LawyerProfile(
            id="bench-001", nome="Dr. Benchmark",
            cv_text=cv_text,
            tags_expertise=["direito civil", "contratos"],
            kpi={"taxa_sucesso": 0.85, "avaliacao_media": 4.5},
            kpi_subarea={}, total_cases=50, publications=[],
            education="", professional_experience="",
            city="São Paulo", state="SP"
        )
        
        # Número de iterações para benchmark
        iterations = 5
        
        # Benchmark embedding padrão
        print(f"🔄 Benchmarking embedding padrão ({iterations} iterações)...")
        standard_times = []
        
        for i in range(iterations):
            start_time = time.time()
            await legal_embedding_service_v2.generate_legal_embedding(cv_text, "lawyer_cv")
            elapsed = time.time() - start_time
            standard_times.append(elapsed)
        
        avg_standard = sum(standard_times) / len(standard_times)
        print(f"   ⏱️  Tempo médio: {avg_standard:.3f}s")
        print(f"   📊 Min/Max: {min(standard_times):.3f}s / {max(standard_times):.3f}s")
        
        # Benchmark embedding enriquecido
        print(f"🔄 Benchmarking embedding enriquecido ({iterations} iterações)...")
        enriched_times = []
        
        for i in range(iterations):
            start_time = time.time()
            await enriched_embedding_service.generate_enriched_embedding(profile, "balanced")
            elapsed = time.time() - start_time
            enriched_times.append(elapsed)
        
        avg_enriched = sum(enriched_times) / len(enriched_times)
        print(f"   ⏱️  Tempo médio: {avg_enriched:.3f}s")
        print(f"   📊 Min/Max: {min(enriched_times):.3f}s / {max(enriched_times):.3f}s")
        
        # Comparação
        overhead = ((avg_enriched - avg_standard) / avg_standard) * 100
        print()
        print("📊 COMPARAÇÃO DE PERFORMANCE:")
        print(f"   📋 Padrão: {avg_standard:.3f}s")
        print(f"   🧠 Enriquecido: {avg_enriched:.3f}s")
        print(f"   📈 Overhead: {overhead:+.1f}%")
        
        if overhead < 50:
            print("   ✅ Overhead aceitável para o benefício obtido")
        else:
            print("   ⚠️  Overhead significativo - considere otimizações")
        
        return {
            "standard_avg": avg_standard,
            "enriched_avg": avg_enriched,
            "overhead_percent": overhead
        }
        
    except Exception as e:
        print(f"❌ Erro no benchmark: {e}")
        return None


async def main():
    """Função principal da demonstração."""
    
    print("🚀 Iniciando demonstração completa dos embeddings enriquecidos...")
    print()
    
    results = {}
    
    # 1. Comparação padrão vs enriquecido
    print("=" * 60)
    comparison_result = await demo_enriched_vs_standard()
    if comparison_result:
        results["comparison"] = comparison_result
    
    print()
    
    # 2. Comparação de templates
    print("=" * 60)
    templates_result = await demo_templates_comparison()
    if templates_result:
        results["templates"] = templates_result
    
    print()
    
    # 3. Análise de qualidade
    print("=" * 60)
    quality_result = await demo_data_quality_analysis()
    if quality_result:
        results["quality_analysis"] = True
    
    print()
    
    # 4. Benchmarks de performance
    print("=" * 60)
    benchmark_result = await demo_performance_benchmarks()
    if benchmark_result:
        results["benchmarks"] = benchmark_result
    
    # Relatório final
    print()
    print("🎉 RELATÓRIO FINAL DA DEMONSTRAÇÃO")
    print("=" * 60)
    
    if "comparison" in results:
        comp = results["comparison"]
        print(f"✅ Comparação realizada com sucesso")
        print(f"   📈 Melhoria observada: {comp['improvement_percent']:+.1f}%")
    
    if "templates" in results:
        print(f"✅ {len(results['templates'])} templates testados")
    
    if "quality_analysis" in results:
        print(f"✅ Análise de qualidade dos dados concluída")
    
    if "benchmarks" in results:
        bench = results["benchmarks"]
        print(f"✅ Benchmarks realizados")
        print(f"   ⚡ Overhead médio: {bench['overhead_percent']:+.1f}%")
    
    print()
    print("💡 CONCLUSÕES:")
    print("   🧠 Embeddings enriquecidos agregam contexto de performance")
    print("   🎯 Melhoria na relevância para advogados com dados ricos")
    print("   📊 Templates adaptativos otimizam para diferentes perfis")
    print("   ⚖️  A/B testing permite validação empírica dos resultados")
    
    print()
    print("🎯 PRÓXIMOS PASSOS:")
    print("   1. Executar migração com script migrate_enriched_embeddings.py")
    print("   2. Configurar A/B testing para validação em produção")
    print("   3. Monitorar métricas de qualidade e performance")
    print("   4. Iterar templates baseado em feedback real")


if __name__ == "__main__":
    asyncio.run(main())
 
 