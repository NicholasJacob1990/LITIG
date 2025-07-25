-- Migration: Criar tabelas para dados híbridos consolidados
-- Data: 2024-01-15
-- Descrição: Tabelas para armazenar perfis consolidados, embeddings e métricas de qualidade

-- ============================================
-- EXTENSÕES NECESSÁRIAS
-- ============================================

-- Extensão para UUIDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Extensão para vetores (embeddings)
CREATE EXTENSION IF NOT EXISTS vector;

-- Extensão para JSON avançado
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- ============================================
-- ENUMS
-- ============================================

-- Tipos de fontes de dados
CREATE TYPE data_source_type AS ENUM (
    'linkedin',
    'academic', 
    'escavador',
    'jusbrasil',
    'deep_research',
    'internal'
);

-- Níveis de qualidade dos dados
CREATE TYPE data_quality_level AS ENUM (
    'high',
    'medium',
    'low',
    'unknown'
);

-- Status de consolidação
CREATE TYPE consolidation_status AS ENUM (
    'pending',
    'in_progress', 
    'completed',
    'failed',
    'expired'
);

-- ============================================
-- TABELA: consolidated_lawyer_profiles
-- ============================================

CREATE TABLE consolidated_lawyer_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lawyer_id VARCHAR(255) NOT NULL UNIQUE,
    
    -- Dados básicos
    full_name VARCHAR(500) NOT NULL,
    alternative_names JSONB DEFAULT '[]',
    
    -- Perfis por fonte
    linkedin_profile JSONB,
    academic_profile JSONB,
    legal_cases_data JSONB,
    market_insights JSONB,
    platform_metrics JSONB,
    
    -- Scores consolidados
    social_influence_score DECIMAL(5,2) DEFAULT 0.0,
    academic_prestige_score DECIMAL(5,2) DEFAULT 0.0,
    legal_expertise_score DECIMAL(5,2) DEFAULT 0.0,
    market_reputation_score DECIMAL(5,2) DEFAULT 0.0,
    overall_success_probability DECIMAL(5,2) DEFAULT 0.0,
    
    -- Métricas de qualidade
    overall_quality_score DECIMAL(4,3) NOT NULL DEFAULT 0.0,
    completeness_score DECIMAL(4,3) NOT NULL DEFAULT 0.0,
    
    -- Metadados
    consolidation_status consolidation_status DEFAULT 'pending',
    consolidation_version VARCHAR(10) DEFAULT '1.0',
    last_consolidated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Índices
    CONSTRAINT consolidated_lawyer_profiles_lawyer_id_key UNIQUE (lawyer_id),
    CONSTRAINT consolidated_lawyer_profiles_quality_score_check CHECK (overall_quality_score >= 0.0 AND overall_quality_score <= 1.0),
    CONSTRAINT consolidated_lawyer_profiles_completeness_check CHECK (completeness_score >= 0.0 AND completeness_score <= 1.0)
);

-- Índices para performance
CREATE INDEX idx_consolidated_profiles_lawyer_id ON consolidated_lawyer_profiles(lawyer_id);
CREATE INDEX idx_consolidated_profiles_quality_score ON consolidated_lawyer_profiles(overall_quality_score DESC);
CREATE INDEX idx_consolidated_profiles_consolidation_status ON consolidated_lawyer_profiles(consolidation_status);
CREATE INDEX idx_consolidated_profiles_last_consolidated ON consolidated_lawyer_profiles(last_consolidated DESC);
CREATE INDEX idx_consolidated_profiles_linkedin_profile ON consolidated_lawyer_profiles USING GIN (linkedin_profile) WHERE linkedin_profile IS NOT NULL;
CREATE INDEX idx_consolidated_profiles_academic_profile ON consolidated_lawyer_profiles USING GIN (academic_profile) WHERE academic_profile IS NOT NULL;

-- ============================================
-- TABELA: data_source_info
-- ============================================

CREATE TABLE data_source_info (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES consolidated_lawyer_profiles(id) ON DELETE CASCADE,
    
    -- Fonte
    source_type data_source_type NOT NULL,
    
    -- Metadados da fonte
    last_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    quality data_quality_level NOT NULL DEFAULT 'unknown',
    confidence_score DECIMAL(4,3) NOT NULL DEFAULT 0.0,
    fields_available JSONB DEFAULT '[]',
    
    -- Custos e limitações
    cost_per_query DECIMAL(8,4) DEFAULT 0.0,
    rate_limit_per_hour INTEGER DEFAULT 100,
    
    -- Dados específicos da fonte
    source_metadata JSONB DEFAULT '{}',
    raw_data JSONB,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT data_source_info_confidence_check CHECK (confidence_score >= 0.0 AND confidence_score <= 1.0),
    CONSTRAINT data_source_info_unique_per_profile UNIQUE (profile_id, source_type)
);

-- Índices
CREATE INDEX idx_data_source_info_profile_id ON data_source_info(profile_id);
CREATE INDEX idx_data_source_info_source_type ON data_source_info(source_type);
CREATE INDEX idx_data_source_info_quality ON data_source_info(quality);
CREATE INDEX idx_data_source_info_last_updated ON data_source_info(last_updated DESC);
CREATE INDEX idx_data_source_info_raw_data ON data_source_info USING GIN (raw_data) WHERE raw_data IS NOT NULL;

-- ============================================
-- TABELA: lawyer_embeddings
-- ============================================

CREATE TABLE lawyer_embeddings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lawyer_id VARCHAR(255) NOT NULL,
    profile_id UUID REFERENCES consolidated_lawyer_profiles(id) ON DELETE CASCADE,
    
    -- Embedding
    embedding vector(768) NOT NULL,
    embedding_provider VARCHAR(50) NOT NULL, -- 'gemini', 'openai', 'local'
    
    -- Dados de origem
    source_text TEXT NOT NULL,
    source_sources JSONB DEFAULT '[]', -- Fontes que contribuíram para o texto
    
    -- Metadados
    embedding_model VARCHAR(100) NOT NULL,
    embedding_version VARCHAR(20) DEFAULT '1.0',
    confidence_score DECIMAL(4,3) DEFAULT 1.0,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT lawyer_embeddings_confidence_check CHECK (confidence_score >= 0.0 AND confidence_score <= 1.0)
);

-- Índices para embeddings (busca vetorial)
CREATE INDEX idx_lawyer_embeddings_lawyer_id ON lawyer_embeddings(lawyer_id);
CREATE INDEX idx_lawyer_embeddings_embedding_cosine ON lawyer_embeddings USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
CREATE INDEX idx_lawyer_embeddings_embedding_l2 ON lawyer_embeddings USING ivfflat (embedding vector_l2_ops) WITH (lists = 100);
CREATE INDEX idx_lawyer_embeddings_provider ON lawyer_embeddings(embedding_provider);
CREATE INDEX idx_lawyer_embeddings_created_at ON lawyer_embeddings(created_at DESC);

-- ============================================
-- TABELA: data_quality_reports
-- ============================================

CREATE TABLE data_quality_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES consolidated_lawyer_profiles(id) ON DELETE CASCADE,
    
    -- Métricas de qualidade
    total_fields INTEGER NOT NULL DEFAULT 0,
    completed_fields INTEGER NOT NULL DEFAULT 0,
    completeness_percentage DECIMAL(5,2) NOT NULL DEFAULT 0.0,
    
    -- Problemas identificados
    missing_critical_data JSONB DEFAULT '[]',
    data_inconsistencies JSONB DEFAULT '[]',
    
    -- Métricas por fonte
    source_quality_breakdown JSONB DEFAULT '{}',
    
    -- Métricas de freshness
    data_freshness_hours INTEGER DEFAULT 0,
    oldest_data_source VARCHAR(50),
    newest_data_source VARCHAR(50),
    
    -- Recomendações
    quality_recommendations JSONB DEFAULT '[]',
    priority_actions JSONB DEFAULT '[]',
    
    -- Metadados
    report_version VARCHAR(10) DEFAULT '1.0',
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT data_quality_reports_completeness_check CHECK (completeness_percentage >= 0.0 AND completeness_percentage <= 100.0)
);

-- Índices
CREATE INDEX idx_data_quality_reports_profile_id ON data_quality_reports(profile_id);
CREATE INDEX idx_data_quality_reports_completeness ON data_quality_reports(completeness_percentage DESC);
CREATE INDEX idx_data_quality_reports_generated_at ON data_quality_reports(generated_at DESC);

-- ============================================
-- TABELA: transparency_audit_log
-- ============================================

CREATE TABLE transparency_audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID REFERENCES consolidated_lawyer_profiles(id) ON DELETE CASCADE,
    
    -- Ação auditada
    action_type VARCHAR(100) NOT NULL, -- 'data_collection', 'consolidation', 'update', 'access'
    source_type data_source_type,
    
    -- Detalhes da ação
    action_details JSONB DEFAULT '{}',
    data_accessed JSONB DEFAULT '{}',
    
    -- Custos
    cost_incurred DECIMAL(8,4) DEFAULT 0.0,
    cost_currency VARCHAR(3) DEFAULT 'USD',
    
    -- Origem da ação
    triggered_by VARCHAR(255), -- user_id, system, job, etc.
    request_ip VARCHAR(45),
    user_agent TEXT,
    
    -- Resultados
    success BOOLEAN DEFAULT true,
    error_message TEXT,
    processing_time_ms INTEGER DEFAULT 0,
    
    -- Timestamps
    occurred_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Retenção
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '90 days')
);

-- Índices
CREATE INDEX idx_transparency_audit_profile_id ON transparency_audit_log(profile_id);
CREATE INDEX idx_transparency_audit_action_type ON transparency_audit_log(action_type);
CREATE INDEX idx_transparency_audit_source_type ON transparency_audit_log(source_type);
CREATE INDEX idx_transparency_audit_occurred_at ON transparency_audit_log(occurred_at DESC);
CREATE INDEX idx_transparency_audit_triggered_by ON transparency_audit_log(triggered_by);
CREATE INDEX idx_transparency_audit_expires_at ON transparency_audit_log(expires_at) WHERE expires_at IS NOT NULL;

-- ============================================
-- TABELA: cache_statistics
-- ============================================

CREATE TABLE cache_statistics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Métricas por fonte
    source_type data_source_type NOT NULL,
    
    -- Contadores
    cache_hits INTEGER DEFAULT 0,
    cache_misses INTEGER DEFAULT 0,
    cache_sets INTEGER DEFAULT 0,
    cache_invalidations INTEGER DEFAULT 0,
    
    -- Custos
    api_calls_saved INTEGER DEFAULT 0,
    cost_savings_usd DECIMAL(10,4) DEFAULT 0.0,
    
    -- Performance
    avg_response_time_ms INTEGER DEFAULT 0,
    total_data_size_bytes BIGINT DEFAULT 0,
    
    -- Período
    period_start TIMESTAMP WITH TIME ZONE NOT NULL,
    period_end TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT cache_statistics_period_check CHECK (period_end > period_start)
);

-- Índices
CREATE INDEX idx_cache_statistics_source_type ON cache_statistics(source_type);
CREATE INDEX idx_cache_statistics_period ON cache_statistics(period_start, period_end);
CREATE INDEX idx_cache_statistics_created_at ON cache_statistics(created_at DESC);

-- ============================================
-- TRIGGERS PARA AUTO-UPDATE
-- ============================================

-- Trigger para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger nas tabelas principais
CREATE TRIGGER update_consolidated_lawyer_profiles_updated_at
    BEFORE UPDATE ON consolidated_lawyer_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_data_source_info_updated_at
    BEFORE UPDATE ON data_source_info
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_lawyer_embeddings_updated_at
    BEFORE UPDATE ON lawyer_embeddings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- FUNÇÕES UTILITÁRIAS
-- ============================================

-- Função para calcular score de qualidade geral
CREATE OR REPLACE FUNCTION calculate_overall_quality_score(profile_id UUID)
RETURNS DECIMAL(4,3) AS $$
DECLARE
    total_weight DECIMAL := 0;
    weighted_score DECIMAL := 0;
    source_rec RECORD;
BEGIN
    -- Pesos por fonte
    FOR source_rec IN
        SELECT 
            source_type,
            confidence_score,
            CASE source_type
                WHEN 'linkedin' THEN 0.3
                WHEN 'academic' THEN 0.25
                WHEN 'escavador' THEN 0.25
                WHEN 'jusbrasil' THEN 0.1
                WHEN 'deep_research' THEN 0.05
                WHEN 'internal' THEN 0.05
                ELSE 0.0
            END AS weight
        FROM data_source_info
        WHERE data_source_info.profile_id = calculate_overall_quality_score.profile_id
    LOOP
        weighted_score := weighted_score + (source_rec.confidence_score * source_rec.weight);
        total_weight := total_weight + source_rec.weight;
    END LOOP;
    
    IF total_weight > 0 THEN
        RETURN weighted_score / total_weight;
    ELSE
        RETURN 0.0;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Função para calcular completude
CREATE OR REPLACE FUNCTION calculate_completeness_score(profile_id UUID)
RETURNS DECIMAL(4,3) AS $$
DECLARE
    total_sources INTEGER := 6; -- Número total de fontes possíveis
    available_sources INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO available_sources
    FROM data_source_info
    WHERE data_source_info.profile_id = calculate_completeness_score.profile_id;
    
    RETURN available_sources::DECIMAL / total_sources;
END;
$$ LANGUAGE plpgsql;

-- Trigger para auto-calcular scores
CREATE OR REPLACE FUNCTION auto_update_quality_scores()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
        UPDATE consolidated_lawyer_profiles
        SET 
            overall_quality_score = calculate_overall_quality_score(NEW.profile_id),
            completeness_score = calculate_completeness_score(NEW.profile_id),
            updated_at = NOW()
        WHERE id = NEW.profile_id;
        
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE consolidated_lawyer_profiles
        SET 
            overall_quality_score = calculate_overall_quality_score(OLD.profile_id),
            completeness_score = calculate_completeness_score(OLD.profile_id),
            updated_at = NOW()
        WHERE id = OLD.profile_id;
        
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger na tabela de fontes
CREATE TRIGGER auto_update_quality_scores_trigger
    AFTER INSERT OR UPDATE OR DELETE ON data_source_info
    FOR EACH ROW
    EXECUTE FUNCTION auto_update_quality_scores();

-- ============================================
-- POLÍTICAS DE LIMPEZA (CLEANUP)
-- ============================================

-- Função para limpeza automática de logs antigos
CREATE OR REPLACE FUNCTION cleanup_old_audit_logs()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM transparency_audit_log
    WHERE expires_at < NOW();
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- ============================================

-- Comentários nas tabelas
COMMENT ON TABLE consolidated_lawyer_profiles IS 'Perfis consolidados de advogados com dados de múltiplas fontes';
COMMENT ON TABLE data_source_info IS 'Informações sobre fontes de dados utilizadas para cada perfil';
COMMENT ON TABLE lawyer_embeddings IS 'Embeddings vetoriais para busca semântica de advogados';
COMMENT ON TABLE data_quality_reports IS 'Relatórios de qualidade e transparência dos dados';
COMMENT ON TABLE transparency_audit_log IS 'Log de auditoria para transparência de coleta e uso de dados';
COMMENT ON TABLE cache_statistics IS 'Estatísticas de performance e economia do sistema de cache';

-- Comentários nas colunas principais
COMMENT ON COLUMN consolidated_lawyer_profiles.overall_quality_score IS 'Score de qualidade geral (0.0-1.0) baseado em todas as fontes';
COMMENT ON COLUMN consolidated_lawyer_profiles.completeness_score IS 'Score de completude (0.0-1.0) baseado no número de fontes disponíveis';
COMMENT ON COLUMN lawyer_embeddings.embedding IS 'Vetor de 768 dimensões para busca semântica';
COMMENT ON COLUMN transparency_audit_log.cost_incurred IS 'Custo em USD da operação realizada';

-- ============================================
-- GRANT DE PERMISSÕES
-- ============================================

-- Assumindo que existe um role 'litgo_api'
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO litgo_api;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO litgo_api;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO litgo_api;

-- ============================================
-- FIM DA MIGRATION
-- ============================================ 
-- Data: 2024-01-15
-- Descrição: Tabelas para armazenar perfis consolidados, embeddings e métricas de qualidade

-- ============================================
-- EXTENSÕES NECESSÁRIAS
-- ============================================

-- Extensão para UUIDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Extensão para vetores (embeddings)
CREATE EXTENSION IF NOT EXISTS vector;

-- Extensão para JSON avançado
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- ============================================
-- ENUMS
-- ============================================

-- Tipos de fontes de dados
CREATE TYPE data_source_type AS ENUM (
    'linkedin',
    'academic', 
    'escavador',
    'jusbrasil',
    'deep_research',
    'internal'
);

-- Níveis de qualidade dos dados
CREATE TYPE data_quality_level AS ENUM (
    'high',
    'medium',
    'low',
    'unknown'
);

-- Status de consolidação
CREATE TYPE consolidation_status AS ENUM (
    'pending',
    'in_progress', 
    'completed',
    'failed',
    'expired'
);

-- ============================================
-- TABELA: consolidated_lawyer_profiles
-- ============================================

CREATE TABLE consolidated_lawyer_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lawyer_id VARCHAR(255) NOT NULL UNIQUE,
    
    -- Dados básicos
    full_name VARCHAR(500) NOT NULL,
    alternative_names JSONB DEFAULT '[]',
    
    -- Perfis por fonte
    linkedin_profile JSONB,
    academic_profile JSONB,
    legal_cases_data JSONB,
    market_insights JSONB,
    platform_metrics JSONB,
    
    -- Scores consolidados
    social_influence_score DECIMAL(5,2) DEFAULT 0.0,
    academic_prestige_score DECIMAL(5,2) DEFAULT 0.0,
    legal_expertise_score DECIMAL(5,2) DEFAULT 0.0,
    market_reputation_score DECIMAL(5,2) DEFAULT 0.0,
    overall_success_probability DECIMAL(5,2) DEFAULT 0.0,
    
    -- Métricas de qualidade
    overall_quality_score DECIMAL(4,3) NOT NULL DEFAULT 0.0,
    completeness_score DECIMAL(4,3) NOT NULL DEFAULT 0.0,
    
    -- Metadados
    consolidation_status consolidation_status DEFAULT 'pending',
    consolidation_version VARCHAR(10) DEFAULT '1.0',
    last_consolidated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Índices
    CONSTRAINT consolidated_lawyer_profiles_lawyer_id_key UNIQUE (lawyer_id),
    CONSTRAINT consolidated_lawyer_profiles_quality_score_check CHECK (overall_quality_score >= 0.0 AND overall_quality_score <= 1.0),
    CONSTRAINT consolidated_lawyer_profiles_completeness_check CHECK (completeness_score >= 0.0 AND completeness_score <= 1.0)
);

-- Índices para performance
CREATE INDEX idx_consolidated_profiles_lawyer_id ON consolidated_lawyer_profiles(lawyer_id);
CREATE INDEX idx_consolidated_profiles_quality_score ON consolidated_lawyer_profiles(overall_quality_score DESC);
CREATE INDEX idx_consolidated_profiles_consolidation_status ON consolidated_lawyer_profiles(consolidation_status);
CREATE INDEX idx_consolidated_profiles_last_consolidated ON consolidated_lawyer_profiles(last_consolidated DESC);
CREATE INDEX idx_consolidated_profiles_linkedin_profile ON consolidated_lawyer_profiles USING GIN (linkedin_profile) WHERE linkedin_profile IS NOT NULL;
CREATE INDEX idx_consolidated_profiles_academic_profile ON consolidated_lawyer_profiles USING GIN (academic_profile) WHERE academic_profile IS NOT NULL;

-- ============================================
-- TABELA: data_source_info
-- ============================================

CREATE TABLE data_source_info (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES consolidated_lawyer_profiles(id) ON DELETE CASCADE,
    
    -- Fonte
    source_type data_source_type NOT NULL,
    
    -- Metadados da fonte
    last_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    quality data_quality_level NOT NULL DEFAULT 'unknown',
    confidence_score DECIMAL(4,3) NOT NULL DEFAULT 0.0,
    fields_available JSONB DEFAULT '[]',
    
    -- Custos e limitações
    cost_per_query DECIMAL(8,4) DEFAULT 0.0,
    rate_limit_per_hour INTEGER DEFAULT 100,
    
    -- Dados específicos da fonte
    source_metadata JSONB DEFAULT '{}',
    raw_data JSONB,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT data_source_info_confidence_check CHECK (confidence_score >= 0.0 AND confidence_score <= 1.0),
    CONSTRAINT data_source_info_unique_per_profile UNIQUE (profile_id, source_type)
);

-- Índices
CREATE INDEX idx_data_source_info_profile_id ON data_source_info(profile_id);
CREATE INDEX idx_data_source_info_source_type ON data_source_info(source_type);
CREATE INDEX idx_data_source_info_quality ON data_source_info(quality);
CREATE INDEX idx_data_source_info_last_updated ON data_source_info(last_updated DESC);
CREATE INDEX idx_data_source_info_raw_data ON data_source_info USING GIN (raw_data) WHERE raw_data IS NOT NULL;

-- ============================================
-- TABELA: lawyer_embeddings
-- ============================================

CREATE TABLE lawyer_embeddings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lawyer_id VARCHAR(255) NOT NULL,
    profile_id UUID REFERENCES consolidated_lawyer_profiles(id) ON DELETE CASCADE,
    
    -- Embedding
    embedding vector(768) NOT NULL,
    embedding_provider VARCHAR(50) NOT NULL, -- 'gemini', 'openai', 'local'
    
    -- Dados de origem
    source_text TEXT NOT NULL,
    source_sources JSONB DEFAULT '[]', -- Fontes que contribuíram para o texto
    
    -- Metadados
    embedding_model VARCHAR(100) NOT NULL,
    embedding_version VARCHAR(20) DEFAULT '1.0',
    confidence_score DECIMAL(4,3) DEFAULT 1.0,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT lawyer_embeddings_confidence_check CHECK (confidence_score >= 0.0 AND confidence_score <= 1.0)
);

-- Índices para embeddings (busca vetorial)
CREATE INDEX idx_lawyer_embeddings_lawyer_id ON lawyer_embeddings(lawyer_id);
CREATE INDEX idx_lawyer_embeddings_embedding_cosine ON lawyer_embeddings USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
CREATE INDEX idx_lawyer_embeddings_embedding_l2 ON lawyer_embeddings USING ivfflat (embedding vector_l2_ops) WITH (lists = 100);
CREATE INDEX idx_lawyer_embeddings_provider ON lawyer_embeddings(embedding_provider);
CREATE INDEX idx_lawyer_embeddings_created_at ON lawyer_embeddings(created_at DESC);

-- ============================================
-- TABELA: data_quality_reports
-- ============================================

CREATE TABLE data_quality_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES consolidated_lawyer_profiles(id) ON DELETE CASCADE,
    
    -- Métricas de qualidade
    total_fields INTEGER NOT NULL DEFAULT 0,
    completed_fields INTEGER NOT NULL DEFAULT 0,
    completeness_percentage DECIMAL(5,2) NOT NULL DEFAULT 0.0,
    
    -- Problemas identificados
    missing_critical_data JSONB DEFAULT '[]',
    data_inconsistencies JSONB DEFAULT '[]',
    
    -- Métricas por fonte
    source_quality_breakdown JSONB DEFAULT '{}',
    
    -- Métricas de freshness
    data_freshness_hours INTEGER DEFAULT 0,
    oldest_data_source VARCHAR(50),
    newest_data_source VARCHAR(50),
    
    -- Recomendações
    quality_recommendations JSONB DEFAULT '[]',
    priority_actions JSONB DEFAULT '[]',
    
    -- Metadados
    report_version VARCHAR(10) DEFAULT '1.0',
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT data_quality_reports_completeness_check CHECK (completeness_percentage >= 0.0 AND completeness_percentage <= 100.0)
);

-- Índices
CREATE INDEX idx_data_quality_reports_profile_id ON data_quality_reports(profile_id);
CREATE INDEX idx_data_quality_reports_completeness ON data_quality_reports(completeness_percentage DESC);
CREATE INDEX idx_data_quality_reports_generated_at ON data_quality_reports(generated_at DESC);

-- ============================================
-- TABELA: transparency_audit_log
-- ============================================

CREATE TABLE transparency_audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID REFERENCES consolidated_lawyer_profiles(id) ON DELETE CASCADE,
    
    -- Ação auditada
    action_type VARCHAR(100) NOT NULL, -- 'data_collection', 'consolidation', 'update', 'access'
    source_type data_source_type,
    
    -- Detalhes da ação
    action_details JSONB DEFAULT '{}',
    data_accessed JSONB DEFAULT '{}',
    
    -- Custos
    cost_incurred DECIMAL(8,4) DEFAULT 0.0,
    cost_currency VARCHAR(3) DEFAULT 'USD',
    
    -- Origem da ação
    triggered_by VARCHAR(255), -- user_id, system, job, etc.
    request_ip VARCHAR(45),
    user_agent TEXT,
    
    -- Resultados
    success BOOLEAN DEFAULT true,
    error_message TEXT,
    processing_time_ms INTEGER DEFAULT 0,
    
    -- Timestamps
    occurred_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Retenção
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '90 days')
);

-- Índices
CREATE INDEX idx_transparency_audit_profile_id ON transparency_audit_log(profile_id);
CREATE INDEX idx_transparency_audit_action_type ON transparency_audit_log(action_type);
CREATE INDEX idx_transparency_audit_source_type ON transparency_audit_log(source_type);
CREATE INDEX idx_transparency_audit_occurred_at ON transparency_audit_log(occurred_at DESC);
CREATE INDEX idx_transparency_audit_triggered_by ON transparency_audit_log(triggered_by);
CREATE INDEX idx_transparency_audit_expires_at ON transparency_audit_log(expires_at) WHERE expires_at IS NOT NULL;

-- ============================================
-- TABELA: cache_statistics
-- ============================================

CREATE TABLE cache_statistics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Métricas por fonte
    source_type data_source_type NOT NULL,
    
    -- Contadores
    cache_hits INTEGER DEFAULT 0,
    cache_misses INTEGER DEFAULT 0,
    cache_sets INTEGER DEFAULT 0,
    cache_invalidations INTEGER DEFAULT 0,
    
    -- Custos
    api_calls_saved INTEGER DEFAULT 0,
    cost_savings_usd DECIMAL(10,4) DEFAULT 0.0,
    
    -- Performance
    avg_response_time_ms INTEGER DEFAULT 0,
    total_data_size_bytes BIGINT DEFAULT 0,
    
    -- Período
    period_start TIMESTAMP WITH TIME ZONE NOT NULL,
    period_end TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT cache_statistics_period_check CHECK (period_end > period_start)
);

-- Índices
CREATE INDEX idx_cache_statistics_source_type ON cache_statistics(source_type);
CREATE INDEX idx_cache_statistics_period ON cache_statistics(period_start, period_end);
CREATE INDEX idx_cache_statistics_created_at ON cache_statistics(created_at DESC);

-- ============================================
-- TRIGGERS PARA AUTO-UPDATE
-- ============================================

-- Trigger para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger nas tabelas principais
CREATE TRIGGER update_consolidated_lawyer_profiles_updated_at
    BEFORE UPDATE ON consolidated_lawyer_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_data_source_info_updated_at
    BEFORE UPDATE ON data_source_info
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_lawyer_embeddings_updated_at
    BEFORE UPDATE ON lawyer_embeddings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- FUNÇÕES UTILITÁRIAS
-- ============================================

-- Função para calcular score de qualidade geral
CREATE OR REPLACE FUNCTION calculate_overall_quality_score(profile_id UUID)
RETURNS DECIMAL(4,3) AS $$
DECLARE
    total_weight DECIMAL := 0;
    weighted_score DECIMAL := 0;
    source_rec RECORD;
BEGIN
    -- Pesos por fonte
    FOR source_rec IN
        SELECT 
            source_type,
            confidence_score,
            CASE source_type
                WHEN 'linkedin' THEN 0.3
                WHEN 'academic' THEN 0.25
                WHEN 'escavador' THEN 0.25
                WHEN 'jusbrasil' THEN 0.1
                WHEN 'deep_research' THEN 0.05
                WHEN 'internal' THEN 0.05
                ELSE 0.0
            END AS weight
        FROM data_source_info
        WHERE data_source_info.profile_id = calculate_overall_quality_score.profile_id
    LOOP
        weighted_score := weighted_score + (source_rec.confidence_score * source_rec.weight);
        total_weight := total_weight + source_rec.weight;
    END LOOP;
    
    IF total_weight > 0 THEN
        RETURN weighted_score / total_weight;
    ELSE
        RETURN 0.0;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Função para calcular completude
CREATE OR REPLACE FUNCTION calculate_completeness_score(profile_id UUID)
RETURNS DECIMAL(4,3) AS $$
DECLARE
    total_sources INTEGER := 6; -- Número total de fontes possíveis
    available_sources INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO available_sources
    FROM data_source_info
    WHERE data_source_info.profile_id = calculate_completeness_score.profile_id;
    
    RETURN available_sources::DECIMAL / total_sources;
END;
$$ LANGUAGE plpgsql;

-- Trigger para auto-calcular scores
CREATE OR REPLACE FUNCTION auto_update_quality_scores()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
        UPDATE consolidated_lawyer_profiles
        SET 
            overall_quality_score = calculate_overall_quality_score(NEW.profile_id),
            completeness_score = calculate_completeness_score(NEW.profile_id),
            updated_at = NOW()
        WHERE id = NEW.profile_id;
        
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE consolidated_lawyer_profiles
        SET 
            overall_quality_score = calculate_overall_quality_score(OLD.profile_id),
            completeness_score = calculate_completeness_score(OLD.profile_id),
            updated_at = NOW()
        WHERE id = OLD.profile_id;
        
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger na tabela de fontes
CREATE TRIGGER auto_update_quality_scores_trigger
    AFTER INSERT OR UPDATE OR DELETE ON data_source_info
    FOR EACH ROW
    EXECUTE FUNCTION auto_update_quality_scores();

-- ============================================
-- POLÍTICAS DE LIMPEZA (CLEANUP)
-- ============================================

-- Função para limpeza automática de logs antigos
CREATE OR REPLACE FUNCTION cleanup_old_audit_logs()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM transparency_audit_log
    WHERE expires_at < NOW();
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- ============================================

-- Comentários nas tabelas
COMMENT ON TABLE consolidated_lawyer_profiles IS 'Perfis consolidados de advogados com dados de múltiplas fontes';
COMMENT ON TABLE data_source_info IS 'Informações sobre fontes de dados utilizadas para cada perfil';
COMMENT ON TABLE lawyer_embeddings IS 'Embeddings vetoriais para busca semântica de advogados';
COMMENT ON TABLE data_quality_reports IS 'Relatórios de qualidade e transparência dos dados';
COMMENT ON TABLE transparency_audit_log IS 'Log de auditoria para transparência de coleta e uso de dados';
COMMENT ON TABLE cache_statistics IS 'Estatísticas de performance e economia do sistema de cache';

-- Comentários nas colunas principais
COMMENT ON COLUMN consolidated_lawyer_profiles.overall_quality_score IS 'Score de qualidade geral (0.0-1.0) baseado em todas as fontes';
COMMENT ON COLUMN consolidated_lawyer_profiles.completeness_score IS 'Score de completude (0.0-1.0) baseado no número de fontes disponíveis';
COMMENT ON COLUMN lawyer_embeddings.embedding IS 'Vetor de 768 dimensões para busca semântica';
COMMENT ON COLUMN transparency_audit_log.cost_incurred IS 'Custo em USD da operação realizada';

-- ============================================
-- GRANT DE PERMISSÕES
-- ============================================

-- Assumindo que existe um role 'litgo_api'
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO litgo_api;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO litgo_api;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO litgo_api;

-- ============================================
-- FIM DA MIGRATION
-- ============================================ 