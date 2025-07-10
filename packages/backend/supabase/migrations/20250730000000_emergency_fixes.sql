-- Migração de Emergência - Correções Críticas
-- Data: 2025-01-04

-- 1. Garantir que a coluna area seja adicionada à tabela cases (se necessário)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'cases' AND column_name = 'area'
    ) THEN
        ALTER TABLE public.cases ADD COLUMN area TEXT;
        -- Atualizar valores existentes extraindo do ai_analysis
        UPDATE public.cases 
        SET area = ai_analysis->>'area' 
        WHERE ai_analysis->>'area' IS NOT NULL;
    END IF;
END $$;

-- 2. Garantir que a coluna subarea seja adicionada à tabela cases (se necessário)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'cases' AND column_name = 'subarea'
    ) THEN
        ALTER TABLE public.cases ADD COLUMN subarea TEXT;
        -- Atualizar valores existentes extraindo do ai_analysis
        UPDATE public.cases 
        SET subarea = ai_analysis->>'subarea' 
        WHERE ai_analysis->>'subarea' IS NOT NULL;
    END IF;
END $$;

-- 3. Garantir que a coluna summary_ai seja adicionada à tabela cases (se necessário)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'cases' AND column_name = 'summary_ai'
    ) THEN
        ALTER TABLE public.cases ADD COLUMN summary_ai JSONB;
        -- Atualizar valores existentes
        UPDATE public.cases 
        SET summary_ai = ai_analysis 
        WHERE ai_analysis IS NOT NULL;
    END IF;
END $$;

-- 4. Corrigir a função get_user_cases para ser mais robusta
DROP FUNCTION IF EXISTS get_user_cases(uuid);

CREATE OR REPLACE FUNCTION get_user_cases(p_user_id uuid)
RETURNS TABLE (
    id uuid,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    client_id uuid,
    lawyer_id uuid,
    status text,
    title text,
    area text,
    subarea text,
    ai_analysis jsonb,
    summary_ai jsonb,
    unread_messages bigint,
    client_name text,
    lawyer_name text,
    client_avatar text,
    lawyer_avatar text,
    client_type text,
    priority text
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
        -- Priorizar coluna física, fallback para JSON
        COALESCE(c.title, c.ai_analysis->>'summary', c.ai_analysis->>'title') as title,
        COALESCE(c.area, c.ai_analysis->>'area') as area,
        COALESCE(c.subarea, c.ai_analysis->>'subarea') as subarea,
        c.ai_analysis,
        COALESCE(c.summary_ai, c.ai_analysis) as summary_ai,
        (
            SELECT count(*)::bigint 
            FROM public.messages m 
            WHERE m.case_id = c.id 
            AND m.read = false 
            AND m.user_id <> p_user_id
        ) as unread_messages,
        (
            SELECT p.full_name 
            FROM public.profiles p 
            WHERE p.id = c.client_id
        ) as client_name,
        (
            SELECT p.full_name 
            FROM public.profiles p 
            WHERE p.id = c.lawyer_id
        ) as lawyer_name,
        (
            SELECT p.avatar_url
            FROM public.profiles p 
            WHERE p.id = c.client_id
        ) as client_avatar,
        (
            SELECT p.avatar_url
            FROM public.profiles p 
            WHERE p.id = c.lawyer_id
        ) as lawyer_avatar,
        (
            SELECT p.user_type
            FROM public.profiles p 
            WHERE p.id = c.client_id
        ) as client_type,
        COALESCE(c.ai_analysis->>'priority', 'medium') as priority
    FROM
        public.cases as c
    WHERE
        c.client_id = p_user_id OR c.lawyer_id = p_user_id
    ORDER BY
        c.updated_at DESC;
END;
$$;

-- 5. Garantir permissões
GRANT EXECUTE ON FUNCTION get_user_cases(uuid) TO authenticated;

-- 6. Adicionar índices para performance
CREATE INDEX IF NOT EXISTS idx_cases_area ON public.cases(area);
CREATE INDEX IF NOT EXISTS idx_cases_subarea ON public.cases(subarea);
CREATE INDEX IF NOT EXISTS idx_cases_updated_at ON public.cases(updated_at);

-- 7. Comentário da função
COMMENT ON FUNCTION get_user_cases(uuid) IS 'Returns all cases for a user with robust field extraction and fallbacks'; 