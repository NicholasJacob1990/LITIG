-- Migration: Enable vector extension
-- Timestamp: 20250102000002

-- Habilitar extensão vector para embeddings
CREATE EXTENSION IF NOT EXISTS vector;

-- Comentário para documentação
COMMENT ON EXTENSION vector IS 'Extensão para suporte a embeddings vetoriais'; 