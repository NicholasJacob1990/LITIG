-- Migration: Adicionar campo is_boutique à tabela law_firms
-- Data: 2025-01-15
-- Descrição: Adiciona o campo is_boutique para identificar escritórios boutique no Sistema de Busca Avançada

-- Adicionar campo is_boutique à tabela law_firms
ALTER TABLE public.law_firms 
ADD COLUMN IF NOT EXISTS is_boutique BOOLEAN DEFAULT FALSE;

-- Criar índice para otimizar consultas de busca por escritórios boutique
CREATE INDEX IF NOT EXISTS idx_law_firms_is_boutique ON public.law_firms(is_boutique);

-- Adicionar comentário para documentação
COMMENT ON COLUMN public.law_firms.is_boutique IS 'Indica se o escritório é classificado como boutique (especialização focada)';

-- Atualizar alguns escritórios como exemplo (opcional - dados fictícios para desenvolvimento)
-- UPDATE public.law_firms 
-- SET is_boutique = true 
-- WHERE team_size <= 15 AND name LIKE '%Especializado%'; 