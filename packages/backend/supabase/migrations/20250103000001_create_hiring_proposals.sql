-- Migration: Create hiring_proposals and contracts tables
-- Date: 2025-01-03

-- Tabela principal de propostas de contratação
CREATE TABLE hiring_proposals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    lawyer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    case_id UUID NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
    contract_type VARCHAR(20) NOT NULL CHECK (contract_type IN ('hourly', 'fixed', 'success')),
    budget DECIMAL(12,2) NOT NULL CHECK (budget > 0),
    notes TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'cancelled', 'expired')),
    response_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    responded_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '7 days'),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de contratos criados após aceitação de propostas
CREATE TABLE contracts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    proposal_id UUID NOT NULL REFERENCES hiring_proposals(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    lawyer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    case_id UUID NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
    contract_type VARCHAR(20) NOT NULL CHECK (contract_type IN ('hourly', 'fixed', 'success')),
    budget DECIMAL(12,2) NOT NULL CHECK (budget > 0),
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled', 'disputed')),
    signed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    total_paid DECIMAL(12,2) DEFAULT 0 CHECK (total_paid >= 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_hiring_proposals_client_id ON hiring_proposals(client_id);
CREATE INDEX idx_hiring_proposals_lawyer_id ON hiring_proposals(lawyer_id);
CREATE INDEX idx_hiring_proposals_case_id ON hiring_proposals(case_id);
CREATE INDEX idx_hiring_proposals_status ON hiring_proposals(status);
CREATE INDEX idx_hiring_proposals_created_at ON hiring_proposals(created_at);
CREATE INDEX idx_hiring_proposals_expires_at ON hiring_proposals(expires_at);

CREATE INDEX idx_contracts_proposal_id ON contracts(proposal_id);
CREATE INDEX idx_contracts_client_id ON contracts(client_id);
CREATE INDEX idx_contracts_lawyer_id ON contracts(lawyer_id);
CREATE INDEX idx_contracts_case_id ON contracts(case_id);
CREATE INDEX idx_contracts_status ON contracts(status);
CREATE INDEX idx_contracts_signed_at ON contracts(signed_at);

-- Função para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para atualizar updated_at
CREATE TRIGGER update_hiring_proposals_updated_at
    BEFORE UPDATE ON hiring_proposals
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_contracts_updated_at
    BEFORE UPDATE ON contracts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Função para expirar propostas automaticamente
CREATE OR REPLACE FUNCTION expire_old_proposals()
RETURNS INTEGER AS $$
DECLARE
    expired_count INTEGER;
BEGIN
    UPDATE hiring_proposals 
    SET status = 'expired', updated_at = NOW()
    WHERE status = 'pending' 
    AND expires_at < NOW();
    
    GET DIAGNOSTICS expired_count = ROW_COUNT;
    RETURN expired_count;
END;
$$ LANGUAGE plpgsql;

-- Policy de segurança - Row Level Security (RLS)
ALTER TABLE hiring_proposals ENABLE ROW LEVEL SECURITY;
ALTER TABLE contracts ENABLE ROW LEVEL SECURITY;

-- Policies para hiring_proposals
CREATE POLICY "Users can view their own proposals" ON hiring_proposals
    FOR SELECT USING (
        auth.uid() = client_id OR auth.uid() = lawyer_id
    );

CREATE POLICY "Clients can create proposals" ON hiring_proposals
    FOR INSERT WITH CHECK (
        auth.uid() = client_id AND 
        EXISTS (
            SELECT 1 FROM cases 
            WHERE id = case_id AND client_id = auth.uid()
        )
    );

CREATE POLICY "Users can update their proposals" ON hiring_proposals
    FOR UPDATE USING (
        auth.uid() = client_id OR auth.uid() = lawyer_id
    ) WITH CHECK (
        auth.uid() = client_id OR auth.uid() = lawyer_id
    );

-- Policies para contracts
CREATE POLICY "Users can view their contracts" ON contracts
    FOR SELECT USING (
        auth.uid() = client_id OR auth.uid() = lawyer_id
    );

CREATE POLICY "System can create contracts" ON contracts
    FOR INSERT WITH CHECK (true); -- Será criado pelo sistema

CREATE POLICY "Users can update their contracts" ON contracts
    FOR UPDATE USING (
        auth.uid() = client_id OR auth.uid() = lawyer_id
    ) WITH CHECK (
        auth.uid() = client_id OR auth.uid() = lawyer_id
    );

-- Comentários nas tabelas
COMMENT ON TABLE hiring_proposals IS 'Propostas de contratação enviadas por clientes para advogados';
COMMENT ON TABLE contracts IS 'Contratos formalizados após aceitação de propostas';

COMMENT ON COLUMN hiring_proposals.contract_type IS 'Tipo de contrato: hourly (por hora), fixed (valor fixo), success (por êxito)';
COMMENT ON COLUMN hiring_proposals.status IS 'Status da proposta: pending, accepted, rejected, cancelled, expired';
COMMENT ON COLUMN hiring_proposals.expires_at IS 'Data limite para resposta do advogado (padrão: 7 dias)';

COMMENT ON COLUMN contracts.status IS 'Status do contrato: active, completed, cancelled, disputed';
COMMENT ON COLUMN contracts.total_paid IS 'Valor total já pago no contrato'; 