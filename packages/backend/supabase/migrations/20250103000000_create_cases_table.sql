-- Migration: Create basic cases table
-- Timestamp: 20250103000000

-- Criar tabela básica de casos
CREATE TABLE IF NOT EXISTS public.cases (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    client_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    lawyer_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    status text DEFAULT 'pending_assignment' CHECK (status IN ('pending_assignment', 'assigned', 'in_progress', 'closed', 'cancelled')),
    ai_analysis jsonb
);

-- Criar índices básicos
CREATE INDEX IF NOT EXISTS idx_cases_client_id ON public.cases(client_id);
CREATE INDEX IF NOT EXISTS idx_cases_lawyer_id ON public.cases(lawyer_id);
CREATE INDEX IF NOT EXISTS idx_cases_status ON public.cases(status);

-- Habilitar RLS
ALTER TABLE public.cases ENABLE ROW LEVEL SECURITY;

-- Políticas básicas de segurança
-- Usuários podem ver casos onde são cliente ou advogado
CREATE POLICY "Users can view their own cases" ON public.cases
FOR SELECT USING (
    client_id = auth.uid() OR lawyer_id = auth.uid()
);

-- Clientes podem inserir novos casos
CREATE POLICY "Clients can create cases" ON public.cases
FOR INSERT WITH CHECK (client_id = auth.uid());

-- Usuários podem atualizar casos onde participam
CREATE POLICY "Users can update their own cases" ON public.cases
FOR UPDATE USING (
    client_id = auth.uid() OR lawyer_id = auth.uid()
);

-- Comentários para documentação
COMMENT ON TABLE public.cases IS 'Tabela principal de casos jurídicos';
COMMENT ON COLUMN public.cases.status IS 'Status do caso: pending_assignment, assigned, in_progress, closed, cancelled';
COMMENT ON COLUMN public.cases.ai_analysis IS 'Análise de IA do caso em formato JSON';
COMMENT ON COLUMN public.cases.client_id IS 'ID do cliente que criou o caso';
COMMENT ON COLUMN public.cases.lawyer_id IS 'ID do advogado atribuído ao caso'; 