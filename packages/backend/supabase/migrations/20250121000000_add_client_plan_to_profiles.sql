-- Migration: Add client plan field to profiles table
-- Timestamp: 20250121000000
-- Description: Adds plan field to profiles table to support VIP/ENTERPRISE client plans

-- Create enum for client plans
CREATE TYPE IF NOT EXISTS clientplan AS ENUM ('FREE', 'VIP', 'ENTERPRISE');

-- Add plan column to profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS plan clientplan DEFAULT 'FREE' NOT NULL;

-- Add index for plan-based queries
CREATE INDEX IF NOT EXISTS idx_profiles_plan ON public.profiles(plan);

-- Add comment for documentation
COMMENT ON COLUMN public.profiles.plan IS 'Cliente plan: FREE (default), VIP (premium services), ENTERPRISE (corporate clients)';

-- Update existing profiles to have FREE plan (already default)
-- This is safe because the column has a default value

-- Create function to get client plan for premium criteria evaluation
CREATE OR REPLACE FUNCTION public.get_client_plan(client_user_id uuid)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    client_plan text;
BEGIN
    SELECT plan::text INTO client_plan
    FROM public.profiles
    WHERE user_id = client_user_id;
    
    RETURN COALESCE(client_plan, 'FREE');
END;
$$;

-- Grant execution permission on the function
GRANT EXECUTE ON FUNCTION public.get_client_plan(uuid) TO authenticated; 