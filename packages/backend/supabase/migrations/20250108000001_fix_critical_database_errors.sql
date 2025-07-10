-- Migration: Corrigir todos os erros críticos do banco de dados
-- Timestamp: 20250108000001

-- =================================================================
-- 1. Corrigir erro de tipo na função get_user_cases
-- =================================================================

-- O erro indica que a coluna 9 retorna VARCHAR(255) mas espera TEXT
-- Vamos garantir que todas as colunas de texto sejam do tipo TEXT

DO $$ 
BEGIN
    -- Alterar coluna title para TEXT se for VARCHAR
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'cases' 
        AND column_name = 'title' 
        AND data_type = 'character varying'
    ) THEN
        ALTER TABLE public.cases ALTER COLUMN title TYPE TEXT;
    END IF;
    
    -- Alterar coluna area para TEXT se for VARCHAR
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'cases' 
        AND column_name = 'area' 
        AND data_type = 'character varying'
    ) THEN
        ALTER TABLE public.cases ALTER COLUMN area TYPE TEXT;
    END IF;
    
    -- Alterar coluna description para TEXT se for VARCHAR
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'cases' 
        AND column_name = 'description' 
        AND data_type = 'character varying'
    ) THEN
        ALTER TABLE public.cases ALTER COLUMN description TYPE TEXT;
    END IF;
END $$;

-- =================================================================
-- 2. Corrigir relacionamento documents -> uploaded_by
-- =================================================================

-- Verificar se a tabela documents usa auth.users ou profiles
DO $$ 
BEGIN
    -- Se a tabela documents existe e usa auth.users, vamos alterar para profiles
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'documents' AND table_schema = 'public'
    ) THEN
        -- Verificar se a FK aponta para auth.users
        IF EXISTS (
            SELECT 1 FROM information_schema.table_constraints tc
            JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
            JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name = tc.constraint_name
            WHERE tc.table_name = 'documents' 
            AND kcu.column_name = 'uploaded_by'
            AND ccu.table_name = 'users'
        ) THEN
            -- Remover constraint existente
            ALTER TABLE public.documents DROP CONSTRAINT IF EXISTS documents_uploaded_by_fkey;
            
            -- Criar nova constraint apontando para profiles
            ALTER TABLE public.documents 
            ADD CONSTRAINT documents_uploaded_by_fkey 
            FOREIGN KEY (uploaded_by) REFERENCES public.profiles(id) ON DELETE SET NULL;
        END IF;
    END IF;
END $$;

-- =================================================================
-- 3. Corrigir relacionamento cases -> profiles
-- =================================================================

-- Verificar se as FKs de cases apontam para profiles corretamente
DO $$ 
BEGIN
    -- Verificar client_id FK
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
        JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name = tc.constraint_name
        WHERE tc.table_name = 'cases' 
        AND kcu.column_name = 'client_id'
        AND ccu.table_name = 'profiles'
    ) THEN
        -- Remover constraint antiga se existir
        ALTER TABLE public.cases DROP CONSTRAINT IF EXISTS cases_client_id_fkey;
        
        -- Criar nova constraint
        ALTER TABLE public.cases 
        ADD CONSTRAINT cases_client_id_fkey 
        FOREIGN KEY (client_id) REFERENCES public.profiles(id) ON DELETE SET NULL;
    END IF;
    
    -- Verificar lawyer_id FK
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
        JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name = tc.constraint_name
        WHERE tc.table_name = 'cases' 
        AND kcu.column_name = 'lawyer_id'
        AND ccu.table_name = 'profiles'
    ) THEN
        -- Remover constraint antiga se existir
        ALTER TABLE public.cases DROP CONSTRAINT IF EXISTS cases_lawyer_id_fkey;
        
        -- Criar nova constraint
        ALTER TABLE public.cases 
        ADD CONSTRAINT cases_lawyer_id_fkey 
        FOREIGN KEY (lawyer_id) REFERENCES public.profiles(id) ON DELETE SET NULL;
    END IF;
END $$;

-- =================================================================
-- 4. Recriar função get_user_cases corrigida
-- =================================================================

DROP FUNCTION IF EXISTS public.get_user_cases(uuid);

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
        COALESCE(c.updated_at, c.created_at) as updated_at,
        c.client_id,
        c.lawyer_id,
        COALESCE(c.status, 'pending')::text,
        COALESCE(c.title, c.ai_analysis->>'title', 'Caso sem título')::text,
        COALESCE(c.area, c.ai_analysis->>'area', 'Área não definida')::text,
        COALESCE(c.subarea, c.ai_analysis->>'subarea', 'Subárea não definida')::text,
        COALESCE(c.ai_analysis, '{}'::jsonb),
        (
            SELECT count(*)::bigint 
            FROM public.messages m 
            WHERE m.case_id = c.id 
            AND m.read = false 
            AND m.user_id <> p_user_id
        ) as unread_messages,
        COALESCE(cp.full_name, 'Cliente não identificado')::text as client_name,
        COALESCE(lp.full_name, 'Advogado não atribuído')::text as lawyer_name,
        cp.avatar_url::text as client_avatar,
        lp.avatar_url::text as lawyer_avatar
    FROM
        public.cases c
    LEFT JOIN public.profiles cp ON c.client_id = cp.id
    LEFT JOIN public.profiles lp ON c.lawyer_id = lp.id
    WHERE
        c.client_id = p_user_id OR c.lawyer_id = p_user_id
    ORDER BY
        COALESCE(c.updated_at, c.created_at) DESC;
END;
$$;

-- =================================================================
-- 5. Garantir que as funções RPC existam
-- =================================================================

-- Função get_process_events (já existe nas migrações)
CREATE OR REPLACE FUNCTION public.get_process_events(p_case_id UUID)
RETURNS TABLE (
    id UUID,
    event_date TIMESTAMP WITH TIME ZONE,
    title TEXT,
    description TEXT,
    document_url TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        pe.id,
        pe.event_date,
        pe.title,
        pe.description,
        pe.document_url
    FROM public.process_events pe
    WHERE pe.case_id = p_case_id
    ORDER BY pe.event_date DESC;
END;
$$;

-- Função get_case_consultations (já existe nas migrações)
CREATE OR REPLACE FUNCTION public.get_case_consultations(p_case_id UUID)
RETURNS TABLE (
    id UUID,
    case_id UUID,
    lawyer_id UUID,
    client_id UUID,
    scheduled_at TIMESTAMP WITH TIME ZONE,
    duration_minutes INTEGER,
    modality TEXT,
    plan_type TEXT,
    status TEXT,
    notes TEXT,
    meeting_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    lawyer_name TEXT,
    client_name TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        c.case_id,
        c.lawyer_id,
        c.client_id,
        c.scheduled_at,
        c.duration_minutes,
        c.modality,
        c.plan_type,
        c.status,
        c.notes,
        c.meeting_url,
        c.created_at,
        c.updated_at,
        lp.full_name as lawyer_name,
        cp.full_name as client_name
    FROM public.consultations c
    LEFT JOIN public.profiles lp ON c.lawyer_id = lp.id
    LEFT JOIN public.profiles cp ON c.client_id = cp.id
    WHERE c.case_id = p_case_id
    ORDER BY c.scheduled_at DESC;
END;
$$;

-- =================================================================
-- 6. Garantir permissões
-- =================================================================

GRANT EXECUTE ON FUNCTION public.get_user_cases(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_process_events(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_case_consultations(uuid) TO authenticated;

-- =================================================================
-- 7. Comentários para documentação
-- =================================================================

COMMENT ON FUNCTION public.get_user_cases(uuid) IS 'Retorna casos do usuário com fallbacks para evitar erros de tipo';
COMMENT ON FUNCTION public.get_process_events(uuid) IS 'Retorna eventos de processo de um caso específico';
COMMENT ON FUNCTION public.get_case_consultations(uuid) IS 'Retorna consultas de um caso específico'; 