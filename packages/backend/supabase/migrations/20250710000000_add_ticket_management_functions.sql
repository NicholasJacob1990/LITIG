-- Migration: Add RPC functions for managing support tickets
-- Timestamp: 20250703120000

-- =================================================================
-- 1. Function to Update Ticket Status
-- =================================================================

CREATE OR REPLACE FUNCTION public.update_ticket_status(
    ticket_id uuid,
    new_status support_ticket_status
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER -- Executar com os privilégios do criador da função
AS $$
DECLARE
    is_ticket_creator boolean;
    is_admin boolean; -- Futuramente, verificar se é membro do time de suporte
BEGIN
    -- Verificar se o usuário atual é o criador do ticket
    SELECT EXISTS (
        SELECT 1
        FROM public.support_tickets st
        WHERE st.id = ticket_id AND st.creator_id = auth.uid()
    ) INTO is_ticket_creator;

    -- Placeholder para verificação de admin/suporte
    is_admin := false;

    -- Permitir a alteração apenas se for o criador ou um admin/suporte
    IF is_ticket_creator OR is_admin THEN
        UPDATE public.support_tickets
        SET
            status = new_status,
            -- Se o ticket for fechado, registrar a data de fechamento
            closed_at = CASE
                WHEN new_status = 'closed' THEN now()
                ELSE closed_at
            END
        WHERE id = ticket_id;
    ELSE
        RAISE EXCEPTION 'Authorization failed: You do not have permission to update this ticket status.';
    END IF;
END;
$$;

COMMENT ON FUNCTION public.update_ticket_status(uuid, support_ticket_status)
IS 'Updates the status of a specific support ticket, with authorization checks.';

-- =================================================================
-- 2. Function to Update Ticket Priority
-- =================================================================

CREATE OR REPLACE FUNCTION public.update_ticket_priority(
    ticket_id uuid,
    new_priority support_ticket_priority
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    is_ticket_creator boolean;
    is_admin boolean;
BEGIN
    -- Verificar se o usuário atual é o criador do ticket
    SELECT EXISTS (
        SELECT 1
        FROM public.support_tickets st
        WHERE st.id = ticket_id AND st.creator_id = auth.uid()
    ) INTO is_ticket_creator;

    is_admin := false; -- Placeholder

    IF is_ticket_creator OR is_admin THEN
        UPDATE public.support_tickets
        SET priority = new_priority
        WHERE id = ticket_id;
    ELSE
        RAISE EXCEPTION 'Authorization failed: You do not have permission to update this ticket priority.';
    END IF;
END;
$$;

COMMENT ON FUNCTION public.update_ticket_priority(uuid, support_ticket_priority)
IS 'Updates the priority of a specific support ticket, with authorization checks.';

-- =================================================================
-- 3. Function to Mark Ticket as Read
-- =================================================================

-- Primeiro, adicionar coluna last_viewed_at se não existir
ALTER TABLE public.support_tickets 
ADD COLUMN IF NOT EXISTS last_viewed_at timestamptz;

CREATE OR REPLACE FUNCTION public.mark_ticket_read(
    ticket_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    is_ticket_creator boolean;
    is_admin boolean;
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM public.support_tickets st
        WHERE st.id = ticket_id AND st.creator_id = auth.uid()
    ) INTO is_ticket_creator;

    is_admin := false; -- Placeholder

    IF is_ticket_creator OR is_admin THEN
        UPDATE public.support_tickets
        SET last_viewed_at = now()
        WHERE id = ticket_id;
    END IF;
END;
$$;

COMMENT ON FUNCTION public.mark_ticket_read(uuid)
IS 'Marks a ticket as read by updating the last_viewed_at timestamp.';

-- =================================================================
-- 4. Preparação para Ratings (Avaliações)
-- =================================================================

-- Tabela para armazenar avaliações de tickets
CREATE TABLE IF NOT EXISTS public.support_ratings (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    ticket_id uuid NOT NULL REFERENCES public.support_tickets(id) ON DELETE CASCADE,
    stars smallint NOT NULL CHECK (stars >= 1 AND stars <= 5),
    comment text,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(ticket_id) -- Um ticket só pode ter uma avaliação
);

ALTER TABLE public.support_ratings ENABLE ROW LEVEL SECURITY;

-- Política: apenas o criador do ticket pode avaliar
CREATE POLICY "Users can rate their own tickets"
    ON public.support_ratings FOR ALL
    USING (
        ticket_id IN (
            SELECT id FROM public.support_tickets WHERE creator_id = auth.uid()
        )
    );

-- Função para avaliar ticket
CREATE OR REPLACE FUNCTION public.rate_ticket(
    ticket_id uuid,
    stars smallint,
    comment text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    is_ticket_creator boolean;
    ticket_status_check support_ticket_status;
BEGIN
    -- Verificar se o usuário é o criador do ticket
    SELECT EXISTS (
        SELECT 1
        FROM public.support_tickets st
        WHERE st.id = ticket_id AND st.creator_id = auth.uid()
    ) INTO is_ticket_creator;

    -- Verificar se o ticket está fechado
    SELECT status INTO ticket_status_check
    FROM public.support_tickets
    WHERE id = ticket_id;

    IF NOT is_ticket_creator THEN
        RAISE EXCEPTION 'Authorization failed: You can only rate your own tickets.';
    END IF;

    IF ticket_status_check != 'closed' THEN
        RAISE EXCEPTION 'Validation failed: You can only rate closed tickets.';
    END IF;

    -- Inserir ou atualizar a avaliação
    INSERT INTO public.support_ratings (ticket_id, stars, comment)
    VALUES (ticket_id, stars, comment)
    ON CONFLICT (ticket_id) 
    DO UPDATE SET 
        stars = EXCLUDED.stars,
        comment = EXCLUDED.comment,
        created_at = now();
END;
$$;

COMMENT ON FUNCTION public.rate_ticket(uuid, smallint, text)
IS 'Allows users to rate their own closed support tickets.'; 