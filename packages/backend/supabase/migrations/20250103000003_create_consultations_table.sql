-- supabase/migrations/20250103000003_create_consultations_table.sql

-- Criar tabela de consultas
CREATE TABLE IF NOT EXISTS public.consultations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id UUID NOT NULL REFERENCES public.cases(id) ON DELETE CASCADE,
    lawyer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    scheduled_at TIMESTAMP WITH TIME ZONE NOT NULL,
    duration_minutes INTEGER DEFAULT 45,
    modality TEXT CHECK (modality IN ('video', 'presencial', 'telefone')) DEFAULT 'video',
    plan_type TEXT DEFAULT 'Por Ato',
    status TEXT CHECK (status IN ('scheduled', 'completed', 'cancelled', 'rescheduled')) DEFAULT 'scheduled',
    notes TEXT,
    meeting_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Criar índices para performance
CREATE INDEX IF NOT EXISTS idx_consultations_case_id ON public.consultations(case_id);
CREATE INDEX IF NOT EXISTS idx_consultations_lawyer_id ON public.consultations(lawyer_id);
CREATE INDEX IF NOT EXISTS idx_consultations_client_id ON public.consultations(client_id);
CREATE INDEX IF NOT EXISTS idx_consultations_scheduled_at ON public.consultations(scheduled_at);
CREATE INDEX IF NOT EXISTS idx_consultations_status ON public.consultations(status);

-- Habilitar RLS
ALTER TABLE public.consultations ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança
-- Usuários podem ver consultas onde são cliente ou advogado
CREATE POLICY "Users can view their own consultations" ON public.consultations
FOR SELECT USING (
    client_id = auth.uid() OR lawyer_id = auth.uid()
);

-- Usuários podem inserir consultas nos casos que participam
CREATE POLICY "Users can insert consultations in their cases" ON public.consultations
FOR INSERT WITH CHECK (
    case_id IN (
        SELECT id FROM public.cases 
        WHERE client_id = auth.uid() OR lawyer_id = auth.uid()
    )
);

-- Usuários podem atualizar consultas onde são cliente ou advogado
CREATE POLICY "Users can update their own consultations" ON public.consultations
FOR UPDATE USING (
    client_id = auth.uid() OR lawyer_id = auth.uid()
);

-- Usuários podem deletar consultas onde são cliente ou advogado
CREATE POLICY "Users can delete their own consultations" ON public.consultations
FOR DELETE USING (
    client_id = auth.uid() OR lawyer_id = auth.uid()
);

-- Trigger para atualizar updated_at automaticamente
CREATE TRIGGER update_consultations_updated_at
    BEFORE UPDATE ON public.consultations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Função para buscar consultas de um caso
CREATE OR REPLACE FUNCTION get_case_consultations(p_case_id UUID)
RETURNS TABLE (
    id UUID,
    case_id UUID,
    lawyer_id UUID,
    client_id UUID,
    scheduled_at TIMESTAMP WITH TIME ZONE,
    duration_minutes INTEGER,
    modality TEXT,
    plan_type TEXT,
    status TEXT,
    notes TEXT,
    meeting_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    lawyer_name TEXT,
    client_name TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        c.case_id,
        c.lawyer_id,
        c.client_id,
        c.scheduled_at,
        c.duration_minutes,
        c.modality,
        c.plan_type,
        c.status,
        c.notes,
        c.meeting_url,
        c.created_at,
        c.updated_at,
        lp.full_name as lawyer_name,
        cp.full_name as client_name
    FROM public.consultations c
    LEFT JOIN public.profiles lp ON c.lawyer_id = lp.id
    LEFT JOIN public.profiles cp ON c.client_id = cp.id
    WHERE c.case_id = p_case_id
    ORDER BY c.scheduled_at DESC;
END;
$$;

-- Inserir dados de exemplo para casos existentes
INSERT INTO public.consultations (case_id, lawyer_id, client_id, scheduled_at, duration_minutes, modality, plan_type, status, notes)
SELECT 
    c.id as case_id,
    c.lawyer_id,
    c.client_id,
    c.created_at + INTERVAL '1 day' as scheduled_at,
    45 as duration_minutes,
    'video' as modality,
    'Plano por Ato' as plan_type,
    'completed' as status,
    'Consulta inicial realizada com sucesso' as notes
FROM public.cases c
WHERE c.lawyer_id IS NOT NULL
ON CONFLICT DO NOTHING;

-- Comentários para documentação
COMMENT ON TABLE public.consultations IS 'Tabela de consultas jurídicas agendadas';
COMMENT ON COLUMN public.consultations.duration_minutes IS 'Duração da consulta em minutos';
COMMENT ON COLUMN public.consultations.modality IS 'Modalidade da consulta: video, presencial ou telefone';
COMMENT ON COLUMN public.consultations.plan_type IS 'Tipo de plano contratado pelo cliente';
COMMENT ON COLUMN public.consultations.meeting_url IS 'URL da reunião para consultas por vídeo'; 