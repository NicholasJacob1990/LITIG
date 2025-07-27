-- =============================================================================
-- Migration 015: Create Cluster Tables (Simplified)
-- =============================================================================
-- Criação das tabelas de clusterização sem dependência de pgvector para início

-- =============================================================================
-- TABELAS DE CLUSTERS PRINCIPAIS
-- =============================================================================

-- Metadados gerais dos clusters
CREATE TABLE IF NOT EXISTS cluster_metadata (
    cluster_id VARCHAR(50) PRIMARY KEY,
    cluster_type VARCHAR(20) NOT NULL CHECK (cluster_type IN ('case', 'lawyer')),
    cluster_label VARCHAR(255) NOT NULL,
    description TEXT,
    total_items INTEGER DEFAULT 0 CHECK (total_items >= 0),
    momentum_score FLOAT DEFAULT 0.0 CHECK (momentum_score >= 0 AND momentum_score <= 1),
    is_emergent BOOLEAN DEFAULT FALSE,
    emergent_since TIMESTAMP WITH TIME ZONE,
    silhouette_score FLOAT CHECK (silhouette_score >= -1 AND silhouette_score <= 1),
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela para clusters de casos
CREATE TABLE IF NOT EXISTS case_clusters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id UUID NOT NULL,
    cluster_id VARCHAR(50) NOT NULL,
    cluster_label VARCHAR(255),
    confidence_score FLOAT CHECK (confidence_score >= 0 AND confidence_score <= 1),
    is_emergent BOOLEAN DEFAULT FALSE,
    momentum_score FLOAT DEFAULT 0.0 CHECK (momentum_score >= 0 AND momentum_score <= 1),
    assigned_method VARCHAR(20) DEFAULT 'hdbscan' CHECK (assigned_method IN ('hdbscan', 'similarity', 'manual')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraint para evitar duplicatas
    UNIQUE(case_id, cluster_id)
);

-- Tabela para clusters de advogados
CREATE TABLE IF NOT EXISTS lawyer_clusters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lawyer_id UUID NOT NULL,
    cluster_id VARCHAR(50) NOT NULL,
    cluster_label VARCHAR(255),
    confidence_score FLOAT CHECK (confidence_score >= 0 AND confidence_score <= 1),
    assigned_method VARCHAR(20) DEFAULT 'hdbscan' CHECK (assigned_method IN ('hdbscan', 'similarity', 'manual')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraint para evitar duplicatas
    UNIQUE(lawyer_id, cluster_id)
);

-- =============================================================================
-- TABELAS DE RÓTULOS
-- =============================================================================

-- Tabela específica para rótulos de clusters de casos
CREATE TABLE IF NOT EXISTS case_cluster_labels (
    cluster_id VARCHAR(50) PRIMARY KEY,
    label VARCHAR(255) NOT NULL,
    description TEXT,
    confidence_score FLOAT DEFAULT 0.8 CHECK (confidence_score >= 0 AND confidence_score <= 1),
    generated_by VARCHAR(50) DEFAULT 'llm_auto', -- 'llm_auto', 'manual', 'hybrid'
    llm_model VARCHAR(50), -- 'gpt-4o', 'gemini-pro', etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela específica para rótulos de clusters de advogados  
CREATE TABLE IF NOT EXISTS lawyer_cluster_labels (
    cluster_id VARCHAR(50) PRIMARY KEY,
    label VARCHAR(255) NOT NULL,
    description TEXT,
    confidence_score FLOAT DEFAULT 0.8 CHECK (confidence_score >= 0 AND confidence_score <= 1),
    generated_by VARCHAR(50) DEFAULT 'llm_auto', -- 'llm_auto', 'manual', 'hybrid'
    llm_model VARCHAR(50), -- 'gpt-4o', 'gemini-pro', etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================================================
-- TABELAS DE MÉTRICAS E ANALYTICS
-- =============================================================================

-- Tabela para histórico de momentum dos clusters
CREATE TABLE IF NOT EXISTS cluster_momentum_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cluster_id VARCHAR(50) NOT NULL,
    cluster_type VARCHAR(20) NOT NULL CHECK (cluster_type IN ('case', 'lawyer')),
    momentum_score FLOAT NOT NULL CHECK (momentum_score >= 0 AND momentum_score <= 1),
    total_items INTEGER NOT NULL CHECK (total_items >= 0),
    new_items_count INTEGER DEFAULT 0 CHECK (new_items_count >= 0),
    period_start TIMESTAMP WITH TIME ZONE NOT NULL,
    period_end TIMESTAMP WITH TIME ZONE NOT NULL,
    calculation_method VARCHAR(50) DEFAULT 'growth_rate',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela para recomendações de parceria
CREATE TABLE IF NOT EXISTS partnership_recommendations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lawyer_id UUID NOT NULL,
    recommended_lawyer_id UUID NOT NULL,
    recommended_firm_id UUID,
    cluster_expertise VARCHAR(255) NOT NULL,
    compatibility_score FLOAT NOT NULL CHECK (compatibility_score >= 0 AND compatibility_score <= 1),
    recommendation_reason TEXT,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'viewed', 'contacted', 'accepted', 'dismissed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    
    -- Evitar recomendações duplicadas
    UNIQUE(lawyer_id, recommended_lawyer_id, cluster_expertise)
);

-- =============================================================================
-- ÍNDICES PARA PERFORMANCE
-- =============================================================================

-- Índices para clusters
CREATE INDEX IF NOT EXISTS idx_case_clusters_cluster_id ON case_clusters(cluster_id);
CREATE INDEX IF NOT EXISTS idx_case_clusters_case_id ON case_clusters(case_id);
CREATE INDEX IF NOT EXISTS idx_case_clusters_emergent ON case_clusters(is_emergent) WHERE is_emergent = TRUE;
CREATE INDEX IF NOT EXISTS idx_case_clusters_momentum ON case_clusters(momentum_score DESC);

CREATE INDEX IF NOT EXISTS idx_lawyer_clusters_cluster_id ON lawyer_clusters(cluster_id);
CREATE INDEX IF NOT EXISTS idx_lawyer_clusters_lawyer_id ON lawyer_clusters(lawyer_id);

-- Índices para metadados
CREATE INDEX IF NOT EXISTS idx_cluster_metadata_type ON cluster_metadata(cluster_type);
CREATE INDEX IF NOT EXISTS idx_cluster_metadata_momentum ON cluster_metadata(momentum_score DESC);
CREATE INDEX IF NOT EXISTS idx_cluster_metadata_emergent ON cluster_metadata(is_emergent) WHERE is_emergent = TRUE;
CREATE INDEX IF NOT EXISTS idx_cluster_metadata_updated ON cluster_metadata(last_updated DESC);

-- Índices para analytics
CREATE INDEX IF NOT EXISTS idx_momentum_history_cluster ON cluster_momentum_history(cluster_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_partnership_recommendations_lawyer ON partnership_recommendations(lawyer_id, status);
CREATE INDEX IF NOT EXISTS idx_partnership_recommendations_expires ON partnership_recommendations(expires_at) WHERE expires_at IS NOT NULL;

-- =============================================================================
-- FUNÇÃO PARA BUSCAR CLUSTERS TRENDING
-- =============================================================================

CREATE OR REPLACE FUNCTION get_trending_clusters(
    p_cluster_type VARCHAR(20) DEFAULT 'case',
    p_limit INT DEFAULT 10,
    p_min_items INT DEFAULT 5
)
RETURNS TABLE(
    cluster_id VARCHAR(50),
    cluster_label VARCHAR(255),
    momentum_score FLOAT,
    total_items INTEGER,
    is_emergent BOOLEAN,
    emergent_since TIMESTAMP WITH TIME ZONE,
    label_confidence FLOAT
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validar tipo de cluster
    IF p_cluster_type NOT IN ('case', 'lawyer') THEN
        RAISE EXCEPTION 'Tipo de cluster inválido: %', p_cluster_type;
    END IF;
    
    RETURN QUERY
    SELECT 
        cm.cluster_id,
        COALESCE(cl.label, cm.cluster_label, 'Cluster sem nome') as cluster_label,
        cm.momentum_score,
        cm.total_items,
        cm.is_emergent,
        cm.emergent_since,
        cl.confidence_score as label_confidence
    FROM cluster_metadata cm
    LEFT JOIN (
        SELECT cluster_id, label, confidence_score 
        FROM case_cluster_labels 
        WHERE p_cluster_type = 'case'
        UNION ALL
        SELECT cluster_id, label, confidence_score 
        FROM lawyer_cluster_labels 
        WHERE p_cluster_type = 'lawyer'
    ) cl ON cm.cluster_id = cl.cluster_id
    WHERE cm.cluster_type = p_cluster_type 
        AND cm.total_items >= p_min_items
    ORDER BY cm.momentum_score DESC, cm.total_items DESC
    LIMIT p_limit;
END;
$$;

-- =============================================================================
-- INSERÇÃO DE DADOS DE EXEMPLO
-- =============================================================================

-- Inserir alguns metadados exemplo para teste
INSERT INTO cluster_metadata (cluster_id, cluster_type, cluster_label, description) VALUES
('case_cluster_example_1', 'case', 'Contratos Digitais', 'Casos relacionados a contratos e disputas em ambiente digital'),
('case_cluster_example_2', 'case', 'Direito Tributário Startups', 'Questões tributárias específicas para empresas de tecnologia'),
('lawyer_cluster_example_1', 'lawyer', 'Especialistas em Cripto', 'Advogados especializados em criptomoedas e blockchain')
ON CONFLICT (cluster_id) DO NOTHING;

-- =============================================================================
-- FIM DA MIGRATION
-- =============================================================================

-- Log de conclusão
DO $$
BEGIN
    RAISE NOTICE '✅ Migration 015 (simplificada) concluída: Tabelas de clusterização criadas!';
    RAISE NOTICE '📊 Tabelas criadas: case_clusters, lawyer_clusters, cluster_metadata';
    RAISE NOTICE '🏷️ Tabelas de rótulos: case_cluster_labels, lawyer_cluster_labels';
    RAISE NOTICE '📈 Tabelas de analytics: cluster_momentum_history, partnership_recommendations';
    RAISE NOTICE '⚡ Função RPC: get_trending_clusters';
END $$;