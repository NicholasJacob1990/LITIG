-- Comprehensive fix for lawyers_nearby function
-- This migration will ensure complete cleanup and recreation of the function

-- Drop ALL possible variants of the function that might exist
DROP FUNCTION IF EXISTS public.lawyers_nearby(numeric, numeric, numeric, text, numeric, boolean);
DROP FUNCTION IF EXISTS public.lawyers_nearby(double precision, double precision, double precision, text, double precision, boolean);
DROP FUNCTION IF EXISTS public.lawyers_nearby(decimal, decimal, integer, varchar, decimal, boolean);
DROP FUNCTION IF EXISTS public.lawyers_nearby(decimal, decimal, decimal, text, decimal, boolean);

-- Drop any other functions that might be interfering
DROP FUNCTION IF EXISTS public.lawyers_with_filters CASCADE;

-- Recreate the lawyers_nearby function with exact schema matching
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
    name varchar(255),
    oab_number varchar(50),
    primary_area varchar(100),
    specialties text[],
    rating decimal(3,2),
    review_count integer,
    experience integer,
    avatar_url text,
    lat decimal(10,8),
    lng decimal(11,8),
    distance_km decimal(10,2),
    response_time varchar(50),
    success_rate integer,
    hourly_rate decimal(10,2),
    consultation_fee decimal(10,2),
    is_available boolean,
    next_availability varchar(100),
    languages text[],
    consultation_types text[]
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
        l.rating,
        l.review_count,
        l.experience,
        l.avatar_url,
        l.lat,
        l.lng,
        (earth_distance(ll_to_earth(_lat, _lng), ll_to_earth(l.lat, l.lng)) / 1000)::decimal(10,2) as distance_km,
        l.response_time,
        l.success_rate,
        l.hourly_rate,
        l.consultation_fee,
        l.is_available,
        l.next_availability,
        l.languages,
        l.consultation_types
    FROM
        public.lawyers as l
    WHERE
        l.lat is not null
        AND l.lng is not null
        AND l.is_approved = true
        AND earth_box(ll_to_earth(_lat, _lng), _radius_km * 1000) @> ll_to_earth(l.lat, l.lng)
        AND earth_distance(ll_to_earth(_lat, _lng), ll_to_earth(l.lat, l.lng)) <= (_radius_km * 1000)
        AND (_area is null OR l.primary_area ilike '%' || _area || '%')
        AND l.rating >= _rating_min
        AND (_available is null OR l.is_available = _available)
    ORDER BY
        distance_km ASC, l.rating DESC;
END;
$$;
