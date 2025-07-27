-- Migration: Create client_invitations table
-- Description: Sistema de convites de clientes para advogados externos
-- Author: LITIG System
-- Date: 2025-01-XX

-- ============================================================================
-- Table: client_invitations
-- ============================================================================

CREATE TABLE IF NOT EXISTS client_invitations (
    -- Identificadores
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL,
    target_name VARCHAR(255) NOT NULL,
    target_email VARCHAR(255),
    token VARCHAR(64) UNIQUE NOT NULL,
    
    -- Dados do caso
    case_summary TEXT NOT NULL,
    case_area VARCHAR(100),
    case_location VARCHAR(200),
    case_complexity VARCHAR(50),
    
    -- Status e controle
    status VARCHAR(30) NOT NULL DEFAULT 'pending',
    channel_attempted VARCHAR(50), -- 'platform_email', 'linkedin_assisted', 'none'
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    sent_at TIMESTAMP WITH TIME ZONE,
    opened_at TIMESTAMP WITH TIME ZONE,
    claimed_at TIMESTAMP WITH TIME ZONE,
    
    -- Dados de resposta (quando aplicável)
    response_data JSONB,
    lawyer_id UUID, -- Quando o convite é aceito e perfil criado
    
    -- Constraints
    CONSTRAINT valid_status CHECK (status IN (
        'pending', 'sent_platform_email', 'failed_email', 
        'linkedin_assisted', 'no_contact_method', 'opened', 
        'claimed', 'expired', 'accepted', 'rejected'
    )),
    CONSTRAINT valid_channel CHECK (channel_attempted IN (
        'platform_email', 'linkedin_assisted', 'none', NULL
    )),
    CONSTRAINT expires_after_creation CHECK (expires_at > created_at)
);

-- ============================================================================
-- Indexes for Performance
-- ============================================================================

-- Index para busca rápida por token (usado no claim)
CREATE INDEX idx_client_invitations_token ON client_invitations(token) WHERE status NOT IN ('expired', 'accepted', 'rejected');

-- Index para busca por cliente
CREATE INDEX idx_client_invitations_client_id ON client_invitations(client_id);

-- Index para analytics por período
CREATE INDEX idx_client_invitations_created_at ON client_invitations(created_at);

-- Index para limpeza de convites expirados
CREATE INDEX idx_client_invitations_expires_at ON client_invitations(expires_at) WHERE status = 'pending';

-- Index composto para analytics de conversão
CREATE INDEX idx_client_invitations_status_channel ON client_invitations(status, channel_attempted, created_at);

-- ============================================================================
-- Functions for Business Logic
-- ============================================================================

-- Função para expirar convites automaticamente
CREATE OR REPLACE FUNCTION expire_old_invitations()
RETURNS INTEGER AS $$
DECLARE
    expired_count INTEGER;
BEGIN
    UPDATE client_invitations 
    SET status = 'expired'
    WHERE status = 'pending' 
      AND expires_at < NOW()
      AND status != 'expired';
    
    GET DIAGNOSTICS expired_count = ROW_COUNT;
    
    RETURN expired_count;
END;
$$ LANGUAGE plpgsql;

-- Função para gerar estatísticas de conversão
CREATE OR REPLACE FUNCTION get_invitation_stats(
    start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() - INTERVAL '30 days',
    end_date TIMESTAMP WITH TIME ZONE DEFAULT NOW()
)
RETURNS TABLE(
    total_invitations BIGINT,
    email_sent BIGINT,
    email_success_rate NUMERIC(5,2),
    linkedin_fallback BIGINT,
    linkedin_fallback_rate NUMERIC(5,2),
    claimed_invitations BIGINT,
    conversion_rate NUMERIC(5,2),
    avg_response_time_hours NUMERIC(8,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as total_invitations,
        COUNT(*) FILTER (WHERE status = 'sent_platform_email') as email_sent,
        ROUND(
            (COUNT(*) FILTER (WHERE status = 'sent_platform_email')::NUMERIC / NULLIF(COUNT(*), 0)) * 100, 
            2
        ) as email_success_rate,
        COUNT(*) FILTER (WHERE status = 'linkedin_assisted') as linkedin_fallback,
        ROUND(
            (COUNT(*) FILTER (WHERE status = 'linkedin_assisted')::NUMERIC / NULLIF(COUNT(*), 0)) * 100, 
            2
        ) as linkedin_fallback_rate,
        COUNT(*) FILTER (WHERE status IN ('claimed', 'accepted')) as claimed_invitations,
        ROUND(
            (COUNT(*) FILTER (WHERE status IN ('claimed', 'accepted'))::NUMERIC / NULLIF(COUNT(*), 0)) * 100, 
            2
        ) as conversion_rate,
        ROUND(
            AVG(EXTRACT(EPOCH FROM (claimed_at - created_at))/3600) FILTER (WHERE claimed_at IS NOT NULL),
            2
        ) as avg_response_time_hours
    FROM client_invitations 
    WHERE created_at >= start_date 
      AND created_at <= end_date;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- Triggers for Audit and Validation
-- ============================================================================

-- Trigger para atualizar timestamps automaticamente
CREATE OR REPLACE FUNCTION update_invitation_timestamps()
RETURNS TRIGGER AS $$
BEGIN
    -- Atualizar sent_at quando status muda para enviado
    IF NEW.status IN ('sent_platform_email', 'linkedin_assisted') AND OLD.status = 'pending' THEN
        NEW.sent_at = NOW();
    END IF;
    
    -- Atualizar claimed_at quando status muda para claimed
    IF NEW.status = 'claimed' AND OLD.status != 'claimed' THEN
        NEW.claimed_at = NOW();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_invitation_timestamps
    BEFORE UPDATE ON client_invitations
    FOR EACH ROW
    EXECUTE FUNCTION update_invitation_timestamps();

-- ============================================================================
-- Sample Data for Testing (Development Only)
-- ============================================================================

-- Esta seção só deve ser executada em ambiente de desenvolvimento
-- DO $$
-- BEGIN
--     IF current_setting('server_version_num')::int >= 120000 THEN
--         -- Inserir alguns convites de exemplo apenas se estiver em dev
--         INSERT INTO client_invitations (
--             client_id, target_name, target_email, token, case_summary,
--             case_area, case_location, status, expires_at
--         ) VALUES 
--         (
--             gen_random_uuid(), 
--             'Dr. João Silva',
--             'joao.silva@example.com',
--             encode(gen_random_bytes(32), 'hex'),
--             'Caso de direito tributário para empresa de médio porte',
--             'Direito Tributário',
--             'São Paulo, SP',
--             'pending',
--             NOW() + INTERVAL '7 days'
--         ),
--         (
--             gen_random_uuid(),
--             'Dra. Maria Santos', 
--             NULL,
--             encode(gen_random_bytes(32), 'hex'),
--             'Questão trabalhista urgente',
--             'Direito Trabalhista',
--             'Rio de Janeiro, RJ', 
--             'linkedin_assisted',
--             NOW() + INTERVAL '7 days'
--         );
--     END IF;
-- END $$;

-- ============================================================================
-- Comments for Documentation
-- ============================================================================

COMMENT ON TABLE client_invitations IS 'Convites enviados por clientes para advogados externos não cadastrados na plataforma';

COMMENT ON COLUMN client_invitations.id IS 'Identificador único do convite';
COMMENT ON COLUMN client_invitations.client_id IS 'ID do cliente que fez a solicitação';
COMMENT ON COLUMN client_invitations.target_name IS 'Nome do advogado alvo do convite';
COMMENT ON COLUMN client_invitations.target_email IS 'E-mail público encontrado do advogado (se disponível)';
COMMENT ON COLUMN client_invitations.token IS 'Token único para reivindicação de perfil';
COMMENT ON COLUMN client_invitations.case_summary IS 'Resumo do caso que motivou o convite';
COMMENT ON COLUMN client_invitations.status IS 'Status atual do convite no pipeline de conversão';
COMMENT ON COLUMN client_invitations.channel_attempted IS 'Canal de contato utilizado na tentativa';
COMMENT ON COLUMN client_invitations.expires_at IS 'Data de expiração do token de convite';
COMMENT ON COLUMN client_invitations.response_data IS 'Dados estruturados de resposta (LinkedIn URLs, etc.)';
COMMENT ON COLUMN client_invitations.lawyer_id IS 'ID do advogado criado quando convite é aceito';

-- ============================================================================
-- Permissions and Security
-- ============================================================================

-- Revogar permissões públicas
REVOKE ALL ON client_invitations FROM PUBLIC;

-- Conceder permissões específicas (ajustar conforme roles do sistema)
-- GRANT SELECT, INSERT, UPDATE ON client_invitations TO litig_api_role;
-- GRANT SELECT ON client_invitations TO litig_analytics_role;

-- ============================================================================
-- Cleanup Job (Optional - via cron or scheduled task)
-- ============================================================================

-- Esta função pode ser chamada periodicamente para limpar convites expirados
-- CREATE OR REPLACE FUNCTION cleanup_expired_invitations()
-- RETURNS INTEGER AS $$
-- DECLARE
--     deleted_count INTEGER;
-- BEGIN
--     -- Expirar convites pendentes que passaram da data
--     PERFORM expire_old_invitations();
--     
--     -- Deletar convites expirados há mais de 90 dias (opcional)
--     DELETE FROM client_invitations 
--     WHERE status = 'expired' 
--       AND expires_at < NOW() - INTERVAL '90 days';
--     
--     GET DIAGNOSTICS deleted_count = ROW_COUNT;
--     
--     RETURN deleted_count;
-- END;
-- $$ LANGUAGE plpgsql; 