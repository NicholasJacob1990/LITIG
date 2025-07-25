#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Core Cluster APIs
================

APIs REST fundamentais para funcionalidades de clusterização de casos e advogados.
Endpoints para trends, detalhes de clusters e recomendações de parceria.

Endpoints:
- GET /api/clusters/trending - Top clusters em alta
- GET /api/clusters/{cluster_id} - Detalhes de cluster específico  
- GET /api/clusters/recommendations/{lawyer_id} - Recomendações de parceria
- GET /api/clusters/stats - Estatísticas gerais de clusterização
"""

import logging
from datetime import datetime
from typing import List, Dict, Any, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from database import get_async_session
from services.cluster_service import ClusterService
from schemas.cluster_schemas import (
    TrendingClusterResponse,
    ClusterDetailResponse,
    PartnershipRecommendationResponse,
    ClusterStatsResponse
)

router = APIRouter(prefix="/api/clusters", tags=["clusters"])
logger = logging.getLogger(__name__)


def _calculate_growth_trend(momentum_score: float) -> str:
    """Calcula trend baseado no momentum score."""
    if momentum_score > 0.8:
        return "🚀 Em explosão"
    elif momentum_score > 0.6:
        return "📈 Crescendo"
    elif momentum_score > 0.4:
        return "📊 Estável"
    else:
        return "📉 Diminuindo"


@router.get("/trending", response_model=List[TrendingClusterResponse])
async def get_trending_clusters(
    limit: int = Query(default=3, ge=1, le=20, description="Número de clusters trending"),
    cluster_type: str = Query(default="case", description="Tipo: 'case' ou 'lawyer'"),
    min_items: int = Query(default=5, ge=1, description="Mínimo de itens por cluster"),
    include_emergent_only: bool = Query(default=False, description="Apenas emergentes"),
    db: AsyncSession = Depends(get_async_session)
):
    """
    Retorna clusters em alta baseado em momentum e relevância.
    
    Usado pelo widget de dashboard no Flutter para mostrar
    tendências de mercado e nichos emergentes.
    """
    
    try:
        logger.info(f"📊 Buscando {limit} clusters trending de {cluster_type}")
        
        cluster_service = ClusterService(db)
        trending_clusters = await cluster_service.get_trending_clusters(
            cluster_type=cluster_type,
            limit=limit,
            min_items=min_items,
            emergent_only=include_emergent_only
        )
        
        if not trending_clusters:
            logger.info(f"ℹ️ Nenhum cluster trending encontrado para {cluster_type}")
            return []
        
        # Converter para formato de resposta
        response_data = []
        for cluster in trending_clusters:
            response_data.append(TrendingClusterResponse(
                cluster_id=cluster["cluster_id"],
                cluster_label=cluster["cluster_label"],
                momentum_score=cluster["momentum_score"],
                total_cases=cluster["total_items"] if cluster_type == "case" else 0,
                total_lawyers=cluster["total_items"] if cluster_type == "lawyer" else 0,
                growth_trend=_calculate_growth_trend(cluster["momentum_score"]),
                is_emergent=cluster["is_emergent"],
                emergent_since=cluster["emergent_since"],
                confidence_score=cluster.get("label_confidence", 0.8)
            ))
        
        logger.info(f"✅ Retornando {len(response_data)} clusters trending")
        return response_data
        
    except Exception as e:
        logger.error(f"❌ Erro ao buscar clusters trending: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Erro interno ao buscar clusters trending: {str(e)}"
        )


@router.get("/{cluster_id}", response_model=ClusterDetailResponse)
async def get_cluster_details(
    cluster_id: str,
    include_members: bool = Query(default=False, description="Incluir membros do cluster"),
    members_limit: int = Query(default=10, ge=1, le=50, description="Limite de membros"),
    db: AsyncSession = Depends(get_async_session)
):
    """
    Detalhes completos de um cluster específico.
    
    Inclui metadados, métricas de qualidade, rótulos gerados
    e opcionalmente lista de membros.
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
            raise HTTPException(
                status_code=404,
                detail=f"Cluster {cluster_id} não encontrado"
            )
        
        logger.info(f"✅ Detalhes do cluster {cluster_id} obtidos")
        return cluster_details
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Erro ao buscar detalhes do cluster {cluster_id}: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Erro interno: {str(e)}"
        )


@router.get("/recommendations/{lawyer_id}", response_model=List[PartnershipRecommendationResponse])
async def get_partnership_recommendations(
    lawyer_id: str,
    limit: int = Query(default=10, ge=1, le=50, description="Número máximo de recomendações"),
    min_compatibility: float = Query(default=0.6, ge=0.0, le=1.0, description="Score mínimo de compatibilidade"),
    exclude_same_firm: bool = Query(default=True, description="Excluir advogados do mesmo escritório"),
    db: AsyncSession = Depends(get_async_session)
):
    """
    Gera recomendações de parceria baseadas em complementaridade de clusters.
    
    Analisa clusters do advogado e sugere parceiros com expertises 
    complementares usando algoritmo avançado de scoring.
    """
    
    try:
        logger.info(f"🤝 Gerando recomendações de parceria para advogado {lawyer_id}")
        
        cluster_service = ClusterService(db)
        recommendations = await cluster_service.get_partnership_recommendations(
            lawyer_id=lawyer_id,
            limit=limit,
            min_compatibility_score=min_compatibility,
            exclude_same_firm=exclude_same_firm
        )
        
        if not recommendations:
            logger.info(f"ℹ️ Nenhuma recomendação encontrada para advogado {lawyer_id}")
            return []
        
        logger.info(f"✅ {len(recommendations)} recomendações geradas para {lawyer_id}")
        return recommendations
        
    except Exception as e:
        logger.error(f"❌ Erro ao gerar recomendações para {lawyer_id}: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Erro interno ao gerar recomendações: {str(e)}"
        )


@router.get("/stats", response_model=ClusterStatsResponse)
async def get_clustering_statistics(
    include_detailed_breakdown: bool = Query(default=False, description="Incluir breakdown detalhado"),
    db: AsyncSession = Depends(get_async_session)
):
    """
    Estatísticas gerais do sistema de clusterização.
    
    Fornece métricas agregadas de clusters, qualidade e performance
    para monitoramento e dashboard executivo.
    """
    
    try:
        logger.info("📊 Gerando estatísticas de clusterização")
        
        cluster_service = ClusterService(db)
        stats = await cluster_service.get_clustering_statistics(
            include_detailed_breakdown=include_detailed_breakdown
        )
        
        logger.info("✅ Estatísticas de clusterização geradas")
        return stats
        
    except Exception as e:
        logger.error(f"❌ Erro ao gerar estatísticas: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Erro interno: {str(e)}"
        ) 