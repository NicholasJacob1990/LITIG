-- Migração para Embeddings V2: 1024 dimensões - ESTRATÉGIA ORIGINAL
-- Cascata Otimizada: OpenAI 3-large (primário) → Voyage Law-2 → Arctic Embed L
-- Foco: Máxima qualidade com especialização jurídica
-- Mantém compatibilidade com sistema atual (768D)

-- 1. Habilita a extensão pgvector se não estiver habilitada
CREATE EXTENSION IF NOT EXISTS vector;

-- 2. Adiciona nova coluna cv_embedding_v2 com 1024 dimensões
-- Estratégia original: OpenAI como primário + especialização legal
ALTER TABLE public.lawyers
ADD COLUMN IF NOT EXISTS cv_embedding_v2 vector(1024);

-- 3. Cria índice IVFFlat otimizado para 1024D
-- lists = sqrt(num_rows) é boa prática para até 1M registros
CREATE INDEX IF NOT EXISTS idx_lawyers_cv_embedding_v2_1024d
ON public.lawyers
USING ivfflat (cv_embedding_v2 vector_cosine_ops)
WITH (lists = 100);

-- 4. Adiciona metadados sobre o embedding
ALTER TABLE public.lawyers
ADD COLUMN IF NOT EXISTS cv_embedding_v2_model VARCHAR(50) DEFAULT 'openai-3-small',
ADD COLUMN IF NOT EXISTS cv_embedding_v2_generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN IF NOT EXISTS cv_embedding_v2_dimensions INTEGER DEFAULT 1024;

-- 5. Comentários para documentação
COMMENT ON COLUMN public.lawyers.cv_embedding_v2 IS 
'Embedding vetorial V2 do currículo (1024D) - ESTRATÉGIA ORIGINAL: OpenAI 3-large → Voyage Law-2 → Arctic Embed L';

COMMENT ON COLUMN public.lawyers.cv_embedding_v2_model IS 
'Modelo usado para gerar o embedding V2 (openai-3-small, voyage-law-2, arctic-embed-l, etc.)';

COMMENT ON INDEX idx_lawyers_cv_embedding_v2_1024d IS 
'Índice IVFFlat para busca por similaridade cosseno em embeddings 1024D - estratégia original otimizada';

-- 6. Adiciona coluna para controle de migração
ALTER TABLE public.lawyers
ADD COLUMN IF NOT EXISTS embedding_migration_status VARCHAR(20) DEFAULT 'pending';

-- Status possíveis: 'pending', 'migrating', 'completed', 'failed'
COMMENT ON COLUMN public.lawyers.embedding_migration_status IS 
'Status da migração de embeddings: pending, migrating, completed, failed';

-- 7. Índice para queries de migração
CREATE INDEX IF NOT EXISTS idx_lawyers_migration_status
ON public.lawyers (embedding_migration_status)
WHERE embedding_migration_status IN ('pending', 'failed');
 
 