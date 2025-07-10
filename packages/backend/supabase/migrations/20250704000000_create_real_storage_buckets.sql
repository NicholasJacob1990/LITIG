-- Migration: Create real storage buckets with proper configuration
-- Timestamp: 20250704000000

-- =================================================================
-- 1. Criar buckets para diferentes tipos de arquivos
-- =================================================================

-- Bucket para documentos de advogados (CVs, OAB, comprovantes)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'lawyer-documents', 
  'lawyer-documents', 
  false, 
  10485760, -- 10MB
  ARRAY[
    'application/pdf',
    'image/jpeg',
    'image/png',
    'text/plain',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  ]
)
ON CONFLICT (id) DO UPDATE SET
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Bucket para documentos de casos (petições, evidências, contratos)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'case-documents', 
  'case-documents', 
  false, 
  52428800, -- 50MB
  ARRAY[
    'application/pdf',
    'image/jpeg',
    'image/png',
    'text/plain',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  ]
)
ON CONFLICT (id) DO UPDATE SET
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Bucket para anexos de suporte (já existe, mas vamos garantir configuração)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'support_attachments', 
  'support_attachments', 
  false, 
  20971520, -- 20MB
  ARRAY[
    'application/pdf',
    'image/jpeg',
    'image/png',
    'image/gif',
    'text/plain',
    'application/zip',
    'application/x-zip-compressed'
  ]
)
ON CONFLICT (id) DO UPDATE SET
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Bucket para contratos assinados
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'contracts', 
  'contracts', 
  false, 
  31457280, -- 30MB
  ARRAY[
    'application/pdf',
    'text/html',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  ]
)
ON CONFLICT (id) DO UPDATE SET
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Bucket para avatars e imagens de perfil
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars', 
  'avatars', 
  true, -- Público para fácil acesso
  5242880, -- 5MB
  ARRAY[
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp'
  ]
)
ON CONFLICT (id) DO UPDATE SET
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- =================================================================
-- 2. Políticas RLS para lawyer-documents
-- =================================================================

-- Advogados podem fazer upload de seus próprios documentos
CREATE POLICY "Lawyers can upload their own documents"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'lawyer-documents' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Advogados podem ver seus próprios documentos
CREATE POLICY "Lawyers can view their own documents"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'lawyer-documents' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Advogados podem deletar seus próprios documentos
CREATE POLICY "Lawyers can delete their own documents"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'lawyer-documents' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- =================================================================
-- 3. Políticas RLS para case-documents
-- =================================================================

-- Usuários podem fazer upload de documentos para casos onde participam
CREATE POLICY "Users can upload documents to their cases"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'case-documents' AND
    EXISTS (
      SELECT 1 FROM public.cases 
      WHERE id::text = (storage.foldername(name))[1]
      AND (client_id = auth.uid() OR lawyer_id = auth.uid())
    )
  );

-- Usuários podem ver documentos de casos onde participam
CREATE POLICY "Users can view documents from their cases"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'case-documents' AND
    EXISTS (
      SELECT 1 FROM public.cases 
      WHERE id::text = (storage.foldername(name))[1]
      AND (client_id = auth.uid() OR lawyer_id = auth.uid())
    )
  );

-- Usuários podem deletar documentos que eles próprios fizeram upload
CREATE POLICY "Users can delete their own case documents"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'case-documents' AND
    owner = auth.uid()
  );

-- =================================================================
-- 4. Políticas RLS para support_attachments
-- =================================================================

-- Usuários podem fazer upload de anexos para tickets onde participam
CREATE POLICY "Users can upload attachments to their tickets"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'support_attachments' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Usuários podem ver anexos de tickets onde participam
CREATE POLICY "Users can view attachments from their tickets"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'support_attachments' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- =================================================================
-- 5. Políticas RLS para contracts
-- =================================================================

-- Sistema pode fazer upload de contratos
CREATE POLICY "System can upload contracts"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'contracts');

-- Usuários podem ver contratos onde são parte
CREATE POLICY "Users can view their contracts"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'contracts' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- =================================================================
-- 6. Políticas RLS para avatars (bucket público)
-- =================================================================

-- Qualquer usuário autenticado pode fazer upload do próprio avatar
CREATE POLICY "Users can upload their own avatar"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Avatars são públicos (qualquer um pode ver)
CREATE POLICY "Avatars are publicly viewable"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

-- Usuários podem atualizar seu próprio avatar
CREATE POLICY "Users can update their own avatar"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Usuários podem deletar seu próprio avatar
CREATE POLICY "Users can delete their own avatar"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- =================================================================
-- 7. Função auxiliar para limpeza de arquivos órfãos
-- =================================================================

CREATE OR REPLACE FUNCTION public.cleanup_orphaned_files()
RETURNS void AS $$
BEGIN
  -- Limpar documentos de advogados órfãos (mais de 7 dias sem referência)
  DELETE FROM storage.objects 
  WHERE bucket_id = 'lawyer-documents' 
  AND created_at < NOW() - INTERVAL '7 days'
  AND NOT EXISTS (
    SELECT 1 FROM auth.users 
    WHERE id::text = (storage.foldername(name))[1]
  );

  -- Limpar documentos de casos órfãos
  DELETE FROM storage.objects 
  WHERE bucket_id = 'case-documents' 
  AND created_at < NOW() - INTERVAL '30 days'
  AND NOT EXISTS (
    SELECT 1 FROM public.cases 
    WHERE id::text = (storage.foldername(name))[1]
  );

  -- Limpar anexos de suporte órfãos (apenas por idade)
  DELETE FROM storage.objects 
  WHERE bucket_id = 'support_attachments' 
  AND created_at < NOW() - INTERVAL '90 days';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- 8. Comentários e documentação
-- =================================================================

COMMENT ON FUNCTION public.cleanup_orphaned_files() IS 'Remove arquivos órfãos dos buckets de storage após períodos específicos';

-- Comentários nos buckets
UPDATE storage.buckets SET 
  public = false,
  avif_autodetection = false
WHERE id IN ('lawyer-documents', 'case-documents', 'support_attachments', 'contracts');

UPDATE storage.buckets SET 
  public = true,
  avif_autodetection = true
WHERE id = 'avatars'; 