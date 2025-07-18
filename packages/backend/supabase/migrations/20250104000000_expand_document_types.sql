-- Migration: Expand document_type enum with comprehensive legal document types
-- Timestamp: 20250104000000
-- Reference: @status.md - ESTRUTURA CONSOLIDADA FINAL DE TIPOS DE DOCUMENTOS

-- =================================================================
-- 1. Adicionar novos valores ao enum document_type existente
-- =================================================================

-- Categoria 1: Documentos Processuais (novos tipos)
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'appeal';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'interlocutory_appeal';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'motion';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'power_of_attorney';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'judicial_decision';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'hearing_document';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'procedural_communication';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'proof_of_filing';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'official_letter';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'expert_report';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'witness_testimony';

-- Categoria 2: Provas e Evidências (novos tipos)
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'medical_report';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'financial_statement';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'forensic_report';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'audit_report';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'photographic_evidence';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'audio_evidence';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'video_evidence';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'digital_evidence';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'evidence_media';

-- Categoria 3: Documentos Contratuais (novos tipos)
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'employment_contract';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'service_agreement';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'insurance_policy';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'lease_agreement';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'purchase_agreement';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'partnership_agreement';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'legal_contract';

-- Categoria 4: Documentos de Identificação (novos tipos)
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'personal_identification';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'proof_of_residence';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'corporate_documents';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'property_deed';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'vehicle_registration';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'income_proof';

-- Categoria 5: Documentos Administrativos (novos tipos)
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'administrative_citation';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'tax_assessment';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'labor_inspection';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'regulatory_decision';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'administrative';

-- Categoria 6: Era Digital e Modernos (novos tipos)
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'electronic_signature';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'blockchain_evidence';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'email_evidence';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'whatsapp_evidence';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'social_media_evidence';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'digital_timestamp';

-- Categoria 7: Documentos Internos do Advogado (novos tipos)
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'legal_analysis';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'research_material';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'draft';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'internal_note';

-- Categoria 8: Financeiros e Comprovantes (novos tipos)
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'financial_document';
ALTER TYPE public.document_type ADD VALUE IF NOT EXISTS 'bank_statement';

-- =================================================================
-- 2. Criar tabela de mapeamento categoria-tipo (para UI)
-- =================================================================

CREATE TABLE IF NOT EXISTS public.document_type_categories (
    id SERIAL PRIMARY KEY,
    category_code VARCHAR(20) NOT NULL,
    category_name VARCHAR(100) NOT NULL,
    category_icon VARCHAR(50) NOT NULL,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Inserir categorias
INSERT INTO public.document_type_categories (category_code, category_name, category_icon, display_order) VALUES
('processual', 'Documentos Processuais', 'gavel', 1),
('probatorio', 'Provas e Evidências', 'description', 2),
('contratual', 'Contratos e Acordos', 'handshake', 3),
('identificacao', 'Identificação e Comprovação', 'badge', 4),
('administrativo', 'Documentos Administrativos', 'business', 5),
('digital', 'Era Digital', 'computer', 6),
('interno', 'Trabalho Interno', 'work', 7),
('financeiro', 'Financeiros e Comprovantes', 'account_balance', 8),
('outros', 'Outros', 'folder', 9)
ON CONFLICT (category_code) DO NOTHING;

-- =================================================================
-- 3. Criar tabela de mapeamento tipo-categoria
-- =================================================================

CREATE TABLE IF NOT EXISTS public.document_type_mappings (
    id SERIAL PRIMARY KEY,
    document_type document_type NOT NULL,
    category_code VARCHAR(20) NOT NULL REFERENCES public.document_type_categories(category_code),
    is_required_for_areas TEXT[] DEFAULT '{}', -- áreas onde é obrigatório
    suggested_for_areas TEXT[] DEFAULT '{}',   -- áreas onde é sugerido
    display_name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(document_type)
);

-- Inserir mapeamentos para Categoria 1: Documentos Processuais
INSERT INTO public.document_type_mappings (document_type, category_code, display_name, description, is_required_for_areas, suggested_for_areas) VALUES
('petition', 'processual', 'Petição', 'Petições iniciais e intermediárias', '{}', '{}'),
('appeal', 'processual', 'Recurso', 'Recursos ordinários, especiais e extraordinários', '{}', '{}'),
('interlocutory_appeal', 'processual', 'Agravo', 'Agravo de instrumento contra decisões interlocutórias', '{}', '{}'),
('motion', 'processual', 'Petição Incidental', 'Requerimentos e petições durante o processo', '{}', '{}'),
('power_of_attorney', 'processual', 'Procuração', 'Procuração para representação processual', '{"Civil","Trabalhista","Criminal"}', '{}'),
('judicial_decision', 'processual', 'Decisão Judicial', 'Sentenças, despachos e acórdãos', '{}', '{}'),
('hearing_document', 'processual', 'Documento de Audiência', 'Atas de audiência e transcrições', '{}', '{}'),
('procedural_communication', 'processual', 'Comunicação Processual', 'Citações, intimações e notificações', '{}', '{}'),
('proof_of_filing', 'processual', 'Comprovante de Protocolo', 'Comprovantes de protocolo de petições', '{}', '{}'),
('official_letter', 'processual', 'Ofício/Mandado', 'Ofícios e mandados judiciais', '{}', '{}'),
('expert_report', 'processual', 'Laudo Pericial', 'Laudos periciais técnicos', '{}', '{"Civil","Trabalhista"}'),
('witness_testimony', 'processual', 'Depoimento', 'Depoimentos e declarações de testemunhas', '{}', '{}')

ON CONFLICT (document_type) DO UPDATE SET
    category_code = EXCLUDED.category_code,
    display_name = EXCLUDED.display_name,
    description = EXCLUDED.description,
    is_required_for_areas = EXCLUDED.is_required_for_areas,
    suggested_for_areas = EXCLUDED.suggested_for_areas;

-- Inserir mapeamentos para Categoria 2: Provas e Evidências
INSERT INTO public.document_type_mappings (document_type, category_code, display_name, description, suggested_for_areas) VALUES
('evidence', 'probatorio', 'Evidência', 'Documentos probatórios gerais', '{}'),
('medical_report', 'probatorio', 'Relatório Médico', 'Relatórios médicos para casos de acidente/INSS', '{"Previdenciário","Civil","Trabalhista"}'),
('financial_statement', 'probatorio', 'Demonstrativo Financeiro', 'Demonstrativos financeiros para casos empresariais', '{"Empresarial","Tributário"}'),
('forensic_report', 'probatorio', 'Laudo Criminal', 'Laudos criminais e periciais forenses', '{"Criminal"}'),
('audit_report', 'probatorio', 'Relatório de Auditoria', 'Relatórios de auditoria fiscal e trabalhista', '{"Tributário","Trabalhista"}'),
('photographic_evidence', 'probatorio', 'Prova Fotográfica', 'Evidências fotográficas', '{}'),
('audio_evidence', 'probatorio', 'Prova Sonora', 'Gravações de áudio como prova', '{}'),
('video_evidence', 'probatorio', 'Prova Audiovisual', 'Gravações de vídeo como prova', '{}'),
('digital_evidence', 'probatorio', 'Evidência Digital', 'Evidências digitais e forenses computacionais', '{}'),
('evidence_media', 'probatorio', 'Mídia Probatória', 'Outras mídias como evidência', '{}')

ON CONFLICT (document_type) DO UPDATE SET
    category_code = EXCLUDED.category_code,
    display_name = EXCLUDED.display_name,
    description = EXCLUDED.description,
    suggested_for_areas = EXCLUDED.suggested_for_areas;

-- Inserir mapeamentos para Categoria 3: Documentos Contratuais
INSERT INTO public.document_type_mappings (document_type, category_code, display_name, description, suggested_for_areas) VALUES
('contract', 'contratual', 'Contrato', 'Contratos gerais', '{}'),
('employment_contract', 'contratual', 'Contrato de Trabalho', 'Contratos de trabalho CLT', '{"Trabalhista"}'),
('service_agreement', 'contratual', 'Acordo de Serviços', 'Contratos de prestação de serviços', '{"Civil","Empresarial"}'),
('insurance_policy', 'contratual', 'Apólice de Seguro', 'Apólices de seguro para sinistros', '{"Civil","Consumidor"}'),
('lease_agreement', 'contratual', 'Contrato de Locação', 'Contratos de locação imobiliária', '{"Civil"}'),
('purchase_agreement', 'contratual', 'Contrato de Compra e Venda', 'Contratos de compra e venda', '{"Civil","Consumidor"}'),
('partnership_agreement', 'contratual', 'Acordo de Parceria', 'Contratos de sociedade e parceria', '{"Empresarial"}'),
('legal_contract', 'contratual', 'Contrato de Honorários', 'Contratos de honorários advocatícios', '{}')

ON CONFLICT (document_type) DO UPDATE SET
    category_code = EXCLUDED.category_code,
    display_name = EXCLUDED.display_name,
    description = EXCLUDED.description,
    suggested_for_areas = EXCLUDED.suggested_for_areas;

-- Inserir mapeamentos para Categoria 4: Documentos de Identificação
INSERT INTO public.document_type_mappings (document_type, category_code, display_name, description, suggested_for_areas) VALUES
('identification', 'identificacao', 'Identificação', 'Documentos de identificação gerais', '{}'),
('personal_identification', 'identificacao', 'Identificação Pessoal', 'RG, CPF, CNH específicos', '{}'),
('proof_of_residence', 'identificacao', 'Comprovante de Residência', 'Comprovantes de residência', '{}'),
('corporate_documents', 'identificacao', 'Documentos Societários', 'Contrato social, atas societárias', '{"Empresarial"}'),
('property_deed', 'identificacao', 'Escritura de Imóvel', 'Escrituras de imóveis', '{"Civil"}'),
('vehicle_registration', 'identificacao', 'Documento de Veículo', 'Documentos de veículos', '{"Civil","Criminal"}'),
('income_proof', 'identificacao', 'Comprovante de Renda', 'Comprovantes de renda para cálculos', '{"Trabalhista","Previdenciário"}')

ON CONFLICT (document_type) DO UPDATE SET
    category_code = EXCLUDED.category_code,
    display_name = EXCLUDED.display_name,
    description = EXCLUDED.description,
    suggested_for_areas = EXCLUDED.suggested_for_areas;

-- Inserir mapeamentos para Categoria 5: Documentos Administrativos
INSERT INTO public.document_type_mappings (document_type, category_code, display_name, description, suggested_for_areas) VALUES
('administrative_citation', 'administrativo', 'Notificação Administrativa', 'Notificações de órgãos administrativos', '{"Administrativo"}'),
('tax_assessment', 'administrativo', 'Auto de Infração Fiscal', 'Autos de infração fiscal', '{"Tributário"}'),
('labor_inspection', 'administrativo', 'Auto de Infração Trabalhista', 'Autos de infração trabalhista', '{"Trabalhista"}'),
('regulatory_decision', 'administrativo', 'Decisão Regulatória', 'Decisões de órgãos reguladores (ANATEL, ANVISA)', '{"Administrativo"}'),
('administrative', 'administrativo', 'Documento Administrativo', 'Documentos administrativos diversos', '{}')

ON CONFLICT (document_type) DO UPDATE SET
    category_code = EXCLUDED.category_code,
    display_name = EXCLUDED.display_name,
    description = EXCLUDED.description,
    suggested_for_areas = EXCLUDED.suggested_for_areas;

-- Inserir mapeamentos para Categoria 6: Era Digital
INSERT INTO public.document_type_mappings (document_type, category_code, display_name, description) VALUES
('electronic_signature', 'digital', 'Assinatura Eletrônica', 'Assinaturas eletrônicas ICP-Brasil'),
('blockchain_evidence', 'digital', 'Prova Blockchain', 'Provas baseadas em blockchain e hash'),
('email_evidence', 'digital', 'Prova de E-mail', 'E-mails como evidência'),
('whatsapp_evidence', 'digital', 'Prova de WhatsApp', 'Conversas de WhatsApp como prova'),
('social_media_evidence', 'digital', 'Prova de Redes Sociais', 'Evidências de redes sociais'),
('digital_timestamp', 'digital', 'Carimbo Temporal', 'Carimbos temporais digitais')

ON CONFLICT (document_type) DO UPDATE SET
    category_code = EXCLUDED.category_code,
    display_name = EXCLUDED.display_name,
    description = EXCLUDED.description;

-- Inserir mapeamentos para Categoria 7: Documentos Internos
INSERT INTO public.document_type_mappings (document_type, category_code, display_name, description) VALUES
('legal_analysis', 'interno', 'Análise Jurídica', 'Pareceres e análises jurídicas'),
('research_material', 'interno', 'Material de Pesquisa', 'Pesquisa doutrinária e jurisprudencial'),
('draft', 'interno', 'Rascunho', 'Rascunhos de documentos'),
('internal_note', 'interno', 'Anotação Interna', 'Anotações internas sobre o caso')

ON CONFLICT (document_type) DO UPDATE SET
    category_code = EXCLUDED.category_code,
    display_name = EXCLUDED.display_name,
    description = EXCLUDED.description;

-- Inserir mapeamentos para Categoria 8: Financeiros
INSERT INTO public.document_type_mappings (document_type, category_code, display_name, description, suggested_for_areas) VALUES
('receipt', 'financeiro', 'Recibo', 'Recibos e comprovantes de pagamento', '{}'),
('financial_document', 'financeiro', 'Documento Financeiro', 'Extratos, holerites e documentos financeiros', '{"Trabalhista","Previdenciário"}'),
('bank_statement', 'financeiro', 'Extrato Bancário', 'Extratos bancários específicos', '{"Trabalhista","Empresarial"}')

ON CONFLICT (document_type) DO UPDATE SET
    category_code = EXCLUDED.category_code,
    display_name = EXCLUDED.display_name,
    description = EXCLUDED.description,
    suggested_for_areas = EXCLUDED.suggested_for_areas;

-- Inserir mapeamento para Outros
INSERT INTO public.document_type_mappings (document_type, category_code, display_name, description) VALUES
('other', 'outros', 'Outro', 'Documentos não categorizados')

ON CONFLICT (document_type) DO UPDATE SET
    category_code = EXCLUDED.category_code,
    display_name = EXCLUDED.display_name,
    description = EXCLUDED.description;

-- =================================================================
-- 4. Criar função para buscar tipos por categoria
-- =================================================================

CREATE OR REPLACE FUNCTION get_document_types_by_category(p_category_code VARCHAR DEFAULT NULL)
RETURNS TABLE (
    document_type document_type,
    category_code VARCHAR,
    category_name VARCHAR,
    category_icon VARCHAR,
    display_name VARCHAR,
    description TEXT,
    is_required_for_areas TEXT[],
    suggested_for_areas TEXT[]
) 
LANGUAGE SQL
AS $$
    SELECT 
        m.document_type,
        m.category_code,
        c.category_name,
        c.category_icon,
        m.display_name,
        m.description,
        m.is_required_for_areas,
        m.suggested_for_areas
    FROM public.document_type_mappings m
    JOIN public.document_type_categories c ON m.category_code = c.category_code
    WHERE (p_category_code IS NULL OR m.category_code = p_category_code)
    ORDER BY c.display_order, m.display_name;
$$;

-- =================================================================
-- 5. Criar função para sugerir tipos por área do caso
-- =================================================================

CREATE OR REPLACE FUNCTION suggest_document_types_for_case_area(p_case_area VARCHAR)
RETURNS TABLE (
    document_type document_type,
    display_name VARCHAR,
    description TEXT,
    is_required BOOLEAN,
    category_name VARCHAR
) 
LANGUAGE SQL
AS $$
    SELECT 
        m.document_type,
        m.display_name,
        m.description,
        (p_case_area = ANY(m.is_required_for_areas)) as is_required,
        c.category_name
    FROM public.document_type_mappings m
    JOIN public.document_type_categories c ON m.category_code = c.category_code
    WHERE 
        p_case_area = ANY(m.is_required_for_areas) 
        OR p_case_area = ANY(m.suggested_for_areas)
    ORDER BY 
        (p_case_area = ANY(m.is_required_for_areas)) DESC,
        c.display_order,
        m.display_name;
$$;

-- =================================================================
-- 6. Atualizar comentários e grants
-- =================================================================

COMMENT ON TABLE public.document_type_categories IS 'Categorias de tipos de documentos para organização da UI';
COMMENT ON TABLE public.document_type_mappings IS 'Mapeamento entre tipos de documentos e suas categorias, com sugestões por área jurídica';

COMMENT ON FUNCTION get_document_types_by_category(VARCHAR) IS 'Retorna tipos de documentos organizados por categoria';
COMMENT ON FUNCTION suggest_document_types_for_case_area(VARCHAR) IS 'Sugere tipos de documentos baseado na área do caso';

-- Grants para as funções e tabelas
GRANT SELECT ON public.document_type_categories TO authenticated;
GRANT SELECT ON public.document_type_mappings TO authenticated;
GRANT EXECUTE ON FUNCTION get_document_types_by_category(VARCHAR) TO authenticated;
GRANT EXECUTE ON FUNCTION suggest_document_types_for_case_area(VARCHAR) TO authenticated; 