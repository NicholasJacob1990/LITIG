-- Migração para adicionar campos da integração HÍBRIDA (Escavador + Jusbrasil)
-- Suporta dados ricos do Escavador e mantém o Jusbrasil como fallback.

-- Adicionar novos campos para dados ricos do Escavador na tabela lawyers
ALTER TABLE lawyers ADD COLUMN IF NOT EXISTS escavador_victories INTEGER DEFAULT 0;
ALTER TABLE lawyers ADD COLUMN IF NOT EXISTS escavador_defeats INTEGER DEFAULT 0;
ALTER TABLE lawyers ADD COLUMN IF NOT EXISTS escavador_ongoing INTEGER DEFAULT 0;
ALTER TABLE lawyers ADD COLUMN IF NOT EXISTS real_success_rate DECIMAL(5,4) DEFAULT 0.0;
ALTER TABLE lawyers ADD COLUMN IF NOT EXISTS escavador_areas_performance JSONB DEFAULT '{}';
ALTER TABLE lawyers ADD COLUMN IF NOT EXISTS escavador_analysis_confidence DECIMAL(5,4) DEFAULT 0.0;
ALTER TABLE lawyers ADD COLUMN IF NOT EXISTS last_escavador_sync TIMESTAMP WITH TIME ZONE;
ALTER TABLE lawyers ADD COLUMN IF NOT EXISTS primary_data_source VARCHAR(20) DEFAULT 'none';

-- Adicionar comentários para clareza
COMMENT ON COLUMN lawyers.real_success_rate IS 'Taxa de sucesso REAL calculada via NLP a partir dos dados do Escavador.';
COMMENT ON COLUMN lawyers.escavador_victories IS 'Contagem de vitórias classificadas pelo NLP do Escavador.';
COMMENT ON COLUMN lawyers.escavador_defeats IS 'Contagem de derrotas classificadas pelo NLP do Escavador.';
COMMENT ON COLUMN lawyers.escavador_areas_performance IS 'Performance detalhada por área jurídica, vinda do Escavador.';
COMMENT ON COLUMN lawyers.escavador_analysis_confidence IS 'Nível de confiança (0-1) da análise de NLP sobre os resultados dos processos.';
COMMENT ON COLUMN lawyers.primary_data_source IS 'Fonte primária usada na última sincronização (escavador, jusbrasil, none).';

-- Tabela para histórico de sincronização HÍBRIDA
CREATE TABLE IF NOT EXISTS hybrid_sync_history (
    id SERIAL PRIMARY KEY,
    lawyer_id UUID NOT NULL REFERENCES lawyers(id) ON DELETE CASCADE,
    sync_timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    primary_source VARCHAR(20) NOT NULL,
    total_processes_escavador INT,
    total_processes_jusbrasil INT,
    final_victories INT,
    final_defeats INT,
    final_success_rate DECIMAL(5,4),
    raw_escavador_data JSONB,
    raw_jusbrasil_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_hybrid_sync_history_lawyer_id ON hybrid_sync_history(lawyer_id);
CREATE INDEX IF NOT EXISTS idx_lawyers_real_success_rate ON lawyers(real_success_rate);
CREATE INDEX IF NOT EXISTS idx_lawyers_last_escavador_sync ON lawyers(last_escavador_sync);

-- Função para obter estatísticas da integração HÍBRIDA
CREATE OR REPLACE FUNCTION get_hybrid_sync_stats()
RETURNS TABLE(
    total_lawyers INTEGER,
    escavador_synced INTEGER,
    jusbrasil_fallback INTEGER,
    high_confidence_analysis INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as total_lawyers,
        COUNT(CASE WHEN primary_data_source = 'escavador' THEN 1 END)::INTEGER as escavador_synced,
        COUNT(CASE WHEN primary_data_source = 'jusbrasil' THEN 1 END)::INTEGER as jusbrasil_fallback,
        COUNT(CASE WHEN escavador_analysis_confidence > 0.7 THEN 1 END)::INTEGER as high_confidence_analysis
    FROM lawyers 
    WHERE status = 'active';
END;
$$ LANGUAGE plpgsql; 