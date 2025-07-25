# Plano de Ação Completo: Clusterização de Casos e Advogados

## 🎯 Visão Geral Executiva

Sistema inteligente de clusterização baseado em embeddings para identificar grupos latentes de casos e advogados, detectar nichos emergentes de mercado e gerar recomendações estratégicas de parceria entre escritórios.

**Valor de Negócio:**
- Identificação proativa de nichos emergentes (ex: "contratos de influenciadores digitais")
- Recomendações inteligentes de parceria entre escritórios complementares
- Business Intelligence para crescimento estratégico dos escritórios

---

## 📊 Arquitetura de Dados Confirmada

### **Fontes de Dados Integradas (Análise Completa)**

#### **1. Casos**
- **Dados Básicos:** Título + descrição + peças processuais
- **Metadados:** Tribunal, ramo, tags manuais, datas
- **LEX-9000:** Classificação jurídica, viabilidade, urgência
- **Triagem IA:** Dados estruturados da entrevistadora inteligente

#### **2. Advogados/Escritórios**

**Escavador API:**
- Processos históricos + movimentações completas
- Outcomes classificados por NLP (`OutcomeClassifier`)
- Distribuição por tribunais e competências
- Análise temporal de atividade processual

**Perplexity API:**
- Formação acadêmica detalhada + publicações científicas
- Scores de reputação universitária + análise de periódicos
- Dados de produção intelectual

**Deep Research:**
- Análise contextual avançada + insights de mercado
- Tendências regulatórias + inteligência competitiva

**Unipile/LinkedIn (Dados Estruturados Completos):**
- **Formação:** Grau, instituição, área de estudo, datas
- **Experiência:** Empresas, cargos, descrições detalhadas, durações
- **Competências:** Skills + número de endorsements
- **Certificações:** Organizações emissoras + URLs de validação
- **Contatos:** E-mails, telefones, endereços, outras redes
- **Networking:** Conexões, seguidores, grau de relacionamento
- **Atividade:** Posts profissionais + métricas de engajamento

**Dados Híbridos:**
- Consolidação via `HybridLegalDataService` com transparência de origem
- Cache Redis com TTL diferenciado por fonte
- Social boost no success_rate baseado em dados do LinkedIn

---

## 🔧 Implementação Técnica

### **Fase 1: Infraestrutura Backend (3-4 dias)**

#### **1.1 Modificação do EmbeddingService**
**Arquivo:** `packages/backend/services/embedding_service.py`

```python
async def generate_embedding_with_provider(self, text: str, allow_local_fallback: bool = True) -> Tuple[List[float], str]:
    """
    Gera embedding com rastreabilidade de origem.
    
    Returns:
        Tuple[embedding_vector, provider_name]
        provider_name: 'gemini', 'openai', 'local'
    """
    
    # Estratégia de cascata: Gemini → OpenAI → Local (se permitido)
    if self.gemini_enabled:
        try:
            embedding = await self._generate_gemini_embedding(text)
            return embedding, "gemini"
        except Exception as e:
            self.logger.warning(f"Gemini fallback: {e}")
    
    if self.openai_enabled:
        try:
            embedding = await self._generate_openai_embedding(text)
            return embedding[:self.embedding_dim], "openai"  # Truncar para 768
        except Exception as e:
            self.logger.warning(f"OpenAI fallback: {e}")
    
    if self.local_enabled and allow_local_fallback:
        embedding = await self._generate_local_embedding(text)
        # Padding para 768 dimensões
        padded = embedding + [0.0] * (self.embedding_dim - len(embedding))
        return padded, "local"
    
    raise Exception("Nenhum provedor de embedding disponível")
```

#### **1.2 Criação das Tabelas de Cluster**
**Arquivo:** `packages/backend/migrations/add_cluster_tables.sql`

```sql
-- Tabela para embeddings com rastreabilidade
CREATE TABLE case_embeddings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id UUID NOT NULL REFERENCES cases(id),
    embedding_vector VECTOR(768) NOT NULL,
    embedding_provider VARCHAR(20) NOT NULL, -- 'gemini', 'openai', 'local'
    data_sources JSONB NOT NULL, -- {'escavador': true, 'lex9000': true, ...}
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE lawyer_embeddings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lawyer_id UUID NOT NULL REFERENCES lawyers(id),
    embedding_vector VECTOR(768) NOT NULL,
    embedding_provider VARCHAR(20) NOT NULL,
    data_sources JSONB NOT NULL, -- {'linkedin': true, 'escavador': true, 'perplexity': true, ...}
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Tabelas de clusters
CREATE TABLE case_clusters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id UUID NOT NULL REFERENCES cases(id),
    cluster_id VARCHAR(50) NOT NULL,
    cluster_label VARCHAR(255),
    confidence_score FLOAT,
    is_emergent BOOLEAN DEFAULT FALSE,
    momentum_score FLOAT DEFAULT 0.0,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE lawyer_clusters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lawyer_id UUID NOT NULL REFERENCES lawyers(id),
    cluster_id VARCHAR(50) NOT NULL,
    cluster_label VARCHAR(255),
    confidence_score FLOAT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Metadados dos clusters
CREATE TABLE cluster_metadata (
    cluster_id VARCHAR(50) PRIMARY KEY,
    cluster_type VARCHAR(20) NOT NULL, -- 'case' ou 'lawyer'
    cluster_label VARCHAR(255) NOT NULL,
    description TEXT,
    total_items INTEGER DEFAULT 0,
    momentum_score FLOAT DEFAULT 0.0,
    is_emergent BOOLEAN DEFAULT FALSE,
    emergent_since TIMESTAMP,
    last_updated TIMESTAMP DEFAULT NOW()
);

-- Tabelas de rótulos de clusters
CREATE TABLE case_cluster_labels (
    cluster_id VARCHAR(50) PRIMARY KEY,
    label VARCHAR(255) NOT NULL,
    description TEXT,
    confidence_score FLOAT DEFAULT 0.8,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE lawyer_cluster_labels (
    cluster_id VARCHAR(50) PRIMARY KEY,
    label VARCHAR(255) NOT NULL,
    description TEXT,
    confidence_score FLOAT DEFAULT 0.8,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_case_embeddings_case_id ON case_embeddings(case_id);
CREATE INDEX idx_lawyer_embeddings_lawyer_id ON lawyer_embeddings(lawyer_id);
CREATE INDEX idx_case_clusters_cluster_id ON case_clusters(cluster_id);
CREATE INDEX idx_lawyer_clusters_cluster_id ON lawyer_clusters(cluster_id);
CREATE INDEX idx_cluster_metadata_momentum ON cluster_metadata(momentum_score DESC);

-- Função RPC para buscar textos de cluster (otimização Supabase)
CREATE OR REPLACE FUNCTION get_cluster_texts(
    cluster_table_name TEXT,
    source_table_name TEXT,
    target_cluster_id VARCHAR(50),
    limit_n INT DEFAULT 5
)
RETURNS TABLE(entity_id UUID, full_text TEXT, confidence_score FLOAT)
LANGUAGE SQL
AS $$
    SELECT 
        s.id as entity_id,
        s.consolidated_text as full_text,
        c.confidence_score
    FROM 
        (SELECT entity_id, confidence_score 
         FROM case_clusters 
         WHERE cluster_id = target_cluster_id 
         ORDER BY confidence_score DESC 
         LIMIT limit_n) c
    JOIN cases s ON c.entity_id = s.id
    WHERE cluster_table_name = 'case_clusters'
    
    UNION ALL
    
    SELECT 
        s.id as entity_id,
        s.bio_consolidated as full_text,
        c.confidence_score
    FROM 
        (SELECT entity_id, confidence_score 
         FROM lawyer_clusters 
         WHERE cluster_id = target_cluster_id 
         ORDER BY confidence_score DESC 
         LIMIT limit_n) c
    JOIN lawyers s ON c.entity_id = s.id
    WHERE cluster_table_name = 'lawyer_clusters';
$$;
```

#### **1.3 Job de Clusterização com Estratégia Híbrida**
**Arquivo:** `packages/backend/jobs/cluster_generation_job.py`

```python
import asyncio
import logging
from datetime import datetime, timedelta
from typing import List, Dict, Any, Tuple
import numpy as np
from sklearn.cluster import HDBSCAN
from sklearn.metrics import silhouette_score
import umap
import openai

from services.embedding_service import get_embedding_service
from services.hybrid_legal_data_service_social import HybridLegalDataServiceSocial
from database import get_async_session
from models.case import Case
from models.lawyer import Lawyer

class ClusterGenerationJob:
    """Job para geração inteligente de clusters com estratégia híbrida."""
    
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.embedding_service = get_embedding_service()
        self.hybrid_service = HybridLegalDataServiceSocial()
        
    async def run_clustering_pipeline(self):
        """Pipeline completo de clusterização."""
        
        try:
            # 1. Coletar e enriquecer dados
            self.logger.info("🔄 Iniciando coleta multi-fonte...")
            cases_data = await self._collect_enriched_cases()
            lawyers_data = await self._collect_enriched_lawyers()
            
            # 2. Gerar embeddings com rastreabilidade
            self.logger.info("🧠 Gerando embeddings...")
            case_embeddings = await self._generate_case_embeddings(cases_data)
            lawyer_embeddings = await self._generate_lawyer_embeddings(lawyers_data)
            
            # 3. Clusterização consciente da origem
            self.logger.info("🎯 Executando clusterização híbrida...")
            case_clusters = await self._perform_hybrid_clustering(case_embeddings, "case")
            lawyer_clusters = await self._perform_hybrid_clustering(lawyer_embeddings, "lawyer")
            
            # 4. Detecção de clusters emergentes
            self.logger.info("🚀 Detectando nichos emergentes...")
            await self._detect_emergent_clusters(case_clusters)
            
            # 5. Rotulagem automática via LLM
            self.logger.info("🏷️ Gerando rótulos inteligentes...")
            await self._generate_cluster_labels(case_clusters, "case")
            await self._generate_cluster_labels(lawyer_clusters, "lawyer")
            
            # 6. Calcular métricas de momentum
            self.logger.info("📊 Calculando métricas...")
            await self._calculate_cluster_momentum()
            
            self.logger.info("✅ Pipeline de clusterização concluído!")
            
        except Exception as e:
            self.logger.error(f"❌ Erro no pipeline de clusterização: {e}")
            raise
    
    async def _collect_enriched_cases(self) -> List[Dict]:
        """Coleta dados enriquecidos de casos via múltiplas fontes."""
        # Implementar coleta via LEX-9000, triagem IA, etc.
        pass
    
    async def _collect_enriched_lawyers(self) -> List[Dict]:
        """Coleta dados enriquecidos de advogados via HybridLegalDataService."""
        # Implementar coleta via Escavador, Perplexity, Deep Research, LinkedIn
        pass
    
    async def _perform_hybrid_clustering(self, embeddings_data: List[Dict], cluster_type: str) -> List[Dict]:
        """
        Clusterização consciente da origem dos embeddings.
        
        Estratégia:
        1. Clusterizar primeiro embeddings de alta qualidade (Gemini/OpenAI)
        2. Atribuir embeddings locais aos clusters existentes via similaridade
        """
        
        # Separar por origem
        high_quality = [item for item in embeddings_data if item['provider'] in ['gemini', 'openai']]
        local_fallback = [item for item in embeddings_data if item['provider'] == 'local']
        
        if not high_quality:
            self.logger.warning("Nenhum embedding de alta qualidade encontrado")
            return []
        
        # 1. Clusterização principal com dados de alta qualidade
        hq_vectors = np.array([item['embedding'] for item in high_quality])
        
        # Aplicar UMAP para redução dimensional otimizada
        embedding_umap = umap.UMAP(
            n_neighbors=5, 
            min_dist=0.3, 
            metric='cosine'
        ).fit_transform(hq_vectors)
        
        # HDBSCAN na representação UMAP
        clusterer = HDBSCAN(
            min_cluster_size=5,
            min_samples=3,
            cluster_selection_epsilon=0.1
        )
        
        cluster_labels = clusterer.fit_predict(embedding_umap)
        
        # 2. Calcular centroides dos clusters encontrados
        cluster_centroids = {}
        for label in set(cluster_labels):
            if label != -1:  # Ignorar outliers
                mask = cluster_labels == label
                centroid = np.mean(hq_vectors[mask], axis=0)
                cluster_centroids[label] = centroid
        
        # 3. Atribuir embeddings locais aos clusters via similaridade
        results = []
        
        # Adicionar resultados de alta qualidade
        for i, item in enumerate(high_quality):
            results.append({
                **item,
                'cluster_id': f"{cluster_type}_cluster_{cluster_labels[i]}",
                'confidence_score': 0.9 if cluster_labels[i] != -1 else 0.3
            })
        
        # Atribuir embeddings locais
        for item in local_fallback:
            vector = np.array(item['embedding'])
            best_cluster = -1
            best_similarity = -1
            
            for cluster_id, centroid in cluster_centroids.items():
                similarity = np.dot(vector, centroid) / (np.linalg.norm(vector) * np.linalg.norm(centroid))
                if similarity > best_similarity and similarity > 0.7:  # Threshold
                    best_similarity = similarity
                    best_cluster = cluster_id
            
            results.append({
                **item,
                'cluster_id': f"{cluster_type}_cluster_{best_cluster}",
                'confidence_score': max(0.1, best_similarity)
            })
        
        return results
    
    async def _detect_emergent_clusters(self, clusters: List[Dict]):
        """Detecta clusters emergentes baseado em momentum."""
        # Implementar lógica de detecção de momentum
        pass
    
    async def _generate_cluster_labels(self, clusters: List[Dict], cluster_type: str):
        """Gera rótulos humanos para clusters via LLM usando função RPC otimizada."""
        
        from sqlalchemy import text
        
        # Obter clusters únicos (excluindo outliers)
        cluster_ids = list(set(
            item['cluster_id'] for item in clusters 
            if not item['cluster_id'].endswith('_-1')
        ))
        
        for cluster_id in cluster_ids:
            self.logger.info(f"🏷️ Gerando rótulo para cluster {cluster_id}...")
            
            try:
                # Usar função RPC para buscar textos representativos
                query = text("""
                    SELECT entity_id, full_text, confidence_score 
                    FROM get_cluster_texts(:cluster_table, :source_table, :cluster_id, 5)
                """)
                
                result = await self.db.execute(query, {
                    "cluster_table": f"{cluster_type}_clusters",
                    "source_table": f"{cluster_type}s", 
                    "cluster_id": cluster_id
                })
                
                sample_texts = [row.full_text[:500] for row in result.fetchall()]
                
                if not sample_texts:
                    continue
                
                # Prompt otimizado para contexto jurídico
                prompt = f"""
                Analise os seguintes textos jurídicos e gere um rótulo preciso e profissional (máximo 4 palavras) que represente o nicho específico:

                Exemplos do cluster:
                {chr(10).join(f"- {text}" for text in sample_texts)}

                Rótulo jurídico:"""
                
                # Usar OpenAI Chat API (mais moderna)
                response = await openai.ChatCompletion.acreate(
                    model="gpt-4o",
                    messages=[{"role": "user", "content": prompt}],
                    max_tokens=20,
                    temperature=0.3
                )
                
                label = response.choices[0].message.content.strip()
                
                # Salvar no banco
                await self._save_cluster_label(cluster_id, label, cluster_type, len(sample_texts))
                
                self.logger.info(f"✅ Cluster {cluster_id} rotulado como: {label}")
                
            except Exception as e:
                self.logger.error(f"Erro ao gerar rótulo para {cluster_id}: {e}")
    
    async def _save_cluster_label(self, cluster_id: str, label: str, cluster_type: str, total_items: int):
        """Salva metadados do cluster e rótulo no banco."""
        from sqlalchemy import text
        
        try:
            # Salvar em cluster_metadata
            metadata_query = text("""
                INSERT INTO cluster_metadata (cluster_id, cluster_type, cluster_label, total_items, last_updated)
                VALUES (:cluster_id, :cluster_type, :label, :total_items, NOW())
                ON CONFLICT (cluster_id) 
                DO UPDATE SET 
                    cluster_label = :label,
                    total_items = :total_items,
                    last_updated = NOW()
            """)
            
            await self.db.execute(metadata_query, {
                "cluster_id": cluster_id,
                "cluster_type": cluster_type,
                "label": label,
                "total_items": total_items
            })
            
            # Salvar em tabela de rótulos específica
            labels_table = f"{cluster_type}_cluster_labels"
            labels_query = text(f"""
                INSERT INTO {labels_table} (cluster_id, label, confidence_score, created_at)
                VALUES (:cluster_id, :label, 0.8, NOW())
                ON CONFLICT (cluster_id)
                DO UPDATE SET 
                    label = :label,
                    confidence_score = 0.8,
                    created_at = NOW()
            """)
            
            await self.db.execute(labels_query, {
                "cluster_id": cluster_id,
                "label": label
            })
            
            await self.db.commit()
            
        except Exception as e:
            self.logger.error(f"Erro ao salvar rótulo do cluster {cluster_id}: {e}")
            await self.db.rollback()
    
    async def _calculate_cluster_momentum(self):
        """Calcula métricas de momentum dos clusters."""
        # Implementar cálculo de momentum baseado em crescimento temporal
        pass
```

#### **1.4 Serviço de Rotulagem Automática**
**Arquivo:** `packages/backend/services/cluster_labeling_service.py`

```python
from supabase import create_client
import os
from openai import OpenAI
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text

class ClusterLabelingService:
    """Serviço para rotulagem automática de clusters via LLM."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
        self.openai_client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
        self.logger = logging.getLogger(__name__)
    
    async def label_all_clusters(self, entity_type: str = "case", model: str = "gpt-4o", n_samples: int = 5):
        """Rotula todos os clusters de um tipo específico."""
        
        # Buscar clusters únicos sem rótulo
        query = text(f"""
            SELECT DISTINCT cluster_id 
            FROM {entity_type}_clusters 
            WHERE cluster_id NOT LIKE '%_-1'
            AND cluster_id NOT IN (
                SELECT cluster_id FROM {entity_type}_cluster_labels
            )
        """)
        
        result = await self.db.execute(query)
        cluster_ids = [row.cluster_id for row in result.fetchall()]
        
        for cluster_id in cluster_ids:
            await self._label_single_cluster(cluster_id, entity_type, model, n_samples)
    
    async def _label_single_cluster(self, cluster_id: str, entity_type: str, model: str, n_samples: int):
        """Rotula um cluster específico."""
        
        try:
            # Buscar textos representativos usando função RPC
            texts_query = text("""
                SELECT full_text FROM get_cluster_texts(:cluster_table, :source_table, :cluster_id, :limit_n)
            """)
            
            result = await self.db.execute(texts_query, {
                "cluster_table": f"{entity_type}_clusters",
                "source_table": f"{entity_type}s",
                "cluster_id": cluster_id,
                "limit_n": n_samples
            })
            
            texts = [row.full_text[:500] for row in result.fetchall()]
            
            if not texts:
                self.logger.warning(f"Nenhum texto encontrado para cluster {cluster_id}")
                return
            
            # Prompt especializado por tipo
            if entity_type == "case":
                context = "casos jurídicos"
                instruction = "Identifique a área jurídica específica ou tipo de disputa"
            else:
                context = "perfis de advogados"  
                instruction = "Identifique a especialização ou nicho de atuação"
            
            prompt = f"""
            Analise os seguintes {context} e {instruction}. 
            Gere um rótulo profissional de no máximo 4 palavras:

            Exemplos:
            {chr(10).join(f"- {text}" for text in texts)}

            Rótulo:"""
            
            # Chamada ao LLM
            response = await self.openai_client.chat.completions.acreate(
                model=model,
                messages=[{"role": "user", "content": prompt}],
                max_tokens=20,
                temperature=0.3
            )
            
            label = response.choices[0].message.content.strip()
            
            # Salvar rótulo
            await self._save_label(cluster_id, label, entity_type)
            
            self.logger.info(f"✅ Cluster {cluster_id} rotulado: {label}")
            
        except Exception as e:
            self.logger.error(f"Erro ao rotular cluster {cluster_id}: {e}")
    
    async def _save_label(self, cluster_id: str, label: str, entity_type: str):
        """Salva o rótulo no banco."""
        
        labels_query = text(f"""
            INSERT INTO {entity_type}_cluster_labels (cluster_id, label, confidence_score)
            VALUES (:cluster_id, :label, 0.85)
            ON CONFLICT (cluster_id) 
            DO UPDATE SET label = :label, confidence_score = 0.85
        """)
        
        await self.db.execute(labels_query, {
            "cluster_id": cluster_id,
            "label": label
        })
        
        await self.db.commit()
```

### **Fase 2: APIs REST (2 dias)**

#### **2.1 API de Clusters Trending**
**Arquivo:** `packages/backend/routes/clusters.py`

```python
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List

from database import get_async_session
from services.cluster_service import ClusterService
from schemas.cluster_schemas import TrendingClusterResponse, ClusterDetailResponse

router = APIRouter(prefix="/api/clusters", tags=["clusters"])

@router.get("/trending", response_model=List[TrendingClusterResponse])
async def get_trending_clusters(
    limit: int = 3,
    cluster_type: str = "case",  # "case" ou "lawyer"
    db: AsyncSession = Depends(get_async_session)
):
    """Retorna clusters em alta baseado em momentum."""
    
    cluster_service = ClusterService(db)
    trending = await cluster_service.get_trending_clusters(
        cluster_type=cluster_type,
        limit=limit
    )
    
    return trending

@router.get("/{cluster_id}", response_model=ClusterDetailResponse)
async def get_cluster_details(
    cluster_id: str,
    db: AsyncSession = Depends(get_async_session)
):
    """Detalhes completos de um cluster específico."""
    
    cluster_service = ClusterService(db)
    details = await cluster_service.get_cluster_details(cluster_id)
    
    if not details:
        raise HTTPException(status_code=404, detail="Cluster não encontrado")
    
    return details

@router.get("/recommendations/{lawyer_id}")
async def get_partnership_recommendations(
    lawyer_id: str,
    db: AsyncSession = Depends(get_async_session)
):
    """Recomendações de parceria baseadas em clusters complementares."""
    
    cluster_service = ClusterService(db)
    recommendations = await cluster_service.get_partnership_recommendations(lawyer_id)
    
    return {
        "lawyer_id": lawyer_id,
        "recommendations": recommendations,
        "generated_at": datetime.now().isoformat()
    }
```

#### **2.2 Service Layer**
**Arquivo:** `packages/backend/services/cluster_service.py`

```python
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, text
from typing import List, Dict, Any, Optional
from datetime import datetime

class ClusterService:
    """Serviço para operações relacionadas a clusters."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def get_trending_clusters(self, cluster_type: str = "case", limit: int = 3) -> List[Dict]:
        """Retorna clusters com maior momentum."""
        
        query = text("""
            SELECT 
                cm.cluster_id,
                COALESCE(cl.label, cm.cluster_label, 'Cluster sem nome') as cluster_label,
                cm.momentum_score,
                cm.total_items,
                cm.is_emergent,
                cm.emergent_since,
                cl.confidence_score as label_confidence
            FROM cluster_metadata cm
            LEFT JOIN {}_cluster_labels cl ON cm.cluster_id = cl.cluster_id
            WHERE cm.cluster_type = :cluster_type 
                AND cm.total_items >= 5
            ORDER BY cm.momentum_score DESC, cm.total_items DESC
            LIMIT :limit
        """.format(cluster_type))
        
        result = await self.db.execute(query, {
            "cluster_type": cluster_type,
            "limit": limit
        })
        
        return [dict(row._mapping) for row in result.fetchall()]
    
    async def get_cluster_details(self, cluster_id: str) -> Optional[Dict]:
        """Detalhes completos de um cluster."""
        
        query = text("""
            SELECT 
                cm.*,
                COUNT(CASE WHEN cm.cluster_type = 'case' THEN cc.case_id END) as case_count,
                COUNT(CASE WHEN cm.cluster_type = 'lawyer' THEN lc.lawyer_id END) as lawyer_count
            FROM cluster_metadata cm
            LEFT JOIN case_clusters cc ON cm.cluster_id = cc.cluster_id
            LEFT JOIN lawyer_clusters lc ON cm.cluster_id = lc.cluster_id
            WHERE cm.cluster_id = :cluster_id
            GROUP BY cm.cluster_id
        """)
        
        result = await self.db.execute(query, {"cluster_id": cluster_id})
        row = result.fetchone()
        
        return dict(row._mapping) if row else None
    
    async def get_partnership_recommendations(self, lawyer_id: str) -> List[Dict]:
        """Gera recomendações de parceria baseadas em complementaridade de clusters."""
        
        # 1. Encontrar clusters do advogado
        lawyer_clusters_query = text("""
            SELECT cluster_id, confidence_score
            FROM lawyer_clusters
            WHERE lawyer_id = :lawyer_id
        """)
        
        lawyer_clusters = await self.db.execute(
            lawyer_clusters_query, 
            {"lawyer_id": lawyer_id}
        )
        lawyer_cluster_ids = [row.cluster_id for row in lawyer_clusters.fetchall()]
        
        if not lawyer_cluster_ids:
            return []
        
        # 2. Encontrar advogados em clusters complementares (não sobrepostos)
        recommendations_query = text("""
            WITH lawyer_strengths AS (
                SELECT 
                    l.id as lawyer_id,
                    l.name,
                    l.law_firm_id,
                    lf.name as firm_name,
                    lc.cluster_id,
                    cm.cluster_label,
                    lc.confidence_score
                FROM lawyer_clusters lc
                JOIN lawyers l ON lc.lawyer_id = l.id
                LEFT JOIN law_firms lf ON l.law_firm_id = lf.id
                JOIN cluster_metadata cm ON lc.cluster_id = cm.cluster_id
                WHERE lc.cluster_id NOT IN :lawyer_clusters
                    AND lc.confidence_score > 0.7
                    AND cm.total_items >= 10
            )
            SELECT 
                lawyer_id,
                name,
                firm_name,
                cluster_id,
                cluster_label,
                confidence_score,
                RANK() OVER (PARTITION BY cluster_id ORDER BY confidence_score DESC) as cluster_rank
            FROM lawyer_strengths
            WHERE cluster_rank <= 3
            ORDER BY confidence_score DESC
            LIMIT 10
        """)
        
        result = await self.db.execute(
            recommendations_query,
            {"lawyer_clusters": tuple(lawyer_cluster_ids)}
        )
        
        recommendations = []
        for row in result.fetchall():
            recommendations.append({
                "lawyer_id": row.lawyer_id,
                "name": row.name,
                "firm_name": row.firm_name,
                "cluster_expertise": row.cluster_label,
                "confidence_score": row.confidence_score,
                "partnership_reason": f"Forte atuação em {row.cluster_label}, complementar às suas especializações"
            })
        
        return recommendations
```

### **Fase 3: Frontend Flutter (5-6 dias)**

#### **3.1 Estrutura de Features**
```
apps/app_flutter/lib/src/features/cluster_insights/
├── data/
│   ├── datasources/
│   │   └── cluster_remote_datasource.dart
│   ├── models/
│   │   ├── trending_cluster_model.dart
│   │   └── cluster_detail_model.dart
│   └── repositories/
│       └── cluster_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── trending_cluster.dart
│   │   └── cluster_detail.dart
│   ├── repositories/
│   │   └── cluster_repository.dart
│   └── usecases/
│       ├── get_trending_clusters.dart
│       └── get_cluster_details.dart
└── presentation/
    ├── bloc/
    │   ├── trending_clusters_bloc.dart
    │   ├── trending_clusters_event.dart
    │   └── trending_clusters_state.dart
    ├── screens/
    │   └── cluster_insights_screen.dart
    └── widgets/
        ├── trending_clusters_widget.dart
        └── cluster_trend_badge.dart
```

#### **3.2 Widget Principal: Modal Bottom Sheet Expansível**

**Conceito:** Widget **compacto no dashboard** que se expande em um **modal completo** com todas as funcionalidades de análise de clusters, sem precisar de nova aba na navegação.

**Vantagens desta Abordagem:**
✅ **Simplicidade**: Mantém dashboard limpo  
✅ **Funcionalidade Completa**: Acesso total aos insights  
✅ **UX Intuitiva**: Transição suave entre preview e análise detalhada  
✅ **Sem Mudança de Navegação**: Não adiciona complexidade ao menu principal  

**Arquivo:** `apps/app_flutter/lib/src/features/cluster_insights/presentation/widgets/expandable_clusters_widget.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/trending_clusters_bloc.dart';
import '../../domain/entities/trending_cluster.dart';

class ExpandableClustersWidget extends StatelessWidget {
  const ExpandableClustersWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TrendingClustersBloc()..add(FetchTrendingClusters()),
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com CTA "Ver Completo"
              Row(
                children: [
                  const Icon(Icons.analytics, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'Insights de Mercado',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _showFullInsightsModal(context),
                    icon: const Icon(Icons.analytics_outlined),
                    label: const Text('Ver Completo'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Preview compacto dos 3 top clusters
              const SizedBox(height: 16),
              BlocBuilder<TrendingClustersBloc, TrendingClustersState>(
                builder: (context, state) {
                  if (state is TrendingClustersLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  
                  if (state is TrendingClustersError) {
                    return Text(
                      'Erro ao carregar tendências: ${state.message}',
                      style: TextStyle(color: Colors.red[600]),
                    );
                  }
                  
                  if (state is TrendingClustersLoaded) {
                    return _buildTrendingList(context, state.clusters);
                  }
                  
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingList(BuildContext context, List<TrendingCluster> clusters) {
    if (clusters.isEmpty) {
      return const Text(
        'Nenhuma tendência identificada no momento.',
        style: TextStyle(fontStyle: FontStyle.italic),
      );
    }

    return Column(
      children: clusters.asMap().entries.map((entry) {
        final index = entry.key;
        final cluster = entry.value;
        
        return _ClusterTrendCard(
          cluster: cluster,
          rank: index + 1,
          onTap: () => _navigateToClusterDetail(context, cluster.clusterId),
        );
      }).toList(),
    );
  }

  void _navigateToFullAnalysis(BuildContext context) {
    Navigator.pushNamed(context, '/cluster-insights');
  }

  void _navigateToClusterDetail(BuildContext context, String clusterId) {
    Navigator.pushNamed(
      context, 
      '/cluster-detail',
      arguments: {'clusterId': clusterId},
    );
  }
}

class _ClusterTrendCard extends StatelessWidget {
  final TrendingCluster cluster;
  final int rank;
  final VoidCallback onTap;

  const _ClusterTrendCard({
    required this.cluster,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRankColor(),
          child: Text(
            '#$rank',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          cluster.clusterLabel,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${cluster.totalCases} casos • Momentum: ${(cluster.momentumScore * 100).toStringAsFixed(0)}%'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (cluster.isEmergent) 
              const Icon(Icons.new_releases, color: Colors.orange, size: 20),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Color _getRankColor() {
    switch (rank) {
      case 1: return Colors.amber;
      case 2: return Colors.grey[600]!;
      case 3: return Colors.brown;
      default: return Colors.blue;
    }
  }
}
```

#### **3.3 Badge para Casos em Clusters Emergentes**
**Arquivo:** `apps/app_flutter/lib/src/shared/widgets/badges/cluster_trend_badge.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ClusterTrendBadge extends StatelessWidget {
  final String? clusterId;
  final String? clusterLabel;
  final double? momentumScore;
  final bool isEmergent;
  final VoidCallback? onTap;

  const ClusterTrendBadge({
    super.key,
    this.clusterId,
    this.clusterLabel,
    this.momentumScore,
    this.isEmergent = false,
    this.onTap,
  });

  bool get _shouldShow => clusterId != null && (isEmergent || (momentumScore ?? 0) > 0.7);

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) return const SizedBox.shrink();

    final badgeColor = _getBadgeColor();
    final badgeText = _getBadgeText();
    final badgeIcon = _getBadgeIcon();

    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(0.3),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      badge = GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap!();
        },
        child: badge,
      );
    }

    return Tooltip(
      message: clusterLabel ?? 'Nicho em tendência',
      child: badge,
    );
  }

  Color _getBadgeColor() {
    if (isEmergent) return const Color(0xFFFF6B35); // Laranja vibrante
    if ((momentumScore ?? 0) > 0.8) return const Color(0xFF10B981); // Verde
    return const Color(0xFF3B82F6); // Azul
  }

  String _getBadgeText() {
    if (isEmergent) return 'NOVO';
    if ((momentumScore ?? 0) > 0.8) return 'EM ALTA';
    return 'TRENDING';
  }

  IconData _getBadgeIcon() {
    if (isEmergent) return Icons.new_releases;
    return Icons.trending_up;
  }
}
```

#### **3.4 Opção C - Híbrida: Modal Bottom Sheet Expansível**

**Conceito:** Widget compacto no dashboard que se expande em um modal completo com todas as funcionalidades.

**Arquivo:** `apps/app_flutter/lib/src/features/cluster_insights/presentation/widgets/expandable_clusters_widget.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ExpandableClustersWidget extends StatelessWidget {
  const ExpandableClustersWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Insights de Mercado',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showFullInsightsModal(context),
                  icon: const Icon(Icons.analytics_outlined),
                  label: const Text('Ver Completo'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Prévia compacta dos 3 top clusters
            BlocBuilder<TrendingClustersBloc, TrendingClustersState>(
              builder: (context, state) {
                if (state is TrendingClustersLoaded && state.clusters.isNotEmpty) {
                  return _buildCompactPreview(context, state.clusters.take(3).toList());
                }
                return const Text('Carregando insights...', style: TextStyle(fontStyle: FontStyle.italic));
              },
            ),
            
            const SizedBox(height: 12),
            
            // CTA para parceiros estratégicos
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.handshake, color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Descubra parceiros estratégicos para seu escritório',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showFullInsightsModal(context, initialTab: 'partnerships'),
                    child: const Text('Ver Agora'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactPreview(BuildContext context, List<TrendingCluster> clusters) {
    return Column(
      children: clusters.map((cluster) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: cluster.isEmergent ? Colors.orange : Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                cluster.clusterLabel,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              '${cluster.totalCases} casos',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      )).toList(),
    );
  }

  void _showFullInsightsModal(BuildContext context, {String? initialTab}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClusterInsightsModal(initialTab: initialTab),
    );
  }
}
```

#### **3.3 Modal Completo com Três Tabs**

**Arquivo:** `apps/app_flutter/lib/src/features/cluster_insights/presentation/widgets/cluster_insights_modal.dart`

```dart
class ClusterInsightsModal extends StatefulWidget {
  final String? initialTab;
  
  const ClusterInsightsModal({super.key, this.initialTab});

  @override
  State<ClusterInsightsModal> createState() => _ClusterInsightsModalState();
}

class _ClusterInsightsModalState extends State<ClusterInsightsModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab == 'partnerships' ? 2 : 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.analytics, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Insights de Mercado',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: const [
              Tab(icon: Icon(Icons.trending_up), text: 'Tendências'),
              Tab(icon: Icon(Icons.category), text: 'Todos Clusters'),
              Tab(icon: Icon(Icons.handshake), text: 'Parcerias'),
            ],
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TrendingClustersTab(),
                _AllClustersTab(),
                _PartnershipRecommendationsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// Tab 1: Tendências Detalhadas
class _TrendingClustersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nichos Emergentes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          BlocBuilder<TrendingClustersBloc, TrendingClustersState>(
            builder: (context, state) {
              if (state is TrendingClustersLoaded) {
                return Column(
                  children: state.clusters.map((cluster) => 
                    _DetailedClusterCard(cluster: cluster)
                  ).toList(),
                );
              }
              return const CircularProgressIndicator();
            },
          ),
        ],
      ),
    );
  }
}

// Tab 2: Todos os Clusters
class _AllClustersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Todos os Clusters Identificados',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Lista completa com filtros
          BlocBuilder<AllClustersBloc, AllClustersState>(
            builder: (context, state) {
              if (state is AllClustersLoaded) {
                return Column(
                  children: state.clusters.map((cluster) => 
                    _ClusterOverviewCard(cluster: cluster)
                  ).toList(),
                );
              }
              return const CircularProgressIndicator();
            },
          ),
        ],
      ),
    );
  }
}

// Tab 3: Recomendações de Parceria
class _PartnershipRecommendationsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Parceiros Estratégicos Recomendados',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Baseado em análise de complementaridade de clusters',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          
          BlocBuilder<PartnershipRecommendationsBloc, PartnershipRecommendationsState>(
            builder: (context, state) {
              if (state is PartnershipRecommendationsLoaded) {
                return Column(
                  children: state.recommendations.map((rec) => 
                    _PartnershipRecommendationCard(recommendation: rec)
                  ).toList(),
                );
              }
              return const CircularProgressIndicator();
            },
          ),
        ],
      ),
    );
  }
}
```

#### **3.4 Experiência do Usuário (UX Flow)**

### **Estado Inicial - Dashboard:**
```
┌─────────────────────────────────────┐
│ 📊 Insights de Mercado    [Ver Completo] │
├─────────────────────────────────────┤
│ • Contratos de Influenciadores  45 casos │
│ • Disputas Cripto             23 casos │  
│ • Direito de IA Generativa    12 casos │
├─────────────────────────────────────┤
│ 🤝 Descubra parceiros estratégicos    │
│                           [Ver Agora] │
└─────────────────────────────────────┘
```

### **Estado Expandido - Modal (90% da tela):**
```
┌─────────────────────────────────────┐
│   ⎼⎼⎼⎼                          ✕    │
│ 📊 Insights de Mercado              │
├─────────────────────────────────────┤
│ [Tendências] [Clusters] [Parcerias] │
├─────────────────────────────────────┤
│                                     │
│   📈 CONTEÚDO COMPLETO:             │
│   • Visão geral de clusters         │
│   • Gráficos de tendência          │
│   • Análise detalhada              │
│   • Recomendações de parceria      │
│                                     │
└─────────────────────────────────────┘
```

### **Fluxos de Navegação:**

**Cenário 1: Usuário Interessado em Tendências**
1. **Dashboard**: Vê preview dos 3 clusters em alta
2. **Clica**: "Ver Completo" 
3. **Modal**: Abre na Tab "Tendências" com análise detalhada
4. **Ação**: Pode clicar em cluster específico para ver detalhes

**Cenário 2: Usuário Busca Parceiros**
1. **Dashboard**: Vê banner "Descubra parceiros estratégicos"
2. **Clica**: "Ver Agora"
3. **Modal**: Abre diretamente na Tab "Parcerias"
4. **Ação**: Vê recomendações e pode conectar ou dispensar

**Cenário 3: Usuário Quer Visão Completa**
1. **Dashboard**: Clica "Ver Completo"
2. **Modal**: Abre na Tab "Tendências" (padrão)
3. **Navegação**: Pode alternar entre as 3 tabs livremente
4. **Fechamento**: Swipe down ou botão X volta ao dashboard

#### **3.5 Integração no Dashboard Principal**
```dart
// No arquivo do dashboard principal do advogado
children: [
  // ... widgets existentes ...
  
  // Widget híbrido - compacto mas expansível para funcionalidade completa
  const ExpandableClustersWidget(),
  
  // ... resto dos widgets ...
]
```

### **🎯 Resultado Final da Opção Híbrida:**

✅ **Simplicidade**: Dashboard limpo com preview útil  
✅ **Funcionalidade**: Acesso completo via modal intuitivo  
✅ **Performance**: Carregamento progressivo conforme necessidade  
✅ **UX Superior**: Transição fluida entre estados  
✅ **Business Intelligence**: Todas as funcionalidades avançadas  

### **Por que é a Solução Ideal:**
- ✅ **Não sobrecarrega** a navegação principal
- ✅ **Oferece value preview** no dashboard  
- ✅ **Expande sob demanda** com funcionalidade completa
- ✅ **Mantém foco** no contexto atual do usuário
- ✅ **Facilita adoção** com descoberta gradual

#### **3.5 Registro de Dependências**
**Arquivo:** `apps/app_flutter/lib/injection_container.dart`

```dart
// Adicionar ao método de setup:

// Cluster Insights Feature
sl.registerLazySingleton<ClusterRemoteDataSource>(
  () => ClusterRemoteDataSourceImpl(client: sl()),
);

sl.registerLazySingleton<ClusterRepository>(
  () => ClusterRepositoryImpl(remoteDataSource: sl()),
);

sl.registerLazySingleton<GetTrendingClusters>(
  () => GetTrendingClusters(repository: sl()),
);

sl.registerFactory(() => TrendingClustersBloc(getTrendingClusters: sl()));
```

#### **3.6 Configuração de Rotas**
**Arquivo:** `apps/app_flutter/lib/src/core/routes/app_router.dart`

```dart
// Adicionar novas rotas:
'/cluster-insights': (context) => const ClusterInsightsScreen(),
'/cluster-detail': (context) {
  final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
  return ClusterDetailScreen(clusterId: args['clusterId']);
},
```

---

## 📈 Observabilidade e Métricas

### **Analytics de Adoção**
**Arquivo:** `packages/backend/services/cluster_analytics_service.py`

```python
async def track_cluster_interaction(
    user_id: str,
    action: str,  # 'view_trending', 'click_cluster', 'accept_partnership'
    cluster_id: str,
    metadata: Dict[str, Any] = None
):
    """Rastreia interações do usuário com clusters."""
    
    event = {
        "user_id": user_id,
        "event_type": f"cluster_{action}",
        "cluster_id": cluster_id,
        "timestamp": datetime.now().isoformat(),
        "metadata": metadata or {}
    }
    
    # Salvar em tabela de eventos para análise posterior
    await save_analytics_event(event)
```

### **Métricas de Sucesso**
- **Taxa de clique em clusters trending**: % de usuários que clicam em clusters sugeridos
- **Taxa de conversão de parcerias**: % de recomendações que resultam em parcerias
- **Qualidade dos clusters**: Feedback dos usuários sobre relevância
- **Detecção de nichos**: Tempo entre identificação automática e adoção manual

---

## ✅ Roadmap de Implementação

### **Sprint 1 (5 dias): Backend Foundation**
- [ ] Modificar `EmbeddingService` com rastreabilidade
- [ ] Criar tabelas de cluster no banco
- [ ] Implementar `ClusterGenerationJob` básico
- [ ] Criar APIs REST fundamentais

### **Sprint 2 (3 dias): Clusterização Inteligente**
- [ ] Implementar algoritmo HDBSCAN híbrido
- [ ] Desenvolver detecção de clusters emergentes
- [ ] Criar rotulagem automática via LLM
- [ ] Sistema de métricas de momentum

### **Sprint 3 (4 dias): Frontend MVP**
- [ ] Estrutura de features Flutter
- [ ] `TrendingClustersWidget` para dashboard
- [ ] `ClusterTrendBadge` para casos
- [ ] Integração com APIs backend

### **Sprint 4 (2 dias): Integração e Polimento**
- [ ] Registro de dependências
- [ ] Configuração de rotas
- [ ] Testes de integração
- [ ] Sistema de analytics

### **Sprint 5 (2 dias): Observabilidade e Deploy**
- [ ] Métricas de performance
- [ ] Logging estruturado
- [ ] Monitoramento de clusters
- [ ] Deploy em produção

---

## 🎯 Critérios de Sucesso

### **Técnicos**
- [ ] Pipeline de clusterização roda sem erros a cada 6h
- [ ] APIs respondem em <500ms
- [ ] Taxa de sucesso de embedding > 95%
- [ ] Clusters têm coesão (Silhouette Score > 0.5)

### **Produto**
- [ ] Widget carrega em <2s no dashboard
- [ ] 3+ clusters emergentes detectados por semana
- [ ] 5+ recomendações de parceria por advogado ativo
- [ ] Feedback positivo de usuários > 80%

### **Negócio**
- [ ] 10%+ dos advogados interagem com tendências mensalmente
- [ ] 2%+ das recomendações resultam em parcerias
- [ ] Identificação de 1+ nicho emergente por mês
- [ ] ROI positivo em 6 meses

---

**Status:** Plano Completo Aprovado para Implementação ✅ 