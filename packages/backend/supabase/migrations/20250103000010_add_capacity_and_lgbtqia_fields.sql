-- Adicionar campo para capacidade de trabalho na tabela lawyers
ALTER TABLE public.lawyers
ADD COLUMN IF NOT EXISTS max_concurrent_cases INTEGER DEFAULT 10;

COMMENT ON COLUMN public.lawyers.max_concurrent_cases IS 'Número máximo de casos que o advogado pode atender simultaneamente.';

-- Adicionar campo para orientação sexual/identidade de gênero na tabela profiles, se não existir
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'profiles' AND column_name = 'lgbtqia'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN lgbtqia BOOLEAN DEFAULT FALSE;
        COMMENT ON COLUMN public.profiles.lgbtqia IS 'Indica se o usuário se identifica como parte da comunidade LGBTQIA+ (opcional)';
    END IF;
END $$; 