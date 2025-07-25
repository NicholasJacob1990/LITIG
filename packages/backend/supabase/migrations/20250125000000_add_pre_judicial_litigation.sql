-- Migration: Add Pre-Judicial Administrative Litigation Support
-- Timestamp: 20250125000000  
-- Description: Adds support for pre-judicial administrative litigation including PROCON, CARF, regulatory agencies

-- Add new document types for pre-judicial processes
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'procon_complaint';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'carf_appeal';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'tax_council_appeal';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'administrative_defense';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'administrative_appeal';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'anatel_process';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'anvisa_process';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'aneel_process';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'anp_process';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'ancine_process';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'anac_process';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'regulatory_agency_process';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'federal_tax_process';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'state_tax_process';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'municipal_tax_process';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'administrative_tribunal';

-- Create enum for pre-judicial case types
CREATE TYPE public.pre_judicial_case_type AS ENUM (
    'administrative_litigation',
    'regulatory_litigation', 
    'tax_administrative'
);

-- Add comment to document the enum
COMMENT ON TYPE public.pre_judicial_case_type IS 'Tipos de casos de contencioso pré-judicial administrativo';

-- Insert new subareas for administrative pre-judicial litigation
INSERT INTO public.area_subareas (area, subarea, description) VALUES
-- Administrative Pre-Judicial Litigation
('Administrativo', 'PROCON', 'Processos administrativos no PROCON'),
('Administrativo', 'CARF', 'Conselho Administrativo de Recursos Fiscais'),
('Administrativo', 'Conselhos de Contribuintes', 'Conselhos de contribuintes estaduais e municipais'),
('Administrativo', 'ANATEL', 'Agência Nacional de Telecomunicações'),
('Administrativo', 'ANVISA', 'Agência Nacional de Vigilância Sanitária'),
('Administrativo', 'ANEEL', 'Agência Nacional de Energia Elétrica'),
('Administrativo', 'ANP', 'Agência Nacional do Petróleo'),
('Administrativo', 'ANCINE', 'Agência Nacional do Cinema'),
('Administrativo', 'ANAC', 'Agência Nacional de Aviação Civil'),
('Administrativo', 'ANTAQ', 'Agência Nacional de Transportes Aquaviários'),
('Administrativo', 'ANTT', 'Agência Nacional de Transportes Terrestres'),
('Administrativo', 'ANS', 'Agência Nacional de Saúde Suplementar'),
('Administrativo', 'ANA', 'Agência Nacional de Águas'),
('Administrativo', 'Processo Administrativo', 'Processos administrativos gerais'),
('Administrativo', 'Tribunal Administrativo', 'Tribunais administrativos diversos'),

-- Tax Administrative Pre-Judicial
('Tributário', 'CARF Federal', 'Conselho Administrativo de Recursos Fiscais - União'),
('Tributário', 'Conselho de Contribuintes Estadual', 'Conselhos de contribuintes dos estados'),
('Tributário', 'Conselho de Contribuintes Municipal', 'Conselhos de contribuintes dos municípios'),
('Tributário', 'Processo Administrativo Fiscal', 'Processos administrativos fiscais'),
('Tributário', 'Receita Federal', 'Procedimentos na Receita Federal'),
('Tributário', 'Receita Estadual', 'Procedimentos nas receitas estaduais'),
('Tributário', 'Receita Municipal', 'Procedimentos nas receitas municipais')

ON CONFLICT (area, subarea) DO UPDATE SET
    description = EXCLUDED.description;

-- Create index for pre-judicial case searches
CREATE INDEX IF NOT EXISTS idx_area_subareas_pre_judicial 
ON public.area_subareas(area) 
WHERE subarea IN ('PROCON', 'CARF', 'ANATEL', 'ANVISA', 'ANEEL', 'ANP', 'ANCINE', 'ANAC', 'ANTAQ', 'ANTT', 'ANS', 'ANA');

-- Update cases table to support pre-judicial case types
ALTER TABLE public.cases 
ADD COLUMN IF NOT EXISTS pre_judicial_type pre_judicial_case_type,
ADD COLUMN IF NOT EXISTS administrative_organ TEXT,
ADD COLUMN IF NOT EXISTS process_number TEXT,
ADD COLUMN IF NOT EXISTS deadline_date TIMESTAMP WITH TIME ZONE;

-- Create indexes for new columns
CREATE INDEX IF NOT EXISTS idx_cases_pre_judicial_type ON public.cases(pre_judicial_type);
CREATE INDEX IF NOT EXISTS idx_cases_administrative_organ ON public.cases(administrative_organ);
CREATE INDEX IF NOT EXISTS idx_cases_process_number ON public.cases(process_number);
CREATE INDEX IF NOT EXISTS idx_cases_deadline_date ON public.cases(deadline_date);

-- Add comments for documentation
COMMENT ON COLUMN public.cases.pre_judicial_type IS 'Tipo específico de contencioso pré-judicial';
COMMENT ON COLUMN public.cases.administrative_organ IS 'Órgão administrativo responsável (PROCON, CARF, ANATEL, etc.)';
COMMENT ON COLUMN public.cases.process_number IS 'Número do processo administrativo';
COMMENT ON COLUMN public.cases.deadline_date IS 'Data limite para manifestação ou recurso';

-- Create function to automatically set pre_judicial_type based on area/subarea
CREATE OR REPLACE FUNCTION set_pre_judicial_type()
RETURNS TRIGGER AS $$
BEGIN
    -- Set pre_judicial_type based on subarea
    IF NEW.subarea IN ('PROCON', 'CARF', 'Conselhos de Contribuintes', 'Processo Administrativo', 'Tribunal Administrativo') THEN
        NEW.pre_judicial_type = 'administrative_litigation';
    ELSIF NEW.subarea IN ('ANATEL', 'ANVISA', 'ANEEL', 'ANP', 'ANCINE', 'ANAC', 'ANTAQ', 'ANTT', 'ANS', 'ANA') THEN
        NEW.pre_judicial_type = 'regulatory_litigation';
    ELSIF NEW.subarea IN ('CARF Federal', 'Conselho de Contribuintes Estadual', 'Conselho de Contribuintes Municipal', 
                          'Processo Administrativo Fiscal', 'Receita Federal', 'Receita Estadual', 'Receita Municipal') THEN
        NEW.pre_judicial_type = 'tax_administrative';
    END IF;
    
    -- Set administrative_organ based on subarea
    CASE 
        WHEN NEW.subarea = 'PROCON' THEN NEW.administrative_organ = 'PROCON';
        WHEN NEW.subarea = 'CARF' OR NEW.subarea = 'CARF Federal' THEN NEW.administrative_organ = 'CARF';
        WHEN NEW.subarea = 'ANATEL' THEN NEW.administrative_organ = 'ANATEL';
        WHEN NEW.subarea = 'ANVISA' THEN NEW.administrative_organ = 'ANVISA';
        WHEN NEW.subarea = 'ANEEL' THEN NEW.administrative_organ = 'ANEEL';
        WHEN NEW.subarea = 'ANP' THEN NEW.administrative_organ = 'ANP';
        WHEN NEW.subarea = 'ANCINE' THEN NEW.administrative_organ = 'ANCINE';
        WHEN NEW.subarea = 'ANAC' THEN NEW.administrative_organ = 'ANAC';
        WHEN NEW.subarea = 'ANTAQ' THEN NEW.administrative_organ = 'ANTAQ';
        WHEN NEW.subarea = 'ANTT' THEN NEW.administrative_organ = 'ANTT';
        WHEN NEW.subarea = 'ANS' THEN NEW.administrative_organ = 'ANS';
        WHEN NEW.subarea = 'ANA' THEN NEW.administrative_organ = 'ANA';
        WHEN NEW.subarea LIKE '%Receita Federal%' THEN NEW.administrative_organ = 'Receita Federal';
        WHEN NEW.subarea LIKE '%Receita Estadual%' THEN NEW.administrative_organ = 'Receita Estadual';
        WHEN NEW.subarea LIKE '%Receita Municipal%' THEN NEW.administrative_organ = 'Receita Municipal';
        WHEN NEW.subarea LIKE '%Conselho de Contribuintes%' THEN NEW.administrative_organ = 'Conselho de Contribuintes';
        ELSE NEW.administrative_organ = NULL;
    END CASE;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically set pre_judicial_type
CREATE TRIGGER trigger_set_pre_judicial_type
    BEFORE INSERT OR UPDATE ON public.cases
    FOR EACH ROW
    EXECUTE FUNCTION set_pre_judicial_type();

-- Create view for pre-judicial cases analytics
CREATE OR REPLACE VIEW public.pre_judicial_cases_summary AS
SELECT 
    pre_judicial_type,
    administrative_organ,
    COUNT(*) as total_cases,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_cases,
    COUNT(CASE WHEN deadline_date < NOW() AND status != 'completed' THEN 1 END) as overdue_cases,
    AVG(EXTRACT(EPOCH FROM (completed_at - created_at))/86400) as avg_days_to_complete
FROM public.cases 
WHERE pre_judicial_type IS NOT NULL
GROUP BY pre_judicial_type, administrative_organ;

COMMENT ON VIEW public.pre_judicial_cases_summary IS 'Resumo analítico de casos de contencioso pré-judicial por tipo e órgão';

-- Insert sample data for development/testing
DO $$
BEGIN
    -- Only insert if in development environment
    IF current_setting('app.environment', true) = 'development' THEN
        INSERT INTO public.cases (
            id, area, subarea, summary, pre_judicial_type, administrative_organ, process_number,
            created_at, updated_at
        ) VALUES 
        (
            gen_random_uuid(),
            'Administrativo',
            'PROCON',
            'Reclamação sobre produto defeituoso não resolvida pela empresa',
            'administrative_litigation',
            'PROCON',
            'PROCON-2025-001234',
            NOW() - INTERVAL '5 days',
            NOW()
        ),
        (
            gen_random_uuid(),
            'Tributário', 
            'CARF Federal',
            'Recurso contra auto de infração da Receita Federal',
            'tax_administrative',
            'CARF',
            'CARF-2025-005678',
            NOW() - INTERVAL '10 days', 
            NOW()
        ),
        (
            gen_random_uuid(),
            'Administrativo',
            'ANATEL',
            'Contestação de multa por descumprimento de regulamento',
            'regulatory_litigation',
            'ANATEL',
            'ANATEL-2025-009876',
            NOW() - INTERVAL '3 days',
            NOW()
        ) ON CONFLICT (id) DO NOTHING;
    END IF;
END $$; 
 