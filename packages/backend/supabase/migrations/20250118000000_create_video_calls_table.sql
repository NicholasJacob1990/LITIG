-- Criação da tabela video_calls para gerenciar chamadas de vídeo
CREATE TABLE video_calls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_name VARCHAR(255) NOT NULL UNIQUE,
    room_url TEXT NOT NULL,
    client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    lawyer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    case_id UUID NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'created' CHECK (status IN ('created', 'active', 'ended', 'expired')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    joined_at TIMESTAMP WITH TIME ZONE,
    ended_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    recording_url TEXT,
    duration_minutes INTEGER DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_video_calls_client_id ON video_calls(client_id);
CREATE INDEX idx_video_calls_lawyer_id ON video_calls(lawyer_id);
CREATE INDEX idx_video_calls_case_id ON video_calls(case_id);
CREATE INDEX idx_video_calls_status ON video_calls(status);
CREATE INDEX idx_video_calls_created_at ON video_calls(created_at);
CREATE INDEX idx_video_calls_expires_at ON video_calls(expires_at);

-- Trigger para atualizar updated_at
CREATE OR REPLACE FUNCTION update_video_calls_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_video_calls_updated_at
    BEFORE UPDATE ON video_calls
    FOR EACH ROW
    EXECUTE FUNCTION update_video_calls_updated_at();

-- Função para expirar salas antigas
CREATE OR REPLACE FUNCTION expire_old_video_calls()
RETURNS void AS $$
BEGIN
    UPDATE video_calls 
    SET status = 'expired', updated_at = NOW()
    WHERE status IN ('created', 'active') 
    AND expires_at < NOW();
END;
$$ language 'plpgsql';

-- Row Level Security (RLS)
ALTER TABLE video_calls ENABLE ROW LEVEL SECURITY;

-- Política para clientes verem suas próprias chamadas
CREATE POLICY "Clients can view their own video calls"
ON video_calls
FOR SELECT
TO authenticated
USING (client_id = auth.uid());

-- Política para advogados verem suas próprias chamadas
CREATE POLICY "Lawyers can view their own video calls"
ON video_calls
FOR SELECT
TO authenticated
USING (lawyer_id = auth.uid());

-- Política para criar chamadas (apenas usuários autenticados)
CREATE POLICY "Users can create video calls"
ON video_calls
FOR INSERT
TO authenticated
WITH CHECK (client_id = auth.uid() OR lawyer_id = auth.uid());

-- Política para atualizar chamadas (apenas participantes)
CREATE POLICY "Participants can update video calls"
ON video_calls
FOR UPDATE
TO authenticated
USING (client_id = auth.uid() OR lawyer_id = auth.uid());

-- Comentários para documentação
COMMENT ON TABLE video_calls IS 'Gerenciamento de chamadas de vídeo entre clientes e advogados';
COMMENT ON COLUMN video_calls.room_name IS 'Nome único da sala no Daily.co';
COMMENT ON COLUMN video_calls.room_url IS 'URL da sala no Daily.co';
COMMENT ON COLUMN video_calls.status IS 'Status da chamada: created, active, ended, expired';
COMMENT ON COLUMN video_calls.recording_url IS 'URL da gravação (se habilitada)';
COMMENT ON COLUMN video_calls.duration_minutes IS 'Duração da chamada em minutos';

-- Inserir dados de exemplo (opcional - remover em produção)
DO $$
BEGIN
    -- Verificar se existem usuários para criar exemplo
    IF EXISTS (SELECT 1 FROM users LIMIT 1) THEN
        INSERT INTO video_calls (
            room_name,
            room_url,
            client_id,
            lawyer_id,
            case_id,
            status,
            expires_at
        ) VALUES (
            'exemplo-chamada-001',
            'https://litig.daily.co/exemplo-chamada-001',
            (SELECT id FROM users WHERE user_type = 'client' LIMIT 1),
            (SELECT id FROM users WHERE user_type = 'lawyer' LIMIT 1),
            (SELECT id FROM cases LIMIT 1),
            'created',
            NOW() + INTERVAL '2 hours'
        );
    END IF;
END $$;