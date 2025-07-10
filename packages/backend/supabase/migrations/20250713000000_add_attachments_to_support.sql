-- Migration: Adicionar campos de anexo à tabela de mensagens de suporte
-- Timestamp: 20250713000000

-- =================================================================
-- 1. Adicionar colunas para anexos
-- =================================================================

ALTER TABLE public.support_messages
ADD COLUMN IF NOT EXISTS attachment_url text,
ADD COLUMN IF NOT EXISTS attachment_name text,
ADD COLUMN IF NOT EXISTS attachment_mime_type text;

-- =================================================================
-- 2. Atualizar a política de segurança
-- =================================================================

-- Garantir que a política permita a inserção das novas colunas.
-- A política existente já é permissiva o suficiente, mas revisar é uma boa prática.
-- A política "Participants can manage messages in their tickets" já permite INSERT
-- para todos os campos, então nenhuma alteração é necessária aqui.

COMMENT ON COLUMN public.support_messages.attachment_url IS 'URL pública ou assinada do anexo no Supabase Storage.';
COMMENT ON COLUMN public.support_messages.attachment_name IS 'Nome original do arquivo enviado.';
COMMENT ON COLUMN public.support_messages.attachment_mime_type IS 'Tipo MIME do arquivo para renderização correta (ex: image/png).'; 