-- Migration: Setup pre-hiring chat functionality
-- Timestamp: 20250718000000

-- =================================================================
-- 1. Create table for pre-hiring chat sessions
-- =================================================================
CREATE TABLE IF NOT EXISTS public.pre_hiring_chats (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    client_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    lawyer_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    
    -- Ensure a client-lawyer pair can only have one pre-hiring chat
    UNIQUE(client_id, lawyer_id)
);

COMMENT ON TABLE public.pre_hiring_chats IS 'Stores chat sessions between clients and lawyers before a case is created.';

-- =================================================================
-- 2. Create table for pre-hiring chat messages
-- =================================================================
CREATE TABLE IF NOT EXISTS public.pre_hiring_messages (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    chat_id uuid NOT NULL REFERENCES public.pre_hiring_chats(id) ON DELETE CASCADE,
    sender_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    content text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.pre_hiring_messages IS 'Stores individual messages for pre-hiring chats.';

-- =================================================================
-- 3. Enable Row Level Security (RLS)
-- =================================================================
ALTER TABLE public.pre_hiring_chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pre_hiring_messages ENABLE ROW LEVEL SECURITY;

-- =================================================================
-- 4. Define RLS Policies
-- =================================================================

-- Policy for pre_hiring_chats: Only participants can see or manage the chat session.
CREATE POLICY "Participants can manage their own pre-hiring chats"
ON public.pre_hiring_chats
FOR ALL
USING (auth.uid() = client_id OR auth.uid() = lawyer_id);

-- Policy for pre_hiring_messages: Only participants can see messages in their chat.
CREATE POLICY "Participants can view messages in their pre-hiring chats"
ON public.pre_hiring_messages
FOR SELECT
USING (
    chat_id IN (
        SELECT id FROM public.pre_hiring_chats
        WHERE auth.uid() = client_id OR auth.uid() = lawyer_id
    )
);

-- Policy for pre_hiring_messages: Only participants can send messages.
CREATE POLICY "Participants can send messages in their pre-hiring chats"
ON public.pre_hiring_messages
FOR INSERT
WITH CHECK (
    sender_id = auth.uid() AND
    chat_id IN (
        SELECT id FROM public.pre_hiring_chats
        WHERE auth.uid() = client_id OR auth.uid() = lawyer_id
    )
);

-- =================================================================
-- 5. Enable Realtime for messages
-- =================================================================
ALTER PUBLICATION supabase_realtime ADD TABLE public.pre_hiring_messages;

-- =================================================================
-- 6. Add trigger to update `updated_at` on chat table
-- =================================================================
CREATE OR REPLACE FUNCTION public.update_chat_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.pre_hiring_chats
    SET updated_at = now()
    WHERE id = NEW.chat_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_new_pre_hiring_message
AFTER INSERT ON public.pre_hiring_messages
FOR EACH ROW
EXECUTE FUNCTION public.update_chat_updated_at();

COMMENT ON TRIGGER on_new_pre_hiring_message ON public.pre_hiring_messages
IS 'Updates the updated_at timestamp on the parent chat session when a new message is sent.';

-- =================================================================
-- 7. Create RPC functions
-- =================================================================

-- Function to get or create a pre-hiring chat
CREATE OR REPLACE FUNCTION public.get_or_create_pre_hiring_chat(p_lawyer_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_chat_id uuid;
    v_client_id uuid := auth.uid();
BEGIN
    -- Check if a chat already exists
    SELECT id INTO v_chat_id
    FROM public.pre_hiring_chats
    WHERE client_id = v_client_id AND lawyer_id = p_lawyer_id;

    -- If chat exists, return its ID
    IF v_chat_id IS NOT NULL THEN
        RETURN v_chat_id;
    END IF;

    -- If chat does not exist, create a new one
    INSERT INTO public.pre_hiring_chats (client_id, lawyer_id)
    VALUES (v_client_id, p_lawyer_id)
    RETURNING id INTO v_chat_id;

    RETURN v_chat_id;
END;
$$;

-- Function to get a consolidated list of all user chats
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
        (SELECT COUNT(*) FROM public.messages m WHERE m.case_id = c.id AND m.read = false AND m.sender_id <> auth.uid()) as unread_count,
        c.updated_at
    FROM public.cases c
    WHERE c.client_id = auth.uid() OR c.lawyer_id = auth.uid();

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
        (SELECT COUNT(*) FROM public.pre_hiring_messages m WHERE m.chat_id = phc.id AND m.read = false AND m.sender_id <> auth.uid()) as unread_count,
        phc.updated_at
    FROM public.pre_hiring_chats phc
    WHERE phc.client_id = auth.uid() OR phc.lawyer_id = auth.uid();
END;
$$; 