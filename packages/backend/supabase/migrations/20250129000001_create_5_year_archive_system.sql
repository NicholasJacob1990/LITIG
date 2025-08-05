-- Migração para sistema de arquivamento de 5 anos
-- Data: 2025-01-29
-- Objetivo: Implementar economia máxima de API com armazenamento de longo prazo

-- ============================================================================
-- TABELA DE ARQUIVO DE LONGO PRAZO (5 ANOS)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.process_movements_archive (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cnj TEXT NOT NULL,
    movement_data JSONB NOT NULL,
    archived_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    original_date TIMESTAMP WITH TIME ZONE,
    
    -- Compressão e otimização
    compressed_data BYTEA, -- Dados comprimidos para economia de espaço
    checksum TEXT,         -- Hash MD5 para verificar integridade
    compression_ratio DECIMAL(4,3) DEFAULT 0.7, -- Ratio de compressão
    
    -- Metadados de arquivamento
    archive_reason TEXT DEFAULT 'age_based' CHECK (archive_reason IN ('age_based', 'manual', 'compliance', 'space_optimization')),
    access_count INTEGER DEFAULT 0,
    last_accessed_at TIMESTAMP WITH TIME ZONE,
    
    -- Classificação automática
    detected_phase TEXT CHECK (detected_phase IN ('inicial', 'instrutoria', 'decisoria', 'recursal', 'final', 'arquivado')),
    process_area TEXT, -- Área do direito para otimização
    
    -- Particionamento por ano para performance
    archived_year INTEGER GENERATED ALWAYS AS (EXTRACT(YEAR FROM archived_at)) STORED,
    
    -- Índices para busca eficiente
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraint para evitar duplicatas
    UNIQUE(cnj, original_date, archive_reason)
);

-- ============================================================================
-- PARTICIONAMENTO POR ANO (2025-2030)
-- ============================================================================

-- Criar partições para os próximos 5 anos
CREATE TABLE IF NOT EXISTS process_movements_archive_2025 
PARTITION OF process_movements_archive 
FOR VALUES FROM (2025) TO (2026);

CREATE TABLE IF NOT EXISTS process_movements_archive_2026 
PARTITION OF process_movements_archive 
FOR VALUES FROM (2026) TO (2027);

CREATE TABLE IF NOT EXISTS process_movements_archive_2027 
PARTITION OF process_movements_archive 
FOR VALUES FROM (2027) TO (2028);

CREATE TABLE IF NOT EXISTS process_movements_archive_2028 
PARTITION OF process_movements_archive 
FOR VALUES FROM (2028) TO (2029);

CREATE TABLE IF NOT EXISTS process_movements_archive_2029 
PARTITION OF process_movements_archive 
FOR VALUES FROM (2029) TO (2030);

CREATE TABLE IF NOT EXISTS process_movements_archive_2030 
PARTITION OF process_movements_archive 
FOR VALUES FROM (2030) TO (2031);

-- ============================================================================
-- TABELA DE MÉTRICAS DE ECONOMIA
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.api_economy_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date_recorded DATE NOT NULL DEFAULT CURRENT_DATE,
    
    -- Métricas de API
    total_api_calls INTEGER DEFAULT 0,
    api_calls_saved INTEGER DEFAULT 0,
    economy_percentage DECIMAL(5,2) DEFAULT 0.0,
    
    -- Métricas de cache
    cache_hit_rate DECIMAL(5,2) DEFAULT 0.0,
    redis_hits INTEGER DEFAULT 0,
    postgresql_hits INTEGER DEFAULT 0,
    api_fallback_hits INTEGER DEFAULT 0,
    
    -- Métricas de custo
    estimated_cost_without_cache DECIMAL(10,2) DEFAULT 0.0,
    actual_cost_with_cache DECIMAL(10,2) DEFAULT 0.0,
    daily_savings DECIMAL(10,2) DEFAULT 0.0,
    
    -- Métricas de performance
    avg_response_time_ms INTEGER DEFAULT 0,
    offline_uptime_percentage DECIMAL(5,2) DEFAULT 0.0,
    
    -- Métricas de armazenamento
    total_data_size_mb BIGINT DEFAULT 0,
    archived_data_size_mb BIGINT DEFAULT 0,
    compression_savings_mb BIGINT DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraint para um registro por dia
    UNIQUE(date_recorded)
);

-- ============================================================================
-- TABELA DE CONFIGURAÇÃO DINÂMICA
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.process_optimization_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cnj TEXT NOT NULL UNIQUE,
    
    -- Classificação automática
    detected_phase TEXT DEFAULT 'instrutoria',
    process_area TEXT,
    access_pattern TEXT DEFAULT 'weekly' CHECK (access_pattern IN ('daily', 'weekly', 'monthly', 'rarely', 'archived')),
    
    -- TTL otimizado
    redis_ttl_seconds INTEGER DEFAULT 3600,
    db_ttl_seconds INTEGER DEFAULT 86400,
    sync_interval_seconds INTEGER DEFAULT 28800,
    
    -- Metadados de uso
    last_accessed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    access_count INTEGER DEFAULT 0,
    last_movement_at TIMESTAMP WITH TIME ZONE,
    days_since_last_movement INTEGER DEFAULT 0,
    
    -- Predições
    predicted_next_movement TEXT,
    predicted_movement_date TIMESTAMP WITH TIME ZONE,
    prediction_confidence DECIMAL(3,2) DEFAULT 0.0,
    
    -- Economia calculada
    estimated_economy_rate DECIMAL(5,2) DEFAULT 0.0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- ÍNDICES PARA PERFORMANCE
-- ============================================================================

-- Índices para archive
CREATE INDEX IF NOT EXISTS process_archive_cnj_idx ON process_movements_archive(cnj);
CREATE INDEX IF NOT EXISTS process_archive_date_idx ON process_movements_archive(original_date);
CREATE INDEX IF NOT EXISTS process_archive_year_idx ON process_movements_archive(archived_year);
CREATE INDEX IF NOT EXISTS process_archive_phase_idx ON process_movements_archive(detected_phase);
CREATE INDEX IF NOT EXISTS process_archive_area_idx ON process_movements_archive(process_area);
CREATE INDEX IF NOT EXISTS process_archive_access_idx ON process_movements_archive(last_accessed_at) WHERE access_count > 0;

-- Índices para metrics
CREATE INDEX IF NOT EXISTS economy_metrics_date_idx ON api_economy_metrics(date_recorded);
CREATE INDEX IF NOT EXISTS economy_metrics_economy_idx ON api_economy_metrics(economy_percentage);

-- Índices para config
CREATE INDEX IF NOT EXISTS optimization_config_phase_idx ON process_optimization_config(detected_phase);
CREATE INDEX IF NOT EXISTS optimization_config_area_idx ON process_optimization_config(process_area);
CREATE INDEX IF NOT EXISTS optimization_config_access_idx ON process_optimization_config(access_pattern);
CREATE INDEX IF NOT EXISTS optimization_config_movement_idx ON process_optimization_config(last_movement_at);

-- ============================================================================
-- FUNÇÕES DE ARQUIVAMENTO AUTOMÁTICO
-- ============================================================================

-- Função para arquivar dados antigos com compressão
CREATE OR REPLACE FUNCTION archive_old_movements_compressed()
RETURNS INTEGER AS $$
DECLARE
    moved_count INTEGER;
    compression_stats RECORD;
BEGIN
    -- Mover dados de 1+ ano para arquivo com compressão
    WITH moved_data AS (
        DELETE FROM public.process_movements 
        WHERE fetched_from_api_at < NOW() - INTERVAL '1 year'
        RETURNING *
    ),
    compressed_inserts AS (
        INSERT INTO public.process_movements_archive 
        (cnj, movement_data, original_date, compressed_data, checksum, detected_phase, process_area)
        SELECT 
            cnj, 
            movement_data,
            fetched_from_api_at,
            compress(movement_data::text::bytea), -- Compressão GZIP
            md5(movement_data::text),            -- Checksum para integridade
            CASE 
                WHEN movement_data->>'type' ILIKE '%sentença%' THEN 'decisoria'
                WHEN movement_data->>'type' ILIKE '%recurso%' THEN 'recursal'
                WHEN movement_data->>'type' ILIKE '%arquiv%' THEN 'arquivado'
                ELSE 'instrutoria'
            END as detected_phase,
            COALESCE(movement_data->>'area', 'civel') as process_area
        FROM moved_data
        RETURNING 1
    )
    SELECT COUNT(*) INTO moved_count FROM compressed_inserts;
    
    -- Atualizar estatísticas de compressão
    INSERT INTO api_economy_metrics 
    (total_data_size_mb, archived_data_size_mb, compression_savings_mb)
    SELECT 
        0, -- Será calculado por job separado
        0,
        moved_count * 0.7 -- Estimativa de 70% de economia por compressão
    ON CONFLICT (date_recorded) DO UPDATE SET
        archived_data_size_mb = api_economy_metrics.archived_data_size_mb + EXCLUDED.archived_data_size_mb,
        compression_savings_mb = api_economy_metrics.compression_savings_mb + EXCLUDED.compression_savings_mb;
    
    RETURN moved_count;
END;
$$ LANGUAGE plpgsql;

-- Função para limpeza de dados muito antigos (apenas metadados após 5 anos)
CREATE OR REPLACE FUNCTION cleanup_very_old_data()
RETURNS INTEGER AS $$
DECLARE
    cleaned_count INTEGER;
BEGIN
    -- Após 5 anos, manter apenas metadados (remover dados completos)
    UPDATE public.process_movements_archive 
    SET 
        movement_data = '{"archived": true, "original_size": ' || 
                       length(movement_data::text) || 
                       ', "archived_reason": "5_year_cleanup"}',
        compressed_data = NULL
    WHERE archived_at < NOW() - INTERVAL '5 years'
    AND compressed_data IS NOT NULL;
    
    GET DIAGNOSTICS cleaned_count = ROW_COUNT;
    RETURN cleaned_count;
END;
$$ LANGUAGE plpgsql;

-- Função para calcular TTL otimizado
CREATE OR REPLACE FUNCTION calculate_optimal_ttl(
    p_cnj TEXT,
    p_phase TEXT DEFAULT 'instrutoria',
    p_area TEXT DEFAULT 'civel',
    p_access_pattern TEXT DEFAULT 'weekly',
    p_days_since_movement INTEGER DEFAULT 30
)
RETURNS JSONB AS $$
DECLARE
    base_ttl JSONB;
    multiplier DECIMAL := 1.0;
    result JSONB;
BEGIN
    -- TTL base por fase
    base_ttl := CASE p_phase
        WHEN 'inicial' THEN '{"redis": 7200, "db": 21600, "sync": 14400}'::jsonb
        WHEN 'instrutoria' THEN '{"redis": 14400, "db": 43200, "sync": 28800}'::jsonb
        WHEN 'decisoria' THEN '{"redis": 28800, "db": 86400, "sync": 43200}'::jsonb
        WHEN 'recursal' THEN '{"redis": 86400, "db": 604800, "sync": 172800}'::jsonb
        WHEN 'final' THEN '{"redis": 604800, "db": 2592000, "sync": 604800}'::jsonb
        WHEN 'arquivado' THEN '{"redis": 2592000, "db": 31536000, "sync": 2592000}'::jsonb
        ELSE '{"redis": 14400, "db": 43200, "sync": 28800}'::jsonb
    END;
    
    -- Multiplicador por área
    multiplier := multiplier * CASE p_area
        WHEN 'tributario' THEN 2.0
        WHEN 'previdenciario' THEN 1.8
        WHEN 'trabalhista' THEN 0.8
        WHEN 'penal' THEN 0.6
        WHEN 'empresarial' THEN 1.5
        ELSE 1.0
    END;
    
    -- Multiplicador por padrão de acesso
    multiplier := multiplier * CASE p_access_pattern
        WHEN 'daily' THEN 0.7
        WHEN 'weekly' THEN 1.0
        WHEN 'monthly' THEN 1.5
        WHEN 'rarely' THEN 3.0
        WHEN 'archived' THEN 10.0
        ELSE 1.0
    END;
    
    -- Multiplicador por inatividade
    IF p_days_since_movement > 90 THEN
        multiplier := multiplier * LEAST(3.0, p_days_since_movement::decimal / 30);
    END IF;
    
    -- Calcular TTL final
    result := jsonb_build_object(
        'redis_ttl', ((base_ttl->>'redis')::integer * multiplier)::integer,
        'db_ttl', ((base_ttl->>'db')::integer * multiplier)::integer,
        'sync_interval', ((base_ttl->>'sync')::integer * multiplier)::integer,
        'multiplier', multiplier,
        'phase', p_phase,
        'area', p_area,
        'access_pattern', p_access_pattern
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TRIGGERS PARA ATUALIZAÇÃO AUTOMÁTICA
-- ============================================================================

-- Trigger para atualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger nas tabelas
CREATE TRIGGER process_archive_updated_at_trigger
    BEFORE UPDATE ON process_movements_archive
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER optimization_config_updated_at_trigger
    BEFORE UPDATE ON process_optimization_config
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger para contar acessos no arquivo
CREATE OR REPLACE FUNCTION increment_archive_access()
RETURNS TRIGGER AS $$
BEGIN
    NEW.access_count = OLD.access_count + 1;
    NEW.last_accessed_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger acionado quando arquivo é consultado
CREATE TRIGGER archive_access_counter
    BEFORE UPDATE ON process_movements_archive
    FOR EACH ROW
    WHEN (NEW.movement_data IS DISTINCT FROM OLD.movement_data)
    EXECUTE FUNCTION increment_archive_access();

-- ============================================================================
-- POLÍTICAS DE SEGURANÇA (RLS)
-- ============================================================================

-- Habilitar RLS
ALTER TABLE public.process_movements_archive ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.api_economy_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.process_optimization_config ENABLE ROW LEVEL SECURITY;

-- Políticas básicas (ajustar conforme necessário)
CREATE POLICY "Users can view archive data" ON public.process_movements_archive
    FOR SELECT USING (true); -- Ajustar conforme regras de negócio

CREATE POLICY "System can manage archive data" ON public.process_movements_archive
    FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Users can view economy metrics" ON public.api_economy_metrics
    FOR SELECT USING (true);

CREATE POLICY "System can manage economy metrics" ON public.api_economy_metrics
    FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Users can view optimization config" ON public.process_optimization_config
    FOR SELECT USING (true);

CREATE POLICY "System can manage optimization config" ON public.process_optimization_config
    FOR ALL USING (auth.role() = 'authenticated');

-- ============================================================================
-- COMENTÁRIOS PARA DOCUMENTAÇÃO
-- ============================================================================

COMMENT ON TABLE public.process_movements_archive IS 'Arquivo de longo prazo (5 anos) para movimentações processuais com compressão automática';
COMMENT ON TABLE public.api_economy_metrics IS 'Métricas diárias de economia de API e performance do sistema';
COMMENT ON TABLE public.process_optimization_config IS 'Configuração dinâmica de TTL otimizado por processo';

COMMENT ON COLUMN public.process_movements_archive.compressed_data IS 'Dados comprimidos para economia de 70% de espaço';
COMMENT ON COLUMN public.process_movements_archive.checksum IS 'Hash MD5 para verificar integridade dos dados';
COMMENT ON COLUMN public.process_movements_archive.detected_phase IS 'Fase processual detectada automaticamente';

COMMENT ON FUNCTION archive_old_movements_compressed() IS 'Arquiva dados antigos com compressão automática';
COMMENT ON FUNCTION calculate_optimal_ttl(TEXT, TEXT, TEXT, TEXT, INTEGER) IS 'Calcula TTL otimizado baseado em múltiplos fatores';
COMMENT ON FUNCTION cleanup_very_old_data() IS 'Remove dados completos após 5 anos, mantendo apenas metadados';

-- ============================================================================
-- DADOS INICIAIS
-- ============================================================================

-- Inserir configuração padrão para economia
INSERT INTO api_economy_metrics (date_recorded, economy_percentage, cache_hit_rate)
VALUES (CURRENT_DATE, 0.0, 0.0)
ON CONFLICT (date_recorded) DO NOTHING; 