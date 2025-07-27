-- =====================================================
-- LITIG Partnership Growth Plan - Database Migration
-- =====================================================
-- Versão: v1.0
-- Data: 2025-07-26
-- Objetivo: Adicionar tabelas para sistema de parcerias híbridas

-- =====================================================
-- 1. PARTNERSHIP INVITATIONS - Sistema de Convites
-- =====================================================

CREATE TABLE IF NOT EXISTS partnership_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token VARCHAR(64) UNIQUE NOT NULL,
    
    -- Quem convida
    inviter_lawyer_id VARCHAR(50) NOT NULL,
    inviter_name VARCHAR(200) NOT NULL,
    
    -- Quem é convidado (dados do perfil público)
    invitee_name VARCHAR(200) NOT NULL,
    invitee_profile_url TEXT,
    invitee_context JSONB,  -- Dados completos do perfil externo
    
    -- Contexto do convite
    area_expertise VARCHAR(100),
    compatibility_score VARCHAR(10),  -- Score formatado (ex: "85%")
    partnership_reason TEXT,
    
    -- Status e controle
    status VARCHAR(20) DEFAULT 'pending' NOT NULL 
        CHECK (status IN ('pending', 'accepted', 'expired', 'cancelled')),
    expires_at TIMESTAMP NOT NULL,
    
    -- Metadados
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    accepted_at TIMESTAMP,
    new_lawyer_id VARCHAR(50),  -- ID do advogado após cadastro
    
    -- Configurações
    linkedin_message_template TEXT,
    claim_url TEXT NOT NULL
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_partnership_invitations_inviter 
    ON partnership_invitations(inviter_lawyer_id);
CREATE INDEX IF NOT EXISTS idx_partnership_invitations_status 
    ON partnership_invitations(status);
CREATE INDEX IF NOT EXISTS idx_partnership_invitations_expires 
    ON partnership_invitations(expires_at);
CREATE INDEX IF NOT EXISTS idx_partnership_invitations_token 
    ON partnership_invitations(token);

-- Comentários
COMMENT ON TABLE partnership_invitations IS 'Convites de parceria enviados a perfis públicos externos';
COMMENT ON COLUMN partnership_invitations.token IS 'Token único e seguro para reivindicar convite';
COMMENT ON COLUMN partnership_invitations.invitee_context IS 'Dados JSON do perfil externo completo';
COMMENT ON COLUMN partnership_invitations.claim_url IS 'URL completa para reivindicar o convite';

-- =====================================================
-- 2. ENGAGEMENT INDEX - Campos na tabela lawyers
-- =====================================================

-- Adicionar campos de engajamento na tabela lawyers (se não existirem)
DO $$ 
BEGIN
    -- Campo para score de engajamento
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'lawyers' AND column_name = 'interaction_score') THEN
        ALTER TABLE lawyers ADD COLUMN interaction_score FLOAT DEFAULT 0.5;
    END IF;
    
    -- Campo para trend de engajamento
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'lawyers' AND column_name = 'engagement_trend') THEN
        ALTER TABLE lawyers ADD COLUMN engagement_trend VARCHAR(20);
    END IF;
    
    -- Campo para timestamp da última atualização
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'lawyers' AND column_name = 'engagement_updated_at') THEN
        ALTER TABLE lawyers ADD COLUMN engagement_updated_at TIMESTAMP;
    END IF;
END $$;

-- Índice para ordenação por score de engajamento
CREATE INDEX IF NOT EXISTS idx_lawyers_interaction_score 
    ON lawyers(interaction_score DESC);

-- Comentários
COMMENT ON COLUMN lawyers.interaction_score IS 'Índice de Engajamento na Plataforma (IEP) - score 0.0 a 1.0';
COMMENT ON COLUMN lawyers.engagement_trend IS 'Tendência do engajamento: improving, declining, stable';
COMMENT ON COLUMN lawyers.engagement_updated_at IS 'Timestamp da última atualização do IEP';

-- =====================================================
-- 3. ENGAGEMENT HISTORY - Histórico de scores IEP
-- =====================================================

CREATE TABLE IF NOT EXISTS lawyer_engagement_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lawyer_id VARCHAR(50) NOT NULL,
    iep_score FLOAT NOT NULL CHECK (iep_score >= 0.0 AND iep_score <= 1.0),
    metrics_json JSONB,  -- Métricas detalhadas do cálculo
    calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_engagement_history_lawyer 
    ON lawyer_engagement_history(lawyer_id);
CREATE INDEX IF NOT EXISTS idx_engagement_history_calculated 
    ON lawyer_engagement_history(calculated_at DESC);
CREATE INDEX IF NOT EXISTS idx_engagement_history_score 
    ON lawyer_engagement_history(iep_score DESC);

-- Comentários
COMMENT ON TABLE lawyer_engagement_history IS 'Histórico de cálculos do Índice de Engajamento (IEP)';
COMMENT ON COLUMN lawyer_engagement_history.iep_score IS 'Score IEP calculado (0.0 - 1.0)';
COMMENT ON COLUMN lawyer_engagement_history.metrics_json IS 'Métricas detalhadas usadas no cálculo';

-- =====================================================
-- 4. JOB EXECUTION LOGS - Logs de execução de jobs
-- =====================================================

CREATE TABLE IF NOT EXISTS job_execution_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_name VARCHAR(100) NOT NULL,
    metadata JSONB,  -- Dados da execução (estatísticas, erros, etc.)
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('completed', 'error', 'up_to_date'))
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_job_logs_name 
    ON job_execution_logs(job_name);
CREATE INDEX IF NOT EXISTS idx_job_logs_executed 
    ON job_execution_logs(executed_at DESC);
CREATE INDEX IF NOT EXISTS idx_job_logs_status 
    ON job_execution_logs(status);

-- Comentários
COMMENT ON TABLE job_execution_logs IS 'Logs de execução de jobs em background';
COMMENT ON COLUMN job_execution_logs.job_name IS 'Nome do job executado';
COMMENT ON COLUMN job_execution_logs.metadata IS 'Dados da execução em formato JSON';

-- =====================================================
-- 5. SEED DATA - Dados iniciais
-- =====================================================

-- Inserir configuração inicial para jobs
INSERT INTO job_execution_logs (job_name, metadata, status) 
VALUES ('calculate_engagement_scores', 
        '{"initial_setup": true, "total_lawyers": 0, "note": "Sistema inicializado"}',
        'completed')
ON CONFLICT DO NOTHING;

-- =====================================================
-- 6. VERIFICAÇÃO E VALIDAÇÃO
-- =====================================================

-- Verificar se todas as tabelas foram criadas
DO $$
DECLARE
    missing_tables TEXT[] := ARRAY[]::TEXT[];
BEGIN
    -- Verificar partnership_invitations
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables 
                   WHERE table_name = 'partnership_invitations') THEN
        missing_tables := array_append(missing_tables, 'partnership_invitations');
    END IF;
    
    -- Verificar lawyer_engagement_history
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables 
                   WHERE table_name = 'lawyer_engagement_history') THEN
        missing_tables := array_append(missing_tables, 'lawyer_engagement_history');
    END IF;
    
    -- Verificar job_execution_logs
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables 
                   WHERE table_name = 'job_execution_logs') THEN
        missing_tables := array_append(missing_tables, 'job_execution_logs');
    END IF;
    
    -- Reportar resultado
    IF array_length(missing_tables, 1) > 0 THEN
        RAISE EXCEPTION 'MIGRATION FAILED: Missing tables: %', array_to_string(missing_tables, ', ');
    ELSE
        RAISE NOTICE 'MIGRATION SUCCESS: All partnership tables created successfully!';
        RAISE NOTICE 'Tables: partnership_invitations, lawyer_engagement_history, job_execution_logs';
        RAISE NOTICE 'Fields added to lawyers: interaction_score, engagement_trend, engagement_updated_at';
    END IF;
END $$;

-- =====================================================
-- FIM DA MIGRATION
-- ===================================================== 