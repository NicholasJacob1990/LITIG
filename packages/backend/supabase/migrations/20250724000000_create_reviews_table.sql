-- Migration: Implementar Fase 9 - Sistema de Reviews/Avaliações
-- Timestamp: 20250721000000
-- Objetivo: Separar feedback subjetivo (R) do KPI objetivo (T) do Jusbrasil

-- =================================================================
-- 1. Enum para resultado percebido pelo cliente
-- =================================================================
CREATE TYPE public.case_outcome AS ENUM ('won', 'lost', 'settled', 'ongoing');

-- =================================================================
-- 2. Tabela de Reviews
-- =================================================================
CREATE TABLE public.reviews (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    contract_id uuid NOT NULL REFERENCES public.contracts(id) ON DELETE CASCADE,
    lawyer_id uuid NOT NULL REFERENCES public.lawyers(id) ON DELETE CASCADE,
    client_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    
    -- Avaliação obrigatória (1-5 estrelas)
    rating integer NOT NULL CHECK (rating BETWEEN 1 AND 5),
    
    -- Comentário opcional
    comment text,
    
    -- Resultado percebido pelo cliente (opcional)
    outcome case_outcome,
    
    -- Aspectos específicos da avaliação (opcional)
    communication_rating integer CHECK (communication_rating BETWEEN 1 AND 5),
    expertise_rating integer CHECK (expertise_rating BETWEEN 1 AND 5),
    timeliness_rating integer CHECK (timeliness_rating BETWEEN 1 AND 5),
    
    -- Recomendaria o advogado? (opcional)
    would_recommend boolean,
    
    -- Metadados
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    
    -- Garantir que cada contrato só pode ter uma avaliação
    UNIQUE(contract_id)
);

-- =================================================================
-- 3. Índices para performance
-- =================================================================
CREATE INDEX idx_reviews_lawyer_id ON public.reviews(lawyer_id);
CREATE INDEX idx_reviews_client_id ON public.reviews(client_id);
CREATE INDEX idx_reviews_rating ON public.reviews(rating);
CREATE INDEX idx_reviews_created_at ON public.reviews(created_at);

-- =================================================================
-- 4. Row Level Security (RLS)
-- =================================================================
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

-- Clientes podem criar reviews para seus próprios contratos
CREATE POLICY "Clients can create reviews for their contracts"
    ON public.reviews FOR INSERT
    WITH CHECK (
        client_id = auth.uid() AND
        contract_id IN (
            SELECT id FROM public.contracts 
            WHERE client_id = auth.uid() 
            AND status = 'closed'
        )
    );

-- Clientes podem visualizar suas próprias reviews
CREATE POLICY "Clients can view their own reviews"
    ON public.reviews FOR SELECT
    USING (client_id = auth.uid());

-- Advogados podem visualizar reviews sobre eles
CREATE POLICY "Lawyers can view reviews about them"
    ON public.reviews FOR SELECT
    USING (
        lawyer_id IN (
            SELECT l.id FROM public.lawyers l
            JOIN public.profiles p ON l.id = p.id
            WHERE p.user_id = auth.uid()
        )
    );

-- Clientes podem atualizar suas próprias reviews (dentro de 7 dias)
CREATE POLICY "Clients can update their recent reviews"
    ON public.reviews FOR UPDATE
    USING (
        client_id = auth.uid() AND
        created_at > (now() - interval '7 days')
    );

-- =================================================================
-- 5. Trigger para atualizar updated_at
-- =================================================================
CREATE TRIGGER reviews_updated_at_trigger
    BEFORE UPDATE ON public.reviews
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- =================================================================
-- 6. Função para calcular média de avaliações
-- =================================================================
CREATE OR REPLACE FUNCTION public.calculate_lawyer_rating(lawyer_uuid uuid)
RETURNS numeric AS $$
DECLARE
    avg_rating numeric;
BEGIN
    SELECT AVG(rating)::numeric(3,2)
    INTO avg_rating
    FROM public.reviews
    WHERE lawyer_id = lawyer_uuid;
    
    RETURN COALESCE(avg_rating, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- 7. Função para atualizar KPI dos advogados (Job noturno)
-- =================================================================
CREATE OR REPLACE FUNCTION public.update_lawyers_review_kpi()
RETURNS integer AS $$
DECLARE
    updated_count integer := 0;
    lawyer_record record;
BEGIN
    -- Atualizar avaliacao_media para todos os advogados com reviews
    FOR lawyer_record IN 
        SELECT 
            l.id,
            AVG(r.rating)::numeric(3,2) as avg_rating,
            COUNT(r.id) as review_count
        FROM public.lawyers l
        LEFT JOIN public.reviews r ON l.id = r.lawyer_id
        GROUP BY l.id
    LOOP
        UPDATE public.lawyers
        SET kpi = jsonb_set(
            COALESCE(kpi, '{}'::jsonb),
            '{avaliacao_media}',
            to_jsonb(COALESCE(lawyer_record.avg_rating, 0))
        ),
        kpi = jsonb_set(
            kpi,
            '{review_count}',
            to_jsonb(COALESCE(lawyer_record.review_count, 0))
        )
        WHERE id = lawyer_record.id;
        
        updated_count := updated_count + 1;
    END LOOP;
    
    RETURN updated_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- 8. View para estatísticas de reviews
-- =================================================================
CREATE OR REPLACE VIEW public.lawyer_review_stats AS
SELECT 
    l.id as lawyer_id,
    p.user_id,
    p.full_name as lawyer_name,
    COUNT(r.id) as total_reviews,
    AVG(r.rating)::numeric(3,2) as average_rating,
    COUNT(CASE WHEN r.rating >= 4 THEN 1 END) as positive_reviews,
    COUNT(CASE WHEN r.rating <= 2 THEN 1 END) as negative_reviews,
    COUNT(CASE WHEN r.would_recommend = true THEN 1 END) as recommendations,
    AVG(r.communication_rating)::numeric(3,2) as avg_communication,
    AVG(r.expertise_rating)::numeric(3,2) as avg_expertise,
    AVG(r.timeliness_rating)::numeric(3,2) as avg_timeliness,
    COUNT(CASE WHEN r.outcome = 'won' THEN 1 END) as perceived_wins,
    COUNT(CASE WHEN r.outcome = 'lost' THEN 1 END) as perceived_losses
FROM public.lawyers l
LEFT JOIN public.profiles p ON l.id = p.id
LEFT JOIN public.reviews r ON l.id = r.lawyer_id
GROUP BY l.id, p.user_id, p.full_name;

-- =================================================================
-- 9. Grants e permissões
-- =================================================================
GRANT SELECT ON public.lawyer_review_stats TO authenticated;
GRANT EXECUTE ON FUNCTION public.calculate_lawyer_rating(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_lawyers_review_kpi() TO service_role;

-- =================================================================
-- 10. Comentários para documentação
-- =================================================================
COMMENT ON TABLE public.reviews IS 'Avaliações dos clientes sobre advogados após conclusão do contrato. Alimenta a feature R (review_score) do algoritmo, separada do KPI T (success_rate) do Jusbrasil.';
COMMENT ON COLUMN public.reviews.rating IS 'Avaliação geral de 1-5 estrelas (obrigatório)';
COMMENT ON COLUMN public.reviews.outcome IS 'Resultado percebido pelo cliente (subjetivo)';
COMMENT ON COLUMN public.reviews.would_recommend IS 'Se o cliente recomendaria o advogado';
COMMENT ON FUNCTION public.update_lawyers_review_kpi() IS 'Job noturno para atualizar kpi.avaliacao_media baseado nas reviews. Executa via cron às 02:00 UTC.';
COMMENT ON VIEW public.lawyer_review_stats IS 'Estatísticas agregadas de reviews por advogado para dashboards e relatórios.';

-- =================================================================
-- 11. Inicializar KPI para advogados existentes
-- =================================================================
UPDATE public.lawyers 
SET kpi = jsonb_set(
    COALESCE(kpi, '{}'::jsonb),
    '{avaliacao_media}',
    '0'::jsonb
)
WHERE kpi IS NULL OR NOT (kpi ? 'avaliacao_media'); 