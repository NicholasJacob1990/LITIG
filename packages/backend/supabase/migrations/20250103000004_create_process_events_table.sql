-- supabase/migrations/20250103000004_create_process_events_table.sql

-- Criar tabela para eventos do processo (linha do tempo)
CREATE TABLE IF NOT EXISTS public.process_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id UUID NOT NULL REFERENCES public.cases(id) ON DELETE CASCADE,
    event_date TIMESTAMP WITH TIME ZONE NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    document_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Criar índices para performance
CREATE INDEX IF NOT EXISTS idx_process_events_case_id ON public.process_events(case_id);
CREATE INDEX IF NOT EXISTS idx_process_events_event_date ON public.process_events(event_date DESC);

-- Habilitar RLS
ALTER TABLE public.process_events ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança
-- Usuários podem ver eventos de processos onde são cliente ou advogado
CREATE POLICY "Users can view process events in their cases" ON public.process_events
FOR SELECT USING (
    case_id IN (
        SELECT id FROM public.cases
        WHERE client_id = auth.uid() OR lawyer_id = auth.uid()
    )
);

-- Advogados podem inserir eventos nos processos que participam
CREATE POLICY "Lawyers can insert process events in their cases" ON public.process_events
FOR INSERT WITH CHECK (
    case_id IN (
        SELECT id FROM public.cases
        WHERE lawyer_id = auth.uid()
    )
);

-- Advogados podem atualizar eventos nos processos que participam
CREATE POLICY "Lawyers can update process events in their cases" ON public.process_events
FOR UPDATE USING (
    case_id IN (
        SELECT id FROM public.cases
        WHERE lawyer_id = auth.uid()
    )
);

-- Trigger para atualizar updated_at automaticamente
CREATE TRIGGER update_process_events_updated_at
    BEFORE UPDATE ON public.process_events
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Função para buscar eventos de um caso
CREATE OR REPLACE FUNCTION get_process_events(p_case_id UUID)
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

-- Inserir dados de exemplo para casos existentes
INSERT INTO public.process_events (case_id, event_date, title, description, document_url)
SELECT 
    c.id as case_id,
    c.created_at + INTERVAL '5 day' as event_date,
    'Petição Inicial Protocolada' as title,
    'A petição inicial foi devidamente protocolada junto ao tribunal competente, dando início formal ao processo.' as description,
    NULL
FROM public.cases c
WHERE c.lawyer_id IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO public.process_events (case_id, event_date, title, description, document_url)
SELECT 
    c.id as case_id,
    c.created_at + INTERVAL '2 day' as event_date,
    'Documentos Recebidos e Analisados' as title,
    'A documentação essencial enviada pelo cliente foi recebida e analisada preliminarmente pelo nosso time.' as description,
    NULL
FROM public.cases c
WHERE c.lawyer_id IS NOT NULL
ON CONFLICT DO NOTHING;


-- Comentários para documentação
COMMENT ON TABLE public.process_events IS 'Tabela para armazenar a linha do tempo e andamentos de um processo judicial.';
COMMENT ON COLUMN public.process_events.event_date IS 'Data em que o evento processual ocorreu.';
COMMENT ON COLUMN public.process_events.title IS 'Título curto do evento (ex: "Audiência Marcada").';
COMMENT ON COLUMN public.process_events.document_url IS 'Link para o documento oficial do evento, se houver.'; 