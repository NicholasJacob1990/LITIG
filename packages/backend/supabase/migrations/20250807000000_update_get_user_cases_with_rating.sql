-- Migration: Atualizar a função get_user_cases para incluir rating e review_count do advogado
-- Timestamp: 20250807000000

-- Primeiro, remove a função existente para garantir uma substituição limpa
DROP FUNCTION IF EXISTS public.get_user_cases(uuid);

-- Recria a função com os novos campos
CREATE OR REPLACE FUNCTION public.get_user_cases(p_user_id uuid)
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
    unread_messages bigint,
    client_name text,
    lawyer_name text,
    client_avatar text,
    lawyer_avatar text,
    -- NOVOS CAMPOS ADICIONADOS
    lawyer_rating numeric,
    lawyer_review_count integer
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
        (SELECT p.full_name FROM public.profiles p WHERE p.id = c.client_id) as client_name,
        -- Dados do advogado, incluindo os novos campos de avaliação
        lawyer_profile.full_name as lawyer_name,
        lawyer_profile.avatar_url as lawyer_avatar,
        lawyer_profile.rating as lawyer_rating,
        lawyer_profile.review_count as lawyer_review_count
    FROM
        public.cases c
    -- Junta com o perfil do advogado para obter os detalhes
    LEFT JOIN
        public.profiles lawyer_profile ON c.lawyer_id = lawyer_profile.id
    WHERE
        c.client_id = p_user_id OR c.lawyer_id = p_user_id
    ORDER BY
        c.created_at DESC;
END;
$$;

COMMENT ON FUNCTION public.get_user_cases(uuid) IS 'Retorna os casos de um usuário (cliente ou advogado) com informações enriquecidas, incluindo nome, avatar e, agora, a avaliação do advogado.'; 