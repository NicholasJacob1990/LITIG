-- supabase/migrations/20250103000001_add_detailed_case_fields.sql

-- Adicionar campos detalhados à tabela cases
ALTER TABLE public.cases 
ADD COLUMN IF NOT EXISTS title TEXT,
ADD COLUMN IF NOT EXISTS description TEXT,
ADD COLUMN IF NOT EXISTS subarea TEXT,
ADD COLUMN IF NOT EXISTS priority TEXT CHECK (priority IN ('low', 'medium', 'high')) DEFAULT 'medium',
ADD COLUMN IF NOT EXISTS urgency_hours INTEGER DEFAULT 72,
ADD COLUMN IF NOT EXISTS risk_level TEXT CHECK (risk_level IN ('low', 'medium', 'high')) DEFAULT 'medium',
ADD COLUMN IF NOT EXISTS confidence_score INTEGER DEFAULT 0 CHECK (confidence_score >= 0 AND confidence_score <= 100),
ADD COLUMN IF NOT EXISTS estimated_cost DECIMAL(10,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
ADD COLUMN IF NOT EXISTS next_step TEXT;

-- Criar índices para melhorar performance
CREATE INDEX IF NOT EXISTS idx_cases_priority ON public.cases(priority);
CREATE INDEX IF NOT EXISTS idx_cases_risk_level ON public.cases(risk_level);
CREATE INDEX IF NOT EXISTS idx_cases_updated_at ON public.cases(updated_at);

-- Remover a função existente antes de criar a nova versão
DROP FUNCTION IF EXISTS get_user_cases(uuid);

-- Atualizar a função get_user_cases para retornar os novos campos
CREATE OR REPLACE FUNCTION get_user_cases(p_user_id uuid)
RETURNS TABLE (
    id uuid,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    client_id uuid,
    lawyer_id uuid,
    status text,
    area text,
    subarea text,
    title text,
    description text,
    priority text,
    urgency_hours integer,
    risk_level text,
    confidence_score integer,
    estimated_cost decimal,
    next_step text,
    ai_analysis jsonb,
    unread_messages bigint,
    client_name text,
    client_type text,
    lawyer_name text,
    lawyer_specialty text,
    lawyer_avatar text,
    lawyer_oab text,
    lawyer_rating decimal,
    lawyer_experience_years integer,
    lawyer_success_rate decimal,
    lawyer_phone text,
    lawyer_email text,
    lawyer_location text
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        c.created_at,
        c.updated_at,
        c.client_id,
        c.lawyer_id,
        c.status,
        COALESCE(c.ai_analysis->>'area', 'Área não definida')::text as area,
        c.subarea,
        c.title,
        c.description,
        c.priority,
        c.urgency_hours,
        c.risk_level,
        c.confidence_score,
        c.estimated_cost,
        c.next_step,
        c.ai_analysis,
        (SELECT count(*) FROM public.messages m WHERE m.case_id = c.id AND m.read = false AND m.user_id <> p_user_id) as unread_messages,
        -- Dados do cliente
        cp.full_name as client_name,
        cp.role as client_type,
        -- Dados do advogado
        lp.full_name as lawyer_name,
        lp.role as lawyer_specialty,
        lp.avatar_url as lawyer_avatar,
        '' as lawyer_oab,
        0::decimal as lawyer_rating,
        0 as lawyer_experience_years,
        0::decimal as lawyer_success_rate,
        lp.phone as lawyer_phone,
        '' as lawyer_email,
        '' as lawyer_location
    FROM
        public.cases as c
    LEFT JOIN public.profiles cp ON cp.id = c.client_id
    LEFT JOIN public.profiles lp ON lp.id = c.lawyer_id
    WHERE
        c.client_id = p_user_id OR c.lawyer_id = p_user_id
    ORDER BY
        c.updated_at DESC, c.created_at DESC;
END;
$$;

-- Função para atualizar automaticamente o campo updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Criar trigger para atualizar updated_at automaticamente
DROP TRIGGER IF EXISTS update_cases_updated_at ON public.cases;
CREATE TRIGGER update_cases_updated_at
    BEFORE UPDATE ON public.cases
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Migrar dados existentes do ai_analysis para os novos campos estruturados (apenas se existirem casos)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM public.cases WHERE ai_analysis IS NOT NULL) THEN
        UPDATE public.cases 
        SET 
            title = COALESCE((ai_analysis->>'title')::text, 'Caso sem título'),
            description = COALESCE((ai_analysis->>'description')::text, 'Descrição não disponível'),
            subarea = COALESCE((ai_analysis->>'subarea')::text, 'Não especificado'),
            priority = COALESCE((ai_analysis->>'priority')::text, 'medium'),
            risk_level = COALESCE((ai_analysis->>'risk_level')::text, 'medium'),
            confidence_score = COALESCE((ai_analysis->>'confidence_score')::integer, 0),
            estimated_cost = COALESCE((ai_analysis->>'estimated_cost')::decimal, 0.00),
            next_step = COALESCE((ai_analysis->>'next_step')::text, 'Aguardando análise inicial'),
            updated_at = timezone('utc'::text, now())
        WHERE ai_analysis IS NOT NULL;
    END IF;
END $$;

-- Atualizar casos sem ai_analysis com valores padrão (apenas se existirem casos)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM public.cases) THEN
        UPDATE public.cases 
        SET 
            title = COALESCE(title, 'Caso #' || id::text),
            description = COALESCE(description, 'Descrição não disponível'),
            subarea = COALESCE(subarea, 'Geral'),
            next_step = COALESCE(next_step, 'Aguardando análise inicial'),
            updated_at = timezone('utc'::text, now())
        WHERE title IS NULL OR description IS NULL OR subarea IS NULL OR next_step IS NULL;
    END IF;
END $$;

-- Comentários para documentação
COMMENT ON COLUMN public.cases.title IS 'Título do caso jurídico';
COMMENT ON COLUMN public.cases.description IS 'Descrição detalhada do caso';
COMMENT ON COLUMN public.cases.subarea IS 'Subárea específica do direito';
COMMENT ON COLUMN public.cases.priority IS 'Prioridade do caso: low, medium, high';
COMMENT ON COLUMN public.cases.urgency_hours IS 'Horas até deadline crítico';
COMMENT ON COLUMN public.cases.risk_level IS 'Nível de risco: low, medium, high';
COMMENT ON COLUMN public.cases.confidence_score IS 'Score de confiança da IA (0-100)';
COMMENT ON COLUMN public.cases.estimated_cost IS 'Custo estimado total do caso';
COMMENT ON COLUMN public.cases.next_step IS 'Próximo passo no processo';
COMMENT ON COLUMN public.cases.updated_at IS 'Data da última atualização'; 