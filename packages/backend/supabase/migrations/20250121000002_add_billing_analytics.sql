-- Migration: Add billing analytics table
-- Timestamp: 20250121000002
-- Description: Creates analytics table for tracking billing events and conversion metrics

-- Create billing analytics table
CREATE TABLE IF NOT EXISTS public.billing_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    event_name TEXT NOT NULL,
    properties JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for analytics queries
CREATE INDEX IF NOT EXISTS idx_billing_analytics_user_id ON public.billing_analytics(user_id);
CREATE INDEX IF NOT EXISTS idx_billing_analytics_event_name ON public.billing_analytics(event_name);
CREATE INDEX IF NOT EXISTS idx_billing_analytics_created_at ON public.billing_analytics(created_at);
CREATE INDEX IF NOT EXISTS idx_billing_analytics_entity_type ON public.billing_analytics USING GIN ((properties->>'entity_type'));
CREATE INDEX IF NOT EXISTS idx_billing_analytics_entity_id ON public.billing_analytics USING GIN ((properties->>'entity_id'));
CREATE INDEX IF NOT EXISTS idx_billing_analytics_plan ON public.billing_analytics USING GIN ((properties->>'new_plan'));

-- Enable RLS on analytics table
ALTER TABLE public.billing_analytics ENABLE ROW LEVEL SECURITY;

-- RLS policy for analytics (admin and own data access)
CREATE POLICY "Users can view their own analytics"
ON public.billing_analytics FOR SELECT
USING (
    user_id = auth.uid() 
    OR 
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE profiles.user_id = auth.uid() 
        AND profiles.role = 'admin'
    )
);

-- Function to track billing events from SQL
CREATE OR REPLACE FUNCTION public.track_billing_event(
    p_user_id UUID,
    p_event_name TEXT,
    p_properties JSONB DEFAULT '{}'
) RETURNS UUID AS $$
DECLARE
    event_id UUID;
BEGIN
    INSERT INTO public.billing_analytics (user_id, event_name, properties)
    VALUES (p_user_id, p_event_name, p_properties)
    RETURNING id INTO event_id;
    
    RETURN event_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION public.track_billing_event(UUID, TEXT, JSONB) TO authenticated;

-- Comments for documentation
COMMENT ON TABLE public.billing_analytics IS 'Analytics events for billing conversion tracking and metrics';
COMMENT ON COLUMN public.billing_analytics.event_name IS 'Type of event: billing_page_view, plan_selected, checkout_started, etc.';
COMMENT ON COLUMN public.billing_analytics.properties IS 'Event properties including entity_type, plan, amount, etc.';
COMMENT ON FUNCTION public.track_billing_event IS 'Helper function to track billing events from SQL triggers or RPC calls'; 