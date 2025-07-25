#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Cluster Quality Metrics APIs
============================

Este módulo implementa as APIs REST para análise de qualidade de clusters,
incluindo métricas de coesão, separação, confiança e insights acionáveis.

Endpoints principais:
- GET /{cluster_id} - Análise detalhada de qualidade de um cluster
- POST /validate - Validação de thresholds de qualidade
- GET /trends - Tendências de qualidade ao longo do tempo
- POST /analyze-batch - Análise em lote de múltiplos clusters
- GET /dashboard - Dashboard executivo de qualidade
- GET /health - Health check do sistema de qualidade

Métricas implementadas:
- Silhouette Score (coesão interna)
- Inertia Score (separação entre clusters)
- Confidence Score (qualidade dos embeddings)
- Provider Quality (distribuição de fontes)
- Actionable Insights (recomendações automáticas)
"""

from datetime import datetime
from typing import Dict, Any, List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from database import get_async_session
from services.cluster_service import ClusterService
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/clusters/quality", tags=["cluster-quality"])


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
    force_refresh: bool = Field(False, description="Forçar regeneração mesmo com dados recentes")


class ClusterQueryParams(BaseModel):
    """Parâmetros de query para clusters."""
    limit: int = Field(default=10, ge=1, le=100, description="Número máximo de resultados")
    cluster_type: str = Field(default="case", description="Tipo de cluster: 'case' ou 'lawyer'")
    min_items: int = Field(default=5, ge=1, description="Mínimo de itens por cluster")
    include_emergent_only: bool = Field(default=False, description="Incluir apenas clusters emergentes")


@router.get("/{cluster_id}", response_model=ClusterDetailResponse)
async def get_cluster_details(
    cluster_id: str,
    include_members: bool = Query(default=True, description="Incluir membros do cluster"),
    members_limit: int = Query(default=20, ge=1, le=100, description="Limite de membros retornados"),
    db: AsyncSession = Depends(get_async_session)
):
    """
    Retorna detalhes completos de um cluster específico.
    
    Inclui metadados, membros, qualidade dos dados e insights.
    Usado pelo modal detalhado no Flutter.
    """
    
    try:
        logger.info(f"🔍 Buscando detalhes do cluster {cluster_id}")
        
        cluster_service = ClusterService(db)
        cluster_details = await cluster_service.get_cluster_details(
            cluster_id=cluster_id,
            include_members=include_members,
            members_limit=members_limit
        )
        
        if not cluster_details:
            logger.warning(f"❌ Cluster {cluster_id} não encontrado")
            raise HTTPException(
                status_code=404,
                detail=f"Cluster {cluster_id} não encontrado"
            )
        
        logger.info(f"✅ Detalhes do cluster {cluster_id} encontrados")
        return cluster_details
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Erro ao buscar detalhes do cluster {cluster_id}: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Erro interno ao buscar cluster: {str(e)}"
        )


@router.get("/recommendations/{lawyer_id}")
async def get_partnership_recommendations(
    lawyer_id: str,
    limit: int = 10,
    min_compatibility_score: float = 0.6,
    exclude_same_firm: bool = True,
    db: AsyncSession = Depends(get_async_session)
):
    """Recomendações de parceria baseadas em clusters complementares."""
    
    cluster_service = ClusterService(db)
    recommendations = await cluster_service.get_partnership_recommendations(
        lawyer_id=lawyer_id,
        limit=limit,
        min_compatibility_score=min_compatibility_score,
        exclude_same_firm=exclude_same_firm
    )
    
    return {
        "lawyer_id": lawyer_id,
        "recommendations": recommendations,
        "total_found": len(recommendations),
        "generated_at": datetime.now().isoformat()
    }


@router.post("/generate")
async def trigger_cluster_generation(
    request: ClusterGenerationRequest,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_async_session)
):
    """
    Trigger manual para gerar clusters.
    
    Útil para admins forçarem regeneração ou testes.
    Executa em background para não bloquear resposta.
    """
    
    try:
        logger.info(f"🚀 Trigger manual de clusterização: {request.entity_type}")
        
        # Verificar se já há job recente rodando (últimas 2 horas)
        if not request.force_refresh:
            recent_execution = await _check_recent_cluster_generation(db)
            if recent_execution:
                logger.warning("⚠️ Job de clusterização executado recentemente")
                raise HTTPException(
                    status_code=429,
                    detail="Job de clusterização executado recentemente. Use force_refresh=true para forçar."
                )
        
        # Adicionar job ao background
        background_tasks.add_task(
            run_cluster_generation,
            entity_type=request.entity_type
        )
        
        logger.info("✅ Job de clusterização agendado para execução em background")
        
        return {
            "status": "success",
            "message": "Job de clusterização iniciado em background",
            "entity_type": request.entity_type,
            "force_refresh": request.force_refresh,
            "triggered_at": datetime.now().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Erro ao iniciar job de clusterização: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Erro interno ao iniciar clusterização: {str(e)}"
        )


@router.get("/stats", response_model=ClusterStatsResponse)
async def get_cluster_stats(
    include_detailed_breakdown: bool = Query(default=False, description="Incluir breakdown detalhado"),
    db: AsyncSession = Depends(get_async_session)
):
    """
    Retorna estatísticas gerais do sistema de clusterização.
    
    Útil para dashboards administrativos e monitoramento.
    """
    
    try:
        logger.info("📊 Buscando estatísticas de clusterização")
        
        cluster_service = ClusterService(db)
        stats = await cluster_service.get_clustering_statistics(
            include_detailed_breakdown=include_detailed_breakdown
        )
        
        logger.info("✅ Estatísticas de clusterização obtidas")
        return stats
        
    except Exception as e:
        logger.error(f"❌ Erro ao buscar estatísticas: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Erro interno ao buscar estatísticas: {str(e)}"
        )


@router.get("/labels/stats")
async def get_labeling_stats(
    db: AsyncSession = Depends(get_async_session)
):
    """
    Retorna estatísticas de rotulagem automática.
    
    Mostra quantos clusters foram rotulados automaticamente vs manualmente.
    """
    
    try:
        logger.info("🏷️ Buscando estatísticas de rotulagem")
        
        labeling_service = ClusterLabelingService(db)
        stats = await labeling_service.get_cluster_labeling_stats()
        
        logger.info("✅ Estatísticas de rotulagem obtidas")
        return {
            "status": "success",
            "data": stats,
            "generated_at": datetime.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"❌ Erro ao buscar estatísticas de rotulagem: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Erro interno: {str(e)}"
        )


@router.post("/labels/regenerate/{cluster_id}")
async def regenerate_cluster_label(
    cluster_id: str,
    entity_type: str = Query(description="Tipo: 'case' ou 'lawyer'"),
    model: str = Query(default="gpt-4o", description="Modelo LLM a usar"),
    db: AsyncSession = Depends(get_async_session)
):
    """
    Regenera rótulo de um cluster específico.
    
    Útil para correções ou melhorias de rótulos.
    """
    
    try:
        logger.info(f"🔄 Regenerando rótulo do cluster {cluster_id}")
        
        labeling_service = ClusterLabelingService(db)
        new_label = await labeling_service.relabel_cluster(
            cluster_id=cluster_id,
            entity_type=entity_type,
            model=model
        )
        
        if new_label:
            logger.info(f"✅ Novo rótulo gerado: '{new_label}'")
            return {
                "status": "success",
                "cluster_id": cluster_id,
                "new_label": new_label,
                "model_used": model,
                "regenerated_at": datetime.now().isoformat()
            }
        else:
            logger.warning(f"⚠️ Falha ao regenerar rótulo para {cluster_id}")
            raise HTTPException(
                status_code=500,
                detail="Falha ao gerar novo rótulo"
            )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Erro ao regenerar rótulo: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Erro interno: {str(e)}"
        )


# Funções auxiliares

def _calculate_growth_trend(momentum_score: float) -> str:
    """Calcula tendência de crescimento baseada no momentum."""
    if momentum_score >= 0.8:
        return "rapidly_increasing"
    elif momentum_score >= 0.6:
        return "increasing"
    elif momentum_score >= 0.4:
        return "stable"
    elif momentum_score >= 0.2:
        return "decreasing"
    else:
        return "rapidly_decreasing"


async def _check_recent_cluster_generation(db: AsyncSession) -> bool:
    """Verifica se houve execução recente de clusterização."""
    
    try:
        from sqlalchemy import text
        
        # Verificar última execução nos logs ou metadados
        query = text("""
            SELECT MAX(last_updated) as last_execution
            FROM cluster_metadata
            WHERE last_updated > NOW() - INTERVAL '2 hours'
        """)
        
        result = await db.execute(query)
        row = result.fetchone()
        
        return row.last_execution is not None
        
    except Exception as e:
        logger.error(f"❌ Erro ao verificar execução recente: {e}")
        return False


# Health check endpoint
@router.get("/emergent-alerts")
async def get_emergent_cluster_alerts(
    cluster_type: str = Query(default="case", description="Tipo: 'case' ou 'lawyer'"),
    limit: int = Query(default=10, ge=1, le=50, description="Número máximo de alertas"),
    urgency_level: Optional[str] = Query(None, description="Filtrar por urgência: 'high', 'medium', 'low'"),
    db: AsyncSession = Depends(get_async_session)
):
    """
    Retorna alertas de clusters emergentes detectados recentemente.
    
    Útil para dashboards de administradores e advogados que querem
    identificar novas oportunidades de mercado.
    """
    
    try:
        from services.cluster_momentum_service import create_momentum_service
        
        logger.info(f"🚨 Buscando alertas de clusters emergentes: {cluster_type}")
        
        momentum_service = create_momentum_service(db)
        emergent_alerts = await momentum_service.detect_emergent_clusters(cluster_type)
        
        # Filtrar por nível de urgência se especificado
        if urgency_level:
            emergent_alerts = [alert for alert in emergent_alerts if alert.urgency_level == urgency_level]
        
        # Limitar resultados
        emergent_alerts = emergent_alerts[:limit]
        
        # Converter para formato de resposta
        alerts_response = []
        for alert in emergent_alerts:
            alerts_response.append({
                "cluster_id": alert.cluster_id,
                "cluster_label": alert.cluster_label,
                "detection_date": alert.detection_date.isoformat(),
                "momentum_score": alert.momentum_score,
                "growth_rate": alert.growth_rate,
                "market_opportunity": alert.market_opportunity,
                "recommended_actions": alert.recommended_actions,
                "urgency_level": alert.urgency_level
            })
        
        logger.info(f"✅ {len(alerts_response)} alertas de clusters emergentes retornados")
        
        return {
            "status": "success",
            "cluster_type": cluster_type,
            "total_alerts": len(alerts_response),
            "alerts": alerts_response,
            "generated_at": datetime.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"❌ Erro ao buscar alertas emergentes: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Erro interno ao buscar alertas: {str(e)}"
        )


@router.get("/momentum/{cluster_id}")
async def get_cluster_momentum(
    cluster_id: str,
    include_history: bool = Query(default=False, description="Incluir histórico de momentum"),
    db: AsyncSession = Depends(get_async_session)
):
    """
    Retorna métricas de momentum detalhadas para um cluster específico.
    
    Inclui crescimento, velocidade, aceleração e análise de tendências.
    """
    
    try:
        from services.cluster_momentum_service import create_momentum_service
        
        logger.info(f"📊 Buscando momentum para cluster {cluster_id}")
        
        momentum_service = create_momentum_service(db)
        momentum_metrics = await momentum_service.calculate_cluster_momentum(cluster_id)
        
        if not momentum_metrics:
            raise HTTPException(
                status_code=404,
                detail=f"Dados de momentum insuficientes para cluster {cluster_id}"
            )
        
        response_data = {
            "cluster_id": momentum_metrics.cluster_id,
            "current_momentum": momentum_metrics.current_momentum,
            "growth_rate": momentum_metrics.growth_rate,
            "velocity": momentum_metrics.velocity,
            "acceleration": momentum_metrics.acceleration,
            "trend": momentum_metrics.trend.value,
            "is_emergent": momentum_metrics.is_emergent,
            "emergent_confidence": momentum_metrics.emergent_confidence,
            "stability_score": momentum_metrics.stability_score,
            "market_potential": momentum_metrics.market_potential,
            "data_points": momentum_metrics.data_points,
            "calculation_date": momentum_metrics.calculation_date.isoformat()
        }
        
        # Incluir histórico se solicitado
        if include_history:
            history_query = text("""
                SELECT recorded_at, total_items, momentum_score
                FROM cluster_momentum_history
                WHERE cluster_id = :cluster_id
                ORDER BY recorded_at DESC
                LIMIT 30
            """)
            
            history_result = await db.execute(history_query, {"cluster_id": cluster_id})
            history_data = []
            
            for row in history_result.fetchall():
                history_data.append({
                    "date": row.recorded_at.isoformat(),
                    "total_items": row.total_items,
                    "momentum_score": float(row.momentum_score or 0.0)
                })
            
            response_data["history"] = history_data
        
        logger.info(f"✅ Momentum do cluster {cluster_id} retornado")
        return response_data
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Erro ao buscar momentum do cluster: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Erro interno: {str(e)}"
        )


@router.get("/health")
async def health_check():
    """Health check para monitoramento do sistema de clusters."""
    
    try:
        # Verificações básicas
        checks = {
            "database": False,
            "embedding_service": False,
            "clustering_libs": False,
            "openai": False,
            "momentum_service": False
        }
        
        # Teste de banco
        try:
            async with get_async_session() as db:
                await db.execute(text("SELECT 1"))
                checks["database"] = True
        except Exception:
            pass
        
        # Teste de bibliotecas de clustering
        try:
            import umap
            import hdbscan
            import numpy as np
            from scipy import stats
            checks["clustering_libs"] = True
        except ImportError:
            pass
        
        # Teste de embedding service
        try:
            from services.embedding_service import embedding_service
            checks["embedding_service"] = True
        except Exception:
            pass
        
        # Teste de OpenAI
        try:
            import openai
            import os
            if os.getenv("OPENAI_API_KEY"):
                checks["openai"] = True
        except Exception:
            pass
        
        # Teste de momentum service
        try:
            from services.cluster_momentum_service import create_momentum_service
            async with get_async_session() as db:
                momentum_service = create_momentum_service(db)
                checks["momentum_service"] = True
        except Exception:
            pass
        
        all_healthy = all(checks.values())
        status_code = 200 if all_healthy else 503
        
        return JSONResponse(
            status_code=status_code,
            content={
                "status": "healthy" if all_healthy else "degraded",
                "checks": checks,
                "timestamp": datetime.now().isoformat(),
                "version": "1.0.0"
            }
        )
        
    except Exception as e:
        logger.error(f"❌ Erro no health check: {e}")
        return JSONResponse(
            status_code=500,
            content={
                "status": "unhealthy",
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }
        ) 