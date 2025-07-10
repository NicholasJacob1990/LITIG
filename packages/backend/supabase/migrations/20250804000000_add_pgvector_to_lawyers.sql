-- Habilita a extensão pgvector, se ainda não estiver habilitada
CREATE EXTENSION IF NOT EXISTS vector;

-- Adiciona a coluna 'cv_embedding' na tabela de advogados
-- A dimensão 384 corresponde ao modelo 'sentence-transformers/all-MiniLM-L6-v2' usado no backend.
ALTER TABLE public.lawyers
ADD COLUMN IF NOT EXISTS cv_embedding vector(384);

-- Cria um índice IVFFlat para otimizar buscas por similaridade de cosseno.
-- Este é um passo crucial para a performance em produção.
-- O número de listas (lists) é um hiperparâmetro. sqrt(N) é um bom ponto de partida para até 1M de registros.
CREATE INDEX IF NOT EXISTS idx_lawyers_cv_embedding
ON public.lawyers
USING ivfflat (cv_embedding vector_cosine_ops)
WITH (lists = 100);

-- Adiciona um comentário para documentação
COMMENT ON COLUMN public.lawyers.cv_embedding IS 'Embedding vetorial do currículo do advogado, gerado por NLP para buscas de similaridade.';

-- NOTA: Após esta migração, um script de backfill será necessário para
-- popular a coluna 'cv_embedding' com os dados que atualmente
-- residem no campo JSONB 'cv_analysis'. 