-- Adiciona as colunas necessárias para o algoritmo de match na tabela 'lawyers'.

-- Garante que a extensão pg_trgm esteja disponível, útil para buscas textuais futuras.
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Adiciona a coluna 'kpi' para armazenar métricas de performance do advogado.
-- O formato JSONB é eficiente para armazenamento e consulta de dados semi-estruturados.
ALTER TABLE public.lawyers
ADD COLUMN IF NOT EXISTS kpi JSONB DEFAULT '{}'::jsonb;

-- Adiciona a coluna para os embeddings de casos históricos.
-- Usar JSONB é uma alternativa caso a extensão 'vector' não esteja universalmente disponível.
-- Para produção de alta performance, o ideal seria usar o tipo 'vector'.
ALTER TABLE public.lawyers
ADD COLUMN IF NOT EXISTS casos_historicos_embeddings JSONB DEFAULT '[]'::jsonb;

-- Adiciona a coluna para o timestamp do round-robin (equidade).
-- TIMESTAMPTZ armazena o timestamp com fuso horário, o que é uma boa prática.
ALTER TABLE public.lawyers
ADD COLUMN IF NOT EXISTS last_offered_at TIMESTAMPTZ;

-- Adiciona um índice na coluna 'kpi' para otimizar consultas baseadas em métricas.
-- Um índice GIN é recomendado para colunas JSONB.
CREATE INDEX IF NOT EXISTS idx_lawyers_kpi ON public.lawyers USING gin (kpi);

-- Comentários para clareza
COMMENT ON COLUMN public.lawyers.kpi IS 'Armazena KPIs (Key Performance Indicators) como taxa de sucesso, capacidade mensal, etc.';
COMMENT ON COLUMN public.lawyers.casos_historicos_embeddings IS 'Array de vetores de embedding de casos anteriores para cálculo de similaridade.';
COMMENT ON COLUMN public.lawyers.last_offered_at IS 'Timestamp da última vez que o advogado foi oferecido em um match, para o algoritmo de equidade.'; 