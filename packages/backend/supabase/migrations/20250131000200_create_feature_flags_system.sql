-- Migração: Sistema de Feature Flags para Rollout Gradual
-- Data: 2025-01-31
-- Descrição: Implementa sistema de feature flags para controle de rollout gradual da contextualização

-- Criar ENUM para status de feature flags
CREATE TYPE feature_status AS ENUM (
    'disabled',
    'testing',
    'gradual_rollout',
    'enabled'
);

-- Criar ENUM para estratégias de rollout
CREATE TYPE rollout_strategy AS ENUM (
    'percentage',
    'user_list',
    'user_role',
    'geographic',
    'device_type',
    'hybrid'
);

-- Tabela principal de feature flags
CREATE TABLE feature_flags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT NOT NULL,
    status feature_status NOT NULL DEFAULT 'disabled',
    rollout_strategy rollout_strategy NOT NULL DEFAULT 'percentage',
    rollout_percentage DECIMAL(5,2) NOT NULL DEFAULT 0.00 CHECK (rollout_percentage >= 0 AND rollout_percentage <= 100),
    target_users JSONB DEFAULT '[]'::jsonb,
    target_roles JSONB DEFAULT '[]'::jsonb,
    target_regions JSONB DEFAULT '[]'::jsonb,
    device_types JSONB DEFAULT '[]'::jsonb,
    start_date TIMESTAMP WITH TIME ZONE,
    end_date TIMESTAMP WITH TIME ZONE,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para feature flags
CREATE INDEX idx_feature_flags_name ON feature_flags(name);
CREATE INDEX idx_feature_flags_status ON feature_flags(status);
CREATE INDEX idx_feature_flags_rollout_strategy ON feature_flags(rollout_strategy);
CREATE INDEX idx_feature_flags_start_date ON feature_flags(start_date);
CREATE INDEX idx_feature_flags_end_date ON feature_flags(end_date);
CREATE INDEX idx_feature_flags_target_roles ON feature_flags USING GIN(target_roles);
CREATE INDEX idx_feature_flags_target_regions ON feature_flags USING GIN(target_regions);
CREATE INDEX idx_feature_flags_metadata ON feature_flags USING GIN(metadata);

-- Tabela de logs de feature flags (para analytics)
CREATE TABLE feature_flag_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    feature_name VARCHAR(255) NOT NULL,
    user_id UUID NOT NULL,
    user_role VARCHAR(50),
    enabled BOOLEAN NOT NULL,
    rollout_percentage DECIMAL(5,2),
    user_hash VARCHAR(32),
    context_data JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para logs de feature flags
CREATE INDEX idx_feature_flag_logs_feature_name ON feature_flag_logs(feature_name);
CREATE INDEX idx_feature_flag_logs_user_id ON feature_flag_logs(user_id);
CREATE INDEX idx_feature_flag_logs_user_role ON feature_flag_logs(user_role);
CREATE INDEX idx_feature_flag_logs_enabled ON feature_flag_logs(enabled);
CREATE INDEX idx_feature_flag_logs_created_at ON feature_flag_logs(created_at);

-- Tabela de configurações contextuais por usuário (cache)
CREATE TABLE contextual_feature_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    user_role VARCHAR(50) NOT NULL,
    allocation_types_enabled JSONB DEFAULT '[]'::jsonb,
    ui_components_enabled JSONB DEFAULT '[]'::jsonb,
    metrics_collection_enabled BOOLEAN DEFAULT FALSE,
    dual_context_enabled BOOLEAN DEFAULT FALSE,
    advanced_kpis_enabled BOOLEAN DEFAULT FALSE,
    real_time_updates_enabled BOOLEAN DEFAULT FALSE,
    performance_monitoring_enabled BOOLEAN DEFAULT FALSE,
    config_hash VARCHAR(64),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para configurações contextuais
CREATE INDEX idx_contextual_configs_user_id ON contextual_feature_configs(user_id);
CREATE INDEX idx_contextual_configs_user_role ON contextual_feature_configs(user_role);
CREATE INDEX idx_contextual_configs_expires_at ON contextual_feature_configs(expires_at);
CREATE INDEX idx_contextual_configs_config_hash ON contextual_feature_configs(config_hash);

-- Função para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para atualizar updated_at
CREATE TRIGGER update_feature_flags_updated_at
    BEFORE UPDATE ON feature_flags
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_contextual_configs_updated_at
    BEFORE UPDATE ON contextual_feature_configs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Função para limpeza automática de logs antigos
CREATE OR REPLACE FUNCTION cleanup_old_feature_flag_logs()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- Remove logs com mais de 90 dias
    DELETE FROM feature_flag_logs
    WHERE created_at < NOW() - INTERVAL '90 days';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Função para limpeza automática de configurações expiradas
CREATE OR REPLACE FUNCTION cleanup_expired_contextual_configs()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- Remove configurações expiradas
    DELETE FROM contextual_feature_configs
    WHERE expires_at < NOW();
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Função para verificar se feature está habilitada para usuário
CREATE OR REPLACE FUNCTION is_feature_enabled_for_user(
    p_feature_name VARCHAR(255),
    p_user_id UUID,
    p_user_role VARCHAR(50),
    p_context JSONB DEFAULT '{}'::jsonb
)
RETURNS BOOLEAN AS $$
DECLARE
    flag_record feature_flags%ROWTYPE;
    user_hash VARCHAR(32);
    user_percentage DECIMAL(5,2);
    is_enabled BOOLEAN := FALSE;
BEGIN
    -- Busca feature flag
    SELECT * INTO flag_record
    FROM feature_flags
    WHERE name = p_feature_name;
    
    -- Se não encontrada, retorna FALSE
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Verifica status
    IF flag_record.status = 'disabled' THEN
        RETURN FALSE;
    END IF;
    
    IF flag_record.status = 'enabled' THEN
        RETURN TRUE;
    END IF;
    
    -- Verifica data de início/fim
    IF flag_record.start_date IS NOT NULL AND NOW() < flag_record.start_date THEN
        RETURN FALSE;
    END IF;
    
    IF flag_record.end_date IS NOT NULL AND NOW() > flag_record.end_date THEN
        RETURN FALSE;
    END IF;
    
    -- Aplica estratégia de rollout
    CASE flag_record.rollout_strategy
        WHEN 'user_list' THEN
            SELECT (flag_record.target_users @> to_jsonb(p_user_id::text)) INTO is_enabled;
        
        WHEN 'user_role' THEN
            SELECT (flag_record.target_roles @> to_jsonb(p_user_role)) INTO is_enabled;
        
        WHEN 'percentage' THEN
            -- Calcula hash consistente do usuário
            user_hash := MD5(p_user_id::text || '_contextual_rollout');
            user_percentage := (('x' || SUBSTR(user_hash, 1, 8))::bit(32)::int % 10000) / 100.0;
            is_enabled := user_percentage < flag_record.rollout_percentage;
        
        WHEN 'geographic' THEN
            SELECT (flag_record.target_regions @> (p_context->'region')) INTO is_enabled;
        
        WHEN 'device_type' THEN
            SELECT (flag_record.device_types @> (p_context->'device_type')) INTO is_enabled;
        
        WHEN 'hybrid' THEN
            -- Verifica lista de usuários específicos primeiro
            IF flag_record.target_users @> to_jsonb(p_user_id::text) THEN
                is_enabled := TRUE;
            ELSE
                -- Verifica role e aplica percentual
                IF flag_record.target_roles @> to_jsonb(p_user_role) THEN
                    user_hash := MD5(p_user_id::text || '_contextual_rollout');
                    user_percentage := (('x' || SUBSTR(user_hash, 1, 8))::bit(32)::int % 10000) / 100.0;
                    is_enabled := user_percentage < flag_record.rollout_percentage;
                END IF;
            END IF;
        
        ELSE
            is_enabled := FALSE;
    END CASE;
    
    RETURN is_enabled;
END;
$$ LANGUAGE plpgsql;

-- Função para obter configuração contextual de um usuário
CREATE OR REPLACE FUNCTION get_contextual_feature_config(
    p_user_id UUID,
    p_user_role VARCHAR(50),
    p_context JSONB DEFAULT '{}'::jsonb
)
RETURNS JSONB AS $$
DECLARE
    config JSONB;
    feature_enabled BOOLEAN;
    allocation_types JSONB := '[]'::jsonb;
    ui_components JSONB := '[]'::jsonb;
BEGIN
    -- Inicializa configuração
    config := '{
        "allocation_types_enabled": [],
        "ui_components_enabled": [],
        "metrics_collection_enabled": false,
        "dual_context_enabled": false,
        "advanced_kpis_enabled": false,
        "real_time_updates_enabled": false,
        "performance_monitoring_enabled": false
    }'::jsonb;
    
    -- Verifica contextual_case_view
    SELECT is_feature_enabled_for_user('contextual_case_view', p_user_id, p_user_role, p_context) INTO feature_enabled;
    IF feature_enabled THEN
        allocation_types := allocation_types || '"platform_match_direct"'::jsonb;
        ui_components := ui_components || '"contextual_case_card"'::jsonb;
    END IF;
    
    -- Verifica advanced_allocation_types
    SELECT is_feature_enabled_for_user('advanced_allocation_types', p_user_id, p_user_role, p_context) INTO feature_enabled;
    IF feature_enabled THEN
        allocation_types := allocation_types || '"platform_match_partnership"'::jsonb;
        allocation_types := allocation_types || '"partnership_proactive_search"'::jsonb;
        allocation_types := allocation_types || '"partnership_platform_suggestion"'::jsonb;
        allocation_types := allocation_types || '"internal_delegation"'::jsonb;
    END IF;
    
    -- Verifica contextual_kpis
    SELECT is_feature_enabled_for_user('contextual_kpis', p_user_id, p_user_role, p_context) INTO feature_enabled;
    IF feature_enabled THEN
        ui_components := ui_components || '"contextual_kpis"'::jsonb;
        config := config || '{"advanced_kpis_enabled": true}'::jsonb;
    END IF;
    
    -- Verifica contextual_actions
    SELECT is_feature_enabled_for_user('contextual_actions', p_user_id, p_user_role, p_context) INTO feature_enabled;
    IF feature_enabled THEN
        ui_components := ui_components || '"contextual_actions"'::jsonb;
    END IF;
    
    -- Verifica contextual_highlights
    SELECT is_feature_enabled_for_user('contextual_highlights', p_user_id, p_user_role, p_context) INTO feature_enabled;
    IF feature_enabled THEN
        ui_components := ui_components || '"contextual_highlights"'::jsonb;
    END IF;
    
    -- Verifica dual_context_navigation
    SELECT is_feature_enabled_for_user('dual_context_navigation', p_user_id, p_user_role, p_context) INTO feature_enabled;
    IF feature_enabled THEN
        config := config || '{"dual_context_enabled": true}'::jsonb;
    END IF;
    
    -- Verifica contextual_metrics
    SELECT is_feature_enabled_for_user('contextual_metrics', p_user_id, p_user_role, p_context) INTO feature_enabled;
    IF feature_enabled THEN
        config := config || '{"metrics_collection_enabled": true}'::jsonb;
    END IF;
    
    -- Verifica real_time_contextual_updates
    SELECT is_feature_enabled_for_user('real_time_contextual_updates', p_user_id, p_user_role, p_context) INTO feature_enabled;
    IF feature_enabled THEN
        config := config || '{"real_time_updates_enabled": true}'::jsonb;
    END IF;
    
    -- Verifica contextual_performance_monitoring
    SELECT is_feature_enabled_for_user('contextual_performance_monitoring', p_user_id, p_user_role, p_context) INTO feature_enabled;
    IF feature_enabled THEN
        config := config || '{"performance_monitoring_enabled": true}'::jsonb;
    END IF;
    
    -- Atualiza arrays na configuração
    config := config || jsonb_build_object(
        'allocation_types_enabled', allocation_types,
        'ui_components_enabled', ui_components
    );
    
    RETURN config;
END;
$$ LANGUAGE plpgsql;

-- Inserir feature flags iniciais para contextualização
INSERT INTO feature_flags (name, description, status, rollout_strategy, rollout_percentage, target_roles, metadata) VALUES
('contextual_case_view', 'Visualização contextual de casos - Fase 1: Admins e super admins', 'gradual_rollout', 'hybrid', 100.0, '["admin", "super_admin"]', '{"phase": "Fase 1: Admins e super admins", "contextual_feature": true}'),
('contextual_kpis', 'KPIs contextuais - Fase 2: 25% dos advogados', 'gradual_rollout', 'hybrid', 25.0, '["advogado"]', '{"phase": "Fase 2: 25% dos advogados", "contextual_feature": true}'),
('contextual_actions', 'Ações contextuais - Fase 3: 50% dos advogados', 'gradual_rollout', 'hybrid', 50.0, '["advogado"]', '{"phase": "Fase 3: 50% dos advogados", "contextual_feature": true}'),
('contextual_highlights', 'Destaques contextuais - Fase 4: 10% dos clientes', 'gradual_rollout', 'hybrid', 10.0, '["cliente"]', '{"phase": "Fase 4: 10% dos clientes", "contextual_feature": true}'),
('dual_context_navigation', 'Navegação em contexto duplo - Fase 5: Contexto duplo para advogados', 'gradual_rollout', 'hybrid', 10.0, '["advogado"]', '{"phase": "Fase 5: Contexto duplo para advogados", "contextual_feature": true}'),
('advanced_allocation_types', 'Tipos de alocação avançados', 'disabled', 'hybrid', 0.0, '[]', '{"contextual_feature": true}'),
('contextual_metrics', 'Métricas contextuais', 'disabled', 'hybrid', 0.0, '[]', '{"contextual_feature": true}'),
('real_time_contextual_updates', 'Atualizações contextuais em tempo real', 'disabled', 'hybrid', 0.0, '[]', '{"contextual_feature": true}'),
('contextual_performance_monitoring', 'Monitoramento de performance contextual', 'disabled', 'hybrid', 0.0, '[]', '{"contextual_feature": true}');

-- Políticas de segurança RLS
ALTER TABLE feature_flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE feature_flag_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE contextual_feature_configs ENABLE ROW LEVEL SECURITY;

-- Apenas admins podem ver/editar feature flags
CREATE POLICY "Admins can view feature flags" ON feature_flags
    FOR SELECT USING (auth.jwt() ->> 'user_role' IN ('admin', 'super_admin'));

CREATE POLICY "Admins can insert feature flags" ON feature_flags
    FOR INSERT WITH CHECK (auth.jwt() ->> 'user_role' IN ('admin', 'super_admin'));

CREATE POLICY "Admins can update feature flags" ON feature_flags
    FOR UPDATE USING (auth.jwt() ->> 'user_role' IN ('admin', 'super_admin'));

CREATE POLICY "Admins can delete feature flags" ON feature_flags
    FOR DELETE USING (auth.jwt() ->> 'user_role' IN ('admin', 'super_admin'));

-- Usuários podem ver seus próprios logs
CREATE POLICY "Users can view their own logs" ON feature_flag_logs
    FOR SELECT USING (user_id = auth.uid());

-- Sistema pode inserir logs
CREATE POLICY "System can insert logs" ON feature_flag_logs
    FOR INSERT WITH CHECK (true);

-- Usuários podem ver suas próprias configurações
CREATE POLICY "Users can view their own configs" ON contextual_feature_configs
    FOR SELECT USING (user_id = auth.uid());

-- Sistema pode inserir/atualizar configurações
CREATE POLICY "System can manage configs" ON contextual_feature_configs
    FOR ALL WITH CHECK (true);

-- Comentários para documentação
COMMENT ON TABLE feature_flags IS 'Armazena configurações de feature flags para rollout gradual';
COMMENT ON TABLE feature_flag_logs IS 'Logs de verificação de feature flags para analytics';
COMMENT ON TABLE contextual_feature_configs IS 'Cache de configurações contextuais por usuário';

COMMENT ON COLUMN feature_flags.rollout_percentage IS 'Percentual de usuários que recebem a feature (0-100)';
COMMENT ON COLUMN feature_flags.target_users IS 'Lista de IDs de usuários específicos';
COMMENT ON COLUMN feature_flags.target_roles IS 'Lista de roles que recebem a feature';
COMMENT ON COLUMN feature_flags.target_regions IS 'Lista de regiões geográficas';
COMMENT ON COLUMN feature_flags.device_types IS 'Lista de tipos de dispositivo';
COMMENT ON COLUMN feature_flags.metadata IS 'Metadados adicionais da feature flag';

COMMENT ON FUNCTION is_feature_enabled_for_user(VARCHAR, UUID, VARCHAR, JSONB) IS 'Verifica se feature está habilitada para usuário específico';
COMMENT ON FUNCTION get_contextual_feature_config(UUID, VARCHAR, JSONB) IS 'Obtém configuração contextual completa para usuário';
COMMENT ON FUNCTION cleanup_old_feature_flag_logs() IS 'Remove logs de feature flags com mais de 90 dias';
COMMENT ON FUNCTION cleanup_expired_contextual_configs() IS 'Remove configurações contextuais expiradas'; 