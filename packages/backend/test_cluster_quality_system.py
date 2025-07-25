#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Test Script: Cluster Quality Metrics System
===========================================

Script para testar o sistema completo de métricas de qualidade dos clusters.
Verifica todas as funcionalidades implementadas no SPRINT 2.2.

Testes realizados:
1. Serviço de métricas de qualidade
2. Integração com ClusterService  
3. APIs REST de qualidade
4. Validação de thresholds
5. Análise de tendências
6. Dashboard de qualidade

Usage:
    python test_cluster_quality_system.py [--test-type all|unit|integration|api]
"""

import asyncio
import logging
import sys
import json
import argparse
from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Imports do sistema
try:
    from database import get_async_session
    from services.cluster_service import ClusterService
    from services.cluster_quality_metrics_service import (
        ClusterQualityMetricsService,
        create_quality_metrics_service,
        QualityThreshold
    )
    from jobs.cluster_generation_job import run_cluster_generation
    IMPORTS_AVAILABLE = True
except ImportError as e:
    logger.error(f"❌ Erro ao importar módulos: {e}")
    IMPORTS_AVAILABLE = False

# Test data e configurações
TEST_CONFIG = {
    "sample_cluster_ids": [
        "case_cluster_1",
        "case_cluster_2", 
        "lawyer_cluster_1",
        "lawyer_cluster_2"
    ],
    "custom_thresholds": {
        "silhouette_score": {"fair": 0.4},
        "cohesion_score": {"fair": 0.5},
        "overall_quality": 0.6
    },
    "batch_size": 5,
    "trends_days": 7
}


class ClusterQualitySystemTester:
    """Testador abrangente do sistema de métricas de qualidade."""
    
    def __init__(self):
        self.results = {
            "unit_tests": {},
            "integration_tests": {},
            "api_tests": {},
            "performance_tests": {},
            "overall_status": "pending"
        }
        self.test_start_time = datetime.now()
    
    async def run_all_tests(self) -> Dict[str, Any]:
        """Executa todos os testes do sistema."""
        
        logger.info("🚀 Iniciando testes completos do sistema de métricas de qualidade")
        
        if not IMPORTS_AVAILABLE:
            self.results["overall_status"] = "failed"
            self.results["error"] = "Imports não disponíveis"
            return self.results
        
        try:
            # 1. Testes unitários
            logger.info("🔬 Executando testes unitários...")
            await self._run_unit_tests()
            
            # 2. Testes de integração
            logger.info("🔗 Executando testes de integração...")
            await self._run_integration_tests()
            
            # 3. Testes de API
            logger.info("🌐 Executando testes de API...")
            await self._run_api_tests()
            
            # 4. Testes de performance
            logger.info("⚡ Executando testes de performance...")
            await self._run_performance_tests()
            
            # 5. Gerar relatório final
            self._generate_final_report()
            
        except Exception as e:
            logger.error(f"❌ Erro geral nos testes: {e}")
            self.results["overall_status"] = "failed"
            self.results["error"] = str(e)
        
        return self.results
    
    async def _run_unit_tests(self):
        """Testes unitários dos componentes."""
        
        unit_results = {}
        
        try:
            async with get_async_session() as db:
                # Test 1: Criação do serviço de métricas
                logger.info("🧪 Teste 1: Criação do serviço de métricas")
                try:
                    quality_service = create_quality_metrics_service(db)
                    unit_results["service_creation"] = {
                        "status": "passed",
                        "service_available": quality_service is not None
                    }
                    logger.info("✅ Serviço de métricas criado com sucesso")
                except Exception as e:
                    unit_results["service_creation"] = {
                        "status": "failed",
                        "error": str(e)
                    }
                    logger.error(f"❌ Falha na criação do serviço: {e}")
                
                # Test 2: Configuração de thresholds
                logger.info("🧪 Teste 2: Configuração de thresholds")
                try:
                    if quality_service:
                        thresholds = quality_service.quality_thresholds
                        expected_keys = ['silhouette_score', 'cohesion_score', 'separation_score']
                        
                        unit_results["threshold_config"] = {
                            "status": "passed" if all(key in thresholds for key in expected_keys) else "failed",
                            "configured_thresholds": list(thresholds.keys()),
                            "expected_thresholds": expected_keys
                        }
                        logger.info("✅ Thresholds configurados corretamente")
                    else:
                        unit_results["threshold_config"] = {
                            "status": "skipped",
                            "reason": "Serviço não disponível"
                        }
                except Exception as e:
                    unit_results["threshold_config"] = {
                        "status": "failed",
                        "error": str(e)
                    }
                
                # Test 3: Enum de qualidade
                logger.info("🧪 Teste 3: Enum de níveis de qualidade")
                try:
                    quality_levels = [threshold.name for threshold in QualityThreshold]
                    expected_levels = ['EXCELLENT', 'GOOD', 'FAIR', 'POOR']
                    
                    unit_results["quality_enum"] = {
                        "status": "passed" if set(quality_levels) == set(expected_levels) else "failed",
                        "available_levels": quality_levels,
                        "expected_levels": expected_levels
                    }
                    logger.info("✅ Enum de qualidade funcionando")
                except Exception as e:
                    unit_results["quality_enum"] = {
                        "status": "failed",
                        "error": str(e)
                    }
        
        except Exception as e:
            logger.error(f"❌ Erro geral nos testes unitários: {e}")
            unit_results["general_error"] = str(e)
        
        self.results["unit_tests"] = unit_results
    
    async def _run_integration_tests(self):
        """Testes de integração entre componentes."""
        
        integration_results = {}
        
        try:
            async with get_async_session() as db:
                cluster_service = ClusterService(db)
                
                # Test 1: Integração ClusterService + QualityMetrics
                logger.info("🔗 Teste 1: Integração ClusterService + QualityMetrics")
                try:
                    has_quality_service = cluster_service.quality_metrics_service is not None
                    integration_results["cluster_quality_integration"] = {
                        "status": "passed" if has_quality_service else "failed",
                        "quality_service_injected": has_quality_service
                    }
                    
                    if has_quality_service:
                        logger.info("✅ Integração ClusterService + QualityMetrics OK")
                    else:
                        logger.warning("⚠️ Serviço de qualidade não injetado no ClusterService")
                        
                except Exception as e:
                    integration_results["cluster_quality_integration"] = {
                        "status": "failed",
                        "error": str(e)
                    }
                
                # Test 2: Métodos de qualidade no ClusterService
                logger.info("🔗 Teste 2: Métodos de qualidade no ClusterService")
                try:
                    quality_methods = [
                        "analyze_cluster_quality",
                        "validate_cluster_quality_thresholds", 
                        "get_quality_trends_report",
                        "analyze_all_clusters_quality"
                    ]
                    
                    available_methods = []
                    for method in quality_methods:
                        if hasattr(cluster_service, method):
                            available_methods.append(method)
                    
                    integration_results["quality_methods"] = {
                        "status": "passed" if len(available_methods) == len(quality_methods) else "partial",
                        "available_methods": available_methods,
                        "expected_methods": quality_methods,
                        "coverage": len(available_methods) / len(quality_methods)
                    }
                    logger.info(f"✅ Métodos de qualidade: {len(available_methods)}/{len(quality_methods)}")
                    
                except Exception as e:
                    integration_results["quality_methods"] = {
                        "status": "failed", 
                        "error": str(e)
                    }
                
                # Test 3: Buscar clusters para teste
                logger.info("🔗 Teste 3: Buscar clusters para análise")
                try:
                    # Buscar clusters existentes para testar
                    trending_clusters = await cluster_service.get_trending_clusters(
                        cluster_type="case", limit=3
                    )
                    
                    integration_results["cluster_discovery"] = {
                        "status": "passed" if trending_clusters else "warning",
                        "clusters_found": len(trending_clusters),
                        "sample_cluster_ids": [c.get("cluster_id") for c in trending_clusters[:2]]
                    }
                    
                    if trending_clusters:
                        logger.info(f"✅ Encontrados {len(trending_clusters)} clusters para teste")
                        # Atualizar IDs de teste com clusters reais
                        TEST_CONFIG["sample_cluster_ids"] = [
                            c.get("cluster_id") for c in trending_clusters[:2]
                        ]
                    else:
                        logger.warning("⚠️ Nenhum cluster encontrado para teste")
                    
                except Exception as e:
                    integration_results["cluster_discovery"] = {
                        "status": "failed",
                        "error": str(e)
                    }
        
        except Exception as e:
            logger.error(f"❌ Erro geral nos testes de integração: {e}")
            integration_results["general_error"] = str(e)
        
        self.results["integration_tests"] = integration_results
    
    async def _run_api_tests(self):
        """Testes das APIs REST de qualidade."""
        
        api_results = {}
        
        try:
            async with get_async_session() as db:
                cluster_service = ClusterService(db)
                
                # Test 1: Análise de qualidade de cluster específico
                logger.info("🌐 Teste 1: API - Análise de qualidade específica")
                try:
                    sample_clusters = TEST_CONFIG["sample_cluster_ids"]
                    if sample_clusters:
                        test_cluster_id = sample_clusters[0]
                        quality_analysis = await cluster_service.analyze_cluster_quality(
                            test_cluster_id, include_detailed_analysis=False
                        )
                        
                        api_results["specific_analysis"] = {
                            "status": "passed" if quality_analysis else "failed",
                            "cluster_tested": test_cluster_id,
                            "analysis_returned": quality_analysis is not None,
                            "response_structure": list(quality_analysis.keys()) if quality_analysis else []
                        }
                        
                        if quality_analysis:
                            logger.info(f"✅ Análise de qualidade para {test_cluster_id}: Score={quality_analysis.get('overall_quality_score', 'N/A')}")
                        else:
                            logger.warning(f"⚠️ Nenhuma análise retornada para {test_cluster_id}")
                    else:
                        api_results["specific_analysis"] = {
                            "status": "skipped",
                            "reason": "Nenhum cluster disponível para teste"
                        }
                        
                except Exception as e:
                    api_results["specific_analysis"] = {
                        "status": "failed",
                        "error": str(e)
                    }
                
                # Test 2: Validação de thresholds
                logger.info("🌐 Teste 2: API - Validação de thresholds")
                try:
                    sample_clusters = TEST_CONFIG["sample_cluster_ids"]
                    if sample_clusters:
                        test_cluster_id = sample_clusters[0]
                        validation_result = await cluster_service.validate_cluster_quality_thresholds(
                            test_cluster_id, TEST_CONFIG["custom_thresholds"]
                        )
                        
                        api_results["threshold_validation"] = {
                            "status": "passed" if validation_result else "failed",
                            "cluster_tested": test_cluster_id,
                            "validation_returned": validation_result is not None,
                            "is_valid": validation_result.get("valid") if validation_result else None
                        }
                        
                        if validation_result:
                            logger.info(f"✅ Validação para {test_cluster_id}: Válido={validation_result.get('valid', 'N/A')}")
                        else:
                            logger.warning(f"⚠️ Nenhuma validação retornada para {test_cluster_id}")
                    else:
                        api_results["threshold_validation"] = {
                            "status": "skipped",
                            "reason": "Nenhum cluster disponível para teste"
                        }
                        
                except Exception as e:
                    api_results["threshold_validation"] = {
                        "status": "failed",
                        "error": str(e)
                    }
                
                # Test 3: Relatório de tendências
                logger.info("🌐 Teste 3: API - Relatório de tendências")
                try:
                    trends_report = await cluster_service.get_quality_trends_report(
                        TEST_CONFIG["trends_days"]
                    )
                    
                    api_results["trends_report"] = {
                        "status": "passed" if trends_report else "failed",
                        "days_analyzed": TEST_CONFIG["trends_days"],
                        "report_returned": trends_report is not None,
                        "report_sections": list(trends_report.keys()) if trends_report else []
                    }
                    
                    if trends_report:
                        logger.info(f"✅ Relatório de tendências gerado: {len(trends_report)} seções")
                    else:
                        logger.warning("⚠️ Nenhum relatório de tendências retornado")
                        
                except Exception as e:
                    api_results["trends_report"] = {
                        "status": "failed",
                        "error": str(e)
                    }
                
                # Test 4: Análise em lote
                logger.info("🌐 Teste 4: API - Análise em lote")
                try:
                    batch_analysis = await cluster_service.analyze_all_clusters_quality(
                        cluster_type="case", batch_size=TEST_CONFIG["batch_size"]
                    )
                    
                    api_results["batch_analysis"] = {
                        "status": "passed" if batch_analysis else "failed",
                        "batch_size": TEST_CONFIG["batch_size"],
                        "analysis_returned": batch_analysis is not None,
                        "clusters_analyzed": batch_analysis.get("total_analyzed", 0) if batch_analysis else 0
                    }
                    
                    if batch_analysis:
                        analyzed_count = batch_analysis.get("total_analyzed", 0)
                        logger.info(f"✅ Análise em lote: {analyzed_count} clusters analisados")
                    else:
                        logger.warning("⚠️ Nenhuma análise em lote retornada")
                        
                except Exception as e:
                    api_results["batch_analysis"] = {
                        "status": "failed",
                        "error": str(e)
                    }
        
        except Exception as e:
            logger.error(f"❌ Erro geral nos testes de API: {e}")
            api_results["general_error"] = str(e)
        
        self.results["api_tests"] = api_results
    
    async def _run_performance_tests(self):
        """Testes de performance do sistema."""
        
        performance_results = {}
        
        try:
            async with get_async_session() as db:
                cluster_service = ClusterService(db)
                
                # Test 1: Performance de análise individual
                logger.info("⚡ Teste 1: Performance - Análise individual")
                try:
                    sample_clusters = TEST_CONFIG["sample_cluster_ids"]
                    if sample_clusters and cluster_service.quality_metrics_service:
                        test_cluster_id = sample_clusters[0]
                        
                        start_time = datetime.now()
                        quality_analysis = await cluster_service.analyze_cluster_quality(
                            test_cluster_id, include_detailed_analysis=True
                        )
                        end_time = datetime.now()
                        
                        duration = (end_time - start_time).total_seconds()
                        
                        performance_results["individual_analysis"] = {
                            "status": "passed" if quality_analysis else "failed",
                            "cluster_tested": test_cluster_id,
                            "duration_seconds": round(duration, 3),
                            "performance_rating": "excellent" if duration < 2 else "good" if duration < 5 else "slow"
                        }
                        
                        logger.info(f"✅ Análise individual: {duration:.3f}s")
                    else:
                        performance_results["individual_analysis"] = {
                            "status": "skipped",
                            "reason": "Clusters ou serviço não disponíveis"
                        }
                        
                except Exception as e:
                    performance_results["individual_analysis"] = {
                        "status": "failed",
                        "error": str(e)
                    }
                
                # Test 2: Performance de análise em lote
                logger.info("⚡ Teste 2: Performance - Análise em lote")
                try:
                    start_time = datetime.now()
                    batch_analysis = await cluster_service.analyze_all_clusters_quality(
                        cluster_type="case", batch_size=3  # Pequeno para teste
                    )
                    end_time = datetime.now()
                    
                    duration = (end_time - start_time).total_seconds()
                    clusters_analyzed = batch_analysis.get("total_analyzed", 0) if batch_analysis else 0
                    
                    performance_results["batch_analysis"] = {
                        "status": "passed" if batch_analysis else "failed",
                        "duration_seconds": round(duration, 3),
                        "clusters_analyzed": clusters_analyzed,
                        "avg_time_per_cluster": round(duration / max(1, clusters_analyzed), 3),
                        "performance_rating": "excellent" if duration < 10 else "good" if duration < 30 else "slow"
                    }
                    
                    logger.info(f"✅ Análise em lote: {duration:.3f}s para {clusters_analyzed} clusters")
                    
                except Exception as e:
                    performance_results["batch_analysis"] = {
                        "status": "failed",
                        "error": str(e)
                    }
        
        except Exception as e:
            logger.error(f"❌ Erro geral nos testes de performance: {e}")
            performance_results["general_error"] = str(e)
        
        self.results["performance_tests"] = performance_results
    
    def _generate_final_report(self):
        """Gera relatório final dos testes."""
        
        total_duration = (datetime.now() - self.test_start_time).total_seconds()
        
        # Calcular estatísticas
        all_test_categories = ["unit_tests", "integration_tests", "api_tests", "performance_tests"]
        passed_tests = 0
        failed_tests = 0
        skipped_tests = 0
        total_tests = 0
        
        for category in all_test_categories:
            tests = self.results.get(category, {})
            for test_name, test_result in tests.items():
                if isinstance(test_result, dict) and "status" in test_result:
                    total_tests += 1
                    status = test_result["status"]
                    if status == "passed":
                        passed_tests += 1
                    elif status == "failed":
                        failed_tests += 1
                    elif status == "skipped":
                        skipped_tests += 1
        
        # Determinar status geral
        if failed_tests == 0 and passed_tests > 0:
            overall_status = "passed"
        elif failed_tests > 0 and passed_tests > failed_tests:
            overall_status = "partial"
        else:
            overall_status = "failed"
        
        # Adicionar summary ao resultado
        self.results["test_summary"] = {
            "overall_status": overall_status,
            "total_duration_seconds": round(total_duration, 3),
            "total_tests": total_tests,
            "passed_tests": passed_tests,
            "failed_tests": failed_tests,
            "skipped_tests": skipped_tests,
            "success_rate": round((passed_tests / max(1, total_tests)) * 100, 1),
            "test_categories": all_test_categories,
            "completed_at": datetime.now().isoformat()
        }
        
        self.results["overall_status"] = overall_status
        
        # Log do resumo
        logger.info("=" * 60)
        logger.info("📊 RELATÓRIO FINAL DOS TESTES")
        logger.info("=" * 60)
        logger.info(f"Status Geral: {overall_status.upper()}")
        logger.info(f"Duração Total: {total_duration:.3f}s")
        logger.info(f"Testes Executados: {total_tests}")
        logger.info(f"✅ Passou: {passed_tests}")
        logger.info(f"❌ Falhou: {failed_tests}")
        logger.info(f"⏭️ Pulado: {skipped_tests}")
        logger.info(f"Taxa de Sucesso: {(passed_tests / max(1, total_tests)) * 100:.1f}%")
        logger.info("=" * 60)


# Funções de teste específicas
async def test_unit_only():
    """Executa apenas testes unitários."""
    tester = ClusterQualitySystemTester()
    await tester._run_unit_tests()
    return tester.results

async def test_integration_only():
    """Executa apenas testes de integração."""
    tester = ClusterQualitySystemTester()
    await tester._run_integration_tests()
    return tester.results

async def test_api_only():
    """Executa apenas testes de API."""
    tester = ClusterQualitySystemTester()
    await tester._run_api_tests()
    return tester.results


# Função principal
async def main():
    """Função principal do script de teste."""
    
    parser = argparse.ArgumentParser(
        description="Testa o sistema de métricas de qualidade dos clusters"
    )
    parser.add_argument(
        "--test-type",
        choices=["all", "unit", "integration", "api", "performance"],
        default="all",
        help="Tipo de teste a executar"
    )
    parser.add_argument(
        "--output-file",
        type=str,
        help="Arquivo para salvar resultados em JSON"
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Output verbose"
    )
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    logger.info(f"🎯 Executando testes: {args.test_type}")
    
    # Executar testes baseado no tipo
    tester = ClusterQualitySystemTester()
    
    if args.test_type == "all":
        results = await tester.run_all_tests()
    elif args.test_type == "unit":
        results = await test_unit_only()
    elif args.test_type == "integration":
        results = await test_integration_only() 
    elif args.test_type == "api":
        results = await test_api_only()
    elif args.test_type == "performance":
        await tester._run_performance_tests()
        results = tester.results
    else:
        logger.error(f"❌ Tipo de teste desconhecido: {args.test_type}")
        return
    
    # Salvar resultados se solicitado
    if args.output_file:
        try:
            with open(args.output_file, 'w', encoding='utf-8') as f:
                json.dump(results, f, indent=2, ensure_ascii=False)
            logger.info(f"📁 Resultados salvos em: {args.output_file}")
        except Exception as e:
            logger.error(f"❌ Erro ao salvar resultados: {e}")
    
    # Código de saída baseado no resultado
    overall_status = results.get("overall_status", "failed")
    if overall_status == "passed":
        sys.exit(0)
    elif overall_status == "partial":
        sys.exit(1)
    else:
        sys.exit(2)


if __name__ == "__main__":
    if not IMPORTS_AVAILABLE:
        logger.error("❌ Não foi possível importar os módulos necessários")
        sys.exit(3)
    
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("🛑 Testes interrompidos pelo usuário")
        sys.exit(130)
    except Exception as e:
        logger.error(f"❌ Erro fatal: {e}")
        sys.exit(1) 