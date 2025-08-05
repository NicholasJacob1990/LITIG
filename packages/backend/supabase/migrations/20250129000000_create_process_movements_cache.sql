-- Migração para criar sistema de cache de movimentações processuais
-- Data: 2025-01-29
-- Objetivo: Evitar reconsultas constantes à API do Escavador e garantir funcionamento offline

-- Tabela para armazenar movimentações processuais em cache
CREATE TABLE IF NOT EXISTS public.process_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cnj TEXT NOT NULL,
    movement_data JSONB NOT NULL,
    movement_type TEXT NOT NULL, -- PETICAO, DECISAO, JUNTADA, etc.
    movement_date TIMESTAMP WITH TIME ZONE,
    content TEXT NOT NULL,
    source_tribunal TEXT,
    source_grau TEXT,
    classification_confidence DECIMAL(3,2) DEFAULT 0.0,
    
    -- Cache metadata
    fetched_from_api_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_freshness_hours INTEGER DEFAULT 24,
    api_response_status TEXT DEFAULT 'success',
    
    -- Índices de busca
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraint para evitar duplicatas
    UNIQUE(cnj, content, movement_date)
);

-- Tabela para status de processos (cache agregado)
CREATE TABLE IF NOT EXISTS public.process_status_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cnj TEXT NOT NULL UNIQUE,
    
    -- Status atual do processo
    current_phase TEXT NOT NULL,
    description TEXT NOT NULL,
    progress_percentage DECIMAL(5,2) DEFAULT 0.0,
    outcome TEXT CHECK (outcome IN ('vitoria', 'derrota', 'andamento')) DEFAULT 'andamento',
    
    -- Metadados do processo
    total_movements INTEGER DEFAULT 0,
    last_movement_date TIMESTAMP WITH TIME ZONE,
    tribunal_name TEXT,
    tribunal_grau TEXT,
    
    -- Dados de cache
    last_api_sync TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    cache_valid_until TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '24 hours'),
    sync_status TEXT DEFAULT 'success', -- success, failed, partial
    api_errors JSONB DEFAULT '[]',
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para otimização de consultas
CREATE INDEX IF NOT EXISTS idx_process_movements_cnj ON public.process_movements(cnj);
CREATE INDEX IF NOT EXISTS idx_process_movements_type ON public.process_movements(movement_type);
CREATE INDEX IF NOT EXISTS idx_process_movements_date ON public.process_movements(movement_date DESC);
CREATE INDEX IF NOT EXISTS idx_process_movements_freshness ON public.process_movements(fetched_from_api_at DESC);

CREATE INDEX IF NOT EXISTS idx_process_status_cache_cnj ON public.process_status_cache(cnj);
CREATE INDEX IF NOT EXISTS idx_process_status_cache_valid_until ON public.process_status_cache(cache_valid_until);
CREATE INDEX IF NOT EXISTS idx_process_status_cache_sync_status ON public.process_status_cache(sync_status);

-- Índice GIN para busca no JSON das movimentações
CREATE INDEX IF NOT EXISTS idx_process_movements_data ON public.process_movements USING GIN (movement_data);

-- Habilitar RLS
ALTER TABLE public.process_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.process_status_cache ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança para process_movements
CREATE POLICY "Users can view process movements" ON public.process_movements
FOR SELECT USING (
    cnj IN (
        SELECT numero_processo FROM public.lawyer_cases
        WHERE lawyer_id IN (
            SELECT id FROM public.lawyers WHERE user_id = auth.uid()
        )
    )
    OR
    EXISTS (
        SELECT 1 FROM public.cases c
        WHERE c.client_id = auth.uid() OR c.lawyer_id = auth.uid()
    )
);

-- Apenas o sistema pode inserir/atualizar movimentações (via service account)
CREATE POLICY "System can manage process movements" ON public.process_movements
FOR ALL USING (auth.uid() IS NOT NULL);

-- Políticas similares para process_status_cache
CREATE POLICY "Users can view process status cache" ON public.process_status_cache
FOR SELECT USING (
    cnj IN (
        SELECT numero_processo FROM public.lawyer_cases
        WHERE lawyer_id IN (
            SELECT id FROM public.lawyers WHERE user_id = auth.uid()
        )
    )
    OR
    EXISTS (
        SELECT 1 FROM public.cases c
        WHERE c.client_id = auth.uid() OR c.lawyer_id = auth.uid()
    )
);

CREATE POLICY "System can manage process status cache" ON public.process_status_cache
FOR ALL USING (auth.uid() IS NOT NULL);

-- Trigger para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_process_movements_updated_at
    BEFORE UPDATE ON public.process_movements
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_process_status_cache_updated_at
    BEFORE UPDATE ON public.process_status_cache
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Função para limpar cache expirado (será chamada por job)
CREATE OR REPLACE FUNCTION clean_expired_process_cache()
RETURNS INTEGER AS $$
DECLARE
    deleted_movements INTEGER;
    deleted_status INTEGER;
BEGIN
    -- Limpar movimentações antigas (mais de 7 dias)
    DELETE FROM public.process_movements
    WHERE fetched_from_api_at < NOW() - INTERVAL '7 days';
    
    GET DIAGNOSTICS deleted_movements = ROW_COUNT;
    
    -- Limpar status cache expirado
    DELETE FROM public.process_status_cache
    WHERE cache_valid_until < NOW() - INTERVAL '1 day';
    
    GET DIAGNOSTICS deleted_status = ROW_COUNT;
    
    RETURN deleted_movements + deleted_status;
END;
$$ LANGUAGE plpgsql;

-- Comentários para documentação
COMMENT ON TABLE public.process_movements IS 'Cache de movimentações processuais do Escavador para evitar reconsultas constantes';
COMMENT ON TABLE public.process_status_cache IS 'Cache agregado do status de processos para funcionamento offline';

COMMENT ON COLUMN public.process_movements.movement_data IS 'Dados completos da movimentação em formato JSON';
COMMENT ON COLUMN public.process_movements.data_freshness_hours IS 'Quantas horas os dados permanecem válidos';
COMMENT ON COLUMN public.process_status_cache.cache_valid_until IS 'Timestamp até quando o cache é considerado válido';
COMMENT ON COLUMN public.process_status_cache.sync_status IS 'Status da última sincronização: success, failed, partial'; 
-- Data: 2025-01-29
-- Objetivo: Evitar reconsultas constantes à API do Escavador e garantir funcionamento offline

-- Tabela para armazenar movimentações processuais em cache
CREATE TABLE IF NOT EXISTS public.process_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cnj TEXT NOT NULL,
    movement_data JSONB NOT NULL,
    movement_type TEXT NOT NULL, -- PETICAO, DECISAO, JUNTADA, etc.
    movement_date TIMESTAMP WITH TIME ZONE,
    content TEXT NOT NULL,
    source_tribunal TEXT,
    source_grau TEXT,
    classification_confidence DECIMAL(3,2) DEFAULT 0.0,
    
    -- Cache metadata
    fetched_from_api_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_freshness_hours INTEGER DEFAULT 24,
    api_response_status TEXT DEFAULT 'success',
    
    -- Índices de busca
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraint para evitar duplicatas
    UNIQUE(cnj, content, movement_date)
);

-- Tabela para status de processos (cache agregado)
CREATE TABLE IF NOT EXISTS public.process_status_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cnj TEXT NOT NULL UNIQUE,
    
    -- Status atual do processo
    current_phase TEXT NOT NULL,
    description TEXT NOT NULL,
    progress_percentage DECIMAL(5,2) DEFAULT 0.0,
    outcome TEXT CHECK (outcome IN ('vitoria', 'derrota', 'andamento')) DEFAULT 'andamento',
    
    -- Metadados do processo
    total_movements INTEGER DEFAULT 0,
    last_movement_date TIMESTAMP WITH TIME ZONE,
    tribunal_name TEXT,
    tribunal_grau TEXT,
    
    -- Dados de cache
    last_api_sync TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    cache_valid_until TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '24 hours'),
    sync_status TEXT DEFAULT 'success', -- success, failed, partial
    api_errors JSONB DEFAULT '[]',
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para otimização de consultas
CREATE INDEX IF NOT EXISTS idx_process_movements_cnj ON public.process_movements(cnj);
CREATE INDEX IF NOT EXISTS idx_process_movements_type ON public.process_movements(movement_type);
CREATE INDEX IF NOT EXISTS idx_process_movements_date ON public.process_movements(movement_date DESC);
CREATE INDEX IF NOT EXISTS idx_process_movements_freshness ON public.process_movements(fetched_from_api_at DESC);

CREATE INDEX IF NOT EXISTS idx_process_status_cache_cnj ON public.process_status_cache(cnj);
CREATE INDEX IF NOT EXISTS idx_process_status_cache_valid_until ON public.process_status_cache(cache_valid_until);
CREATE INDEX IF NOT EXISTS idx_process_status_cache_sync_status ON public.process_status_cache(sync_status);

-- Índice GIN para busca no JSON das movimentações
CREATE INDEX IF NOT EXISTS idx_process_movements_data ON public.process_movements USING GIN (movement_data);

-- Habilitar RLS
ALTER TABLE public.process_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.process_status_cache ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança para process_movements
CREATE POLICY "Users can view process movements" ON public.process_movements
FOR SELECT USING (
    cnj IN (
        SELECT numero_processo FROM public.lawyer_cases
        WHERE lawyer_id IN (
            SELECT id FROM public.lawyers WHERE user_id = auth.uid()
        )
    )
    OR
    EXISTS (
        SELECT 1 FROM public.cases c
        WHERE c.client_id = auth.uid() OR c.lawyer_id = auth.uid()
    )
);

-- Apenas o sistema pode inserir/atualizar movimentações (via service account)
CREATE POLICY "System can manage process movements" ON public.process_movements
FOR ALL USING (auth.uid() IS NOT NULL);

-- Políticas similares para process_status_cache
CREATE POLICY "Users can view process status cache" ON public.process_status_cache
FOR SELECT USING (
    cnj IN (
        SELECT numero_processo FROM public.lawyer_cases
        WHERE lawyer_id IN (
            SELECT id FROM public.lawyers WHERE user_id = auth.uid()
        )
    )
    OR
    EXISTS (
        SELECT 1 FROM public.cases c
        WHERE c.client_id = auth.uid() OR c.lawyer_id = auth.uid()
    )
);

CREATE POLICY "System can manage process status cache" ON public.process_status_cache
FOR ALL USING (auth.uid() IS NOT NULL);

-- Trigger para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_process_movements_updated_at
    BEFORE UPDATE ON public.process_movements
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_process_status_cache_updated_at
    BEFORE UPDATE ON public.process_status_cache
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Função para limpar cache expirado (será chamada por job)
CREATE OR REPLACE FUNCTION clean_expired_process_cache()
RETURNS INTEGER AS $$
DECLARE
    deleted_movements INTEGER;
    deleted_status INTEGER;
BEGIN
    -- Limpar movimentações antigas (mais de 7 dias)
    DELETE FROM public.process_movements
    WHERE fetched_from_api_at < NOW() - INTERVAL '7 days';
    
    GET DIAGNOSTICS deleted_movements = ROW_COUNT;
    
    -- Limpar status cache expirado
    DELETE FROM public.process_status_cache
    WHERE cache_valid_until < NOW() - INTERVAL '1 day';
    
    GET DIAGNOSTICS deleted_status = ROW_COUNT;
    
    RETURN deleted_movements + deleted_status;
END;
$$ LANGUAGE plpgsql;

-- Comentários para documentação
COMMENT ON TABLE public.process_movements IS 'Cache de movimentações processuais do Escavador para evitar reconsultas constantes';
COMMENT ON TABLE public.process_status_cache IS 'Cache agregado do status de processos para funcionamento offline';

COMMENT ON COLUMN public.process_movements.movement_data IS 'Dados completos da movimentação em formato JSON';
COMMENT ON COLUMN public.process_movements.data_freshness_hours IS 'Quantas horas os dados permanecem válidos';
COMMENT ON COLUMN public.process_status_cache.cache_valid_until IS 'Timestamp até quando o cache é considerado válido';
COMMENT ON COLUMN public.process_status_cache.sync_status IS 'Status da última sincronização: success, failed, partial'; 
-- Data: 2025-01-29
-- Objetivo: Evitar reconsultas constantes à API do Escavador e garantir funcionamento offline

-- Tabela para armazenar movimentações processuais em cache
CREATE TABLE IF NOT EXISTS public.process_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cnj TEXT NOT NULL,
    movement_data JSONB NOT NULL,
    movement_type TEXT NOT NULL, -- PETICAO, DECISAO, JUNTADA, etc.
    movement_date TIMESTAMP WITH TIME ZONE,
    content TEXT NOT NULL,
    source_tribunal TEXT,
    source_grau TEXT,
    classification_confidence DECIMAL(3,2) DEFAULT 0.0,
    
    -- Cache metadata
    fetched_from_api_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_freshness_hours INTEGER DEFAULT 24,
    api_response_status TEXT DEFAULT 'success',
    
    -- Índices de busca
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraint para evitar duplicatas
    UNIQUE(cnj, content, movement_date)
);

-- Tabela para status de processos (cache agregado)
CREATE TABLE IF NOT EXISTS public.process_status_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cnj TEXT NOT NULL UNIQUE,
    
    -- Status atual do processo
    current_phase TEXT NOT NULL,
    description TEXT NOT NULL,
    progress_percentage DECIMAL(5,2) DEFAULT 0.0,
    outcome TEXT CHECK (outcome IN ('vitoria', 'derrota', 'andamento')) DEFAULT 'andamento',
    
    -- Metadados do processo
    total_movements INTEGER DEFAULT 0,
    last_movement_date TIMESTAMP WITH TIME ZONE,
    tribunal_name TEXT,
    tribunal_grau TEXT,
    
    -- Dados de cache
    last_api_sync TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    cache_valid_until TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '24 hours'),
    sync_status TEXT DEFAULT 'success', -- success, failed, partial
    api_errors JSONB DEFAULT '[]',
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para otimização de consultas
CREATE INDEX IF NOT EXISTS idx_process_movements_cnj ON public.process_movements(cnj);
CREATE INDEX IF NOT EXISTS idx_process_movements_type ON public.process_movements(movement_type);
CREATE INDEX IF NOT EXISTS idx_process_movements_date ON public.process_movements(movement_date DESC);
CREATE INDEX IF NOT EXISTS idx_process_movements_freshness ON public.process_movements(fetched_from_api_at DESC);

CREATE INDEX IF NOT EXISTS idx_process_status_cache_cnj ON public.process_status_cache(cnj);
CREATE INDEX IF NOT EXISTS idx_process_status_cache_valid_until ON public.process_status_cache(cache_valid_until);
CREATE INDEX IF NOT EXISTS idx_process_status_cache_sync_status ON public.process_status_cache(sync_status);

-- Índice GIN para busca no JSON das movimentações
CREATE INDEX IF NOT EXISTS idx_process_movements_data ON public.process_movements USING GIN (movement_data);

-- Habilitar RLS
ALTER TABLE public.process_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.process_status_cache ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança para process_movements
CREATE POLICY "Users can view process movements" ON public.process_movements
FOR SELECT USING (
    cnj IN (
        SELECT numero_processo FROM public.lawyer_cases
        WHERE lawyer_id IN (
            SELECT id FROM public.lawyers WHERE user_id = auth.uid()
        )
    )
    OR
    EXISTS (
        SELECT 1 FROM public.cases c
        WHERE c.client_id = auth.uid() OR c.lawyer_id = auth.uid()
    )
);

-- Apenas o sistema pode inserir/atualizar movimentações (via service account)
CREATE POLICY "System can manage process movements" ON public.process_movements
FOR ALL USING (auth.uid() IS NOT NULL);

-- Políticas similares para process_status_cache
CREATE POLICY "Users can view process status cache" ON public.process_status_cache
FOR SELECT USING (
    cnj IN (
        SELECT numero_processo FROM public.lawyer_cases
        WHERE lawyer_id IN (
            SELECT id FROM public.lawyers WHERE user_id = auth.uid()
        )
    )
    OR
    EXISTS (
        SELECT 1 FROM public.cases c
        WHERE c.client_id = auth.uid() OR c.lawyer_id = auth.uid()
    )
);

CREATE POLICY "System can manage process status cache" ON public.process_status_cache
FOR ALL USING (auth.uid() IS NOT NULL);

-- Trigger para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_process_movements_updated_at
    BEFORE UPDATE ON public.process_movements
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_process_status_cache_updated_at
    BEFORE UPDATE ON public.process_status_cache
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Função para limpar cache expirado (será chamada por job)
CREATE OR REPLACE FUNCTION clean_expired_process_cache()
RETURNS INTEGER AS $$
DECLARE
    deleted_movements INTEGER;
    deleted_status INTEGER;
BEGIN
    -- Limpar movimentações antigas (mais de 7 dias)
    DELETE FROM public.process_movements
    WHERE fetched_from_api_at < NOW() - INTERVAL '7 days';
    
    GET DIAGNOSTICS deleted_movements = ROW_COUNT;
    
    -- Limpar status cache expirado
    DELETE FROM public.process_status_cache
    WHERE cache_valid_until < NOW() - INTERVAL '1 day';
    
    GET DIAGNOSTICS deleted_status = ROW_COUNT;
    
    RETURN deleted_movements + deleted_status;
END;
$$ LANGUAGE plpgsql;

-- Comentários para documentação
COMMENT ON TABLE public.process_movements IS 'Cache de movimentações processuais do Escavador para evitar reconsultas constantes';
COMMENT ON TABLE public.process_status_cache IS 'Cache agregado do status de processos para funcionamento offline';

COMMENT ON COLUMN public.process_movements.movement_data IS 'Dados completos da movimentação em formato JSON';
COMMENT ON COLUMN public.process_movements.data_freshness_hours IS 'Quantas horas os dados permanecem válidos';
COMMENT ON COLUMN public.process_status_cache.cache_valid_until IS 'Timestamp até quando o cache é considerado válido';
COMMENT ON COLUMN public.process_status_cache.sync_status IS 'Status da última sincronização: success, failed, partial'; 