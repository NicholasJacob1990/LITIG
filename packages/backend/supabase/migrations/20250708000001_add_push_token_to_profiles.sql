-- Migration: Add expo_push_token to profiles
-- Timestamp: 20250708000000

ALTER TABLE public.profiles
ADD COLUMN expo_push_token TEXT;

COMMENT ON COLUMN public.profiles.expo_push_token IS 'The unique Expo push token for the user device, used for sending notifications.'; 