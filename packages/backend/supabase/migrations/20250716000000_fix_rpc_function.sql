-- Migration: Fix get_user_cases RPC function to match actual cases table structure
-- Timestamp: 20250716000000

-- Drop the existing function that references non-existent columns
DROP FUNCTION IF EXISTS get_user_cases(uuid);

-- Create corrected RPC function aligned with actual cases table
CREATE OR REPLACE FUNCTION get_user_cases(p_user_id uuid)
RETURNS TABLE (
    id uuid,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    client_id uuid,
    lawyer_id uuid,
    status text,
    ai_analysis jsonb,
    unread_messages bigint,
    client_name text,
    lawyer_name text
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
            WHERE p.user_id = c.client_id
        ) as client_name,
        (
            SELECT p.full_name 
            FROM public.profiles p 
            WHERE p.user_id = c.lawyer_id
        ) as lawyer_name
    FROM
        public.cases as c
    WHERE
        c.client_id = p_user_id OR c.lawyer_id = p_user_id
    ORDER BY
        c.updated_at DESC;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_user_cases(uuid) TO authenticated;

COMMENT ON FUNCTION get_user_cases(uuid) IS 'Returns all cases for a user (client or lawyer) with metadata'; 