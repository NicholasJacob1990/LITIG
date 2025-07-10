-- Add fields to lawyers table for CV analysis and profile completion
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS cv_url text;
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS cv_analysis jsonb;
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS review_count integer DEFAULT 0;
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS experience integer DEFAULT 0;
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS response_time varchar(50) DEFAULT '24h';
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS success_rate integer DEFAULT 0;
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS hourly_rate decimal(10,2) DEFAULT 0;
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS consultation_fee decimal(10,2) DEFAULT 0;
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS next_availability varchar(100) DEFAULT 'A definir';
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS languages text[] DEFAULT ARRAY['Português'];
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS consultation_types text[] DEFAULT ARRAY['chat', 'video'];
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS is_approved boolean DEFAULT false;
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS bio text;
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS education text[];
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS certifications text[];
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS professional_experience text[];
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS skills text[];
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS awards text[];
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS publications text[];
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS bar_associations text[];
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS practice_areas text[];
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS phone varchar(20);
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS email varchar(255);
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS website varchar(255);
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS linkedin varchar(255);
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS office_address text;
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS office_hours text;
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS graduation_year integer;
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS postgraduate_courses text[];
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS current_cases_count integer DEFAULT 0;
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS total_cases_count integer DEFAULT 0;
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS specialization_years jsonb; -- {area: years} format
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS professional_summary text;
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS availability_schedule jsonb; -- schedule format
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS consultation_methods text[] DEFAULT ARRAY['online', 'presencial'];
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS emergency_availability boolean DEFAULT false;
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS profile_completion_percentage integer DEFAULT 0;
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS cv_processed_at timestamp with time zone;
ALTER TABLE public.lawyers ADD COLUMN IF NOT EXISTS profile_updated_at timestamp with time zone DEFAULT now();

-- Create index for faster searches
CREATE INDEX IF NOT EXISTS idx_lawyers_is_approved ON public.lawyers (is_approved);
CREATE INDEX IF NOT EXISTS idx_lawyers_experience ON public.lawyers (experience);
CREATE INDEX IF NOT EXISTS idx_lawyers_rating ON public.lawyers (rating);
CREATE INDEX IF NOT EXISTS idx_lawyers_specialties ON public.lawyers USING gin (specialties);
CREATE INDEX IF NOT EXISTS idx_lawyers_practice_areas ON public.lawyers USING gin (practice_areas);
CREATE INDEX IF NOT EXISTS idx_lawyers_languages ON public.lawyers USING gin (languages);
CREATE INDEX IF NOT EXISTS idx_lawyers_consultation_types ON public.lawyers USING gin (consultation_types);

-- Update trigger for profile_updated_at
CREATE OR REPLACE FUNCTION update_lawyer_profile_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.profile_updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_lawyers_profile_updated_at ON public.lawyers;
CREATE TRIGGER update_lawyers_profile_updated_at 
    BEFORE UPDATE ON public.lawyers 
    FOR EACH ROW 
    EXECUTE FUNCTION update_lawyer_profile_updated_at();

-- Function to calculate profile completion percentage
CREATE OR REPLACE FUNCTION calculate_profile_completion(lawyer_id uuid)
RETURNS integer AS $$
DECLARE
    completion_score integer := 0;
    total_fields integer := 20; -- Total number of important fields
BEGIN
    SELECT 
        (CASE WHEN name IS NOT NULL AND name != '' THEN 1 ELSE 0 END) +
        (CASE WHEN oab_number IS NOT NULL AND oab_number != '' THEN 1 ELSE 0 END) +
        (CASE WHEN primary_area IS NOT NULL AND primary_area != '' THEN 1 ELSE 0 END) +
        (CASE WHEN avatar_url IS NOT NULL AND avatar_url != '' THEN 1 ELSE 0 END) +
        (CASE WHEN bio IS NOT NULL AND bio != '' THEN 1 ELSE 0 END) +
        (CASE WHEN phone IS NOT NULL AND phone != '' THEN 1 ELSE 0 END) +
        (CASE WHEN email IS NOT NULL AND email != '' THEN 1 ELSE 0 END) +
        (CASE WHEN experience IS NOT NULL AND experience > 0 THEN 1 ELSE 0 END) +
        (CASE WHEN hourly_rate IS NOT NULL AND hourly_rate > 0 THEN 1 ELSE 0 END) +
        (CASE WHEN consultation_fee IS NOT NULL AND consultation_fee > 0 THEN 1 ELSE 0 END) +
        (CASE WHEN education IS NOT NULL AND array_length(education, 1) > 0 THEN 1 ELSE 0 END) +
        (CASE WHEN specialties IS NOT NULL AND array_length(specialties, 1) > 0 THEN 1 ELSE 0 END) +
        (CASE WHEN practice_areas IS NOT NULL AND array_length(practice_areas, 1) > 0 THEN 1 ELSE 0 END) +
        (CASE WHEN languages IS NOT NULL AND array_length(languages, 1) > 0 THEN 1 ELSE 0 END) +
        (CASE WHEN consultation_types IS NOT NULL AND array_length(consultation_types, 1) > 0 THEN 1 ELSE 0 END) +
        (CASE WHEN professional_experience IS NOT NULL AND array_length(professional_experience, 1) > 0 THEN 1 ELSE 0 END) +
        (CASE WHEN certifications IS NOT NULL AND array_length(certifications, 1) > 0 THEN 1 ELSE 0 END) +
        (CASE WHEN skills IS NOT NULL AND array_length(skills, 1) > 0 THEN 1 ELSE 0 END) +
        (CASE WHEN office_address IS NOT NULL AND office_address != '' THEN 1 ELSE 0 END) +
        (CASE WHEN professional_summary IS NOT NULL AND professional_summary != '' THEN 1 ELSE 0 END)
    INTO completion_score
    FROM public.lawyers
    WHERE id = lawyer_id;
    
    RETURN ROUND((completion_score::decimal / total_fields::decimal) * 100);
END;
$$ language 'plpgsql';

-- Update existing lawyers with default values
UPDATE public.lawyers 
SET 
    review_count = COALESCE(review_count, 0),
    experience = COALESCE(experience, 0),
    response_time = COALESCE(response_time, '24h'),
    success_rate = COALESCE(success_rate, 0),
    hourly_rate = COALESCE(hourly_rate, 0),
    consultation_fee = COALESCE(consultation_fee, 0),
    next_availability = COALESCE(next_availability, 'A definir'),
    languages = COALESCE(languages, ARRAY['Português']),
    consultation_types = COALESCE(consultation_types, ARRAY['chat', 'video']),
    is_approved = COALESCE(is_approved, false),
    profile_completion_percentage = calculate_profile_completion(id),
    profile_updated_at = COALESCE(profile_updated_at, now())
WHERE TRUE;
