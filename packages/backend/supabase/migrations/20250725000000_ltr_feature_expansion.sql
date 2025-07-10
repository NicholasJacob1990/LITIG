-- Migração para expansão das features v2.2 do algoritmo de match
-- Adiciona suporte para KPI granular, soft-skills e complexidade de casos

-- KPI granular (wins por área/subárea)
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS kpi_subarea JSONB DEFAULT '{}'::jsonb;

-- Soft-skills (0–1)
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS kpi_softskill NUMERIC(3,2) DEFAULT 0 CHECK (kpi_softskill >= 0 AND kpi_softskill <= 1);

-- Complexidade do case
ALTER TABLE public.cases ADD COLUMN IF NOT EXISTS complexity TEXT
  CHECK (complexity IN ('LOW','MEDIUM','HIGH')) DEFAULT 'MEDIUM';

-- Adiciona campo para armazenar outcomes de casos históricos (para case similarity ponderada)
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS case_outcomes JSONB DEFAULT '[]'::jsonb;

-- Adiciona campo para score de CV baseado em publicações
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS cv_score NUMERIC(3,2) DEFAULT 0 CHECK (cv_score >= 0 AND cv_score <= 1);

-- Índice full-text para reviews (análise de sentimento)
CREATE INDEX IF NOT EXISTS reviews_tsv_idx ON public.reviews
  USING gin (to_tsvector('portuguese', comment));

-- Índices para otimização das novas colunas
CREATE INDEX IF NOT EXISTS idx_lawyers_kpi_subarea ON public.lawyers USING gin (kpi_subarea);
CREATE INDEX IF NOT EXISTS idx_lawyers_kpi_softskill ON public.lawyers (kpi_softskill);
CREATE INDEX IF NOT EXISTS idx_cases_complexity ON public.cases (complexity);
CREATE INDEX IF NOT EXISTS idx_lawyers_cv_score ON public.lawyers (cv_score);

-- Comentários para documentação
COMMENT ON COLUMN public.lawyers.kpi_subarea IS 'KPI granular por área/subárea no formato {"area/subarea": success_rate}';
COMMENT ON COLUMN public.lawyers.kpi_softskill IS 'Score de soft-skills baseado em análise de sentimento de reviews (0-1)';
COMMENT ON COLUMN public.cases.complexity IS 'Complexidade do caso: LOW, MEDIUM ou HIGH';
COMMENT ON COLUMN public.lawyers.case_outcomes IS 'Array de outcomes de casos históricos [true, false, ...] para case similarity ponderada';
COMMENT ON COLUMN public.lawyers.cv_score IS 'Score do CV baseado em publicações e qualificações (0-1)';

-- Expansão de Features para o Algoritmo LTR v2.2

-- Adiciona a coluna de complexidade na tabela de casos.
-- Esta coluna será usada para selecionar dinamicamente os pesos do LTR.
ALTER TABLE public.cases
ADD COLUMN IF NOT EXISTS complexity TEXT;

COMMENT ON COLUMN public.cases.complexity IS 'Nível de complexidade do caso (LOW, MEDIUM, HIGH) para seleção de pesos LTR.';

-- Adiciona colunas de KPI granulares na tabela de advogados.
ALTER TABLE public.lawyers
ADD COLUMN IF NOT EXISTS kpi_subarea JSONB,
ADD COLUMN IF NOT EXISTS kpi_softskill REAL;

COMMENT ON COLUMN public.lawyers.kpi_subarea IS 'KPIs de taxa de sucesso por subárea jurídica. Ex: {"Direito de Família": 0.85}.';
COMMENT ON COLUMN public.lawyers.kpi_softskill IS 'Score de soft skills (ex: comunicação, empatia) extraído de reviews, entre 0 e 1.';

-- Adiciona um índice para a nova coluna de complexidade para otimizar consultas.
CREATE INDEX IF NOT EXISTS idx_cases_complexity ON public.cases(complexity); 