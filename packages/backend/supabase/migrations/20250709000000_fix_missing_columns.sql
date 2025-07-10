-- Migração para corrigir colunas faltantes
-- Criada em: 2025-07-09

-- Adicionar coluna description à tabela cases se não existir
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'cases' AND column_name = 'description'
    ) THEN
        ALTER TABLE cases ADD COLUMN description TEXT;
    END IF;
END $$;

-- Adicionar coluna title à tabela cases se não existir  
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'cases' AND column_name = 'title'
    ) THEN
        ALTER TABLE cases ADD COLUMN title VARCHAR(255);
    END IF;
END $$;

-- Garantir que as tabelas de calendário existam
CREATE TABLE IF NOT EXISTS calendar_credentials (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    provider VARCHAR(50) NOT NULL,
    access_token TEXT,
    refresh_token TEXT,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    provider VARCHAR(50) DEFAULT 'local',
    external_id VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Garantir que a tabela support_tickets exista
CREATE TABLE IF NOT EXISTS support_tickets (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
    priority VARCHAR(50) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Garantir que a tabela tasks tenha todas as colunas necessárias
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'tasks' AND column_name = 'case_id'
    ) THEN
        ALTER TABLE tasks ADD COLUMN case_id UUID REFERENCES cases(id) ON DELETE CASCADE;
    END IF;
END $$;

-- Adicionar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_calendar_credentials_user_id ON calendar_credentials(user_id);
CREATE INDEX IF NOT EXISTS idx_events_user_id ON events(user_id);
CREATE INDEX IF NOT EXISTS idx_events_start_time ON events(start_time);
CREATE INDEX IF NOT EXISTS idx_support_tickets_creator_id ON support_tickets(creator_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_status ON support_tickets(status);
CREATE INDEX IF NOT EXISTS idx_tasks_case_id ON tasks(case_id);

-- Habilitar RLS (Row Level Security) nas novas tabelas
ALTER TABLE calendar_credentials ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança para calendar_credentials
CREATE POLICY "Users can view own calendar credentials" ON calendar_credentials
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own calendar credentials" ON calendar_credentials
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own calendar credentials" ON calendar_credentials
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own calendar credentials" ON calendar_credentials
    FOR DELETE USING (auth.uid() = user_id);

-- Políticas de segurança para events
CREATE POLICY "Users can view own events" ON events
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own events" ON events
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own events" ON events
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own events" ON events
    FOR DELETE USING (auth.uid() = user_id);

-- Políticas de segurança para support_tickets
CREATE POLICY "Users can view own support tickets" ON support_tickets
    FOR SELECT USING (auth.uid() = creator_id);

CREATE POLICY "Users can insert own support tickets" ON support_tickets
    FOR INSERT WITH CHECK (auth.uid() = creator_id);

CREATE POLICY "Users can update own support tickets" ON support_tickets
    FOR UPDATE USING (auth.uid() = creator_id);

CREATE POLICY "Users can delete own support tickets" ON support_tickets
    FOR DELETE USING (auth.uid() = creator_id); 