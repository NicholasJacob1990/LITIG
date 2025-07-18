-- =============================================================================
-- MIGRAÇÃO: Sistema de Avaliações (Ratings)
-- Implementação Sprint 3.1 - PLANO_ACAO_DETALHADO.md
-- Data: 2025-01-04
-- =============================================================================

-- Tabela principal de avaliações
CREATE TABLE IF NOT EXISTS ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id UUID REFERENCES cases(id) ON DELETE CASCADE,
    lawyer_id UUID REFERENCES users(id) ON DELETE CASCADE,
    client_id UUID REFERENCES users(id) ON DELETE CASCADE,
    rater_id UUID REFERENCES users(id) ON DELETE CASCADE,
    rater_type VARCHAR(10) NOT NULL CHECK (rater_type IN ('client', 'lawyer')),
    
    -- Avaliações detalhadas (1-5)
    overall_rating DECIMAL(2,1) NOT NULL CHECK (overall_rating >= 1 AND overall_rating <= 5),
    communication_rating DECIMAL(2,1) NOT NULL CHECK (communication_rating >= 1 AND communication_rating <= 5),
    expertise_rating DECIMAL(2,1) NOT NULL CHECK (expertise_rating >= 1 AND expertise_rating <= 5),
    responsiveness_rating DECIMAL(2,1) NOT NULL CHECK (responsiveness_rating >= 1 AND responsiveness_rating <= 5),
    value_rating DECIMAL(2,1) NOT NULL CHECK (value_rating >= 1 AND value_rating <= 5),
    
    -- Feedback textual
    comment TEXT,
    tags TEXT[] DEFAULT '{}',
    
    -- Metadados
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    is_verified BOOLEAN DEFAULT TRUE,
    is_public BOOLEAN DEFAULT TRUE,
    helpful_votes INTEGER DEFAULT 0,
    
    -- Controle de unicidade: um usuário só pode avaliar uma vez por caso
    UNIQUE(case_id, rater_id, rater_type)
);

-- Tabela para estatísticas agregadas dos advogados
CREATE TABLE IF NOT EXISTS lawyer_rating_stats (
    lawyer_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    overall_rating DECIMAL(3,2) DEFAULT 0,
    total_ratings INTEGER DEFAULT 0,
    communication_avg DECIMAL(3,2) DEFAULT 0,
    expertise_avg DECIMAL(3,2) DEFAULT 0,
    responsiveness_avg DECIMAL(3,2) DEFAULT 0,
    value_avg DECIMAL(3,2) DEFAULT 0,
    star_distribution JSONB DEFAULT '{}',
    last_updated TIMESTAMP DEFAULT NOW()
);

-- =============================================================================
-- ÍNDICES PARA PERFORMANCE
-- =============================================================================

-- Índices principais
CREATE INDEX IF NOT EXISTS idx_ratings_lawyer_id ON ratings(lawyer_id);
CREATE INDEX IF NOT EXISTS idx_ratings_client_id ON ratings(client_id);
CREATE INDEX IF NOT EXISTS idx_ratings_case_id ON ratings(case_id);
CREATE INDEX IF NOT EXISTS idx_ratings_rater_type ON ratings(rater_type);
CREATE INDEX IF NOT EXISTS idx_ratings_overall_rating ON ratings(overall_rating);
CREATE INDEX IF NOT EXISTS idx_ratings_created_at ON ratings(created_at);
CREATE INDEX IF NOT EXISTS idx_ratings_is_public ON ratings(is_public);

-- Índices compostos para queries comuns
CREATE INDEX IF NOT EXISTS idx_ratings_lawyer_public ON ratings(lawyer_id, is_public, rater_type);
CREATE INDEX IF NOT EXISTS idx_ratings_date_range ON ratings(created_at, lawyer_id);

-- =============================================================================
-- TRIGGERS PARA ATUALIZAÇÃO AUTOMÁTICA
-- =============================================================================

-- Trigger para atualizar timestamp de updated_at
CREATE OR REPLACE FUNCTION update_rating_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_ratings_timestamp
    BEFORE UPDATE ON ratings
    FOR EACH ROW
    EXECUTE FUNCTION update_rating_timestamp();

-- Trigger para atualizar estatísticas do advogado automaticamente
CREATE OR REPLACE FUNCTION update_lawyer_rating_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- Só atualizar para avaliações de clientes
    IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') AND NEW.rater_type = 'client' THEN
        -- Recalcular estatísticas para o advogado
        INSERT INTO lawyer_rating_stats (
            lawyer_id,
            overall_rating,
            total_ratings,
            communication_avg,
            expertise_avg,
            responsiveness_avg,
            value_avg,
            star_distribution,
            last_updated
        )
        SELECT
            NEW.lawyer_id,
            ROUND(AVG(overall_rating)::numeric, 2),
            COUNT(*),
            ROUND(AVG(communication_rating)::numeric, 2),
            ROUND(AVG(expertise_rating)::numeric, 2),
            ROUND(AVG(responsiveness_rating)::numeric, 2),
            ROUND(AVG(value_rating)::numeric, 2),
            jsonb_build_object(
                '1', COUNT(*) FILTER (WHERE ROUND(overall_rating) = 1),
                '2', COUNT(*) FILTER (WHERE ROUND(overall_rating) = 2),
                '3', COUNT(*) FILTER (WHERE ROUND(overall_rating) = 3),
                '4', COUNT(*) FILTER (WHERE ROUND(overall_rating) = 4),
                '5', COUNT(*) FILTER (WHERE ROUND(overall_rating) = 5)
            ),
            NOW()
        FROM ratings
        WHERE lawyer_id = NEW.lawyer_id
          AND rater_type = 'client'
          AND is_public = true
        ON CONFLICT (lawyer_id)
        DO UPDATE SET
            overall_rating = EXCLUDED.overall_rating,
            total_ratings = EXCLUDED.total_ratings,
            communication_avg = EXCLUDED.communication_avg,
            expertise_avg = EXCLUDED.expertise_avg,
            responsiveness_avg = EXCLUDED.responsiveness_avg,
            value_avg = EXCLUDED.value_avg,
            star_distribution = EXCLUDED.star_distribution,
            last_updated = EXCLUDED.last_updated;
    END IF;
    
    -- Para DELETE, também recalcular
    IF TG_OP = 'DELETE' AND OLD.rater_type = 'client' THEN
        INSERT INTO lawyer_rating_stats (
            lawyer_id,
            overall_rating,
            total_ratings,
            communication_avg,
            expertise_avg,
            responsiveness_avg,
            value_avg,
            star_distribution,
            last_updated
        )
        SELECT
            OLD.lawyer_id,
            COALESCE(ROUND(AVG(overall_rating)::numeric, 2), 0),
            COUNT(*),
            COALESCE(ROUND(AVG(communication_rating)::numeric, 2), 0),
            COALESCE(ROUND(AVG(expertise_rating)::numeric, 2), 0),
            COALESCE(ROUND(AVG(responsiveness_rating)::numeric, 2), 0),
            COALESCE(ROUND(AVG(value_rating)::numeric, 2), 0),
            jsonb_build_object(
                '1', COUNT(*) FILTER (WHERE ROUND(overall_rating) = 1),
                '2', COUNT(*) FILTER (WHERE ROUND(overall_rating) = 2),
                '3', COUNT(*) FILTER (WHERE ROUND(overall_rating) = 3),
                '4', COUNT(*) FILTER (WHERE ROUND(overall_rating) = 4),
                '5', COUNT(*) FILTER (WHERE ROUND(overall_rating) = 5)
            ),
            NOW()
        FROM ratings
        WHERE lawyer_id = OLD.lawyer_id
          AND rater_type = 'client'
          AND is_public = true
        ON CONFLICT (lawyer_id)
        DO UPDATE SET
            overall_rating = EXCLUDED.overall_rating,
            total_ratings = EXCLUDED.total_ratings,
            communication_avg = EXCLUDED.communication_avg,
            expertise_avg = EXCLUDED.expertise_avg,
            responsiveness_avg = EXCLUDED.responsiveness_avg,
            value_avg = EXCLUDED.value_avg,
            star_distribution = EXCLUDED.star_distribution,
            last_updated = EXCLUDED.last_updated;
    END IF;
    
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_lawyer_stats
    AFTER INSERT OR UPDATE OR DELETE ON ratings
    FOR EACH ROW
    EXECUTE FUNCTION update_lawyer_rating_stats();

-- =============================================================================
-- POLÍTICAS RLS (Row Level Security)
-- =============================================================================

-- Habilitar RLS
ALTER TABLE ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE lawyer_rating_stats ENABLE ROW LEVEL SECURITY;

-- Política para leitura de avaliações
CREATE POLICY "ratings_read_policy" ON ratings
    FOR SELECT USING (
        -- Qualquer one pode ler avaliações públicas
        is_public = true
        OR
        -- Usuários envolvidos no caso podem ver a avaliação
        rater_id = auth.uid()
        OR
        lawyer_id = auth.uid()
        OR
        client_id = auth.uid()
    );

-- Política para criação de avaliações
CREATE POLICY "ratings_create_policy" ON ratings
    FOR INSERT WITH CHECK (
        -- Só pode criar se for o rater
        rater_id = auth.uid()
        AND
        -- E se estiver envolvido no caso
        (
            (rater_type = 'client' AND client_id = auth.uid())
            OR
            (rater_type = 'lawyer' AND lawyer_id = auth.uid())
        )
    );

-- Política para atualização (somente próprias avaliações)
CREATE POLICY "ratings_update_policy" ON ratings
    FOR UPDATE USING (rater_id = auth.uid());

-- Política para exclusão (somente próprias avaliações)
CREATE POLICY "ratings_delete_policy" ON ratings
    FOR DELETE USING (rater_id = auth.uid());

-- Política para estatísticas (leitura pública)
CREATE POLICY "lawyer_stats_read_policy" ON lawyer_rating_stats
    FOR SELECT USING (true);

-- =============================================================================
-- DADOS INICIAIS E COMENTÁRIOS
-- =============================================================================

-- Comentários das tabelas
COMMENT ON TABLE ratings IS 'Avaliações de casos finalizados entre clientes e advogados';
COMMENT ON TABLE lawyer_rating_stats IS 'Estatísticas agregadas de avaliações por advogado';

-- Comentários das colunas principais
COMMENT ON COLUMN ratings.rater_type IS 'Tipo do avaliador: client ou lawyer';
COMMENT ON COLUMN ratings.overall_rating IS 'Avaliação geral (1-5)';
COMMENT ON COLUMN ratings.communication_rating IS 'Avaliação da comunicação (1-5)';
COMMENT ON COLUMN ratings.expertise_rating IS 'Avaliação da expertise técnica (1-5)';
COMMENT ON COLUMN ratings.responsiveness_rating IS 'Avaliação da responsividade (1-5)';
COMMENT ON COLUMN ratings.value_rating IS 'Avaliação do custo-benefício (1-5)';
COMMENT ON COLUMN ratings.tags IS 'Tags destacadas pelo avaliador';
COMMENT ON COLUMN ratings.helpful_votes IS 'Número de votos de utilidade da avaliação';

-- Inserir dados de exemplo (opcional, apenas para desenvolvimento)
-- INSERT INTO ratings (case_id, lawyer_id, client_id, rater_id, rater_type, overall_rating, communication_rating, expertise_rating, responsiveness_rating, value_rating, comment, tags)
-- VALUES (...);

-- =============================================================================
-- FIM DA MIGRAÇÃO
-- ============================================================================= 