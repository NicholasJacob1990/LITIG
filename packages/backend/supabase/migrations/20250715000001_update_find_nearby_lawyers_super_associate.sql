-- Migration: Update find_nearby_lawyers to include Super Associates
-- Timestamp: 20250715000001
-- Description: Atualiza função find_nearby_lawyers para incluir lawyer_platform_associate

-- Dropar função existente
DROP FUNCTION IF EXISTS public.find_nearby_lawyers(text, float8, float8, float8);

-- Criar função atualizada que inclui Super Associados
CREATE OR REPLACE FUNCTION public.find_nearby_lawyers(
    area text,
    lat float8,
    lon float8,
    km float8 DEFAULT 50.0
)
RETURNS TABLE (
    id uuid,
    nome text,
    tags_expertise text[],
    geo_latlon point,
    is_available boolean,
    rating numeric,
    distance_km float8,
    is_platform_associate boolean,
    contract_signed boolean,
    user_role text
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        l.id,
        l.name as nome,
        COALESCE(l.tags_expertise, ARRAY[l.primary_area]) as tags_expertise,
        l.geo_latlon,
        l.is_available,
        l.rating,
        -- Calcular distância em km
        (point(lon, lat) <@> l.geo_latlon) * 111.32 AS distance_km,
        COALESCE(l.is_platform_associate, FALSE) as is_platform_associate,
        COALESCE(l.contract_signed, FALSE) as contract_signed,
        p.role as user_role
    FROM 
        public.lawyers l
    JOIN 
        public.profiles p ON l.id = p.id
    WHERE 
        l.is_available = true
        AND l.geo_latlon IS NOT NULL
        -- Filtro de distância
        AND (point(lon, lat) <@> l.geo_latlon) * 111.32 <= km
        -- Filtro por área/especialidade
        AND (
            l.primary_area ILIKE '%' || area || '%'
            OR l.tags_expertise @> ARRAY[area]
            OR area = ANY(l.specialties)
        )
        -- Incluir apenas roles elegíveis
        AND (
            -- Advogados tradicionais
            p.role IN ('lawyer_individual', 'lawyer_office', 'lawyer_associated')
            OR 
            -- Super Associados com contrato assinado
            (p.role = 'lawyer_platform_associate' AND COALESCE(l.contract_signed, FALSE) = TRUE)
        )
    ORDER BY 
        distance_km ASC,
        l.rating DESC,
        l.name ASC;
END;
$$;

-- Criar função alternativa para busca sem localização geográfica
CREATE OR REPLACE FUNCTION public.find_lawyers_by_expertise(
    area text,
    exclude_ids uuid[] DEFAULT '{}'::uuid[]
)
RETURNS TABLE (
    id uuid,
    nome text,
    tags_expertise text[],
    is_available boolean,
    rating numeric,
    is_platform_associate boolean,
    contract_signed boolean,
    user_role text
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        l.id,
        l.name as nome,
        COALESCE(l.tags_expertise, ARRAY[l.primary_area]) as tags_expertise,
        l.is_available,
        l.rating,
        COALESCE(l.is_platform_associate, FALSE) as is_platform_associate,
        COALESCE(l.contract_signed, FALSE) as contract_signed,
        p.role as user_role
    FROM 
        public.lawyers l
    JOIN 
        public.profiles p ON l.id = p.id
    WHERE 
        l.is_available = true
        AND l.id != ALL(exclude_ids)
        -- Filtro por área/especialidade
        AND (
            l.primary_area ILIKE '%' || area || '%'
            OR l.tags_expertise @> ARRAY[area]
            OR area = ANY(l.specialties)
        )
        -- Incluir apenas roles elegíveis
        AND (
            -- Advogados tradicionais
            p.role IN ('lawyer_individual', 'lawyer_office', 'lawyer_associated')
            OR 
            -- Super Associados com contrato assinado
            (p.role = 'lawyer_platform_associate' AND COALESCE(l.contract_signed, FALSE) = TRUE)
        )
    ORDER BY 
        l.rating DESC,
        l.name ASC;
END;
$$;

-- Grant permissões para as funções
GRANT EXECUTE ON FUNCTION public.find_nearby_lawyers TO authenticated;
GRANT EXECUTE ON FUNCTION public.find_lawyers_by_expertise TO authenticated;
GRANT EXECUTE ON FUNCTION public.find_nearby_lawyers TO service_role;
GRANT EXECUTE ON FUNCTION public.find_lawyers_by_expertise TO service_role;

-- Comentários para documentação
COMMENT ON FUNCTION public.find_nearby_lawyers IS 'Busca advogados próximos incluindo Super Associados com contrato assinado';
COMMENT ON FUNCTION public.find_lawyers_by_expertise IS 'Busca advogados por expertise incluindo Super Associados com contrato assinado'; 