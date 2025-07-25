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
('administrative', 'administrativo', 'Documento Administrativo', 'Documentos administrativos diversos', '{}'),

-- NOVO: Documentos específicos para contencioso pré-judicial
('procon_complaint', 'administrativo', 'Reclamação PROCON', 'Reclamações e processos no PROCON', '{"Consumidor", "Administrativo"}'),
('carf_appeal', 'administrativo', 'Recurso CARF', 'Recursos no Conselho Administrativo de Recursos Fiscais', '{"Tributário", "Administrativo"}'),
('tax_council_appeal', 'administrativo', 'Recurso Conselho de Contribuintes', 'Recursos em conselhos de contribuintes estaduais/municipais', '{"Tributário", "Administrativo"}'),
('administrative_defense', 'administrativo', 'Defesa Administrativa', 'Defesas em processos administrativos', '{"Administrativo"}'),
('administrative_appeal', 'administrativo', 'Recurso Administrativo', 'Recursos administrativos diversos', '{"Administrativo"}'),
('anatel_process', 'administrativo', 'Processo ANATEL', 'Processos na Agência Nacional de Telecomunicações', '{"Regulatório", "Administrativo"}'),
('anvisa_process', 'administrativo', 'Processo ANVISA', 'Processos na Agência Nacional de Vigilância Sanitária', '{"Regulatório", "Administrativo"}'),
('aneel_process', 'administrativo', 'Processo ANEEL', 'Processos na Agência Nacional de Energia Elétrica', '{"Regulatório", "Administrativo"}'),
('anp_process', 'administrativo', 'Processo ANP', 'Processos na Agência Nacional do Petróleo', '{"Regulatório", "Administrativo"}'),
('ancine_process', 'administrativo', 'Processo ANCINE', 'Processos na Agência Nacional do Cinema', '{"Regulatório", "Administrativo"}'),
('anac_process', 'administrativo', 'Processo ANAC', 'Processos na Agência Nacional de Aviação Civil', '{"Regulatório", "Administrativo"}'),
('regulatory_agency_process', 'administrativo', 'Processo Agência Reguladora', 'Processos em agências reguladoras diversas', '{"Regulatório", "Administrativo"}'),
('federal_tax_process', 'administrativo', 'Processo Receita Federal', 'Processos na Receita Federal do Brasil', '{"Tributário", "Administrativo"}'),
('state_tax_process', 'administrativo', 'Processo Receita Estadual', 'Processos em receitas estaduais', '{"Tributário", "Administrativo"}'),
('municipal_tax_process', 'administrativo', 'Processo Receita Municipal', 'Processos em receitas municipais', '{"Tributário", "Administrativo"}'),
('administrative_tribunal', 'administrativo', 'Processo Tribunal Administrativo', 'Processos em tribunais administrativos', '{"Administrativo"}'),

-- NOVO: Documentos específicos para Direito Digital expandido
('marco_civil_violation', 'digital', 'Violação Marco Civil', 'Violações do Marco Civil da Internet', '{"Digital"}'),
('image_rights_violation', 'digital', 'Violação Direito de Imagem Digital', 'Uso indevido de imagem na internet', '{"Digital"}'),
('digital_contract', 'digital', 'Contrato Digital', 'Contratos eletrônicos e assinaturas digitais', '{"Digital"}'),
('cybersecurity_incident', 'digital', 'Incidente de Cibersegurança', 'Vazamentos e incidentes de segurança', '{"Digital"}'),
('cryptocurrency_transaction', 'digital', 'Transação Criptomoeda', 'Operações com Bitcoin, NFTs e ativos digitais', '{"Digital"}'),
('content_removal_request', 'digital', 'Solicitação Remoção Conteúdo', 'Direito ao esquecimento e remoção de conteúdo', '{"Digital"}'),
('fake_news_evidence', 'digital', 'Evidência Fake News', 'Provas de notícias falsas e desinformação', '{"Digital"}'),
('cyberbullying_evidence', 'digital', 'Evidência Cyberbullying', 'Provas de assédio e violência digital', '{"Digital"}'),
('digital_piracy_evidence', 'digital', 'Evidência Pirataria Digital', 'Provas de violação de direitos autorais online', '{"Digital"}'),
('online_gambling_complaint', 'digital', 'Reclamação Jogos Online', 'Questões com jogos e apostas online', '{"Digital"}')

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

-- NOVO: Documentos específicos para Direito do Consumidor expandido
('product_defect_report', 'probatorio', 'Laudo Vício Produto', 'Laudos técnicos de defeitos em produtos', '{"Consumidor"}'),
('service_defect_report', 'probatorio', 'Laudo Vício Serviço', 'Relatórios de falhas na prestação de serviços', '{"Consumidor"}'),
('misleading_advertising', 'probatorio', 'Propaganda Enganosa', 'Evidências de publicidade falsa ou enganosa', '{"Consumidor"}'),
('abusive_advertising', 'probatorio', 'Propaganda Abusiva', 'Evidências de publicidade abusiva', '{"Consumidor"}'),
('credit_database_report', 'administrativo', 'Relatório SPC/Serasa', 'Extratos de cadastros de proteção ao crédito', '{"Consumidor"}'),
('health_plan_denial', 'administrativo', 'Negativa Plano Saúde', 'Negativas de cobertura de planos de saúde', '{"Consumidor"}'),
('telecom_complaint', 'administrativo', 'Reclamação Telecomunicações', 'Reclamações sobre telefonia e internet', '{"Consumidor"}'),
('bank_fee_dispute', 'administrativo', 'Contestação Tarifa Bancária', 'Questionamentos de tarifas bancárias', '{"Consumidor"}'),
('debt_renegotiation', 'contratual', 'Renegociação Dívidas', 'Documentos de renegociação por superendividamento', '{"Consumidor"}'),
('ecommerce_dispute', 'administrativo', 'Disputa E-commerce', 'Problemas com compras online e marketplaces', '{"Consumidor"}'),
('public_service_complaint', 'administrativo', 'Reclamação Serviço Público', 'Reclamações sobre água, luz, gás', '{"Consumidor"}'),
('insurance_claim_denial', 'administrativo', 'Negativa Seguro', 'Negativas de indenização de seguradoras', '{"Consumidor"}'),
('transport_complaint', 'administrativo', 'Reclamação Transporte', 'Problemas com transporte público e aplicativos', '{"Consumidor"}'),
('food_safety_complaint', 'probatorio', 'Reclamação Segurança Alimentar', 'Problemas com restaurantes e delivery', '{"Consumidor"}'),
('education_complaint', 'administrativo', 'Reclamação Educação', 'Problemas com instituições de ensino', '{"Consumidor"}'),
('tourism_complaint', 'administrativo', 'Reclamação Turismo', 'Problemas com viagens e agências', '{"Consumidor"}'),
('vehicle_defect_report', 'probatorio', 'Defeito Veículo', 'Problemas com automóveis e concessionárias', '{"Consumidor"}'),
('real_estate_consumer_dispute', 'administrativo', 'Disputa Imobiliária Consumidor', 'Problemas com construtoras e imobiliárias', '{"Consumidor"}'),
('credit_card_fraud', 'administrativo', 'Fraude Cartão Crédito', 'Fraudes e problemas com cartões', '{"Consumidor"}'),
('abusive_loan', 'administrativo', 'Empréstimo Abusivo', 'Financiamentos e empréstimos com juros abusivos', '{"Consumidor"}'),

-- NOVO: Documentos específicos para Direitos das Startups
('term_sheet', 'contratual', 'Term Sheet', 'Proposta de investimento e condições preliminares', '{"Startups"}'),
('sha_agreement', 'contratual', 'Shareholders Agreement', 'Acordo de acionistas e governança', '{"Startups"}'),
('investment_agreement', 'contratual', 'Investment Agreement', 'Contrato de investimento definitivo', '{"Startups"}'),
('stock_option_plan', 'contratual', 'Stock Option Plan', 'Plano de opções de compra de ações', '{"Startups"}'),
('vesting_schedule', 'contratual', 'Cronograma Vesting', 'Cronograma de aquisição de equity', '{"Startups"}'),
('board_resolution', 'administrativo', 'Ata Conselho Administração', 'Deliberações do conselho de administração', '{"Startups"}'),
('cap_table', 'contratual', 'Cap Table', 'Tabela de capitalização societária', '{"Startups"}'),
('due_diligence_report', 'probatorio', 'Relatório Due Diligence', 'Relatório de auditoria legal para investimento', '{"Startups"}'),
('pitch_deck', 'administrativo', 'Pitch Deck', 'Apresentação para investidores', '{"Startups"}'),
('saas_agreement', 'contratual', 'Contrato SaaS', 'Software as a Service agreement', '{"Startups"}'),
('api_license', 'contratual', 'Licença API', 'Contrato de licenciamento de API', '{"Startups"}'),
('development_agreement', 'contratual', 'Development Agreement', 'Contrato de desenvolvimento de software', '{"Startups"}'),
('nda_startup', 'contratual', 'NDA Startup', 'Acordo de confidencialidade para startups', '{"Startups"}'),
('acceleration_contract', 'contratual', 'Contrato Aceleração', 'Contrato com aceleradora ou incubadora', '{"Startups"}'),
('corporate_venture_agreement', 'contratual', 'Corporate Venture Agreement', 'Acordo de corporate venture capital', '{"Startups"}'),
('crowdfunding_terms', 'administrativo', 'Termos Crowdfunding', 'Condições de financiamento coletivo', '{"Startups"}'),
('startup_legal_compliance', 'administrativo', 'Compliance Startup', 'Documentos de adequação regulatória', '{"Startups"}'),
('sandbox_application', 'administrativo', 'Sandbox Regulatório', 'Aplicação para sandbox regulatório', '{"Startups"}'),
('patent_application_tech', 'administrativo', 'Pedido Patente Tech', 'Pedido de patente para tecnologia', '{"Startups"}'),
('trademark_tech', 'administrativo', 'Marca Tecnológica', 'Registro de marca para empresa tech', '{"Startups"}'),
('software_license', 'contratual', 'Licença Software', 'Contrato de licenciamento de software', '{"Startups"}'),
('exit_strategy_plan', 'administrativo', 'Plano Exit Strategy', 'Planejamento de saída e liquidez', '{"Startups"}'),
('ipo_documentation', 'administrativo', 'Documentação IPO', 'Documentos para oferta pública inicial', '{"Startups"}'),
('ma_term_sheet', 'contratual', 'Term Sheet M&A', 'Proposta de fusão ou aquisição', '{"Startups"}'),
('employee_stock_option', 'contratual', 'Stock Option Funcionário', 'Concessão de opções para funcionários', '{"Startups"}'),
('advisor_agreement', 'contratual', 'Acordo Advisor', 'Contrato com consultores e advisors', '{"Startups"}'),
('joint_venture_startup', 'contratual', 'Joint Venture Startup', 'Parceria estratégica entre startups', '{"Startups"}'),
('fintech_compliance', 'administrativo', 'Compliance Fintech', 'Adequação regulatória para fintechs', '{"Startups"}'),
('healthtech_anvisa', 'administrativo', 'Registro ANVISA', 'Documentação para healthtechs na ANVISA', '{"Startups"}'),
('international_expansion_docs', 'administrativo', 'Expansão Internacional', 'Documentos para expansão global', '{"Startups"}'),
('esg_startup_report', 'administrativo', 'Relatório ESG Startup', 'Relatório de sustentabilidade e impacto', '{"Startups"}'),

-- NOVO: Documentos específicos para MARCS (Arbitragem, Mediação, etc.)
('arbitration_agreement', 'contratual', 'Convenção de Arbitragem', 'Cláusula compromissória ou compromisso arbitral', '{"Civil", "Empresarial", "Administrativo", "Regulatório"}'),
('request_for_arbitration', 'processual', 'Requerimento de Arbitragem', 'Documento que inicia o procedimento arbitral', '{"Civil", "Empresarial", "Administrativo", "Regulatório"}'),
('statement_of_claim_arbitration', 'processual', 'Petição Inicial (Arbitragem)', 'Argumentos e pedidos da parte demandante na arbitragem', '{"Civil", "Empresarial", "Administrativo", "Regulatório"}'),
('statement_of_defense_arbitration', 'processual', 'Contestação (Arbitragem)', 'Defesa e pedidos da parte demandada na arbitragem', '{"Civil", "Empresarial", "Administrativo", "Regulatório"}'),
('arbitral_award', 'processual', 'Sentença Arbitral', 'Decisão final proferida pelo tribunal arbitral', '{"Civil", "Empresarial", "Administrativo", "Regulatório"}'),
('request_for_annulment_award', 'processual', 'Pedido de Anulação de Sentença', 'Ação judicial para anular uma sentença arbitral', '{"Civil", "Empresarial"}'),
('request_for_enforcement_award', 'processual', 'Pedido de Cumprimento de Sentença', 'Ação para executar uma sentença arbitral na justiça', '{"Civil", "Empresarial"}'),
('mediation_agreement', 'contratual', 'Termo de Mediação', 'Contrato que estabelece as regras da mediação', '{"Civil", "Empresarial", "Tributário", "Administrativo"}'),
('mediated_settlement', 'contratual', 'Acordo de Mediação', 'Acordo final alcançado pelas partes na mediação', '{"Civil", "Empresarial", "Tributário", "Administrativo"}'),
('conciliation_term', 'contratual', 'Termo de Conciliação', 'Acordo final alcançado na conciliação', '{"Civil", "Empresarial", "Tributário"}'),
('tax_transaction_agreement', 'contratual', 'Termo de Transação Tributária', 'Acordo com o fisco para pagamento de débitos', '{"Tributário"}'),
('dispute_board_report', 'probatorio', 'Relatório Dispute Board', 'Decisão ou recomendação do comitê de resolução de disputas', '{"Empresarial", "Regulatório"}'),

-- NOVO: Documentos específicos para Erro Médico como Direito do Consumidor
('medical_error_report', 'probatorio', 'Laudo Erro Médico', 'Laudo técnico sobre erro médico ou negligência', '{"Consumidor", "Saúde"}'),
('medical_records', 'probatorio', 'Prontuário Médico', 'Prontuário e registros médicos do paciente', '{"Consumidor", "Saúde"}'),
('medical_expert_opinion', 'probatorio', 'Parecer Médico Pericial', 'Opinião técnica sobre procedimento médico', '{"Consumidor", "Saúde"}'),
('surgery_report', 'probatorio', 'Relatório Cirúrgico', 'Relatório detalhado de procedimento cirúrgico', '{"Consumidor", "Saúde"}'),
('aesthetic_treatment_contract', 'contratual', 'Contrato Tratamento Estético', 'Contrato para procedimentos estéticos', '{"Consumidor"}'),
('hospital_bill', 'administrativo', 'Conta Hospitalar', 'Cobrança de serviços hospitalares', '{"Consumidor", "Saúde"}'),
('health_plan_denial_letter', 'administrativo', 'Negativa Plano Saúde', 'Carta de negativa de cobertura', '{"Consumidor"}'),
('medical_consent_form', 'contratual', 'Termo Consentimento Médico', 'Termo de consentimento para procedimentos', '{"Consumidor", "Saúde"}'),
('medical_prescription', 'probatorio', 'Prescrição Médica', 'Receitas e prescrições médicas', '{"Consumidor", "Saúde"}'),
('medical_exam_results', 'probatorio', 'Resultado Exames', 'Resultados de exames médicos e laboratoriais', '{"Consumidor", "Saúde"}'),
('medical_complication_report', 'probatorio', 'Relatório Complicações', 'Registro de complicações pós-procedimento', '{"Consumidor", "Saúde"}'),
('aesthetic_before_after', 'probatorio', 'Fotos Antes/Depois', 'Registro fotográfico de procedimentos estéticos', '{"Consumidor"}'),
('health_insurance_contract', 'contratual', 'Contrato Plano Saúde', 'Contrato de prestação de serviços de saúde', '{"Consumidor"}'),
('medical_equipment_defect', 'probatorio', 'Defeito Equipamento Médico', 'Evidência de defeito em equipamento médico', '{"Consumidor", "Saúde"}'),
('hospital_infection_report', 'probatorio', 'Infecção Hospitalar', 'Relatório de infecção adquirida em ambiente hospitalar', '{"Consumidor", "Saúde"}')

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