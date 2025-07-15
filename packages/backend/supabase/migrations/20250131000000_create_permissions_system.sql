-- Migration: Criar sistema de permissões (Navigation & Permissions Refactor)
-- Timestamp: 20250131000000
-- Objetivos:
-- 1. Migrar de sistema baseado em roles para sistema baseado em permissions
-- 2. Permitir navegação dinâmica e flexível
-- 3. Facilitar adição de novos perfis sem alterar código

-- =================================================================
-- 1. Tabela de Permissões (todas as capacidades possíveis do sistema)
-- =================================================================
CREATE TABLE IF NOT EXISTS public.permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key TEXT NOT NULL UNIQUE, -- Ex: 'nav.view.dashboard', 'cases.can.create'
    description TEXT,
    category TEXT, -- Ex: 'navigation', 'cases', 'partnerships'
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- =================================================================
-- 2. Tabela de Perfis (expandir a tabela profiles existente)
-- =================================================================
-- Adicionar campo para identificar perfis específicos
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS user_role TEXT DEFAULT 'client' 
CHECK (user_role IN ('client', 'lawyer_associated', 'lawyer_individual', 'lawyer_office', 'lawyer_platform_associate'));

-- Atualizar valores existentes baseado no role atual
UPDATE public.profiles 
SET user_role = 'lawyer_associated' 
WHERE role = 'lawyer' AND user_role = 'client';

-- =================================================================
-- 3. Tabela de Junção: Associar permissões a perfis
-- =================================================================
CREATE TABLE IF NOT EXISTS public.profile_permissions (
    profile_type TEXT NOT NULL, -- Referência ao user_role
    permission_id UUID NOT NULL REFERENCES public.permissions(id) ON DELETE CASCADE,
    PRIMARY KEY (profile_type, permission_id),
    CONSTRAINT valid_profile_type CHECK (
        profile_type IN ('client', 'lawyer_associated', 'lawyer_individual', 'lawyer_office', 'lawyer_platform_associate')
    )
);

-- =================================================================
-- 4. Índices para performance
-- =================================================================
CREATE INDEX IF NOT EXISTS idx_permissions_key ON public.permissions(key);
CREATE INDEX IF NOT EXISTS idx_permissions_category ON public.permissions(category);
CREATE INDEX IF NOT EXISTS idx_profile_permissions_type ON public.profile_permissions(profile_type);
CREATE INDEX IF NOT EXISTS idx_profiles_user_role ON public.profiles(user_role);

-- =================================================================
-- 5. Trigger para atualizar updated_at automaticamente
-- =================================================================
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_permissions_updated_at
    BEFORE UPDATE ON public.permissions
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- =================================================================
-- 6. Função para obter permissões do usuário
-- =================================================================
CREATE OR REPLACE FUNCTION public.get_user_permissions(user_id UUID)
RETURNS TABLE (permission_key TEXT)
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT p.key
    FROM public.permissions p
    INNER JOIN public.profile_permissions pp ON p.id = pp.permission_id
    INNER JOIN public.profiles prof ON prof.user_role = pp.profile_type
    WHERE prof.user_id = get_user_permissions.user_id;
END;
$$ LANGUAGE plpgsql;

-- =================================================================
-- 7. RLS (Row Level Security) para as novas tabelas
-- =================================================================
ALTER TABLE public.permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profile_permissions ENABLE ROW LEVEL SECURITY;

-- Política: Todos os usuários autenticados podem ver permissões
CREATE POLICY "Authenticated users can view permissions" ON public.permissions
    FOR SELECT USING (auth.role() = 'authenticated');

-- Política: Todos os usuários autenticados podem ver associações de perfis
CREATE POLICY "Authenticated users can view profile permissions" ON public.profile_permissions
    FOR SELECT USING (auth.role() = 'authenticated');

-- =================================================================
-- 8. Comentários para documentação
-- =================================================================
COMMENT ON TABLE public.permissions IS 'Tabela de permissões/capacidades disponíveis no sistema';
COMMENT ON TABLE public.profile_permissions IS 'Tabela de junção que associa permissões a tipos de perfil';
COMMENT ON COLUMN public.permissions.key IS 'Chave única da permissão (ex: nav.view.dashboard)';
COMMENT ON COLUMN public.permissions.category IS 'Categoria da permissão para organização';
COMMENT ON COLUMN public.profiles.user_role IS 'Tipo específico de usuário para sistema de permissões';
COMMENT ON FUNCTION public.get_user_permissions(UUID) IS 'Retorna todas as permissões de um usuário baseado em seu perfil'; 