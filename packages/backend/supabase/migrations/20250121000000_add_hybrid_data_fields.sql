-- Migração para adicionar campos de transparência de dados híbridos
-- ===================================================================

-- Adicionar campos de transparência de dados na tabela lawyers
ALTER TABLE lawyers 
ADD COLUMN IF NOT EXISTS data_last_synced TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS data_transparency JSONB,
ADD COLUMN IF NOT EXISTS data_quality_score DECIMAL(3,2) DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS sync_status VARCHAR(20) DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS external_sources TEXT[] DEFAULT '{}';

-- Adicionar campos de transparência de dados na tabela law_firms
ALTER TABLE law_firms 
ADD COLUMN IF NOT EXISTS data_last_synced TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS data_transparency JSONB,
ADD COLUMN IF NOT EXISTS data_quality_score DECIMAL(3,2) DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS sync_status VARCHAR(20) DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS external_sources TEXT[] DEFAULT '{}';

-- Criar índices para otimizar consultas de sincronização
CREATE INDEX IF NOT EXISTS idx_lawyers_data_last_synced ON lawyers(data_last_synced);
CREATE INDEX IF NOT EXISTS idx_lawyers_sync_status ON lawyers(sync_status);
CREATE INDEX IF NOT EXISTS idx_lawyers_data_quality ON lawyers(data_quality_score);

CREATE INDEX IF NOT EXISTS idx_law_firms_data_last_synced ON law_firms(data_last_synced);
CREATE INDEX IF NOT EXISTS idx_law_firms_sync_status ON law_firms(sync_status);
CREATE INDEX IF NOT EXISTS idx_law_firms_data_quality ON law_firms(data_quality_score);

-- Índices GIN para busca em JSONB
CREATE INDEX IF NOT EXISTS idx_lawyers_data_transparency ON lawyers USING gin(data_transparency);
CREATE INDEX IF NOT EXISTS idx_law_firms_data_transparency ON law_firms USING gin(data_transparency);

-- Função para atualizar timestamp de sincronização automaticamente
CREATE OR REPLACE FUNCTION update_sync_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    IF NEW.data_transparency IS NOT NULL AND NEW.data_transparency != OLD.data_transparency THEN
        NEW.data_last_synced = NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers para atualizar timestamps automaticamente
DROP TRIGGER IF EXISTS lawyers_sync_timestamp ON lawyers;
CREATE TRIGGER lawyers_sync_timestamp
    BEFORE UPDATE ON lawyers
    FOR EACH ROW
    EXECUTE FUNCTION update_sync_timestamp();

DROP TRIGGER IF EXISTS law_firms_sync_timestamp ON law_firms;
CREATE TRIGGER law_firms_sync_timestamp
    BEFORE UPDATE ON law_firms
    FOR EACH ROW
    EXECUTE FUNCTION update_sync_timestamp();

-- Tabela para logs de sincronização
CREATE TABLE IF NOT EXISTS sync_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type VARCHAR(20) NOT NULL, -- 'lawyer' ou 'law_firm'
    entity_id UUID NOT NULL,
    sync_type VARCHAR(20) NOT NULL, -- 'full', 'incremental', 'single'
    status VARCHAR(20) NOT NULL, -- 'success', 'error', 'partial'
    sources_used TEXT[] DEFAULT '{}',
    changes_detected JSONB,
    error_message TEXT,
    execution_time_ms INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para tabela de logs
CREATE INDEX IF NOT EXISTS idx_sync_logs_entity ON sync_logs(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_sync_logs_created_at ON sync_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_sync_logs_status ON sync_logs(status);

-- Tabela para métricas de qualidade de dados
CREATE TABLE IF NOT EXISTS data_quality_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type VARCHAR(20) NOT NULL,
    entity_id UUID NOT NULL,
    metric_name VARCHAR(50) NOT NULL,
    metric_value DECIMAL(5,3) NOT NULL,
    source VARCHAR(20) NOT NULL,
    measured_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(entity_type, entity_id, metric_name, source)
);

-- Índices para métricas de qualidade
CREATE INDEX IF NOT EXISTS idx_data_quality_entity ON data_quality_metrics(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_data_quality_metric ON data_quality_metrics(metric_name);
CREATE INDEX IF NOT EXISTS idx_data_quality_source ON data_quality_metrics(source);

-- View para relatórios de sincronização
CREATE OR REPLACE VIEW sync_status_report AS
SELECT 
    'lawyer' as entity_type,
    COUNT(*) as total_entities,
    COUNT(CASE WHEN data_last_synced IS NOT NULL THEN 1 END) as synced_entities,
    COUNT(CASE WHEN data_last_synced > NOW() - INTERVAL '24 hours' THEN 1 END) as recently_synced,
    AVG(data_quality_score) as avg_quality_score,
    COUNT(CASE WHEN sync_status = 'error' THEN 1 END) as error_count
FROM lawyers
UNION ALL
SELECT 
    'law_firm' as entity_type,
    COUNT(*) as total_entities,
    COUNT(CASE WHEN data_last_synced IS NOT NULL THEN 1 END) as synced_entities,
    COUNT(CASE WHEN data_last_synced > NOW() - INTERVAL '24 hours' THEN 1 END) as recently_synced,
    AVG(data_quality_score) as avg_quality_score,
    COUNT(CASE WHEN sync_status = 'error' THEN 1 END) as error_count
FROM law_firms;

-- Função para obter estatísticas de sincronização
CREATE OR REPLACE FUNCTION get_sync_statistics()
RETURNS TABLE(
    entity_type text,
    total_entities bigint,
    synced_entities bigint,
    sync_coverage decimal,
    recently_synced bigint,
    avg_quality_score decimal,
    error_count bigint
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.entity_type::text,
        r.total_entities,
        r.synced_entities,
        CASE 
            WHEN r.total_entities > 0 THEN 
                ROUND((r.synced_entities::decimal / r.total_entities * 100), 2)
            ELSE 0
        END as sync_coverage,
        r.recently_synced,
        ROUND(r.avg_quality_score, 3) as avg_quality_score,
        r.error_count
    FROM sync_status_report r;
END;
$$ LANGUAGE plpgsql;

-- Função para limpar logs antigos (manter apenas últimos 30 dias)
CREATE OR REPLACE FUNCTION cleanup_old_sync_logs()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM sync_logs 
    WHERE created_at < NOW() - INTERVAL '30 days';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    DELETE FROM data_quality_metrics 
    WHERE measured_at < NOW() - INTERVAL '30 days';
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Comentários para documentação
COMMENT ON COLUMN lawyers.data_last_synced IS 'Timestamp da última sincronização de dados externos';
COMMENT ON COLUMN lawyers.data_transparency IS 'Metadados de transparência sobre fontes de dados';
COMMENT ON COLUMN lawyers.data_quality_score IS 'Score de qualidade dos dados (0.0-1.0)';
COMMENT ON COLUMN lawyers.sync_status IS 'Status da sincronização: pending, success, error, partial';
COMMENT ON COLUMN lawyers.external_sources IS 'Lista de fontes externas utilizadas';

COMMENT ON TABLE sync_logs IS 'Logs de sincronização de dados híbridos';
COMMENT ON TABLE data_quality_metrics IS 'Métricas de qualidade dos dados por fonte';
COMMENT ON VIEW sync_status_report IS 'Relatório consolidado de status de sincronização'; 