-- Migration: Criar gatilho e webhook para notificações de novas mensagens de suporte
-- Timestamp: 20250712000000

-- =================================================================
-- 1. Habilitar a extensão pg_net se ainda não estiver habilitada
-- =================================================================
CREATE EXTENSION IF NOT EXISTS pg_net;

-- =================================================================
-- 2. Criar a função que será acionada pelo gatilho
-- =================================================================
CREATE OR REPLACE FUNCTION public.handle_new_support_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER -- Executar com os privilégios do criador da função
AS $$
DECLARE
    -- URL da Supabase Function (webhook)
    webhook_url text := 'https://gmpwdoctnaqbnodmliso.supabase.co/functions/v1/support-ticket-notifier';
    -- Payload que será enviado. O Supabase já formata o `NEW` record
    -- em um formato que a função consegue entender.
    payload json;
BEGIN
    -- Construir o payload no formato esperado pelo webhook
    payload := json_build_object(
        'type', 'INSERT',
        'table', 'support_messages',
        'schema', 'public',
        'record', row_to_json(NEW),
        'old_record', null
    );

    -- Chamar o webhook de forma assíncrona
    PERFORM net.http_post(
        url := webhook_url,
        body := payload,
        headers := '{"Content-Type": "application/json"}'::jsonb
    );

    RETURN NEW;
END;
$$;

-- =================================================================
-- 3. Criar o gatilho na tabela `support_messages`
-- =================================================================

-- Remover gatilho antigo se existir para garantir idempotência
DROP TRIGGER IF EXISTS on_new_support_message ON public.support_messages;

-- Criar o gatilho que executa a função após cada nova mensagem
CREATE TRIGGER on_new_support_message
AFTER INSERT ON public.support_messages
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_support_message();

COMMENT ON TRIGGER on_new_support_message ON public.support_messages
IS 'Aciona um webhook para enviar uma notificação push após a inserção de uma nova mensagem de suporte.'; 