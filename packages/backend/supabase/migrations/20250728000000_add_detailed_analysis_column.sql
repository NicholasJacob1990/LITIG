-- Adiciona coluna para análise detalhada na tabela cases
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'cases' AND column_name = 'detailed_analysis'
    ) THEN
        ALTER TABLE cases ADD COLUMN detailed_analysis JSONB;
    END IF;
END $$;

-- Adiciona comentário para documentar o campo
COMMENT ON COLUMN cases.detailed_analysis IS 'Análise jurídica detalhada gerada pelo OpenAI com schema rico';

-- Cria índice para consultas mais rápidas no JSONB
CREATE INDEX IF NOT EXISTS idx_cases_detailed_analysis_gin ON cases USING GIN (detailed_analysis);

-- Adiciona índice para consultas por área principal na análise detalhada
-- Usando btree ao invés de gin para texto simples
CREATE INDEX IF NOT EXISTS idx_cases_detailed_analysis_area ON cases USING btree ((detailed_analysis->'classificacao'->>'area_principal'));

-- Adiciona índice para consultas por viabilidade
-- Usando btree ao invés de gin para texto simples
CREATE INDEX IF NOT EXISTS idx_cases_detailed_analysis_viability ON cases USING btree ((detailed_analysis->'analise_viabilidade'->>'classificacao')); 