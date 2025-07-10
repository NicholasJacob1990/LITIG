-- supabase/migrations/20250726000000_create_case_matches_table.sql

-- Tabela para persistir os matches gerados para cada caso
CREATE TABLE IF NOT EXISTS public.case_matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id UUID NOT NULL REFERENCES public.cases(id) ON DELETE CASCADE,
    lawyer_id UUID NOT NULL REFERENCES public.lawyers(id) ON DELETE CASCADE,
    
    -- Scores e dados do momento do match
    fair_score NUMERIC(10, 8) NOT NULL,
    equity_score NUMERIC(10, 8) NOT NULL,
    raw_score NUMERIC(10, 8) NOT NULL,
    
    -- Dados de explicabilidade
    features JSONB,
    breakdown JSONB,
    weights_used JSONB,
    preset_used TEXT,

    -- Metadados
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT unique_case_lawyer_match UNIQUE (case_id, lawyer_id)
);

-- Índices para otimização
CREATE INDEX IF NOT EXISTS idx_case_matches_case_id ON public.case_matches(case_id);
CREATE INDEX IF NOT EXISTS idx_case_matches_lawyer_id ON public.case_matches(lawyer_id);

-- Comentários para documentação
COMMENT ON TABLE public.case_matches IS 'Armazena as recomendações de advogados (matches) geradas para cada caso, permitindo que o usuário as revisite.';
COMMENT ON COLUMN public.case_matches.fair_score IS 'Score final de compatibilidade, incluindo o fator de equidade.';
COMMENT ON COLUMN public.case_matches.breakdown IS 'Contribuição (delta) de cada feature para o score final.';
COMMENT ON COLUMN public.case_matches.preset_used IS 'O preset de pesos utilizado para gerar este match (ex: balanced, fast, expert).'; 