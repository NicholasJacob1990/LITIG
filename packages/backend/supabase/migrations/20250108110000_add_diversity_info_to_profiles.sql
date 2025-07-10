-- Adicionar campos de diversidade à tabela profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS gender TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS ethnicity TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS sexual_orientation TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_pcd BOOLEAN DEFAULT FALSE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS share_diversity_data BOOLEAN DEFAULT FALSE;

-- Adicionar comentários para documentar os campos
COMMENT ON COLUMN profiles.gender IS 'Identidade de gênero do usuário (opcional)';
COMMENT ON COLUMN profiles.ethnicity IS 'Cor/raça/etnia do usuário (opcional)';
COMMENT ON COLUMN profiles.sexual_orientation IS 'Orientação sexual do usuário (opcional)';
COMMENT ON COLUMN profiles.is_pcd IS 'Indica se o usuário é pessoa com deficiência';
COMMENT ON COLUMN profiles.share_diversity_data IS 'Permite compartilhar dados de diversidade para estatísticas';

-- Criar índices para consultas de diversidade (se necessário)
CREATE INDEX IF NOT EXISTS idx_profiles_diversity ON profiles(gender, ethnicity, is_pcd) WHERE share_diversity_data = true; 