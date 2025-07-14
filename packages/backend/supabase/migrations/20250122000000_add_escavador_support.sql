-- Migração para adicionar suporte ao Escavador
-- Data: 2025-01-22
-- Descrição: Adiciona o Escavador como fonte de dados híbridos

-- Adicionar Escavador como fonte válida nos enums (se necessário)
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
    'escavador_config',
    'escavador',
    0.80,
    8,
    'configured',
    NOW()
) ON CONFLICT (entity_type, entity_id, source) DO UPDATE SET
    confidence_score = EXCLUDED.confidence_score,
    data_freshness_hours = EXCLUDED.data_freshness_hours,
    validation_status = EXCLUDED.validation_status,
    last_updated = EXCLUDED.last_updated;

-- Adicionar comentário sobre o Escavador
COMMENT ON TABLE public.data_quality_metrics IS 'Métricas de qualidade por fonte de dados. Suporta: JusBrasil (0.35), Escavador (0.25), CNJ (0.25), OAB (0.10), Sistema Interno (0.05)';

-- Atualizar função get_sync_statistics para incluir Escavador
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
            CASE 
                WHEN l.id IS NOT NULL THEN 'lawyer'
                WHEN lf.id IS NOT NULL THEN 'law_firm'
                ELSE 'unknown'
            END as etype,
            COALESCE(l.id, lf.id) as entity_id,
            COALESCE(l.data_quality_score, lf.data_quality_score, 0) as quality_score,
            COALESCE(l.data_last_synced, lf.data_last_synced) as last_synced,
            COALESCE(l.data_transparency, lf.data_transparency, '[]'::jsonb) as transparency
        FROM public.lawyers l
        FULL OUTER JOIN public.law_firms lf ON FALSE -- Separar entidades
        WHERE (p_entity_type IS NULL OR 
               (p_entity_type = 'lawyer' AND l.id IS NOT NULL) OR
               (p_entity_type = 'law_firm' AND lf.id IS NOT NULL))
    ),
    source_stats AS (
        SELECT 
            etype,
            COUNT(*) as total,
            COUNT(CASE WHEN last_synced > NOW() - INTERVAL '1 hour' * p_hours_back THEN 1 END) as synced,
            AVG(quality_score) as avg_quality,
            MAX(last_synced) as max_sync_time,
            jsonb_build_object(
                'jusbrasil', COUNT(CASE WHEN transparency ? 'jusbrasil' THEN 1 END),
                'escavador', COUNT(CASE WHEN transparency ? 'escavador' THEN 1 END),
                'cnj', COUNT(CASE WHEN transparency ? 'cnj' THEN 1 END),
                'oab', COUNT(CASE WHEN transparency ? 'oab' THEN 1 END),
                'internal', COUNT(CASE WHEN transparency ? 'internal' THEN 1 END)
            ) as sources
        FROM entity_stats
        GROUP BY etype
    )
    SELECT 
        ss.etype,
        ss.total,
        ss.synced,
        CASE WHEN ss.total > 0 THEN ROUND((ss.synced::numeric / ss.total::numeric) * 100, 2) ELSE 0 END,
        ROUND(ss.avg_quality, 3),
        ss.sources,
        ss.max_sync_time
    FROM source_stats ss
    ORDER BY ss.etype;
END;
$$ LANGUAGE plpgsql;

-- Comentário sobre a função atualizada
COMMENT ON FUNCTION public.get_sync_statistics IS 'Estatísticas de sincronização incluindo suporte ao Escavador';

-- Criar índice para melhorar performance de queries com Escavador
CREATE INDEX IF NOT EXISTS idx_lawyers_data_transparency_escavador 
ON public.lawyers USING gin ((data_transparency->'escavador'));

CREATE INDEX IF NOT EXISTS idx_law_firms_data_transparency_escavador 
ON public.law_firms USING gin ((data_transparency->'escavador'));

-- Inserir log de migração
INSERT INTO public.sync_logs (
    entity_type,
    entity_id,
    sync_type,
    status,
    details,
    created_at
) VALUES (
    'system',
    'migration',
    'schema_update',
    'success',
    jsonb_build_object(
        'migration', '20250122000000_add_escavador_support',
        'description', 'Adicionado suporte ao Escavador como fonte de dados híbridos',
        'new_source', 'escavador',
        'weight', 0.25,
        'ttl_hours', 8,
        'confidence_base', 0.80
    ),
    NOW()
); 