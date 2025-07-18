-- Migration para tabelas de documentos OCR
-- Criado em: Janeiro 2025

-- Tabela para logs de processamento OCR
CREATE TABLE IF NOT EXISTS document_processing_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    case_id UUID REFERENCES cases(id) ON DELETE SET NULL,
    document_type TEXT NOT NULL,
    extracted_data JSONB DEFAULT '{}',
    confidence_score FLOAT DEFAULT 0.0,
    processing_method TEXT DEFAULT 'backend',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB DEFAULT '{}',
    status TEXT DEFAULT 'processed'
);

-- Tabela para documentos de casos processados via OCR
CREATE TABLE IF NOT EXISTS case_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id UUID NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    category TEXT DEFAULT 'general',
    extracted_data JSONB DEFAULT '{}',
    ocr_result JSONB DEFAULT '{}',
    confidence_score FLOAT DEFAULT 0.0,
    uploaded_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    file_size BIGINT DEFAULT 0,
    image_url TEXT,
    processing_metadata JSONB DEFAULT '{}',
    reprocessed_at TIMESTAMP WITH TIME ZONE,
    reprocessed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL
);

-- Bucket para armazenar imagens de documentos (executar no Supabase Dashboard)
-- INSERT INTO storage.buckets (id, name, public) VALUES ('document-images', 'document-images', true);

-- Políticas de segurança para document_processing_logs
CREATE POLICY "Users can view their own processing logs" ON document_processing_logs
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own processing logs" ON document_processing_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Políticas de segurança para case_documents
CREATE POLICY "Users can view case documents they have access to" ON case_documents
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM cases 
            WHERE cases.id = case_documents.case_id 
            AND (cases.client_id = auth.uid() OR cases.lawyer_id = auth.uid())
        )
    );

CREATE POLICY "Users can insert documents to their cases" ON case_documents
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM cases 
            WHERE cases.id = case_documents.case_id 
            AND (cases.client_id = auth.uid() OR cases.lawyer_id = auth.uid())
        )
        AND auth.uid() = uploaded_by
    );

CREATE POLICY "Users can update documents they uploaded" ON case_documents
    FOR UPDATE USING (auth.uid() = uploaded_by);

CREATE POLICY "Lawyers can reprocess documents in their cases" ON case_documents
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM cases 
            WHERE cases.id = case_documents.case_id 
            AND cases.lawyer_id = auth.uid()
        )
    );

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_document_processing_logs_user_id ON document_processing_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_document_processing_logs_case_id ON document_processing_logs(case_id);
CREATE INDEX IF NOT EXISTS idx_document_processing_logs_created_at ON document_processing_logs(created_at);

CREATE INDEX IF NOT EXISTS idx_case_documents_case_id ON case_documents(case_id);
CREATE INDEX IF NOT EXISTS idx_case_documents_uploaded_by ON case_documents(uploaded_by);
CREATE INDEX IF NOT EXISTS idx_case_documents_category ON case_documents(category);
CREATE INDEX IF NOT EXISTS idx_case_documents_type ON case_documents(type);
CREATE INDEX IF NOT EXISTS idx_case_documents_uploaded_at ON case_documents(uploaded_at);

-- Habilitar RLS
ALTER TABLE document_processing_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE case_documents ENABLE ROW LEVEL SECURITY;

-- Trigger para atualizar estatísticas de casos
CREATE OR REPLACE FUNCTION update_case_stats_on_document_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Atualizar contadores no caso relacionado
    UPDATE cases 
    SET 
        document_count = (
            SELECT COUNT(*) 
            FROM case_documents 
            WHERE case_id = COALESCE(NEW.case_id, OLD.case_id)
        ),
        ocr_document_count = (
            SELECT COUNT(*) 
            FROM case_documents 
            WHERE case_id = COALESCE(NEW.case_id, OLD.case_id) 
            AND category = 'ocr_processed'
        ),
        updated_at = NOW()
    WHERE id = COALESCE(NEW.case_id, OLD.case_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Associar trigger com a tabela
DROP TRIGGER IF EXISTS case_documents_stats_trigger ON case_documents;
CREATE TRIGGER case_documents_stats_trigger
    AFTER INSERT OR UPDATE OR DELETE ON case_documents
    FOR EACH ROW
    EXECUTE FUNCTION update_case_stats_on_document_change();

-- Adicionar colunas de documento aos casos se não existirem
ALTER TABLE cases 
ADD COLUMN IF NOT EXISTS document_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS ocr_document_count INTEGER DEFAULT 0;

-- Comentários para documentação
COMMENT ON TABLE document_processing_logs IS 'Log de todos os processamentos OCR realizados';
COMMENT ON TABLE case_documents IS 'Documentos de casos processados via OCR com dados extraídos';
COMMENT ON COLUMN case_documents.extracted_data IS 'Dados estruturados extraídos pelo OCR (CPF, nome, etc.)';
COMMENT ON COLUMN case_documents.ocr_result IS 'Resultado bruto do processamento OCR';
COMMENT ON COLUMN case_documents.confidence_score IS 'Score de confiança do OCR (0.0 a 1.0)';
COMMENT ON COLUMN case_documents.processing_metadata IS 'Metadados do processamento (método, timestamps, etc.)'; 