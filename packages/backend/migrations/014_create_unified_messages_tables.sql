-- Migration 014: Tabelas para Sistema de Mensagens Unificadas
-- Criação das tabelas para integração com Unipile SDK
-- Data: 2025-07-20

-- Tabela de contas conectadas via Unipile
CREATE TABLE user_connected_accounts (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL,
    provider VARCHAR(50) NOT NULL, -- 'linkedin', 'instagram', 'whatsapp', 'gmail', 'outlook'
    account_id VARCHAR(255) NOT NULL,
    account_name VARCHAR(255),
    account_email VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    last_sync_at TIMESTAMP,
    sync_status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'syncing', 'synced', 'error'
    error_message TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, provider, account_id)
);

-- Tabela de chats unificados
CREATE TABLE unified_chats (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL,
    provider VARCHAR(50) NOT NULL,
    provider_chat_id VARCHAR(255) NOT NULL,
    chat_name VARCHAR(255),
    chat_type VARCHAR(50), -- 'direct', 'group', 'channel'
    chat_avatar_url VARCHAR(500),
    last_message_content TEXT,
    last_message_at TIMESTAMP,
    unread_count INTEGER DEFAULT 0,
    is_archived BOOLEAN DEFAULT false,
    is_muted BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, provider, provider_chat_id)
);

-- Tabela de mensagens unificadas
CREATE TABLE unified_messages (
    id SERIAL PRIMARY KEY,
    chat_id INTEGER REFERENCES unified_chats(id) ON DELETE CASCADE,
    provider_message_id VARCHAR(255) NOT NULL,
    sender_id VARCHAR(255),
    sender_name VARCHAR(255),
    sender_email VARCHAR(255),
    sender_avatar_url VARCHAR(500),
    message_type VARCHAR(50), -- 'text', 'image', 'video', 'file', 'audio', 'location'
    content TEXT,
    attachments JSONB,
    reactions JSONB,
    is_outgoing BOOLEAN DEFAULT false,
    is_read BOOLEAN DEFAULT false,
    is_delivered BOOLEAN DEFAULT false,
    reply_to_message_id INTEGER REFERENCES unified_messages(id),
    sent_at TIMESTAMP,
    received_at TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(chat_id, provider_message_id)
);

-- Tabela de calendários conectados
CREATE TABLE user_calendars (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL,
    provider VARCHAR(50) NOT NULL, -- 'google', 'outlook'
    calendar_id VARCHAR(255) NOT NULL,
    calendar_name VARCHAR(255),
    calendar_color VARCHAR(7), -- Hex color
    timezone VARCHAR(100),
    is_primary BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    last_sync_at TIMESTAMP,
    sync_status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, provider, calendar_id)
);

-- Tabela de eventos de calendário sincronizados
CREATE TABLE unified_calendar_events (
    id SERIAL PRIMARY KEY,
    calendar_id INTEGER REFERENCES user_calendars(id) ON DELETE CASCADE,
    provider_event_id VARCHAR(255) NOT NULL,
    title VARCHAR(500) NOT NULL,
    description TEXT,
    location VARCHAR(500),
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    all_day BOOLEAN DEFAULT false,
    event_status VARCHAR(50), -- 'confirmed', 'tentative', 'cancelled'
    organizer_email VARCHAR(255),
    attendees JSONB,
    reminders JSONB,
    recurrence_rule TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(calendar_id, provider_event_id)
);

-- Tabela de contatos unificados (extraídos das plataformas)
CREATE TABLE unified_contacts (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL,
    provider VARCHAR(50) NOT NULL,
    provider_contact_id VARCHAR(255) NOT NULL,
    name VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(50),
    avatar_url VARCHAR(500),
    company VARCHAR(255),
    position VARCHAR(255),
    profile_url VARCHAR(500),
    contact_data JSONB, -- Dados específicos da plataforma
    last_interaction_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, provider, provider_contact_id)
);

-- Tabela de preferências de notificação
CREATE TABLE user_notification_preferences (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL UNIQUE,
    email_notifications BOOLEAN DEFAULT true,
    push_notifications BOOLEAN DEFAULT true,
    linkedin_notifications BOOLEAN DEFAULT true,
    instagram_notifications BOOLEAN DEFAULT true,
    whatsapp_notifications BOOLEAN DEFAULT true,
    gmail_notifications BOOLEAN DEFAULT true,
    outlook_notifications BOOLEAN DEFAULT true,
    calendar_reminders BOOLEAN DEFAULT true,
    quiet_hours_start TIME,
    quiet_hours_end TIME,
    timezone VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Tabela de tokens push para notificações
CREATE TABLE user_push_tokens (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL,
    device_type VARCHAR(50), -- 'ios', 'android', 'web'
    push_token VARCHAR(500) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    last_used_at TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, push_token)
);

-- Índices para performance
CREATE INDEX idx_unified_messages_chat_id ON unified_messages(chat_id);
CREATE INDEX idx_unified_messages_sent_at ON unified_messages(sent_at DESC);
CREATE INDEX idx_unified_messages_is_read ON unified_messages(is_read) WHERE is_read = false;
CREATE INDEX idx_unified_chats_user_id ON unified_chats(user_id);
CREATE INDEX idx_unified_chats_last_message_at ON unified_chats(last_message_at DESC);
CREATE INDEX idx_user_connected_accounts_user_id ON user_connected_accounts(user_id);
CREATE INDEX idx_user_connected_accounts_provider ON user_connected_accounts(provider);
CREATE INDEX idx_user_calendars_user_id ON user_calendars(user_id);
CREATE INDEX idx_unified_calendar_events_start_time ON unified_calendar_events(start_time);
CREATE INDEX idx_unified_contacts_user_id ON unified_contacts(user_id);
CREATE INDEX idx_unified_contacts_provider ON unified_contacts(provider);

-- Função para atualizar timestamp de updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para atualizar updated_at automaticamente
CREATE TRIGGER update_user_connected_accounts_updated_at BEFORE UPDATE
    ON user_connected_accounts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_unified_chats_updated_at BEFORE UPDATE
    ON unified_chats FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_unified_messages_updated_at BEFORE UPDATE
    ON unified_messages FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_calendars_updated_at BEFORE UPDATE
    ON user_calendars FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_unified_calendar_events_updated_at BEFORE UPDATE
    ON unified_calendar_events FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_unified_contacts_updated_at BEFORE UPDATE
    ON unified_contacts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_notification_preferences_updated_at BEFORE UPDATE
    ON user_notification_preferences FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Comentários nas tabelas
COMMENT ON TABLE user_connected_accounts IS 'Contas de usuários conectadas via Unipile (LinkedIn, Instagram, Gmail, etc.)';
COMMENT ON TABLE unified_chats IS 'Chats consolidados de todas as plataformas em uma única interface';
COMMENT ON TABLE unified_messages IS 'Mensagens unificadas com suporte a diferentes tipos de mídia';
COMMENT ON TABLE user_calendars IS 'Calendários conectados (Google Calendar, Outlook)';
COMMENT ON TABLE unified_calendar_events IS 'Eventos sincronizados dos calendários externos';
COMMENT ON TABLE unified_contacts IS 'Contatos extraídos e unificados de todas as plataformas';
COMMENT ON TABLE user_notification_preferences IS 'Preferências de notificação por usuário';
COMMENT ON TABLE user_push_tokens IS 'Tokens para envio de notificações push';