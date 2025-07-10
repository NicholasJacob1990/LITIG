-- Fix lawyers_nearby function column references
-- The function was referencing non-existent columns

-- Drop any existing versions of the function to avoid conflicts
DROP FUNCTION IF EXISTS public.lawyers_nearby(numeric, numeric, numeric, text, numeric, boolean);
DROP FUNCTION IF EXISTS public.lawyers_nearby(double precision, double precision, double precision, text, double precision, boolean);

-- Recreate the function with correct column references
CREATE OR REPLACE FUNCTION public.lawyers_nearby(
    _lat numeric,
    _lng numeric,
    _radius_km numeric default 50,
    _area text default null,
    _rating_min numeric default 0,
    _available boolean default null
)
RETURNS TABLE(
    id uuid,
    name text,
    oab_number text,
    primary_area text,
    specialties text[],
    avatar_url text,
    is_available boolean,
    rating numeric,
    lat numeric,
    lng numeric,
    distance_km numeric
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        l.id,
        l.name,
        l.oab_number,
        l.primary_area,
        l.specialties,
        l.avatar_url,  -- Fixed: was profile_picture_url
        l.is_available,
        l.rating,
        l.lat,
        l.lng,
        (earth_distance(ll_to_earth(_lat, _lng), ll_to_earth(l.lat, l.lng)) / 1000) as distance_km
    FROM
        public.lawyers as l
    WHERE
        l.lat is not null
        AND l.lng is not null
        AND earth_box(ll_to_earth(_lat, _lng), _radius_km * 1000) @> ll_to_earth(l.lat, l.lng)
        AND earth_distance(ll_to_earth(_lat, _lng), ll_to_earth(l.lat, l.lng)) <= (_radius_km * 1000)
        AND (_area is null OR l.primary_area ilike '%' || _area || '%')
        AND l.rating >= _rating_min
        AND (_available is null OR l.is_available = _available)
    ORDER BY
        (l.rating * 0.3 + (5 - least(earth_distance(ll_to_earth(_lat, _lng), ll_to_earth(l.lat, l.lng)) / 1000 / _radius_km * 5, 5)) * 0.7) desc,
        earth_distance(ll_to_earth(_lat, _lng), ll_to_earth(l.lat, l.lng)) asc;
END;
$$;
