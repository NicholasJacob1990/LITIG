-- Migração: Adicionar campos necessários para o algoritmo de matching
-- Data: 2025-01-25
-- Descrição: Corrige discrepâncias entre código e schema do banco de dados (versão simplificada)

-- Adicionar campos faltantes para o algoritmo de matching
ALTER TABLE public.lawyers 
ADD COLUMN IF NOT EXISTS tags_expertise TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS cases_30d INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS capacidade_mensal INTEGER DEFAULT 10,
ADD COLUMN IF NOT EXISTS geo_latlon POINT,
ADD COLUMN IF NOT EXISTS last_offered_at TIMESTAMP WITH TIME ZONE;

-- Criar índices para performance
CREATE INDEX IF NOT EXISTS idx_lawyers_tags_expertise 
ON public.lawyers USING GIN(tags_expertise);

CREATE INDEX IF NOT EXISTS idx_lawyers_geo_latlon 
ON public.lawyers USING GIST(geo_latlon);

CREATE INDEX IF NOT EXISTS idx_lawyers_cases_30d 
ON public.lawyers(cases_30d);

CREATE INDEX IF NOT EXISTS idx_lawyers_last_offered_at 
ON public.lawyers(last_offered_at);

-- Adicionar comentários para documentação
COMMENT ON COLUMN public.lawyers.tags_expertise IS 'Array de tags de expertise/especialização do advogado';
COMMENT ON COLUMN public.lawyers.cases_30d IS 'Número de casos ativos nos últimos 30 dias';
COMMENT ON COLUMN public.lawyers.capacidade_mensal IS 'Capacidade mensal de casos do advogado';
COMMENT ON COLUMN public.lawyers.geo_latlon IS 'Localização geográfica como ponto (longitude, latitude)';
COMMENT ON COLUMN public.lawyers.last_offered_at IS 'Timestamp da última oferta enviada ao advogado';

-- Validar migração
DO $$
DECLARE
    v_count INTEGER;
BEGIN
    -- Verificar se campos foram criados
    SELECT COUNT(*) INTO v_count
    FROM information_schema.columns
    WHERE table_schema = 'public' 
    AND table_name = 'lawyers'
    AND column_name IN ('tags_expertise', 'cases_30d', 'capacidade_mensal', 'geo_latlon', 'last_offered_at');
    
    IF v_count != 5 THEN
        RAISE EXCEPTION 'Migração falhou: nem todos os campos foram criados';
    END IF;
    
    RAISE NOTICE 'Migração concluída com sucesso: % campos adicionados', v_count;
END $$; 