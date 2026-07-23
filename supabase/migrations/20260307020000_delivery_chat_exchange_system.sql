-- Migration: Delivery Chat Exchange System
-- Adds: chat_conversations, chat_messages, exchange_confirmation_codes, delivery_request enhancements

-- Add missing columns to delivery_requests if not exists
ALTER TABLE public.delivery_requests
  ADD COLUMN IF NOT EXISTS partner_user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS partner_name TEXT,
  ADD COLUMN IF NOT EXISTS partner_phone TEXT,
  ADD COLUMN IF NOT EXISTS partner_location TEXT,
  ADD COLUMN IF NOT EXISTS is_exchange_delivery BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS exchange_partner_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS distance_km NUMERIC(5,2),
  ADD COLUMN IF NOT EXISTS confirmation_code_a TEXT,
  ADD COLUMN IF NOT EXISTS confirmation_code_b TEXT,
  ADD COLUMN IF NOT EXISTS code_a_verified BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS code_b_verified BOOLEAN DEFAULT false;

-- Chat conversations table
CREATE TABLE IF NOT EXISTS public.chat_conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  participant_a UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  participant_b UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
  exchange_id UUID REFERENCES public.exchanges(id) ON DELETE SET NULL,
  last_message TEXT,
  last_message_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  unread_count_a INTEGER DEFAULT 0,
  unread_count_b INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Chat messages table
CREATE TABLE IF NOT EXISTS public.chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES public.chat_conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  message_type TEXT DEFAULT 'text',
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Exchange confirmation codes table
CREATE TABLE IF NOT EXISTS public.exchange_confirmation_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  delivery_request_id UUID NOT NULL REFERENCES public.delivery_requests(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  code TEXT NOT NULL,
  step TEXT NOT NULL, -- 'pickup_a', 'pickup_b', 'delivery_a', 'delivery_b'
  is_verified BOOLEAN DEFAULT false,
  verified_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_chat_conversations_participant_a ON public.chat_conversations(participant_a);
CREATE INDEX IF NOT EXISTS idx_chat_conversations_participant_b ON public.chat_conversations(participant_b);
CREATE INDEX IF NOT EXISTS idx_chat_messages_conversation_id ON public.chat_messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender_id ON public.chat_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_exchange_confirmation_codes_delivery_request_id ON public.exchange_confirmation_codes(delivery_request_id);
CREATE INDEX IF NOT EXISTS idx_delivery_requests_partner_user_id ON public.delivery_requests(partner_user_id);

-- Function to generate 4-digit confirmation code
CREATE OR REPLACE FUNCTION public.generate_confirmation_code()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  code TEXT;
BEGIN
  code := LPAD(FLOOR(RANDOM() * 9000 + 1000)::TEXT, 4, '0');
  RETURN code;
END;
$$;

-- Function to update conversation last message
CREATE OR REPLACE FUNCTION public.update_conversation_last_message()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.chat_conversations
  SET last_message = NEW.content,
      last_message_at = NEW.created_at,
      updated_at = CURRENT_TIMESTAMP
  WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$;

-- Enable RLS
ALTER TABLE public.chat_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exchange_confirmation_codes ENABLE ROW LEVEL SECURITY;

-- RLS Policies for chat_conversations
DROP POLICY IF EXISTS "users_view_own_conversations" ON public.chat_conversations;
CREATE POLICY "users_view_own_conversations"
ON public.chat_conversations
FOR SELECT
TO authenticated
USING (participant_a = auth.uid() OR participant_b = auth.uid());

DROP POLICY IF EXISTS "users_create_conversations" ON public.chat_conversations;
CREATE POLICY "users_create_conversations"
ON public.chat_conversations
FOR INSERT
TO authenticated
WITH CHECK (participant_a = auth.uid() OR participant_b = auth.uid());

DROP POLICY IF EXISTS "users_update_own_conversations" ON public.chat_conversations;
CREATE POLICY "users_update_own_conversations"
ON public.chat_conversations
FOR UPDATE
TO authenticated
USING (participant_a = auth.uid() OR participant_b = auth.uid())
WITH CHECK (participant_a = auth.uid() OR participant_b = auth.uid());

-- RLS Policies for chat_messages
DROP POLICY IF EXISTS "users_view_conversation_messages" ON public.chat_messages;
CREATE POLICY "users_view_conversation_messages"
ON public.chat_messages
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.chat_conversations cc
    WHERE cc.id = conversation_id
    AND (cc.participant_a = auth.uid() OR cc.participant_b = auth.uid())
  )
);

DROP POLICY IF EXISTS "users_send_messages" ON public.chat_messages;
CREATE POLICY "users_send_messages"
ON public.chat_messages
FOR INSERT
TO authenticated
WITH CHECK (sender_id = auth.uid());

-- RLS Policies for exchange_confirmation_codes
DROP POLICY IF EXISTS "users_view_own_codes" ON public.exchange_confirmation_codes;
CREATE POLICY "users_view_own_codes"
ON public.exchange_confirmation_codes
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_codes" ON public.exchange_confirmation_codes;
CREATE POLICY "users_manage_own_codes"
ON public.exchange_confirmation_codes
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- RLS for delivery_ratings (ensure public read for partner ratings)
DROP POLICY IF EXISTS "public_view_delivery_ratings" ON public.delivery_ratings;
CREATE POLICY "public_view_delivery_ratings"
ON public.delivery_ratings
FOR SELECT
TO public
USING (true);

DROP POLICY IF EXISTS "users_create_delivery_ratings" ON public.delivery_ratings;
CREATE POLICY "users_create_delivery_ratings"
ON public.delivery_ratings
FOR INSERT
TO authenticated
WITH CHECK (rater_id = auth.uid());

-- Trigger for updating conversation last message
DROP TRIGGER IF EXISTS update_conversation_on_message ON public.chat_messages;
CREATE TRIGGER update_conversation_on_message
  AFTER INSERT ON public.chat_messages
  FOR EACH ROW
  EXECUTE FUNCTION public.update_conversation_last_message();

-- RLS for products: public read so all users can see products on home feed and profiles
DROP POLICY IF EXISTS "public_view_products" ON public.products;
CREATE POLICY "public_view_products"
ON public.products
FOR SELECT
TO public
USING (is_active = true);

DROP POLICY IF EXISTS "users_manage_own_products" ON public.products;
CREATE POLICY "users_manage_own_products"
ON public.products
FOR ALL
TO authenticated
USING (owner_id = auth.uid())
WITH CHECK (owner_id = auth.uid());

-- RLS for user_profiles: public read so users can view other profiles
DROP POLICY IF EXISTS "public_view_user_profiles" ON public.user_profiles;
CREATE POLICY "public_view_user_profiles"
ON public.user_profiles
FOR SELECT
TO public
USING (is_active = true);

DROP POLICY IF EXISTS "users_manage_own_user_profiles" ON public.user_profiles;
CREATE POLICY "users_manage_own_user_profiles"
ON public.user_profiles
FOR ALL
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());
