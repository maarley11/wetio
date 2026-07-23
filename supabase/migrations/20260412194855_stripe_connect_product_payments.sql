-- Migration: Stripe Connect for direct product payments (0% commission for WETIO)
-- Adds stripe_connect_account_id to user_profiles and price to products
-- Creates product_orders table to track purchases

-- 1. Add stripe_connect_account_id to user_profiles (for sellers to receive payments directly)
ALTER TABLE public.user_profiles
ADD COLUMN IF NOT EXISTS stripe_connect_account_id TEXT DEFAULT NULL;

-- 2. Add price column to products (in FCFA)
ALTER TABLE public.products
ADD COLUMN IF NOT EXISTS price INTEGER DEFAULT NULL;

-- 3. Create product_orders table to track purchases
CREATE TABLE IF NOT EXISTS public.product_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    buyer_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    seller_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
    stripe_payment_intent_id TEXT UNIQUE,
    amount_fcfa INTEGER NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    delivery_method TEXT NOT NULL DEFAULT 'standard',
    delivery_fee_fcfa INTEGER NOT NULL DEFAULT 0,
    total_fcfa INTEGER NOT NULL,
    payment_status TEXT NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 4. Indexes
CREATE INDEX IF NOT EXISTS idx_product_orders_buyer_id ON public.product_orders(buyer_id);
CREATE INDEX IF NOT EXISTS idx_product_orders_seller_id ON public.product_orders(seller_id);
CREATE INDEX IF NOT EXISTS idx_product_orders_product_id ON public.product_orders(product_id);
CREATE INDEX IF NOT EXISTS idx_product_orders_payment_intent ON public.product_orders(stripe_payment_intent_id);

-- 5. Enable RLS
ALTER TABLE public.product_orders ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies
DROP POLICY IF EXISTS "buyers_view_own_orders" ON public.product_orders;
CREATE POLICY "buyers_view_own_orders"
ON public.product_orders
FOR SELECT
TO authenticated
USING (buyer_id = auth.uid() OR seller_id = auth.uid());

DROP POLICY IF EXISTS "buyers_create_orders" ON public.product_orders;
CREATE POLICY "buyers_create_orders"
ON public.product_orders
FOR INSERT
TO authenticated
WITH CHECK (buyer_id = auth.uid());

DROP POLICY IF EXISTS "service_role_manage_orders" ON public.product_orders;
CREATE POLICY "service_role_manage_orders"
ON public.product_orders
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);
