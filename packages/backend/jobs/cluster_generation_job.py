#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Cluster Generation Job
======================

Job para geração automatizada de clusters de casos e advogados usando:
- Coleta multi-fonte de dados (Escavador, Perplexity, Deep Research, LinkedIn)
- Embeddings híbridos com cascata Gemini → OpenAI → Local
- Clusterização consciente da origem: UMAP + HDBSCAN
- Rotulagem automática via LLM
- Detecção de clusters emergentes

Execução: A cada 6-12 horas via scheduler
"""

import asyncio
import logging
import numpy as np
import json
from datetime import datetime, timedelta
from typing import List, Dict, Any, Tuple, Optional
from dataclasses import dataclass
from pathlib import Path

# Imports científicos
try:
    import umap
    import hdbscan
    from sklearn.metrics import silhouette_score
    from sklearn.preprocessing import StandardScaler
    CLUSTERING_AVAILABLE = True
except ImportError:
    logging.warning("⚠️ Bibliotecas de clustering não instaladas: pip install umap-learn hdbscan scikit-learn")
    CLUSTERING_AVAILABLE = False

# Imports do projeto
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, text, and_, or_
from database import get_async_session

# Serviços
from services.cluster_data_collection_service import (
    ClusterDataCollectionService, 
    ConsolidatedClusterData, 
    ClusterDataType
)
from services.embedding_service import generate_embedding_with_provider
from services.cluster_labeling_service import ClusterLabelingService


@dataclass
class ClusteringConfig:
    """Configurações para clusterização."""
    # UMAP parameters
    umap_n_neighbors: int = 15
    umap_min_dist: float = 0.1
    umap_metric: str = 'cosine'
    umap_n_components: int = 50  # Redução dimensional intermediária
    
    # HDBSCAN parameters  
    hdbscan_min_cluster_size: int = 5
    hdbscan_min_samples: int = 3
    hdbscan_cluster_selection_epsilon: float = 0.05
    hdbscan_metric: str = 'euclidean'
    
    # Embedding quality thresholds
    high_quality_providers: List[str] = None
    similarity_threshold: float = 0.7  # Para atribuir embeddings locais
    
    # Cluster validation
    min_silhouette_score: float = 0.3
    max_clusters: int = 100
    min_cluster_members: int = 3
    
    def __post_init__(self):
        if self.high_quality_providers is None:
            self.high_quality_providers = ['gemini', 'openai']


@dataclass
class ClusterResult:
    """Resultado de clusterização para uma entidade."""
    entity_id: str
    cluster_id: str
    confidence_score: float
    embedding_provider: str
    data_sources: Dict[str, bool]
    assignment_method: str  # 'hdbscan', 'similarity', 'outlier'


@dataclass
class ClusterMetadata:
    """Metadados de um cluster."""
    cluster_id: str
    cluster_type: str  # 'case' ou 'lawyer'
    total_members: int
    centroid: List[float]
    silhouette_score: float
    member_providers: Dict[str, int]  # {'gemini': 10, 'openai': 5, 'local': 2}
    data_quality_avg: float
    created_at: datetime


class ClusterGenerationJob:
    """Job principal para geração de clusters."""
    
    def __init__(self, config: Optional[ClusteringConfig] = None):
        self.config = config or ClusteringConfig()
        self.logger = logging.getLogger(__name__)
        self.data_collector = ClusterDataCollectionService()
        
        # Validar disponibilidade de bibliotecas
        if not CLUSTERING_AVAILABLE:
            raise ImportError("Bibliotecas de clustering não disponíveis")
    
    async def run_clustering_pipeline(self, entity_type: ClusterDataType = None):
        """
        Pipeline completo de clusterização.
        
        Args:
            entity_type: Tipo específico a processar (None = ambos)
        """
        start_time = datetime.now()
        self.logger.info(f"🚀 Iniciando pipeline de clusterização - {start_time}")
        
        try:
            # Determinar tipos a processar
            types_to_process = [entity_type] if entity_type else [ClusterDataType.CASE, ClusterDataType.LAWYER]
            
            for cluster_type in types_to_process:
                self.logger.info(f"📊 Processando clusterização de {cluster_type.value}s")
                
                # 1. Coletar dados consolidados
                consolidated_data = await self._collect_entities_data(cluster_type)
                if not consolidated_data:
                    self.logger.warning(f"❌ Nenhum dado encontrado para {cluster_type.value}")
                    continue
                
                # 2. Gerar embeddings com rastreabilidade
                embeddings_data = await self._generate_embeddings_batch(consolidated_data)
                if not embeddings_data:
                    self.logger.warning(f"❌ Falha na geração de embeddings para {cluster_type.value}")
                    continue
                
                # 3. Estratégia de clusterização híbrida
                cluster_results = await self._perform_hybrid_clustering(embeddings_data, cluster_type)
                
                # 4. Salvar resultados no banco
                await self._save_cluster_results(cluster_results, cluster_type)
                
                # 5. Detectar clusters emergentes
                await self._detect_emergent_clusters(cluster_results, cluster_type)
                
                # 6. Gerar rótulos automáticos
                await self._generate_cluster_labels(cluster_results, cluster_type)
                
                self.logger.info(f"✅ Clusterização de {cluster_type.value} concluída: {len(cluster_results)} entidades processadas")
            
            duration = datetime.now() - start_time
            self.logger.info(f"🎉 Pipeline completo concluído em {duration.total_seconds():.1f}s")
            
        except Exception as e:
            self.logger.error(f"❌ Erro no pipeline de clusterização: {e}")
            raise
    
    async def _collect_entities_data(self, entity_type: ClusterDataType) -> List[ConsolidatedClusterData]:
        """Coleta dados consolidados de entidades para clusterização."""
        
        consolidated_data = []
        
        try:
            async with get_async_session() as db:
                # Buscar entidades que precisam de clusterização
                if entity_type == ClusterDataType.CASE:
                    # Buscar casos sem cluster ou com cluster antigo
                    query = text("""
                        SELECT DISTINCT c.id, c.title, c.description
                        FROM cases c
                        LEFT JOIN case_clusters cc ON c.id = cc.case_id 
                        WHERE cc.case_id IS NULL 
                           OR cc.updated_at < NOW() - INTERVAL '24 hours'
                        LIMIT 500
                    """)
                    
                    result = await db.execute(query)
                    entities = result.fetchall()
                    
                    # Coletar dados para cada caso
                    self.logger.info(f"📦 Coletando dados de {len(entities)} casos")
                    
                    for entity in entities:
                        case_data = await self.data_collector.collect_case_data_for_clustering(str(entity.id))
                        if case_data:
                            consolidated_data.append(case_data)
                
                elif entity_type == ClusterDataType.LAWYER:
                    # Buscar advogados sem cluster ou com cluster antigo
                    query = text("""
                        SELECT DISTINCT l.id, l.oab_number, l.name
                        FROM lawyers l
                        LEFT JOIN lawyer_clusters lc ON l.id = lc.lawyer_id
                        WHERE lc.lawyer_id IS NULL 
                           OR lc.updated_at < NOW() - INTERVAL '24 hours'
                        LIMIT 500
                    """)
                    
                    result = await db.execute(query)
                    entities = result.fetchall()
                    
                    # Coletar dados para cada advogado
                    self.logger.info(f"📦 Coletando dados de {len(entities)} advogados")
                    
                    for entity in entities:
                        lawyer_data = await self.data_collector.collect_lawyer_data_for_clustering(
                            str(entity.id), 
                            entity.oab_number
                        )
                        if lawyer_data:
                            consolidated_data.append(lawyer_data)
        
        except Exception as e:
            self.logger.error(f"❌ Erro ao coletar dados de entidades: {e}")
        
        self.logger.info(f"✅ Coletados dados de {len(consolidated_data)} entidades válidas")
        return consolidated_data
    
    async def _generate_embeddings_batch(self, consolidated_data: List[ConsolidatedClusterData]) -> List[Dict[str, Any]]:
        """Gera embeddings em batch com rastreabilidade."""
        
        embeddings_data = []
        
        self.logger.info(f"🧠 Gerando embeddings para {len(consolidated_data)} entidades")
        
        # Processar em batches para otimizar performance
        batch_size = 10
        for i in range(0, len(consolidated_data), batch_size):
            batch = consolidated_data[i:i + batch_size]
            
            # Gerar embeddings do batch em paralelo
            batch_tasks = [
                self._generate_single_embedding(data)
                for data in batch
            ]
            
            batch_results = await asyncio.gather(*batch_tasks, return_exceptions=True)
            
            # Processar resultados
            for result in batch_results:
                if isinstance(result, Exception):
                    self.logger.error(f"Erro na geração de embedding: {result}")
                    continue
                
                if result:
                    embeddings_data.append(result)
            
            self.logger.debug(f"📊 Batch {i//batch_size + 1}/{(len(consolidated_data) + batch_size - 1)//batch_size} concluído")
        
        self.logger.info(f"✅ Embeddings gerados: {len(embeddings_data)}/{len(consolidated_data)}")
        return embeddings_data
    
    async def _generate_single_embedding(self, data: ConsolidatedClusterData) -> Optional[Dict[str, Any]]:
        """Gera embedding para uma entidade com rastreabilidade."""
        
        try:
            # Gerar embedding com rastreabilidade de provider
            embedding_vector, provider = await generate_embedding_with_provider(
                data.consolidated_text,
                allow_local_fallback=True
            )
            
            return {
                'entity_id': data.entity_id,
                'entity_type': data.entity_type.value,
                'embedding': embedding_vector,
                'provider': provider,
                'data_sources': data.data_sources,
                'data_quality_score': data.data_quality_score,
                'consolidated_text': data.consolidated_text,
                'text_length': len(data.consolidated_text),
                'metadata': data.metadata
            }
            
        except Exception as e:
            self.logger.error(f"❌ Erro ao gerar embedding para {data.entity_id}: {e}")
            return None
    
    async def _perform_hybrid_clustering(self, embeddings_data: List[Dict], entity_type: ClusterDataType) -> List[ClusterResult]:
        """
        Executa clusterização híbrida consciente da origem dos embeddings.
        
        Estratégia:
        1. Separar embeddings por qualidade (high-quality vs local)
        2. Clusterizar primeiro os de alta qualidade com UMAP+HDBSCAN
        3. Atribuir embeddings locais aos clusters via similaridade
        4. Aplicar pós-processamento e validação
        """
        
        self.logger.info(f"🎯 Executando clusterização híbrida para {len(embeddings_data)} embeddings")
        
        # 1. Separar por qualidade do provider
        high_quality_data = [
            item for item in embeddings_data 
            if item['provider'] in self.config.high_quality_providers
        ]
        local_data = [
            item for item in embeddings_data 
            if item['provider'] not in self.config.high_quality_providers
        ]
        
        self.logger.info(f"📊 Dados de alta qualidade: {len(high_quality_data)}, Locais: {len(local_data)}")
        
        cluster_results = []
        
        if not high_quality_data:
            self.logger.warning("❌ Nenhum embedding de alta qualidade disponível")
            return cluster_results
        
        # 2. Clusterização principal com dados de alta qualidade
        hq_embeddings = np.array([item['embedding'] for item in high_quality_data])
        
        self.logger.info("🔄 Aplicando UMAP para redução dimensional...")
        
        # UMAP para redução dimensional otimizada
        umap_reducer = umap.UMAP(
            n_neighbors=min(self.config.umap_n_neighbors, len(high_quality_data) - 1),
            min_dist=self.config.umap_min_dist,
            metric=self.config.umap_metric,
            n_components=min(self.config.umap_n_components, len(high_quality_data) - 1),
            random_state=42
        )
        
        hq_embeddings_umap = umap_reducer.fit_transform(hq_embeddings)
        
        self.logger.info("🎯 Aplicando HDBSCAN para clusterização...")
        
        # HDBSCAN na representação UMAP
        clusterer = hdbscan.HDBSCAN(
            min_cluster_size=max(self.config.hdbscan_min_cluster_size, 3),
            min_samples=self.config.hdbscan_min_samples,
            cluster_selection_epsilon=self.config.hdbscan_cluster_selection_epsilon,
            metric=self.config.hdbscan_metric
        )
        
        cluster_labels = clusterer.fit_predict(hq_embeddings_umap)
        
        # 3. Processar resultados de alta qualidade
        unique_clusters = set(cluster_labels)
        n_clusters = len(unique_clusters) - (1 if -1 in unique_clusters else 0)
        
        self.logger.info(f"✅ HDBSCAN encontrou {n_clusters} clusters (outliers: {sum(1 for x in cluster_labels if x == -1)})")
        
        # Calcular centroides dos clusters para atribuição posterior
        cluster_centroids = {}
        for cluster_id in unique_clusters:
            if cluster_id != -1:  # Ignorar outliers
                mask = cluster_labels == cluster_id
                centroid = np.mean(hq_embeddings[mask], axis=0)
                cluster_centroids[cluster_id] = centroid
        
        # 4. Adicionar resultados de alta qualidade
        for i, item in enumerate(high_quality_data):
            cluster_id = cluster_labels[i]
            
            # Calcular confidence score baseado na distância ao centróide
            if cluster_id != -1 and cluster_id in cluster_centroids:
                embedding_vec = np.array(item['embedding'])
                centroid = cluster_centroids[cluster_id]
                similarity = np.dot(embedding_vec, centroid) / (
                    np.linalg.norm(embedding_vec) * np.linalg.norm(centroid)
                )
                confidence_score = max(0.1, similarity)
            else:
                confidence_score = 0.1  # Outlier
            
            cluster_results.append(ClusterResult(
                entity_id=item['entity_id'],
                cluster_id=f"{entity_type.value}_cluster_{cluster_id}",
                confidence_score=confidence_score,
                embedding_provider=item['provider'],
                data_sources=item['data_sources'],
                assignment_method='hdbscan'
            ))
        
        # 5. Atribuir embeddings locais aos clusters via similaridade
        if local_data and cluster_centroids:
            self.logger.info(f"🔗 Atribuindo {len(local_data)} embeddings locais aos clusters")
            
            for item in local_data:
                embedding_vec = np.array(item['embedding'])
                best_cluster_id = -1
                best_similarity = -1
                
                # Encontrar cluster mais similar
                for cluster_id, centroid in cluster_centroids.items():
                    similarity = np.dot(embedding_vec, centroid) / (
                        np.linalg.norm(embedding_vec) * np.linalg.norm(centroid)
                    )
                    
                    if similarity > best_similarity and similarity > self.config.similarity_threshold:
                        best_similarity = similarity
                        best_cluster_id = cluster_id
                
                cluster_results.append(ClusterResult(
                    entity_id=item['entity_id'],
                    cluster_id=f"{entity_type.value}_cluster_{best_cluster_id}",
                    confidence_score=max(0.05, best_similarity),
                    embedding_provider=item['provider'],
                    data_sources=item['data_sources'],
                    assignment_method='similarity' if best_cluster_id != -1 else 'outlier'
                ))
        
        # 6. Validação e métricas de qualidade
        await self._validate_clustering_quality(cluster_results, hq_embeddings, cluster_labels)
        
        self.logger.info(f"✅ Clusterização híbrida concluída: {len(cluster_results)} entidades atribuídas")
        
        return cluster_results
    
    async def _validate_clustering_quality(self, cluster_results: List[ClusterResult], embeddings: np.ndarray, labels: np.ndarray):
        """Valida qualidade da clusterização."""
        
        try:
            # Calcular silhouette score apenas para clusters válidos (não outliers)
            valid_mask = labels != -1
            if np.sum(valid_mask) >= 2:
                silhouette_avg = silhouette_score(embeddings[valid_mask], labels[valid_mask])
                self.logger.info(f"📊 Silhouette Score: {silhouette_avg:.3f}")
                
                if silhouette_avg < self.config.min_silhouette_score:
                    self.logger.warning(f"⚠️ Silhouette score baixo: {silhouette_avg:.3f} < {self.config.min_silhouette_score}")
            
            # Estatísticas dos clusters
            cluster_sizes = {}
            for result in cluster_results:
                cluster_id = result.cluster_id
                cluster_sizes[cluster_id] = cluster_sizes.get(cluster_id, 0) + 1
            
            valid_clusters = {k: v for k, v in cluster_sizes.items() if not k.endswith('_-1') and v >= self.config.min_cluster_members}
            
            self.logger.info(f"📈 Clusters válidos: {len(valid_clusters)}")
            self.logger.info(f"📈 Cluster sizes: {dict(sorted(valid_clusters.items(), key=lambda x: x[1], reverse=True)[:5])}")
            
        except Exception as e:
            self.logger.error(f"❌ Erro na validação de qualidade: {e}")
    
    async def _save_cluster_results(self, cluster_results: List[ClusterResult], entity_type: ClusterDataType):
        """Salva resultados da clusterização no banco."""
        
        if not cluster_results:
            return
        
        try:
            async with get_async_session() as db:
                table_name = f"{entity_type.value}_clusters"
                
                self.logger.info(f"💾 Salvando {len(cluster_results)} resultados em {table_name}")
                
                # Limpar clusters antigos
                await db.execute(text(f"DELETE FROM {table_name} WHERE updated_at < NOW() - INTERVAL '1 day'"))
                
                # Inserir novos resultados
                for result in cluster_results:
                    insert_query = text(f"""
                        INSERT INTO {table_name} (
                            {entity_type.value}_id, cluster_id, confidence_score, 
                            assigned_method, created_at, updated_at
                        ) VALUES (
                            :entity_id, :cluster_id, :confidence_score,
                            :assignment_method, NOW(), NOW()
                        )
                        ON CONFLICT ({entity_type.value}_id) 
                        DO UPDATE SET 
                            cluster_id = :cluster_id,
                            confidence_score = :confidence_score,
                            assigned_method = :assignment_method,
                            updated_at = NOW()
                    """)
                    
                    await db.execute(insert_query, {
                        'entity_id': result.entity_id,
                        'cluster_id': result.cluster_id,
                        'confidence_score': result.confidence_score,
                        'assignment_method': result.assignment_method
                    })
                
                await db.commit()
                self.logger.info(f"✅ Resultados salvos com sucesso em {table_name}")
                
        except Exception as e:
            self.logger.error(f"❌ Erro ao salvar resultados: {e}")
            await db.rollback()
    
    async def _detect_emergent_clusters(self, cluster_results: List[ClusterResult], entity_type: ClusterDataType):
        """Detecta clusters emergentes baseado em momentum e crescimento temporal."""
        
        try:
            from services.cluster_momentum_service import create_momentum_service
            
            # Agrupar por cluster
            cluster_groups = {}
            for result in cluster_results:
                cluster_id = result.cluster_id
                if cluster_id not in cluster_groups:
                    cluster_groups[cluster_id] = []
                cluster_groups[cluster_id].append(result)
            
            self.logger.info(f"🚀 Analisando {len(cluster_groups)} clusters para detecção de emergentes")
            
            # Usar o serviço de momentum para detecção avançada
            async with get_async_session() as db:
                momentum_service = create_momentum_service(db)
                
                # 1. Atualizar histórico de momentum para todos os clusters
                for cluster_id, members in cluster_groups.items():
                    if cluster_id.endswith('_-1'):  # Ignorar outliers
                        continue
                    
                    total_members = len(members)
                    await momentum_service.update_cluster_momentum_history(cluster_id, total_members)
                
                # 2. Detectar clusters emergentes usando algoritmo de momentum
                emergent_alerts = await momentum_service.detect_emergent_clusters(entity_type.value)
                
                # 3. Processar alertas e atualizar metadata
                if emergent_alerts:
                    self.logger.info(f"🚀 Detectados {len(emergent_alerts)} clusters emergentes com análise de momentum")
                    
                    for alert in emergent_alerts:
                        self.logger.info(
                            f"📊 Cluster emergente: {alert.cluster_label} "
                            f"(momentum: {alert.momentum_score:.3f}, growth: {alert.growth_rate:.3f})"
                        )
                        
                        # Calcular métricas detalhadas
                        momentum_metrics = await momentum_service.calculate_cluster_momentum(alert.cluster_id)
                        
                        if momentum_metrics:
                            # Marcar como emergente no banco
                            success = await momentum_service.mark_cluster_as_emergent(alert.cluster_id, momentum_metrics)
                            
                            if success:
                                self.logger.info(f"✅ Cluster {alert.cluster_id} marcado como emergente")
                            
                            # Salvar métricas detalhadas no metadata
                            update_metadata_query = text("""
                                INSERT INTO cluster_metadata (
                                    cluster_id, cluster_type, total_items, 
                                    is_emergent, emergent_since, momentum_score,
                                    description, last_updated
                                ) VALUES (
                                    :cluster_id, :cluster_type, :total_items,
                                    true, NOW(), :momentum_score, :description, NOW()
                                )
                                ON CONFLICT (cluster_id)
                                DO UPDATE SET
                                    total_items = :total_items,
                                    is_emergent = true,
                                    emergent_since = COALESCE(cluster_metadata.emergent_since, NOW()),
                                    momentum_score = :momentum_score,
                                    description = :description,
                                    last_updated = NOW()
                            """)
                            
                            await db.execute(update_metadata_query, {
                                'cluster_id': alert.cluster_id,
                                'cluster_type': entity_type.value,
                                'total_items': cluster_groups.get(alert.cluster_id, []),
                                'momentum_score': momentum_metrics.current_momentum,
                                'description': alert.market_opportunity
                            })
                
                # 4. Fallback para clusters que não têm histórico suficiente (critérios básicos)
                basic_emergent_clusters = []
                
                for cluster_id, members in cluster_groups.items():
                    if cluster_id.endswith('_-1'):
                        continue
                    
                    # Verificar se já foi analisado pelo momentum service
                    already_detected = any(alert.cluster_id == cluster_id for alert in emergent_alerts)
                    if already_detected:
                        continue
                    
                    # Aplicar critérios básicos para clusters novos
                    total_members = len(members)
                    avg_confidence = sum(m.confidence_score for m in members) / total_members
                    
                    is_emergent_basic = (
                        total_members >= 5 and 
                        avg_confidence > 0.6 and
                        total_members <= 20  # Clusters pequenos mas significativos
                    )
                    
                    if is_emergent_basic:
                        basic_emergent_clusters.append({
                            'cluster_id': cluster_id,
                            'member_count': total_members,
                            'avg_confidence': avg_confidence,
                            'detected_at': datetime.now()
                        })
                
                # 5. Salvar clusters emergentes básicos
                if basic_emergent_clusters:
                    self.logger.info(f"📈 Detectados {len(basic_emergent_clusters)} clusters emergentes (critérios básicos)")
                    
                    for cluster_info in basic_emergent_clusters:
                        basic_update_query = text("""
                            INSERT INTO cluster_metadata (
                                cluster_id, cluster_type, total_items, 
                                is_emergent, emergent_since, momentum_score, last_updated
                            ) VALUES (
                                :cluster_id, :cluster_type, :total_items,
                                true, NOW(), 0.5, NOW()
                            )
                            ON CONFLICT (cluster_id)
                            DO UPDATE SET
                                total_items = :total_items,
                                is_emergent = true,
                                emergent_since = COALESCE(cluster_metadata.emergent_since, NOW()),
                                momentum_score = GREATEST(cluster_metadata.momentum_score, 0.5),
                                last_updated = NOW()
                        """)
                        
                        await db.execute(basic_update_query, {
                            'cluster_id': cluster_info['cluster_id'],
                            'cluster_type': entity_type.value,
                            'total_items': cluster_info['member_count']
                        })
                
                await db.commit()
                self.logger.info("✅ Detecção de clusters emergentes concluída com análise de momentum")
            
        except Exception as e:
            self.logger.error(f"❌ Erro na detecção de clusters emergentes: {e}")
            # Não falhar o pipeline inteiro por causa deste erro
    
    async def _generate_cluster_labels(self, cluster_results: List[ClusterResult], entity_type: ClusterDataType):
        """Gera rótulos automáticos para clusters via LLM."""
        
        try:
            async with get_async_session() as db:
                labeling_service = ClusterLabelingService(db)
                await labeling_service.label_all_clusters(
                    entity_type=entity_type.value,
                    model="gpt-4o",
                    n_samples=5
                )
                
                self.logger.info(f"🏷️ Rótulos gerados para clusters de {entity_type.value}")
                
        except Exception as e:
            self.logger.error(f"❌ Erro na geração de rótulos: {e}")


# Função principal para execução via scheduler
async def run_cluster_generation(entity_type: str = None):
    """
    Função principal para execução do job de clusterização.
    
    Args:
        entity_type: 'case', 'lawyer' ou None (ambos)
    """
    
    try:
        # Configuração otimizada
        config = ClusteringConfig(
            umap_n_neighbors=10,
            umap_min_dist=0.05,
            hdbscan_min_cluster_size=4,
            hdbscan_min_samples=2,
            similarity_threshold=0.65
        )
        
        # Determinar tipo
        cluster_type = None
        if entity_type:
            cluster_type = ClusterDataType.CASE if entity_type == 'case' else ClusterDataType.LAWYER
        
        # Executar job
        job = ClusterGenerationJob(config)
        await job.run_clustering_pipeline(cluster_type)
        
        return {"status": "success", "message": "Clusterização concluída"}
        
    except Exception as e:
        logging.error(f"❌ Erro no job de clusterização: {e}")
        return {"status": "error", "message": str(e)}


if __name__ == "__main__":
    # Teste local
    import sys
    
    entity_type = sys.argv[1] if len(sys.argv) > 1 else None
    result = asyncio.run(run_cluster_generation(entity_type))
    print(f"Resultado: {result}") 