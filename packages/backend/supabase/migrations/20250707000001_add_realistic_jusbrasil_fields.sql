-- Migração para adicionar campos REALISTAS da integração Jusbrasil
-- Baseado nas limitações reais da API identificadas

-- Adicionar novos campos realistas à tabela lawyers
ALTER TABLE lawyers ADD COLUMN IF NOT EXISTS estimated_success_rate DECIMAL(5,4) DEFAULT 0.5;
ALTER TABLE lawyers ADD COLUMN IF NOT EXISTS jusbrasil_areas JSONB DEFAULT '{}';
ALTER TABLE lawyers ADD COLUMN IF NOT EXISTS jusbrasil_activity_level VARCHAR(20) DEFAULT 'low';
ALTER TABLE lawyers ADD COLUMN IF NOT EXISTS jusbrasil_specialization DECIMAL(5,4) DEFAULT 0.0;
ALTER TABLE lawyers ADD COLUMN IF NOT EXISTS jusbrasil_data_quality VARCHAR(20) DEFAULT 'unavailable';
ALTER TABLE lawyers ADD COLUMN IF NOT EXISTS jusbrasil_limitations JSONB DEFAULT '[]';
ALTER TABLE lawyers ADD COLUMN IF NOT EXISTS jusbrasil_sync_coverage DECIMAL(5,4) DEFAULT 0.0;

-- Comentários explicativos dos novos campos
COMMENT ON COLUMN lawyers.estimated_success_rate IS 'Taxa de sucesso ESTIMADA baseada em heurísticas (não dados reais)';
COMMENT ON COLUMN lawyers.jusbrasil_areas IS 'Distribuição de processos por área jurídica';
COMMENT ON COLUMN lawyers.jusbrasil_activity_level IS 'Nível de atividade: high, medium, low';
COMMENT ON COLUMN lawyers.jusbrasil_specialization IS 'Score de especialização (0-1) baseado na concentração de áreas';
COMMENT ON COLUMN lawyers.jusbrasil_data_quality IS 'Qualidade dos dados: high, medium, low, unavailable';
COMMENT ON COLUMN lawyers.jusbrasil_limitations IS 'Lista de limitações conhecidas dos dados';
COMMENT ON COLUMN lawyers.jusbrasil_sync_coverage IS 'Cobertura da sincronização (0-1)';

-- Tabela para histórico de sincronização Jusbrasil
CREATE TABLE IF NOT EXISTS jusbrasil_sync_history (
    id SERIAL PRIMARY KEY,
    lawyer_id UUID NOT NULL REFERENCES lawyers(id) ON DELETE CASCADE,
    sync_timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    total_processes INTEGER NOT NULL DEFAULT 0,
    data_quality VARCHAR(20) NOT NULL DEFAULT 'unavailable',
    sync_coverage DECIMAL(5,4) NOT NULL DEFAULT 0.0,
    raw_data JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_jusbrasil_sync_history_lawyer_id ON jusbrasil_sync_history(lawyer_id);
CREATE INDEX IF NOT EXISTS idx_jusbrasil_sync_history_timestamp ON jusbrasil_sync_history(sync_timestamp);
CREATE INDEX IF NOT EXISTS idx_lawyers_jusbrasil_data_quality ON lawyers(jusbrasil_data_quality);
CREATE INDEX IF NOT EXISTS idx_lawyers_last_jusbrasil_sync ON lawyers(last_jusbrasil_sync);

-- Tabela para estatísticas dos jobs de sincronização
CREATE TABLE IF NOT EXISTS jusbrasil_job_stats (
    id SERIAL PRIMARY KEY,
    job_timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    total_lawyers INTEGER NOT NULL DEFAULT 0,
    successful_syncs INTEGER NOT NULL DEFAULT 0,
    failed_syncs INTEGER NOT NULL DEFAULT 0,
    no_data_lawyers INTEGER NOT NULL DEFAULT 0,
    execution_time_seconds INTEGER NOT NULL DEFAULT 0,
    api_errors JSONB DEFAULT '[]',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índice para estatísticas dos jobs
CREATE INDEX IF NOT EXISTS idx_jusbrasil_job_stats_timestamp ON jusbrasil_job_stats(job_timestamp);

-- Função para calcular estatísticas gerais da sincronização
CREATE OR REPLACE FUNCTION get_jusbrasil_sync_stats()
RETURNS TABLE(
    total_lawyers INTEGER,
    synced_lawyers INTEGER,
    high_quality_data INTEGER,
    sync_coverage DECIMAL,
    last_sync TIMESTAMP WITH TIME ZONE,
    avg_processes_per_lawyer DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as total_lawyers,
        COUNT(CASE WHEN last_jusbrasil_sync IS NOT NULL THEN 1 END)::INTEGER as synced_lawyers,
        COUNT(CASE WHEN jusbrasil_data_quality = 'high' THEN 1 END)::INTEGER as high_quality_data,
        (COUNT(CASE WHEN last_jusbrasil_sync IS NOT NULL THEN 1 END)::DECIMAL / 
         NULLIF(COUNT(*)::DECIMAL, 0)) as sync_coverage,
        MAX(last_jusbrasil_sync) as last_sync,
        AVG(total_cases)::DECIMAL as avg_processes_per_lawyer
    FROM lawyers 
    WHERE is_available = true;
END;
$$ LANGUAGE plpgsql;

-- Função para obter advogados que precisam ser sincronizados
CREATE OR REPLACE FUNCTION get_lawyers_needing_sync(batch_size INTEGER DEFAULT 10)
RETURNS TABLE(
    id UUID,
    name TEXT,
    oab_number TEXT,
    last_jusbrasil_sync TIMESTAMP WITH TIME ZONE,
    jusbrasil_data_quality VARCHAR,
    priority_score INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        l.id,
        l.name,
        l.oab_number,
        l.last_jusbrasil_sync,
        l.jusbrasil_data_quality,
        CASE 
            WHEN l.last_jusbrasil_sync IS NULL THEN 100
            WHEN l.jusbrasil_data_quality = 'unavailable' THEN 90
            WHEN l.jusbrasil_data_quality = 'low' THEN 70
            WHEN l.last_jusbrasil_sync < (NOW() - INTERVAL '7 days') THEN 50
            WHEN l.last_jusbrasil_sync < (NOW() - INTERVAL '24 hours') THEN 30
            ELSE 10
        END as priority_score
    FROM lawyers l
    WHERE l.is_available = true
    AND l.oab_number IS NOT NULL 
    AND (
        l.last_jusbrasil_sync IS NULL OR
        l.last_jusbrasil_sync < (NOW() - INTERVAL '24 hours') OR
        l.jusbrasil_data_quality IN ('low', 'unavailable')
    )
    ORDER BY priority_score DESC, l.last_jusbrasil_sync ASC NULLS FIRST
    LIMIT batch_size;
END;
$$ LANGUAGE plpgsql;

-- Política de RLS para histórico (apenas leitura para advogados)
ALTER TABLE jusbrasil_sync_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Advogados podem ver seu próprio histórico de sincronização"
ON jusbrasil_sync_history
FOR SELECT
USING (
    lawyer_id = auth.uid()
);

-- Política de RLS para estatísticas dos jobs (apenas usuários autenticados)
ALTER TABLE jusbrasil_job_stats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuários autenticados podem ver estatísticas dos jobs"
ON jusbrasil_job_stats
FOR SELECT
USING (auth.uid() IS NOT NULL);

-- Inserir dados explicativos sobre limitações (verificar se tabela system_config existe)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'system_config'
    ) THEN
        INSERT INTO system_config (key, value, description) VALUES
        (
            'jusbrasil_api_limitations',
            '["Não categoriza vitórias/derrotas automaticamente", "Processos em segredo de justiça não são retornados", "Processos trabalhistas do autor não retornados (anti-discriminação)", "Apenas processos não atualizados há +4 dias", "Foco em monitoramento empresarial, não performance de advogados"]',
            'Limitações conhecidas da API Jusbrasil'
        ),
        (
            'jusbrasil_data_transparency',
            'true',
            'Transparência total sobre limitações dos dados do Jusbrasil'
        ),
        (
            'jusbrasil_estimation_disclaimer',
            'Os dados de performance são estimativas baseadas em heurísticas e padrões históricos do setor. A API Jusbrasil não fornece dados reais de vitórias/derrotas.',
            'Disclaimer sobre estimativas de performance'
        )
        ON CONFLICT (key) DO UPDATE SET 
            value = EXCLUDED.value,
            description = EXCLUDED.description;
    END IF;
END $$;

-- Comentários finais
COMMENT ON TABLE jusbrasil_sync_history IS 'Histórico de sincronizações realistas do Jusbrasil';
COMMENT ON TABLE jusbrasil_job_stats IS 'Estatísticas dos jobs de sincronização';
COMMENT ON FUNCTION get_jusbrasil_sync_stats() IS 'Retorna estatísticas gerais da sincronização Jusbrasil';
COMMENT ON FUNCTION get_lawyers_needing_sync(INTEGER) IS 'Retorna advogados que precisam ser sincronizados, ordenados por prioridade'; 