-- Corrige relacionamento entre case_documents e profiles
-- Data: 2025-01-04

-- 1. Verificar se a tabela case_documents existe, se não, criar
CREATE TABLE IF NOT EXISTS public.case_documents (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    case_id UUID REFERENCES public.cases(id) ON DELETE CASCADE NOT NULL,
    uploaded_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    file_name TEXT NOT NULL,
    file_size INTEGER,
    file_type TEXT,
    file_url TEXT,
    storage_path TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Criar índices para performance
CREATE INDEX IF NOT EXISTS idx_case_documents_case_id ON public.case_documents(case_id);
CREATE INDEX IF NOT EXISTS idx_case_documents_uploaded_by ON public.case_documents(uploaded_by);
CREATE INDEX IF NOT EXISTS idx_case_documents_created_at ON public.case_documents(created_at);

-- 3. Habilitar RLS
ALTER TABLE public.case_documents ENABLE ROW LEVEL SECURITY;

-- 4. Políticas de segurança
-- Usuários podem ver documentos dos casos que participam
CREATE POLICY "Users can view documents in their cases" ON public.case_documents
FOR SELECT USING (
    case_id IN (
        SELECT id FROM public.cases 
        WHERE client_id = auth.uid() OR lawyer_id = auth.uid()
    )
);

-- Usuários podem inserir documentos nos casos que participam
CREATE POLICY "Users can insert documents in their cases" ON public.case_documents
FOR INSERT WITH CHECK (
    case_id IN (
        SELECT id FROM public.cases 
        WHERE client_id = auth.uid() OR lawyer_id = auth.uid()
    ) AND uploaded_by = auth.uid()
);

-- Usuários podem atualizar documentos que enviaram
CREATE POLICY "Users can update their own documents" ON public.case_documents
FOR UPDATE USING (uploaded_by = auth.uid());

-- Usuários podem deletar documentos que enviaram
CREATE POLICY "Users can delete their own documents" ON public.case_documents
FOR DELETE USING (uploaded_by = auth.uid());

-- 5. Função para atualizar updated_at
CREATE OR REPLACE FUNCTION update_case_documents_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 6. Trigger para updated_at
DROP TRIGGER IF EXISTS update_case_documents_updated_at ON public.case_documents;
CREATE TRIGGER update_case_documents_updated_at
    BEFORE UPDATE ON public.case_documents
    FOR EACH ROW
    EXECUTE FUNCTION update_case_documents_updated_at();

-- 7. Garantir permissões
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON TABLE public.case_documents TO postgres, anon, authenticated, service_role;

-- 8. Comentários para documentação
COMMENT ON TABLE public.case_documents IS 'Documentos anexados aos casos jurídicos';
COMMENT ON COLUMN public.case_documents.case_id IS 'ID do caso ao qual o documento pertence';
COMMENT ON COLUMN public.case_documents.uploaded_by IS 'ID do usuário que fez o upload (referencia profiles)';
COMMENT ON COLUMN public.case_documents.file_name IS 'Nome original do arquivo';
COMMENT ON COLUMN public.case_documents.file_size IS 'Tamanho do arquivo em bytes';
COMMENT ON COLUMN public.case_documents.file_type IS 'Tipo MIME do arquivo';
COMMENT ON COLUMN public.case_documents.file_url IS 'URL pública do arquivo no storage';
COMMENT ON COLUMN public.case_documents.storage_path IS 'Caminho do arquivo no storage do Supabase'; 