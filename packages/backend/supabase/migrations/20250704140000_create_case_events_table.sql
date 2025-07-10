-- Tabela para registrar eventos e andamentos de um caso
CREATE TABLE IF NOT EXISTS case_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    case_id UUID NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
    
    -- Tipo do evento para podermos usar ícones e lógicas diferentes
    event_type TEXT NOT NULL, -- ex: 'document_upload', 'hearing_scheduled', 'lawyer_message', 'fee_payment'
    
    -- Descrição do evento para ser exibida na timeline
    description TEXT NOT NULL,
    
    -- Quem gerou o evento (sistema, cliente, advogado)
    created_by_id UUID REFERENCES auth.users(id),
    
    -- Metadados adicionais (ex: ID do documento, link da audiência)
    metadata JSONB,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE case_events IS 'Registra uma timeline de eventos importantes para cada caso.';
COMMENT ON COLUMN case_events.event_type IS 'Tipo de evento para diferenciação na UI (ícones, cores, etc).';
COMMENT ON COLUMN case_events.created_by_id IS 'ID do usuário (cliente ou advogado) ou sistema que originou o evento.';
COMMENT ON COLUMN case_events.metadata IS 'Dados extras em JSON, como IDs de documentos, links, etc.';

-- Índices para otimização de consultas
CREATE INDEX IF NOT EXISTS idx_case_events_case_id ON case_events(case_id);
CREATE INDEX IF NOT EXISTS idx_case_events_created_at ON case_events(created_at DESC);

-- Habilitar RLS
ALTER TABLE case_events ENABLE ROW LEVEL SECURITY;

-- Política de Segurança: Apenas participantes do caso podem ver os eventos
CREATE POLICY "Case participants can view case events"
ON case_events FOR SELECT
USING (
    case_id IN (
        SELECT id FROM public.cases 
        WHERE client_id = auth.uid() OR lawyer_id = auth.uid()
    )
);

-- Política de Segurança: Apenas participantes podem criar eventos
CREATE POLICY "Case participants can create case events"
ON case_events FOR INSERT
WITH CHECK (
    case_id IN (
        SELECT id FROM public.cases 
        WHERE client_id = auth.uid() OR lawyer_id = auth.uid()
    )
); 