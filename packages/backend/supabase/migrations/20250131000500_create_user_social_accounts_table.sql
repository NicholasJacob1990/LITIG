-- Migration: Create user_social_accounts table for social media connections
-- Date: 2025-01-31
-- Purpose: Store connected social media accounts (LinkedIn, Instagram, Facebook) via Unipile

-- Create ENUM for social providers
CREATE TYPE IF NOT EXISTS social_provider AS ENUM (
    'linkedin',
    'instagram', 
    'facebook',
    'twitter',
    'whatsapp'
);

-- Create user_social_accounts table
CREATE TABLE IF NOT EXISTS public.user_social_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    provider social_provider NOT NULL,
    account_id TEXT NOT NULL, -- Unipile account ID
    username TEXT,
    email TEXT,
    display_name TEXT,
    profile_url TEXT,
    avatar_url TEXT,
    follower_count INTEGER DEFAULT 0,
    following_count INTEGER DEFAULT 0,
    posts_count INTEGER DEFAULT 0,
    is_verified BOOLEAN DEFAULT FALSE,
    is_business_account BOOLEAN DEFAULT FALSE,
    last_sync_at TIMESTAMPTZ DEFAULT NOW(),
    connection_status TEXT DEFAULT 'active' CHECK (connection_status IN ('active', 'expired', 'revoked', 'error')),
    connection_metadata JSONB DEFAULT '{}',
    social_metrics JSONB DEFAULT '{}', -- Engagement, professional content ratio, etc.
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraint para evitar duplicatas
    UNIQUE(user_id, provider, account_id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_social_accounts_user_id ON public.user_social_accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_user_social_accounts_provider ON public.user_social_accounts(provider);
CREATE INDEX IF NOT EXISTS idx_user_social_accounts_status ON public.user_social_accounts(connection_status);
CREATE INDEX IF NOT EXISTS idx_user_social_accounts_sync ON public.user_social_accounts(last_sync_at);
CREATE INDEX IF NOT EXISTS idx_user_social_accounts_metrics ON public.user_social_accounts USING GIN(social_metrics);

-- Enable RLS
ALTER TABLE public.user_social_accounts ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own social accounts" ON public.user_social_accounts
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own social accounts" ON public.user_social_accounts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own social accounts" ON public.user_social_accounts
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own social accounts" ON public.user_social_accounts
    FOR DELETE USING (auth.uid() = user_id);

-- Create trigger for updated_at
CREATE OR REPLACE FUNCTION public.update_user_social_accounts_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_social_accounts_updated_at
    BEFORE UPDATE ON public.user_social_accounts
    FOR EACH ROW
    EXECUTE FUNCTION public.update_user_social_accounts_updated_at();

-- Comments for documentation
COMMENT ON TABLE public.user_social_accounts IS 'Stores connected social media accounts via Unipile SDK';
COMMENT ON COLUMN public.user_social_accounts.account_id IS 'Unipile account identifier';
COMMENT ON COLUMN public.user_social_accounts.social_metrics IS 'JSON with engagement metrics, professional content ratio, etc.';
COMMENT ON COLUMN public.user_social_accounts.connection_metadata IS 'JSON with connection-specific metadata from Unipile';

-- Create function to get user social summary
CREATE OR REPLACE FUNCTION public.get_user_social_summary(p_user_id UUID)
RETURNS TABLE (
    total_accounts INTEGER,
    platforms TEXT[],
    total_followers INTEGER,
    total_posts INTEGER,
    verified_accounts INTEGER,
    business_accounts INTEGER,
    last_sync TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as total_accounts,
        ARRAY_AGG(provider::TEXT) as platforms,
        COALESCE(SUM(follower_count), 0)::INTEGER as total_followers,
        COALESCE(SUM(posts_count), 0)::INTEGER as total_posts,
        COUNT(*) FILTER (WHERE is_verified = TRUE)::INTEGER as verified_accounts,
        COUNT(*) FILTER (WHERE is_business_account = TRUE)::INTEGER as business_accounts,
        MAX(last_sync_at) as last_sync
    FROM public.user_social_accounts 
    WHERE user_id = p_user_id 
    AND connection_status = 'active';
END;
$$; 