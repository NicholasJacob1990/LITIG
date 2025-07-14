-- Migração para adicionar suporte ao Unipile
-- Data: 2025-01-22
-- Descrição: Adiciona o Unipile como fonte de dados híbridos para comunicação/email

-- Adicionar Unipile como fonte válida nos enums (se necessário)
-- Nota: Como usamos JSONB, não precisamos alterar enums

-- Atualizar configurações de fontes de dados
INSERT INTO public.data_quality_metrics (
    entity_type,
    entity_id,
    source,
    confidence_score,
    data_freshness_hours,
    validation_status,
    last_updated
) VALUES (
    'system',
    'unipile_config',
    'unipile',
    0.75,
    4,
    'configured',
    NOW()
) ON CONFLICT (entity_type, entity_id, source) DO UPDATE SET
    confidence_score = EXCLUDED.confidence_score,
    data_freshness_hours = EXCLUDED.data_freshness_hours,
    validation_status = EXCLUDED.validation_status,
    last_updated = EXCLUDED.last_updated;

-- Adicionar comentário sobre as fontes atualizadas
COMMENT ON TABLE public.data_quality_metrics IS 'Métricas de qualidade por fonte de dados. Suporta: Escavador (0.30), Unipile (0.20), JusBrasil (0.25), CNJ (0.15), OAB (0.07), Sistema Interno (0.03)';

-- Atualizar função get_sync_statistics para incluir Unipile
CREATE OR REPLACE FUNCTION public.get_sync_statistics(
    p_entity_type text DEFAULT NULL,
    p_hours_back integer DEFAULT 24
) RETURNS TABLE (
    entity_type text,
    total_entities bigint,
    synced_entities bigint,
    sync_coverage numeric,
    avg_quality_score numeric,
    source_breakdown jsonb,
    last_sync_time timestamp with time zone
) AS $$
BEGIN
    RETURN QUERY
    WITH entity_stats AS (
        SELECT 
            dqm.entity_type,
            COUNT(DISTINCT dqm.entity_id) as total_entities,
            COUNT(DISTINCT CASE WHEN dqm.last_updated > NOW() - INTERVAL '1 hour' * p_hours_back THEN dqm.entity_id END) as synced_entities,
            AVG(dqm.confidence_score) as avg_quality_score,
            jsonb_object_agg(
                dqm.source,
                jsonb_build_object(
                    'count', COUNT(*),
                    'avg_confidence', AVG(dqm.confidence_score),
                    'last_updated', MAX(dqm.last_updated)
                )
            ) as source_breakdown,
            MAX(dqm.last_updated) as last_sync_time
        FROM public.data_quality_metrics dqm
        WHERE (p_entity_type IS NULL OR dqm.entity_type = p_entity_type)
        AND dqm.source IN ('escavador', 'unipile', 'jusbrasil', 'cnj', 'oab', 'internal')
        GROUP BY dqm.entity_type
    )
    SELECT 
        es.entity_type,
        es.total_entities,
        es.synced_entities,
        ROUND((es.synced_entities::numeric / NULLIF(es.total_entities, 0)) * 100, 2) as sync_coverage,
        ROUND(es.avg_quality_score, 3) as avg_quality_score,
        es.source_breakdown,
        es.last_sync_time
    FROM entity_stats es
    ORDER BY es.entity_type;
END;
$$ LANGUAGE plpgsql;

-- Índices para otimizar consultas do Unipile
CREATE INDEX IF NOT EXISTS idx_lawyers_data_transparency_unipile 
ON public.lawyers USING GIN ((data_transparency -> 'unipile'));

CREATE INDEX IF NOT EXISTS idx_law_firms_data_transparency_unipile 
ON public.law_firms USING GIN ((data_transparency -> 'unipile'));

-- Função para verificar configuração do Unipile
CREATE OR REPLACE FUNCTION public.check_unipile_configuration()
RETURNS TABLE (
    source text,
    configured boolean,
    api_endpoint text,
    confidence_score numeric,
    ttl_hours integer,
    last_check timestamp with time zone
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        'unipile'::text as source,
        EXISTS(
            SELECT 1 FROM public.data_quality_metrics 
            WHERE entity_type = 'system' 
            AND entity_id = 'unipile_config'
            AND validation_status = 'configured'
        ) as configured,
        'https://api.unipile.com/v1'::text as api_endpoint,
        0.75::numeric as confidence_score,
        4::integer as ttl_hours,
        NOW() as last_check;
END;
$$ LANGUAGE plpgsql;

-- Inserir configuração padrão do Unipile se não existir
INSERT INTO public.system_config (key, value, description, created_at, updated_at)
VALUES (
    'unipile_api_endpoint',
    'https://api.unipile.com/v1',
    'Endpoint da API do Unipile para dados de comunicação/email',
    NOW(),
    NOW()
) ON CONFLICT (key) DO UPDATE SET
    value = EXCLUDED.value,
    description = EXCLUDED.description,
    updated_at = EXCLUDED.updated_at;

-- Comentário final
COMMENT ON FUNCTION public.check_unipile_configuration() IS 'Verifica se o Unipile está configurado corretamente como fonte de dados'; 