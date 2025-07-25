-- Migration: Add billing tables for Stripe integration
-- Timestamp: 20250121000001
-- Description: Creates tables to support Stripe billing, subscriptions, and audit trail

-- Add Stripe customer ID to profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS stripe_customer_id TEXT UNIQUE;

-- Create index for Stripe customer lookups
CREATE INDEX IF NOT EXISTS idx_profiles_stripe_customer_id ON public.profiles(stripe_customer_id);

-- Update client plan ENUM to include all plan types
ALTER TYPE clientplan ADD VALUE IF NOT EXISTS 'PRO';
ALTER TYPE clientplan ADD VALUE IF NOT EXISTS 'PARTNER';
ALTER TYPE clientplan ADD VALUE IF NOT EXISTS 'PREMIUM';

-- Add plan field to lawyers table for PRO/PARTNER plans
ALTER TABLE public.lawyers 
ADD COLUMN IF NOT EXISTS plan clientplan DEFAULT 'FREE' NOT NULL;

-- Add plan field to law_firms table for PARTNER/PREMIUM plans
ALTER TABLE public.law_firms 
ADD COLUMN IF NOT EXISTS plan clientplan DEFAULT 'FREE' NOT NULL;

-- Create indexes for plan-based queries
CREATE INDEX IF NOT EXISTS idx_lawyers_plan ON public.lawyers(plan);
CREATE INDEX IF NOT EXISTS idx_law_firms_plan ON public.law_firms(plan);

-- Create billing records table for audit trail (expanded for all entity types)
CREATE TABLE IF NOT EXISTS public.billing_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    entity_type TEXT NOT NULL CHECK (entity_type IN ('client', 'lawyer', 'firm')),
    entity_id UUID NOT NULL, -- Can reference profiles, lawyers, or law_firms
    stripe_subscription_id TEXT UNIQUE NOT NULL,
    plan TEXT NOT NULL CHECK (plan IN ('FREE', 'VIP', 'ENTERPRISE', 'PRO', 'PARTNER', 'PREMIUM')),
    amount_cents INTEGER NOT NULL CHECK (amount_cents >= 0),
    status TEXT NOT NULL CHECK (status IN ('active', 'cancelled', 'past_due', 'trialing')),
    billing_period_start TIMESTAMPTZ NOT NULL,
    billing_period_end TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create billing issues table for failed payments
CREATE TABLE IF NOT EXISTS public.billing_issues (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    entity_type TEXT NOT NULL CHECK (entity_type IN ('client', 'lawyer', 'firm')),
    entity_id UUID NOT NULL,
    issue_type TEXT NOT NULL CHECK (issue_type IN ('payment_failed', 'subscription_expired', 'card_declined')),
    stripe_invoice_id TEXT,
    status TEXT NOT NULL CHECK (status IN ('pending_review', 'resolved', 'escalated')) DEFAULT 'pending_review',
    details JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_at TIMESTAMPTZ
);

-- Create plan history table for tracking upgrades/downgrades (universal)
CREATE TABLE IF NOT EXISTS public.plan_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    entity_type TEXT NOT NULL CHECK (entity_type IN ('client', 'lawyer', 'firm')),
    entity_id UUID NOT NULL,
    old_plan TEXT,
    new_plan TEXT NOT NULL CHECK (new_plan IN ('FREE', 'VIP', 'ENTERPRISE', 'PRO', 'PARTNER', 'PREMIUM')),
    change_reason TEXT CHECK (change_reason IN ('upgrade', 'downgrade', 'cancellation', 'admin_change')),
    stripe_event_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_billing_records_user_id ON public.billing_records(user_id);
CREATE INDEX IF NOT EXISTS idx_billing_records_entity ON public.billing_records(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_billing_records_status ON public.billing_records(status);
CREATE INDEX IF NOT EXISTS idx_billing_records_stripe_subscription_id ON public.billing_records(stripe_subscription_id);

CREATE INDEX IF NOT EXISTS idx_billing_issues_user_id ON public.billing_issues(user_id);
CREATE INDEX IF NOT EXISTS idx_billing_issues_entity ON public.billing_issues(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_billing_issues_status ON public.billing_issues(status);
CREATE INDEX IF NOT EXISTS idx_billing_issues_created_at ON public.billing_issues(created_at);

CREATE INDEX IF NOT EXISTS idx_plan_history_user_id ON public.plan_history(user_id);
CREATE INDEX IF NOT EXISTS idx_plan_history_entity ON public.plan_history(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_plan_history_created_at ON public.plan_history(created_at);

-- Enable RLS on billing tables
ALTER TABLE public.billing_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.billing_issues ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plan_history ENABLE ROW LEVEL SECURITY;

-- RLS policies for billing_records
CREATE POLICY "Users can view their own billing records"
ON public.billing_records FOR SELECT
USING (user_id = auth.uid());

-- RLS policies for billing_issues (admin only for now)
CREATE POLICY "Admins can view all billing issues"
ON public.billing_issues FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE profiles.user_id = auth.uid() 
        AND profiles.role = 'admin'
    )
);

-- RLS policies for plan_history
CREATE POLICY "Users can view their own plan history"
ON public.plan_history FOR SELECT
USING (user_id = auth.uid());

-- Function to automatically record plan changes for clients
CREATE OR REPLACE FUNCTION public.record_client_plan_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Only record if plan actually changed
    IF OLD.plan IS DISTINCT FROM NEW.plan THEN
        INSERT INTO public.plan_history (
            user_id,
            entity_type,
            entity_id,
            old_plan,
            new_plan,
            change_reason
        ) VALUES (
            NEW.user_id,
            'client',
            NEW.id,
            OLD.plan,
            NEW.plan,
            CASE 
                WHEN OLD.plan = 'FREE' AND NEW.plan IN ('VIP', 'ENTERPRISE') THEN 'upgrade'
                WHEN OLD.plan IN ('VIP', 'ENTERPRISE') AND NEW.plan = 'FREE' THEN 'downgrade'
                WHEN OLD.plan = 'VIP' AND NEW.plan = 'ENTERPRISE' THEN 'upgrade'
                WHEN OLD.plan = 'ENTERPRISE' AND NEW.plan = 'VIP' THEN 'downgrade'
                ELSE 'admin_change'
            END
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to automatically record plan changes for lawyers
CREATE OR REPLACE FUNCTION public.record_lawyer_plan_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Only record if plan actually changed
    IF OLD.plan IS DISTINCT FROM NEW.plan THEN
        INSERT INTO public.plan_history (
            user_id,
            entity_type,
            entity_id,
            old_plan,
            new_plan,
            change_reason
        ) VALUES (
            (SELECT user_id FROM public.profiles WHERE id = NEW.id),
            'lawyer',
            NEW.id,
            OLD.plan,
            NEW.plan,
            CASE 
                WHEN OLD.plan = 'FREE' AND NEW.plan = 'PRO' THEN 'upgrade'
                WHEN OLD.plan = 'PRO' AND NEW.plan = 'FREE' THEN 'downgrade'
                ELSE 'admin_change'
            END
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to automatically record plan changes for firms
CREATE OR REPLACE FUNCTION public.record_firm_plan_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Only record if plan actually changed
    IF OLD.plan IS DISTINCT FROM NEW.plan THEN
        INSERT INTO public.plan_history (
            user_id,
            entity_type,
            entity_id,
            old_plan,
            new_plan,
            change_reason
        ) VALUES (
            -- Get owner/main user of the firm (you may need to adjust this logic)
            (SELECT user_id FROM public.profiles p 
             JOIN public.lawyers l ON p.user_id = l.user_id 
             WHERE l.firm_id = NEW.id LIMIT 1),
            'firm',
            NEW.id,
            OLD.plan,
            NEW.plan,
            CASE 
                WHEN OLD.plan = 'FREE' AND NEW.plan IN ('PARTNER', 'PREMIUM') THEN 'upgrade'
                WHEN OLD.plan IN ('PARTNER', 'PREMIUM') AND NEW.plan = 'FREE' THEN 'downgrade'
                WHEN OLD.plan = 'PARTNER' AND NEW.plan = 'PREMIUM' THEN 'upgrade'
                WHEN OLD.plan = 'PREMIUM' AND NEW.plan = 'PARTNER' THEN 'downgrade'
                ELSE 'admin_change'
            END
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Triggers to automatically record plan changes
CREATE TRIGGER trigger_record_client_plan_change
    AFTER UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.record_client_plan_change();

CREATE TRIGGER trigger_record_lawyer_plan_change
    AFTER UPDATE ON public.lawyers
    FOR EACH ROW
    EXECUTE FUNCTION public.record_lawyer_plan_change();

CREATE TRIGGER trigger_record_firm_plan_change
    AFTER UPDATE ON public.law_firms
    FOR EACH ROW
    EXECUTE FUNCTION public.record_firm_plan_change();

-- Function to sync plan to user metadata (for JWT claims) - Universal
CREATE OR REPLACE FUNCTION public.sync_plan_to_user_metadata()
RETURNS TRIGGER AS $$
DECLARE
    target_user_id UUID;
    plan_value TEXT;
BEGIN
    -- Determine user_id and plan based on which table triggered
    IF TG_TABLE_NAME = 'profiles' THEN
        target_user_id := NEW.user_id;
        plan_value := NEW.plan;
    ELSIF TG_TABLE_NAME = 'lawyers' THEN
        SELECT user_id INTO target_user_id FROM public.profiles WHERE id = NEW.id;
        plan_value := NEW.plan;
    ELSIF TG_TABLE_NAME = 'law_firms' THEN
        -- For firms, sync to the main owner/partner
        SELECT p.user_id INTO target_user_id 
        FROM public.profiles p 
        JOIN public.lawyers l ON p.user_id = l.user_id 
        WHERE l.firm_id = NEW.id 
        ORDER BY l.created_at ASC 
        LIMIT 1;
        plan_value := NEW.plan;
    END IF;
    
    -- Update auth.users.raw_user_meta_data to include plan in JWT
    IF target_user_id IS NOT NULL THEN
        UPDATE auth.users 
        SET raw_user_meta_data = COALESCE(raw_user_meta_data, '{}'::jsonb) || jsonb_build_object('plan', plan_value)
        WHERE id = target_user_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Triggers to sync plan changes to JWT metadata
CREATE TRIGGER trigger_sync_client_plan_to_jwt
    AFTER UPDATE ON public.profiles
    FOR EACH ROW
    WHEN (OLD.plan IS DISTINCT FROM NEW.plan)
    EXECUTE FUNCTION public.sync_plan_to_user_metadata();

CREATE TRIGGER trigger_sync_lawyer_plan_to_jwt
    AFTER UPDATE ON public.lawyers
    FOR EACH ROW
    WHEN (OLD.plan IS DISTINCT FROM NEW.plan)
    EXECUTE FUNCTION public.sync_plan_to_user_metadata();

CREATE TRIGGER trigger_sync_firm_plan_to_jwt
    AFTER UPDATE ON public.law_firms
    FOR EACH ROW
    WHEN (OLD.plan IS DISTINCT FROM NEW.plan)
    EXECUTE FUNCTION public.sync_plan_to_user_metadata();

-- Comments for documentation
COMMENT ON TABLE public.billing_records IS 'Audit trail for Stripe billing records and subscriptions (clients, lawyers, firms)';
COMMENT ON TABLE public.billing_issues IS 'Tracks billing issues like failed payments for manual review (all entity types)';
COMMENT ON TABLE public.plan_history IS 'Historical record of all plan changes for each entity (clients, lawyers, firms)';

COMMENT ON COLUMN public.profiles.stripe_customer_id IS 'Stripe customer ID for billing integration';
COMMENT ON COLUMN public.billing_records.entity_type IS 'Type of entity: client, lawyer, or firm';
COMMENT ON COLUMN public.billing_records.entity_id IS 'ID of the entity (profiles.id, lawyers.id, or law_firms.id)';
COMMENT ON COLUMN public.billing_records.amount_cents IS 'Amount in cents to avoid floating point issues';
COMMENT ON COLUMN public.plan_history.change_reason IS 'Reason for plan change: upgrade, downgrade, cancellation, or admin_change'; 