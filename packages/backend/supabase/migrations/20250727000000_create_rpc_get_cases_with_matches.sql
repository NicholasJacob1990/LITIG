-- supabase/migrations/20250727000000_create_rpc_get_cases_with_matches.sql

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
        c.title,
        c.created_at,
        count(cm.id) as match_count
    FROM 
        public.cases c
    JOIN 
        public.case_matches cm ON c.id = cm.case_id
    WHERE 
        c.user_id = auth.uid() -- RLS: Apenas casos do usuário logado
    GROUP BY 
        c.id
    ORDER BY
        c.created_at DESC;
END;
$$ LANGUAGE plpgsql; 