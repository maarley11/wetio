-- Migration to fix payment_transactions table and support token purchases

-- 1. Create payment_transactions table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.payment_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    payment_intent_id TEXT UNIQUE,
    amount_fcfa INTEGER NOT NULL,
    tokens_purchased INTEGER NOT NULL,
    payment_status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'awaiting_verification', 'completed', 'failed'
    payment_method TEXT NOT NULL, -- 'stripe', 'wave', 'orange_money'
    admin_notes TEXT,
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 2. Add payment_intent_id if table exists but column is missing
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'payment_transactions') THEN
        IF NOT EXISTS (SELECT FROM pg_attribute WHERE attrelid = 'public.payment_transactions'::regclass AND attname = 'payment_intent_id') THEN
            ALTER TABLE public.payment_transactions ADD COLUMN payment_intent_id TEXT UNIQUE;
        END IF;
    END IF;
END $$;

-- 3. Enable RLS
ALTER TABLE public.payment_transactions ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies
DROP POLICY IF EXISTS "users_view_own_payments" ON public.payment_transactions;
CREATE POLICY "users_view_own_payments"
ON public.payment_transactions
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "users_insert_own_payments" ON public.payment_transactions;
CREATE POLICY "users_insert_own_payments"
ON public.payment_transactions
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- 5. Admin can view and manage all payments
DROP POLICY IF EXISTS "admins_manage_all_payments" ON public.payment_transactions;
CREATE POLICY "admins_manage_all_payments"
ON public.payment_transactions
FOR ALL 
TO authenticated
USING (auth.jwt() ->> 'email' = 'admin@wetio.com')
WITH CHECK (auth.jwt() ->> 'email' = 'admin@wetio.com');

-- 6. Service role can manage all
