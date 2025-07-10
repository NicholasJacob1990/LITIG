-- Migração para adicionar campo "Escopo do Serviço" na tabela cases
-- Data: 2025-08-01
-- Descrição: Adiciona campo service_scope para que advogados possam definir o escopo detalhado do serviço a ser prestado

-- Adicionar coluna service_scope na tabela cases
ALTER TABLE cases 
ADD COLUMN IF NOT EXISTS service_scope TEXT;

-- Adicionar coluna para data de definição do escopo
ALTER TABLE cases 
ADD COLUMN IF NOT EXISTS service_scope_defined_at TIMESTAMP WITH TIME ZONE;

-- Adicionar coluna para identificar quem definiu o escopo
ALTER TABLE cases 
ADD COLUMN IF NOT EXISTS service_scope_defined_by UUID REFERENCES profiles(id);

-- Comentários para documentação
COMMENT ON COLUMN cases.service_scope IS 'Escopo detalhado do serviço a ser prestado, definido pelo advogado após análise';
COMMENT ON COLUMN cases.service_scope_defined_at IS 'Data e hora em que o escopo do serviço foi definido';
COMMENT ON COLUMN cases.service_scope_defined_by IS 'ID do advogado que definiu o escopo do serviço';

-- Criar índice para otimizar consultas
CREATE INDEX IF NOT EXISTS idx_cases_service_scope_defined 
ON cases(service_scope_defined_at) 
WHERE service_scope IS NOT NULL;

-- Função RPC para atualizar o escopo do serviço
CREATE OR REPLACE FUNCTION update_service_scope(
  p_case_id UUID,
  p_service_scope TEXT,
  p_lawyer_id UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result JSON;
BEGIN
  -- Verificar se o advogado tem permissão para atualizar este caso
  IF NOT EXISTS (
    SELECT 1 FROM cases 
    WHERE id = p_case_id 
    AND lawyer_id = p_lawyer_id
  ) THEN
    RAISE EXCEPTION 'Acesso negado: Apenas o advogado responsável pode definir o escopo do serviço';
  END IF;

  -- Atualizar o escopo do serviço
  UPDATE cases 
  SET 
    service_scope = p_service_scope,
    service_scope_defined_at = NOW(),
    service_scope_defined_by = p_lawyer_id,
    updated_at = NOW()
  WHERE id = p_case_id;

  -- Retornar dados atualizados
  SELECT json_build_object(
    'success', true,
    'message', 'Escopo do serviço atualizado com sucesso',
    'case_id', p_case_id,
    'service_scope', p_service_scope,
    'defined_at', NOW(),
    'defined_by', p_lawyer_id
  ) INTO result;

  RETURN result;
END;
$$;

-- Dropar função existente para evitar conflitos de tipo
DROP FUNCTION IF EXISTS get_user_cases(UUID);

-- Atualizar a função get_user_cases para incluir o novo campo
CREATE OR REPLACE FUNCTION get_user_cases(user_id UUID)
RETURNS TABLE (
  id UUID,
  title TEXT,
  description TEXT,
  area TEXT,
  subarea TEXT,
  status TEXT,
  priority TEXT,
  urgency_hours INTEGER,
  risk_level TEXT,
  confidence_score NUMERIC,
  estimated_cost NUMERIC,
  next_step TEXT,
  consultation_fee NUMERIC,
  representation_fee NUMERIC,
  fee_type TEXT,
  success_percentage NUMERIC,
  hourly_rate NUMERIC,
  plan_type TEXT,
  payment_terms TEXT,
  service_scope TEXT,
  service_scope_defined_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE,
  client_name TEXT,
  client_type TEXT,
  lawyer_name TEXT,
  lawyer_specialty TEXT,
  lawyer_avatar TEXT,
  lawyer_oab TEXT,
  lawyer_rating NUMERIC,
  lawyer_experience_years INTEGER,
  unread_messages BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    c.id,
    c.title,
    c.description,
    c.area,
    c.subarea,
    c.status,
    c.priority,
    c.urgency_hours,
    c.risk_level,
    c.confidence_score,
    c.estimated_cost,
    c.next_step,
    c.consultation_fee,
    c.representation_fee,
    c.fee_type,
    c.success_percentage,
    c.hourly_rate,
    c.plan_type,
    c.payment_terms,
    c.service_scope,
    c.service_scope_defined_at,
    c.created_at,
    c.updated_at,
    client_profile.full_name as client_name,
    client_profile.user_type as client_type,
    lawyer_profile.full_name as lawyer_name,
    lawyer_profile.specialization as lawyer_specialty,
    lawyer_profile.avatar_url as lawyer_avatar,
    lawyer_profile.oab_number as lawyer_oab,
    lawyer_profile.rating as lawyer_rating,
    lawyer_profile.experience_years as lawyer_experience_years,
    COALESCE(msg_count.unread_count, 0) as unread_messages
  FROM cases c
  LEFT JOIN profiles client_profile ON c.client_id = client_profile.id
  LEFT JOIN profiles lawyer_profile ON c.lawyer_id = lawyer_profile.id
  LEFT JOIN (
    SELECT 
      case_id,
      COUNT(*) as unread_count
    FROM messages 
    WHERE read_at IS NULL 
    AND sender_id != user_id
    GROUP BY case_id
  ) msg_count ON c.id = msg_count.case_id
  WHERE c.client_id = user_id OR c.lawyer_id = user_id
  ORDER BY c.updated_at DESC;
END;
$$; 