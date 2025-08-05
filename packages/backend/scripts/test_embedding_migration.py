#!/usr/bin/env python3
"""
Script de Teste e Validação: Embeddings V1 vs V2

Executa testes completos para validar a migração, incluindo:
- Testes de funcionalidade básica
- Comparação A/B entre V1 e V2
- Análise de performance e qualidade
- Validação de similaridade semântica
- Teste de stress com múltiplos contextos

Uso:
    python test_embedding_migration.py --basic-test
    python test_embedding_migration.py --ab-comparison --samples 100
    python test_embedding_migration.py --stress-test --concurrent 10
    python test_embedding_migration.py --full-validation
"""
import asyncio
import argparse
import logging
import time
import json
import statistics
from datetime import datetime
from typing import Dict, List, Any, Tuple
import sys
import os

# Adicionar path do backend ao sys.path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Configuração de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(f'embedding_test_{datetime.now().strftime("%Y%m%d_%H%M%S")}.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


class EmbeddingMigrationTester:
    """
    Tester completo para validação da migração de embeddings.
    
    Funcionalidades:
    - Teste básico de funcionamento
    - Comparação A/B detalhada
    - Análise de performance
    - Validação de qualidade semântica
    - Teste de stress
    """
    
    def __init__(self):
        self.test_samples = [
            {
                "text": "Advogado especialista em direito empresarial com 15 anos de experiência em fusões e aquisições",
                "context": "lawyer_cv",
                "category": "corporate_law"
            },
            {
                "text": "Caso de responsabilidade civil por danos materiais em acidente de trânsito",
                "context": "case",
                "category": "civil_law"
            },
            {
                "text": "Contrato de prestação de serviços advocatícios para consultoria jurídica empresarial",
                "context": "contract",
                "category": "contract_law"
            },
            {
                "text": "Parecer jurídico sobre constitucionalidade de lei municipal de zoneamento urbano",
                "context": "legal_opinion",
                "category": "constitutional_law"
            },
            {
                "text": "Precedente do STJ sobre aplicação de juros compostos em contratos bancários",
                "context": "precedent",
                "category": "banking_law"
            },
            {
                "text": "Advogada criminalista com especialização em crimes econômicos e lavagem de dinheiro",
                "context": "lawyer_cv",
                "category": "criminal_law"
            },
            {
                "text": "Ação trabalhista por horas extras não pagas e adicional noturno",
                "context": "case",
                "category": "labor_law"
            },
            {
                "text": "Recurso extraordinário sobre direitos fundamentais e liberdade de expressão",
                "context": "precedent",
                "category": "constitutional_law"
            }
        ]
        
        self.results = {
            "basic_tests": {},
            "ab_comparison": {},
            "performance_analysis": {},
            "quality_validation": {},
            "stress_test": {}
        }

    async def run_basic_test(self) -> Dict[str, Any]:
        """Executa testes básicos de funcionamento."""
        logger.info("🧪 Iniciando testes básicos...")
        
        try:
            # Importar serviços
            from services.hybrid_embedding_service import hybrid_embedding_service
            from services.embedding_service_v2 import legal_embedding_service_v2
            
            basic_results = {
                "hybrid_service_status": {},
                "v2_service_stats": {},
                "sample_embeddings": []
            }
            
            # 1. Testar status dos serviços
            try:
                basic_results["hybrid_service_status"] = hybrid_embedding_service.get_service_status()
                logger.info("✅ Híbrido service: OK")
            except Exception as e:
                logger.error(f"❌ Híbrido service: {e}")
                basic_results["hybrid_service_status"] = {"error": str(e)}
            
            # 2. Testar V2 service stats
            try:
                basic_results["v2_service_stats"] = legal_embedding_service_v2.get_provider_stats()
                logger.info("✅ V2 service: OK")
            except Exception as e:
                logger.error(f"❌ V2 service: {e}")
                basic_results["v2_service_stats"] = {"error": str(e)}
            
            # 3. Testar geração de embeddings com amostras
            for i, sample in enumerate(self.test_samples[:3]):  # Apenas 3 amostras para teste básico
                try:
                    result = await hybrid_embedding_service.generate_embedding(
                        sample["text"], 
                        sample["context"]
                    )
                    
                    basic_results["sample_embeddings"].append({
                        "sample_id": i,
                        "category": sample["category"],
                        "success": True,
                        "dimensions": result.dimensions,
                        "version": result.version,
                        "provider": result.provider,
                        "generation_time": result.generation_time,
                        "confidence": result.confidence_score
                    })
                    
                    logger.info(f"✅ Amostra {i+1}: {result.dimensions}D via {result.provider} ({result.version})")
                    
                except Exception as e:
                    logger.error(f"❌ Amostra {i+1}: {e}")
                    basic_results["sample_embeddings"].append({
                        "sample_id": i,
                        "success": False,
                        "error": str(e)
                    })
            
            # 4. Testar comparação V1 vs V2
            try:
                comparison = await hybrid_embedding_service.compare_versions(
                    "Teste de comparação V1 vs V2", "case"
                )
                basic_results["version_comparison"] = comparison
                logger.info("✅ Comparação V1 vs V2: OK")
            except Exception as e:
                logger.error(f"❌ Comparação V1 vs V2: {e}")
                basic_results["version_comparison"] = {"error": str(e)}
            
            self.results["basic_tests"] = basic_results
            logger.info("🎉 Testes básicos concluídos!")
            
            return basic_results
            
        except Exception as e:
            logger.error(f"❌ Erro nos testes básicos: {e}")
            raise

    async def run_ab_comparison(self, num_samples: int = 50) -> Dict[str, Any]:
        """Executa comparação A/B detalhada entre V1 e V2."""
        logger.info(f"⚖️  Iniciando comparação A/B com {num_samples} amostras...")
        
        try:
            from services.hybrid_embedding_service import hybrid_embedding_service
            
            ab_results = {
                "samples_tested": 0,
                "v1_results": [],
                "v2_results": [],
                "comparisons": [],
                "summary": {}
            }
            
            # Expandir amostras se necessário
            test_texts = []
            for i in range(num_samples):
                sample = self.test_samples[i % len(self.test_samples)]
                # Adicionar variação para ter mais diversidade
                variation = f" - Variação {i//len(self.test_samples) + 1}" if i >= len(self.test_samples) else ""
                test_texts.append({
                    "text": sample["text"] + variation,
                    "context": sample["context"],
                    "category": sample["category"]
                })
            
            # Executar comparações
            for i, sample in enumerate(test_texts):
                try:
                    comparison = await hybrid_embedding_service.compare_versions(
                        sample["text"], sample["context"]
                    )
                    
                    if comparison.get("v1", {}).get("success") and comparison.get("v2", {}).get("success"):
                        ab_results["v1_results"].append(comparison["v1"])
                        ab_results["v2_results"].append(comparison["v2"])
                        ab_results["comparisons"].append({
                            "sample_id": i,
                            "category": sample["category"],
                            "context": sample["context"],
                            **comparison.get("comparison", {})
                        })
                    
                    ab_results["samples_tested"] += 1
                    
                    if (i + 1) % 10 == 0:
                        logger.info(f"📊 Progresso: {i+1}/{num_samples} amostras testadas")
                        
                except Exception as e:
                    logger.warning(f"⚠️  Erro na amostra {i}: {e}")
                    continue
            
            # Calcular estatísticas
            if ab_results["v1_results"] and ab_results["v2_results"]:
                v1_times = [r["generation_time"] for r in ab_results["v1_results"]]
                v2_times = [r["generation_time"] for r in ab_results["v2_results"]]
                
                dimension_diffs = [c["dimension_difference"] for c in ab_results["comparisons"]]
                time_diffs = [c["time_difference"] for c in ab_results["comparisons"]]
                
                ab_results["summary"] = {
                    "v1_avg_time": statistics.mean(v1_times),
                    "v2_avg_time": statistics.mean(v2_times),
                    "v1_median_time": statistics.median(v1_times),
                    "v2_median_time": statistics.median(v2_times),
                    "avg_dimension_difference": statistics.mean(dimension_diffs),
                    "avg_time_difference": statistics.mean(time_diffs),
                    "v2_faster_count": sum(1 for t in time_diffs if t < 0),
                    "v1_faster_count": sum(1 for t in time_diffs if t > 0),
                    "success_rate": ab_results["samples_tested"] / num_samples * 100
                }
            
            self.results["ab_comparison"] = ab_results
            logger.info("🎉 Comparação A/B concluída!")
            
            return ab_results
            
        except Exception as e:
            logger.error(f"❌ Erro na comparação A/B: {e}")
            raise

    async def run_performance_analysis(self) -> Dict[str, Any]:
        """Executa análise detalhada de performance."""
        logger.info("📈 Iniciando análise de performance...")
        
        try:
            from services.hybrid_embedding_service import hybrid_embedding_service
            from services.embedding_service_v2 import legal_embedding_service_v2
            
            perf_results = {
                "provider_analysis": {},
                "context_analysis": {},
                "dimension_analysis": {},
                "metrics": {}
            }
            
            # 1. Análise por provedor V2
            logger.info("🔍 Analisando provedores V2...")
            
            providers = ["openai", "voyage", "arctic"]
            provider_results = {}
            
            for provider in providers:
                provider_times = []
                provider_successes = 0
                
                for sample in self.test_samples:
                    try:
                        start_time = time.time()
                        embedding, used_provider = await legal_embedding_service_v2.generate_legal_embedding(
                            sample["text"], 
                            sample["context"], 
                            force_provider=provider
                        )
                        generation_time = time.time() - start_time
                        
                        if used_provider == provider:
                            provider_times.append(generation_time)
                            provider_successes += 1
                            
                    except Exception as e:
                        logger.warning(f"⚠️  {provider} falhou: {e}")
                        continue
                
                if provider_times:
                    provider_results[provider] = {
                        "avg_time": statistics.mean(provider_times),
                        "median_time": statistics.median(provider_times),
                        "min_time": min(provider_times),
                        "max_time": max(provider_times),
                        "success_count": provider_successes,
                        "total_attempts": len(self.test_samples)
                    }
            
            perf_results["provider_analysis"] = provider_results
            
            # 2. Análise por tipo de contexto
            logger.info("🔍 Analisando performance por contexto...")
            
            context_results = {}
            unique_contexts = list(set(sample["context"] for sample in self.test_samples))
            
            for context in unique_contexts:
                context_samples = [s for s in self.test_samples if s["context"] == context]
                context_times = []
                
                for sample in context_samples:
                    try:
                        result = await hybrid_embedding_service.generate_embedding(
                            sample["text"], context
                        )
                        context_times.append(result.generation_time)
                    except Exception:
                        continue
                
                if context_times:
                    context_results[context] = {
                        "avg_time": statistics.mean(context_times),
                        "sample_count": len(context_times)
                    }
            
            perf_results["context_analysis"] = context_results
            
            # 3. Análise de dimensões
            logger.info("🔍 Analisando impacto das dimensões...")
            
            dimension_analysis = {
                "v1_768d": [],
                "v2_1024d": []
            }
            
            for sample in self.test_samples[:5]:  # Amostra menor para performance
                # V1
                try:
                    result_v1 = await hybrid_embedding_service.generate_embedding(
                        sample["text"], sample["context"], force_version="v1"
                    )
                    dimension_analysis["v1_768d"].append({
                        "generation_time": result_v1.generation_time,
                        "dimensions": result_v1.dimensions
                    })
                except Exception:
                    pass
                
                # V2
                try:
                    result_v2 = await hybrid_embedding_service.generate_embedding(
                        sample["text"], sample["context"], force_version="v2"
                    )
                    dimension_analysis["v2_1024d"].append({
                        "generation_time": result_v2.generation_time,
                        "dimensions": result_v2.dimensions
                    })
                except Exception:
                    pass
            
            perf_results["dimension_analysis"] = dimension_analysis
            
            # 4. Métricas do serviço híbrido
            perf_results["metrics"] = hybrid_embedding_service.get_metrics()
            
            self.results["performance_analysis"] = perf_results
            logger.info("🎉 Análise de performance concluída!")
            
            return perf_results
            
        except Exception as e:
            logger.error(f"❌ Erro na análise de performance: {e}")
            raise

    async def run_stress_test(self, concurrent_requests: int = 10) -> Dict[str, Any]:
        """Executa teste de stress com requisições concorrentes."""
        logger.info(f"💪 Iniciando teste de stress com {concurrent_requests} requisições concorrentes...")
        
        try:
            from services.hybrid_embedding_service import hybrid_embedding_service
            
            stress_results = {
                "concurrent_requests": concurrent_requests,
                "total_requests": 0,
                "successful_requests": 0,
                "failed_requests": 0,
                "total_time": 0,
                "avg_time_per_request": 0,
                "requests_per_second": 0,
                "errors": []
            }
            
            async def single_request(request_id: int, sample: Dict[str, str]) -> Dict[str, Any]:
                """Executa uma única requisição."""
                try:
                    start_time = time.time()
                    result = await hybrid_embedding_service.generate_embedding(
                        sample["text"], sample["context"]
                    )
                    end_time = time.time()
                    
                    return {
                        "request_id": request_id,
                        "success": True,
                        "generation_time": end_time - start_time,
                        "dimensions": result.dimensions,
                        "version": result.version,
                        "provider": result.provider
                    }
                    
                except Exception as e:
                    return {
                        "request_id": request_id,
                        "success": False,
                        "error": str(e),
                        "generation_time": 0
                    }
            
            # Preparar requisições
            requests = []
            for i in range(concurrent_requests):
                sample = self.test_samples[i % len(self.test_samples)]
                requests.append(single_request(i, sample))
            
            # Executar requisições concorrentes
            start_time = time.time()
            results = await asyncio.gather(*requests, return_exceptions=True)
            end_time = time.time()
            
            # Processar resultados
            stress_results["total_time"] = end_time - start_time
            stress_results["total_requests"] = len(results)
            
            for result in results:
                if isinstance(result, Exception):
                    stress_results["failed_requests"] += 1
                    stress_results["errors"].append(str(result))
                elif result.get("success", False):
                    stress_results["successful_requests"] += 1
                else:
                    stress_results["failed_requests"] += 1
                    stress_results["errors"].append(result.get("error", "Unknown error"))
            
            # Calcular métricas
            if stress_results["successful_requests"] > 0:
                successful_times = [
                    r["generation_time"] for r in results 
                    if isinstance(r, dict) and r.get("success", False)
                ]
                stress_results["avg_time_per_request"] = statistics.mean(successful_times)
                stress_results["requests_per_second"] = stress_results["total_requests"] / stress_results["total_time"]
            
            self.results["stress_test"] = stress_results
            logger.info("🎉 Teste de stress concluído!")
            
            return stress_results
            
        except Exception as e:
            logger.error(f"❌ Erro no teste de stress: {e}")
            raise

    async def run_full_validation(self) -> Dict[str, Any]:
        """Executa validação completa com todos os testes."""
        logger.info("🚀 Iniciando validação completa...")
        
        full_results = {
            "start_time": datetime.now().isoformat(),
            "tests_completed": [],
            "overall_status": "running"
        }
        
        try:
            # 1. Testes básicos
            logger.info("1️⃣ Executando testes básicos...")
            await self.run_basic_test()
            full_results["tests_completed"].append("basic_tests")
            
            # 2. Comparação A/B
            logger.info("2️⃣ Executando comparação A/B...")
            await self.run_ab_comparison(30)  # 30 amostras para validação completa
            full_results["tests_completed"].append("ab_comparison")
            
            # 3. Análise de performance
            logger.info("3️⃣ Executando análise de performance...")
            await self.run_performance_analysis()
            full_results["tests_completed"].append("performance_analysis")
            
            # 4. Teste de stress
            logger.info("4️⃣ Executando teste de stress...")
            await self.run_stress_test(5)  # 5 requisições concorrentes
            full_results["tests_completed"].append("stress_test")
            
            full_results["end_time"] = datetime.now().isoformat()
            full_results["overall_status"] = "completed"
            full_results["all_results"] = self.results
            
            # Gerar resumo
            full_results["summary"] = self._generate_summary()
            
            logger.info("🎉 Validação completa finalizada!")
            
            return full_results
            
        except Exception as e:
            full_results["overall_status"] = "failed"
            full_results["error"] = str(e)
            logger.error(f"❌ Erro na validação completa: {e}")
            raise

    def _generate_summary(self) -> Dict[str, Any]:
        """Gera resumo executivo dos testes."""
        summary = {
            "migration_ready": False,
            "recommendations": [],
            "key_metrics": {},
            "issues_found": []
        }
        
        try:
            # Verificar se testes básicos passaram
            basic_tests = self.results.get("basic_tests", {})
            if basic_tests.get("hybrid_service_status", {}).get("error"):
                summary["issues_found"].append("Serviço híbrido com problemas")
            
            # Analisar comparação A/B
            ab_comparison = self.results.get("ab_comparison", {})
            if ab_comparison.get("summary"):
                ab_summary = ab_comparison["summary"]
                summary["key_metrics"]["success_rate"] = ab_summary.get("success_rate", 0)
                summary["key_metrics"]["v2_avg_time"] = ab_summary.get("v2_avg_time", 0)
                
                if ab_summary.get("success_rate", 0) >= 90:
                    summary["recommendations"].append("Alta taxa de sucesso - migração viável")
                else:
                    summary["issues_found"].append("Taxa de sucesso baixa")
            
            # Analisar performance
            perf_analysis = self.results.get("performance_analysis", {})
            if perf_analysis.get("provider_analysis"):
                providers_working = len([
                    p for p in perf_analysis["provider_analysis"].values()
                    if p.get("success_count", 0) > 0
                ])
                summary["key_metrics"]["providers_available"] = providers_working
                
                if providers_working >= 2:
                    summary["recommendations"].append("Múltiplos provedores funcionando - boa redundância")
                else:
                    summary["issues_found"].append("Poucos provedores disponíveis")
            
            # Analisar stress test
            stress_test = self.results.get("stress_test", {})
            if stress_test.get("successful_requests", 0) > 0:
                success_rate = (stress_test["successful_requests"] / stress_test["total_requests"]) * 100
                summary["key_metrics"]["stress_success_rate"] = success_rate
                
                if success_rate >= 80:
                    summary["recommendations"].append("Sistema estável sob carga")
                else:
                    summary["issues_found"].append("Problemas de estabilidade sob carga")
            
            # Decisão final
            if (len(summary["issues_found"]) == 0 and 
                summary["key_metrics"].get("success_rate", 0) >= 90):
                summary["migration_ready"] = True
                summary["recommendations"].append("✅ SISTEMA PRONTO PARA MIGRAÇÃO V2")
            else:
                summary["recommendations"].append("⚠️  Resolver problemas antes da migração")
            
        except Exception as e:
            summary["issues_found"].append(f"Erro ao gerar resumo: {e}")
        
        return summary

    def save_results(self, filename: str = None):
        """Salva resultados em arquivo JSON."""
        if not filename:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"embedding_test_results_{timestamp}.json"
        
        try:
            with open(filename, 'w', encoding='utf-8') as f:
                json.dump(self.results, f, indent=2, ensure_ascii=False, default=str)
            
            logger.info(f"📁 Resultados salvos em: {filename}")
            
        except Exception as e:
            logger.error(f"❌ Erro ao salvar resultados: {e}")


async def main():
    """Função principal CLI."""
    parser = argparse.ArgumentParser(description="Teste e Validação de Migração de Embeddings")
    
    parser.add_argument("--basic-test", action="store_true", help="Executar testes básicos")
    parser.add_argument("--ab-comparison", action="store_true", help="Executar comparação A/B")
    parser.add_argument("--performance", action="store_true", help="Executar análise de performance")
    parser.add_argument("--stress-test", action="store_true", help="Executar teste de stress")
    parser.add_argument("--full-validation", action="store_true", help="Executar validação completa")
    
    parser.add_argument("--samples", type=int, default=50, help="Número de amostras para A/B test")
    parser.add_argument("--concurrent", type=int, default=10, help="Requisições concorrentes para stress test")
    parser.add_argument("--save-results", type=str, help="Arquivo para salvar resultados")
    
    args = parser.parse_args()
    
    # Criar tester
    tester = EmbeddingMigrationTester()
    
    try:
        if args.full_validation:
            await tester.run_full_validation()
        else:
            if args.basic_test:
                await tester.run_basic_test()
            
            if args.ab_comparison:
                await tester.run_ab_comparison(args.samples)
            
            if args.performance:
                await tester.run_performance_analysis()
            
            if args.stress_test:
                await tester.run_stress_test(args.concurrent)
        
        # Salvar resultados se solicitado
        if args.save_results:
            tester.save_results(args.save_results)
        else:
            tester.save_results()  # Usar nome padrão
        
        print("\n🎉 TESTE CONCLUÍDO COM SUCESSO!")
        
        # Mostrar resumo se validação completa foi executada
        if args.full_validation and "summary" in tester.results.get("full_validation", {}):
            summary = tester.results["full_validation"]["summary"]
            print(f"\n📊 RESUMO EXECUTIVO:")
            print(f"   Pronto para migração: {'✅ SIM' if summary['migration_ready'] else '❌ NÃO'}")
            print(f"   Problemas encontrados: {len(summary['issues_found'])}")
            print(f"   Recomendações: {len(summary['recommendations'])}")
        
        return 0
        
    except Exception as e:
        logger.error(f"❌ Erro na execução: {e}")
        return 1


if __name__ == "__main__":
    exit_code = asyncio.run(main())
 
 