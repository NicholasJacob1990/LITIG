#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Cluster Quality Metrics APIs
============================

APIs REST específicas para métricas de qualidade dos clusters.
Endpoints especializados para análise, validação e monitoramento de qualidade.

Endpoints:
- GET /api/clusters/quality/{cluster_id} - Análise de qualidade específica
- POST /api/clusters/quality/validate - Validação de thresholds
- GET /api/clusters/quality/trends - Tendências históricas
- POST /api/clusters/quality/analyze-batch - Análise em lote
- GET /api/clusters/quality/dashboard - Dashboard consolidado
"""

import logging
from datetime import datetime
from typing import List, Dict, Any, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, BackgroundTasks
from fastapi.responses import JSONResponse
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel, Field

# Dependências do projeto
from database import get_async_session
from services.cluster_service import ClusterService

# Configurar router
router = APIRouter(prefix="/api/clusters/quality", tags=["cluster-quality"])
logger = logging.getLogger(__name__)


# Modelos de entrada
class QualityAnalysisRequest(BaseModel):
    """Request para análise de qualidade."""
    cluster_ids: Optional[List[str]] = Field(None, description="IDs específicos ou None para todos")
    cluster_type: Optional[str] = Field(None, description="Filtrar por tipo")
    include_detailed_analysis: bool = Field(True, description="Incluir análise detalhada")


class QualityValidationRequest(BaseModel):
    """Request para validação de qualidade."""
    cluster_id: str = Field(description="ID do cluster")
    custom_thresholds: Optional[Dict[str, float]] = Field(None, description="Thresholds customizados")


# ==============================================================================
# ENDPOINTS DE MÉTRICAS DE QUALIDADE
# ==============================================================================

@router.get("/{cluster_id}")
async def analyze_cluster_quality(
    cluster_id: str,
    include_detailed: bool = Query(True, description="Incluir análise detalhada"),
    db: AsyncSession = Depends(get_async_session)
):
    """
    Análise completa de qualidade de um cluster específico.
    
    Retorna métricas de silhouette score, consistência, qualidade dos embeddings
    e insights acionáveis para melhoria.
    
    **Métricas retornadas:**
    - Overall Quality Score (0-1)
    - Silhouette Score (coesão vs separação)
    - Cohesion Score (compactness interna)
    - Separation Score (distância de outros clusters)
    - Semantic Coherence (coerência semântica)
    - Provider Quality (qualidade por embedding provider)
    - Outliers Detected (entidades com baixa confidence)
    - Actionable Insights (recomendações de melhoria)
    """
    
    try:
        logger.info(f"🔍 Analisando qualidade do cluster {cluster_id}")
        
        cluster_service = ClusterService(db)
        quality_analysis = await cluster_service.analyze_cluster_quality(
            cluster_id, include_detailed
        )
        
        if not quality_analysis:
            raise HTTPException(
                status_code=404,
                detail=f"Cluster {cluster_id} não encontrado ou não analisável"
            )
        
        return JSONResponse(
            content={
                "success": True,
                "data": quality_analysis,
                "metadata": {
                    "analysis_type": "detailed" if include_detailed else "basic",
                    "metrics_available": [
                        "overall_quality_score",
                        "silhouette_score", 
                        "cohesion_score",
                        "separation_score",
                        "semantic_coherence",
                        "provider_quality",
                        "outliers_detected"
                    ]
                },
                "timestamp": datetime.now().isoformat()
            }
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Erro na análise de qualidade: {e}")
        raise HTTPException(
            status_code=500,
            detail="Erro interno na análise de qualidade"
        )


@router.post("/validate")
async def validate_cluster_quality(
    request: QualityValidationRequest,
    db: AsyncSession = Depends(get_async_session)
):
    """
    Valida se um cluster atende aos thresholds de qualidade configurados.
    
    Permite thresholds customizados para validação específica.
    
    **Thresholds padrão:**
    - Silhouette Score: >= 0.3 (fair)
    - Cohesion Score: >= 0.4 (fair) 
    - Separation Score: >= 0.3 (fair)
    - Overall Quality: >= 0.5 (fair)
    
    **Exemplo de thresholds customizados:**
    ```json
    {
        "cluster_id": "case_cluster_5",
        "custom_thresholds": {
            "silhouette_score": {"fair": 0.4},
            "cohesion_score": {"fair": 0.5},
            "overall_quality": 0.6
        }
    }
    ```
    """
    
    try:
        logger.info(f"✅ Validando qualidade do cluster {request.cluster_id}")
        
        cluster_service = ClusterService(db)
        validation_result = await cluster_service.validate_cluster_quality_thresholds(
            request.cluster_id, request.custom_thresholds
        )
        
        return JSONResponse(
            content={
                "success": True,
                "data": validation_result,
                "metadata": {
                    "validation_type": "custom" if request.custom_thresholds else "default",
                    "thresholds_used": request.custom_thresholds or "default_system_thresholds"
                },
                "timestamp": datetime.now().isoformat()
            }
        )
        
    except Exception as e:
        logger.error(f"❌ Erro na validação de qualidade: {e}")
        raise HTTPException(
            status_code=500,
            detail="Erro interno na validação de qualidade"
        )


@router.get("/trends")
async def get_quality_trends(
    days_back: int = Query(30, ge=1, le=90, description="Dias para análise histórica"),
    cluster_type: Optional[str] = Query(None, description="Filtrar por tipo de cluster"),
    db: AsyncSession = Depends(get_async_session)
):
    """
    Relatório de tendências de qualidade dos clusters ao longo do tempo.
    
    Inclui métricas históricas, tendências e detecção de anomalias.
    
    **Dados retornados:**
    - Tendências por tipo de cluster (cases vs lawyers)
    - Estatísticas de evolução temporal
    - Anomalias de qualidade detectadas
    - Distribuição de qualidade por período
    - Performance de providers de embedding
    """
    
    try:
        logger.info(f"📈 Gerando relatório de tendências ({days_back} dias)")
        
        cluster_service = ClusterService(db)
        trends_report = await cluster_service.get_quality_trends_report(days_back)
        
        # Filtrar por tipo se especificado
        if cluster_type and cluster_type in trends_report:
            filtered_trends = {
                cluster_type: trends_report[cluster_type],
                "overall_trends": trends_report.get("overall_trends", {}),
                "quality_anomalies": [
                    anomaly for anomaly in trends_report.get("quality_anomalies", [])
                    if cluster_type in anomaly.get("affected_types", [cluster_type])
                ],
                "period": trends_report.get("period", {}),
                "generated_at": trends_report.get("generated_at")
            }
            trends_report = filtered_trends
        
        return JSONResponse(
            content={
                "success": True,
                "data": trends_report,
                "metadata": {
                    "period_analyzed": f"{days_back} days",
                    "cluster_type_filter": cluster_type or "all",
                    "metrics_included": [
                        "avg_quality_trends",
                        "silhouette_trends", 
                        "quality_distribution",
                        "anomaly_detection"
                    ]
                },
                "timestamp": datetime.now().isoformat()
            }
        )
        
    except Exception as e:
        logger.error(f"❌ Erro no relatório de tendências: {e}")
        raise HTTPException(
            status_code=500,
            detail="Erro interno no relatório de tendências"
        )


@router.post("/analyze-batch")
async def analyze_clusters_quality_batch(
    request: QualityAnalysisRequest,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_async_session)
):
    """
    Análise de qualidade em lote para múltiplos clusters.
    
    Executa análise para clusters específicos ou todos os clusters do sistema.
    Ideal para auditorias de qualidade e relatórios consolidados.
    
    **Modos de operação:**
    1. **IDs específicos**: Analisa apenas os clusters fornecidos
    2. **Por tipo**: Analisa todos os clusters de um tipo (case/lawyer) 
    3. **Completo**: Analisa todos os clusters do sistema
    
    **Otimizações:**
    - Processamento em batches de 10 clusters
    - Análise paralela quando possível
    - Fallback gracioso para clusters com erro
    """
    
    try:
        logger.info(f"📊 Iniciando análise de qualidade em lote")
        
        cluster_service = ClusterService(db)
        
        # Se IDs específicos foram fornecidos, analisar apenas esses
        if request.cluster_ids:
            logger.info(f"🎯 Analisando {len(request.cluster_ids)} clusters específicos")
            
            analysis_results = []
            failed_analyses = []
            
            for cluster_id in request.cluster_ids:
                try:
                    result = await cluster_service.analyze_cluster_quality(
                        cluster_id, request.include_detailed_analysis
                    )
                    if result:
                        analysis_results.append(result)
                    else:
                        failed_analyses.append(cluster_id)
                except Exception as e:
                    logger.error(f"Erro na análise do cluster {cluster_id}: {e}")
                    failed_analyses.append(cluster_id)
            
            return JSONResponse(
                content={
                    "success": True,
                    "data": {
                        "analysis_mode": "specific_clusters",
                        "total_requested": len(request.cluster_ids),
                        "successfully_analyzed": len(analysis_results),
                        "failed_analyses": failed_analyses,
                        "results": analysis_results,
                        "success_rate": len(analysis_results) / len(request.cluster_ids) if request.cluster_ids else 0
                    },
                    "metadata": {
                        "detailed_analysis": request.include_detailed_analysis,
                        "processing_mode": "synchronous"
                    },
                    "timestamp": datetime.now().isoformat()
                }
            )
        
        # Caso contrário, usar análise em lote otimizada
        logger.info(f"🔄 Executando análise em lote para tipo: {request.cluster_type or 'todos'}")
        
        batch_result = await cluster_service.analyze_all_clusters_quality(
            request.cluster_type, batch_size=10
        )
        
        return JSONResponse(
            content={
                "success": True,
                "data": {
                    "analysis_mode": "batch_processing",
                    "cluster_type_filter": request.cluster_type or "all",
                    **batch_result
                },
                "metadata": {
                    "detailed_analysis": request.include_detailed_analysis,
                    "processing_mode": "batch_optimized",
                    "batch_size": 10
                },
                "timestamp": datetime.now().isoformat()
            }
        )
        
    except Exception as e:
        logger.error(f"❌ Erro na análise em lote: {e}")
        raise HTTPException(
            status_code=500,
            detail="Erro interno na análise em lote"
        )


@router.get("/dashboard")
async def get_quality_dashboard(
    cluster_type: Optional[str] = Query(None, description="Filtrar por tipo"),
    refresh_data: bool = Query(False, description="Forçar refresh dos dados"),
    db: AsyncSession = Depends(get_async_session)
):
    """
    Dashboard consolidado de qualidade dos clusters.
    
    Métricas em tempo real para monitoramento e alertas de qualidade.
    Ideal para administradores e análise de health do sistema.
    
    **Seções do Dashboard:**
    
    1. **Overview**: Métricas gerais de qualidade
    2. **Quality Distribution**: Distribuição por níveis de qualidade
    3. **Provider Performance**: Performance dos providers de embedding
    4. **Recent Trends**: Tendências dos últimos 7 dias  
    5. **System Health**: Status geral do sistema
    6. **Quality Alerts**: Alertas de baixa qualidade
    
    **Métricas-chave:**
    - Total de clusters analisados
    - Score médio de qualidade
    - Clusters de alta/baixa qualidade
    - Anomalias recentes detectadas
    """
    
    try:
        logger.info("📊 Gerando dashboard de qualidade")
        
        cluster_service = ClusterService(db)
        
        # Obter estatísticas gerais
        stats = await cluster_service.get_clustering_statistics(include_detailed_breakdown=True)
        
        # Obter tendências recentes (7 dias)
        recent_trends = await cluster_service.get_quality_trends_report(7)
        
        # Análise consolidada de qualidade (sample limitado para performance)
        quality_analysis = await cluster_service.analyze_all_clusters_quality(
            cluster_type, batch_size=20
        )
        
        # Calcular métricas do overview
        case_clusters = stats.case_clustering.get("total_clusters", 0)
        lawyer_clusters = stats.lawyer_clustering.get("total_clusters", 0)
        total_clusters = case_clusters + lawyer_clusters
        
        avg_quality = quality_analysis.get("summary", {}).get("avg_overall_quality", 0)
        high_quality = quality_analysis.get("quality_trends", {}).get("high_quality_clusters", 0)
        low_quality = quality_analysis.get("quality_trends", {}).get("low_quality_clusters", 0)
        
        # Alertas de qualidade (últimos 5)
        quality_alerts = [
            {
                **alert,
                "severity": "high" if alert.get("deviation", 0) > 3 else "medium",
                "cluster_type": "mixed"  # Placeholder
            }
            for alert in recent_trends.get("quality_anomalies", [])
            if alert.get("type") == "low_quality"
        ][:5]
        
        dashboard_data = {
            "overview": {
                "total_clusters": total_clusters,
                "case_clusters": case_clusters,
                "lawyer_clusters": lawyer_clusters,
                "avg_quality_score": round(avg_quality, 3),
                "high_quality_clusters": high_quality,
                "medium_quality_clusters": quality_analysis.get("quality_trends", {}).get("medium_quality_clusters", 0),
                "low_quality_clusters": low_quality,
                "quality_score_trend": "stable"  # TODO: Calcular baseado em histórico
            },
            "quality_distribution": quality_analysis.get("summary", {}).get("quality_distribution", {}),
            "provider_performance": {
                provider: {
                    "avg_quality": round(score, 3),
                    "status": "good" if score >= 0.6 else "fair" if score >= 0.4 else "poor"
                }
                for provider, score in quality_analysis.get("provider_performance", {}).items()
            },
            "recent_trends": {
                "period": "7 days",
                "case_trends": recent_trends.get("case_clusters", {}).get("statistics", {}),
                "lawyer_trends": recent_trends.get("lawyer_clusters", {}).get("statistics", {}),
                "overall_trend": recent_trends.get("overall_trends", {}).get("quality_trend", "stable")
            },
            "system_health": {
                **stats.system_health,
                "quality_health_score": min(1.0, avg_quality + 0.2),  # Bonus para estabilidade
                "alerts_count": len(quality_alerts)
            },
            "quality_alerts": quality_alerts,
            "metadata": {
                "last_clustering_run": stats.case_clustering.get("last_clustering_run") or stats.lawyer_clustering.get("last_clustering_run"),
                "data_freshness": "fresh" if not refresh_data else "refreshed",
                "analysis_coverage": f"{quality_analysis.get('total_analyzed', 0)} clusters"
            },
            "generated_at": datetime.now().isoformat()
        }
        
        return JSONResponse(
            content={
                "success": True,
                "data": dashboard_data,
                "metadata": {
                    "cluster_type_filter": cluster_type or "all",
                    "refresh_forced": refresh_data,
                    "dashboard_sections": [
                        "overview", 
                        "quality_distribution", 
                        "provider_performance",
                        "recent_trends",
                        "system_health", 
                        "quality_alerts"
                    ]
                },
                "timestamp": datetime.now().isoformat()
            }
        )
        
    except Exception as e:
        logger.error(f"❌ Erro no dashboard de qualidade: {e}")
        raise HTTPException(
            status_code=500,
            detail="Erro interno no dashboard de qualidade"
        )


@router.get("/health")
async def cluster_quality_health_check(
    db: AsyncSession = Depends(get_async_session)
):
    """
    Health check específico para o sistema de métricas de qualidade.
    
    Verifica se todos os componentes necessários estão funcionando.
    """
    
    try:
        cluster_service = ClusterService(db)
        
        # Verificar se o serviço de métricas está disponível
        health_checks = {
            "quality_service_available": cluster_service.quality_metrics_service is not None,
            "database_connection": True,  # Se chegou até aqui, conexão OK
            "clustering_system": True     # TODO: Verificar último job de clustering
        }
        
        # Status geral
        all_healthy = all(health_checks.values())
        
        return JSONResponse(
            content={
                "success": True,
                "data": {
                    "status": "healthy" if all_healthy else "degraded",
                    "checks": health_checks,
                    "version": "1.0.0",
                    "features_available": [
                        "cluster_quality_analysis",
                        "threshold_validation", 
                        "quality_trends",
                        "batch_analysis",
                        "quality_dashboard"
                    ] if health_checks["quality_service_available"] else ["basic_health_check"],
                    "timestamp": datetime.now().isoformat()
                }
            },
            status_code=200 if all_healthy else 503
        )
        
    except Exception as e:
        logger.error(f"❌ Erro no health check: {e}")
        return JSONResponse(
            content={
                "success": False,
                "data": {
                    "status": "unhealthy",
                    "error": str(e),
                    "timestamp": datetime.now().isoformat()
                }
            },
            status_code=503
        ) 