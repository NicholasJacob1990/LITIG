// // -- Migration: Add SLA settings for law firms
// // -- Date: 2025-01-31
// // -- Purpose: Allow law firms to customize SLA timeouts for internal delegations
// // 
// // -- Create SLA settings table
// // CREATE TABLE IF NOT EXISTS public.firm_sla_settings (
// //     id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
// //     firm_id uuid REFERENCES public.firms(id) ON DELETE CASCADE,
// //     created_at timestamp with time zone DEFAULT NOW(),
// //     updated_at timestamp with time zone DEFAULT NOW(),
// //     
// //     -- SLA configurations for different scenarios
// //     default_internal_delegation_hours integer DEFAULT 48 CHECK (default_internal_delegation_hours >= 1 AND default_internal_delegation_hours <= 720), -- Max 30 days
// //     urgent_internal_delegation_hours integer DEFAULT 24 CHECK (urgent_internal_delegation_hours >= 1 AND urgent_internal_delegation_hours <= 168), -- Max 7 days
// //     complex_case_delegation_hours integer DEFAULT 72 CHECK (complex_case_delegation_hours >= 1 AND complex_case_delegation_hours <= 720), -- Max 30 days
// //     
// //     -- Notification settings
// //     notify_before_deadline_hours integer DEFAULT 4 CHECK (notify_before_deadline_hours >= 1 AND notify_before_deadline_hours <= 48),
// //     escalate_after_deadline_hours integer DEFAULT 2 CHECK (escalate_after_deadline_hours >= 0 AND escalate_after_deadline_hours <= 24),
// //     
// //     -- Business rules
// //     allow_weekend_deadlines boolean DEFAULT false,
// //     business_hours_only boolean DEFAULT false,
// //     business_start_hour integer DEFAULT 9 CHECK (business_start_hour >= 0 AND business_start_hour <= 23),
// //     business_end_hour integer DEFAULT 18 CHECK (business_end_hour >= 1 AND business_end_hour <= 23),
// //     
// //     -- Metadata
// //     settings_metadata jsonb DEFAULT '{}',
// //     is_active boolean DEFAULT true,
// //     
// //     -- Ensure one settings per firm
// //     CONSTRAINT unique_firm_sla_settings UNIQUE (firm_id)
// // );
// // 
// // -- Create indexes
// // CREATE INDEX IF NOT EXISTS idx_firm_sla_settings_firm_id ON public.firm_sla_settings(firm_id);
// // CREATE INDEX IF NOT EXISTS idx_firm_sla_settings_active ON public.firm_sla_settings(is_active);
// // 
// // -- Create function to update updated_at
// // CREATE OR REPLACE FUNCTION update_firm_sla_settings_updated_at()
// // RETURNS TRIGGER AS $$
// // BEGIN
// //     NEW.updated_at = NOW();
// //     RETURN NEW;
// // END;
// // $$ LANGUAGE plpgsql;
// // 
// // -- Create trigger
// // CREATE TRIGGER trigger_update_firm_sla_settings_updated_at
// //     BEFORE UPDATE ON public.firm_sla_settings
// //     FOR EACH ROW
// //     EXECUTE FUNCTION update_firm_sla_settings_updated_at();
// // 
// // -- Add RLS policies
// // ALTER TABLE public.firm_sla_settings ENABLE ROW LEVEL SECURITY;
// // 
// // -- Policy: Firm owners and associates can view/manage their firm's SLA settings
// // CREATE POLICY "Firm members can manage SLA settings" ON public.firm_sla_settings
// //     FOR ALL USING (
// //         EXISTS (
// //             SELECT 1 FROM public.firm_lawyers fl
// //             WHERE fl.firm_id = firm_sla_settings.firm_id
// //             AND fl.lawyer_id = auth.uid()
// //             AND fl.role IN ('owner', 'partner', 'admin')
// //             AND fl.is_active = true
// //         )
// //     );
// // 
// // -- Policy: Associates can view SLA settings (read-only)
// // CREATE POLICY "Firm associates can view SLA settings" ON public.firm_sla_settings
// //     FOR SELECT USING (
// //         EXISTS (
// //             SELECT 1 FROM public.firm_lawyers fl
// //             WHERE fl.firm_id = firm_sla_settings.firm_id
// //             AND fl.lawyer_id = auth.uid()
// //             AND fl.is_active = true
// //         )
// //     );
// // 
// // -- Create default SLA settings for existing firms
// // INSERT INTO public.firm_sla_settings (firm_id)
// // SELECT f.id
// // FROM public.firms f
// // WHERE NOT EXISTS (
// //     SELECT 1 FROM public.firm_sla_settings sla
// //     WHERE sla.firm_id = f.id
// // )
// // ON CONFLICT (firm_id) DO NOTHING;
// // 
// // -- Add SLA override fields to offers table
// // ALTER TABLE public.offers ADD COLUMN IF NOT EXISTS sla_hours_override integer;
// // ALTER TABLE public.offers ADD COLUMN IF NOT EXISTS sla_priority_level integer DEFAULT 1 CHECK (sla_priority_level >= 1 AND sla_priority_level <= 3);
// // 
// // -- Add comments for documentation
// // COMMENT ON TABLE public.firm_sla_settings IS 'SLA configuration settings for law firms internal delegations';
// // COMMENT ON COLUMN public.firm_sla_settings.default_internal_delegation_hours IS 'Default SLA hours for internal delegations';
// // COMMENT ON COLUMN public.firm_sla_settings.urgent_internal_delegation_hours IS 'SLA hours for urgent internal delegations';
// // COMMENT ON COLUMN public.firm_sla_settings.complex_case_delegation_hours IS 'SLA hours for complex case delegations';
// // COMMENT ON COLUMN public.offers.sla_hours_override IS 'Override SLA hours for this specific offer';
// // COMMENT ON COLUMN public.offers.sla_priority_level IS 'Priority level: 1=normal, 2=urgent, 3=emergency';
// // 
// // -- Create function to calculate deadline with business rules
// // CREATE OR REPLACE FUNCTION calculate_delegation_deadline(
// //     p_firm_id uuid,
// //     p_priority_level integer DEFAULT 1,
// //     p_sla_override_hours integer DEFAULT NULL,
// //     p_start_time timestamp with time zone DEFAULT NOW()
// // ) RETURNS timestamp with time zone AS $$
// // DECLARE
// //     v_sla_settings record;
// //     v_deadline timestamp with time zone;
// //     v_sla_hours integer;
// // BEGIN
// //     -- Get firm SLA settings
// //     SELECT * INTO v_sla_settings
// //     FROM public.firm_sla_settings
// //     WHERE firm_id = p_firm_id AND is_active = true;
// //     
// //     -- If no settings found, use defaults
// //     IF v_sla_settings IS NULL THEN
// //         v_sla_hours := COALESCE(p_sla_override_hours, 48);
// //     ELSE
// //         -- Determine SLA hours based on priority
// //         IF p_sla_override_hours IS NOT NULL THEN
// //             v_sla_hours := p_sla_override_hours;
// //         ELSIF p_priority_level = 3 THEN -- Emergency
// //             v_sla_hours := v_sla_settings.urgent_internal_delegation_hours;
// //         ELSIF p_priority_level = 2 THEN -- Urgent
// //             v_sla_hours := v_sla_settings.urgent_internal_delegation_hours;
// //         ELSE -- Normal
// //             v_sla_hours := v_sla_settings.default_internal_delegation_hours;
// //         END IF;
// //     END IF;
// //     
// //     -- Calculate base deadline
// //     v_deadline := p_start_time + (v_sla_hours || ' hours')::interval;
// //     
// //     -- Apply business rules if settings exist
// //     IF v_sla_settings IS NOT NULL THEN
// //         -- Skip weekends if configured
// //         IF NOT v_sla_settings.allow_weekend_deadlines THEN
// //             -- If deadline falls on weekend, move to next Monday
// //             WHILE EXTRACT(DOW FROM v_deadline) IN (0, 6) LOOP
// //                 v_deadline := v_deadline + interval '1 day';
// //             END LOOP;
// //         END IF;
// //         
// //         -- Adjust to business hours if configured
// //         IF v_sla_settings.business_hours_only THEN
// //             -- If deadline is before business hours, set to business start
// //             IF EXTRACT(HOUR FROM v_deadline) < v_sla_settings.business_start_hour THEN
// //                 v_deadline := date_trunc('day', v_deadline) + 
// //                              (v_sla_settings.business_start_hour || ' hours')::interval;
// //             -- If deadline is after business hours, move to next business day start
// //             ELSIF EXTRACT(HOUR FROM v_deadline) >= v_sla_settings.business_end_hour THEN
// //                 v_deadline := date_trunc('day', v_deadline) + interval '1 day' + 
// //                              (v_sla_settings.business_start_hour || ' hours')::interval;
// //             END IF;
// //         END IF;
// //     END IF;
// //     
// //     RETURN v_deadline;
// // END;
// // $$ LANGUAGE plpgsql;
// // 
// // -- Update offers trigger to use custom SLA calculation
// // CREATE OR REPLACE FUNCTION set_contextual_offer_deadline()
// // RETURNS TRIGGER AS $$
// // DECLARE
// //     v_firm_id uuid;
// // BEGIN
// //     -- Set response deadline based on allocation type
// //     IF NEW.response_deadline IS NULL THEN
// //         CASE NEW.allocation_type
// //             WHEN 'internal_delegation' THEN
// //                 -- Get firm_id from context or lawyer profile
// //                 SELECT firm_id INTO v_firm_id
// //                 FROM public.lawyers l
// //                 WHERE l.id = NEW.target_lawyer_id;
// //                 
// //                 -- Use custom SLA calculation
// //                 NEW.response_deadline := calculate_delegation_deadline(
// //                     v_firm_id,
// //                     COALESCE(NEW.sla_priority_level, 1),
// //                     NEW.sla_hours_override,
// //                     NEW.created_at
// //                 );
// //             WHEN 'platform_match_direct' THEN
// //                 -- SLA fixo de 24 horas para match direto da plataforma
// //                 NEW.response_deadline = NEW.created_at + INTERVAL '24 hours';
// //             WHEN 'partnership_proactive_search' THEN
// //                 NEW.response_deadline = NEW.created_at + INTERVAL '72 hours';
// //             WHEN 'partnership_platform_suggestion' THEN
// //                 NEW.response_deadline = NEW.created_at + INTERVAL '48 hours';
// //             ELSE
// //                 NEW.response_deadline = NEW.created_at + INTERVAL '24 hours';
// //         END CASE;
// //     END IF;
// //     
// //     RETURN NEW;
// // END;
// // $$ LANGUAGE plpgsql;
// // 
// // -- Replace existing trigger
// // DROP TRIGGER IF EXISTS trigger_set_contextual_fields ON public.offers;
// // CREATE TRIGGER trigger_set_contextual_fields
// //     BEFORE INSERT OR UPDATE ON public.offers
// //     FOR EACH ROW
// //     EXECUTE FUNCTION set_contextual_offer_deadline(); 
// // -- Date: 2025-01-31
// // -- Purpose: Allow law firms to customize SLA timeouts for internal delegations
// // 
// // -- Create SLA settings table
// // CREATE TABLE IF NOT EXISTS public.firm_sla_settings (
// //     id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
// //     firm_id uuid REFERENCES public.firms(id) ON DELETE CASCADE,
// //     created_at timestamp with time zone DEFAULT NOW(),
// //     updated_at timestamp with time zone DEFAULT NOW(),
// //     
// //     -- SLA configurations for different scenarios
// //     default_internal_delegation_hours integer DEFAULT 48 CHECK (default_internal_delegation_hours >= 1 AND default_internal_delegation_hours <= 720), -- Max 30 days
// //     urgent_internal_delegation_hours integer DEFAULT 24 CHECK (urgent_internal_delegation_hours >= 1 AND urgent_internal_delegation_hours <= 168), -- Max 7 days
// //     complex_case_delegation_hours integer DEFAULT 72 CHECK (complex_case_delegation_hours >= 1 AND complex_case_delegation_hours <= 720), -- Max 30 days
// //     
// //     -- Notification settings
// //     notify_before_deadline_hours integer DEFAULT 4 CHECK (notify_before_deadline_hours >= 1 AND notify_before_deadline_hours <= 48),
// //     escalate_after_deadline_hours integer DEFAULT 2 CHECK (escalate_after_deadline_hours >= 0 AND escalate_after_deadline_hours <= 24),
// //     
// //     -- Business rules
// //     allow_weekend_deadlines boolean DEFAULT false,
// //     business_hours_only boolean DEFAULT false,
// //     business_start_hour integer DEFAULT 9 CHECK (business_start_hour >= 0 AND business_start_hour <= 23),
// //     business_end_hour integer DEFAULT 18 CHECK (business_end_hour >= 1 AND business_end_hour <= 23),
// //     
// //     -- Metadata
// //     settings_metadata jsonb DEFAULT '{}',
// //     is_active boolean DEFAULT true,
// //     
// //     -- Ensure one settings per firm
// //     CONSTRAINT unique_firm_sla_settings UNIQUE (firm_id)
// // );
// // 
// // -- Create indexes
// // CREATE INDEX IF NOT EXISTS idx_firm_sla_settings_firm_id ON public.firm_sla_settings(firm_id);
// // CREATE INDEX IF NOT EXISTS idx_firm_sla_settings_active ON public.firm_sla_settings(is_active);
// // 
// // -- Create function to update updated_at
// // CREATE OR REPLACE FUNCTION update_firm_sla_settings_updated_at()
// // RETURNS TRIGGER AS $$
// // BEGIN
// //     NEW.updated_at = NOW();
// //     RETURN NEW;
// // END;
// // $$ LANGUAGE plpgsql;
// // 
// // -- Create trigger
// // CREATE TRIGGER trigger_update_firm_sla_settings_updated_at
// //     BEFORE UPDATE ON public.firm_sla_settings
// //     FOR EACH ROW
// //     EXECUTE FUNCTION update_firm_sla_settings_updated_at();
// // 
// // -- Add RLS policies
// // ALTER TABLE public.firm_sla_settings ENABLE ROW LEVEL SECURITY;
// // 
// // -- Policy: Firm owners and associates can view/manage their firm's SLA settings
// // CREATE POLICY "Firm members can manage SLA settings" ON public.firm_sla_settings
// //     FOR ALL USING (
// //         EXISTS (
// //             SELECT 1 FROM public.firm_lawyers fl
// //             WHERE fl.firm_id = firm_sla_settings.firm_id
// //             AND fl.lawyer_id = auth.uid()
// //             AND fl.role IN ('owner', 'partner', 'admin')
// //             AND fl.is_active = true
// //         )
// //     );
// // 
// // -- Policy: Associates can view SLA settings (read-only)
// // CREATE POLICY "Firm associates can view SLA settings" ON public.firm_sla_settings
// //     FOR SELECT USING (
// //         EXISTS (
// //             SELECT 1 FROM public.firm_lawyers fl
// //             WHERE fl.firm_id = firm_sla_settings.firm_id
// //             AND fl.lawyer_id = auth.uid()
// //             AND fl.is_active = true
// //         )
// //     );
// // 
// // -- Create default SLA settings for existing firms
// // INSERT INTO public.firm_sla_settings (firm_id)
// // SELECT f.id
// // FROM public.firms f
// // WHERE NOT EXISTS (
// //     SELECT 1 FROM public.firm_sla_settings sla
// //     WHERE sla.firm_id = f.id
// // )
// // ON CONFLICT (firm_id) DO NOTHING;
// // 
// // -- Add SLA override fields to offers table
// // ALTER TABLE public.offers ADD COLUMN IF NOT EXISTS sla_hours_override integer;
// // ALTER TABLE public.offers ADD COLUMN IF NOT EXISTS sla_priority_level integer DEFAULT 1 CHECK (sla_priority_level >= 1 AND sla_priority_level <= 3);
// // 
// // -- Add comments for documentation
// // COMMENT ON TABLE public.firm_sla_settings IS 'SLA configuration settings for law firms internal delegations';
// // COMMENT ON COLUMN public.firm_sla_settings.default_internal_delegation_hours IS 'Default SLA hours for internal delegations';
// // COMMENT ON COLUMN public.firm_sla_settings.urgent_internal_delegation_hours IS 'SLA hours for urgent internal delegations';
// // COMMENT ON COLUMN public.firm_sla_settings.complex_case_delegation_hours IS 'SLA hours for complex case delegations';
// // COMMENT ON COLUMN public.offers.sla_hours_override IS 'Override SLA hours for this specific offer';
// // COMMENT ON COLUMN public.offers.sla_priority_level IS 'Priority level: 1=normal, 2=urgent, 3=emergency';
// // 
// // -- Create function to calculate deadline with business rules
// // CREATE OR REPLACE FUNCTION calculate_delegation_deadline(
// //     p_firm_id uuid,
// //     p_priority_level integer DEFAULT 1,
// //     p_sla_override_hours integer DEFAULT NULL,
// //     p_start_time timestamp with time zone DEFAULT NOW()
// // ) RETURNS timestamp with time zone AS $$
// // DECLARE
// //     v_sla_settings record;
// //     v_deadline timestamp with time zone;
// //     v_sla_hours integer;
// // BEGIN
// //     -- Get firm SLA settings
// //     SELECT * INTO v_sla_settings
// //     FROM public.firm_sla_settings
// //     WHERE firm_id = p_firm_id AND is_active = true;
// //     
// //     -- If no settings found, use defaults
// //     IF v_sla_settings IS NULL THEN
// //         v_sla_hours := COALESCE(p_sla_override_hours, 48);
// //     ELSE
// //         -- Determine SLA hours based on priority
// //         IF p_sla_override_hours IS NOT NULL THEN
// //             v_sla_hours := p_sla_override_hours;
// //         ELSIF p_priority_level = 3 THEN -- Emergency
// //             v_sla_hours := v_sla_settings.urgent_internal_delegation_hours;
// //         ELSIF p_priority_level = 2 THEN -- Urgent
// //             v_sla_hours := v_sla_settings.urgent_internal_delegation_hours;
// //         ELSE -- Normal
// //             v_sla_hours := v_sla_settings.default_internal_delegation_hours;
// //         END IF;
// //     END IF;
// //     
// //     -- Calculate base deadline
// //     v_deadline := p_start_time + (v_sla_hours || ' hours')::interval;
// //     
// //     -- Apply business rules if settings exist
// //     IF v_sla_settings IS NOT NULL THEN
// //         -- Skip weekends if configured
// //         IF NOT v_sla_settings.allow_weekend_deadlines THEN
// //             -- If deadline falls on weekend, move to next Monday
// //             WHILE EXTRACT(DOW FROM v_deadline) IN (0, 6) LOOP
// //                 v_deadline := v_deadline + interval '1 day';
// //             END LOOP;
// //         END IF;
// //         
// //         -- Adjust to business hours if configured
// //         IF v_sla_settings.business_hours_only THEN
// //             -- If deadline is before business hours, set to business start
// //             IF EXTRACT(HOUR FROM v_deadline) < v_sla_settings.business_start_hour THEN
// //                 v_deadline := date_trunc('day', v_deadline) + 
// //                              (v_sla_settings.business_start_hour || ' hours')::interval;
// //             -- If deadline is after business hours, move to next business day start
// //             ELSIF EXTRACT(HOUR FROM v_deadline) >= v_sla_settings.business_end_hour THEN
// //                 v_deadline := date_trunc('day', v_deadline) + interval '1 day' + 
// //                              (v_sla_settings.business_start_hour || ' hours')::interval;
// //             END IF;
// //         END IF;
// //     END IF;
// //     
// //     RETURN v_deadline;
// // END;
// // $$ LANGUAGE plpgsql;
// // 
// // -- Update offers trigger to use custom SLA calculation
// // CREATE OR REPLACE FUNCTION set_contextual_offer_deadline()
// // RETURNS TRIGGER AS $$
// // DECLARE
// //     v_firm_id uuid;
// // BEGIN
// //     -- Set response deadline based on allocation type
// //     IF NEW.response_deadline IS NULL THEN
// //         CASE NEW.allocation_type
// //             WHEN 'internal_delegation' THEN
// //                 -- Get firm_id from context or lawyer profile
// //                 SELECT firm_id INTO v_firm_id
// //                 FROM public.lawyers l
// //                 WHERE l.id = NEW.target_lawyer_id;
// //                 
// //                 -- Use custom SLA calculation
// //                 NEW.response_deadline := calculate_delegation_deadline(
// //                     v_firm_id,
// //                     COALESCE(NEW.sla_priority_level, 1),
// //                     NEW.sla_hours_override,
// //                     NEW.created_at
// //                 );
// //             WHEN 'platform_match_direct' THEN
// //                 -- SLA fixo de 24 horas para match direto da plataforma
// //                 NEW.response_deadline = NEW.created_at + INTERVAL '24 hours';
// //             WHEN 'partnership_proactive_search' THEN
// //                 NEW.response_deadline = NEW.created_at + INTERVAL '72 hours';
// //             WHEN 'partnership_platform_suggestion' THEN
// //                 NEW.response_deadline = NEW.created_at + INTERVAL '48 hours';
// //             ELSE
// //                 NEW.response_deadline = NEW.created_at + INTERVAL '24 hours';
// //         END CASE;
// //     END IF;
// //     
// //     RETURN NEW;
// // END;
// // $$ LANGUAGE plpgsql;
// // 
// // -- Replace existing trigger
// // DROP TRIGGER IF EXISTS trigger_set_contextual_fields ON public.offers;
// // CREATE TRIGGER trigger_set_contextual_fields
// //     BEFORE INSERT OR UPDATE ON public.offers
// //     FOR EACH ROW
// //     EXECUTE FUNCTION set_contextual_offer_deadline(); 