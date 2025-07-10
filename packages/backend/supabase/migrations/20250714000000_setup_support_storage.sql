-- Migration: Criação do bucket de anexos no Supabase Storage
-- Timestamp: 20250714000000
 
INSERT INTO storage.buckets (id, name, public)
VALUES ('support_attachments', 'support_attachments', false)
ON CONFLICT (id) DO NOTHING; 