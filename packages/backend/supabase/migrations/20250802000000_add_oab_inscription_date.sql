-- Adicionar coluna de data de inscrição na OAB
ALTER TABLE public.lawyers 
ADD COLUMN IF NOT EXISTS oab_inscription_date date;

-- Criar índice para consultas por data, se for um filtro comum
CREATE INDEX IF NOT EXISTS idx_lawyers_oab_inscription_date 
ON public.lawyers (oab_inscription_date);

-- Adicionar comentário para documentar o propósito da coluna
COMMENT ON COLUMN public.lawyers.oab_inscription_date 
IS 'Data de inscrição do advogado na OAB, usada para calcular senioridade.'; 