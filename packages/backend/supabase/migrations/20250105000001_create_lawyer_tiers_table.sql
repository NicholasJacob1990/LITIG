-- Migração: Criar tabela de tiers de advogados e sistema de preços padronizados
-- Data: 2025-01-05
-- Descrição: Implementa o modelo híbrido com valores padrão por tier

-- Criar tabela de tiers (níveis) de advogados
CREATE TABLE IF NOT EXISTS public.lawyer_tiers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tier_name VARCHAR(50) NOT NULL UNIQUE,
    display_name VARCHAR(100) NOT NULL,
    description TEXT,
    consultation_fee DECIMAL(10,2) NOT NULL,
    hourly_rate DECIMAL(10,2) NOT NULL,
    min_experience_years INTEGER DEFAULT 0,
    max_experience_years INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Adicionar coluna tier_id na tabela lawyers
ALTER TABLE public.lawyers 
ADD COLUMN IF NOT EXISTS tier_id UUID REFERENCES public.lawyer_tiers(id);

-- Criar índices para performance
CREATE INDEX IF NOT EXISTS idx_lawyers_tier_id ON public.lawyers(tier_id);
CREATE INDEX IF NOT EXISTS idx_lawyer_tiers_tier_name ON public.lawyer_tiers(tier_name);

-- Inserir tiers padrão
INSERT INTO public.lawyer_tiers (tier_name, display_name, description, consultation_fee, hourly_rate, min_experience_years, max_experience_years)
VALUES 
    ('junior', 'Advogado Júnior', 'Profissionais com até 3 anos de experiência, ideais para casos de baixa complexidade', 150.00, 200.00, 0, 3),
    ('pleno', 'Advogado Pleno', 'Profissionais com 4 a 10 anos de experiência, adequados para casos de média complexidade', 300.00, 400.00, 4, 10),
    ('senior', 'Advogado Sênior', 'Profissionais com mais de 10 anos de experiência, especialistas em casos complexos', 500.00, 600.00, 11, NULL),
    ('especialista', 'Advogado Especialista', 'Profissionais altamente especializados com reconhecimento no mercado', 800.00, 1000.00, 8, NULL)
ON CONFLICT (tier_name) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    description = EXCLUDED.description,
    consultation_fee = EXCLUDED.consultation_fee,
    hourly_rate = EXCLUDED.hourly_rate,
    min_experience_years = EXCLUDED.min_experience_years,
    max_experience_years = EXCLUDED.max_experience_years,
    updated_at = NOW();

-- Função para obter valores padrão do tier
CREATE OR REPLACE FUNCTION get_tier_default_fees(p_tier_id UUID)
RETURNS TABLE(
    consultation_fee DECIMAL,
    hourly_rate DECIMAL,
    tier_name VARCHAR,
    display_name VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        lt.consultation_fee,
        lt.hourly_rate,
        lt.tier_name,
        lt.display_name
    FROM public.lawyer_tiers lt
    WHERE lt.id = p_tier_id;
END;
$$ LANGUAGE plpgsql;

-- Função para buscar advogados por tier
CREATE OR REPLACE FUNCTION get_lawyers_by_tier(p_tier_names TEXT[])
RETURNS TABLE(
    id UUID,
    name TEXT,
    tier_name VARCHAR,
    tier_display_name VARCHAR,
    consultation_fee DECIMAL,
    hourly_rate DECIMAL,
    rating NUMERIC,
    avatar_url TEXT,
    oab_number TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        l.id,
        l.name,
        lt.tier_name,
        lt.display_name,
        lt.consultation_fee,
        lt.hourly_rate,
        l.rating,
        l.avatar_url,
        l.oab_number
    FROM public.lawyers l
    JOIN public.lawyer_tiers lt ON l.tier_id = lt.id
    WHERE lt.tier_name = ANY(p_tier_names)
    AND l.is_available = true
    ORDER BY l.rating DESC;
END;
$$ LANGUAGE plpgsql;

-- Definir tier padrão para todos os advogados existentes
UPDATE public.lawyers 
SET tier_id = (SELECT id FROM public.lawyer_tiers WHERE tier_name = 'pleno')
WHERE tier_id IS NULL;

-- Comentários para documentação
COMMENT ON TABLE public.lawyer_tiers IS 'Tabela de tiers (níveis) de advogados com valores padronizados';
COMMENT ON COLUMN public.lawyer_tiers.tier_name IS 'Nome único do tier (junior, pleno, senior, especialista)';
COMMENT ON COLUMN public.lawyer_tiers.display_name IS 'Nome para exibição na interface';
COMMENT ON COLUMN public.lawyer_tiers.consultation_fee IS 'Valor padrão da consulta para este tier';
COMMENT ON COLUMN public.lawyer_tiers.hourly_rate IS 'Valor padrão por hora para este tier';
COMMENT ON COLUMN public.lawyers.tier_id IS 'Referência ao tier do advogado, define valores padrão';

-- Habilitar RLS
ALTER TABLE public.lawyer_tiers ENABLE ROW LEVEL SECURITY;

-- Política para leitura pública dos tiers
CREATE POLICY "Tiers são públicos para leitura" ON public.lawyer_tiers
    FOR SELECT USING (true);

-- Política para modificação apenas por administradores
CREATE POLICY "Apenas administradores podem modificar tiers" ON public.lawyer_tiers
    FOR ALL USING (false);

-- Grant permissões para as funções
GRANT EXECUTE ON FUNCTION get_tier_default_fees TO authenticated;
GRANT EXECUTE ON FUNCTION get_lawyers_by_tier TO authenticated;
GRANT EXECUTE ON FUNCTION get_tier_default_fees TO service_role;
GRANT EXECUTE ON FUNCTION get_lawyers_by_tier TO service_role; 