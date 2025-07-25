-- Migration: Create partnership feedback table for ML training
-- This table stores user feedback on partnership recommendations for machine learning

CREATE TABLE IF NOT EXISTS partnership_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    lawyer_id UUID NOT NULL REFERENCES lawyers(id),
    recommended_lawyer_id UUID NOT NULL REFERENCES lawyers(id),
    feedback_type VARCHAR(20) NOT NULL CHECK (feedback_type IN ('accepted', 'rejected', 'contacted', 'dismissed')),
    feedback_score FLOAT NOT NULL CHECK (feedback_score >= 0.0 AND feedback_score <= 1.0),
    interaction_time_seconds INTEGER,
    feedback_notes TEXT,
    timestamp TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_partnership_feedback_lawyer_id ON partnership_feedback(lawyer_id);
CREATE INDEX idx_partnership_feedback_recommended_id ON partnership_feedback(recommended_lawyer_id);
CREATE INDEX idx_partnership_feedback_timestamp ON partnership_feedback(timestamp);
CREATE INDEX idx_partnership_feedback_type ON partnership_feedback(feedback_type);
CREATE INDEX idx_partnership_feedback_user_id ON partnership_feedback(user_id);

-- Composite index for common queries
CREATE INDEX idx_partnership_feedback_lawyer_timestamp ON partnership_feedback(lawyer_id, timestamp);

-- Add comments for documentation
COMMENT ON TABLE partnership_feedback IS 'Stores user feedback on partnership recommendations for ML training';
COMMENT ON COLUMN partnership_feedback.feedback_type IS 'Type of feedback: accepted, rejected, contacted, dismissed';
COMMENT ON COLUMN partnership_feedback.feedback_score IS 'Relevance score from 0.0 to 1.0';
COMMENT ON COLUMN partnership_feedback.interaction_time_seconds IS 'Time spent viewing the recommendation'; 