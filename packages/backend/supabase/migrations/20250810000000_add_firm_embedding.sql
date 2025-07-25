-- Migration: Adicionar Perfil Semântico e Embedding para Escritórios (Law Firms)
-- Feature-E: Busca Semântica B2B

-- 1. Adicionar coluna para armazenar o perfil textual que gera o embedding
ALTER TABLE public.law_firms
ADD COLUMN IF NOT EXISTS semantic_profile TEXT;

COMMENT ON COLUMN public.law_firms.semantic_profile IS 'Texto agregado usado para gerar o embedding do escritório (descrição, áreas de foco, etc.)';

-- 2. Adicionar coluna para o vetor de embedding
ALTER TABLE public.law_firms
ADD COLUMN IF NOT EXISTS embedding vector(768);

COMMENT ON COLUMN public.law_firms.embedding IS 'Vetor de embedding gerado a partir do semantic_profile para busca de similaridade.';

-- 3. Criar um índice para a busca de vetores
-- Usar IVFFlat é um bom começo para performance. O número de listas (lists) pode ser ajustado.
-- Regra geral: `n_rows / 1000` para datasets < 1M, e `sqrt(n_rows)` para > 1M. Começamos com um valor padrão.
CREATE INDEX IF NOT EXISTS idx_law_firms_embedding ON public.law_firms
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100); 
 