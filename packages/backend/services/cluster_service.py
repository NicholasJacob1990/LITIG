#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Cluster Service
===============

Serviço de lógica de negócio para operações relacionadas a clusters.
Centraliza operações de consulta, análise e recomendações.

Features:
- Busca de clusters trending com momentum
- Detalhes completos de clusters
- Recomendações de parceria baseadas em complementaridade
- Estatísticas do sistema de clusterização
- Análise de qualidade e métricas
"""

import asyncio
import logging
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional, Tuple
from dataclasses import dataclass
import json

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, text, and_, or_, func, desc
from sqlalchemy.sql import text

# Schemas de resposta
from schemas.cluster_schemas import (
    TrendingClusterResponse,
    ClusterDetailResponse,
    PartnershipRecommendationResponse,
    ClusterStatsResponse,
    ClusterMemberInfo
)


@dataclass
class ClusterAnalytics:
    """Analytics de um cluster específico."""
    cluster_id: str
    total_members: int
    avg_confidence: float
    provider_distribution: Dict[str, int]
    data_sources_coverage: Dict[str, int]
    quality_score: float
    momentum_score: float
    creation_date: datetime
    last_updated: datetime


class ClusterService:
    """Serviço para operações relacionadas a clusters."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
        self.logger = logging.getLogger(__name__)
    
    async def get_trending_clusters(
        self, 
        cluster_type: str = "case", 
        limit: int = 10,
        min_items: int = 5,
        emergent_only: bool = False
    ) -> List[Dict[str, Any]]:
        """
        Retorna clusters com maior momentum e relevância.
        
        Args:
            cluster_type: 'case' ou 'lawyer'
            limit: Número máximo de resultados
            min_items: Mínimo de itens por cluster
            emergent_only: Filtrar apenas clusters emergentes
            
        Returns:
            Lista de clusters ordenados por momentum
        """
        
        try:
            self.logger.info(f"🔍 Buscando clusters trending: {cluster_type}, limit={limit}")
            
            # Query base usando função RPC otimizada
            base_conditions = [
                "cm.cluster_type = :cluster_type",
                "cm.total_items >= :min_items",
                "cm.cluster_id NOT LIKE '%_-1'"  # Excluir outliers
            ]
            
            if emergent_only:
                base_conditions.append("cm.is_emergent = true")
            
            conditions_sql = " AND ".join(base_conditions)
            
            query = text(f"""
                SELECT 
                    cm.cluster_id,
                    COALESCE(cl.label, cm.cluster_label, 'Cluster sem nome') as cluster_label,
                    cm.momentum_score,
                    cm.total_items,
                    cm.is_emergent,
                    cm.emergent_since,
                    cl.confidence_score as label_confidence,
                    cm.last_updated,
                    cm.created_at,
                    -- Cálculo dinâmico de relevância
                    (cm.momentum_score * 0.6 + 
                     LEAST(cm.total_items::float / 100, 1.0) * 0.3 + 
                     COALESCE(cl.confidence_score, 0.5) * 0.1) as relevance_score
                FROM cluster_metadata cm
                LEFT JOIN {cluster_type}_cluster_labels cl ON cm.cluster_id = cl.cluster_id
                WHERE {conditions_sql}
                ORDER BY 
                    cm.is_emergent DESC,
                    relevance_score DESC,
                    cm.momentum_score DESC,
                    cm.total_items DESC
                LIMIT :limit
            """)
            
            result = await self.db.execute(query, {
                "cluster_type": cluster_type,
                "min_items": min_items,
                "limit": limit
            })
            
            rows = result.fetchall()
            
            # Converter para formato de retorno
            trending_clusters = []
            for row in rows:
                cluster_data = {
                    "cluster_id": row.cluster_id,
                    "cluster_label": row.cluster_label,
                    "momentum_score": float(row.momentum_score or 0.0),
                    "total_items": row.total_items,
                    "is_emergent": row.is_emergent,
                    "emergent_since": row.emergent_since,
                    "label_confidence": float(row.label_confidence or 0.8),
                    "last_updated": row.last_updated,
                    "created_at": row.created_at,
                    "relevance_score": float(row.relevance_score or 0.0)
                }
                trending_clusters.append(cluster_data)
            
            self.logger.info(f"✅ Encontrados {len(trending_clusters)} clusters trending")
            return trending_clusters
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao buscar clusters trending: {e}")
            return []
    
    async def get_cluster_details(
        self, 
        cluster_id: str,
        include_members: bool = True,
        members_limit: int = 20
    ) -> Optional[ClusterDetailResponse]:
        """
        Retorna detalhes completos de um cluster específico.
        
        Args:
            cluster_id: ID do cluster
            include_members: Se incluir lista de membros
            members_limit: Limite de membros retornados
            
        Returns:
            Detalhes completos do cluster ou None se não encontrado
        """
        
        try:
            self.logger.info(f"🔍 Buscando detalhes do cluster {cluster_id}")
            
            # 1. Buscar metadados básicos do cluster
            metadata_query = text("""
                SELECT 
                    cm.*,
                    cl.label as generated_label,
                    cl.confidence_score as label_confidence,
                    cl.generated_by,
                    cl.llm_model
                FROM cluster_metadata cm
                LEFT JOIN case_cluster_labels cl ON cm.cluster_id = cl.cluster_id
                WHERE cm.cluster_id = :cluster_id
                
                UNION ALL
                
                SELECT 
                    cm.*,
                    cl.label as generated_label,
                    cl.confidence_score as label_confidence,
                    cl.generated_by,
                    cl.llm_model
                FROM cluster_metadata cm
                LEFT JOIN lawyer_cluster_labels cl ON cm.cluster_id = cl.cluster_id
                WHERE cm.cluster_id = :cluster_id
            """)
            
            metadata_result = await self.db.execute(metadata_query, {"cluster_id": cluster_id})
            metadata_row = metadata_result.fetchone()
            
            if not metadata_row:
                self.logger.warning(f"❌ Cluster {cluster_id} não encontrado")
                return None
            
            # 2. Buscar analytics do cluster
            analytics = await self._get_cluster_analytics(cluster_id, metadata_row.cluster_type)
            
            # 3. Buscar membros se solicitado
            members = []
            if include_members:
                members = await self._get_cluster_members(
                    cluster_id, 
                    metadata_row.cluster_type, 
                    members_limit
                )
            
            # 4. Montar resposta
            cluster_details = ClusterDetailResponse(
                cluster_id=cluster_id,
                cluster_type=metadata_row.cluster_type,
                cluster_label=metadata_row.generated_label or metadata_row.cluster_label or "Cluster sem nome",
                description=metadata_row.description,
                total_members=metadata_row.total_items,
                momentum_score=float(metadata_row.momentum_score or 0.0),
                is_emergent=metadata_row.is_emergent,
                emergent_since=metadata_row.emergent_since,
                quality_metrics={
                    "silhouette_score": analytics.quality_score,
                    "avg_confidence": analytics.avg_confidence,
                    "data_sources_coverage": analytics.data_sources_coverage,
                    "provider_distribution": analytics.provider_distribution
                },
                label_info={
                    "generated_label": metadata_row.generated_label,
                    "confidence_score": float(metadata_row.label_confidence or 0.8),
                    "generated_by": metadata_row.generated_by or "unknown",
                    "llm_model": metadata_row.llm_model
                },
                members=members,
                created_at=metadata_row.created_at,
                last_updated=metadata_row.last_updated
            )
            
            self.logger.info(f"✅ Detalhes do cluster {cluster_id} obtidos")
            return cluster_details
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao buscar detalhes do cluster {cluster_id}: {e}")
            return None
    
    async def get_partnership_recommendations(
        self,
        lawyer_id: str,
        limit: int = 10,
        min_compatibility_score: float = 0.6,
        exclude_same_firm: bool = True
    ) -> List[PartnershipRecommendationResponse]:
        """
        Gera recomendações de parceria baseadas em complementaridade de clusters.
        
        Args:
            lawyer_id: ID do advogado
            limit: Número máximo de recomendações  
            min_compatibility_score: Score mínimo de compatibilidade
            exclude_same_firm: Excluir advogados do mesmo escritório
            
        Returns:
            Lista de recomendações de parceria
        """
        
        try:
            self.logger.info(f"🤝 Gerando recomendações para advogado {lawyer_id}")
            
            # 1. Encontrar clusters do advogado
            lawyer_clusters_query = text("""
                SELECT lc.cluster_id, lc.confidence_score, cm.cluster_label
                FROM lawyer_clusters lc
                JOIN cluster_metadata cm ON lc.cluster_id = cm.cluster_id
                WHERE lc.lawyer_id = :lawyer_id 
                    AND lc.confidence_score > 0.3
                ORDER BY lc.confidence_score DESC
            """)
            
            lawyer_clusters_result = await self.db.execute(
                lawyer_clusters_query, 
                {"lawyer_id": lawyer_id}
            )
            lawyer_clusters = lawyer_clusters_result.fetchall()
            
            if not lawyer_clusters:
                self.logger.info(f"ℹ️ Advogado {lawyer_id} não possui clusters atribuídos")
                return []
            
            lawyer_cluster_ids = [row.cluster_id for row in lawyer_clusters]
            
            # 2. Buscar advogados em clusters complementares
            exclude_firm_condition = ""
            if exclude_same_firm:
                exclude_firm_condition = """
                    AND NOT EXISTS (
                        SELECT 1 FROM lawyers l1, lawyers l2 
                        WHERE l1.id = :lawyer_id 
                            AND l2.id = lc.lawyer_id 
                            AND l1.law_firm_id = l2.law_firm_id
                            AND l1.law_firm_id IS NOT NULL
                    )
                """
            
            recommendations_query = text(f"""
                WITH lawyer_expertise AS (
                    SELECT 
                        l.id as lawyer_id,
                        l.name,
                        l.oab_number,
                        lf.name as firm_name,
                        lc.cluster_id,
                        cm.cluster_label,
                        lc.confidence_score,
                        -- Calcular complementaridade (clusters não sobrepostos)
                        CASE 
                            WHEN lc.cluster_id = ANY(:lawyer_clusters::text[]) THEN 0.0
                            ELSE lc.confidence_score 
                        END as complementarity_score
                    FROM lawyer_clusters lc
                    JOIN lawyers l ON lc.lawyer_id = l.id
                    LEFT JOIN law_firms lf ON l.law_firm_id = lf.id
                    JOIN cluster_metadata cm ON lc.cluster_id = cm.cluster_id
                    WHERE lc.lawyer_id != :lawyer_id
                        AND lc.confidence_score > :min_compatibility
                        AND cm.total_items >= 5
                        {exclude_firm_condition}
                ),
                recommendations AS (
                    SELECT 
                        lawyer_id,
                        name,
                        firm_name,
                        cluster_id,
                        cluster_label,
                        confidence_score,
                        complementarity_score,
                        -- Score final baseado em complementaridade e força no cluster
                        (complementarity_score * 0.7 + confidence_score * 0.3) as final_score,
                        ROW_NUMBER() OVER (
                            PARTITION BY lawyer_id 
                            ORDER BY complementarity_score DESC
                        ) as expertise_rank
                    FROM lawyer_expertise
                    WHERE complementarity_score > 0
                )
                SELECT 
                    lawyer_id,
                    name,
                    firm_name,
                    cluster_id,
                    cluster_label,
                    confidence_score,
                    complementarity_score,
                    final_score
                FROM recommendations
                WHERE expertise_rank <= 2  -- Top 2 especialidades por advogado
                ORDER BY final_score DESC
                LIMIT :limit
            """)
            
            recommendations_result = await self.db.execute(recommendations_query, {
                "lawyer_id": lawyer_id,
                "lawyer_clusters": lawyer_cluster_ids,
                "min_compatibility": min_compatibility_score,
                "limit": limit
            })
            
            # 3. Construir recomendações
            recommendations = []
            for row in recommendations_result.fetchall():
                # Gerar razão da recomendação
                recommendation_reason = self._generate_partnership_reason(
                    row.cluster_label,
                    row.confidence_score,
                    row.complementarity_score
                )
                
                recommendation = PartnershipRecommendationResponse(
                    recommended_lawyer_id=row.lawyer_id,
                    lawyer_name=row.name,
                    firm_name=row.firm_name,
                    cluster_expertise=row.cluster_label,
                    compatibility_score=float(row.final_score),
                    confidence_in_expertise=float(row.confidence_score),
                    complementarity_score=float(row.complementarity_score),
                    recommendation_reason=recommendation_reason,
                    potential_synergies=[
                        f"Expertise complementar em {row.cluster_label}",
                        "Ampliação de portfólio de serviços",
                        "Acesso a novos mercados"
                    ]
                )
                recommendations.append(recommendation)
            
            self.logger.info(f"✅ {len(recommendations)} recomendações geradas para {lawyer_id}")
            return recommendations
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao gerar recomendações: {e}")
            return []
    
    async def get_clustering_statistics(
        self, 
        include_detailed_breakdown: bool = False
    ) -> ClusterStatsResponse:
        """
        Retorna estatísticas gerais do sistema de clusterização.
        
        Args:
            include_detailed_breakdown: Incluir breakdown detalhado por fonte
            
        Returns:
            Estatísticas completas do sistema
        """
        
        try:
            self.logger.info("📊 Coletando estatísticas de clusterização")
            
            # Estatísticas básicas
            basic_stats_query = text("""
                SELECT 
                    cluster_type,
                    COUNT(*) as total_clusters,
                    SUM(total_items) as total_entities,
                    AVG(total_items) as avg_cluster_size,
                    COUNT(CASE WHEN is_emergent = true THEN 1 END) as emergent_clusters,
                    AVG(momentum_score) as avg_momentum,
                    MAX(last_updated) as last_clustering_run
                FROM cluster_metadata
                WHERE cluster_id NOT LIKE '%_-1'
                    AND total_items >= 3
                GROUP BY cluster_type
            """)
            
            basic_result = await self.db.execute(basic_stats_query)
            basic_rows = basic_result.fetchall()
            
            # Organizar estatísticas por tipo
            case_stats = None
            lawyer_stats = None
            
            for row in basic_rows:
                stats_data = {
                    "total_clusters": row.total_clusters,
                    "total_entities": row.total_entities,
                    "avg_cluster_size": float(row.avg_cluster_size or 0),
                    "emergent_clusters": row.emergent_clusters,
                    "avg_momentum": float(row.avg_momentum or 0),
                    "last_clustering_run": row.last_clustering_run
                }
                
                if row.cluster_type == "case":
                    case_stats = stats_data
                elif row.cluster_type == "lawyer":
                    lawyer_stats = stats_data
            
            # Estatísticas de qualidade
            quality_stats = await self._get_quality_statistics()
            
            # Breakdown detalhado se solicitado
            detailed_breakdown = None
            if include_detailed_breakdown:
                detailed_breakdown = await self._get_detailed_breakdown()
            
            stats = ClusterStatsResponse(
                case_clustering=case_stats or self._empty_cluster_stats(),
                lawyer_clustering=lawyer_stats or self._empty_cluster_stats(),
                quality_metrics=quality_stats,
                system_health={
                    "clustering_pipeline_status": "healthy",
                    "last_successful_run": max(
                        (case_stats or {}).get("last_clustering_run"),
                        (lawyer_stats or {}).get("last_clustering_run"),
                        key=lambda x: x or datetime.min
                    ) if case_stats or lawyer_stats else None,
                    "data_freshness_hours": self._calculate_data_freshness()
                },
                detailed_breakdown=detailed_breakdown,
                generated_at=datetime.now()
            )
            
            self.logger.info("✅ Estatísticas de clusterização coletadas")
            return stats
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao coletar estatísticas: {e}")
            # Retornar estatísticas vazias em caso de erro
            return ClusterStatsResponse(
                case_clustering=self._empty_cluster_stats(),
                lawyer_clustering=self._empty_cluster_stats(),
                quality_metrics={},
                system_health={"clustering_pipeline_status": "error"},
                generated_at=datetime.now()
            )
    
    # Métodos auxiliares privados
    
    async def _get_cluster_analytics(self, cluster_id: str, cluster_type: str) -> ClusterAnalytics:
        """Coleta analytics detalhados de um cluster."""
        
        try:
            # Query para analytics do cluster
            analytics_query = text(f"""
                SELECT 
                    COUNT(*) as total_members,
                    AVG(confidence_score) as avg_confidence,
                    MIN(created_at) as creation_date,
                    MAX(updated_at) as last_updated
                FROM {cluster_type}_clusters
                WHERE cluster_id = :cluster_id
            """)
            
            analytics_result = await self.db.execute(analytics_query, {"cluster_id": cluster_id})
            analytics_row = analytics_result.fetchone()
            
            # Query para distribuição de providers (se disponível)
            provider_query = text(f"""
                SELECT 
                    ce.embedding_provider,
                    COUNT(*) as count
                FROM {cluster_type}_embeddings ce
                JOIN {cluster_type}_clusters cc ON ce.{cluster_type}_id = cc.{cluster_type}_id
                WHERE cc.cluster_id = :cluster_id
                GROUP BY ce.embedding_provider
            """)
            
            try:
                provider_result = await self.db.execute(provider_query, {"cluster_id": cluster_id})
                provider_distribution = {row.embedding_provider: row.count for row in provider_result.fetchall()}
            except Exception:
                provider_distribution = {}
            
            return ClusterAnalytics(
                cluster_id=cluster_id,
                total_members=analytics_row.total_members,
                avg_confidence=float(analytics_row.avg_confidence or 0.0),
                provider_distribution=provider_distribution,
                data_sources_coverage={},  # TODO: Implementar se necessário
                quality_score=float(analytics_row.avg_confidence or 0.0),  # Placeholder
                momentum_score=0.0,  # Será obtido de cluster_metadata
                creation_date=analytics_row.creation_date,
                last_updated=analytics_row.last_updated
            )
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao obter analytics do cluster {cluster_id}: {e}")
            return ClusterAnalytics(
                cluster_id=cluster_id,
                total_members=0,
                avg_confidence=0.0,
                provider_distribution={},
                data_sources_coverage={},
                quality_score=0.0,
                momentum_score=0.0,
                creation_date=datetime.now(),
                last_updated=datetime.now()
            )
    
    async def _get_cluster_members(self, cluster_id: str, cluster_type: str, limit: int) -> List[ClusterMemberInfo]:
        """Busca membros de um cluster com informações básicas."""
        
        try:
            if cluster_type == "case":
                members_query = text("""
                    SELECT 
                        c.id,
                        c.title as name,
                        c.description,
                        cc.confidence_score,
                        cc.assigned_method,
                        cc.created_at
                    FROM case_clusters cc
                    JOIN cases c ON cc.case_id = c.id
                    WHERE cc.cluster_id = :cluster_id
                    ORDER BY cc.confidence_score DESC
                    LIMIT :limit
                """)
            else:  # lawyer
                members_query = text("""
                    SELECT 
                        l.id,
                        l.name,
                        l.bio as description,
                        lc.confidence_score,
                        lc.assigned_method,
                        lc.created_at
                    FROM lawyer_clusters lc
                    JOIN lawyers l ON lc.lawyer_id = l.id
                    WHERE lc.cluster_id = :cluster_id
                    ORDER BY lc.confidence_score DESC
                    LIMIT :limit
                """)
            
            members_result = await self.db.execute(members_query, {
                "cluster_id": cluster_id,
                "limit": limit
            })
            
            members = []
            for row in members_result.fetchall():
                member = ClusterMemberInfo(
                    entity_id=row.id,
                    entity_name=row.name,
                    description=row.description or "",
                    confidence_score=float(row.confidence_score),
                    assignment_method=row.assigned_method,
                    added_to_cluster_at=row.created_at
                )
                members.append(member)
            
            return members
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao buscar membros do cluster {cluster_id}: {e}")
            return []
    
    def _generate_partnership_reason(self, cluster_label: str, confidence: float, complementarity: float) -> str:
        """Gera razão textual para recomendação de parceria."""
        
        if complementarity > 0.8:
            strength = "excelente"
        elif complementarity > 0.6:
            strength = "boa"
        else:
            strength = "moderada"
        
        return f"Possui {strength} expertise em {cluster_label}, área complementar ao seu portfólio atual. Score de confiança: {confidence:.2f}"
    
    async def _get_quality_statistics(self) -> Dict[str, Any]:
        """Coleta estatísticas de qualidade dos clusters."""
        
        try:
            quality_query = text("""
                SELECT 
                    AVG(CASE WHEN total_items >= 5 THEN 1.0 ELSE 0.0 END) as cluster_size_quality,
                    AVG(momentum_score) as avg_momentum,
                    COUNT(CASE WHEN is_emergent = true THEN 1 END)::float / COUNT(*) as emergent_ratio
                FROM cluster_metadata
                WHERE cluster_id NOT LIKE '%_-1'
            """)
            
            result = await self.db.execute(quality_query)
            row = result.fetchone()
            
            return {
                "cluster_size_quality": float(row.cluster_size_quality or 0.0),
                "avg_momentum_score": float(row.avg_momentum or 0.0),
                "emergent_clusters_ratio": float(row.emergent_ratio or 0.0),
                "overall_quality_score": float((row.cluster_size_quality or 0.0) * 0.5 + (row.avg_momentum or 0.0) * 0.5)
            }
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao coletar estatísticas de qualidade: {e}")
            return {}
    
    async def _get_detailed_breakdown(self) -> Dict[str, Any]:
        """Coleta breakdown detalhado do sistema."""
        
        # TODO: Implementar breakdown detalhado se necessário
        return {
            "embedding_providers": {},
            "data_sources": {},
            "cluster_algorithms": {"umap_hdbscan": "primary"}
        }
    
    def _empty_cluster_stats(self) -> Dict[str, Any]:
        """Retorna estatísticas vazias para clusters."""
        return {
            "total_clusters": 0,
            "total_entities": 0,
            "avg_cluster_size": 0.0,
            "emergent_clusters": 0,
            "avg_momentum": 0.0,
            "last_clustering_run": None
        }
    
    def _calculate_data_freshness(self) -> int:
        """Calcula frescor dos dados em horas."""
        # TODO: Implementar cálculo baseado em timestamps reais
        return 24  # Placeholder 