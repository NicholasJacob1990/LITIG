-- Migração: Aprimoramento da Tabela de Ofertas para Sistema Unificado
-- Adiciona campos necessários para o novo fluxo de ofertas

-- Adicionar novos status
ALTER TABLE offers 
DROP CONSTRAINT IF EXISTS offers_status_check;

ALTER TABLE offers 
ADD CONSTRAINT offers_status_check 
CHECK (status IN ('pending','interested','accepted','declined','rejected','expired','closed'));

-- Adicionar novos campos
ALTER TABLE offers 
ADD COLUMN IF NOT EXISTS client_choice_order INTEGER,
ADD COLUMN IF NOT EXISTS offer_details JSONB,
ADD COLUMN IF NOT EXISTS rejection_reason TEXT,
ADD COLUMN IF NOT EXISTS accepted_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS rejected_at TIMESTAMPTZ;

-- Índices para performance dos novos campos
CREATE INDEX IF NOT EXISTS offers_client_choice_order_idx ON offers(client_choice_order);
CREATE INDEX IF NOT EXISTS offers_offer_details_idx ON offers USING GIN(offer_details);

-- Atualizar função para expirar ofertas (manter compatibilidade)
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

-- Função para aceitar uma oferta
CREATE OR REPLACE FUNCTION accept_offer(
    p_offer_id UUID,
    p_lawyer_id UUID,
    p_notes TEXT DEFAULT NULL
)
RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    case_id UUID
) AS $$
DECLARE
    v_offer_record RECORD;
    v_case_id UUID;
BEGIN
    -- Verificar se a oferta existe e pertence ao advogado
    SELECT * INTO v_offer_record
    FROM offers 
    WHERE id = p_offer_id 
      AND lawyer_id = p_lawyer_id 
      AND status = 'pending';
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Oferta não encontrada ou não está pendente', NULL::UUID;
        RETURN;
    END IF;
    
    -- Verificar se não expirou
    IF v_offer_record.expires_at < NOW() THEN
        RETURN QUERY SELECT FALSE, 'Oferta expirada', NULL::UUID;
        RETURN;
    END IF;
    
    -- Aceitar a oferta
    UPDATE offers 
    SET status = 'accepted',
        accepted_at = NOW(),
        responded_at = NOW(),
        updated_at = NOW(),
        offer_details = COALESCE(offer_details, '{}'::jsonb) || 
                       CASE WHEN p_notes IS NOT NULL 
                            THEN jsonb_build_object('acceptance_notes', p_notes)
                            ELSE '{}'::jsonb END
    WHERE id = p_offer_id;
    
    v_case_id := v_offer_record.case_id;
    
    -- Rejeitar outras ofertas pendentes para o mesmo caso
    UPDATE offers 
    SET status = 'closed',
        updated_at = NOW()
    WHERE case_id = v_case_id 
      AND id != p_offer_id 
      AND status = 'pending';
    
    RETURN QUERY SELECT TRUE, 'Oferta aceita com sucesso', v_case_id;
END;
$$ LANGUAGE plpgsql;

-- Função para rejeitar uma oferta
CREATE OR REPLACE FUNCTION reject_offer(
    p_offer_id UUID,
    p_lawyer_id UUID,
    p_reason TEXT
)
RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    case_id UUID
) AS $$
DECLARE
    v_offer_record RECORD;
    v_case_id UUID;
BEGIN
    -- Verificar se a oferta existe e pertence ao advogado
    SELECT * INTO v_offer_record
    FROM offers 
    WHERE id = p_offer_id 
      AND lawyer_id = p_lawyer_id 
      AND status = 'pending';
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Oferta não encontrada ou não está pendente', NULL::UUID;
        RETURN;
    END IF;
    
    -- Rejeitar a oferta
    UPDATE offers 
    SET status = 'rejected',
        rejected_at = NOW(),
        responded_at = NOW(),
        rejection_reason = p_reason,
        updated_at = NOW()
    WHERE id = p_offer_id;
    
    v_case_id := v_offer_record.case_id;
    
    RETURN QUERY SELECT TRUE, 'Oferta rejeitada com sucesso', v_case_id;
END;
$$ LANGUAGE plpgsql;

-- Comentários para documentação
COMMENT ON COLUMN offers.client_choice_order IS 'Ordem de escolha do cliente (1 = primeira escolha)';
COMMENT ON COLUMN offers.offer_details IS 'Detalhes da oferta em formato JSON (resumo do caso, área jurídica, etc.)';
COMMENT ON COLUMN offers.rejection_reason IS 'Motivo da rejeição da oferta';
COMMENT ON COLUMN offers.accepted_at IS 'Timestamp de quando a oferta foi aceita';
COMMENT ON COLUMN offers.rejected_at IS 'Timestamp de quando a oferta foi rejeitada';
COMMENT ON FUNCTION accept_offer(UUID, UUID, TEXT) IS 'Aceita uma oferta e fecha outras ofertas do mesmo caso';
COMMENT ON FUNCTION reject_offer(UUID, UUID, TEXT) IS 'Rejeita uma oferta com motivo'; 