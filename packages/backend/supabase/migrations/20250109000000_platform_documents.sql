-- Tabela de documentos da plataforma (contratos, políticas, etc.)
CREATE TABLE platform_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    type VARCHAR(50) NOT NULL CHECK (type IN ('contract', 'policy', 'manual', 'ethics', 'commission')),
    version VARCHAR(20) NOT NULL,
    document_url TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    requires_acceptance BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabela de aceites de documentos por advogados
CREATE TABLE lawyer_accepted_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lawyer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    document_id UUID NOT NULL REFERENCES platform_documents(id) ON DELETE CASCADE,
    accepted_at TIMESTAMPTZ DEFAULT NOW(),
    ip_address INET,
    user_agent TEXT,
    UNIQUE(lawyer_id, document_id)
);

-- Políticas de Segurança (RLS)
ALTER TABLE platform_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE lawyer_accepted_documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Lawyers can view active public documents" ON platform_documents
    FOR SELECT USING (is_active = true AND requires_acceptance = false);

CREATE POLICY "Lawyers can view their accepted documents" ON lawyer_accepted_documents
    FOR SELECT USING (lawyer_id = auth.uid());

CREATE POLICY "Lawyers can accept documents" ON lawyer_accepted_documents
    FOR INSERT WITH CHECK (lawyer_id = auth.uid()); 