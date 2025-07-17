-- Migration: Add contextual fields to offers table
-- Date: 2025-01-31
-- Purpose: Support contextual offers based on allocation types

-- Add contextual fields to offers table
ALTER TABLE offers ADD COLUMN IF NOT EXISTS allocation_type allocation_type;
ALTER TABLE offers ADD COLUMN IF NOT EXISTS context_metadata JSONB DEFAULT '{}';
ALTER TABLE offers ADD COLUMN IF NOT EXISTS priority_level INTEGER DEFAULT 1 CHECK (priority_level >= 1 AND priority_level <= 5);
ALTER TABLE offers ADD COLUMN IF NOT EXISTS response_deadline TIMESTAMPTZ;
ALTER TABLE offers ADD COLUMN IF NOT EXISTS delegation_details JSONB DEFAULT '{}';
ALTER TABLE offers ADD COLUMN IF NOT EXISTS partnership_details JSONB DEFAULT '{}';
ALTER TABLE offers ADD COLUMN IF NOT EXISTS match_details JSONB DEFAULT '{}';

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_offers_allocation_type ON offers(allocation_type);
CREATE INDEX IF NOT EXISTS idx_offers_priority_level ON offers(priority_level);
CREATE INDEX IF NOT EXISTS idx_offers_response_deadline ON offers(response_deadline);
CREATE INDEX IF NOT EXISTS idx_offers_context_metadata ON offers USING GIN(context_metadata);

-- Add RLS policies for contextual offers
CREATE POLICY "Users can view contextual offers" ON offers
    FOR SELECT USING (
        -- Users can see their own offers
        target_lawyer_id = auth.uid() OR
        -- Or offers where they are involved in the context
        (
            allocation_type = 'internal_delegation' AND
            (context_metadata->>'delegated_by')::uuid = auth.uid()
        ) OR
        (
            allocation_type IN ('partnership_proactive_search', 'partnership_platform_suggestion') AND
            (context_metadata->>'partner_id')::uuid = auth.uid()
        )
    );

-- Create ENUM type for allocation types
DO $$ BEGIN
    CREATE TYPE allocation_type AS ENUM (
        'internal_delegation',
        'platform_match_direct', 
        'partnership_proactive_search',
        'partnership_platform_suggestion',
        'client_direct_choice'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Function to automatically set context metadata and deadlines
CREATE OR REPLACE FUNCTION set_offer_context_metadata()
RETURNS TRIGGER AS $$
BEGIN
    -- Set context metadata based on allocation type
    CASE NEW.allocation_type
        WHEN 'internal_delegation' THEN
            NEW.context_metadata = jsonb_build_object(
                'delegation_type', 'internal',
                'delegated_by', COALESCE(NEW.delegation_details->>'delegated_by', ''),
                'delegation_reason', COALESCE(NEW.delegation_details->>'reason', ''),
                'priority_override', COALESCE(NEW.delegation_details->>'priority_override', false)
            );
        WHEN 'partnership_proactive_search' THEN
            NEW.context_metadata = jsonb_build_object(
                'partnership_type', 'proactive_search',
                'partner_id', COALESCE(NEW.partnership_details->>'partner_id', ''),
                'search_criteria', COALESCE(NEW.partnership_details->>'criteria', '{}'),
                'expected_collaboration', COALESCE(NEW.partnership_details->>'collaboration_type', '')
            );
        WHEN 'partnership_platform_suggestion' THEN
            NEW.context_metadata = jsonb_build_object(
                'partnership_type', 'ai_suggested',
                'match_score', COALESCE(NEW.match_details->>'score', 0),
                'suggestion_reason', COALESCE(NEW.match_details->>'reason', ''),
                'confidence_level', COALESCE(NEW.match_details->>'confidence', 0)
            );
        WHEN 'platform_match_direct' THEN
            NEW.context_metadata = jsonb_build_object(
                'match_type', 'direct',
                'algorithm_version', COALESCE(NEW.match_details->>'algorithm_version', '2.7'),
                'match_score', COALESCE(NEW.match_details->>'score', 0),
                'factors', COALESCE(NEW.match_details->>'factors', '{}')
            );
        ELSE
            NEW.context_metadata = COALESCE(NEW.context_metadata, '{}');
    END CASE;

    -- Set response deadline to standardized 24 hours for all allocation types
    IF NEW.response_deadline IS NULL THEN
        -- UNIFORMIZED TO 24 HOURS FOR ALL TYPES
        NEW.response_deadline = NOW() + INTERVAL '24 hours';
    END IF;

    -- Set priority level based on allocation type and case urgency
    IF NEW.priority_level = 1 THEN
        CASE NEW.allocation_type
            WHEN 'platform_match_direct' THEN
                NEW.priority_level = 5; -- Highest priority
            WHEN 'internal_delegation' THEN
                NEW.priority_level = 4;
            WHEN 'partnership_platform_suggestion' THEN
                NEW.priority_level = 3;
            WHEN 'partnership_proactive_search' THEN
                NEW.priority_level = 2;
            ELSE
                NEW.priority_level = 1;
        END CASE;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically set context metadata
CREATE TRIGGER set_offer_context_metadata_trigger
    BEFORE INSERT OR UPDATE ON offers
    FOR EACH ROW
    EXECUTE FUNCTION set_offer_context_metadata();

-- Create view for contextual offers analytics
CREATE OR REPLACE VIEW contextual_offers_analytics AS
SELECT 
    allocation_type,
    COUNT(*) as total_offers,
    COUNT(CASE WHEN status = 'accepted' THEN 1 END) as accepted_offers,
    COUNT(CASE WHEN status = 'declined' THEN 1 END) as declined_offers,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_offers,
    AVG(CASE WHEN status = 'accepted' THEN 
        EXTRACT(EPOCH FROM (updated_at - created_at))/3600 
    END) as avg_acceptance_time_hours,
    AVG(priority_level) as avg_priority_level,
    COUNT(CASE WHEN response_deadline < NOW() AND status = 'pending' THEN 1 END) as expired_offers
FROM offers 
WHERE allocation_type IS NOT NULL
GROUP BY allocation_type;

-- Create function to get contextual offer insights
CREATE OR REPLACE FUNCTION get_contextual_offer_insights(
    p_user_id UUID,
    p_allocation_type allocation_type DEFAULT NULL,
    p_days_back INTEGER DEFAULT 30
)
RETURNS TABLE (
    allocation_type allocation_type,
    total_offers BIGINT,
    acceptance_rate NUMERIC,
    avg_response_time_hours NUMERIC,
    priority_distribution JSONB,
    top_rejection_reasons JSONB,
    performance_trend JSONB
) AS $$
BEGIN
    RETURN QUERY
    WITH offer_stats AS (
        SELECT 
            o.allocation_type,
            COUNT(*) as total,
            COUNT(CASE WHEN o.status = 'accepted' THEN 1 END) as accepted,
            AVG(CASE WHEN o.status = 'accepted' THEN 
                EXTRACT(EPOCH FROM (o.updated_at - o.created_at))/3600 
            END) as avg_response_hours,
            jsonb_object_agg(o.priority_level, COUNT(*)) as priority_dist
        FROM offers o
        WHERE o.target_lawyer_id = p_user_id
            AND o.created_at >= NOW() - INTERVAL '1 day' * p_days_back
            AND (p_allocation_type IS NULL OR o.allocation_type = p_allocation_type)
        GROUP BY o.allocation_type
    ),
    rejection_reasons AS (
        SELECT 
            o.allocation_type,
            jsonb_object_agg(
                COALESCE(o.context_metadata->>'rejection_reason', 'No reason provided'),
                COUNT(*)
            ) as reasons
        FROM offers o
        WHERE o.target_lawyer_id = p_user_id
            AND o.status = 'declined'
            AND o.created_at >= NOW() - INTERVAL '1 day' * p_days_back
            AND (p_allocation_type IS NULL OR o.allocation_type = p_allocation_type)
        GROUP BY o.allocation_type
    ),
    trend_data AS (
        SELECT 
            o.allocation_type,
            jsonb_object_agg(
                TO_CHAR(DATE_TRUNC('day', o.created_at), 'YYYY-MM-DD'),
                COUNT(*)
            ) as daily_counts
        FROM offers o
        WHERE o.target_lawyer_id = p_user_id
            AND o.created_at >= NOW() - INTERVAL '1 day' * p_days_back
            AND (p_allocation_type IS NULL OR o.allocation_type = p_allocation_type)
        GROUP BY o.allocation_type
    )
    SELECT 
        os.allocation_type,
        os.total,
        CASE WHEN os.total > 0 THEN ROUND((os.accepted::NUMERIC / os.total) * 100, 2) ELSE 0 END,
        ROUND(os.avg_response_hours, 2),
        os.priority_dist,
        COALESCE(rr.reasons, '{}'::jsonb),
        COALESCE(td.daily_counts, '{}'::jsonb)
    FROM offer_stats os
    LEFT JOIN rejection_reasons rr ON os.allocation_type = rr.allocation_type
    LEFT JOIN trend_data td ON os.allocation_type = td.allocation_type;
END;
$$ LANGUAGE plpgsql;

-- Create function to get contextual offer recommendations
CREATE OR REPLACE FUNCTION get_contextual_offer_recommendations(
    p_user_id UUID
)
RETURNS TABLE (
    recommendation_type TEXT,
    message TEXT,
    priority INTEGER,
    action_required BOOLEAN
) AS $$
DECLARE
    user_stats RECORD;
BEGIN
    -- Get user statistics for the last 30 days
    SELECT 
        COUNT(*) as total_offers,
        COUNT(CASE WHEN status = 'accepted' THEN 1 END) as accepted_offers,
        COUNT(CASE WHEN status = 'declined' THEN 1 END) as declined_offers,
        COUNT(CASE WHEN response_deadline < NOW() AND status = 'pending' THEN 1 END) as expired_offers,
        AVG(CASE WHEN status = 'accepted' THEN 
            EXTRACT(EPOCH FROM (updated_at - created_at))/3600 
        END) as avg_response_time
    INTO user_stats
    FROM offers 
    WHERE target_lawyer_id = p_user_id 
        AND created_at >= NOW() - INTERVAL '30 days';

    -- Generate recommendations based on statistics
    RETURN QUERY
    SELECT 
        CASE 
            WHEN us.expired_offers > 0 THEN 'expired_offers'
            WHEN us.total_offers > 0 AND (us.accepted_offers::NUMERIC / us.total_offers) < 0.5 THEN 'low_acceptance_rate'
            WHEN us.avg_response_time > 24 THEN 'slow_response'
            ELSE 'performance_good'
        END,
        CASE 
            WHEN us.expired_offers > 0 THEN 'Você tem ofertas expiradas. Configure notificações para não perder oportunidades.'
            WHEN us.total_offers > 0 AND (us.accepted_offers::NUMERIC / us.total_offers) < 0.5 THEN 'Sua taxa de aceitação está baixa. Considere revisar os critérios de casos.'
            WHEN us.avg_response_time > 24 THEN 'Você está demorando para responder ofertas. Tempo médio ideal: dentro de 24 horas.'
            ELSE 'Sua performance está boa! Continue assim.'
        END,
        CASE 
            WHEN us.expired_offers > 0 THEN 5
            WHEN us.total_offers > 0 AND (us.accepted_offers::NUMERIC / us.total_offers) < 0.5 THEN 4
            WHEN us.avg_response_time > 24 THEN 3
            ELSE 1
        END,
        CASE 
            WHEN us.expired_offers > 0 THEN true
            WHEN us.total_offers > 0 AND (us.accepted_offers::NUMERIC / us.total_offers) < 0.5 THEN true
            WHEN us.avg_response_time > 24 THEN true
            ELSE false
        END
    FROM user_stats us;
END;
$$ LANGUAGE plpgsql;

-- Comments for documentation
COMMENT ON COLUMN offers.allocation_type IS 'Type of case allocation that generated this offer';
COMMENT ON COLUMN offers.context_metadata IS 'Contextual information specific to the allocation type';
COMMENT ON COLUMN offers.priority_level IS 'Priority level from 1 (lowest) to 5 (highest)';
COMMENT ON COLUMN offers.response_deadline IS 'Deadline for lawyer to respond to this offer - STANDARDIZED TO 24 HOURS';
COMMENT ON COLUMN offers.delegation_details IS 'Details specific to internal delegation offers';
COMMENT ON COLUMN offers.partnership_details IS 'Details specific to partnership offers';
COMMENT ON COLUMN offers.match_details IS 'Details specific to algorithmic match offers'; 