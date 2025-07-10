-- Migration: Habilitar replicação para tabelas de suporte e tarefas
-- Timestamp: 20250711000000

-- =================================================================
-- 1. Habilitar replicação para mensagens de suporte
-- =================================================================

-- Adiciona a tabela à publicação do Supabase Realtime.
-- Se a tabela já estiver na publicação, o comando não fará nada.
ALTER PUBLICATION supabase_realtime ADD TABLE public.support_messages;

-- =================================================================
-- 2. Habilitar replicação para tarefas (preparação futura)
-- =================================================================

ALTER PUBLICATION supabase_realtime ADD TABLE public.tasks;

-- =================================================================
-- 3. Habilitar replicação para tickets (preparação futura)
-- =================================================================

ALTER PUBLICATION supabase_realtime ADD TABLE public.support_tickets; 