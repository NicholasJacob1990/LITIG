-- ========================================================================
-- MIGRAÇÃO: Política de Privacidade Universal
-- ========================================================================
-- 
-- Implementa a nova regra corporativa:
-- "Qualquer caso – premium ou não – só expõe dados do cliente 
--  depois que o advogado/escritório clica em Aceitar."
--
-- Esta migração cria:
-- 1. Colunas sensíveis na tabela cases
-- 2. View cases_preview (só dados não-sensíveis)
-- 3. Tabela case_assignments (registro de aceites)
-- 4. RLS policies para controle de acesso
-- 5. RPC function para aceitar casos
-- 6. Storage policies para arquivos
-- ========================================================================

-- 📄 1. ADICIONAR COLUNAS SENSÍVEIS À TABELA CASES
-- ========================================================================

-- Adicionar colunas de dados sensíveis do cliente
ALTER TABLE public.cases 
ADD COLUMN IF NOT EXISTS valor_causa NUMERIC,
ADD COLUMN IF NOT EXISTS cliente_nome TEXT,
ADD COLUMN IF NOT EXISTS cliente_email TEXT,
ADD COLUMN IF NOT EXISTS cliente_phone TEXT,
ADD COLUMN IF NOT EXISTS cliente_cpf TEXT,
ADD COLUMN IF NOT EXISTS cliente_cnpj TEXT,
ADD COLUMN IF NOT EXISTS cliente_address TEXT,
ADD COLUMN IF NOT EXISTS detailed_description TEXT,
ADD COLUMN IF NOT EXISTS client_documents JSONB DEFAULT '[]';

-- Adicionar metadados de aceite
ALTER TABLE public.cases 
ADD COLUMN IF NOT EXISTS accepted_by UUID REFERENCES auth.users(id),
ADD COLUMN IF NOT EXISTS accepted_at TIMESTAMPTZ;

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_cases_accepted_by ON public.cases(accepted_by);
CREATE INDEX IF NOT EXISTS idx_cases_accepted_at ON public.cases(accepted_at);
CREATE INDEX IF NOT EXISTS idx_cases_area_subarea ON public.cases(area, subarea);

-- 📄 2. VIEW CASES_PREVIEW (SÓ DADOS NÃO-SENSÍVEIS)
-- ========================================================================

CREATE OR REPLACE VIEW public.cases_preview AS
SELECT
    id,
    area,
    subarea,
    complexity,
    urgency_h,
    is_premium,
    status,
    created_at,
    updated_at,
    -- Localização genérica (cidade/estado, não endereço completo)
    location_city,
    location_state,
    -- Valor em faixa, não exato
    CASE 
        WHEN valor_causa IS NULL THEN 'Não informado'
        WHEN valor_causa < 50000 THEN 'Até R$ 50 mil'
        WHEN valor_causa < 100000 THEN 'R$ 50-100 mil'
        WHEN valor_causa < 300000 THEN 'R$ 100-300 mil'
        WHEN valor_causa < 500000 THEN 'R$ 300-500 mil'
        ELSE 'Acima de R$ 500 mil'
    END as valor_faixa,
    -- Indicadores sem expor dados sensíveis
    CASE WHEN cliente_nome IS NOT NULL THEN 1 ELSE 0 END as has_client_data,
    CASE WHEN client_documents::text != '[]' THEN 
        jsonb_array_length(client_documents) 
        ELSE 0 
    END as documents_count,
    -- Status de aceite (sem expor quem aceitou)
    CASE WHEN accepted_by IS NOT NULL THEN true ELSE false END as is_accepted
FROM public.cases
WHERE status = 'ABERTO' OR status IS NULL; -- Só casos disponíveis

-- 📄 3. TABELA CASE_ASSIGNMENTS (REGISTRO DE ACEITES)
-- ========================================================================

CREATE TABLE IF NOT EXISTS public.case_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id UUID NOT NULL REFERENCES public.cases(id) ON DELETE CASCADE,
    lawyer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    accepted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    abandoned_at TIMESTAMPTZ NULL,
    abandon_reason TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Um caso só pode ser aceito por um advogado
    UNIQUE(case_id)
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_case_assignments_lawyer_id ON public.case_assignments(lawyer_id);
CREATE INDEX IF NOT EXISTS idx_case_assignments_case_id ON public.case_assignments(case_id);
CREATE INDEX IF NOT EXISTS idx_case_assignments_accepted_at ON public.case_assignments(accepted_at);

-- 📄 4. TABELA DE AUDITORIA
-- ========================================================================

CREATE SCHEMA IF NOT EXISTS audit;

CREATE TABLE IF NOT EXISTS audit.case_access (
    id BIGSERIAL PRIMARY KEY,
    lawyer_id UUID REFERENCES auth.users(id),
    case_id UUID REFERENCES public.cases(id),
    action TEXT NOT NULL, -- 'preview' | 'accept' | 'read_full' | 'abandon'
    ip_address INET,
    user_agent TEXT,
    accessed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_case_access_lawyer_case ON audit.case_access(lawyer_id, case_id);
CREATE INDEX IF NOT EXISTS idx_case_access_action_time ON audit.case_access(action, accessed_at);

-- 📄 5. ROW LEVEL SECURITY (RLS) POLICIES
-- ========================================================================

-- 5.1 VIEW cases_preview: público para usuários autenticados
ALTER VIEW public.cases_preview OWNER TO postgres;
GRANT SELECT ON public.cases_preview TO authenticated;

-- 5.2 Tabela cases: só quem aceitou pode ver dados completos
ALTER TABLE public.cases ENABLE ROW LEVEL SECURITY;

-- Policy: Só pode ver caso completo se aceitou
CREATE POLICY "lawyer_accepted_can_view_full_case" 
    ON public.cases 
    FOR SELECT 
    USING (
        -- Admin pode ver tudo
        (auth.jwt() ->> 'role')::text = 'admin'
        OR
        -- Cliente proprietário pode ver
        client_id = auth.uid()
        OR
        -- Advogado que aceitou pode ver
        EXISTS (
            SELECT 1 
            FROM public.case_assignments ca 
            WHERE ca.case_id = cases.id 
              AND ca.lawyer_id = auth.uid()
              AND ca.abandoned_at IS NULL
        )
    );

-- 5.3 Tabela case_assignments: só o próprio usuário vê seus aceites
ALTER TABLE public.case_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_can_view_own_assignments" 
    ON public.case_assignments 
    FOR SELECT 
    USING (lawyer_id = auth.uid());

CREATE POLICY "user_can_insert_assignment" 
    ON public.case_assignments 
    FOR INSERT 
    WITH CHECK (lawyer_id = auth.uid());

CREATE POLICY "user_can_update_own_assignment" 
    ON public.case_assignments 
    FOR UPDATE 
    USING (lawyer_id = auth.uid())
    WITH CHECK (lawyer_id = auth.uid());

-- 📄 6. BUCKET STORAGE POLICIES (DOCUMENTOS)
-- ========================================================================

-- Criar bucket se não existir
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'case-files', 
    'case-files', 
    false, 
    52428800, -- 50MB
    ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/jpg', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document']::text[]
)
ON CONFLICT (id) DO NOTHING;

-- Policy: Só pode baixar arquivos de casos aceitos
CREATE POLICY "case_files_after_accept" 
    ON storage.objects 
    FOR SELECT 
    USING (
        bucket_id = 'case-files'
        AND (
            -- Admin pode ver tudo
            (auth.jwt() ->> 'role')::text = 'admin'
            OR
            -- Advogado que aceitou o caso
            EXISTS (
                SELECT 1 
                FROM public.case_assignments ca 
                WHERE ca.case_id::text = split_part(storage.objects.name, '/', 1)
                  AND ca.lawyer_id = auth.uid()
                  AND ca.abandoned_at IS NULL
            )
        )
    );

-- 📄 7. RPC FUNCTIONS (FUNÇÕES PARA ACEITAR CASOS)
-- ========================================================================

-- Função para aceitar um caso
CREATE OR REPLACE FUNCTION public.accept_case(_case_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    _result JSON;
    _case_exists BOOLEAN;
    _already_accepted BOOLEAN;
    _user_id UUID;
BEGIN
    -- Verificar se usuário está autenticado
    _user_id := auth.uid();
    IF _user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Usuário não autenticado'
        );
    END IF;
    
    -- Verificar se caso existe e está disponível
    SELECT true INTO _case_exists
    FROM public.cases 
    WHERE id = _case_id 
      AND (status = 'ABERTO' OR status IS NULL);
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Caso não encontrado ou não disponível'
        );
    END IF;
    
    -- Verificar se já foi aceito
    SELECT true INTO _already_accepted
    FROM public.case_assignments 
    WHERE case_id = _case_id 
      AND abandoned_at IS NULL;
    
    IF FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Caso já foi aceito por outro advogado'
        );
    END IF;
    
    -- Aceitar o caso
    BEGIN
        -- Inserir assignment
        INSERT INTO public.case_assignments (case_id, lawyer_id)
        VALUES (_case_id, _user_id);
        
        -- Atualizar tabela cases
        UPDATE public.cases 
        SET accepted_by = _user_id,
            accepted_at = NOW(),
            status = 'ACEITO'
        WHERE id = _case_id;
        
        -- Log de auditoria
        INSERT INTO audit.case_access (lawyer_id, case_id, action)
        VALUES (_user_id, _case_id, 'accept');
        
        _result := json_build_object(
            'success', true,
            'case_id', _case_id,
            'accepted_by', _user_id,
            'accepted_at', NOW()
        );
        
    EXCEPTION WHEN unique_violation THEN
        -- Caso já aceito por outro (race condition)
        _result := json_build_object(
            'success', false,
            'error', 'Caso já foi aceito por outro advogado'
        );
    END;
    
    RETURN _result;
END;
$$;

-- Função para abandonar um caso
CREATE OR REPLACE FUNCTION public.abandon_case(_case_id UUID, _reason TEXT DEFAULT NULL)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    _result JSON;
    _user_id UUID;
BEGIN
    _user_id := auth.uid();
    
    -- Verificar se usuário pode abandonar este caso
    IF NOT EXISTS (
        SELECT 1 FROM public.case_assignments 
        WHERE case_id = _case_id 
          AND lawyer_id = _user_id 
          AND abandoned_at IS NULL
    ) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Você não aceitou este caso ou já o abandonou'
        );
    END IF;
    
    -- Abandonar o caso
    UPDATE public.case_assignments 
    SET abandoned_at = NOW(),
        abandon_reason = _reason
    WHERE case_id = _case_id AND lawyer_id = _user_id;
    
    -- Reabrir o caso
    UPDATE public.cases 
    SET accepted_by = NULL,
        accepted_at = NULL,
        status = 'ABERTO'
    WHERE id = _case_id;
    
    -- Log de auditoria
    INSERT INTO audit.case_access (lawyer_id, case_id, action)
    VALUES (_user_id, _case_id, 'abandon');
    
    RETURN json_build_object(
        'success', true,
        'case_id', _case_id,
        'abandoned_at', NOW()
    );
END;
$$;

-- 📄 8. GRANTS E PERMISSÕES
-- ========================================================================

-- Permitir execução das funções para usuários autenticados
GRANT EXECUTE ON FUNCTION public.accept_case(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.abandon_case(UUID, TEXT) TO authenticated;

-- Permitir select na view de preview
GRANT SELECT ON public.cases_preview TO authenticated;

-- Permitir operações na tabela de assignments
GRANT SELECT, INSERT, UPDATE ON public.case_assignments TO authenticated;

-- Permitir insert na auditoria
GRANT INSERT ON audit.case_access TO authenticated;
GRANT USAGE ON SEQUENCE audit.case_access_id_seq TO authenticated;

-- 📄 9. TRIGGERS DE AUDITORIA AUTOMÁTICA
-- ========================================================================

-- Trigger para logar acesso a casos completos
CREATE OR REPLACE FUNCTION audit.log_case_access()
RETURNS TRIGGER AS $$
BEGIN
    -- Log apenas para acessos de usuários (não admin)
    IF (auth.jwt() ->> 'role')::text != 'admin' THEN
        INSERT INTO audit.case_access (lawyer_id, case_id, action)
        VALUES (auth.uid(), NEW.id, 'read_full');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Aplicar trigger na tabela cases
CREATE TRIGGER trg_audit_case_access
    AFTER SELECT ON public.cases
    FOR EACH ROW 
    EXECUTE FUNCTION audit.log_case_access();

-- ========================================================================
-- FIM DA MIGRAÇÃO
-- ========================================================================

-- Log da migração
DO $$
BEGIN
    RAISE NOTICE 'Migração de Política de Privacidade Universal aplicada com sucesso!';
    RAISE NOTICE 'Nova política: dados do cliente só são revelados após aceite.';
    RAISE NOTICE 'Use cases_preview para listagem e accept_case() para aceitar.';
END
$$; 