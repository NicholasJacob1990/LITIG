-- supabase/migrations/20250715100000_create_rpc_get_lawyers_active_case_count.sql

CREATE OR REPLACE FUNCTION get_lawyers_active_case_count(lawyer_ids_list uuid[])
RETURNS TABLE (
    lawyer_id uuid,
    active_cases_count bigint
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id AS lawyer_id,
        COUNT(c.id) AS active_cases_count
    FROM 
        profiles p
    LEFT JOIN 
        cases c ON p.id = c.lawyer_id
    WHERE 
        p.id = ANY(lawyer_ids_list)
        AND c.status NOT IN ('finalizado', 'cancelado', 'closed', 'resolved')
    GROUP BY 
        p.id;
END;
$$; 