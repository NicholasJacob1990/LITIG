-- Função PostgreSQL V2: Busca híbrida com embeddings 1024D especializados
-- Estratégia: Voyage Law-2 + OpenAI 3-large + Arctic Embed L
-- Mantém compatibilidade com sistema atual (768D) durante migração

-- 1. Função principal V2 com embeddings 1024D
CREATE OR REPLACE FUNCTION find_nearby_lawyers_v2(
    lat float,
    lon float,
    km float,
    embedding vector(1024),
    use_fallback boolean DEFAULT false
)
RETURNS TABLE(
    id text,
    nome text,
    tags_expertise text[],
    geo_latlon float[],
    curriculo_json jsonb,
    kpi jsonb,
    similarity_score float,
    distance_km float,
    embedding_model text
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Se use_fallback=true ou embedding V2 não disponível, usar função original
    IF use_fallback OR embedding IS NULL THEN
        RETURN QUERY
        SELECT 
            l.id::text,
            l.nome,
            l.tags_expertise,
            ARRAY[l.latitude, l.longitude]::float[] as geo_latlon,
            l.curriculo_json,
            l.kpi,
            NULL::float as similarity_score,
            ST_Distance(
                CAST(ST_SetSRID(ST_MakePoint(lon, lat), 4326) AS geography),
                CAST(ST_SetSRID(ST_MakePoint(l.longitude, l.latitude), 4326) AS geography)
            ) / 1000 as distance_km,
            'fallback_geo_only'::text as embedding_model
        FROM public.lawyers l
        WHERE ST_DWithin(
            CAST(ST_SetSRID(ST_MakePoint(lon, lat), 4326) AS geography),
            CAST(ST_SetSRID(ST_MakePoint(l.longitude, l.latitude), 4326) AS geography),
            km * 1000
        )
        AND l.ativo = true
        ORDER BY distance_km
        LIMIT 100;
        RETURN;
    END IF;

    -- Busca principal com embeddings V2 (1536D)
    RETURN QUERY
    SELECT 
        l.id::text,
        l.nome,
        l.tags_expertise,
        ARRAY[l.latitude, l.longitude]::float[] as geo_latlon,
        l.curriculo_json,
        l.kpi,
        1.0 - (l.cv_embedding_v2 <=> embedding) as similarity_score,
        ST_Distance(
            CAST(ST_SetSRID(ST_MakePoint(lon, lat), 4326) AS geography),
            CAST(ST_SetSRID(ST_MakePoint(l.longitude, l.latitude), 4326) AS geography)
        ) / 1000 as distance_km,
        COALESCE(l.cv_embedding_v2_model, 'gemini-embedding-001')::text as embedding_model
    FROM public.lawyers l
    WHERE 
        l.cv_embedding_v2 IS NOT NULL
        AND l.ativo = true
        AND ST_DWithin(
            CAST(ST_SetSRID(ST_MakePoint(lon, lat), 4326) AS geography),
            CAST(ST_SetSRID(ST_MakePoint(l.longitude, l.latitude), 4326) AS geography),
            km * 1000
        )
    ORDER BY 
        l.cv_embedding_v2 <=> embedding,  -- Semantic similarity first
        distance_km                       -- Then geographic distance
    LIMIT 100;
END;
$$;

-- 2. Função híbrida inteligente que escolhe automaticamente a melhor estratégia
CREATE OR REPLACE FUNCTION find_nearby_lawyers_smart(
    lat float,
    lon float,
    km float,
    embedding_v1 vector(384) DEFAULT NULL,
    embedding_v2 vector(1024) DEFAULT NULL
)
RETURNS TABLE(
    id text,
    nome text,
    tags_expertise text[],
    geo_latlon float[],
    curriculo_json jsonb,
    kpi jsonb,
    similarity_score float,
    distance_km float,
    embedding_model text,
    search_strategy text
)
LANGUAGE plpgsql
AS $$
DECLARE
    v2_coverage_pct float;
    min_coverage_threshold float := 0.7; -- 70% dos advogados devem ter embedding V2
BEGIN
    -- Verifica cobertura de embeddings V2 na área
    SELECT 
        COALESCE(
            COUNT(CASE WHEN cv_embedding_v2 IS NOT NULL THEN 1 END)::float / 
            NULLIF(COUNT(*)::float, 0), 
            0
        ) INTO v2_coverage_pct
    FROM public.lawyers l
    WHERE 
        l.ativo = true
        AND ST_DWithin(
            CAST(ST_SetSRID(ST_MakePoint(lon, lat), 4326) AS geography),
            CAST(ST_SetSRID(ST_MakePoint(l.longitude, l.latitude), 4326) AS geography),
            km * 1000
        );

    -- Estratégia 1: Se temos boa cobertura V2 e embedding V2 disponível
    IF v2_coverage_pct >= min_coverage_threshold AND embedding_v2 IS NOT NULL THEN
        RETURN QUERY
        SELECT 
            r.id, r.nome, r.tags_expertise, r.geo_latlon, r.curriculo_json,
            r.kpi, r.similarity_score, r.distance_km, r.embedding_model,
            'v2_semantic'::text as search_strategy
        FROM find_nearby_lawyers_v2(lat, lon, km, embedding_v2, false) r;
        RETURN;
    END IF;

    -- Estratégia 2: Fallback para sistema V1 (768D) se disponível
    IF embedding_v1 IS NOT NULL THEN
        RETURN QUERY
        SELECT 
            l.id::text,
            l.nome,
            l.tags_expertise,
            ARRAY[l.latitude, l.longitude]::float[] as geo_latlon,
            l.curriculo_json,
            l.kpi,
            1.0 - (l.cv_embedding <=> embedding_v1) as similarity_score,
            ST_Distance(
                CAST(ST_SetSRID(ST_MakePoint(lon, lat), 4326) AS geography),
                CAST(ST_SetSRID(ST_MakePoint(l.longitude, l.latitude), 4326) AS geography)
            ) / 1000 as distance_km,
            'legacy_384d'::text as embedding_model,
            'v1_semantic'::text as search_strategy
        FROM public.lawyers l
        WHERE 
            l.cv_embedding IS NOT NULL
            AND l.ativo = true
            AND ST_DWithin(
                CAST(ST_SetSRID(ST_MakePoint(lon, lat), 4326) AS geography),
                CAST(ST_SetSRID(ST_MakePoint(l.longitude, l.latitude), 4326) AS geography),
                km * 1000
            )
        ORDER BY 
            l.cv_embedding <=> embedding_v1,
            distance_km
        LIMIT 100;
        RETURN;
    END IF;

    -- Estratégia 3: Fallback geográfico puro (sem embedding)
    RETURN QUERY
    SELECT 
        l.id::text,
        l.nome,
        l.tags_expertise,
        ARRAY[l.latitude, l.longitude]::float[] as geo_latlon,
        l.curriculo_json,
        l.kpi,
        NULL::float as similarity_score,
        ST_Distance(
            CAST(ST_SetSRID(ST_MakePoint(lon, lat), 4326) AS geography),
            CAST(ST_SetSRID(ST_MakePoint(l.longitude, l.latitude), 4326) AS geography)
        ) / 1000 as distance_km,
        'geographic_only'::text as embedding_model,
        'geographic_fallback'::text as search_strategy
    FROM public.lawyers l
    WHERE 
        l.ativo = true
        AND ST_DWithin(
            CAST(ST_SetSRID(ST_MakePoint(lon, lat), 4326) AS geography),
            CAST(ST_SetSRID(ST_MakePoint(l.longitude, l.latitude), 4326) AS geography),
            km * 1000
        )
    ORDER BY distance_km
    LIMIT 100;
END;
$$;

-- 3. Comentários para documentação
COMMENT ON FUNCTION find_nearby_lawyers_v2 IS 
'Busca advogados usando embeddings V2 (1024D) especializados em legal com fallback para busca geográfica';

COMMENT ON FUNCTION find_nearby_lawyers_smart IS 
'Busca inteligente que escolhe automaticamente entre V2, V1 ou geográfica baseado na cobertura';
 
 