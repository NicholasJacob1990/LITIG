-- =====================================================
-- LITIG Partnership B2B Chat System - Database Migration
-- =====================================================
-- Versão: v1.0
-- Data: 2025-01-25
-- Objetivo: Estender sistema de chat para parcerias B2B

-- =====================================================
-- 1. ESTENDER CHAT_ROOMS PARA PARCERIAS B2B
-- =====================================================

-- Adicionar campos para suporte a parcerias B2B
ALTER TABLE chat_rooms ADD COLUMN IF NOT EXISTS room_type VARCHAR(20) DEFAULT 'case' 
    CHECK (room_type IN ('case', 'partnership', 'firm_collaboration', 'b2b_negotiation'));

ALTER TABLE chat_rooms ADD COLUMN IF NOT EXISTS partnership_id UUID 
    REFERENCES partnerships(id) ON DELETE CASCADE;

ALTER TABLE chat_rooms ADD COLUMN IF NOT EXISTS firm_id UUID 
    REFERENCES law_firms(id) ON DELETE CASCADE;

ALTER TABLE chat_rooms ADD COLUMN IF NOT EXISTS secondary_firm_id UUID 
    REFERENCES law_firms(id) ON DELETE CASCADE;

-- Relaxar constraint de case_id para permitir NULL em parcerias
ALTER TABLE chat_rooms ALTER COLUMN case_id DROP NOT NULL;

-- Relaxar constraint unique para permitir múltiplas salas por contexto
DROP INDEX IF EXISTS chat_rooms_client_id_lawyer_id_case_id_key;

-- Criar nova constraint mais flexível
CREATE UNIQUE INDEX IF NOT EXISTS idx_chat_rooms_case_unique 
    ON chat_rooms(client_id, lawyer_id, case_id) 
    WHERE room_type = 'case' AND case_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_chat_rooms_partnership_unique 
    ON chat_rooms(lawyer_id, partner_lawyer_id, partnership_id) 
    WHERE room_type = 'partnership' AND partnership_id IS NOT NULL;

-- Adicionar campo para segundo advogado/escritório
ALTER TABLE chat_rooms ADD COLUMN IF NOT EXISTS partner_lawyer_id UUID 
    REFERENCES users(id) ON DELETE CASCADE;

-- =====================================================
-- 2. CRIAR TABELA PARTNERSHIPS (se não existir)
-- =====================================================

CREATE TABLE IF NOT EXISTS partnerships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    partner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    case_id UUID REFERENCES cases(id) ON DELETE SET NULL,
    firm_id UUID REFERENCES law_firms(id) ON DELETE SET NULL,
    partner_firm_id UUID REFERENCES law_firms(id) ON DELETE SET NULL,
    partnership_type VARCHAR(50) NOT NULL DEFAULT 'collaboration',
    status VARCHAR(20) NOT NULL DEFAULT 'pending' 
        CHECK (status IN ('pending', 'active', 'completed', 'cancelled')),
    honorarios TEXT,
    proposal_message TEXT,
    contract_url TEXT,
    contract_accepted_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Campos para chat automático
    auto_create_chat BOOLEAN DEFAULT TRUE,
    chat_enabled BOOLEAN DEFAULT TRUE
);

-- =====================================================
-- 3. CRIAR TABELA PARTNERSHIP_PARTICIPANTS
-- =====================================================

CREATE TABLE IF NOT EXISTS partnership_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    partnership_id UUID NOT NULL REFERENCES partnerships(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    firm_id UUID REFERENCES law_firms(id) ON DELETE SET NULL,
    role VARCHAR(30) NOT NULL CHECK (role IN ('creator', 'partner', 'firm_representative', 'observer')),
    permissions JSONB DEFAULT '{"can_message": true, "can_invite": false, "can_archive": false}',
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(partnership_id, user_id)
);

-- =====================================================
-- 4. ATUALIZAR CHAT_MESSAGES PARA CONTEXTO B2B
-- =====================================================

-- Adicionar campos para contexto de mensagem
ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS message_context VARCHAR(30) DEFAULT 'general'
    CHECK (message_context IN ('general', 'proposal', 'negotiation', 'contract', 'work_update', 'billing'));

ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS reply_to_message_id UUID 
    REFERENCES chat_messages(id) ON DELETE SET NULL;

ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS priority VARCHAR(10) DEFAULT 'normal'
    CHECK (priority IN ('low', 'normal', 'high', 'urgent'));

-- =====================================================
-- 5. CRIAR ÍNDICES PARA PERFORMANCE
-- =====================================================

-- Índices para parcerias
CREATE INDEX IF NOT EXISTS idx_partnerships_creator_id ON partnerships(creator_id);
CREATE INDEX IF NOT EXISTS idx_partnerships_partner_id ON partnerships(partner_id);
CREATE INDEX IF NOT EXISTS idx_partnerships_status ON partnerships(status);
CREATE INDEX IF NOT EXISTS idx_partnerships_type ON partnerships(partnership_type);

-- Índices para participantes
CREATE INDEX IF NOT EXISTS idx_partnership_participants_partnership_id 
    ON partnership_participants(partnership_id);
CREATE INDEX IF NOT EXISTS idx_partnership_participants_user_id 
    ON partnership_participants(user_id);

-- Índices adicionais para chat_rooms
CREATE INDEX IF NOT EXISTS idx_chat_rooms_room_type ON chat_rooms(room_type);
CREATE INDEX IF NOT EXISTS idx_chat_rooms_partnership_id ON chat_rooms(partnership_id);
CREATE INDEX IF NOT EXISTS idx_chat_rooms_firm_id ON chat_rooms(firm_id);
CREATE INDEX IF NOT EXISTS idx_chat_rooms_partner_lawyer_id ON chat_rooms(partner_lawyer_id);

-- Índices para chat_messages estendido
CREATE INDEX IF NOT EXISTS idx_chat_messages_context ON chat_messages(message_context);
CREATE INDEX IF NOT EXISTS idx_chat_messages_priority ON chat_messages(priority);
CREATE INDEX IF NOT EXISTS idx_chat_messages_reply_to ON chat_messages(reply_to_message_id);

-- =====================================================
-- 6. FUNÇÕES PARA AUTOMAÇÃO
-- =====================================================

-- Função para criar sala de chat automaticamente após parceria aceita
CREATE OR REPLACE FUNCTION create_partnership_chat_room()
RETURNS TRIGGER AS $$
BEGIN
    -- Criar sala de chat quando parceria for aceita
    IF NEW.status = 'active' AND NEW.auto_create_chat = TRUE AND 
       (OLD.status IS NULL OR OLD.status != 'active') THEN
        
        INSERT INTO chat_rooms (
            room_type, 
            partnership_id,
            lawyer_id,
            partner_lawyer_id,
            firm_id,
            secondary_firm_id,
            status,
            created_at
        )
        VALUES (
            'partnership',
            NEW.id,
            NEW.creator_id,
            NEW.partner_id,
            NEW.firm_id,
            NEW.partner_firm_id,
            'active',
            CURRENT_TIMESTAMP
        )
        ON CONFLICT DO NOTHING;
        
        -- Inserir participantes automaticamente
        INSERT INTO partnership_participants (partnership_id, user_id, role, permissions)
        VALUES 
            (NEW.id, NEW.creator_id, 'creator', '{"can_message": true, "can_invite": true, "can_archive": true}'),
            (NEW.id, NEW.partner_id, 'partner', '{"can_message": true, "can_invite": false, "can_archive": false}')
        ON CONFLICT (partnership_id, user_id) DO NOTHING;
        
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para criação automática de sala de chat de parceria
DROP TRIGGER IF EXISTS create_partnership_chat_trigger ON partnerships;
CREATE TRIGGER create_partnership_chat_trigger 
    AFTER INSERT OR UPDATE ON partnerships 
    FOR EACH ROW EXECUTE FUNCTION create_partnership_chat_room();

-- =====================================================
-- 7. VIEWS PARA CONSULTAS OTIMIZADAS
-- =====================================================

-- View para salas de chat de parcerias
CREATE OR REPLACE VIEW partnership_chat_rooms AS
SELECT 
    cr.*,
    p.partnership_type,
    p.status as partnership_status,
    creator.name as creator_name,
    partner.name as partner_name,
    cf.name as creator_firm_name,
    pf.name as partner_firm_name
FROM chat_rooms cr
JOIN partnerships p ON cr.partnership_id = p.id
JOIN users creator ON p.creator_id = creator.id
JOIN users partner ON p.partner_id = partner.id
LEFT JOIN law_firms cf ON p.firm_id = cf.id
LEFT JOIN law_firms pf ON p.partner_firm_id = pf.id
WHERE cr.room_type = 'partnership';

-- View para participantes de chat B2B
CREATE OR REPLACE VIEW partnership_chat_participants AS
SELECT 
    pp.*,
    u.name as user_name,
    u.email as user_email,
    u.user_type,
    f.name as firm_name,
    p.partnership_type
FROM partnership_participants pp
JOIN users u ON pp.user_id = u.id
JOIN partnerships p ON pp.partnership_id = p.id
LEFT JOIN law_firms f ON pp.firm_id = f.id;

-- =====================================================
-- 8. COMENTÁRIOS E DOCUMENTAÇÃO
-- =====================================================

COMMENT ON COLUMN chat_rooms.room_type IS 'Tipo da sala: case (cliente-advogado), partnership (advogado-advogado), firm_collaboration (escritório-escritório), b2b_negotiation (negociação B2B)';
COMMENT ON COLUMN chat_rooms.partnership_id IS 'ID da parceria (para salas tipo partnership)';
COMMENT ON COLUMN chat_rooms.firm_id IS 'ID do escritório principal';
COMMENT ON COLUMN chat_rooms.secondary_firm_id IS 'ID do escritório secundário (para colaborações entre escritórios)';
COMMENT ON COLUMN chat_rooms.partner_lawyer_id IS 'ID do advogado parceiro (para parcerias advogado-advogado)';

COMMENT ON TABLE partnerships IS 'Parcerias entre advogados e/ou escritórios para colaboração em casos';
COMMENT ON COLUMN partnerships.partnership_type IS 'Tipo de parceria: collaboration, correspondent, expert_opinion, full_partnership';
COMMENT ON COLUMN partnerships.auto_create_chat IS 'Se TRUE, cria sala de chat automaticamente quando parceria é aceita';
COMMENT ON COLUMN partnerships.chat_enabled IS 'Se FALSE, desabilita chat para esta parceria';

COMMENT ON TABLE partnership_participants IS 'Participantes de uma parceria (podem incluir múltiplos advogados por escritório)';
COMMENT ON COLUMN partnership_participants.permissions IS 'Permissões JSON: can_message, can_invite, can_archive';

COMMENT ON COLUMN chat_messages.message_context IS 'Contexto da mensagem: general, proposal, negotiation, contract, work_update, billing';
COMMENT ON COLUMN chat_messages.reply_to_message_id IS 'ID da mensagem à qual esta é uma resposta';
COMMENT ON COLUMN chat_messages.priority IS 'Prioridade da mensagem: low, normal, high, urgent';

-- =====================================================
-- 9. DADOS DE TESTE (opcional - comentado)
-- =====================================================

/*
-- Inserir parceria de exemplo
INSERT INTO partnerships (id, creator_id, partner_id, partnership_type, status, auto_create_chat)
VALUES (
    gen_random_uuid(),
    (SELECT id FROM users WHERE user_type LIKE '%lawyer%' LIMIT 1),
    (SELECT id FROM users WHERE user_type LIKE '%lawyer%' LIMIT 1 OFFSET 1),
    'collaboration',
    'active',
    true
);
*/

-- =====================================================
-- 10. VERIFICAÇÃO FINAL
-- =====================================================

DO $$
DECLARE
    missing_columns TEXT[] := ARRAY[]::TEXT[];
    missing_tables TEXT[] := ARRAY[]::TEXT[];
BEGIN
    -- Verificar colunas adicionadas em chat_rooms
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'chat_rooms' AND column_name = 'room_type') THEN
        missing_columns := array_append(missing_columns, 'chat_rooms.room_type');
    END IF;
    
    -- Verificar tabela partnerships
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables 
                   WHERE table_name = 'partnerships') THEN
        missing_tables := array_append(missing_tables, 'partnerships');
    END IF;
    
    -- Verificar tabela partnership_participants
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables 
                   WHERE table_name = 'partnership_participants') THEN
        missing_tables := array_append(missing_tables, 'partnership_participants');
    END IF;
    
    -- Reportar resultado
    IF array_length(missing_columns, 1) > 0 OR array_length(missing_tables, 1) > 0 THEN
        RAISE EXCEPTION 'MIGRATION FAILED: Missing columns: %, Missing tables: %', 
            array_to_string(missing_columns, ', '), 
            array_to_string(missing_tables, ', ');
    ELSE
        RAISE NOTICE 'MIGRATION SUCCESS: Partnership B2B Chat System implemented!';
        RAISE NOTICE 'Extended: chat_rooms, chat_messages';
        RAISE NOTICE 'Created: partnerships, partnership_participants';
        RAISE NOTICE 'Added: Views, triggers, indexes for B2B chat';
    END IF;
END $$;

-- =====================================================
-- FIM DA MIGRATION
-- ===================================================== 