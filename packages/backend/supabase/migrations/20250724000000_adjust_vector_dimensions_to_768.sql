-- Habilita a extensão pgvector, caso ainda não esteja.
CREATE EXTENSION IF NOT EXISTS vector;

-- ATENÇÃO: Esta migração ALTERA o tipo de dados de colunas existentes.
-- Isso pode causar a reescrita da tabela inteira, o que pode ser uma operação
-- demorada e intensiva em I/O em tabelas muito grandes.
-- FAÇA UM BACKUP ANTES DE EXECUTAR EM PRODUÇÃO.

-- 1. Alterar a tabela 'cases' para a nova dimensão de 768
-- Remove o índice antigo para permitir a alteração do tipo da coluna.
DROP INDEX IF EXISTS idx_cases_embedding;

-- Altera o tipo da coluna para vector(768).
-- Se você tiver dados existentes, precisará truncá-los ou recriá-los.
-- Exemplo para truncar:
-- UPDATE public.cases SET embedding = (embedding::real[])[1:768]::vector(768);
ALTER TABLE public.cases
ALTER COLUMN embedding SET DATA TYPE vector(768);

-- Recria o índice com a nova dimensão.
CREATE INDEX idx_cases_embedding
ON public.cases
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);

-- 2. Alterar a tabela 'lawyers' para a nova dimensão de 768
-- Remove o índice antigo.
DROP INDEX IF EXISTS idx_lawyers_cv_embedding;

-- Altera o tipo da coluna para vector(768).
ALTER TABLE public.lawyers
ALTER COLUMN cv_embedding SET DATA TYPE vector(768);

-- Recria o índice com a nova dimensão.
CREATE INDEX idx_lawyers_cv_embedding
ON public.lawyers
USING ivfflat (cv_embedding vector_cosine_ops)
WITH (lists = 100);

COMMENT ON COLUMN public.cases.embedding IS 'Embedding do resumo do caso, dimensão 768, gerado primariamente pelo Gemini.';
COMMENT ON COLUMN public.lawyers.cv_embedding IS 'Embedding vetorial do currículo, dimensão 768, gerado primariamente pelo Gemini.'; 
 