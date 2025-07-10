-- Migração: Tabela de Ofertas (Sinal de Interesse)
-- Implementa as Fases 4 & 5 do fluxo de match

CREATE TABLE IF NOT EXISTS offers (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id          UUID NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
    lawyer_id        UUID NOT NULL REFERENCES lawyers(id) ON DELETE CASCADE,
    status           TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','interested','declined','expired','closed')),
    sent_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    responded_at     TIMESTAMPTZ,
    expires_at       TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '24 hours'),
    
    -- Snapshot do score para auditoria
    fair_score       NUMERIC,
    raw_score        NUMERIC,
    equity_weight    NUMERIC,
    
    -- Metadados para round-robin
    last_offered_at  TIMESTAMPTZ,
    
    -- Timestamps padrão
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Índices para performance
CREATE UNIQUE INDEX IF NOT EXISTS offers_case_lawyer_ux ON offers(case_id, lawyer_id);
CREATE INDEX IF NOT EXISTS offers_lawyer_status_idx ON offers(lawyer_id, status);
CREATE INDEX IF NOT EXISTS offers_case_status_idx ON offers(case_id, status);
CREATE INDEX IF NOT EXISTS offers_expires_at_idx ON offers(expires_at) WHERE status = 'pending';

-- Trigger para atualizar updated_at
CREATE OR REPLACE FUNCTION update_offers_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER offers_updated_at_trigger
    BEFORE UPDATE ON offers
    FOR EACH ROW
    EXECUTE FUNCTION update_offers_updated_at();

-- Função para expirar ofertas automaticamente
CREATE OR REPLACE FUNCTION expire_pending_offers()
RETURNS INTEGER AS $$
DECLARE
    expired_count INTEGER;
BEGIN
    UPDATE offers 
    SET status = 'expired', 
        updated_at = NOW()
    WHERE status = 'pending' 
      AND expires_at < NOW();
    
    GET DIAGNOSTICS expired_count = ROW_COUNT;
    RETURN expired_count;
END;
$$ LANGUAGE plpgsql;

-- Comentários para documentação
COMMENT ON TABLE offers IS 'Ofertas de casos para advogados - Fases 4 & 5 do fluxo de match';
COMMENT ON COLUMN offers.status IS 'Status da oferta: pending (aguardando), interested (interessado), declined (recusado), expired (expirado), closed (caso fechado)';
COMMENT ON COLUMN offers.expires_at IS 'Data limite para resposta do advogado (SLA de 24h)';
COMMENT ON FUNCTION expire_pending_offers() IS 'Expira ofertas pendentes que passaram do prazo'; 