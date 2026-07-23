-- ==================================================
-- Migration: Fix Phone Authentication System
-- Description: Update handle_new_user trigger to properly store phone numbers
-- ==================================================

-- Drop existing trigger and function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Create improved handle_new_user function that includes phone data
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.user_profiles (
    id, 
    email, 
    full_name, 
    pseudo, 
    phone, 
    location, 
    role
  )
  VALUES (
    NEW.id, 
    NEW.email, 
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'pseudo', ''),
    COALESCE(NEW.raw_user_meta_data->>'phone', ''),
    COALESCE(NEW.raw_user_meta_data->>'location', ''),
    COALESCE(NEW.raw_user_meta_data->>'role', 'user')::public.user_role
  );
  RETURN NEW;
END;
$$;

-- Recreate trigger on auth.users table
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Add index on phone column for better performance during phone lookups
CREATE INDEX IF NOT EXISTS idx_user_profiles_phone ON public.user_profiles(phone) 
WHERE phone IS NOT NULL AND phone != '';

-- Update any existing users who have phone data in metadata but not in profile
UPDATE public.user_profiles
SET phone = auth_users.raw_user_meta_data->>'phone',
    location = COALESCE(auth_users.raw_user_meta_data->>'location', location)
FROM auth.users AS auth_users
WHERE user_profiles.id = auth_users.id 
  AND auth_users.raw_user_meta_data->>'phone' IS NOT NULL 
  AND auth_users.raw_user_meta_data->>'phone' != ''
  AND (user_profiles.phone IS NULL OR user_profiles.phone = '');

-- Ensure RLS policies are enabled
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Add comment for documentation
COMMENT ON FUNCTION public.handle_new_user() IS 'Trigger function that creates user profile with complete metadata including phone number when new user is created in auth.users';
COMMENT ON INDEX idx_user_profiles_phone IS 'Index for efficient phone number lookups during authentication';