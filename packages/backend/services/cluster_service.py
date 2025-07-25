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

# Importar serviço de métricas de qualidade
try:
    from services.cluster_quality_metrics_service import (
        ClusterQualityMetricsService,
        create_quality_metrics_service
    )
    QUALITY_METRICS_AVAILABLE = True
except ImportError:
    QUALITY_METRICS_AVAILABLE = False
    logging.warning("⚠️ Serviço de métricas de qualidade não disponível")


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
        
        # Inicializar serviço de métricas de qualidade se disponível
        if QUALITY_METRICS_AVAILABLE:
            self.quality_metrics_service = create_quality_metrics_service(db)
        else:
            self.quality_metrics_service = None
    
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
        Usa algoritmo avançado do `PartnershipRecommendationService`.
        """
        try:
            from services.partnership_recommendation_service import PartnershipRecommendationService

            recommender = PartnershipRecommendationService(self.db)
            raw_recs = await recommender.get_recommendations(
                lawyer_id,
                limit=limit,
                min_confidence=min_compatibility_score,
                exclude_same_firm=exclude_same_firm,
            )

            responses: List[PartnershipRecommendationResponse] = []
            for r in raw_recs:
                responses.append(
                    PartnershipRecommendationResponse(
                        recommended_lawyer_id=r.lawyer_id,
                        lawyer_name=r.lawyer_name,
                        firm_name=r.firm_name,
                        cluster_expertise=', '.join(r.compatibility_clusters[:3]),
                        compatibility_score=round(r.final_score, 3),
                        confidence_in_expertise=round(r.complementarity_score, 3),
                        complementarity_score=round(r.complementarity_score, 3),
                        recommendation_reason=r.recommendation_reason,
                        potential_synergies=[
                            f"Expertise complementar em {c}" for c in r.compatibility_clusters[:3]
                        ] + ([f"Sinergia entre escritórios: {r.firm_synergy_reason}"] if r.firm_synergy_reason else []),
                    )
                )

            return responses
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
    
    async def analyze_cluster_quality(
        self, 
        cluster_id: str,
        include_detailed_analysis: bool = True
    ) -> Optional[Dict[str, Any]]:
        """
        Análise completa de qualidade de um cluster específico.
        
        Args:
            cluster_id: ID do cluster a analisar
            include_detailed_analysis: Se incluir análises detalhadas
            
        Returns:
            Relatório de qualidade ou None se não disponível
        """
        
        if not self.quality_metrics_service:
            self.logger.warning("❌ Serviço de métricas de qualidade não disponível")
            return None
        
        try:
            self.logger.info(f"🔍 Analisando qualidade do cluster {cluster_id}")
            
            quality_report = await self.quality_metrics_service.analyze_cluster_quality(
                cluster_id, include_detailed_analysis
            )
            
            if quality_report:
                # Converter para formato de resposta da API
                return {
                    "cluster_id": quality_report.cluster_id,
                    "cluster_type": quality_report.cluster_type,
                    "overall_quality_score": quality_report.overall_quality_score,
                    "quality_level": quality_report.quality_level.name,
                    "silhouette_score": quality_report.silhouette_analysis.silhouette_avg,
                    "cohesion_score": quality_report.consistency_metrics.cohesion_score,
                    "separation_score": quality_report.consistency_metrics.separation_score,
                    "semantic_coherence": quality_report.consistency_metrics.semantic_coherence,
                    "provider_quality": {
                        eq.provider_name: {
                            "total_embeddings": eq.total_embeddings,
                            "quality_score": eq.quality_score,
                            "outlier_rate": eq.outlier_rate
                        }
                        for eq in quality_report.embedding_quality
                    },
                    "outliers_detected": len(quality_report.silhouette_analysis.outlier_indices),
                    "actionable_insights": quality_report.actionable_insights,
                    "generated_at": quality_report.generated_at.isoformat()
                }
            
            return None
            
        except Exception as e:
            self.logger.error(f"❌ Erro na análise de qualidade do cluster {cluster_id}: {e}")
            return None
    
    async def validate_cluster_quality_thresholds(
        self, 
        cluster_id: str,
        custom_thresholds: Dict[str, float] = None
    ) -> Dict[str, Any]:
        """
        Valida se um cluster atende aos thresholds de qualidade.
        
        Args:
            cluster_id: ID do cluster
            custom_thresholds: Thresholds customizados (opcional)
            
        Returns:
            Resultado da validação
        """
        
        if not self.quality_metrics_service:
            return {"valid": False, "error": "Serviço de métricas não disponível"}
        
        try:
            return await self.quality_metrics_service.validate_cluster_quality_thresholds(
                cluster_id, custom_thresholds
            )
            
        except Exception as e:
            self.logger.error(f"❌ Erro na validação de qualidade: {e}")
            return {"valid": False, "error": str(e)}
    
    async def get_quality_trends_report(self, days_back: int = 30) -> Dict[str, Any]:
        """
        Gera relatório de tendências de qualidade ao longo do tempo.
        
        Args:
            days_back: Número de dias para análise histórica
            
        Returns:
            Relatório de tendências
        """
        
        if not self.quality_metrics_service:
            return {"error": "Serviço de métricas não disponível"}
        
        try:
            return await self.quality_metrics_service.generate_quality_trends_report(days_back)
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao gerar relatório de tendências: {e}")
            return {"error": str(e)}
    
    async def analyze_all_clusters_quality(
        self, 
        cluster_type: str = None,
        batch_size: int = 10
    ) -> Dict[str, Any]:
        """
        Análise de qualidade em lote para todos os clusters.
        
        Args:
            cluster_type: Filtrar por tipo ou None para todos
            batch_size: Tamanho do batch
            
        Returns:
            Relatório consolidado
        """
        
        if not self.quality_metrics_service:
            return {"error": "Serviço de métricas não disponível"}
        
        try:
            self.logger.info(f"📊 Iniciando análise de qualidade em lote (tipo: {cluster_type})")
            
            return await self.quality_metrics_service.analyze_all_clusters_quality(
                cluster_type, batch_size
            )
            
        except Exception as e:
            self.logger.error(f"❌ Erro na análise em lote: {e}")
            return {"error": str(e)}
    
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