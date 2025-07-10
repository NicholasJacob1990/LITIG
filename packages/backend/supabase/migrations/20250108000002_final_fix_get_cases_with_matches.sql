-- Migração para corrigir definitivamente a função get_cases_with_matches_count
-- Data: 2025-01-08

-- Corrigir função get_cases_with_matches_count para usar client_id e lawyer_id em vez de user_id
CREATE OR REPLACE FUNCTION public.get_cases_with_matches_count()
RETURNS TABLE (
    id UUID,
    title TEXT,
    created_at TIMESTAMPTZ,
    match_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        COALESCE(c.title, c.ai_analysis->>'title', 'Caso sem título') as title,
        c.created_at,
        COALESCE(count(cm.id), 0) as match_count
    FROM 
        public.cases c
    LEFT JOIN 
        public.case_matches cm ON c.id = cm.case_id
    WHERE 
        c.client_id = auth.uid() OR c.lawyer_id = auth.uid() -- RLS: Apenas casos do usuário logado
    GROUP BY 
        c.id, c.title, c.ai_analysis, c.created_at
    ORDER BY
        c.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Garantir permissões corretas
GRANT EXECUTE ON FUNCTION public.get_cases_with_matches_count() TO authenticated;

-- Comentário para documentação
COMMENT ON FUNCTION public.get_cases_with_matches_count() IS 'Retorna casos com contagem de matches para o usuário logado (cliente ou advogado)'; 