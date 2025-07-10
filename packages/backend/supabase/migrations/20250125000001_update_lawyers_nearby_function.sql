-- Migração: Atualizar função lawyers_nearby para usar novos campos
-- Data: 2025-01-25
-- Descrição: Atualiza função RPC para usar geo_latlon e tags_expertise

-- Dropar função antiga se existir
DROP FUNCTION IF EXISTS public.lawyers_nearby CASCADE;

-- Criar função atualizada
CREATE OR REPLACE FUNCTION public.lawyers_nearby(
    p_lat float8,
    p_lng float8,
    p_radius_km float8 DEFAULT 50.0,
    p_specialties text[] DEFAULT NULL
)
RETURNS TABLE (
    id uuid,
    name text,
    email text,
    phone text,
    oab_number text,
    tags_expertise text[],
    geo_latlon point,
    distance_km float8,
    avaliacao_media float8,
    total_cases integer,
    success_rate float8,
    hourly_rate numeric,
    cases_30d integer,
    capacidade_mensal integer,
    last_offered_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        l.id,
        l.name,
        l.email,
        l.phone,
        l.oab_number,
        l.tags_expertise,
        l.geo_latlon,
        -- Calcular distância em km usando a fórmula de Haversine
        (point(p_lng, p_lat) <@> l.geo_latlon) * 111.32 AS distance_km,
        COALESCE(l.avaliacao_media, 0.0) AS avaliacao_media,
        COALESCE(l.total_cases, 0) AS total_cases,
        COALESCE(l.success_rate, 0.0) AS success_rate,
        l.hourly_rate,
        COALESCE(l.cases_30d, 0) AS cases_30d,
        COALESCE(l.capacidade_mensal, 10) AS capacidade_mensal,
        l.last_offered_at
    FROM 
        public.lawyers l
    WHERE 
        l.geo_latlon IS NOT NULL
        -- Filtro de distância usando operador de distância do PostgreSQL
        AND (point(p_lng, p_lat) <@> l.geo_latlon) * 111.32 <= p_radius_km
        -- Filtro opcional por especialidades
        AND (
            p_specialties IS NULL 
            OR p_specialties = '{}'
            OR l.tags_expertise && p_specialties
        )
    ORDER BY 
        distance_km ASC,
        l.avaliacao_media DESC,
        l.total_cases DESC;
END;
$$;

-- Criar índice espacial se não existir
CREATE INDEX IF NOT EXISTS idx_lawyers_geo_latlon_active 
ON public.lawyers USING GIST (geo_latlon) 
WHERE geo_latlon IS NOT NULL;

-- Grant permissões necessárias
GRANT EXECUTE ON FUNCTION public.lawyers_nearby TO authenticated;
GRANT EXECUTE ON FUNCTION public.lawyers_nearby TO service_role;

-- Adicionar comentário para documentação
COMMENT ON FUNCTION public.lawyers_nearby IS 'Busca advogados próximos a uma localização, com filtro opcional por especialidades';

-- Teste da função (comentado para produção)
-- SELECT * FROM lawyers_nearby(-23.550520, -46.633308, 10.0, ARRAY['Trabalhista', 'Civil']); 