-- Migration: Add delivery partner flag to user_profiles
-- Adds: is_delivery_partner column to user_profiles

ALTER TABLE public.user_profiles
ADD COLUMN IF NOT EXISTS is_delivery_partner BOOLEAN DEFAULT false;

-- Index for searching delivery partners
CREATE INDEX IF NOT EXISTS idx_user_profiles_is_delivery_partner ON public.user_profiles(is_delivery_partner) WHERE is_delivery_partner = true;
