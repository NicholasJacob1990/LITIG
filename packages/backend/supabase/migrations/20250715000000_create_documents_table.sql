-- Migration: Create documents table for case file management
-- Timestamp: 20250715000000

-- Enum para tipos de documento
CREATE TYPE public.document_type AS ENUM (
    'petition', 
    'decision', 
    'evidence', 
    'contract', 
    'receipt', 
    'identification', 
    'other'
);

-- Tabela para documentos dos casos
CREATE TABLE public.documents (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    case_id uuid NOT NULL REFERENCES public.cases(id) ON DELETE CASCADE,
    uploaded_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE SET NULL,
    name text NOT NULL,
    original_name text NOT NULL,
    file_path text NOT NULL, -- Caminho no Supabase Storage
    file_size bigint NOT NULL, -- Tamanho em bytes
    mime_type text NOT NULL,
    document_type document_type DEFAULT 'other',
    description text,
    is_confidential boolean DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- Índices para performance
CREATE INDEX idx_documents_case_id ON public.documents(case_id);
CREATE INDEX idx_documents_uploaded_by ON public.documents(uploaded_by);
CREATE INDEX idx_documents_type ON public.documents(document_type);

-- RLS (Row Level Security)
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;

-- Políticas de acesso
-- Usuários podem ver documentos de casos onde são cliente ou advogado
CREATE POLICY "Users can view documents from their cases"
    ON public.documents FOR SELECT
    USING (
        case_id IN (
            SELECT id FROM public.cases 
            WHERE client_id = auth.uid() OR lawyer_id = auth.uid()
        )
    );

-- Usuários podem fazer upload de documentos em seus casos
CREATE POLICY "Users can upload documents to their cases"
    ON public.documents FOR INSERT
    WITH CHECK (
        case_id IN (
            SELECT id FROM public.cases 
            WHERE client_id = auth.uid() OR lawyer_id = auth.uid()
        )
        AND uploaded_by = auth.uid()
    );

-- Usuários podem atualizar apenas documentos que eles próprios fizeram upload
CREATE POLICY "Users can update their own documents"
    ON public.documents FOR UPDATE
    USING (uploaded_by = auth.uid());

-- Usuários podem deletar apenas documentos que eles próprios fizeram upload
CREATE POLICY "Users can delete their own documents"
    ON public.documents FOR DELETE
    USING (uploaded_by = auth.uid());

-- Trigger para updated_at
CREATE TRIGGER on_documents_updated
    BEFORE UPDATE ON public.documents
    FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Comentários
COMMENT ON TABLE public.documents IS 'Stores documents and files related to legal cases';
COMMENT ON COLUMN public.documents.file_path IS 'Path to file in Supabase Storage';
COMMENT ON COLUMN public.documents.file_size IS 'File size in bytes';
COMMENT ON COLUMN public.documents.is_confidential IS 'Whether document contains confidential information'; 