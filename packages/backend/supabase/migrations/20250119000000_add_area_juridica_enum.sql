-- Migration: Add comprehensive legal areas enum
-- Timestamp: 20250119000000
-- Description: Creates area_juridica enum type with all Brazilian legal areas

-- Create the enum type for legal areas
CREATE TYPE public.area_juridica AS ENUM (
    -- Áreas Principais (já existentes)
    'Trabalhista',
    'Civil',
    'Criminal',
    'Tributário',
    'Previdenciário',
    'Consumidor',
    'Família',
    'Empresarial',
    
    -- Direito Público (alta prioridade)
    'Administrativo',
    'Constitucional',
    'Eleitoral',
    
    -- Direito Especializado (alta demanda)
    'Imobiliário',
    'Ambiental',
    'Bancário',
    'Seguros',
    'Saúde',
    'Educacional',
    
    -- Direito Empresarial Especializado
    'Propriedade Intelectual',
    'Concorrencial',
    'Societário',
    'Recuperação Judicial',
    
    -- Direito Internacional e Regulatório
    'Internacional',
    'Regulatório',
    'Telecomunicações',
    'Energia',
    
    -- Direitos Especiais
    'Militar',
    'Agrário',
    'Marítimo',
    'Aeronáutico',
    
    -- Direitos Emergentes
    'Digital',
    'Desportivo',
    'Médico'
);

-- Add comment to document the enum
COMMENT ON TYPE public.area_juridica IS 'Áreas jurídicas suportadas pelo sistema - Cobertura completa do mercado brasileiro';

-- Create a validation function for area mapping
CREATE OR REPLACE FUNCTION validate_area_juridica(area_text TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    -- Check if the text matches any enum value
    RETURN area_text IN (
        'Trabalhista', 'Civil', 'Criminal', 'Tributário', 'Previdenciário',
        'Consumidor', 'Família', 'Empresarial', 'Administrativo', 'Constitucional',
        'Eleitoral', 'Imobiliário', 'Ambiental', 'Bancário', 'Seguros',
        'Saúde', 'Educacional', 'Propriedade Intelectual', 'Concorrencial',
        'Societário', 'Recuperação Judicial', 'Internacional', 'Regulatório',
        'Telecomunicações', 'Energia', 'Militar', 'Agrário', 'Marítimo',
        'Aeronáutico', 'Digital', 'Desportivo', 'Médico'
    );
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Add area validation constraint to cases table
ALTER TABLE public.cases 
ADD CONSTRAINT cases_area_valid 
CHECK (validate_area_juridica(area));

-- Create index for area searches
CREATE INDEX idx_cases_area ON public.cases(area);

-- Create a mapping table for area specializations
CREATE TABLE IF NOT EXISTS public.area_subareas (
    id SERIAL PRIMARY KEY,
    area area_juridica NOT NULL,
    subarea TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(area, subarea)
);

-- Insert common subareas for each legal area
INSERT INTO public.area_subareas (area, subarea, description) VALUES
-- Trabalhista
('Trabalhista', 'Rescisão', 'Casos de rescisão contratual'),
('Trabalhista', 'Justa Causa', 'Demissão por justa causa'),
('Trabalhista', 'Verbas Rescisórias', 'Cálculo e pagamento de verbas'),
('Trabalhista', 'Assédio Moral', 'Casos de assédio no ambiente de trabalho'),
('Trabalhista', 'Acidente de Trabalho', 'Acidentes e doenças ocupacionais'),
('Trabalhista', 'Horas Extras', 'Pagamento de horas extraordinárias'),

-- Criminal
('Criminal', 'Crimes Patrimoniais', 'Roubo, furto, estelionato'),
('Criminal', 'Crimes contra a Vida', 'Homicídio, lesão corporal'),
('Criminal', 'Crimes de Trânsito', 'Infrações penais no trânsito'),
('Criminal', 'Tráfico', 'Tráfico de drogas e entorpecentes'),
('Criminal', 'Crimes Digitais', 'Crimes cibernéticos'),

-- Civil
('Civil', 'Contratos', 'Elaboração e revisão de contratos'),
('Civil', 'Responsabilidade Civil', 'Indenizações e danos'),
('Civil', 'Obrigações', 'Direito das obrigações'),
('Civil', 'Sucessões', 'Inventário e partilha'),
('Civil', 'Direitos Reais', 'Propriedade e posse'),

-- Família
('Família', 'Divórcio', 'Divórcio judicial e extrajudicial'),
('Família', 'Alimentos', 'Pensão alimentícia'),
('Família', 'Guarda', 'Guarda de menores'),
('Família', 'Adoção', 'Processos de adoção'),
('Família', 'União Estável', 'Reconhecimento e dissolução'),

-- Administrativo
('Administrativo', 'Servidor Público', 'Direitos dos servidores'),
('Administrativo', 'Licitações', 'Processos licitatórios'),
('Administrativo', 'Concurso Público', 'Questões de concursos'),
('Administrativo', 'Improbidade', 'Atos de improbidade administrativa'),
('Administrativo', 'Desapropriação', 'Processos expropriatórios'),

-- Imobiliário
('Imobiliário', 'Locação', 'Contratos de aluguel e despejo'),
('Imobiliário', 'Compra e Venda', 'Transações imobiliárias'),
('Imobiliário', 'Usucapião', 'Aquisição por usucapião'),
('Imobiliário', 'Condomínio', 'Questões condominiais'),
('Imobiliário', 'Registro', 'Registro de imóveis'),

-- Tributário
('Tributário', 'Impostos Federais', 'IR, IPI, IOF'),
('Tributário', 'Impostos Estaduais', 'ICMS, IPVA'),
('Tributário', 'Impostos Municipais', 'ISS, IPTU'),
('Tributário', 'Planejamento Tributário', 'Elisão fiscal'),
('Tributário', 'Execução Fiscal', 'Cobranças fiscais'),

-- Bancário
('Bancário', 'Juros Abusivos', 'Revisão de juros'),
('Bancário', 'Negativação Indevida', 'Exclusão de cadastros'),
('Bancário', 'Contratos Bancários', 'Revisão contratual'),
('Bancário', 'Tarifas', 'Cobrança indevida de tarifas'),

-- Digital
('Digital', 'LGPD', 'Proteção de dados pessoais'),
('Digital', 'Crimes Digitais', 'Invasão, fraudes online'),
('Digital', 'E-commerce', 'Comércio eletrônico'),
('Digital', 'Redes Sociais', 'Questões em redes sociais'),
('Digital', 'Propriedade Digital', 'Domínios, conteúdo digital');

-- Add index for subarea searches
CREATE INDEX idx_area_subareas_area ON public.area_subareas(area);
CREATE INDEX idx_area_subareas_subarea ON public.area_subareas(subarea);

-- Grant permissions
GRANT SELECT ON public.area_subareas TO authenticated;
GRANT ALL ON public.area_subareas TO service_role;

-- Add RLS policy
ALTER TABLE public.area_subareas ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Area subareas are viewable by all authenticated users" 
    ON public.area_subareas FOR SELECT 
    TO authenticated 
    USING (true);