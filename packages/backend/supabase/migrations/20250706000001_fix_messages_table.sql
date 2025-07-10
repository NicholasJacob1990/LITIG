-- Migration to fix messages table policies and add sender_id
-- This should run after the messages table is created.

-- Adicionar coluna sender_id na tabela messages se não existir
-- Usar um bloco DO para evitar erro se a coluna já existir de alguma forma
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' AND table_name = 'messages' AND column_name = 'sender_id'
  ) THEN
    ALTER TABLE public.messages ADD COLUMN sender_id UUID;
  END IF;
END$$;


-- Adicionar foreign key para sender_id referenciando profiles
-- Adicionar verificação para evitar erro se a constraint já existir
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'fk_messages_sender' AND conrelid = 'public.messages'::regclass
  ) THEN
    ALTER TABLE public.messages ADD CONSTRAINT fk_messages_sender 
      FOREIGN KEY (sender_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
  END IF;
END$$;

-- Atualizar política de mensagens para usar sender_id
DROP POLICY IF EXISTS "Users can view messages from their cases" ON public.messages;
CREATE POLICY "Users can view messages from their cases" ON public.messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.cases c 
      WHERE c.id = messages.case_id 
      AND (c.client_id = auth.uid() OR c.lawyer_id = auth.uid())
    )
  );

DROP POLICY IF EXISTS "Users can insert messages to their cases" ON public.messages;
CREATE POLICY "Users can insert messages to their cases" ON public.messages
  FOR INSERT WITH CHECK (
    sender_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM public.cases c 
      WHERE c.id = messages.case_id 
      AND (c.client_id = auth.uid() OR c.lawyer_id = auth.uid())
    )
  );

-- Criar índices para melhorar performance
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_case_id ON public.messages(case_id); 