-- Update initial token grant from 50 to 30 for new users
-- This migration updates the default token value and any trigger that grants initial tokens

-- Update default value for tokens column if it exists
DO $$
BEGIN
  -- Update the default tokens for new user profiles from 50 to 30
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'user_profiles' 
    AND column_name = 'tokens'
  ) THEN
    ALTER TABLE public.user_profiles 
    ALTER COLUMN tokens SET DEFAULT 30;
  END IF;
END $$;

-- Update any existing function that sets initial tokens to 50
CREATE OR REPLACE FUNCTION public.handle_new_user_tokens()
RETURNS TRIGGER AS $$
BEGIN
  -- Grant 30 initial tokens (= 3 free products) to new users
  UPDATE public.user_profiles
  SET tokens = 30
  WHERE id = NEW.id AND (tokens IS NULL OR tokens = 0 OR tokens = 50);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Log the migration
DO $$
BEGIN
  RAISE NOTICE 'Updated initial token grant from 50 to 30 tokens (3 free products)';
END $$;
