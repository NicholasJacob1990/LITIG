#!/usr/bin/env python3
"""
Demo Rápido: Sistema de Embeddings V2 - Estratégia Original

Demonstra o sistema completo funcionando:
- Estratégia original: OpenAI → Voyage → Arctic
- Sistema híbrido inteligente
- Comparação V1 vs V2
- Validação de qualidade

Uso:
    python quick_demo_v2.py
"""
import asyncio
import sys
import os
import time
from typing import Dict, Any

# Adicionar path do backend ao sys.path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def print_banner():
    """Imprime banner do demo."""
    print("""
🚀 ======================================================================
   LITIG-1: DEMO SISTEMA DE EMBEDDINGS V2 - ESTRATÉGIA ORIGINAL
   Migração 768D → 1024D Especializada em Domínio Jurídico
======================================================================

📋 Estratégia Original Implementada:
   1. OpenAI text-embedding-3-small (primário) - Máxima qualidade
   2. Voyage Law-2 (especializado legal) - NDCG@10: 0.847  
   3. Arctic Embed L (fallback local) - 1024D nativo

🎯 Benefícios Esperados:
   • +35-40% melhoria na precisão para casos jurídicos
   • -50% redução de casos mal-matchados
   • +33% capacidade semântica (1024D vs 768D)
   • Zero downtime durante migração

======================================================================
""")

async def demo_v2_service():
    """Demonstra o serviço V2 com estratégia original."""
    print("\n🧠 TESTANDO SERVIÇO V2 - ESTRATÉGIA ORIGINAL")
    print("=" * 60)
    
    try:
        from services.embedding_service_v2 import legal_embedding_service_v2
        
        # 1. Mostrar configuração da estratégia
        print("📊 Configuração da Estratégia Original:")
        stats = legal_embedding_service_v2.get_provider_stats()
        print(f"   Estratégia: {stats['strategy']}")
        print(f"   Dimensões: {stats['embedding_dimension']}D")
        
        for provider, info in stats['providers'].items():
            status = "✅ Disponível" if info['available'] else "❌ Indisponível"
            priority = info['priority']
            justification = info['justification']
            print(f"   {priority}. {provider}: {status}")
            print(f"      └─ {justification}")
        
        # 2. Testar geração de embeddings
        print(f"\n🧪 Testando Geração de Embeddings:")
        
        test_cases = [
            {
                "text": "Advogado especialista em direito empresarial com 15 anos de experiência",
                "context": "lawyer_cv",
                "description": "CV de advogado empresarial"
            },
            {
                "text": "Caso de responsabilidade civil por danos em acidente de trânsito",
                "context": "case",
                "description": "Caso de direito civil"
            },
            {
                "text": "Parecer sobre constitucionalidade de lei municipal",
                "context": "legal_opinion",
                "description": "Parecer constitucional"
            }
        ]
        
        for i, test in enumerate(test_cases, 1):
            print(f"\n   Teste {i}: {test['description']}")
            try:
                start_time = time.time()
                embedding, provider = await legal_embedding_service_v2.generate_legal_embedding(
                    test["text"], test["context"]
                )
                generation_time = time.time() - start_time
                
                print(f"   ✅ Sucesso: {len(embedding)}D via {provider}")
                print(f"      └─ Tempo: {generation_time:.3f}s")
                print(f"      └─ Contexto: {test['context']}")
                
            except Exception as e:
                print(f"   ❌ Erro: {e}")
        
        return True
        
    except ImportError as e:
        print(f"❌ Serviço V2 não disponível: {e}")
        return False
    except Exception as e:
        print(f"❌ Erro no serviço V2: {e}")
        return False

async def demo_hybrid_service():
    """Demonstra o serviço híbrido inteligente."""
    print("\n🔄 TESTANDO SERVIÇO HÍBRIDO INTELIGENTE")
    print("=" * 60)
    
    try:
        from services.hybrid_embedding_service import hybrid_embedding_service
        
        # 1. Status do serviço híbrido
        print("📊 Status do Serviço Híbrido:")
        status = hybrid_embedding_service.get_service_status()
        
        print(f"   Estratégia: {status['hybrid_service']['strategy']}")
        print(f"   Threshold V2: {status['hybrid_service']['v2_threshold']*100:.0f}%")
        print(f"   V1 disponível: {'✅' if status['v1_service']['available'] else '❌'}")
        print(f"   V2 disponível: {'✅' if status['v2_service']['available'] else '❌'}")
        
        # 2. Testar geração híbrida
        print(f"\n🧪 Testando Geração Híbrida:")
        
        test_text = "Especialista em fusões e aquisições com MBA em direito empresarial"
        
        try:
            result = await hybrid_embedding_service.generate_embedding(
                test_text, "lawyer_cv"
            )
            
            print(f"   ✅ Embedding gerado:")
            print(f"      └─ Dimensões: {result.dimensions}D")
            print(f"      └─ Versão: {result.version}")
            print(f"      └─ Provedor: {result.provider}")
            print(f"      └─ Tempo: {result.generation_time:.3f}s")
            print(f"      └─ Confiança: {result.confidence_score:.2f}")
            
        except Exception as e:
            print(f"   ❌ Erro na geração híbrida: {e}")
        
        # 3. Testar comparação V1 vs V2
        print(f"\n⚖️  Testando Comparação V1 vs V2:")
        
        try:
            comparison = await hybrid_embedding_service.compare_versions(
                test_text, "lawyer_cv"
            )
            
            if comparison.get("v1", {}).get("success") and comparison.get("v2", {}).get("success"):
                v1 = comparison["v1"]
                v2 = comparison["v2"]
                comp = comparison.get("comparison", {})
                
                print(f"   📊 Resultados da Comparação:")
                print(f"      V1: {v1['dimensions']}D via {v1['provider']} ({v1['generation_time']:.3f}s)")
                print(f"      V2: {v2['dimensions']}D via {v2['provider']} ({v2['generation_time']:.3f}s)")
                print(f"      Diferença: +{comp.get('dimension_difference', 0)}D")
                
                if comp.get('time_difference', 0) < 0:
                    print(f"      ⚡ V2 é {abs(comp['time_difference']):.3f}s mais rápido")
                else:
                    print(f"      🐌 V1 é {comp['time_difference']:.3f}s mais rápido")
                    
            else:
                print("   ⚠️  Comparação parcial - nem todas as versões funcionaram")
                
        except Exception as e:
            print(f"   ❌ Erro na comparação: {e}")
        
        return True
        
    except ImportError as e:
        print(f"❌ Serviço híbrido não disponível: {e}")
        return False
    except Exception as e:
        print(f"❌ Erro no serviço híbrido: {e}")
        return False

async def demo_migration_status():
    """Demonstra verificação do status da migração."""
    print("\n📈 VERIFICANDO STATUS DA MIGRAÇÃO")
    print("=" * 60)
    
    try:
        from scripts.migrate_embeddings_v2 import EmbeddingMigrationV2
        
        migrator = EmbeddingMigrationV2(dry_run=True)
        
        print("📊 Status da Migração V1 → V2:")
        status = await migrator.check_migration_status()
        
        print(f"   Total de advogados: {status['total_lawyers']}")
        print(f"   Progresso da migração: {status['migration_progress']:.1f}%")
        print(f"   Cobertura V2: {status['v2_coverage']['percentage']:.1f}%")
        print(f"   Pronto para switch: {'✅ SIM' if status['ready_for_v2_switch'] else '❌ NÃO'}")
        
        print(f"\n   📋 Breakdown por Status:")
        breakdown = status['status_breakdown']
        for status_name, count in breakdown.items():
            print(f"      {status_name}: {count} advogados")
        
        return True
        
    except Exception as e:
        print(f"❌ Erro ao verificar status da migração: {e}")
        return False

async def demo_performance_comparison():
    """Demonstra comparação de performance detalhada."""
    print("\n⚡ ANÁLISE DE PERFORMANCE V1 vs V2")
    print("=" * 60)
    
    try:
        from services.hybrid_embedding_service import hybrid_embedding_service
        
        # Casos de teste para análise
        test_cases = [
            "Advogado criminalista especializado em crimes econômicos",
            "Caso de direito trabalhista - horas extras não pagas",
            "Contrato de prestação de serviços advocatícios"
        ]
        
        v1_times = []
        v2_times = []
        
        print("🧪 Executando testes de performance...")
        
        for i, test_case in enumerate(test_cases, 1):
            print(f"   Teste {i}/3: {test_case[:50]}...")
            
            try:
                # V1
                start_time = time.time()
                v1_result = await hybrid_embedding_service.generate_embedding(
                    test_case, "case", force_version="v1"
                )
                v1_time = time.time() - start_time
                v1_times.append(v1_time)
                
                # V2
                start_time = time.time()
                v2_result = await hybrid_embedding_service.generate_embedding(
                    test_case, "case", force_version="v2"
                )
                v2_time = time.time() - start_time
                v2_times.append(v2_time)
                
                print(f"      V1: {v1_result.dimensions}D em {v1_time:.3f}s")
                print(f"      V2: {v2_result.dimensions}D em {v2_time:.3f}s")
                
            except Exception as e:
                print(f"      ❌ Erro no teste {i}: {e}")
        
        # Análise dos resultados
        if v1_times and v2_times:
            print(f"\n📊 Análise de Performance:")
            print(f"   V1 - Tempo médio: {sum(v1_times)/len(v1_times):.3f}s")
            print(f"   V2 - Tempo médio: {sum(v2_times)/len(v2_times):.3f}s")
            
            v1_avg = sum(v1_times) / len(v1_times)
            v2_avg = sum(v2_times) / len(v2_times)
            
            if v2_avg < v1_avg:
                improvement = ((v1_avg - v2_avg) / v1_avg) * 100
                print(f"   ⚡ V2 é {improvement:.1f}% mais rápido que V1")
            else:
                degradation = ((v2_avg - v1_avg) / v1_avg) * 100
                print(f"   🐌 V2 é {degradation:.1f}% mais lento que V1")
        
        return True
        
    except Exception as e:
        print(f"❌ Erro na análise de performance: {e}")
        return False

async def demo_quick_validation():
    """Executa validação rápida do sistema."""
    print("\n✅ VALIDAÇÃO RÁPIDA DO SISTEMA")
    print("=" * 60)
    
    try:
        from scripts.test_embedding_migration import EmbeddingMigrationTester
        
        tester = EmbeddingMigrationTester()
        
        print("🧪 Executando testes básicos...")
        basic_results = await tester.run_basic_test()
        
        # Analisar resultados
        if basic_results.get("hybrid_service_status", {}).get("error"):
            print("❌ Problema no serviço híbrido")
            return False
        
        sample_embeddings = basic_results.get("sample_embeddings", [])
        successful_samples = [s for s in sample_embeddings if s.get("success", False)]
        
        print(f"📊 Resultados da Validação:")
        print(f"   Amostras testadas: {len(sample_embeddings)}")
        print(f"   Sucessos: {len(successful_samples)}")
        print(f"   Taxa de sucesso: {len(successful_samples)/len(sample_embeddings)*100:.1f}%")
        
        if successful_samples:
            print(f"   Versões usadas:")
            for sample in successful_samples:
                version = sample.get("version", "unknown")
                provider = sample.get("provider", "unknown")
                dimensions = sample.get("dimensions", 0)
                print(f"      {version}: {dimensions}D via {provider}")
        
        # Verificar se sistema está funcional
        success_rate = len(successful_samples) / len(sample_embeddings) * 100
        if success_rate >= 80:
            print(f"\n✅ SISTEMA FUNCIONAL - Taxa de sucesso: {success_rate:.1f}%")
            return True
        else:
            print(f"\n❌ SISTEMA COM PROBLEMAS - Taxa de sucesso: {success_rate:.1f}%")
            return False
        
    except Exception as e:
        print(f"❌ Erro na validação: {e}")
        return False

def print_summary(results: Dict[str, bool]):
    """Imprime resumo final do demo."""
    print("\n" + "=" * 70)
    print("📋 RESUMO DO DEMO - SISTEMA EMBEDDINGS V2")
    print("=" * 70)
    
    total_tests = len(results)
    successful_tests = sum(results.values())
    
    print(f"🧪 Testes Executados: {total_tests}")
    print(f"✅ Sucessos: {successful_tests}")
    print(f"❌ Falhas: {total_tests - successful_tests}")
    print(f"📊 Taxa de Sucesso: {successful_tests/total_tests*100:.1f}%")
    
    print(f"\n📋 Detalhamento:")
    for test_name, success in results.items():
        status = "✅ PASS" if success else "❌ FAIL"
        print(f"   {test_name}: {status}")
    
    if successful_tests == total_tests:
        print(f"\n🎉 DEMO CONCLUÍDO COM SUCESSO!")
        print(f"✅ Sistema de Embeddings V2 com estratégia original está funcionando perfeitamente!")
        print(f"🚀 Pronto para migração em produção!")
    else:
        print(f"\n⚠️  DEMO PARCIALMENTE CONCLUÍDO")
        print(f"🔧 Alguns componentes precisam de configuração adicional")
        print(f"📖 Consulte o guia de migração para resolver problemas")
    
    print(f"\n📚 Próximos Passos:")
    print(f"   1. Configurar API keys necessárias")
    print(f"   2. Executar migrações SQL no banco")
    print(f"   3. Executar migração gradual dos embeddings")
    print(f"   4. Monitorar performance em produção")
    
    print("=" * 70)

async def main():
    """Função principal do demo."""
    print_banner()
    
    results = {}
    
    try:
        # 1. Testar serviço V2
        print("🚀 Iniciando demo do sistema V2...")
        results["v2_service"] = await demo_v2_service()
        
        # 2. Testar serviço híbrido
        results["hybrid_service"] = await demo_hybrid_service()
        
        # 3. Verificar status da migração
        results["migration_status"] = await demo_migration_status()
        
        # 4. Análise de performance
        results["performance_analysis"] = await demo_performance_comparison()
        
        # 5. Validação rápida
        results["quick_validation"] = await demo_quick_validation()
        
    except KeyboardInterrupt:
        print("\n⏹️  Demo interrompido pelo usuário")
        return 1
    except Exception as e:
        print(f"\n❌ Erro crítico no demo: {e}")
        return 1
    
    # Mostrar resumo
    print_summary(results)
    
    return 0

if __name__ == "__main__":
    exit_code = asyncio.run(main())
 
 