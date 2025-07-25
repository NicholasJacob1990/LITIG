-- Migration: Add Complete Startup Law Support
-- Timestamp: 20250125000001  
-- Description: Comprehensive implementation of Startup Law ecosystem in Brazil

-- Add new document types for startup ecosystem
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'term_sheet';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'sha_agreement';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'investment_agreement';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'stock_option_plan';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'vesting_schedule';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'cap_table';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'due_diligence_report';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'saas_agreement';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'api_license';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'development_agreement';

-- Add new case types for startup-specific workflows
ALTER TYPE public.case_type ADD VALUE IF NOT EXISTS 'startup_funding';
ALTER TYPE public.case_type ADD VALUE IF NOT EXISTS 'startup_corporate';
ALTER TYPE public.case_type ADD VALUE IF NOT EXISTS 'startup_compliance';

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_cases_startup_area ON public.cases(legal_area) WHERE legal_area = 'Startups';
CREATE INDEX IF NOT EXISTS idx_documents_startup_type ON public.documents(document_type) WHERE document_type IN (
    'term_sheet', 'sha_agreement', 'investment_agreement', 'stock_option_plan'
);

-- Update case type mappings for startup ecosystem
INSERT INTO public.case_type_mappings (legal_area, case_type, priority, description) VALUES
('Startups', 'startup_funding', 1, 'Casos relacionados a investimentos e captação de recursos'),
('Startups', 'startup_corporate', 2, 'Estruturação societária e governança corporativa'),
('Startups', 'startup_compliance', 3, 'Adequação regulatória e compliance específico'),
('Startups', 'corporate', 4, 'Direito societário geral aplicado a startups'),
('Startups', 'ma', 5, 'Fusões, aquisições e exit strategies'),
('Startups', 'contract', 6, 'Contratos tecnológicos e comerciais'),
('Startups', 'compliance', 7, 'Compliance regulatório geral'),
('Startups', 'ip', 8, 'Propriedade intelectual e tecnologia'),
('Startups', 'consultancy', 9, 'Consultoria estratégica e preventiva')
ON CONFLICT (legal_area, case_type) DO UPDATE SET
    priority = EXCLUDED.priority,
    description = EXCLUDED.description;

-- Create startup-specific metadata table
CREATE TABLE IF NOT EXISTS public.startup_case_metadata (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id UUID REFERENCES public.cases(id) ON DELETE CASCADE,
    funding_stage TEXT CHECK (funding_stage IN ('pre_seed', 'seed', 'series_a', 'series_b', 'series_c', 'ipo', 'exit')),
    company_valuation DECIMAL,
    investment_amount DECIMAL,
    investors_count INTEGER DEFAULT 0,
    regulatory_sector TEXT, -- fintech, healthtech, edtech, etc.
    compliance_requirements TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT unique_case_startup_metadata UNIQUE (case_id)
);

-- Create indexes for startup metadata
CREATE INDEX IF NOT EXISTS idx_startup_metadata_stage ON public.startup_case_metadata(funding_stage);
CREATE INDEX IF NOT EXISTS idx_startup_metadata_sector ON public.startup_case_metadata(regulatory_sector);

-- Add triggers for updated_at
CREATE OR REPLACE FUNCTION public.update_startup_metadata_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_startup_metadata_updated_at
    BEFORE UPDATE ON public.startup_case_metadata
    FOR EACH ROW
    EXECUTE FUNCTION public.update_startup_metadata_updated_at();

-- Insert sample startup document categories
INSERT INTO public.document_categories (code, name, description, applicable_areas) VALUES
('startup_investment', 'Investimentos Startup', 'Documentos relacionados a investimentos e captação', '{"Startups"}'),
('startup_corporate', 'Societário Startup', 'Estruturação societária e governança de startups', '{"Startups"}'),
('startup_tech', 'Contratos Tech', 'Contratos tecnológicos e propriedade intelectual', '{"Startups"}'),
('startup_regulatory', 'Regulatório Startup', 'Compliance e adequação regulatória específica', '{"Startups"}')
ON CONFLICT (code) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    applicable_areas = EXCLUDED.applicable_areas;

-- Update document type mappings for startups
UPDATE public.document_type_mappings 
SET applicable_areas = applicable_areas || '{"Startups"}'::jsonb
WHERE type_key IN ('contract', 'corporate_docs', 'compliance_docs', 'ip_docs');

-- Add startup-specific urgency rules
INSERT INTO public.urgency_rules (legal_area, subarea, default_urgency, factors, created_at) VALUES
('Startups', 'Investimentos e Venture Capital', 'HIGH', 
 '{"time_sensitive": true, "investor_deadlines": true, "market_window": true}', NOW()),
('Startups', 'Exit Strategy', 'URGENT', 
 '{"ipo_timeline": true, "ma_deadlines": true, "regulatory_approval": true}', NOW()),
('Startups', 'Compliance e Regulatório', 'HIGH', 
 '{"regulatory_deadlines": true, "sandbox_application": true, "cvm_deadlines": true}', NOW())
ON CONFLICT (legal_area, subarea) DO UPDATE SET
    default_urgency = EXCLUDED.default_urgency,
    factors = EXCLUDED.factors,
    updated_at = NOW();

-- Performance optimization: Create materialized view for startup analytics
CREATE MATERIALIZED VIEW IF NOT EXISTS public.startup_cases_analytics AS
SELECT 
    s.regulatory_sector,
    s.funding_stage,
    c.legal_area,
    c.subarea,
    COUNT(*) as case_count,
    AVG(c.urgency_score) as avg_urgency,
    AVG(EXTRACT(EPOCH FROM (c.resolved_at - c.created_at))/3600) as avg_resolution_hours
FROM public.cases c
JOIN public.startup_case_metadata s ON c.id = s.case_id
WHERE c.legal_area = 'Startups'
GROUP BY s.regulatory_sector, s.funding_stage, c.legal_area, c.subarea;

-- Create refresh function for analytics
CREATE OR REPLACE FUNCTION public.refresh_startup_analytics()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW public.startup_cases_analytics;
END;
$$ LANGUAGE plpgsql;

-- Schedule automatic refresh (requires pg_cron extension)
-- SELECT cron.schedule('refresh-startup-analytics', '0 */6 * * *', 'SELECT public.refresh_startup_analytics();');

COMMENT ON TABLE public.startup_case_metadata IS 'Metadados específicos para casos de startups incluindo estágio de funding e setor regulatório';
COMMENT ON MATERIALIZED VIEW public.startup_cases_analytics IS 'View materializada para analytics de casos de startups por setor e estágio'; 
 