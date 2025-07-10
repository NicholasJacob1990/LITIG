-- Adicionar colunas para gestão de disponibilidade na tabela lawyers

ALTER TABLE public.lawyers
ADD COLUMN IF NOT EXISTS is_available BOOLEAN DEFAULT TRUE NOT NULL,
ADD COLUMN IF NOT EXISTS availability_reason TEXT;

COMMENT ON COLUMN public.lawyers.is_available IS 'Indica se o advogado está disponível para receber novas ofertas de casos (true) ou não (false).';
COMMENT ON COLUMN public.lawyers.availability_reason IS 'Motivo opcional para a indisponibilidade (ex: "Férias", "Excesso de casos").';

-- Criar um índice na coluna de disponibilidade para otimizar as buscas do algoritmo de matching
CREATE INDEX IF NOT EXISTS idx_lawyers_is_available ON public.lawyers(is_available); 