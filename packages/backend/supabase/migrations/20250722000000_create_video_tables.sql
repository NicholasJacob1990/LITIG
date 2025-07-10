-- Criar tabela de salas de vídeo
CREATE TABLE video_rooms (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  url TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  config JSONB DEFAULT '{
    "max_participants": 2,
    "enable_recording": false,
    "enable_chat": true,
    "enable_screenshare": true
  }'::jsonb
);

-- Criar tabela de sessões de vídeo
CREATE TABLE video_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id TEXT NOT NULL REFERENCES video_rooms(id) ON DELETE CASCADE,
  case_id UUID REFERENCES cases(id) ON DELETE SET NULL,
  client_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  lawyer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  status TEXT CHECK (status IN ('scheduled', 'active', 'ended', 'cancelled')) DEFAULT 'scheduled',
  started_at TIMESTAMPTZ,
  ended_at TIMESTAMPTZ,
  duration_minutes INTEGER,
  recording_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para melhor performance
CREATE INDEX idx_video_sessions_room_id ON video_sessions(room_id);
CREATE INDEX idx_video_sessions_case_id ON video_sessions(case_id);
CREATE INDEX idx_video_sessions_client_id ON video_sessions(client_id);
CREATE INDEX idx_video_sessions_lawyer_id ON video_sessions(lawyer_id);
CREATE INDEX idx_video_sessions_status ON video_sessions(status);
CREATE INDEX idx_video_sessions_created_at ON video_sessions(created_at);
CREATE INDEX idx_video_rooms_expires_at ON video_rooms(expires_at);

-- Trigger para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_video_sessions_updated_at
  BEFORE UPDATE ON video_sessions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- RLS (Row Level Security) para video_rooms
ALTER TABLE video_rooms ENABLE ROW LEVEL SECURITY;

-- Política para video_rooms: usuários podem ver salas onde participam
CREATE POLICY "Users can view rooms they participate in" ON video_rooms
  FOR SELECT USING (
    id IN (
      SELECT room_id FROM video_sessions 
      WHERE client_id = auth.uid() OR lawyer_id = auth.uid()
    )
  );

-- Política para video_rooms: apenas sistema pode inserir/atualizar/deletar
CREATE POLICY "System can manage video rooms" ON video_rooms
  FOR ALL USING (auth.role() = 'service_role');

-- RLS para video_sessions
ALTER TABLE video_sessions ENABLE ROW LEVEL SECURITY;

-- Política para video_sessions: usuários podem ver suas próprias sessões
CREATE POLICY "Users can view their own sessions" ON video_sessions
  FOR SELECT USING (client_id = auth.uid() OR lawyer_id = auth.uid());

-- Política para video_sessions: usuários podem atualizar suas próprias sessões
CREATE POLICY "Users can update their own sessions" ON video_sessions
  FOR UPDATE USING (client_id = auth.uid() OR lawyer_id = auth.uid());

-- Política para video_sessions: apenas sistema pode inserir/deletar
CREATE POLICY "System can create sessions" ON video_sessions
  FOR INSERT WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "System can delete sessions" ON video_sessions
  FOR DELETE USING (auth.role() = 'service_role');

-- Função para buscar sessões de vídeo de um usuário
CREATE OR REPLACE FUNCTION get_user_video_sessions(user_id UUID)
RETURNS TABLE (
  id UUID,
  room_id TEXT,
  case_id UUID,
  client_id UUID,
  lawyer_id UUID,
  status TEXT,
  started_at TIMESTAMPTZ,
  ended_at TIMESTAMPTZ,
  duration_minutes INTEGER,
  recording_url TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  room_name TEXT,
  room_url TEXT,
  room_config JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    vs.id,
    vs.room_id,
    vs.case_id,
    vs.client_id,
    vs.lawyer_id,
    vs.status,
    vs.started_at,
    vs.ended_at,
    vs.duration_minutes,
    vs.recording_url,
    vs.created_at,
    vs.updated_at,
    vr.name as room_name,
    vr.url as room_url,
    vr.config as room_config
  FROM video_sessions vs
  JOIN video_rooms vr ON vs.room_id = vr.id
  WHERE vs.client_id = user_id OR vs.lawyer_id = user_id
  ORDER BY vs.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para limpar salas expiradas (para ser executada por um cron job)
CREATE OR REPLACE FUNCTION cleanup_expired_video_rooms()
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  -- Deletar salas expiradas (isso também deletará as sessões relacionadas por CASCADE)
  DELETE FROM video_rooms 
  WHERE expires_at < NOW();
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Comentários para documentação
COMMENT ON TABLE video_rooms IS 'Salas de videochamada criadas via Daily.co API';
COMMENT ON TABLE video_sessions IS 'Sessões de videochamada entre clientes e advogados';
COMMENT ON COLUMN video_rooms.id IS 'ID da sala no Daily.co';
COMMENT ON COLUMN video_rooms.url IS 'URL da sala no Daily.co';
COMMENT ON COLUMN video_rooms.config IS 'Configurações da sala (max_participants, recording, etc.)';
COMMENT ON COLUMN video_sessions.status IS 'Status da sessão: scheduled, active, ended, cancelled';
COMMENT ON COLUMN video_sessions.duration_minutes IS 'Duração da chamada em minutos';
COMMENT ON COLUMN video_sessions.recording_url IS 'URL da gravação (se disponível)';

-- Grants para as funções
GRANT EXECUTE ON FUNCTION get_user_video_sessions(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION cleanup_expired_video_rooms() TO service_role;
