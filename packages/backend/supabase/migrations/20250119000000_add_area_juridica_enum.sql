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
    'Médico',
    'Startups'
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
        'Aeronáutico', 'Digital', 'Desportivo', 'Médico', 'Startups'
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
-- NOVO: MARCS em Direito Civil
('Civil', 'Arbitragem Cível e Contratual', 'Resolução de disputas cíveis via arbitragem'),
('Civil', 'Mediação e Conciliação Cível', 'Métodos consensuais para resolução de conflitos cíveis'),
('Civil', 'Execução de Sentença Arbitral', 'Procedimentos para executar uma decisão arbitral no judiciário'),
('Civil', 'Dispute Boards em Contratos', 'Conselhos de resolução de disputas em contratos de longa duração'),

-- Família
('Família', 'Divórcio', 'Divórcio judicial e extrajudicial'),
('Família', 'Alimentos', 'Pensão alimentícia'),
('Família', 'Guarda', 'Guarda de menores'),
('Família', 'Adoção', 'Processos de adoção'),
('Família', 'União Estável', 'Reconhecimento e dissolução'),

-- Administrativo
('Administrativo', 'Servidor Público', 'Direitos dos servidores'),
('Administrativo', 'Licitações e Contratos Públicos', 'Processos licitatórios e contratos com o governo'),
('Administrativo', 'Improbidade Administrativa', 'Ações de improbidade'),
-- NOVO: MARCS em Direito Administrativo
('Administrativo', 'Arbitragem com a Administração Pública', 'Resolução de disputas em contratos públicos via arbitragem'),
('Administrativo', 'Mediação em Conflitos Públicos', 'Mediação envolvendo entes públicos e concessionárias'),
('Administrativo', 'Câmaras de Resolução de Conflitos', 'Atuação em câmaras de prevenção e resolução de litígios'),

-- Imobiliário
('Imobiliário', 'Locação', 'Contratos de aluguel e despejo'),
('Imobiliário', 'Compra e Venda', 'Transações imobiliárias'),
('Imobiliário', 'Usucapião', 'Aquisição por usucapião'),
('Imobiliário', 'Condomínio', 'Questões condominiais'),
('Imobiliário', 'Registro', 'Registro de imóveis'),

-- Tributário
('Tributário', 'Planejamento Tributário', 'Estruturação para otimização da carga fiscal'),
('Tributário', 'Contencioso Fiscal', 'Defesas em execuções fiscais e autos de infração'),
('Tributário', 'Tributos em Espécie', 'ICMS, ISS, IRPJ, PIS, COFINS'),
-- NOVO: MARCS em Direito Tributário
('Tributário', 'Transação Tributária', 'Negociação de débitos fiscais com a Fazenda Pública'),
('Tributário', 'Arbitragem Tributária', 'Resolução de conflitos tributários via arbitragem (tendência)'),
('Tributário', 'Mediação Fiscal', 'Mediação de disputas com o fisco'),

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

-- Empresarial
('Empresarial', 'Societário', 'Constituição, M&A, acordos de sócios'),
('Empresarial', 'Contratos Comerciais', 'Contratos de fornecimento, distribuição, etc.'),
('Empresarial', 'Títulos de Crédito', 'Cheques, notas promissórias, duplicatas'),
('Empresarial', 'Falência e Recuperação', 'Processos de recuperação judicial e falência'),
-- NOVO: MARCS em Direito Empresarial
('Empresarial', 'Arbitragem Societária e M&A', 'Disputas sobre acordos de sócios, M&A e apuração de haveres'),
('Empresarial', 'Mediação Empresarial', 'Mediação para conflitos entre sócios, empresas e fornecedores'),
('Empresarial', 'Comitês de Resolução de Disputas', 'Dispute boards em projetos de infraestrutura e construção'),

-- Regulatório
('Regulatório', 'Setor Elétrico', 'Regulação da ANEEL'),
('Regulatório', 'Telecomunicações', 'Regulação da ANATEL'),
('Regulatório', 'Saúde Suplementar', 'Regulação da ANS'),
-- NOVO: MARCS em Direito Regulatório
('Regulatório', 'Arbitragem Setorial', 'Arbitragem em setores regulados (energia, telecom, portos, etc.)'),
('Regulatório', 'Painéis de Resolução de Disputas', 'Dispute boards em projetos de infraestrutura e regulação'),
('Regulatório', 'Mediação com Agências Reguladoras', 'Mediação de conflitos com agências reguladoras');

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