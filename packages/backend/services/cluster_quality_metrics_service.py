#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Cluster Quality Metrics Service
===============================

Serviço especializado para análise de qualidade dos clusters.
Implementa métricas de qualidade, consistência e validação de embeddings.

Features:
- Silhouette Score Analysis
- Cluster Consistency Metrics
- Embedding Quality Assessment
- Provider Performance Comparison
- Quality Thresholds Validation
- Automated Quality Reports
"""

import asyncio
import logging
import numpy as np
import json
from datetime import datetime, timedelta
from typing import List, Dict, Any, Tuple, Optional, NamedTuple
from dataclasses import dataclass
from enum import Enum

# Imports científicos
try:
    from sklearn.metrics import silhouette_score, silhouette_samples
    from sklearn.metrics.pairwise import cosine_similarity, euclidean_distances
    from scipy import stats
    from scipy.spatial.distance import pdist, squareform
    import pandas as pd
    SCIENTIFIC_LIBS_AVAILABLE = True
except ImportError:
    logging.warning("⚠️ Bibliotecas científicas não instaladas: pip install scikit-learn scipy pandas")
    SCIENTIFIC_LIBS_AVAILABLE = False

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, text, and_, or_, func


class QualityThreshold(Enum):
    """Thresholds de qualidade para diferentes métricas."""
    EXCELLENT = 0.8
    GOOD = 0.6
    FAIR = 0.4
    POOR = 0.2


@dataclass
class SilhouetteAnalysis:
    """Análise de silhouette para um cluster."""
    cluster_id: str
    silhouette_avg: float
    silhouette_samples: List[float]
    quality_level: QualityThreshold
    outlier_indices: List[int]
    recommendations: List[str]


@dataclass
class ClusterConsistencyMetrics:
    """Métricas de consistência interna de um cluster."""
    cluster_id: str
    intra_cluster_distance: float
    inter_cluster_distance: float
    cohesion_score: float
    separation_score: float
    compactness_ratio: float
    provider_consistency: Dict[str, float]
    semantic_coherence: float


@dataclass
class EmbeddingQualityReport:
    """Relatório de qualidade dos embeddings por provider."""
    provider_name: str
    total_embeddings: int
    avg_vector_norm: float
    dimensionality_consistency: float
    variance_explained: float
    cluster_assignment_accuracy: float
    outlier_rate: float
    quality_score: float


@dataclass
class ClusterQualityReport:
    """Relatório completo de qualidade de um cluster."""
    cluster_id: str
    cluster_type: str
    silhouette_analysis: SilhouetteAnalysis
    consistency_metrics: ClusterConsistencyMetrics
    embedding_quality: List[EmbeddingQualityReport]
    overall_quality_score: float
    quality_level: QualityThreshold
    actionable_insights: List[str]
    generated_at: datetime


class ClusterQualityMetricsService:
    """Serviço para análise de qualidade dos clusters."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
        self.logger = logging.getLogger(__name__)
        
        if not SCIENTIFIC_LIBS_AVAILABLE:
            raise ImportError("Bibliotecas científicas não disponíveis para análise de qualidade")
        
        # Configurações de qualidade
        self.quality_thresholds = {
            'silhouette_score': {
                'excellent': 0.7,
                'good': 0.5,
                'fair': 0.3,
                'poor': 0.1
            },
            'cohesion_score': {
                'excellent': 0.8,
                'good': 0.6,
                'fair': 0.4,
                'poor': 0.2
            },
            'separation_score': {
                'excellent': 0.7,
                'good': 0.5,
                'fair': 0.3,
                'poor': 0.1
            }
        }
    
    async def analyze_cluster_quality(
        self, 
        cluster_id: str, 
        include_detailed_analysis: bool = True
    ) -> Optional[ClusterQualityReport]:
        """
        Análise completa de qualidade de um cluster específico.
        
        Args:
            cluster_id: ID do cluster a analisar
            include_detailed_analysis: Se incluir análises detalhadas (mais lento)
            
        Returns:
            Relatório completo de qualidade ou None se erro
        """
        
        try:
            self.logger.info(f"🔍 Analisando qualidade do cluster {cluster_id}")
            
            # 1. Obter dados do cluster
            cluster_data = await self._get_cluster_data(cluster_id)
            if not cluster_data:
                self.logger.warning(f"❌ Cluster {cluster_id} não encontrado")
                return None
            
            cluster_type = cluster_data['cluster_type']
            
            # 2. Obter embeddings do cluster
            embeddings_data = await self._get_cluster_embeddings(cluster_id, cluster_type)
            if len(embeddings_data) < 3:
                self.logger.warning(f"❌ Cluster {cluster_id} tem poucos membros para análise: {len(embeddings_data)}")
                return None
            
            # 3. Análise de Silhouette
            silhouette_analysis = await self._analyze_silhouette_score(
                cluster_id, embeddings_data, include_detailed_analysis
            )
            
            # 4. Métricas de Consistência
            consistency_metrics = await self._calculate_consistency_metrics(
                cluster_id, embeddings_data
            )
            
            # 5. Qualidade dos Embeddings por Provider
            embedding_quality = await self._analyze_embedding_quality_by_provider(
                embeddings_data
            )
            
            # 6. Score de qualidade geral
            overall_score = self._calculate_overall_quality_score(
                silhouette_analysis, consistency_metrics, embedding_quality
            )
            
            # 7. Insights acionáveis
            insights = self._generate_actionable_insights(
                silhouette_analysis, consistency_metrics, embedding_quality, overall_score
            )
            
            # 8. Compilar relatório
            quality_report = ClusterQualityReport(
                cluster_id=cluster_id,
                cluster_type=cluster_type,
                silhouette_analysis=silhouette_analysis,
                consistency_metrics=consistency_metrics,
                embedding_quality=embedding_quality,
                overall_quality_score=overall_score,
                quality_level=self._get_quality_level(overall_score),
                actionable_insights=insights,
                generated_at=datetime.now()
            )
            
            # 9. Salvar métricas no banco
            await self._save_quality_metrics(quality_report)
            
            self.logger.info(f"✅ Análise de qualidade concluída para {cluster_id}: {overall_score:.3f}")
            return quality_report
            
        except Exception as e:
            self.logger.error(f"❌ Erro na análise de qualidade do cluster {cluster_id}: {e}")
            return None
    
    async def analyze_all_clusters_quality(
        self, 
        cluster_type: str = None,
        batch_size: int = 10
    ) -> Dict[str, Any]:
        """
        Análise de qualidade em lote para todos os clusters.
        
        Args:
            cluster_type: Filtrar por tipo ('case', 'lawyer') ou None para todos
            batch_size: Tamanho do batch para processamento
            
        Returns:
            Relatório consolidado de qualidade
        """
        
        try:
            self.logger.info(f"📊 Iniciando análise de qualidade em lote (tipo: {cluster_type})")
            
            # 1. Obter lista de clusters
            clusters = await self._get_clusters_for_analysis(cluster_type)
            
            if not clusters:
                self.logger.warning("❌ Nenhum cluster encontrado para análise")
                return {}
            
            self.logger.info(f"🎯 Analisando {len(clusters)} clusters")
            
            # 2. Processar em batches
            quality_reports = []
            failed_analyses = []
            
            for i in range(0, len(clusters), batch_size):
                batch = clusters[i:i + batch_size]
                
                # Processar batch em paralelo
                batch_tasks = [
                    self.analyze_cluster_quality(cluster['cluster_id'], include_detailed_analysis=False)
                    for cluster in batch
                ]
                
                batch_results = await asyncio.gather(*batch_tasks, return_exceptions=True)
                
                # Processar resultados do batch
                for j, result in enumerate(batch_results):
                    if isinstance(result, Exception):
                        self.logger.error(f"Erro na análise do cluster {batch[j]['cluster_id']}: {result}")
                        failed_analyses.append(batch[j]['cluster_id'])
                        continue
                    
                    if result:
                        quality_reports.append(result)
                
                self.logger.debug(f"📊 Batch {i//batch_size + 1}/{(len(clusters) + batch_size - 1)//batch_size} concluído")
            
            # 3. Gerar relatório consolidado
            consolidated_report = self._generate_consolidated_quality_report(quality_reports)
            consolidated_report['failed_analyses'] = failed_analyses
            consolidated_report['total_analyzed'] = len(quality_reports)
            consolidated_report['success_rate'] = len(quality_reports) / len(clusters) if clusters else 0
            
            self.logger.info(f"✅ Análise em lote concluída: {len(quality_reports)}/{len(clusters)} clusters analisados")
            return consolidated_report
            
        except Exception as e:
            self.logger.error(f"❌ Erro na análise de qualidade em lote: {e}")
            return {}
    
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
            Resultado da validação com detalhes
        """
        
        try:
            thresholds = custom_thresholds or self.quality_thresholds
            
            # Obter análise de qualidade
            quality_report = await self.analyze_cluster_quality(cluster_id, include_detailed_analysis=False)
            if not quality_report:
                return {"valid": False, "error": "Cluster não encontrado ou não analisável"}
            
            # Validar thresholds
            validations = {}
            
            # Silhouette Score
            silhouette_threshold = thresholds.get('silhouette_score', {}).get('fair', 0.3)
            validations['silhouette_score'] = {
                "value": quality_report.silhouette_analysis.silhouette_avg,
                "threshold": silhouette_threshold,
                "passed": quality_report.silhouette_analysis.silhouette_avg >= silhouette_threshold
            }
            
            # Cohesion Score
            cohesion_threshold = thresholds.get('cohesion_score', {}).get('fair', 0.4)
            validations['cohesion_score'] = {
                "value": quality_report.consistency_metrics.cohesion_score,
                "threshold": cohesion_threshold,
                "passed": quality_report.consistency_metrics.cohesion_score >= cohesion_threshold
            }
            
            # Separation Score
            separation_threshold = thresholds.get('separation_score', {}).get('fair', 0.3)
            validations['separation_score'] = {
                "value": quality_report.consistency_metrics.separation_score,
                "threshold": separation_threshold,
                "passed": quality_report.consistency_metrics.separation_score >= separation_threshold
            }
            
            # Overall Quality
            overall_threshold = 0.5  # Threshold mínimo geral
            validations['overall_quality'] = {
                "value": quality_report.overall_quality_score,
                "threshold": overall_threshold,
                "passed": quality_report.overall_quality_score >= overall_threshold
            }
            
            # Resultado final
            all_passed = all(v["passed"] for v in validations.values())
            
            return {
                "cluster_id": cluster_id,
                "valid": all_passed,
                "validations": validations,
                "quality_level": quality_report.quality_level.name,
                "recommendations": quality_report.actionable_insights,
                "validated_at": datetime.now()
            }
            
        except Exception as e:
            self.logger.error(f"❌ Erro na validação de thresholds para {cluster_id}: {e}")
            return {"valid": False, "error": str(e)}
    
    async def generate_quality_trends_report(
        self, 
        days_back: int = 30
    ) -> Dict[str, Any]:
        """
        Gera relatório de tendências de qualidade ao longo do tempo.
        
        Args:
            days_back: Número de dias para análise histórica
            
        Returns:
            Relatório de tendências de qualidade
        """
        
        try:
            self.logger.info(f"📈 Gerando relatório de tendências de qualidade ({days_back} dias)")
            
            # Query para métricas históricas
            trends_query = text("""
                SELECT 
                    DATE(generated_at) as analysis_date,
                    cluster_type,
                    AVG(overall_quality_score) as avg_quality,
                    AVG(silhouette_score) as avg_silhouette,
                    AVG(cohesion_score) as avg_cohesion,
                    COUNT(*) as clusters_analyzed,
                    COUNT(CASE WHEN overall_quality_score >= 0.7 THEN 1 END) as high_quality_clusters,
                    COUNT(CASE WHEN overall_quality_score < 0.3 THEN 1 END) as low_quality_clusters
                FROM cluster_quality_metrics
                WHERE generated_at >= NOW() - INTERVAL :days_back DAY
                GROUP BY DATE(generated_at), cluster_type
                ORDER BY analysis_date DESC, cluster_type
            """)
            
            result = await self.db.execute(trends_query, {"days_back": days_back})
            trends_data = result.fetchall()
            
            # Organizar dados por tipo
            case_trends = []
            lawyer_trends = []
            
            for row in trends_data:
                trend_data = {
                    "date": row.analysis_date.isoformat(),
                    "avg_quality": float(row.avg_quality or 0),
                    "avg_silhouette": float(row.avg_silhouette or 0),
                    "avg_cohesion": float(row.avg_cohesion or 0),
                    "clusters_analyzed": row.clusters_analyzed,
                    "high_quality_clusters": row.high_quality_clusters,
                    "low_quality_clusters": row.low_quality_clusters,
                    "quality_rate": (row.high_quality_clusters / row.clusters_analyzed) if row.clusters_analyzed > 0 else 0
                }
                
                if row.cluster_type == "case":
                    case_trends.append(trend_data)
                elif row.cluster_type == "lawyer":
                    lawyer_trends.append(trend_data)
            
            # Calcular tendências gerais
            overall_trends = self._calculate_trend_statistics(case_trends + lawyer_trends)
            
            # Identificar anomalias
            quality_anomalies = self._detect_quality_anomalies(case_trends + lawyer_trends)
            
            return {
                "case_clusters": {
                    "trends": case_trends,
                    "statistics": self._calculate_trend_statistics(case_trends)
                },
                "lawyer_clusters": {
                    "trends": lawyer_trends,
                    "statistics": self._calculate_trend_statistics(lawyer_trends)
                },
                "overall_trends": overall_trends,
                "quality_anomalies": quality_anomalies,
                "period": {
                    "days_analyzed": days_back,
                    "start_date": (datetime.now() - timedelta(days=days_back)).isoformat(),
                    "end_date": datetime.now().isoformat()
                },
                "generated_at": datetime.now().isoformat()
            }
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao gerar relatório de tendências: {e}")
            return {}
    
    # Métodos auxiliares privados
    
    async def _get_cluster_data(self, cluster_id: str) -> Optional[Dict[str, Any]]:
        """Obter dados básicos do cluster."""
        
        try:
            query = text("""
                SELECT cluster_id, cluster_type, total_items, created_at
                FROM cluster_metadata
                WHERE cluster_id = :cluster_id
            """)
            
            result = await self.db.execute(query, {"cluster_id": cluster_id})
            row = result.fetchone()
            
            if row:
                return {
                    "cluster_id": row.cluster_id,
                    "cluster_type": row.cluster_type,
                    "total_items": row.total_items,
                    "created_at": row.created_at
                }
            
            return None
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao obter dados do cluster {cluster_id}: {e}")
            return None
    
    async def _get_cluster_embeddings(self, cluster_id: str, cluster_type: str) -> List[Dict[str, Any]]:
        """Obter embeddings dos membros do cluster."""
        
        try:
            # Query baseada no tipo de cluster
            if cluster_type == "case":
                query = text("""
                    SELECT 
                        cc.case_id as entity_id,
                        cc.confidence_score,
                        ce.embedding_vector,
                        ce.embedding_provider,
                        ce.embedding_dim
                    FROM case_clusters cc
                    JOIN case_embeddings ce ON cc.case_id = ce.case_id
                    WHERE cc.cluster_id = :cluster_id
                        AND ce.embedding_vector IS NOT NULL
                    ORDER BY cc.confidence_score DESC
                """)
            else:  # lawyer
                query = text("""
                    SELECT 
                        lc.lawyer_id as entity_id,
                        lc.confidence_score,
                        le.embedding_vector,
                        le.embedding_provider,
                        le.embedding_dim
                    FROM lawyer_clusters lc
                    JOIN lawyer_embeddings le ON lc.lawyer_id = le.lawyer_id
                    WHERE lc.cluster_id = :cluster_id
                        AND le.embedding_vector IS NOT NULL
                    ORDER BY lc.confidence_score DESC
                """)
            
            result = await self.db.execute(query, {"cluster_id": cluster_id})
            rows = result.fetchall()
            
            embeddings_data = []
            for row in rows:
                # Parsear embedding vector (assumindo JSON)
                try:
                    if isinstance(row.embedding_vector, str):
                        embedding = json.loads(row.embedding_vector)
                    else:
                        embedding = row.embedding_vector
                    
                    embeddings_data.append({
                        "entity_id": row.entity_id,
                        "confidence_score": float(row.confidence_score),
                        "embedding": np.array(embedding),
                        "provider": row.embedding_provider,
                        "embedding_dim": row.embedding_dim
                    })
                except Exception as e:
                    self.logger.warning(f"Erro ao parsear embedding para {row.entity_id}: {e}")
                    continue
            
            return embeddings_data
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao obter embeddings do cluster {cluster_id}: {e}")
            return []
    
    async def _analyze_silhouette_score(
        self, 
        cluster_id: str, 
        embeddings_data: List[Dict[str, Any]],
        detailed: bool = True
    ) -> SilhouetteAnalysis:
        """Análise detalhada de silhouette score."""
        
        try:
            # Extrair embeddings e criar labels dummy (todos do mesmo cluster)
            embeddings_matrix = np.array([item["embedding"] for item in embeddings_data])
            cluster_labels = np.zeros(len(embeddings_data))  # Todos no mesmo cluster
            
            # Precisa de pelo menos 2 clusters para silhouette, então vamos usar outros clusters como referência
            other_embeddings = await self._get_reference_embeddings_for_silhouette(
                cluster_id, len(embeddings_data)
            )
            
            if other_embeddings:
                # Combinar com embeddings de outros clusters
                all_embeddings = np.vstack([embeddings_matrix, other_embeddings])
                all_labels = np.hstack([
                    np.zeros(len(embeddings_data)),  # Cluster atual = 0
                    np.ones(len(other_embeddings))   # Outros clusters = 1
                ])
                
                # Calcular silhouette score
                silhouette_avg = silhouette_score(all_embeddings, all_labels)
                
                if detailed:
                    silhouette_samples_scores = silhouette_samples(all_embeddings, all_labels)
                    # Pegar apenas os scores das amostras do cluster atual
                    cluster_silhouette_samples = silhouette_samples_scores[:len(embeddings_data)]
                else:
                    cluster_silhouette_samples = []
                
            else:
                # Fallback: usar intra-cluster cohesion como proxy
                if len(embeddings_matrix) >= 2:
                    pairwise_distances = pdist(embeddings_matrix, metric='cosine')
                    avg_distance = np.mean(pairwise_distances)
                    silhouette_avg = max(0, 1 - avg_distance)  # Converter para score positivo
                else:
                    silhouette_avg = 0.5  # Score neutro para clusters muito pequenos
                
                cluster_silhouette_samples = []
            
            # Identificar outliers baseado nos scores individuais
            outlier_indices = []
            if cluster_silhouette_samples:
                threshold = np.percentile(cluster_silhouette_samples, 10)  # Bottom 10%
                outlier_indices = [
                    i for i, score in enumerate(cluster_silhouette_samples) 
                    if score < threshold
                ]
            
            # Determinar qualidade e recomendações
            quality_level = self._get_quality_level(silhouette_avg)
            recommendations = self._generate_silhouette_recommendations(
                silhouette_avg, len(outlier_indices), len(embeddings_data)
            )
            
            return SilhouetteAnalysis(
                cluster_id=cluster_id,
                silhouette_avg=silhouette_avg,
                silhouette_samples=cluster_silhouette_samples.tolist() if len(cluster_silhouette_samples) > 0 else [],
                quality_level=quality_level,
                outlier_indices=outlier_indices,
                recommendations=recommendations
            )
            
        except Exception as e:
            self.logger.error(f"❌ Erro na análise de silhouette para {cluster_id}: {e}")
            return SilhouetteAnalysis(
                cluster_id=cluster_id,
                silhouette_avg=0.0,
                silhouette_samples=[],
                quality_level=QualityThreshold.POOR,
                outlier_indices=[],
                recommendations=["Erro na análise de qualidade"]
            )
    
    async def _calculate_consistency_metrics(
        self, 
        cluster_id: str, 
        embeddings_data: List[Dict[str, Any]]
    ) -> ClusterConsistencyMetrics:
        """Calcular métricas de consistência interna do cluster."""
        
        try:
            embeddings_matrix = np.array([item["embedding"] for item in embeddings_data])
            
            # 1. Intra-cluster distance (compactness)
            if len(embeddings_matrix) >= 2:
                pairwise_distances = pdist(embeddings_matrix, metric='cosine')
                intra_cluster_distance = np.mean(pairwise_distances)
            else:
                intra_cluster_distance = 0.0
            
            # 2. Inter-cluster distance (separation)
            inter_cluster_distance = await self._calculate_inter_cluster_distance(
                cluster_id, embeddings_matrix
            )
            
            # 3. Cohesion score (quanto menor a distância interna, melhor)
            cohesion_score = max(0, 1 - intra_cluster_distance) if intra_cluster_distance > 0 else 1.0
            
            # 4. Separation score (quanto maior a distância para outros clusters, melhor)
            separation_score = min(1, inter_cluster_distance) if inter_cluster_distance > 0 else 0.0
            
            # 5. Compactness ratio
            compactness_ratio = (
                inter_cluster_distance / intra_cluster_distance 
                if intra_cluster_distance > 0 else 1.0
            )
            
            # 6. Consistência por provider
            provider_consistency = self._calculate_provider_consistency(embeddings_data)
            
            # 7. Coerência semântica (baseada na variação dos embeddings)
            semantic_coherence = self._calculate_semantic_coherence(embeddings_matrix)
            
            return ClusterConsistencyMetrics(
                cluster_id=cluster_id,
                intra_cluster_distance=intra_cluster_distance,
                inter_cluster_distance=inter_cluster_distance,
                cohesion_score=cohesion_score,
                separation_score=separation_score,
                compactness_ratio=compactness_ratio,
                provider_consistency=provider_consistency,
                semantic_coherence=semantic_coherence
            )
            
        except Exception as e:
            self.logger.error(f"❌ Erro no cálculo de consistência para {cluster_id}: {e}")
            return ClusterConsistencyMetrics(
                cluster_id=cluster_id,
                intra_cluster_distance=1.0,
                inter_cluster_distance=0.0,
                cohesion_score=0.0,
                separation_score=0.0,
                compactness_ratio=0.0,
                provider_consistency={},
                semantic_coherence=0.0
            )
    
    async def _analyze_embedding_quality_by_provider(
        self, 
        embeddings_data: List[Dict[str, Any]]
    ) -> List[EmbeddingQualityReport]:
        """Análise de qualidade por provider de embedding."""
        
        try:
            # Agrupar por provider
            provider_groups = {}
            for item in embeddings_data:
                provider = item["provider"]
                if provider not in provider_groups:
                    provider_groups[provider] = []
                provider_groups[provider].append(item)
            
            quality_reports = []
            
            for provider, items in provider_groups.items():
                embeddings_matrix = np.array([item["embedding"] for item in items])
                
                # Métricas básicas
                total_embeddings = len(items)
                avg_vector_norm = np.mean([np.linalg.norm(item["embedding"]) for item in items])
                
                # Consistência dimensional
                dimensions = [len(item["embedding"]) for item in items]
                dimensionality_consistency = 1.0 if len(set(dimensions)) == 1 else 0.0
                
                # Variância explicada (PCA)
                if len(embeddings_matrix) >= 2:
                    try:
                        from sklearn.decomposition import PCA
                        pca = PCA(n_components=min(5, len(embeddings_matrix)-1))
                        pca.fit(embeddings_matrix)
                        variance_explained = np.sum(pca.explained_variance_ratio_[:3])  # Top 3 componentes
                    except:
                        variance_explained = 0.5  # Fallback
                else:
                    variance_explained = 0.5
                
                # Accuracy de atribuição de cluster (baseada na confidence)
                confidences = [item["confidence_score"] for item in items]
                cluster_assignment_accuracy = np.mean(confidences)
                
                # Taxa de outliers (confidence muito baixa)
                outlier_threshold = 0.3
                outlier_rate = sum(1 for conf in confidences if conf < outlier_threshold) / total_embeddings
                
                # Score de qualidade geral
                quality_score = (
                    dimensionality_consistency * 0.2 +
                    min(1.0, variance_explained) * 0.3 +
                    cluster_assignment_accuracy * 0.3 +
                    (1 - outlier_rate) * 0.2
                )
                
                quality_reports.append(EmbeddingQualityReport(
                    provider_name=provider,
                    total_embeddings=total_embeddings,
                    avg_vector_norm=avg_vector_norm,
                    dimensionality_consistency=dimensionality_consistency,
                    variance_explained=variance_explained,
                    cluster_assignment_accuracy=cluster_assignment_accuracy,
                    outlier_rate=outlier_rate,
                    quality_score=quality_score
                ))
            
            return quality_reports
            
        except Exception as e:
            self.logger.error(f"❌ Erro na análise de qualidade por provider: {e}")
            return []
    
    def _calculate_overall_quality_score(
        self,
        silhouette_analysis: SilhouetteAnalysis,
        consistency_metrics: ClusterConsistencyMetrics,
        embedding_quality: List[EmbeddingQualityReport]
    ) -> float:
        """Calcular score de qualidade geral ponderado."""
        
        try:
            # Pesos para diferentes métricas
            weights = {
                'silhouette': 0.3,
                'cohesion': 0.25,
                'separation': 0.2,
                'embedding_quality': 0.15,
                'semantic_coherence': 0.1
            }
            
            # Normalizar scores
            silhouette_normalized = max(0, min(1, silhouette_analysis.silhouette_avg))
            cohesion_normalized = max(0, min(1, consistency_metrics.cohesion_score))
            separation_normalized = max(0, min(1, consistency_metrics.separation_score))
            semantic_normalized = max(0, min(1, consistency_metrics.semantic_coherence))
            
            # Qualidade média dos embeddings
            if embedding_quality:
                avg_embedding_quality = np.mean([eq.quality_score for eq in embedding_quality])
            else:
                avg_embedding_quality = 0.5  # Score neutro
            
            # Calcular score final ponderado
            overall_score = (
                silhouette_normalized * weights['silhouette'] +
                cohesion_normalized * weights['cohesion'] +
                separation_normalized * weights['separation'] +
                avg_embedding_quality * weights['embedding_quality'] +
                semantic_normalized * weights['semantic_coherence']
            )
            
            return max(0.0, min(1.0, overall_score))
            
        except Exception as e:
            self.logger.error(f"❌ Erro no cálculo de qualidade geral: {e}")
            return 0.0
    
    def _get_quality_level(self, score: float) -> QualityThreshold:
        """Determinar nível de qualidade baseado no score."""
        if score >= 0.8:
            return QualityThreshold.EXCELLENT
        elif score >= 0.6:
            return QualityThreshold.GOOD
        elif score >= 0.4:
            return QualityThreshold.FAIR
        else:
            return QualityThreshold.POOR
    
    def _generate_actionable_insights(
        self,
        silhouette_analysis: SilhouetteAnalysis,
        consistency_metrics: ClusterConsistencyMetrics,
        embedding_quality: List[EmbeddingQualityReport],
        overall_score: float
    ) -> List[str]:
        """Gerar insights acionáveis baseados na análise."""
        
        insights = []
        
        # Insights de silhouette
        if silhouette_analysis.silhouette_avg < 0.3:
            insights.append("⚠️ Baixa coesão do cluster - considere re-clusterização ou divisão")
        
        if len(silhouette_analysis.outlier_indices) > 0:
            outlier_ratio = len(silhouette_analysis.outlier_indices) / max(1, len(silhouette_analysis.silhouette_samples))
            if outlier_ratio > 0.2:
                insights.append(f"🎯 {outlier_ratio*100:.1f}% de outliers detectados - revisar atribuições")
        
        # Insights de consistência
        if consistency_metrics.cohesion_score < 0.5:
            insights.append("🔧 Baixa coesão interna - membros muito dispersos")
        
        if consistency_metrics.separation_score < 0.4:
            insights.append("📊 Baixa separação de outros clusters - possível sobreposição")
        
        if consistency_metrics.compactness_ratio < 1.5:
            insights.append("⚖️ Cluster pouco compacto comparado à separação")
        
        # Insights de embedding quality
        low_quality_providers = [eq for eq in embedding_quality if eq.quality_score < 0.5]
        if low_quality_providers:
            provider_names = [eq.provider_name for eq in low_quality_providers]
            insights.append(f"🧠 Qualidade baixa nos providers: {', '.join(provider_names)}")
        
        # Insights gerais
        if overall_score < 0.4:
            insights.append("🚨 Cluster de baixa qualidade - necessita reestruturação")
        elif overall_score < 0.6:
            insights.append("⚡ Qualidade moderada - pequenos ajustes podem melhorar")
        elif overall_score >= 0.8:
            insights.append("✨ Cluster de alta qualidade - manter monitoramento")
        
        return insights
    
    async def _save_quality_metrics(self, quality_report: ClusterQualityReport):
        """Salvar métricas de qualidade no banco."""
        
        try:
            # Criar tabela se não existir
            create_table_query = text("""
                CREATE TABLE IF NOT EXISTS cluster_quality_metrics (
                    id SERIAL PRIMARY KEY,
                    cluster_id VARCHAR(100) NOT NULL,
                    cluster_type VARCHAR(20) NOT NULL,
                    silhouette_score FLOAT,
                    cohesion_score FLOAT,
                    separation_score FLOAT,
                    semantic_coherence FLOAT,
                    overall_quality_score FLOAT,
                    quality_level VARCHAR(20),
                    total_outliers INTEGER DEFAULT 0,
                    provider_distribution JSON,
                    actionable_insights TEXT[],
                    generated_at TIMESTAMP DEFAULT NOW(),
                    INDEX idx_cluster_quality_cluster_id (cluster_id),
                    INDEX idx_cluster_quality_generated_at (generated_at)
                )
            """)
            
            try:
                await self.db.execute(create_table_query)
            except Exception:
                pass  # Tabela já existe
            
            # Inserir métricas
            insert_query = text("""
                INSERT INTO cluster_quality_metrics (
                    cluster_id, cluster_type, silhouette_score, cohesion_score,
                    separation_score, semantic_coherence, overall_quality_score,
                    quality_level, total_outliers, provider_distribution,
                    actionable_insights, generated_at
                ) VALUES (
                    :cluster_id, :cluster_type, :silhouette_score, :cohesion_score,
                    :separation_score, :semantic_coherence, :overall_quality_score,
                    :quality_level, :total_outliers, :provider_distribution,
                    :actionable_insights, :generated_at
                )
            """)
            
            # Preparar dados para inserção
            provider_distribution = {
                eq.provider_name: {
                    "count": eq.total_embeddings,
                    "quality_score": eq.quality_score
                }
                for eq in quality_report.embedding_quality
            }
            
            await self.db.execute(insert_query, {
                "cluster_id": quality_report.cluster_id,
                "cluster_type": quality_report.cluster_type,
                "silhouette_score": quality_report.silhouette_analysis.silhouette_avg,
                "cohesion_score": quality_report.consistency_metrics.cohesion_score,
                "separation_score": quality_report.consistency_metrics.separation_score,
                "semantic_coherence": quality_report.consistency_metrics.semantic_coherence,
                "overall_quality_score": quality_report.overall_quality_score,
                "quality_level": quality_report.quality_level.name,
                "total_outliers": len(quality_report.silhouette_analysis.outlier_indices),
                "provider_distribution": json.dumps(provider_distribution),
                "actionable_insights": quality_report.actionable_insights,
                "generated_at": quality_report.generated_at
            })
            
            await self.db.commit()
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao salvar métricas de qualidade: {e}")
            await self.db.rollback()
    
    # Métodos auxiliares adicionais (implementação resumida)
    
    async def _get_reference_embeddings_for_silhouette(self, cluster_id: str, sample_size: int) -> Optional[np.ndarray]:
        """Obter embeddings de outros clusters para comparação no silhouette."""
        # Implementação simplificada - retorna None para usar fallback
        return None
    
    async def _calculate_inter_cluster_distance(self, cluster_id: str, embeddings_matrix: np.ndarray) -> float:
        """Calcular distância média para outros clusters."""
        # Implementação simplificada
        return 0.5
    
    def _calculate_provider_consistency(self, embeddings_data: List[Dict[str, Any]]) -> Dict[str, float]:
        """Calcular consistência por provider."""
        providers = {}
        for item in embeddings_data:
            provider = item["provider"]
            if provider not in providers:
                providers[provider] = []
            providers[provider].append(item["confidence_score"])
        
        return {
            provider: np.std(scores) if len(scores) > 1 else 0.0
            for provider, scores in providers.items()
        }
    
    def _calculate_semantic_coherence(self, embeddings_matrix: np.ndarray) -> float:
        """Calcular coerência semântica baseada na variação."""
        if len(embeddings_matrix) < 2:
            return 1.0
        
        # Usar coeficiente de variação como proxy
        mean_norms = np.mean([np.linalg.norm(emb) for emb in embeddings_matrix])
        std_norms = np.std([np.linalg.norm(emb) for emb in embeddings_matrix])
        
        if mean_norms > 0:
            cv = std_norms / mean_norms
            coherence = max(0, 1 - cv)  # Menor variação = maior coerência
        else:
            coherence = 0.0
        
        return coherence
    
    def _generate_silhouette_recommendations(self, score: float, outliers: int, total: int) -> List[str]:
        """Gerar recomendações baseadas no silhouette score."""
        recommendations = []
        
        if score < 0.3:
            recommendations.append("Considere re-clusterização com parâmetros diferentes")
        if outliers > total * 0.2:
            recommendations.append("Revisar atribuição de outliers ao cluster")
        if score > 0.7:
            recommendations.append("Cluster bem estruturado - manter configuração")
        
        return recommendations
    
    async def _get_clusters_for_analysis(self, cluster_type: str = None) -> List[Dict[str, Any]]:
        """Obter lista de clusters para análise."""
        try:
            conditions = ["total_items >= 3"]  # Mínimo para análise
            
            if cluster_type:
                conditions.append("cluster_type = :cluster_type")
            
            query = text(f"""
                SELECT cluster_id, cluster_type, total_items
                FROM cluster_metadata
                WHERE {' AND '.join(conditions)}
                ORDER BY total_items DESC
                LIMIT 100
            """)
            
            params = {}
            if cluster_type:
                params["cluster_type"] = cluster_type
            
            result = await self.db.execute(query, params)
            return [
                {
                    "cluster_id": row.cluster_id,
                    "cluster_type": row.cluster_type,
                    "total_items": row.total_items
                }
                for row in result.fetchall()
            ]
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao obter clusters para análise: {e}")
            return []
    
    def _generate_consolidated_quality_report(self, quality_reports: List[ClusterQualityReport]) -> Dict[str, Any]:
        """Gerar relatório consolidado de qualidade."""
        
        if not quality_reports:
            return {}
        
        # Estatísticas gerais
        overall_scores = [report.overall_quality_score for report in quality_reports]
        silhouette_scores = [report.silhouette_analysis.silhouette_avg for report in quality_reports]
        
        # Distribuição por nível de qualidade
        quality_distribution = {}
        for report in quality_reports:
            level = report.quality_level.name
            quality_distribution[level] = quality_distribution.get(level, 0) + 1
        
        # Providers performance
        provider_performance = {}
        for report in quality_reports:
            for eq_report in report.embedding_quality:
                provider = eq_report.provider_name
                if provider not in provider_performance:
                    provider_performance[provider] = []
                provider_performance[provider].append(eq_report.quality_score)
        
        # Média por provider
        provider_avg_quality = {
            provider: np.mean(scores)
            for provider, scores in provider_performance.items()
        }
        
        return {
            "summary": {
                "total_clusters_analyzed": len(quality_reports),
                "avg_overall_quality": np.mean(overall_scores),
                "avg_silhouette_score": np.mean(silhouette_scores),
                "quality_distribution": quality_distribution
            },
            "provider_performance": provider_avg_quality,
            "quality_trends": {
                "high_quality_clusters": sum(1 for score in overall_scores if score >= 0.7),
                "medium_quality_clusters": sum(1 for score in overall_scores if 0.4 <= score < 0.7),
                "low_quality_clusters": sum(1 for score in overall_scores if score < 0.4)
            },
            "generated_at": datetime.now().isoformat()
        }
    
    def _calculate_trend_statistics(self, trends_data: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Calcular estatísticas de tendência."""
        if not trends_data:
            return {}
        
        quality_scores = [item["avg_quality"] for item in trends_data]
        
        return {
            "avg_quality": np.mean(quality_scores),
            "quality_trend": "improving" if len(quality_scores) > 1 and quality_scores[-1] > quality_scores[0] else "stable",
            "best_day": max(trends_data, key=lambda x: x["avg_quality"])["date"] if trends_data else None,
            "worst_day": min(trends_data, key=lambda x: x["avg_quality"])["date"] if trends_data else None
        }
    
    def _detect_quality_anomalies(self, trends_data: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Detectar anomalias na qualidade."""
        if len(trends_data) < 3:
            return []
        
        quality_scores = [item["avg_quality"] for item in trends_data]
        mean_quality = np.mean(quality_scores)
        std_quality = np.std(quality_scores)
        
        anomalies = []
        for item in trends_data:
            z_score = abs((item["avg_quality"] - mean_quality) / std_quality) if std_quality > 0 else 0
            if z_score > 2:  # Anomalia se Z-score > 2
                anomalies.append({
                    "date": item["date"],
                    "quality_score": item["avg_quality"],
                    "deviation": z_score,
                    "type": "low_quality" if item["avg_quality"] < mean_quality else "high_quality"
                })
        
        return anomalies


# Função factory para criar o serviço
def create_quality_metrics_service(db: AsyncSession) -> ClusterQualityMetricsService:
    """Factory para criar instância do serviço de métricas de qualidade."""
    return ClusterQualityMetricsService(db) 