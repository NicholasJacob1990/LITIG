-- Corrije a função get_user_cases para extrair dados do JSONB ai_analysis
-- e garantir compatibilidade com as telas que esperam campos de nível superior.

DROP FUNCTION IF EXISTS get_user_cases(uuid);

CREATE OR REPLACE FUNCTION get_user_cases(p_user_id uuid)
RETURNS TABLE (
    id uuid,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    client_id uuid,
    lawyer_id uuid,
    status text,
    -- Campos extraídos do JSON para fácil acesso no frontend
    title text,
    area text,
    subarea text,
    -- O JSON completo ainda é retornado para a análise detalhada
    ai_analysis jsonb,
    unread_messages bigint,
    client_name text,
    lawyer_name text,
    client_avatar text,
    lawyer_avatar text
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
        -- Extrai campos específicos do JSONB para o nível superior da resposta
        c.ai_analysis->>'summary' as title,
        c.ai_analysis->>'area' as area,
        c.ai_analysis->>'subarea' as subarea,
        c.ai_analysis,
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
        ) as lawyer_avatar
    FROM
        public.cases as c
    WHERE
        c.client_id = p_user_id OR c.lawyer_id = p_user_id
    ORDER BY
        c.updated_at DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION get_user_cases(uuid) TO authenticated;

COMMENT ON FUNCTION get_user_cases(uuid) IS 'Returns all cases for a user (client or lawyer), extracting key fields from the ai_analysis JSON for convenience.'; 