-- Migration: Adicionar tabelas de escritórios de advocacia (Law Firms)
-- Feature-E: Firm Reputation para matching B2B
-- Data: 2025-01-15

-- 1. Criar tabela law_firms
CREATE TABLE IF NOT EXISTS public.law_firms (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL,
    team_size integer DEFAULT 0,
    main_lat double precision,
    main_lon double precision,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- 2. Criar tabela firm_kpis (KPIs agregados do escritório)
CREATE TABLE IF NOT EXISTS public.firm_kpis (
    firm_id uuid PRIMARY KEY REFERENCES public.law_firms(id) ON DELETE CASCADE,
    success_rate double precision DEFAULT 0.0 CHECK (success_rate >= 0 AND success_rate <= 1),
    nps double precision DEFAULT 0.0 CHECK (nps >= -1 AND nps <= 1),
    reputation_score double precision DEFAULT 0.0 CHECK (reputation_score >= 0 AND reputation_score <= 1),
    diversity_index double precision DEFAULT 0.0 CHECK (diversity_index >= 0 AND diversity_index <= 1),
    active_cases integer DEFAULT 0 CHECK (active_cases >= 0),
    updated_at timestamp with time zone DEFAULT now()
);

-- 3. Adicionar coluna firm_id à tabela lawyers
ALTER TABLE public.lawyers 
ADD COLUMN IF NOT EXISTS firm_id uuid REFERENCES public.law_firms(id) ON DELETE SET NULL;

-- 4. Criar índices para performance
CREATE INDEX IF NOT EXISTS idx_law_firms_name ON public.law_firms (name);
CREATE INDEX IF NOT EXISTS idx_law_firms_location ON public.law_firms (main_lat, main_lon);
CREATE INDEX IF NOT EXISTS idx_law_firms_team_size ON public.law_firms (team_size);

CREATE INDEX IF NOT EXISTS idx_firm_kpis_success_rate ON public.firm_kpis (success_rate);
CREATE INDEX IF NOT EXISTS idx_firm_kpis_reputation_score ON public.firm_kpis (reputation_score);

CREATE INDEX IF NOT EXISTS idx_lawyers_firm_id ON public.lawyers (firm_id);

-- 5. Criar trigger para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Aplicar trigger nas tabelas
CREATE TRIGGER update_law_firms_updated_at 
    BEFORE UPDATE ON public.law_firms 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_firm_kpis_updated_at 
    BEFORE UPDATE ON public.firm_kpis 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 6. Adicionar comentários de documentação
COMMENT ON TABLE public.law_firms IS 'Escritórios de advocacia para matching B2B';
COMMENT ON COLUMN public.law_firms.name IS 'Nome do escritório de advocacia';
COMMENT ON COLUMN public.law_firms.team_size IS 'Número de advogados no escritório';
COMMENT ON COLUMN public.law_firms.main_lat IS 'Latitude da sede principal';
COMMENT ON COLUMN public.law_firms.main_lon IS 'Longitude da sede principal';

COMMENT ON TABLE public.firm_kpis IS 'KPIs agregados do escritório para Feature-E (Firm Reputation)';
COMMENT ON COLUMN public.firm_kpis.success_rate IS 'Taxa de sucesso agregada do escritório (0-1)';
COMMENT ON COLUMN public.firm_kpis.nps IS 'Net Promoter Score do escritório (-1 a 1)';
COMMENT ON COLUMN public.firm_kpis.reputation_score IS 'Score de reputação no mercado (0-1)';
COMMENT ON COLUMN public.firm_kpis.diversity_index IS 'Índice de diversidade corporativa (0-1)';
COMMENT ON COLUMN public.firm_kpis.active_cases IS 'Número de casos ativos do escritório';

COMMENT ON COLUMN public.lawyers.firm_id IS 'ID do escritório ao qual o advogado pertence (opcional)';

-- 7. Habilitar Row Level Security (RLS) para as novas tabelas
ALTER TABLE public.law_firms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.firm_kpis ENABLE ROW LEVEL SECURITY;

-- 8. Criar políticas básicas de RLS (podem ser refinadas posteriormente)
-- Política para law_firms: qualquer usuário autenticado pode ler
CREATE POLICY "law_firms_select_policy" ON public.law_firms
    FOR SELECT USING (auth.role() = 'authenticated');

-- Política para firm_kpis: qualquer usuário autenticado pode ler
CREATE POLICY "firm_kpis_select_policy" ON public.firm_kpis
    FOR SELECT USING (auth.role() = 'authenticated');