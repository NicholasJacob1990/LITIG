-- Migration: Adicionar colunas de rating em tempo real à tabela profiles
-- Timestamp: 20250806000000

-- =================================================================
-- 1. Adicionar colunas de rating e contagem de reviews à tabela profiles
-- =================================================================
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS rating NUMERIC(3, 2) DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS review_count INTEGER DEFAULT 0;

COMMENT ON COLUMN public.profiles.rating IS 'Avaliação média do advogado, calculada a partir da tabela de reviews. Normalizado para acesso rápido pelo frontend.';
COMMENT ON COLUMN public.profiles.review_count IS 'Número total de avaliações recebidas pelo advogado.';


-- =================================================================
-- 2. Função para atualizar o perfil de um advogado após nova review
-- =================================================================
CREATE OR REPLACE FUNCTION public.update_profile_rating()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    avg_rating NUMERIC;
    total_reviews INTEGER;
BEGIN
    -- Calcula a nova média e contagem de reviews para o advogado que foi avaliado
    SELECT
        AVG(rating),
        COUNT(id)
    INTO
        avg_rating,
        total_reviews
    FROM
        public.reviews
    WHERE
        lawyer_id = NEW.lawyer_id;

    -- Atualiza a tabela de profiles com os novos valores
    UPDATE public.profiles
    SET
        rating = COALESCE(avg_rating, 0),
        review_count = COALESCE(total_reviews, 0)
    WHERE
        id = NEW.lawyer_id; -- A FK em `reviews` é para `lawyers(id)`, que é o mesmo que `profiles(id)` para advogados

    RETURN NEW;
END;
$$;


-- =================================================================
-- 3. Gatilho (Trigger) para executar a função após inserção de review
-- =================================================================
-- Remover gatilho antigo se existir, para evitar duplicidade
DROP TRIGGER IF EXISTS on_new_review_update_profile_rating ON public.reviews;

-- Criar o novo gatilho
CREATE TRIGGER on_new_review_update_profile_rating
AFTER INSERT ON public.reviews
FOR EACH ROW
EXECUTE FUNCTION public.update_profile_rating();

COMMENT ON TRIGGER on_new_review_update_profile_rating ON public.reviews IS 'Atualiza a avaliação média e a contagem de reviews na tabela de profiles do advogado sempre que uma nova avaliação é inserida.';

-- =================================================================
-- 4. Backfill: Preencher dados para advogados que já possuem reviews
-- =================================================================
-- Esta função será executada uma vez para popular os dados existentes.
DO $$
DECLARE
    lawyer_record RECORD;
BEGIN
    FOR lawyer_record IN
        SELECT
            p.id,
            AVG(r.rating) AS new_rating,
            COUNT(r.id) AS new_review_count
        FROM
            public.profiles p
        JOIN
            public.reviews r ON p.id = r.lawyer_id
        WHERE
            p.role = 'advogado'
        GROUP BY
            p.id
    LOOP
        UPDATE public.profiles
        SET
            rating = COALESCE(lawyer_record.new_rating, 0),
            review_count = COALESCE(lawyer_record.new_review_count, 0)
        WHERE
            id = lawyer_record.id;
    END LOOP;
END $$; 