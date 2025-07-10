-- Criar tabela principal de contratos
CREATE TABLE contracts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id UUID NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
    lawyer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending-signature'
        CHECK (status IN ('pending-signature', 'active', 'closed', 'canceled')),
    fee_model JSONB NOT NULL, -- {type:"success",percent:20} ou {type:"fixed",value:5000}
    created_at TIMESTAMPTZ DEFAULT NOW(),
    signed_client TIMESTAMPTZ,
    signed_lawyer TIMESTAMPTZ,
    doc_url TEXT, -- PDF no Storage / DocuSign envelopeId
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Impedir dois contratos ativos para o mesmo caso
CREATE UNIQUE INDEX contracts_case_ux ON contracts(case_id) 
WHERE status IN ('pending-signature', 'active');

-- Índices para performance
CREATE INDEX idx_contracts_lawyer_id ON contracts(lawyer_id);
CREATE INDEX idx_contracts_client_id ON contracts(client_id);
CREATE INDEX idx_contracts_status ON contracts(status);
CREATE INDEX idx_contracts_created_at ON contracts(created_at);

-- Trigger para atualizar updated_at automaticamente
CREATE TRIGGER update_contracts_updated_at
    BEFORE UPDATE ON contracts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- RLS (Row Level Security) para contracts
ALTER TABLE contracts ENABLE ROW LEVEL SECURITY;

-- Política: usuários podem ver contratos onde são cliente ou advogado
CREATE POLICY "Users can view their own contracts" ON contracts
    FOR SELECT USING (
        client_id = auth.uid() OR lawyer_id = auth.uid()
    );

-- Política: apenas clientes podem criar contratos
CREATE POLICY "Clients can create contracts" ON contracts
    FOR INSERT WITH CHECK (
        client_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM cases 
            WHERE id = case_id AND client_id = auth.uid()
        )
    );

-- Política: cliente e advogado podem atualizar (para assinatura)
CREATE POLICY "Parties can update contracts" ON contracts
    FOR UPDATE USING (
        client_id = auth.uid() OR lawyer_id = auth.uid()
    );

-- Política: apenas sistema pode deletar
CREATE POLICY "System can delete contracts" ON contracts
    FOR DELETE USING (auth.role() = 'service_role');

-- Função para buscar contratos de um usuário
CREATE OR REPLACE FUNCTION get_user_contracts(user_id UUID)
RETURNS TABLE (
    id UUID,
    case_id UUID,
    lawyer_id UUID,
    client_id UUID,
    status TEXT,
    fee_model JSONB,
    created_at TIMESTAMPTZ,
    signed_client TIMESTAMPTZ,
    signed_lawyer TIMESTAMPTZ,
    doc_url TEXT,
    updated_at TIMESTAMPTZ,
    case_title TEXT,
    case_area TEXT,
    lawyer_name TEXT,
    client_name TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.case_id,
        c.lawyer_id,
        c.client_id,
        c.status,
        c.fee_model,
        c.created_at,
        c.signed_client,
        c.signed_lawyer,
        c.doc_url,
        c.updated_at,
        cs.title as case_title,
        cs.area as case_area,
        lp.full_name as lawyer_name,
        cp.full_name as client_name
    FROM contracts c
    JOIN cases cs ON c.case_id = cs.id
    JOIN profiles lp ON c.lawyer_id = lp.id
    JOIN profiles cp ON c.client_id = cp.id
    WHERE c.client_id = user_id OR c.lawyer_id = user_id
    ORDER BY c.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para ativar contrato quando ambas as partes assinaram
CREATE OR REPLACE FUNCTION check_contract_activation()
RETURNS TRIGGER AS $$
BEGIN
    -- Se ambas as assinaturas estão presentes, ativar contrato
    IF NEW.signed_client IS NOT NULL AND NEW.signed_lawyer IS NOT NULL AND NEW.status = 'pending-signature' THEN
        NEW.status = 'active';
        NEW.updated_at = NOW();
        
        -- Fechar todas as outras ofertas para este caso
        UPDATE offers 
        SET status = 'closed', updated_at = NOW()
        WHERE case_id = NEW.case_id AND status IN ('pending', 'interested');
        
        -- Log da ativação
        INSERT INTO audit_log (table_name, record_id, action, details, user_id)
        VALUES (
            'contracts',
            NEW.id,
            'activated',
            jsonb_build_object(
                'case_id', NEW.case_id,
                'lawyer_id', NEW.lawyer_id,
                'client_id', NEW.client_id,
                'fee_model', NEW.fee_model
            ),
            NEW.client_id
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para ativação automática
CREATE TRIGGER contract_activation_trigger
    BEFORE UPDATE ON contracts
    FOR EACH ROW
    EXECUTE FUNCTION check_contract_activation();

-- Função para validar modelo de honorários
CREATE OR REPLACE FUNCTION validate_fee_model(fee_model JSONB)
RETURNS BOOLEAN AS $$
DECLARE
    fee_type TEXT;
    fee_value NUMERIC;
BEGIN
    -- Extrair tipo
    fee_type := fee_model->>'type';
    
    -- Validar tipos permitidos
    IF fee_type NOT IN ('success', 'fixed', 'hourly') THEN
        RETURN FALSE;
    END IF;
    
    -- Validar valores baseado no tipo
    CASE fee_type
        WHEN 'success' THEN
            fee_value := (fee_model->>'percent')::NUMERIC;
            RETURN fee_value > 0 AND fee_value <= 100;
        WHEN 'fixed' THEN
            fee_value := (fee_model->>'value')::NUMERIC;
            RETURN fee_value > 0;
        WHEN 'hourly' THEN
            fee_value := (fee_model->>'rate')::NUMERIC;
            RETURN fee_value > 0;
        ELSE
            RETURN FALSE;
    END CASE;
END;
$$ LANGUAGE plpgsql;

-- Constraint para validar fee_model
ALTER TABLE contracts 
ADD CONSTRAINT valid_fee_model 
CHECK (validate_fee_model(fee_model));

-- Comentários para documentação
COMMENT ON TABLE contracts IS 'Contratos formalizados entre clientes e advogados';
COMMENT ON COLUMN contracts.status IS 'Status: pending-signature, active, closed, canceled';
COMMENT ON COLUMN contracts.fee_model IS 'Modelo de honorários: success (%), fixed (valor), hourly (por hora)';
COMMENT ON COLUMN contracts.doc_url IS 'URL do documento PDF ou ID do envelope DocuSign';
COMMENT ON COLUMN contracts.signed_client IS 'Timestamp da assinatura do cliente';
COMMENT ON COLUMN contracts.signed_lawyer IS 'Timestamp da assinatura do advogado';

-- Grants para as funções
GRANT EXECUTE ON FUNCTION get_user_contracts(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION validate_fee_model(JSONB) TO authenticated; 