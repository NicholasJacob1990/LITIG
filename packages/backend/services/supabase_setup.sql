-- Configuração do Supabase para Brazilian Legal RAG
-- Execute este SQL no seu dashboard do Supabase

-- 1. Habilitar extensão pgvector para vetores
CREATE EXTENSION IF NOT EXISTS vector;

-- 2. Criar tabela para documentos jurídicos
CREATE TABLE IF NOT EXISTS legal_documents (
    id BIGSERIAL PRIMARY KEY,
    content TEXT NOT NULL,
    metadata JSONB,
    embedding VECTOR(1536) -- Dimensão para OpenAI text-embedding-3-small
);

-- 3. Criar índice para busca eficiente por vetores
CREATE INDEX IF NOT EXISTS legal_documents_embedding_idx 
ON legal_documents USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);

-- 4. Criar função para busca por similaridade
CREATE OR REPLACE FUNCTION match_legal_documents (
    query_embedding VECTOR(1536),
    match_threshold FLOAT DEFAULT 0.78,
    match_count INT DEFAULT 5
)
RETURNS TABLE (
    id BIGINT,
    content TEXT,
    metadata JSONB,
    similarity FLOAT
)
LANGUAGE SQL STABLE
AS $$
SELECT
    legal_documents.id,
    legal_documents.content,
    legal_documents.metadata,
    1 - (legal_documents.embedding <=> query_embedding) AS similarity
FROM legal_documents
WHERE 1 - (legal_documents.embedding <=> query_embedding) > match_threshold
ORDER BY legal_documents.embedding <=> query_embedding
LIMIT match_count;
$$;

-- 5. Configurar RLS (Row Level Security) se necessário
-- ALTER TABLE legal_documents ENABLE ROW LEVEL SECURITY;

-- 6. Criar política para permitir leitura pública (ajuste conforme necessário)
-- CREATE POLICY "Allow public read access" ON legal_documents FOR SELECT USING (true);

-- 7. Verificar configuração
SELECT 
    'Tabela legal_documents criada' as status,
    COUNT(*) as total_documents
FROM legal_documents;

-- 8. Exemplo de query de teste (executar após inserir dados)
-- SELECT content, metadata, similarity 
-- FROM match_legal_documents('[0.1,0.2,...]'::vector, 0.7, 3);
