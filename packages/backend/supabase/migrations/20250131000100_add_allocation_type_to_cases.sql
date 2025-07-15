-- Migration: Add allocation_type field to cases table
-- Timestamp: 20250131000100
-- Reference: ARQUITETURA_GERAL_DO_SISTEMA.md - Sistema de Contextual Case View

-- Criar ENUM para tipos de alocação de casos
CREATE TYPE IF NOT EXISTS allocation_type AS ENUM (
    'platform_match_direct',         -- Algoritmo → Advogado (Super Associado)
    'platform_match_partnership',    -- Algoritmo → Parceria → Advogado
    'partnership_proactive_search',  -- Parceria criada por busca manual
    'partnership_platform_suggestion', -- Parceria sugerida por IA
    'internal_delegation'            -- Escritório → Advogado Associado
);

-- Adicionar campo allocation_type na tabela cases
ALTER TABLE public.cases 
ADD COLUMN allocation_type allocation_type DEFAULT 'platform_match_direct';

-- Adicionar campos contextuais adicionais
ALTER TABLE public.cases 
ADD COLUMN partner_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
ADD COLUMN partnership_id uuid, -- Para referenciar parcerias futuras
ADD COLUMN delegated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
ADD COLUMN match_score numeric(5,2), -- Score do match (0-100)
ADD COLUMN response_deadline timestamp with time zone,
ADD COLUMN context_metadata jsonb; -- Metadados contextuais específicos

-- Criar índices para otimizar consultas
CREATE INDEX IF NOT EXISTS idx_cases_allocation_type ON public.cases(allocation_type);
CREATE INDEX IF NOT EXISTS idx_cases_partner_id ON public.cases(partner_id);
CREATE INDEX IF NOT EXISTS idx_cases_delegated_by ON public.cases(delegated_by);
CREATE INDEX IF NOT EXISTS idx_cases_response_deadline ON public.cases(response_deadline);

-- Atualizar política de segurança para incluir parceiros
DROP POLICY IF EXISTS "Users can view their own cases" ON public.cases;
CREATE POLICY "Users can view their own cases" ON public.cases
FOR SELECT USING (
    client_id = auth.uid() 
    OR lawyer_id = auth.uid()
    OR partner_id = auth.uid()
    OR delegated_by = auth.uid()
);

-- Atualizar política de update para incluir parceiros
DROP POLICY IF EXISTS "Users can update their own cases" ON public.cases;
CREATE POLICY "Users can update their own cases" ON public.cases
FOR UPDATE USING (
    client_id = auth.uid() 
    OR lawyer_id = auth.uid()
    OR partner_id = auth.uid()
    OR delegated_by = auth.uid()
);

-- Comentários para documentação
COMMENT ON COLUMN public.cases.allocation_type IS 'Tipo de alocação do caso: platform_match_direct, platform_match_partnership, partnership_proactive_search, partnership_platform_suggestion, internal_delegation';
COMMENT ON COLUMN public.cases.partner_id IS 'ID do parceiro em casos de parceria';
COMMENT ON COLUMN public.cases.partnership_id IS 'ID da parceria (referência futura)';
COMMENT ON COLUMN public.cases.delegated_by IS 'ID do usuário que delegou o caso (para internal_delegation)';
COMMENT ON COLUMN public.cases.match_score IS 'Score do match algorítmico (0-100)';
COMMENT ON COLUMN public.cases.response_deadline IS 'Prazo limite para resposta do advogado';
COMMENT ON COLUMN public.cases.context_metadata IS 'Metadados contextuais específicos por tipo de alocação'; 