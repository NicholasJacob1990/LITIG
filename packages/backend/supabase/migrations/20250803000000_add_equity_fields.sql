-- Adicionar colunas de equidade (opcionais) para o β-layer de diversidade
ALTER TABLE public.lawyers 
ADD COLUMN IF NOT EXISTS gender VARCHAR(50),
ADD COLUMN IF NOT EXISTS ethnicity VARCHAR(100),
ADD COLUMN IF NOT EXISTS pcd BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS orientation VARCHAR(50);

-- Criar índices para análises agregadas (sem identificação individual)
CREATE INDEX IF NOT EXISTS idx_lawyers_gender ON public.lawyers (gender) WHERE gender IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_lawyers_ethnicity ON public.lawyers (ethnicity) WHERE ethnicity IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_lawyers_pcd ON public.lawyers (pcd) WHERE pcd = true;
CREATE INDEX IF NOT EXISTS idx_lawyers_orientation ON public.lawyers (orientation) WHERE orientation IS NOT NULL;


-- Adicionar comentários para documentar o propósito das colunas
COMMENT ON COLUMN public.lawyers.gender IS 'Gênero autodeclarado (opcional), usado para iniciativas de equidade.';
COMMENT ON COLUMN public.lawyers.ethnicity IS 'Etnia autodeclarada (opcional), usada para iniciativas de equidade.';
COMMENT ON COLUMN public.lawyers.pcd IS 'Indica se a pessoa é com deficiência (opcional), usado para iniciativas de equidade.';
COMMENT ON COLUMN public.lawyers.orientation IS 'Orientação sexual autodeclarada (opcional), usada para iniciativas de equidade.';

-- NOTA DE SEGURANÇA: A política de RLS para proteger estes dados
-- deve ser criada e gerenciada em um arquivo de políticas separado
-- ou diretamente no painel do Supabase para garantir que não seja
-- acidentalmente sobrescrita e que o acesso seja restrito
-- apenas a roles autorizadas (ex: o próprio usuário ou administradores). 