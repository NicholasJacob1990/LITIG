-- =============================================================================
-- Migration 015: Create Cluster Tables
-- =============================================================================
-- Criação de todas as tabelas necessárias para o sistema de clusterização
-- de casos e advogados baseado em embeddings com rastreabilidade completa
-- 
-- Autor: Sistema LITIG-1
-- Data: $(date)
-- Versão: 1.0
-- =============================================================================

-- Habilitar extensão pgvector se não estiver habilitada
CREATE EXTENSION IF NOT EXISTS vector;

-- =============================================================================
-- TABELAS DE EMBEDDINGS COM RASTREABILIDADE
-- =============================================================================

-- Tabela para embeddings de casos com rastreabilidade de origem
CREATE TABLE IF NOT EXISTS case_embeddings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id UUID NOT NULL,
    embedding_vector VECTOR(768) NOT NULL,
    embedding_provider VARCHAR(20) NOT NULL CHECK (embedding_provider IN ('gemini', 'openai', 'local')),
    data_sources JSONB NOT NULL DEFAULT '{}', -- {'escavador': true, 'lex9000': true, 'triagem_ia': true}
    consolidated_text TEXT, -- Texto consolidado usado para gerar embedding
    confidence_score FLOAT DEFAULT 0.8 CHECK (confidence_score >= 0 AND confidence_score <= 1),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Foreign key para casos (assumindo que existe tabela cases)
    FOREIGN KEY (case_id) REFERENCES cases(id) ON DELETE CASCADE
);

-- Tabela para embeddings de advogados com rastreabilidade de origem  
CREATE TABLE IF NOT EXISTS lawyer_embeddings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lawyer_id UUID NOT NULL,
    embedding_vector VECTOR(768) NOT NULL,
    embedding_provider VARCHAR(20) NOT NULL CHECK (embedding_provider IN ('gemini', 'openai', 'local')),
    data_sources JSONB NOT NULL DEFAULT '{}', -- {'linkedin': true, 'escavador': true, 'perplexity': true, 'deep_research': true, 'unipile': true}
    consolidated_text TEXT, -- Bio consolidada de todas as fontes
    confidence_score FLOAT DEFAULT 0.8 CHECK (confidence_score >= 0 AND confidence_score <= 1),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Foreign key para advogados (assumindo que existe tabela lawyers)
    FOREIGN KEY (lawyer_id) REFERENCES lawyers(id) ON DELETE CASCADE
);

-- =============================================================================
-- TABELAS DE CLUSTERS
-- =============================================================================

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
    
    -- Foreign keys
    FOREIGN KEY (case_id) REFERENCES cases(id) ON DELETE CASCADE,
    
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
    
    -- Foreign keys
    FOREIGN KEY (lawyer_id) REFERENCES lawyers(id) ON DELETE CASCADE,
    
    -- Constraint para evitar duplicatas
    UNIQUE(lawyer_id, cluster_id)
);

-- =============================================================================
-- TABELAS DE METADADOS DOS CLUSTERS
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
    
    -- Foreign keys
    FOREIGN KEY (lawyer_id) REFERENCES lawyers(id) ON DELETE CASCADE,
    FOREIGN KEY (recommended_lawyer_id) REFERENCES lawyers(id) ON DELETE CASCADE,
    
    -- Evitar recomendações duplicadas
    UNIQUE(lawyer_id, recommended_lawyer_id, cluster_expertise)
);

-- =============================================================================
-- ÍNDICES PARA PERFORMANCE
-- =============================================================================

-- Índices para embeddings
CREATE INDEX IF NOT EXISTS idx_case_embeddings_case_id ON case_embeddings(case_id);
CREATE INDEX IF NOT EXISTS idx_case_embeddings_provider ON case_embeddings(embedding_provider);
CREATE INDEX IF NOT EXISTS idx_case_embeddings_created_at ON case_embeddings(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_lawyer_embeddings_lawyer_id ON lawyer_embeddings(lawyer_id);
CREATE INDEX IF NOT EXISTS idx_lawyer_embeddings_provider ON lawyer_embeddings(embedding_provider);
CREATE INDEX IF NOT EXISTS idx_lawyer_embeddings_created_at ON lawyer_embeddings(created_at DESC);

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

-- Índices vetoriais para similarity search (pgvector)
CREATE INDEX IF NOT EXISTS idx_case_embeddings_vector ON case_embeddings USING ivfflat (embedding_vector vector_cosine_ops) WITH (lists = 100);
CREATE INDEX IF NOT EXISTS idx_lawyer_embeddings_vector ON lawyer_embeddings USING ivfflat (embedding_vector vector_cosine_ops) WITH (lists = 100);

-- =============================================================================
-- FUNÇÃO RPC PARA BUSCAR TEXTOS DE CLUSTER (OTIMIZAÇÃO SUPABASE)
-- =============================================================================

CREATE OR REPLACE FUNCTION get_cluster_texts(
    cluster_table_name TEXT,
    source_table_name TEXT,
    target_cluster_id VARCHAR(50),
    limit_n INT DEFAULT 5
)
RETURNS TABLE(
    entity_id UUID, 
    full_text TEXT, 
    confidence_score FLOAT,
    embedding_provider VARCHAR(20),
    data_sources JSONB
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validar parâmetros de entrada
    IF cluster_table_name NOT IN ('case_clusters', 'lawyer_clusters') THEN
        RAISE EXCEPTION 'Tabela de cluster inválida: %', cluster_table_name;
    END IF;
    
    IF source_table_name NOT IN ('cases', 'lawyers') THEN
        RAISE EXCEPTION 'Tabela de origem inválida: %', source_table_name;
    END IF;
    
    -- Query para clusters de casos
    IF cluster_table_name = 'case_clusters' AND source_table_name = 'cases' THEN
        RETURN QUERY
        SELECT 
            c.case_id as entity_id,
            COALESCE(ce.consolidated_text, s.description, s.title) as full_text,
            c.confidence_score,
            ce.embedding_provider,
            ce.data_sources
        FROM case_clusters c
        JOIN cases s ON c.case_id = s.id
        LEFT JOIN case_embeddings ce ON c.case_id = ce.case_id
        WHERE c.cluster_id = target_cluster_id
        ORDER BY c.confidence_score DESC, c.created_at DESC
        LIMIT limit_n;
        
    -- Query para clusters de advogados
    ELSIF cluster_table_name = 'lawyer_clusters' AND source_table_name = 'lawyers' THEN
        RETURN QUERY
        SELECT 
            l.lawyer_id as entity_id,
            COALESCE(le.consolidated_text, s.bio, s.name) as full_text,
            l.confidence_score,
            le.embedding_provider,
            le.data_sources
        FROM lawyer_clusters l
        JOIN lawyers s ON l.lawyer_id = s.id
        LEFT JOIN lawyer_embeddings le ON l.lawyer_id = le.lawyer_id
        WHERE l.cluster_id = target_cluster_id
        ORDER BY l.confidence_score DESC, l.created_at DESC
        LIMIT limit_n;
        
    ELSE
        RAISE EXCEPTION 'Combinação inválida de tabelas: % e %', cluster_table_name, source_table_name;
    END IF;
END;
$$;

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
-- FUNÇÃO PARA CÁLCULO DE SIMILARIDADE VETORIAL
-- =============================================================================

CREATE OR REPLACE FUNCTION calculate_vector_similarity(
    vector1 VECTOR(768),
    vector2 VECTOR(768),
    similarity_method VARCHAR(20) DEFAULT 'cosine'
)
RETURNS FLOAT
LANGUAGE plpgsql
AS $$
DECLARE
    similarity_score FLOAT;
BEGIN
    CASE similarity_method
        WHEN 'cosine' THEN
            similarity_score := 1 - (vector1 <=> vector2);
        WHEN 'euclidean' THEN  
            similarity_score := 1 / (1 + (vector1 <-> vector2));
        WHEN 'inner_product' THEN
            similarity_score := vector1 <#> vector2;
        ELSE
            RAISE EXCEPTION 'Método de similaridade inválido: %', similarity_method;
    END CASE;
    
    RETURN similarity_score;
END;
$$;

-- =============================================================================
-- TRIGGERS PARA ATUALIZAÇÃO AUTOMÁTICA
-- =============================================================================

-- Trigger para atualizar timestamp em embeddings
CREATE OR REPLACE FUNCTION update_embedding_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER case_embeddings_update_timestamp
    BEFORE UPDATE ON case_embeddings
    FOR EACH ROW
    EXECUTE FUNCTION update_embedding_timestamp();

CREATE TRIGGER lawyer_embeddings_update_timestamp
    BEFORE UPDATE ON lawyer_embeddings
    FOR EACH ROW
    EXECUTE FUNCTION update_embedding_timestamp();

-- Trigger para atualizar contadores em cluster_metadata
CREATE OR REPLACE FUNCTION update_cluster_metadata_count()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    table_prefix VARCHAR(10);
    count_total INTEGER;
BEGIN
    -- Determinar prefixo da tabela
    IF TG_TABLE_NAME = 'case_clusters' THEN
        table_prefix := 'case';
    ELSIF TG_TABLE_NAME = 'lawyer_clusters' THEN
        table_prefix := 'lawyer';
    ELSE
        RETURN COALESCE(NEW, OLD);
    END IF;
    
    -- Operação de INSERT ou UPDATE
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
        -- Contar total de items no cluster
        EXECUTE format('SELECT COUNT(*) FROM %I WHERE cluster_id = $1', TG_TABLE_NAME)
        INTO count_total
        USING NEW.cluster_id;
        
        -- Atualizar ou inserir metadata
        INSERT INTO cluster_metadata (cluster_id, cluster_type, cluster_label, total_items, last_updated)
        VALUES (NEW.cluster_id, table_prefix, NEW.cluster_label, count_total, NOW())
        ON CONFLICT (cluster_id) 
        DO UPDATE SET 
            total_items = count_total,
            last_updated = NOW();
            
        RETURN NEW;
    END IF;
    
    -- Operação de DELETE
    IF TG_OP = 'DELETE' THEN
        -- Contar total restante no cluster
        EXECUTE format('SELECT COUNT(*) FROM %I WHERE cluster_id = $1', TG_TABLE_NAME)
        INTO count_total
        USING OLD.cluster_id;
        
        IF count_total = 0 THEN
            -- Remover metadata se cluster estiver vazio
            DELETE FROM cluster_metadata WHERE cluster_id = OLD.cluster_id;
        ELSE
            -- Atualizar contador
            UPDATE cluster_metadata 
            SET total_items = count_total, last_updated = NOW()
            WHERE cluster_id = OLD.cluster_id;
        END IF;
        
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$;

-- Aplicar trigger às tabelas de cluster
CREATE TRIGGER case_clusters_update_metadata
    AFTER INSERT OR UPDATE OR DELETE ON case_clusters
    FOR EACH ROW
    EXECUTE FUNCTION update_cluster_metadata_count();

CREATE TRIGGER lawyer_clusters_update_metadata
    AFTER INSERT OR UPDATE OR DELETE ON lawyer_clusters
    FOR EACH ROW
    EXECUTE FUNCTION update_cluster_metadata_count();

-- =============================================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- =============================================================================

-- Comentários nas tabelas principais
COMMENT ON TABLE case_embeddings IS 'Embeddings de casos com rastreabilidade de origem e multi-fonte';
COMMENT ON TABLE lawyer_embeddings IS 'Embeddings de advogados com dados consolidados de múltiplas APIs';
COMMENT ON TABLE case_clusters IS 'Clusters de casos gerados via HDBSCAN com métricas de qualidade';
COMMENT ON TABLE lawyer_clusters IS 'Clusters de advogados para análise de especialização';
COMMENT ON TABLE cluster_metadata IS 'Metadados centralizados de todos os clusters';
COMMENT ON TABLE partnership_recommendations IS 'Recomendações de parceria baseadas em complementaridade de clusters';

-- Comentários nas colunas importantes
COMMENT ON COLUMN case_embeddings.embedding_provider IS 'Origem do embedding: gemini, openai ou local';
COMMENT ON COLUMN case_embeddings.data_sources IS 'JSON com fontes de dados utilizadas: escavador, lex9000, triagem_ia';
COMMENT ON COLUMN case_embeddings.consolidated_text IS 'Texto final usado para gerar o embedding';
COMMENT ON COLUMN cluster_metadata.momentum_score IS 'Score de crescimento/tendência do cluster (0-1)';
COMMENT ON COLUMN cluster_metadata.is_emergent IS 'Marca clusters identificados como nichos emergentes';

-- =============================================================================
-- INSERÇÃO DE DADOS DE EXEMPLO (OPCIONAL)
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
    RAISE NOTICE '✅ Migration 015 concluída: Tabelas de clusterização criadas com sucesso!';
    RAISE NOTICE '📊 Tabelas criadas: case_embeddings, lawyer_embeddings, case_clusters, lawyer_clusters, cluster_metadata';
    RAISE NOTICE '🏷️ Tabelas de rótulos: case_cluster_labels, lawyer_cluster_labels';
    RAISE NOTICE '📈 Tabelas de analytics: cluster_momentum_history, partnership_recommendations';
    RAISE NOTICE '⚡ Funções RPC: get_cluster_texts, get_trending_clusters, calculate_vector_similarity';
    RAISE NOTICE '🔧 Triggers automáticos configurados para manutenção de contadores';
END $$; 