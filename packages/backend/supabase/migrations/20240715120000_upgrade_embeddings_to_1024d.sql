-- MIGRATION: Upgrade embedding vector columns to 1024 dimensions for V2 Strategy.
--
-- Altera as colunas de embedding nas tabelas principais para suportar
-- os vetores de 1024 dimensões gerados pelo `embedding_service_v2`.
-- Isso é um passo destrutivo para os dados existentes, um backfill será necessário.

-- Tabela: cases
-- Utilizada para armazenar o embedding do resumo do caso.
ALTER TABLE public.cases
ADD COLUMN IF NOT EXISTS embedding_v2 vector(1024);

COMMENT ON COLUMN public.cases.embedding_v2 IS 'Embedding de 1024 dimensões gerado pelo serviço V2.';

-- Tabela: lawyers
-- Utilizada para armazenar o embedding do CV do advogado.
ALTER TABLE public.lawyers
ADD COLUMN IF NOT EXISTS cv_embedding_v2 vector(1024);

COMMENT ON COLUMN public.lawyers.cv_embedding_v2 IS 'Embedding do CV de 1024 dimensões gerado pelo serviço V2.';

-- Tabela: law_firms
-- Utilizada para armazenar o embedding do perfil semântico do escritório.
ALTER TABLE public.law_firms
ADD COLUMN IF NOT EXISTS embedding_v2 vector(1024);

COMMENT ON COLUMN public.law_firms.embedding_v2 IS 'Embedding do perfil do escritório de 1024 dimensões gerado pelo serviço V2.';

-- Recriar Índices para as novas colunas V2
-- A remoção dos índices antigos e colunas legadas será feita em uma migração de limpeza futura.

CREATE INDEX IF NOT EXISTS idx_cases_embedding_v2
ON public.cases
USING ivfflat (embedding_v2 vector_cosine_ops)
WITH (lists = 100);

CREATE INDEX IF NOT EXISTS idx_lawyers_cv_embedding_v2
ON public.lawyers
USING ivfflat (cv_embedding_v2 vector_cosine_ops)
WITH (lists = 100);

CREATE INDEX IF NOT EXISTS idx_law_firms_embedding_v2
ON public.law_firms
USING ivfflat (embedding_v2 vector_cosine_ops)
WITH (lists = 100);