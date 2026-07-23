-- Exchange Delivery Coordination Migration
-- Adds tables for 2-way exchange delivery with confirmation codes and ratings

-- Add columns to delivery_requests for exchange coordination
ALTER TABLE public.delivery_requests
  ADD COLUMN IF NOT EXISTS exchange_type TEXT DEFAULT 'simple',
  ADD COLUMN IF NOT EXISTS person_a_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS person_b_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS person_a_address TEXT,
  ADD COLUMN IF NOT EXISTS person_b_address TEXT,
  ADD COLUMN IF NOT EXISTS person_a_product TEXT,
  ADD COLUMN IF NOT EXISTS person_b_product TEXT,
  ADD COLUMN IF NOT EXISTS person_a_lat DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS person_a_lng DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS person_b_lat DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS person_b_lng DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS distance_km DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS current_step INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_price_fcfa INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS person_b_accepted BOOLEAN DEFAULT false;

-- Confirmation codes table
CREATE TABLE IF NOT EXISTS public.delivery_confirmation_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  delivery_request_id UUID REFERENCES public.delivery_requests(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  code TEXT NOT NULL,
  step INTEGER NOT NULL,
  is_used BOOLEAN DEFAULT false,
  used_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_confirmation_codes_delivery ON public.delivery_confirmation_codes(delivery_request_id);
CREATE INDEX IF NOT EXISTS idx_confirmation_codes_user ON public.delivery_confirmation_codes(user_id);

-- Add rating columns to delivery_persons for average rating
ALTER TABLE public.delivery_persons
  ADD COLUMN IF NOT EXISTS average_rating DOUBLE PRECISION DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_ratings INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS base_price_fcfa INTEGER DEFAULT 2000,
  ADD COLUMN IF NOT EXISTS current_lat DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS current_lng DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS full_name TEXT,
  ADD COLUMN IF NOT EXISTS phone TEXT,
  ADD COLUMN IF NOT EXISTS profile_image TEXT;

-- Add profile_image to user_profiles if needed
ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

-- Enable RLS
ALTER TABLE public.delivery_confirmation_codes ENABLE ROW LEVEL SECURITY;

-- RLS Policies for confirmation codes
DROP POLICY IF EXISTS "users_view_own_codes" ON public.delivery_confirmation_codes;
CREATE POLICY "users_view_own_codes"
  ON public.delivery_confirmation_codes
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "users_insert_own_codes" ON public.delivery_confirmation_codes;
CREATE POLICY "users_insert_own_codes"
  ON public.delivery_confirmation_codes
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_update_own_codes" ON public.delivery_confirmation_codes;
CREATE POLICY "users_update_own_codes"
  ON public.delivery_confirmation_codes
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Function to update delivery person average rating
CREATE OR REPLACE FUNCTION public.update_delivery_person_rating()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.delivery_persons
  SET 
    average_rating = (
      SELECT COALESCE(AVG(rating::DOUBLE PRECISION), 0)
      FROM public.delivery_ratings
      WHERE delivery_person_id = NEW.delivery_person_id
    ),
    total_ratings = (
      SELECT COUNT(*)
      FROM public.delivery_ratings
      WHERE delivery_person_id = NEW.delivery_person_id
    )
  WHERE id = NEW.delivery_person_id;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS update_rating_after_insert ON public.delivery_ratings;
CREATE TRIGGER update_rating_after_insert
  AFTER INSERT ON public.delivery_ratings
  FOR EACH ROW
  EXECUTE FUNCTION public.update_delivery_person_rating();
