-- Location: supabase/migrations/20250109183616_add_tokens_system.sql
-- Schema Analysis: token_transactions and payment_transactions tables exist, user_profiles missing tokens column
-- Integration Type: extension/enhancement 
-- Dependencies: user_profiles, token_transactions, payment_transactions tables

-- 1. Add tokens column to user_profiles table
ALTER TABLE public.user_profiles 
ADD COLUMN tokens INTEGER DEFAULT 50 NOT NULL;

-- 2. Create index for tokens column
CREATE INDEX idx_user_profiles_tokens ON public.user_profiles(tokens);

-- 3. Update existing users to have 50 tokens (if any exist without tokens)
UPDATE public.user_profiles SET tokens = 50 WHERE tokens IS NULL;

-- 4. Create function to get user current token balance
CREATE OR REPLACE FUNCTION public.get_user_token_balance(user_uuid UUID)
RETURNS INTEGER
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT tokens FROM public.user_profiles 
WHERE id = user_uuid
$$;

-- 5. Create function to deduct tokens for product publication
CREATE OR REPLACE FUNCTION public.deduct_tokens_for_publication(
    user_uuid UUID,
    product_title TEXT,
    tokens_to_deduct INTEGER DEFAULT 10
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_balance INTEGER;
    new_balance INTEGER;
    transaction_id UUID;
BEGIN
    -- Get current token balance
    SELECT tokens INTO current_balance 
    FROM public.user_profiles 
    WHERE id = user_uuid;
    
    -- Check if user exists
    IF current_balance IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Utilisateur non trouvé',
            'error_code', 'USER_NOT_FOUND'
        );
    END IF;
    
    -- Check if user has enough tokens
    IF current_balance < tokens_to_deduct THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Jetons insuffisants. Vous avez ' || current_balance || ' jetons, mais ' || tokens_to_deduct || ' sont requis.',
            'error_code', 'INSUFFICIENT_TOKENS',
            'current_balance', current_balance,
            'required_tokens', tokens_to_deduct
        );
    END IF;
    
    -- Calculate new balance
    new_balance := current_balance - tokens_to_deduct;
    
    -- Update user tokens
    UPDATE public.user_profiles 
    SET tokens = new_balance, updated_at = CURRENT_TIMESTAMP
    WHERE id = user_uuid;
    
    -- Create transaction record
    INSERT INTO public.token_transactions (
        user_id,
        type,
        amount,
        description,
        reference_id,
        balance_after
    ) VALUES (
        user_uuid,
        'spent'::public.token_transaction_type,
        -tokens_to_deduct,
        'Publication du produit: ' || product_title,
        'PRODUCT_PUBLICATION_' || extract(epoch from now())::bigint,
        new_balance
    ) RETURNING id INTO transaction_id;
    
    RETURN jsonb_build_object(
        'success', true,
        'message', 'Jetons déduits avec succès',
        'tokens_deducted', tokens_to_deduct,
        'previous_balance', current_balance,
        'new_balance', new_balance,
        'transaction_id', transaction_id
    );
END;
$$;

-- 6. Create function to add tokens after successful payment
CREATE OR REPLACE FUNCTION public.add_tokens_after_payment(
    user_uuid UUID,
    tokens_to_add INTEGER,
    payment_reference TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_balance INTEGER;
    new_balance INTEGER;
    transaction_id UUID;
BEGIN
    -- Get current token balance
    SELECT tokens INTO current_balance 
    FROM public.user_profiles 
    WHERE id = user_uuid;
    
    -- Check if user exists
    IF current_balance IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Utilisateur non trouvé',
            'error_code', 'USER_NOT_FOUND'
        );
    END IF;
    
    -- Calculate new balance
    new_balance := current_balance + tokens_to_add;
    
    -- Update user tokens
    UPDATE public.user_profiles 
    SET tokens = new_balance, updated_at = CURRENT_TIMESTAMP
    WHERE id = user_uuid;
    
    -- Create transaction record
    INSERT INTO public.token_transactions (
        user_id,
        type,
        amount,
        description,
        reference_id,
        balance_after
    ) VALUES (
        user_uuid,
        'purchased'::public.token_transaction_type,
        tokens_to_add,
        'Achat de jetons: ' || tokens_to_add || ' jetons pour 1000 FCFA',
        payment_reference,
        new_balance
    ) RETURNING id INTO transaction_id;
    
    RETURN jsonb_build_object(
        'success', true,
        'message', 'Jetons ajoutés avec succès',
        'tokens_added', tokens_to_add,
        'previous_balance', current_balance,
        'new_balance', new_balance,
        'transaction_id', transaction_id
    );
END;
$$;

-- 7. Create function to get user token transaction history
CREATE OR REPLACE FUNCTION public.get_user_token_history(
    user_uuid UUID,
    limit_count INTEGER DEFAULT 20
)
RETURNS TABLE(
    id UUID,
    transaction_type TEXT,
    amount INTEGER,
    description TEXT,
    reference_id TEXT,
    balance_after INTEGER,
    created_at TIMESTAMPTZ
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT 
    tt.id,
    tt.type::TEXT as transaction_type,
    tt.amount,
    tt.description,
    tt.reference_id,
    tt.balance_after,
    tt.created_at
FROM public.token_transactions tt
WHERE tt.user_id = user_uuid
ORDER BY tt.created_at DESC
LIMIT limit_count;
$$;

-- 8. Create function to check if user can publish product
CREATE OR REPLACE FUNCTION public.can_user_publish_product(
    user_uuid UUID,
    required_tokens INTEGER DEFAULT 10
)
RETURNS JSONB
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT 
    CASE 
        WHEN up.tokens IS NULL THEN 
            jsonb_build_object(
                'can_publish', false,
                'message', 'Utilisateur non trouvé',
                'current_balance', 0,
                'required_tokens', required_tokens
            )
        WHEN up.tokens >= required_tokens THEN 
            jsonb_build_object(
                'can_publish', true,
                'message', 'Publication autorisée',
                'current_balance', up.tokens,
                'required_tokens', required_tokens
            )
        ELSE 
            jsonb_build_object(
                'can_publish', false,
                'message', 'Jetons insuffisants pour publier ce produit',
                'current_balance', up.tokens,
                'required_tokens', required_tokens,
                'tokens_needed', required_tokens - up.tokens
            )
    END
FROM public.user_profiles up
WHERE up.id = user_uuid;
$$;

-- 9. Update existing mock data to ensure users have token balances
DO $$
BEGIN
    -- Update any existing users to have 50 tokens if they don't already
    UPDATE public.user_profiles 
    SET tokens = 50 
    WHERE tokens = 0 OR tokens IS NULL;
    
    -- Ensure the existing sample token transactions are consistent
    -- This updates any existing token transactions to have proper balance_after values
    UPDATE public.token_transactions tt
    SET balance_after = COALESCE(
        (SELECT tokens FROM public.user_profiles up WHERE up.id = tt.user_id),
        20
    )
    WHERE tt.balance_after = 20; -- Update the sample data balance
END $$;