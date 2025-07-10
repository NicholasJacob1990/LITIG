-- Migration: Corrigir erros de colunas inexistentes
-- Timestamp: 20250108000000

-- =================================================================
-- 1. Corrigir tabela messages - adicionar sender_id se não existir
-- =================================================================
DO $$ 
BEGIN
    -- Verificar se a tabela messages existe
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'messages'
    ) THEN
        -- Se a tabela existe, verificar se sender_id existe
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' AND table_name = 'messages' AND column_name = 'sender_id'
        ) THEN
            -- Se sender_id não existe, adicionar como alias para user_id
            ALTER TABLE public.messages ADD COLUMN sender_id UUID;
            
            -- Atualizar sender_id com valores de user_id
            UPDATE public.messages SET sender_id = user_id WHERE sender_id IS NULL;
            
            -- Adicionar constraint de foreign key
            ALTER TABLE public.messages 
            ADD CONSTRAINT messages_sender_id_fkey 
            FOREIGN KEY (sender_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        END IF;
    END IF;
END $$;

-- =================================================================
-- 2. Corrigir tabela cases - garantir que não há referência a user_id
-- =================================================================
-- A tabela cases deve usar client_id e lawyer_id, não user_id

-- =================================================================
-- 3. Atualizar função get_user_chat_list para usar sender_id
-- =================================================================
CREATE OR REPLACE FUNCTION public.get_user_chat_list()
RETURNS TABLE (
    chat_id uuid,
    chat_type text,
    other_participant_id uuid,
    other_participant_name text,
    other_participant_avatar text,
    last_message_content text,
    last_message_at timestamptz,
    unread_count bigint,
    updated_at timestamptz
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Verificar se a tabela cases existe
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'cases'
    ) THEN
        -- Chats de Casos
        RETURN QUERY
        SELECT
            c.id as chat_id,
            'case' as chat_type,
            CASE
                WHEN c.client_id = auth.uid() THEN c.lawyer_id
                ELSE c.client_id
            END as other_participant_id,
            CASE
                WHEN c.client_id = auth.uid() THEN (SELECT p.full_name FROM public.profiles p WHERE p.id = c.lawyer_id)
                ELSE (SELECT p.full_name FROM public.profiles p WHERE p.id = c.client_id)
            END as other_participant_name,
            CASE
                WHEN c.client_id = auth.uid() THEN (SELECT p.avatar_url FROM public.profiles p WHERE p.id = c.lawyer_id)
                ELSE (SELECT p.avatar_url FROM public.profiles p WHERE p.id = c.client_id)
            END as other_participant_avatar,
            (SELECT m.content FROM public.messages m WHERE m.case_id = c.id ORDER BY m.created_at DESC LIMIT 1) as last_message_content,
            (SELECT m.created_at FROM public.messages m WHERE m.case_id = c.id ORDER BY m.created_at DESC LIMIT 1) as last_message_at,
            (SELECT COUNT(*) FROM public.messages m WHERE m.case_id = c.id AND m.read = false AND COALESCE(m.sender_id, m.user_id) <> auth.uid()) as unread_count,
            c.updated_at
        FROM public.cases c
        WHERE c.client_id = auth.uid() OR c.lawyer_id = auth.uid();
    END IF;

    -- Verificar se a tabela pre_hiring_chats existe
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'pre_hiring_chats'
    ) THEN
        -- Chats Pré-Contratação
        RETURN QUERY
        SELECT
            phc.id as chat_id,
            'pre_hiring' as chat_type,
            CASE
                WHEN phc.client_id = auth.uid() THEN phc.lawyer_id
                ELSE phc.client_id
            END as other_participant_id,
            CASE
                WHEN phc.client_id = auth.uid() THEN (SELECT p.full_name FROM public.profiles p WHERE p.id = phc.lawyer_id)
                ELSE (SELECT p.full_name FROM public.profiles p WHERE p.id = phc.client_id)
            END as other_participant_name,
            CASE
                WHEN phc.client_id = auth.uid() THEN (SELECT p.avatar_url FROM public.profiles p WHERE p.id = phc.lawyer_id)
                ELSE (SELECT p.avatar_url FROM public.profiles p WHERE p.id = phc.client_id)
            END as other_participant_avatar,
            (SELECT m.content FROM public.pre_hiring_messages m WHERE m.chat_id = phc.id ORDER BY m.created_at DESC LIMIT 1) as last_message_content,
            (SELECT m.created_at FROM public.pre_hiring_messages m WHERE m.chat_id = phc.id ORDER BY m.created_at DESC LIMIT 1) as last_message_at,
            0::bigint as unread_count, -- Pre-hiring messages não têm campo read
            phc.updated_at
        FROM public.pre_hiring_chats phc
        WHERE phc.client_id = auth.uid() OR phc.lawyer_id = auth.uid();
    END IF;
END;
$$;

-- =================================================================
-- 4. Corrigir função get_cases_with_matches_count
-- =================================================================
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

-- =================================================================
-- 5. Trigger para manter sender_id sincronizado com user_id
-- =================================================================
DO $$
BEGIN
    -- Verificar se a tabela messages existe
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'messages'
    ) THEN
        -- Criar função para sincronizar sender_id
        CREATE OR REPLACE FUNCTION public.sync_message_sender_id()
        RETURNS TRIGGER AS $func$
        BEGIN
            -- Sempre manter sender_id igual a user_id
            NEW.sender_id = NEW.user_id;
            RETURN NEW;
        END;
        $func$ LANGUAGE plpgsql;

        -- Criar trigger se não existir
        DROP TRIGGER IF EXISTS sync_sender_id_trigger ON public.messages;
        CREATE TRIGGER sync_sender_id_trigger
            BEFORE INSERT OR UPDATE ON public.messages
            FOR EACH ROW
            EXECUTE FUNCTION public.sync_message_sender_id();
    END IF;
END $$;

-- =================================================================
-- 6. Comentários para documentação
-- =================================================================
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'messages'
    ) THEN
        COMMENT ON COLUMN public.messages.sender_id IS 'ID do remetente da mensagem - mantido sincronizado com user_id para compatibilidade';
        COMMENT ON TRIGGER sync_sender_id_trigger ON public.messages IS 'Mantém sender_id sincronizado com user_id automaticamente';
    END IF;
END $$;
