-- Migration: Create tables for Agenda, Tasks, and Support Features
-- Timestamp: 20250707000000

-- =================================================================
-- 1. Agenda / Calendar Features
-- =================================================================

-- Tabela para armazenar credenciais OAuth 2.0 para Google/Outlook
CREATE TABLE public.calendar_credentials (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    provider text NOT NULL,
    access_token text NOT NULL, -- Idealmente, criptografado com pgsodium
    refresh_token text,      -- Idealmente, criptografado com pgsodium
    expires_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(user_id, provider)
);

ALTER TABLE public.calendar_credentials ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their own calendar credentials"
    ON public.calendar_credentials FOR ALL
    USING (auth.uid() = user_id);

COMMENT ON TABLE public.calendar_credentials IS 'Stores OAuth credentials for external calendar providers.';
COMMENT ON COLUMN public.calendar_credentials.access_token IS 'Encrypted access token.';
COMMENT ON COLUMN public.calendar_credentials.refresh_token IS 'Encrypted refresh token for offline access.';

-- Enum para os provedores de calendário suportados
CREATE TYPE public.calendar_provider AS ENUM ('google', 'outlook');

-- Enum para o status de um evento
CREATE TYPE public.event_status AS ENUM ('confirmed', 'tentative', 'cancelled');

-- Tabela para armazenar eventos sincronizados
CREATE TABLE public.events (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    external_id text, -- ID do evento no provedor externo (Google/Outlook)
    provider calendar_provider,
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    case_id uuid REFERENCES public.cases(id) ON DELETE SET NULL,
    title text NOT NULL,
    description text,
    start_time timestamptz NOT NULL,
    end_time timestamptz NOT NULL,
    status event_status NOT NULL DEFAULT 'confirmed',
    is_virtual boolean NOT NULL DEFAULT false,
    video_link text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(user_id, provider, external_id)
);

ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own events"
    ON public.events FOR SELECT
    USING (auth.uid() = user_id);
CREATE POLICY "Users can create their own events"
    ON public.events FOR INSERT
    WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own events"
    ON public.events FOR UPDATE
    USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own events"
    ON public.events FOR DELETE
    USING (auth.uid() = user_id);

COMMENT ON TABLE public.events IS 'Stores calendar events, synced from external providers or created locally.';
COMMENT ON COLUMN public.events.external_id IS 'The unique ID from the external calendar provider.';

-- =================================================================
-- 2. Tasks and Deadlines Control
-- =================================================================

-- Enum para o status da tarefa
CREATE TYPE public.task_status AS ENUM ('pending', 'in_progress', 'completed', 'overdue');

-- Tabela para tarefas
CREATE TABLE public.tasks (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    case_id uuid REFERENCES public.cases(id) ON DELETE CASCADE,
    assigned_to uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
    title text NOT NULL,
    description text,
    priority smallint DEFAULT 5, -- Prioridade de 1 (baixa) a 10 (alta)
    due_date timestamptz,
    status task_status NOT NULL DEFAULT 'pending',
    erp_synced boolean NOT NULL DEFAULT false,
    erp_task_id text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    created_by uuid REFERENCES auth.users(id)
);

ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
-- Advogados podem ver tarefas de seus casos. Clientes podem ver tarefas de seus casos.
CREATE POLICY "Users can view tasks related to their cases"
    ON public.tasks FOR SELECT
    USING (
        (
            SELECT role FROM public.profiles WHERE user_id = auth.uid()
        ) = 'lawyer' AND case_id IN (SELECT id FROM public.cases WHERE lawyer_id = auth.uid())
        OR
        (
            SELECT role FROM public.profiles WHERE user_id = auth.uid()
        ) = 'client' AND case_id IN (SELECT id FROM public.cases WHERE client_id = auth.uid())
    );

CREATE POLICY "Users can manage tasks on their assigned cases"
    ON public.tasks FOR ALL
    USING (
        (
            SELECT role FROM public.profiles WHERE user_id = auth.uid()
        ) = 'lawyer' AND case_id IN (SELECT id FROM public.cases WHERE lawyer_id = auth.uid())
    )
    WITH CHECK (created_by = auth.uid());


COMMENT ON TABLE public.tasks IS 'Manages tasks and deadlines for legal cases.';
COMMENT ON COLUMN public.tasks.due_date IS 'Timestamp for when the task is due.';

-- =================================================================
-- 3. Internal Support Team Features
-- =================================================================

-- Enum para status e prioridade do ticket
CREATE TYPE public.support_ticket_status AS ENUM ('open', 'in_progress', 'closed', 'on_hold');
CREATE TYPE public.support_ticket_priority AS ENUM ('low', 'medium', 'high', 'critical');

-- Tabela para tickets de suporte
CREATE TABLE public.support_tickets (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    creator_id uuid NOT NULL REFERENCES auth.users(id),
    case_id uuid REFERENCES public.cases(id),
    subject text NOT NULL,
    status support_ticket_status NOT NULL DEFAULT 'open',
    priority support_ticket_priority NOT NULL DEFAULT 'medium',
    assigned_to_group text, -- Ex: 'controladoria', 'financeiro'
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    closed_at timestamptz
);

ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;
-- Criador do ticket e membros do time de suporte podem ver/gerenciar.
-- (Assumindo uma futura tabela/função `is_support_staff()`)
CREATE POLICY "Users can manage their own support tickets"
    ON public.support_tickets FOR ALL
    USING (auth.uid() = creator_id); -- Simplificado: adicionar lógica de staff aqui.

COMMENT ON TABLE public.support_tickets IS 'Handles internal support requests from legal team members.';

-- Tabela para mensagens dentro de um ticket de suporte
CREATE TABLE public.support_messages (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    ticket_id uuid NOT NULL REFERENCES public.support_tickets(id) ON DELETE CASCADE,
    sender_id uuid NOT NULL REFERENCES auth.users(id),
    content text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.support_messages ENABLE ROW LEVEL SECURITY;
-- Participantes do ticket podem trocar mensagens.
CREATE POLICY "Participants can manage messages in their tickets"
    ON public.support_messages FOR ALL
    USING (
        ticket_id IN (
            SELECT id FROM public.support_tickets WHERE creator_id = auth.uid()
        )
    ); -- Simplificado: adicionar lógica de staff aqui.

COMMENT ON TABLE public.support_messages IS 'Stores messages for a specific support ticket.';

-- =================================================================
-- Functions & Triggers
-- =================================================================

-- Trigger para atualizar o campo `updated_at` automaticamente
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar o trigger nas novas tabelas
CREATE TRIGGER on_calendar_credentials_updated
  BEFORE UPDATE ON public.calendar_credentials
  FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

CREATE TRIGGER on_events_updated
  BEFORE UPDATE ON public.events
  FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

CREATE TRIGGER on_tasks_updated
  BEFORE UPDATE ON public.tasks
  FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

CREATE TRIGGER on_support_tickets_updated
  BEFORE UPDATE ON public.support_tickets
  FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at(); 