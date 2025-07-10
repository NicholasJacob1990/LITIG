-- Habilita a extensão pgvector, necessária para o tipo 'vector'.
CREATE EXTENSION IF NOT EXISTS vector;

-- Adiciona a nova coluna 'embedding' com o tipo 'vector' na tabela 'cases'.
-- A dimensão 384 corresponde ao modelo text-embedding-3-small da OpenAI.
ALTER TABLE public.cases
ADD COLUMN IF NOT EXISTS embedding vector(384);

-- Cria um índice IVFFlat para otimizar buscas por similaridade de cosseno.
-- Este é um passo crucial para a performance em produção.
-- O número de listas (lists) deve ser ajustado com base no tamanho da tabela.
-- Para tabelas com até 1M de registros, sqrt(N) é um bom ponto de partida.
-- Para tabelas maiores, N/1000.
-- Assumindo uma tabela pequena para começar.
CREATE INDEX IF NOT EXISTS idx_cases_embedding
ON public.cases
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);

-- Remove a coluna antiga 'summary_embedding' que usava JSONB.
-- ATENÇÃO: Faça um backup ou migre os dados antes de executar em produção.
-- Em um cenário real, você faria:
-- UPDATE public.cases SET embedding = CAST(summary_embedding AS vector);
ALTER TABLE public.cases
DROP COLUMN IF EXISTS summary_embedding; 