-- Location: supabase/migrations/20250306190000_update_initial_tokens_to_30.sql
-- Update initial token count from 50 to 30 (= 3 free products)

-- Update default for new users
ALTER TABLE public.user_profiles
  ALTER COLUMN tokens SET DEFAULT 30;

-- Update existing users who still have exactly 50 tokens (initial grant) to 30
-- Only update users who haven't purchased tokens (still at the default 50)
UPDATE public.user_profiles 
SET tokens = 30 
WHERE tokens = 50;
