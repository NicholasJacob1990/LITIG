-- supabase/migrations/20250103000002_add_fee_structure.sql

-- Adicionar campos de estrutura de honorários à tabela cases
ALTER TABLE public.cases 
ADD COLUMN IF NOT EXISTS consultation_fee DECIMAL(10,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS representation_fee DECIMAL(10,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS fee_type TEXT CHECK (fee_type IN ('fixed', 'success', 'hourly', 'plan', 'mixed')) DEFAULT 'fixed',
ADD COLUMN IF NOT EXISTS success_percentage DECIMAL(5,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS hourly_rate DECIMAL(10,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS plan_type TEXT,
ADD COLUMN IF NOT EXISTS payment_terms TEXT;

-- Criar índices para performance
CREATE INDEX IF NOT EXISTS idx_cases_fee_type ON public.cases(fee_type);

-- Atualizar a função get_user_cases para incluir os novos campos de honorários
DROP FUNCTION IF EXISTS get_user_cases(uuid);

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
    -- Novos campos de honorários
    consultation_fee decimal,
    representation_fee decimal,
    fee_type text,
    success_percentage decimal,
    hourly_rate decimal,
    plan_type text,
    payment_terms text,
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
        c.status::text,
        c.area,
        c.subarea,
        c.title,
        c.description,
        c.priority,
        c.urgency_hours,
        c.risk_level,
        c.confidence_score,
        c.estimated_cost,
        c.next_step,
        -- Novos campos de honorários
        c.consultation_fee,
        c.representation_fee,
        c.fee_type,
        c.success_percentage,
        c.hourly_rate,
        c.plan_type,
        c.payment_terms,
        c.ai_analysis,
        (SELECT count(*) FROM public.messages m WHERE m.case_id = c.id AND m.read = false AND m.user_id <> p_user_id) as unread_messages,
        cp.full_name as client_name,
        cp.role as client_type,
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

-- Atualizar casos existentes com valores de exemplo
UPDATE public.cases 
SET 
    consultation_fee = 350.00,
    representation_fee = 2500.00,
    fee_type = 'mixed',
    payment_terms = 'Consulta à vista, representação 50% antecipado + 50% ao final'
WHERE consultation_fee IS NULL OR consultation_fee = 0;

-- Comentários para documentação
COMMENT ON COLUMN public.cases.consultation_fee IS 'Valor da consulta inicial';
COMMENT ON COLUMN public.cases.representation_fee IS 'Valor dos honorários de representação';
COMMENT ON COLUMN public.cases.fee_type IS 'Tipo de cobrança: fixed, success, hourly, plan, mixed';
COMMENT ON COLUMN public.cases.success_percentage IS 'Percentual de êxito (para fee_type = success)';
COMMENT ON COLUMN public.cases.hourly_rate IS 'Valor por hora (para fee_type = hourly)';
COMMENT ON COLUMN public.cases.plan_type IS 'Tipo de plano (para fee_type = plan)';
COMMENT ON COLUMN public.cases.payment_terms IS 'Condições de pagamento detalhadas'; 