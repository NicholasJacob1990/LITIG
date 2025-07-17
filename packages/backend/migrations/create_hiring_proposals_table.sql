-- Migration: Create hiring_proposals table
-- Created: 2024-01-17
-- Description: Tabela para propostas de contratação de advogados

-- Criar tabela para propostas de contratação
CREATE TABLE hiring_proposals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    lawyer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    case_id UUID NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
    contract_type VARCHAR(20) NOT NULL CHECK (contract_type IN ('hourly', 'fixed', 'success')),
    budget DECIMAL(10,2) NOT NULL CHECK (budget > 0),
    notes TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'expired')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    responded_at TIMESTAMP WITH TIME ZONE,
    response_message TEXT,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT (NOW() + INTERVAL '7 days'),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Criar índices para performance
CREATE INDEX idx_hiring_proposals_lawyer_id ON hiring_proposals(lawyer_id);
CREATE INDEX idx_hiring_proposals_client_id ON hiring_proposals(client_id);
CREATE INDEX idx_hiring_proposals_case_id ON hiring_proposals(case_id);
CREATE INDEX idx_hiring_proposals_status ON hiring_proposals(status);
CREATE INDEX idx_hiring_proposals_created_at ON hiring_proposals(created_at);
CREATE INDEX idx_hiring_proposals_expires_at ON hiring_proposals(expires_at);

-- Criar tabela para contratos
CREATE TABLE contracts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    proposal_id UUID NOT NULL REFERENCES hiring_proposals(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    lawyer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    case_id UUID NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
    contract_type VARCHAR(20) NOT NULL CHECK (contract_type IN ('hourly', 'fixed', 'success')),
    budget DECIMAL(10,2) NOT NULL CHECK (budget > 0),
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Campos específicos para contratos
    start_date DATE,
    end_date DATE,
    hours_worked DECIMAL(5,2) DEFAULT 0,
    amount_paid DECIMAL(10,2) DEFAULT 0,
    payment_schedule VARCHAR(20) DEFAULT 'monthly' CHECK (payment_schedule IN ('weekly', 'monthly', 'milestone', 'completion')),
    
    -- Constraints
    CONSTRAINT unique_active_contract_per_case UNIQUE (case_id, status) WHERE status = 'active'
);

-- Criar índices para contratos
CREATE INDEX idx_contracts_proposal_id ON contracts(proposal_id);
CREATE INDEX idx_contracts_client_id ON contracts(client_id);
CREATE INDEX idx_contracts_lawyer_id ON contracts(lawyer_id);
CREATE INDEX idx_contracts_case_id ON contracts(case_id);
CREATE INDEX idx_contracts_status ON contracts(status);
CREATE INDEX idx_contracts_created_at ON contracts(created_at);

-- Criar trigger para atualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_hiring_proposals_updated_at
    BEFORE UPDATE ON hiring_proposals
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_contracts_updated_at
    BEFORE UPDATE ON contracts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Criar trigger para expirar propostas automaticamente
CREATE OR REPLACE FUNCTION expire_old_proposals()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE hiring_proposals
    SET status = 'expired'
    WHERE status = 'pending' AND expires_at < NOW();
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Criar função para limpeza periódica (deve ser chamada por um job scheduler)
CREATE OR REPLACE FUNCTION cleanup_expired_proposals()
RETURNS INTEGER AS $$
DECLARE
    affected_rows INTEGER;
BEGIN
    UPDATE hiring_proposals
    SET status = 'expired'
    WHERE status = 'pending' AND expires_at < NOW();
    
    GET DIAGNOSTICS affected_rows = ROW_COUNT;
    
    RETURN affected_rows;
END;
$$ LANGUAGE plpgsql;

-- Criar view para propostas ativas
CREATE VIEW active_hiring_proposals AS
SELECT 
    hp.*,
    c.name as client_name,
    c.email as client_email,
    l.name as lawyer_name,
    l.email as lawyer_email,
    cs.title as case_title,
    cs.description as case_description
FROM hiring_proposals hp
JOIN users c ON hp.client_id = c.id
JOIN users l ON hp.lawyer_id = l.id
JOIN cases cs ON hp.case_id = cs.id
WHERE hp.status = 'pending' AND hp.expires_at > NOW();

-- Criar view para contratos ativos
CREATE VIEW active_contracts AS
SELECT 
    ct.*,
    c.name as client_name,
    c.email as client_email,
    l.name as lawyer_name,
    l.email as lawyer_email,
    cs.title as case_title,
    cs.description as case_description
FROM contracts ct
JOIN users c ON ct.client_id = c.id
JOIN users l ON ct.lawyer_id = l.id
JOIN cases cs ON ct.case_id = cs.id
WHERE ct.status = 'active';

-- Inserir alguns dados de exemplo (opcional, para desenvolvimento)
-- INSERT INTO hiring_proposals (client_id, lawyer_id, case_id, contract_type, budget, notes)
-- VALUES 
-- ((SELECT id FROM users WHERE email = 'client@example.com' LIMIT 1),
--  (SELECT id FROM users WHERE email = 'lawyer@example.com' LIMIT 1),
--  (SELECT id FROM cases LIMIT 1),
--  'hourly',
--  150.00,
--  'Proposta de contratação para consultoria jurídica');

-- Comentários para documentação
COMMENT ON TABLE hiring_proposals IS 'Propostas de contratação enviadas por clientes para advogados';
COMMENT ON TABLE contracts IS 'Contratos firmados entre clientes e advogados';
COMMENT ON COLUMN hiring_proposals.contract_type IS 'Tipo de contrato: hourly (por hora), fixed (valor fixo), success (taxa de êxito)';
COMMENT ON COLUMN hiring_proposals.budget IS 'Orçamento proposto pelo cliente';
COMMENT ON COLUMN hiring_proposals.expires_at IS 'Data de expiração da proposta (padrão: 7 dias)';
COMMENT ON COLUMN contracts.payment_schedule IS 'Cronograma de pagamento: weekly, monthly, milestone, completion';
COMMENT ON COLUMN contracts.hours_worked IS 'Horas trabalhadas no contrato (para contratos por hora)';
COMMENT ON COLUMN contracts.amount_paid IS 'Valor já pago do contrato';

-- Conceder permissões (ajustar conforme necessário)
-- GRANT SELECT, INSERT, UPDATE ON hiring_proposals TO app_user;
-- GRANT SELECT, INSERT, UPDATE ON contracts TO app_user;
-- GRANT SELECT ON active_hiring_proposals TO app_user;
-- GRANT SELECT ON active_contracts TO app_user;