-- Criar tabela de salas de chat
CREATE TABLE IF NOT EXISTS chat_rooms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    lawyer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    case_id UUID NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
    contract_id UUID REFERENCES contracts(id) ON DELETE SET NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'closed', 'archived')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_message_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Índices para performance
    UNIQUE(client_id, lawyer_id, case_id)
);

-- Criar tabela de mensagens do chat
CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    message_type VARCHAR(20) NOT NULL DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'document', 'audio')),
    attachment_url TEXT,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Criar índices para performance
CREATE INDEX IF NOT EXISTS idx_chat_rooms_client_id ON chat_rooms(client_id);
CREATE INDEX IF NOT EXISTS idx_chat_rooms_lawyer_id ON chat_rooms(lawyer_id);
CREATE INDEX IF NOT EXISTS idx_chat_rooms_case_id ON chat_rooms(case_id);
CREATE INDEX IF NOT EXISTS idx_chat_rooms_last_message_at ON chat_rooms(last_message_at DESC);

CREATE INDEX IF NOT EXISTS idx_chat_messages_room_id ON chat_messages(room_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender_id ON chat_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON chat_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_messages_unread ON chat_messages(room_id, is_read, sender_id);

-- Criar trigger para atualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_chat_rooms_updated_at 
    BEFORE UPDATE ON chat_rooms 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_chat_messages_updated_at 
    BEFORE UPDATE ON chat_messages 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Criar função para criar sala de chat automaticamente após contrato aceito
CREATE OR REPLACE FUNCTION create_chat_room_after_contract()
RETURNS TRIGGER AS $$
BEGIN
    -- Criar sala de chat quando contrato for aceito
    IF NEW.status = 'active' AND (OLD.status IS NULL OR OLD.status != 'active') THEN
        INSERT INTO chat_rooms (client_id, lawyer_id, case_id, contract_id, status)
        VALUES (NEW.client_id, NEW.lawyer_id, NEW.case_id, NEW.id, 'active')
        ON CONFLICT (client_id, lawyer_id, case_id) 
        DO UPDATE SET 
            contract_id = NEW.id,
            status = 'active',
            updated_at = CURRENT_TIMESTAMP;
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Criar trigger para criação automática de sala de chat
CREATE TRIGGER create_chat_room_trigger 
    AFTER INSERT OR UPDATE ON contracts 
    FOR EACH ROW EXECUTE FUNCTION create_chat_room_after_contract();

-- Inserir dados de exemplo (opcional, remover em produção)
/*
INSERT INTO chat_rooms (id, client_id, lawyer_id, case_id, status) 
VALUES 
    ('550e8400-e29b-41d4-a716-446655440001', 
     '550e8400-e29b-41d4-a716-446655440002', 
     '550e8400-e29b-41d4-a716-446655440003', 
     '550e8400-e29b-41d4-a716-446655440004', 
     'active')
ON CONFLICT (client_id, lawyer_id, case_id) DO NOTHING;

INSERT INTO chat_messages (room_id, sender_id, content, message_type) 
VALUES 
    ('550e8400-e29b-41d4-a716-446655440001', 
     '550e8400-e29b-41d4-a716-446655440002', 
     'Olá! Gostaria de discutir os detalhes do meu caso.', 
     'text'),
    ('550e8400-e29b-41d4-a716-446655440001', 
     '550e8400-e29b-41d4-a716-446655440003', 
     'Olá! Claro, vou analisar seu caso e te retorno em breve.', 
     'text');
*/