-- Migração para Embeddings Enriquecidos: CV + KPIs + Performance (1024D)
-- Estratégia: Combinar dados textuais com métricas numéricas em um "super-documento"
-- Objetivo: Embedding que entende tanto o conteúdo quanto a performance do advogado

-- 1. Adiciona nova coluna para embeddings enriquecidos
ALTER TABLE public.lawyers
ADD COLUMN IF NOT EXISTS cv_embedding_v2_enriched vector(1024);

-- 2. Cria índice IVFFlat especializado para embeddings enriquecidos
CREATE INDEX IF NOT EXISTS idx_lawyers_cv_embedding_v2_enriched_1024d
ON public.lawyers
USING ivfflat (cv_embedding_v2_enriched vector_cosine_ops)
WITH (lists = 100);

-- 3. Adiciona metadados sobre o embedding enriquecido
ALTER TABLE public.lawyers
ADD COLUMN IF NOT EXISTS cv_embedding_v2_enriched_model VARCHAR(50) DEFAULT 'openai-3-large',
ADD COLUMN IF NOT EXISTS cv_embedding_v2_enriched_generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN IF NOT EXISTS cv_embedding_v2_enriched_version VARCHAR(10) DEFAULT 'v1.0';

-- 4. Adiciona flag para controlar uso de embeddings enriquecidos
ALTER TABLE public.lawyers
ADD COLUMN IF NOT EXISTS use_enriched_embeddings BOOLEAN DEFAULT false;

-- 5. Comentários para documentação
COMMENT ON COLUMN public.lawyers.cv_embedding_v2_enriched IS 
'Embedding enriquecido (1024D) que combina CV + KPIs + performance para matching holístico';

COMMENT ON COLUMN public.lawyers.cv_embedding_v2_enriched_model IS 
'Modelo usado para gerar o embedding enriquecido (openai-3-large, voyage-law-2, etc.)';

COMMENT ON COLUMN public.lawyers.cv_embedding_v2_enriched_version IS 
'Versão do algoritmo de enriquecimento usado (v1.0, v1.1, etc.)';

COMMENT ON COLUMN public.lawyers.use_enriched_embeddings IS 
'Flag para habilitar uso de embeddings enriquecidos no matching (A/B testing)';

COMMENT ON INDEX idx_lawyers_cv_embedding_v2_enriched_1024d IS 
'Índice para busca por similaridade em embeddings enriquecidos (CV + KPIs + performance)';

-- 6. Índice adicional para controle de A/B testing
CREATE INDEX IF NOT EXISTS idx_lawyers_use_enriched_embeddings
ON public.lawyers (use_enriched_embeddings)
WHERE use_enriched_embeddings = true;
 
 