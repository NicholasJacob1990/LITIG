-- Migration: Sistema de Contexto Automático (Solução 3)
-- Timestamp: 20250119000000
-- Objetivo: Detecção automática de contexto sem toggle manual

-- =================================================================
-- 1. Tabela para logs de contexto automático
-- =================================================================
CREATE TABLE IF NOT EXISTS public.auto_context_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    context_mode TEXT NOT NULL CHECK (context_mode IN ('platform_work', 'personal_client')),
    session_id TEXT,
    detection_method TEXT NOT NULL DEFAULT 'automatic',
    detection_metadata JSONB,
    detected_at TIMESTAMPTZ DEFAULT NOW(),
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =================================================================
-- 2. Índices para performance
-- =================================================================
CREATE INDEX idx_auto_context_logs_user_id ON public.auto_context_logs(user_id);
CREATE INDEX idx_auto_context_logs_detected_at ON public.auto_context_logs(detected_at);
CREATE INDEX idx_auto_context_logs_context_mode ON public.auto_context_logs(context_mode);
CREATE INDEX idx_auto_context_logs_session ON public.auto_context_logs(session_id);

-- Índice composto para consultas frequentes
CREATE INDEX idx_auto_context_user_time 
    ON public.auto_context_logs(user_id, detected_at DESC);

-- =================================================================
-- 3. Função para obter contexto atual do usuário
-- =================================================================
CREATE OR REPLACE FUNCTION public.get_current_auto_context(user_id UUID)
RETURNS TABLE (
    context_mode TEXT,
    detected_at TIMESTAMPTZ,
    detection_method TEXT
)
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        acl.context_mode,
        acl.detected_at,
        acl.detection_method
    FROM public.auto_context_logs acl
    WHERE acl.user_id = get_current_auto_context.user_id
    ORDER BY acl.detected_at DESC
    LIMIT 1;
    
    -- Se não há registro, retornar contexto padrão
    IF NOT FOUND THEN
        RETURN QUERY
        SELECT 
            'platform_work'::TEXT as context_mode,
            NOW() as detected_at,
            'default'::TEXT as detection_method;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- =================================================================
-- 4. Função para detectar contexto baseado em rota
-- =================================================================
CREATE OR REPLACE FUNCTION public.detect_context_from_route(
    route_path TEXT,
    action_data JSONB DEFAULT '{}'::JSONB
)
RETURNS TEXT
SECURITY DEFINER
AS $$
DECLARE
    personal_indicators TEXT[] := ARRAY[
        '/personal/',
        '/my-cases/',
        '/personal-area/',
        '/hire-for-me/',
        '/my-payments/'
    ];
    indicator TEXT;
BEGIN
    -- Verificar indicadores de rota pessoal
    FOREACH indicator IN ARRAY personal_indicators
    LOOP
        IF route_path LIKE '%' || indicator || '%' THEN
            RETURN 'personal_client';
        END IF;
    END LOOP;
    
    -- Verificar dados da ação
    IF (action_data->>'is_personal_action')::BOOLEAN = TRUE THEN
        RETURN 'personal_client';
    END IF;
    
    IF action_data->>'payment_source' = 'personal_funds' THEN
        RETURN 'personal_client';
    END IF;
    
    -- Padrão: trabalho da plataforma
    RETURN 'platform_work';
END;
$$ LANGUAGE plpgsql;

-- =================================================================
-- 5. Trigger para auto-detecção em mudanças de rota
-- =================================================================
CREATE OR REPLACE FUNCTION public.auto_detect_context_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Apenas para Super Associados
    IF EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.user_id = NEW.user_id 
        AND p.user_role = 'lawyer_platform_associate'
    ) THEN
        -- Detectar contexto baseado na nova rota
        NEW.context_mode := public.detect_context_from_route(
            NEW.detection_metadata->>'route',
            NEW.detection_metadata->'action_data'
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_detect_context
    BEFORE INSERT ON public.auto_context_logs
    FOR EACH ROW
    EXECUTE FUNCTION public.auto_detect_context_change();

-- =================================================================
-- 6. RLS (Row Level Security)
-- =================================================================
ALTER TABLE public.auto_context_logs ENABLE ROW LEVEL SECURITY;

-- Usuários podem ver apenas seus próprios logs
CREATE POLICY "Users can view own context logs" ON public.auto_context_logs
    FOR SELECT USING (auth.uid() = user_id);

-- Usuários podem criar logs para si mesmos
CREATE POLICY "Users can create own context logs" ON public.auto_context_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Administradores podem ver todos os logs
CREATE POLICY "Admins can view all context logs" ON public.auto_context_logs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles p 
            WHERE p.user_id = auth.uid() 
            AND p.user_role IN ('admin', 'super_admin')
        )
    );

-- =================================================================
-- 7. View para relatórios de contexto
-- =================================================================
CREATE OR REPLACE VIEW public.context_usage_report AS
SELECT 
    acl.user_id,
    p.full_name,
    acl.context_mode,
    COUNT(*) as switches_count,
    DATE_TRUNC('day', acl.detected_at) as date,
    AVG(
        EXTRACT(EPOCH FROM (
            LEAD(acl.detected_at) OVER (
                PARTITION BY acl.user_id 
                ORDER BY acl.detected_at
            ) - acl.detected_at
        )) / 60
    ) as avg_duration_minutes
FROM public.auto_context_logs acl
JOIN public.profiles p ON p.user_id = acl.user_id
WHERE p.user_role = 'lawyer_platform_associate'
GROUP BY acl.user_id, p.full_name, acl.context_mode, DATE_TRUNC('day', acl.detected_at)
ORDER BY date DESC, switches_count DESC;

-- =================================================================
-- 8. Comentários para documentação
-- =================================================================
COMMENT ON TABLE public.auto_context_logs IS 'Logs de detecção automática de contexto para Super Associados';
COMMENT ON COLUMN public.auto_context_logs.context_mode IS 'Contexto detectado: platform_work ou personal_client';
COMMENT ON COLUMN public.auto_context_logs.detection_method IS 'Método de detecção: automatic, manual_override, default';
COMMENT ON COLUMN public.auto_context_logs.detection_metadata IS 'Metadados sobre como o contexto foi detectado';
COMMENT ON FUNCTION public.get_current_auto_context(UUID) IS 'Obtém o contexto atual de um usuário';
COMMENT ON FUNCTION public.detect_context_from_route(TEXT, JSONB) IS 'Detecta contexto baseado na rota e dados da ação';
COMMENT ON VIEW public.context_usage_report IS 'Relatório de uso de contextos por Super Associados';

-- =================================================================
-- 9. Dados iniciais para testes
-- =================================================================
-- Inserir alguns contextos de exemplo para demonstração
-- (Remover em produção)
/*
INSERT INTO public.auto_context_logs (user_id, context_mode, detection_method, detection_metadata) 
SELECT 
    p.user_id,
    'platform_work',
    'default',
    '{"route": "/dashboard", "detection_reason": "initial_setup"}'::JSONB
FROM public.profiles p 
WHERE p.user_role = 'lawyer_platform_associate'
ON CONFLICT DO NOTHING;
*/ 