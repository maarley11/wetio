-- Migration: Fix delivery_requests schema
-- Ensures all required columns exist for the real-time delivery system

ALTER TABLE public.delivery_requests
ADD COLUMN IF NOT EXISTS exchange_id UUID REFERENCES public.exchanges(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS initiator_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS pickup_address TEXT,
ADD COLUMN IF NOT EXISTS delivery_address TEXT,
ADD COLUMN IF NOT EXISTS pickup_lat DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS pickup_lng DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS delivery_lat DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS delivery_lng DOUBLE PRECISION;

-- Also ensure the partner_user_id exists and is indexed
ALTER TABLE public.delivery_requests
ADD COLUMN IF NOT EXISTS partner_user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_delivery_requests_partner_user_id ON public.delivery_requests(partner_user_id);
CREATE INDEX IF NOT EXISTS idx_delivery_requests_exchange_id ON public.delivery_requests(exchange_id);
