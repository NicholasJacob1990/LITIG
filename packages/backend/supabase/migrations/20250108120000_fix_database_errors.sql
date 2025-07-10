-- Atualizar função get_user_cases_with_rating para usar client_id em vez de user_id
CREATE OR REPLACE FUNCTION get_user_cases_with_rating(user_uuid UUID)
RETURNS TABLE (
  id UUID,
  title TEXT,
  description TEXT,
  status TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  client_id UUID,
  lawyer_id UUID,
  lawyer_name TEXT,
  lawyer_rating DECIMAL,
  lawyer_review_count INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    c.id,
    c.title,
    c.description,
    c.status,
    c.created_at,
    c.updated_at,
    c.client_id,
    c.lawyer_id,
    p.full_name as lawyer_name,
    p.rating as lawyer_rating,
    p.review_count as lawyer_review_count
  FROM cases c
  LEFT JOIN profiles p ON c.lawyer_id = p.id
  WHERE c.client_id = user_uuid
  ORDER BY c.updated_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Atualizar políticas RLS para usar client_id
DROP POLICY IF EXISTS "Users can view their own cases" ON cases;
CREATE POLICY "Users can view their own cases" ON cases
  FOR SELECT USING (
    auth.uid() = client_id OR 
    auth.uid() = lawyer_id
  );

DROP POLICY IF EXISTS "Users can insert their own cases" ON cases;
CREATE POLICY "Users can insert their own cases" ON cases
  FOR INSERT WITH CHECK (auth.uid() = client_id);

DROP POLICY IF EXISTS "Users can update their own cases" ON cases;
CREATE POLICY "Users can update their own cases" ON cases
  FOR UPDATE USING (
    auth.uid() = client_id OR 
    auth.uid() = lawyer_id
  );

-- Criar índices para melhorar performance
CREATE INDEX IF NOT EXISTS idx_cases_client_id ON cases(client_id);
CREATE INDEX IF NOT EXISTS idx_cases_lawyer_id ON cases(lawyer_id); 