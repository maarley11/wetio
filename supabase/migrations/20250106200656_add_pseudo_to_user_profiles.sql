-- ============================================
-- Migration: Add Pseudo to User Profiles
-- Description: Add username field for privacy protection
-- Dependencies: user_profiles table exists
-- ============================================

-- 1. ADD PSEUDO COLUMN
ALTER TABLE public.user_profiles 
ADD COLUMN pseudo TEXT;

-- 2. ADD INDEX FOR PERFORMANCE
CREATE INDEX idx_user_profiles_pseudo ON public.user_profiles(pseudo);

-- 3. ADD UNIQUE CONSTRAINT FOR PSEUDO
ALTER TABLE public.user_profiles 
ADD CONSTRAINT unique_pseudo UNIQUE (pseudo);

-- 4. UPDATE TRIGGER FUNCTION TO HANDLE PSEUDO
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, full_name, pseudo, role)
  VALUES (
    NEW.id, 
    NEW.email, 
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'pseudo', ''),
    COALESCE(NEW.raw_user_meta_data->>'role', 'user')::public.user_role
  );
  RETURN NEW;
END;
$$;

-- 5. UPDATE EXISTING USERS WITH DEFAULT PSEUDO
DO $$
DECLARE
    user_record RECORD;
    base_pseudo TEXT;
    counter INTEGER;
    final_pseudo TEXT;
BEGIN
    -- Update existing users without pseudo
    FOR user_record IN 
        SELECT id, email, full_name FROM public.user_profiles WHERE pseudo IS NULL OR pseudo = ''
    LOOP
        -- Generate base pseudo from full_name or email
        IF user_record.full_name IS NOT NULL AND user_record.full_name != '' THEN
            base_pseudo := LOWER(TRIM(split_part(user_record.full_name, ' ', 1)));
        ELSE
            base_pseudo := LOWER(split_part(user_record.email, '@', 1));
        END IF;
        
        -- Remove special characters and ensure it's not empty
        base_pseudo := REGEXP_REPLACE(base_pseudo, '[^a-z0-9]', '', 'g');
        IF LENGTH(base_pseudo) < 3 THEN
            base_pseudo := 'user' || SUBSTRING(user_record.id::TEXT, 1, 4);
        END IF;
        
        -- Check if pseudo already exists and add counter if needed
        counter := 0;
        final_pseudo := base_pseudo;
        
        WHILE EXISTS (SELECT 1 FROM public.user_profiles WHERE pseudo = final_pseudo) LOOP
            counter := counter + 1;
            final_pseudo := base_pseudo || counter::TEXT;
        END LOOP;
        
        -- Update user with unique pseudo
        UPDATE public.user_profiles 
        SET pseudo = final_pseudo, updated_at = NOW()
        WHERE id = user_record.id;
        
        RAISE NOTICE 'Updated user % with pseudo %', user_record.email, final_pseudo;
    END LOOP;
    
    RAISE NOTICE 'All existing users updated with unique pseudos';
END $$;