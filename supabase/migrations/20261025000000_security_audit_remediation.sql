-- ==============================================================================
-- MIGRATION DE DURCISSEMENT ET REMÉDIATION DE SÉCURITÉ AUDIT — WETIO
-- Date: 2026-11-07
-- Projet Supabase: zjcnggoxjyonahoiansk (www.kaywetio.com)
-- 100% IDEMPOTENT & ROBUSTE
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 0. REQUÊTE D'AUDIT PRÉALABLE : LISTER LES GRANTS ACTUELS DE ANON
--    (À exécuter dans le SQL Editor pour inspecter l'état avant/après)
-- ------------------------------------------------------------------------------
/*
SELECT grantee, table_schema, table_name, privilege_type
FROM information_schema.role_table_grants
WHERE grantee = 'anon'
  AND table_schema = 'public'
ORDER BY table_name, privilege_type;
*/

-- ------------------------------------------------------------------------------
-- 1. ADJONCTION DES COLONNES PUBLIQUES ET DE CONTRÔLE SUR USER_PROFILES
-- ------------------------------------------------------------------------------
ALTER TABLE public.user_profiles 
  ADD COLUMN IF NOT EXISTS reputation_score NUMERIC DEFAULT 5.0,
  ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS is_delivery_partner BOOLEAN DEFAULT false;

-- ------------------------------------------------------------------------------
-- 2. PROTECTION DES COLONNES FINANCIÈRES ET SENSIBLES (ANTI AUTO-CRÉDIT)
--    Empêche un utilisateur authentifié de modifier lui-même son solde (balance),
--    ses jetons (tokens), son statut vérifié (is_verified) ou son score via l'API REST.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.protect_sensitive_profile_columns()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    -- Seul le rôle service_role (Edge Functions / Triggers internes) ou postgres
    -- peut modifier tokens, balance, is_verified, reputation_score.
    IF current_setting('request.jwt.claim.role', true) = 'authenticated' THEN
        NEW.tokens := OLD.tokens;
        NEW.balance := OLD.balance;
        NEW.is_verified := OLD.is_verified;
        NEW.reputation_score := OLD.reputation_score;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_sensitive_profile_columns ON public.user_profiles;
CREATE TRIGGER trg_protect_sensitive_profile_columns
BEFORE UPDATE ON public.user_profiles
FOR EACH ROW
EXECUTE FUNCTION public.protect_sensitive_profile_columns();

-- ------------------------------------------------------------------------------
-- 3. CRÉATION DE LA VUE SÉCURISÉE PUBLIC_PROFILES (SECURITY BARRIER)
--    Expose EXCLUSIVEMENT les 7 attributs publics demandés :
--    id, pseudo, avatar_url, full_name, reputation_score, is_verified, location
-- ------------------------------------------------------------------------------
DROP VIEW IF EXISTS public.public_profiles CASCADE;

CREATE VIEW public.public_profiles
WITH (security_barrier = true) AS
SELECT 
    id,
    pseudo,
    avatar_url,
    full_name,
    reputation_score,
    is_verified,
    location
FROM public.user_profiles
WHERE COALESCE(is_active, true) = true;

COMMENT ON VIEW public.public_profiles IS 'Vue publique sécurisée (SECURITY BARRIER) des profils utilisateurs sans données PII/financières.';

-- ------------------------------------------------------------------------------
-- 4. FONCTIONS SÉCURISÉES (LOGIN & CRÉDIT IDEMPOTENT DE JETONS)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_login_email_for_identifier(p_identifier TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_clean TEXT := TRIM(LOWER(p_identifier));
    v_clean_phone TEXT := REGEXP_REPLACE(p_identifier, '\D', '', 'g');
    v_email TEXT;
BEGIN
    IF v_clean = '' THEN
        RETURN NULL;
    END IF;

    -- 1. Recherche par pseudo insensible à la casse
    SELECT email INTO v_email
    FROM public.user_profiles
    WHERE LOWER(pseudo) = v_clean AND COALESCE(is_active, true) = true
    LIMIT 1;

    -- 2. Si non trouvé, recherche par numéro de téléphone
    IF v_email IS NULL AND v_clean_phone <> '' THEN
        SELECT email INTO v_email
        FROM public.user_profiles
        WHERE REGEXP_REPLACE(phone, '\D', '', 'g') = v_clean_phone AND COALESCE(is_active, true) = true
        LIMIT 1;
    END IF;

    RETURN v_email;
END;
$$;

-- Fonction atomique et idempotente pour créditer les jetons côté serveur (Stripe / Wave)
CREATE OR REPLACE FUNCTION public.credit_tokens_idempotent(
    p_user_id UUID,
    p_tokens INTEGER,
    p_payment_intent_id TEXT,
    p_amount_fcfa INTEGER,
    p_payment_method TEXT DEFAULT 'stripe'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_existing_status TEXT;
    v_current_balance INTEGER;
    v_new_balance INTEGER;
    v_tx_id UUID;
BEGIN
    IF p_tokens <= 0 THEN
        RAISE EXCEPTION 'Nombre de jetons invalide (%)', p_tokens;
    END IF;

    -- Verrouillage exclusif de la transaction de paiement (idempotence stricte)
    SELECT payment_status INTO v_existing_status
    FROM public.payment_transactions
    WHERE payment_intent_id = p_payment_intent_id
    FOR UPDATE;

    -- Si déjà créditée, retourner immédiatement sans double crédit
    IF v_existing_status = 'completed' THEN
        SELECT tokens INTO v_current_balance FROM public.user_profiles WHERE id = p_user_id;
        RETURN jsonb_build_object(
            'success', true,
            'already_processed', true,
            'new_balance', COALESCE(v_current_balance, 0),
            'message', 'Transaction déjà créditée (idempotence)'
        );
    END IF;

    -- Verrouillage de la ligne user_profiles
    SELECT tokens INTO v_current_balance
    FROM public.user_profiles
    WHERE id = p_user_id
    FOR UPDATE;

    IF v_current_balance IS NULL THEN
        RAISE EXCEPTION 'Profil utilisateur introuvable pour %', p_user_id;
    END IF;

    v_new_balance := v_current_balance + p_tokens;

    -- Mise à jour du solde de jetons
    UPDATE public.user_profiles
    SET tokens = v_new_balance,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_user_id;

    -- Mise à jour ou insertion dans payment_transactions
    UPDATE public.payment_transactions
    SET payment_status = 'completed',
        verified_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE payment_intent_id = p_payment_intent_id;

    -- Journalisation dans token_transactions
    INSERT INTO public.token_transactions (
        user_id,
        type,
        amount,
        description,
        reference_id,
        balance_after
    ) VALUES (
        p_user_id,
        'purchased'::public.token_transaction_type,
        p_tokens,
        'Achat validé (' || UPPER(p_payment_method) || ') : ' || p_tokens || ' jetons (' || p_amount_fcfa || ' FCFA)',
        p_payment_intent_id,
        v_new_balance
    ) RETURNING id INTO v_tx_id;

    RETURN jsonb_build_object(
        'success', true,
        'already_processed', false,
        'tokens_added', p_tokens,
        'previous_balance', v_current_balance,
        'new_balance', v_new_balance,
        'transaction_id', v_tx_id
    );
END;
$$;

-- Sécurisation des fonctions existantes de jetons (vérification stricte auth.uid())
CREATE OR REPLACE FUNCTION public.deduct_tokens_for_publication(
    user_uuid UUID,
    product_title TEXT,
    tokens_to_deduct INTEGER DEFAULT 10
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    current_balance INTEGER;
    new_balance INTEGER;
    transaction_id UUID;
BEGIN
    IF auth.uid() IS NULL OR auth.uid() <> user_uuid THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Accès non autorisé : vous ne pouvez débiter que votre propre compte',
            'error_code', 'UNAUTHORIZED'
        );
    END IF;

    IF tokens_to_deduct <= 0 THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Montant de déduction invalide',
            'error_code', 'INVALID_AMOUNT'
        );
    END IF;

    SELECT tokens INTO current_balance 
    FROM public.user_profiles 
    WHERE id = user_uuid
    FOR UPDATE;
    
    IF current_balance IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Utilisateur non trouvé',
            'error_code', 'USER_NOT_FOUND'
        );
    END IF;
    
    IF current_balance < tokens_to_deduct THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Jetons insuffisants. Vous avez ' || current_balance || ' jetons, mais ' || tokens_to_deduct || ' sont requis.',
            'error_code', 'INSUFFICIENT_TOKENS',
            'current_balance', current_balance,
            'required_tokens', tokens_to_deduct
        );
    END IF;
    
    new_balance := current_balance - tokens_to_deduct;
    
    UPDATE public.user_profiles 
    SET tokens = new_balance, updated_at = CURRENT_TIMESTAMP
    WHERE id = user_uuid;
    
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

-- Durcissement de add_tokens_after_payment : réservé exclusivement à l'admin ou service_role
CREATE OR REPLACE FUNCTION public.add_tokens_after_payment(
    user_uuid UUID,
    tokens_to_add INTEGER,
    payment_reference TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_caller_email TEXT := COALESCE(auth.jwt() ->> 'email', '');
    v_caller_role TEXT := COALESCE(current_setting('request.jwt.claim.role', true), '');
BEGIN
    IF v_caller_role <> 'service_role' AND v_caller_email NOT IN ('admin@wetio.com', 'admin@wetio.sn') THEN
        RAISE EXCEPTION 'Accès refusé : opération réservée aux administrateurs et au service_role';
    END IF;

    RETURN public.credit_tokens_idempotent(
        user_uuid,
        tokens_to_add,
        payment_reference,
        0,
        'wave'
    );
END;
$$;

-- ------------------------------------------------------------------------------
-- 5. ACTIVATION ET FORÇAGE DU ROW LEVEL SECURITY (RLS) SUR TOUTES LES TABLES
-- ------------------------------------------------------------------------------
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public'
    ) LOOP
        EXECUTE 'ALTER TABLE public.' || quote_ident(r.tablename) || ' ENABLE ROW LEVEL SECURITY;';
        EXECUTE 'ALTER TABLE public.' || quote_ident(r.tablename) || ' FORCE ROW LEVEL SECURITY;';
    END LOOP;
END $$;

-- ------------------------------------------------------------------------------
-- 6. POLITIQUES RLS COMPLÈTES PAR TABLE
-- ------------------------------------------------------------------------------
DO $$
BEGIN
    -- === A. USER_PROFILES (SELECT/INSERT/UPDATE réservés à auth.uid() = id) ===
    IF to_regclass('public.user_profiles') IS NOT NULL THEN
        DROP POLICY IF EXISTS "public_view_user_profiles" ON public.user_profiles;
        DROP POLICY IF EXISTS "users_manage_own_user_profiles" ON public.user_profiles;
        DROP POLICY IF EXISTS "users_view_own_profile" ON public.user_profiles;
        DROP POLICY IF EXISTS "users_update_own_profile" ON public.user_profiles;
        DROP POLICY IF EXISTS "users_insert_own_profile" ON public.user_profiles;

        EXECUTE 'CREATE POLICY "users_view_own_profile" ON public.user_profiles FOR SELECT TO authenticated USING (auth.uid() = id OR auth.jwt() ->> ''email'' IN (''admin@wetio.com'', ''admin@wetio.sn''))';
        EXECUTE 'CREATE POLICY "users_insert_own_profile" ON public.user_profiles FOR INSERT TO authenticated WITH CHECK (auth.uid() = id)';
        EXECUTE 'CREATE POLICY "users_update_own_profile" ON public.user_profiles FOR UPDATE TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id)';
    END IF;

    -- === B. DELIVERY_REQUESTS (Participants uniquement) ===
    IF to_regclass('public.delivery_requests') IS NOT NULL THEN
        DROP POLICY IF EXISTS "users_view_delivery_requests" ON public.delivery_requests;
        DROP POLICY IF EXISTS "users_manage_delivery_requests" ON public.delivery_requests;
        DROP POLICY IF EXISTS "users_insert_delivery_requests" ON public.delivery_requests;
        DROP POLICY IF EXISTS "users_update_delivery_requests" ON public.delivery_requests;

        EXECUTE 'CREATE POLICY "users_view_delivery_requests" ON public.delivery_requests FOR SELECT TO authenticated USING (initiator_id = auth.uid() OR partner_user_id = auth.uid() OR person_a_id = auth.uid() OR person_b_id = auth.uid() OR exchange_partner_id = auth.uid())';
        EXECUTE 'CREATE POLICY "users_insert_delivery_requests" ON public.delivery_requests FOR INSERT TO authenticated WITH CHECK (initiator_id = auth.uid() OR person_a_id = auth.uid())';
        EXECUTE 'CREATE POLICY "users_update_delivery_requests" ON public.delivery_requests FOR UPDATE TO authenticated USING (initiator_id = auth.uid() OR partner_user_id = auth.uid() OR person_a_id = auth.uid() OR person_b_id = auth.uid() OR exchange_partner_id = auth.uid()) WITH CHECK (initiator_id = auth.uid() OR partner_user_id = auth.uid() OR person_a_id = auth.uid() OR person_b_id = auth.uid() OR exchange_partner_id = auth.uid())';
    END IF;

    -- === C. EXCHANGES (Participants requester_id / owner_id uniquement) ===
    IF to_regclass('public.exchanges') IS NOT NULL THEN
        DROP POLICY IF EXISTS "users_view_exchanges" ON public.exchanges;
        DROP POLICY IF EXISTS "users_insert_exchanges" ON public.exchanges;
        DROP POLICY IF EXISTS "users_update_exchanges" ON public.exchanges;

        EXECUTE 'CREATE POLICY "users_view_exchanges" ON public.exchanges FOR SELECT TO authenticated USING (requester_id = auth.uid() OR owner_id = auth.uid())';
        EXECUTE 'CREATE POLICY "users_insert_exchanges" ON public.exchanges FOR INSERT TO authenticated WITH CHECK (requester_id = auth.uid())';
        EXECUTE 'CREATE POLICY "users_update_exchanges" ON public.exchanges FOR UPDATE TO authenticated USING (requester_id = auth.uid() OR owner_id = auth.uid()) WITH CHECK (requester_id = auth.uid() OR owner_id = auth.uid())';
    END IF;

    -- === D. TOKEN_TRANSACTIONS (Lecture propriétaire uniquement, écriture via RPC/service_role) ===
    IF to_regclass('public.token_transactions') IS NOT NULL THEN
        DROP POLICY IF EXISTS "users_view_token_transactions" ON public.token_transactions;
        DROP POLICY IF EXISTS "users_insert_token_transactions" ON public.token_transactions;

        EXECUTE 'CREATE POLICY "users_view_token_transactions" ON public.token_transactions FOR SELECT TO authenticated USING (user_id = auth.uid())';
    END IF;

    -- === E. FAVORITES (Propriétaire user_id = auth.uid() uniquement) ===
    IF to_regclass('public.favorites') IS NOT NULL THEN
        DROP POLICY IF EXISTS "users_manage_own_favorites" ON public.favorites;
        DROP POLICY IF EXISTS "users_view_favorites" ON public.favorites;
        DROP POLICY IF EXISTS "users_insert_favorites" ON public.favorites;
        DROP POLICY IF EXISTS "users_update_favorites" ON public.favorites;
        DROP POLICY IF EXISTS "users_delete_favorites" ON public.favorites;

        EXECUTE 'CREATE POLICY "users_view_favorites" ON public.favorites FOR SELECT TO authenticated USING (user_id = auth.uid())';
        EXECUTE 'CREATE POLICY "users_insert_favorites" ON public.favorites FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid())';
        EXECUTE 'CREATE POLICY "users_update_favorites" ON public.favorites FOR UPDATE TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid())';
        EXECUTE 'CREATE POLICY "users_delete_favorites" ON public.favorites FOR DELETE TO authenticated USING (user_id = auth.uid())';
    END IF;

    -- === F. PRODUCTS (Catalogue public en lecture, INSERT/UPDATE/DELETE réservés à owner_id = auth.uid()) ===
    IF to_regclass('public.products') IS NOT NULL THEN
        DROP POLICY IF EXISTS "public_read_active_products" ON public.products;
        DROP POLICY IF EXISTS "public_view_products" ON public.products;
        DROP POLICY IF EXISTS "public_view_active_products" ON public.products;
        DROP POLICY IF EXISTS "users_manage_own_products" ON public.products;
        DROP POLICY IF EXISTS "users_insert_own_products" ON public.products;
        DROP POLICY IF EXISTS "users_update_own_products" ON public.products;
        DROP POLICY IF EXISTS "users_delete_own_products" ON public.products;
        DROP POLICY IF EXISTS "owners_read_own_products" ON public.products;
        DROP POLICY IF EXISTS "users_insert_products" ON public.products;
        DROP POLICY IF EXISTS "users_update_products" ON public.products;
        DROP POLICY IF EXISTS "users_delete_products" ON public.products;

        EXECUTE 'CREATE POLICY "public_view_active_products" ON public.products FOR SELECT TO public USING (COALESCE(is_active, true) = true OR (auth.role() = ''authenticated'' AND owner_id = auth.uid()))';
        EXECUTE 'CREATE POLICY "users_insert_products" ON public.products FOR INSERT TO authenticated WITH CHECK (owner_id = auth.uid())';
        EXECUTE 'CREATE POLICY "users_update_products" ON public.products FOR UPDATE TO authenticated USING (owner_id = auth.uid()) WITH CHECK (owner_id = auth.uid())';
        EXECUTE 'CREATE POLICY "users_delete_products" ON public.products FOR DELETE TO authenticated USING (owner_id = auth.uid())';
    END IF;

    -- === G. CHAT_CONVERSATIONS & CHAT_MESSAGES ===
    IF to_regclass('public.chat_conversations') IS NOT NULL THEN
        DROP POLICY IF EXISTS "participants_view_conversations" ON public.chat_conversations;
        DROP POLICY IF EXISTS "participants_insert_conversations" ON public.chat_conversations;
        DROP POLICY IF EXISTS "participants_update_conversations" ON public.chat_conversations;

        EXECUTE 'CREATE POLICY "participants_view_conversations" ON public.chat_conversations FOR SELECT TO authenticated USING (participant_a = auth.uid() OR participant_b = auth.uid())';
        EXECUTE 'CREATE POLICY "participants_insert_conversations" ON public.chat_conversations FOR INSERT TO authenticated WITH CHECK (participant_a = auth.uid() OR participant_b = auth.uid())';
        EXECUTE 'CREATE POLICY "participants_update_conversations" ON public.chat_conversations FOR UPDATE TO authenticated USING (participant_a = auth.uid() OR participant_b = auth.uid())';
    END IF;

    IF to_regclass('public.chat_messages') IS NOT NULL THEN
        DROP POLICY IF EXISTS "participants_view_messages" ON public.chat_messages;
        DROP POLICY IF EXISTS "participants_insert_messages" ON public.chat_messages;

        EXECUTE 'CREATE POLICY "participants_view_messages" ON public.chat_messages FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.chat_conversations c WHERE c.id = conversation_id AND (c.participant_a = auth.uid() OR c.participant_b = auth.uid())))';
        EXECUTE 'CREATE POLICY "participants_insert_messages" ON public.chat_messages FOR INSERT TO authenticated WITH CHECK (sender_id = auth.uid())';
    END IF;

    -- === H. PRODUCT_ORDERS & EXCHANGE_HISTORY ===
    IF to_regclass('public.product_orders') IS NOT NULL THEN
        DROP POLICY IF EXISTS "users_view_product_orders" ON public.product_orders;
        DROP POLICY IF EXISTS "users_insert_product_orders" ON public.product_orders;
        DROP POLICY IF EXISTS "users_update_product_orders" ON public.product_orders;

        EXECUTE 'CREATE POLICY "users_view_product_orders" ON public.product_orders FOR SELECT TO authenticated USING (buyer_id = auth.uid() OR seller_id = auth.uid())';
        EXECUTE 'CREATE POLICY "users_insert_product_orders" ON public.product_orders FOR INSERT TO authenticated WITH CHECK (buyer_id = auth.uid())';
        EXECUTE 'CREATE POLICY "users_update_product_orders" ON public.product_orders FOR UPDATE TO authenticated USING (buyer_id = auth.uid() OR seller_id = auth.uid())';
    END IF;

    IF to_regclass('public.exchange_history') IS NOT NULL THEN
        DROP POLICY IF EXISTS "users_view_exchange_history" ON public.exchange_history;
        DROP POLICY IF EXISTS "users_insert_exchange_history" ON public.exchange_history;
        DROP POLICY IF EXISTS "users_update_exchange_history" ON public.exchange_history;
        DROP POLICY IF EXISTS "users_delete_exchange_history" ON public.exchange_history;

        EXECUTE 'CREATE POLICY "users_view_exchange_history" ON public.exchange_history FOR SELECT TO authenticated USING (owner_id = auth.uid() OR requester_id = auth.uid())';
        EXECUTE 'CREATE POLICY "users_insert_exchange_history" ON public.exchange_history FOR INSERT TO authenticated WITH CHECK (owner_id = auth.uid() OR requester_id = auth.uid())';
        EXECUTE 'CREATE POLICY "users_update_exchange_history" ON public.exchange_history FOR UPDATE TO authenticated USING (owner_id = auth.uid() OR requester_id = auth.uid())';
        EXECUTE 'CREATE POLICY "users_delete_exchange_history" ON public.exchange_history FOR DELETE TO authenticated USING (owner_id = auth.uid() OR requester_id = auth.uid())';
    END IF;

    -- === I. PAYMENT_TRANSACTIONS ===
    IF to_regclass('public.payment_transactions') IS NOT NULL THEN
        DROP POLICY IF EXISTS "users_view_own_payments" ON public.payment_transactions;
        DROP POLICY IF EXISTS "users_insert_own_payments" ON public.payment_transactions;
        DROP POLICY IF EXISTS "admins_manage_all_payments" ON public.payment_transactions;
        DROP POLICY IF EXISTS "users_view_payment_transactions" ON public.payment_transactions;
        DROP POLICY IF EXISTS "users_insert_payment_transactions" ON public.payment_transactions;
        DROP POLICY IF EXISTS "admins_update_payment_transactions" ON public.payment_transactions;

        EXECUTE 'CREATE POLICY "users_view_payment_transactions" ON public.payment_transactions FOR SELECT TO authenticated USING (user_id = auth.uid() OR auth.jwt() ->> ''email'' IN (''admin@wetio.com'', ''admin@wetio.sn''))';
        EXECUTE 'CREATE POLICY "admins_update_payment_transactions" ON public.payment_transactions FOR UPDATE TO authenticated USING (auth.jwt() ->> ''email'' IN (''admin@wetio.com'', ''admin@wetio.sn'')) WITH CHECK (auth.jwt() ->> ''email'' IN (''admin@wetio.com'', ''admin@wetio.sn''))';
    END IF;

    -- === J. DELIVERY_PERSONS & DELIVERY_RATINGS ===
    IF to_regclass('public.delivery_persons') IS NOT NULL THEN
        DROP POLICY IF EXISTS "public_view_delivery_persons" ON public.delivery_persons;
        EXECUTE 'CREATE POLICY "public_view_delivery_persons" ON public.delivery_persons FOR SELECT TO authenticated USING (true)';
    END IF;

    IF to_regclass('public.delivery_ratings') IS NOT NULL THEN
        DROP POLICY IF EXISTS "public_view_delivery_ratings" ON public.delivery_ratings;
        EXECUTE 'CREATE POLICY "public_view_delivery_ratings" ON public.delivery_ratings FOR SELECT TO authenticated USING (true)';
    END IF;
END $$;

-- ------------------------------------------------------------------------------
-- 7. RÉVOCATION DES DROITS PAR DÉFAUT DU RÔLE ANON & MOINDRE PRIVILÈGE
-- ------------------------------------------------------------------------------
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM anon;
REVOKE ALL ON ALL ROUTINES IN SCHEMA public FROM anon;

ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON SEQUENCES FROM anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON ROUTINES FROM anon;

-- Droits strictement minimaux accordés à anon (catalogue produits + vue public_profiles + résolution login)
GRANT USAGE ON SCHEMA public TO anon;
GRANT SELECT ON public.public_profiles TO anon;
GRANT EXECUTE ON FUNCTION public.get_login_email_for_identifier(TEXT) TO anon;

DO $$
BEGIN
    IF to_regclass('public.products') IS NOT NULL THEN
        EXECUTE 'GRANT SELECT ON public.products TO anon';
    END IF;
END $$;

-- Droits pour les utilisateurs authentifiés (filtrés par RLS)
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT SELECT ON public.public_profiles TO authenticated;

-- Restriction stricte sur credit_tokens_idempotent (uniquement service_role)
REVOKE ALL ON FUNCTION public.credit_tokens_idempotent(UUID, INTEGER, TEXT, INTEGER, TEXT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.credit_tokens_idempotent(UUID, INTEGER, TEXT, INTEGER, TEXT) TO service_role;

-- ------------------------------------------------------------------------------
-- 8. DURCISSEMENT DU STORAGE (BUCKET product-images)
--    Limite de taille (5 Mo), MIME types stricts, anti-listing massif
-- ------------------------------------------------------------------------------
UPDATE storage.buckets
SET public = true,
    file_size_limit = 5242880, -- 5 Mo max par image
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp']
WHERE id = 'product-images';

DROP POLICY IF EXISTS "public_read_product_images" ON storage.objects;
DROP POLICY IF EXISTS "authenticated_upload_product_images" ON storage.objects;
DROP POLICY IF EXISTS "owners_delete_product_images" ON storage.objects;
DROP POLICY IF EXISTS "owners_update_product_images" ON storage.objects;

-- Lecture publique des images du bucket product-images (nécessaire pour le catalogue)
CREATE POLICY "public_read_product_images" ON storage.objects
FOR SELECT TO public
USING (bucket_id = 'product-images');

-- Upload réservé aux utilisateurs authentifiés avec contrôle d'extension et d'owner
CREATE POLICY "authenticated_upload_product_images" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
    bucket_id = 'product-images'
    AND (storage.extension(name) IN ('jpg', 'jpeg', 'png', 'webp'))
);

-- Modification et suppression réservées exclusivement au propriétaire du fichier
CREATE POLICY "owners_update_product_images" ON storage.objects
FOR UPDATE TO authenticated
USING (bucket_id = 'product-images' AND owner = auth.uid())
WITH CHECK (bucket_id = 'product-images' AND owner = auth.uid());

CREATE POLICY "owners_delete_product_images" ON storage.objects
FOR DELETE TO authenticated
USING (bucket_id = 'product-images' AND owner = auth.uid());

-- ------------------------------------------------------------------------------
-- 9. FAILLE 2 : AUDIT ET PURGE DES COMPTES NON CONFIRMÉS / JETABLES / SUSPECTS
-- ------------------------------------------------------------------------------

-- 9.A. Requête d'audit : Lister les comptes suspects (métadonnées incohérentes,
--      emails non confirmés, ou domaines d'emails jetables)
/*
SELECT 
    u.id,
    u.email,
    u.phone,
    u.email_confirmed_at,
    u.created_at,
    u.raw_user_meta_data,
    p.pseudo,
    p.full_name,
    p.tokens,
    p.balance,
    CASE
        WHEN u.email_confirmed_at IS NULL THEN 'EMAIL_NON_CONFIRME'
        WHEN SPLIT_PART(u.email, '@', 2) IN (
            'yopmail.com', 'tempmail.com', '10minutemail.com', 'guerrillamail.com',
            'mailinator.com', 'trashmail.com', 'sharklasers.com', 'getnada.com', 'temp-mail.org'
        ) THEN 'EMAIL_JETABLE'
        WHEN p.id IS NULL THEN 'PROFIL_ORPHELIN'
        WHEN COALESCE(u.raw_user_meta_data->>'pseudo', '') = '' AND COALESCE(p.pseudo, '') = '' THEN 'METADATA_INCOHERENTE'
        ELSE 'A_VERIFIER'
    END AS raison_suspicion
FROM auth.users u
LEFT JOIN public.user_profiles p ON p.id = u.id
WHERE u.email_confirmed_at IS NULL
   OR SPLIT_PART(u.email, '@', 2) IN (
       'yopmail.com', 'tempmail.com', '10minutemail.com', 'guerrillamail.com',
       'mailinator.com', 'trashmail.com', 'sharklasers.com', 'getnada.com', 'temp-mail.org'
   )
   OR p.id IS NULL
   OR (COALESCE(u.raw_user_meta_data->>'full_name', '') = '' AND COALESCE(p.full_name, '') = '')
ORDER BY u.created_at DESC;
*/

-- 9.B. Purge sécurisée des comptes créés avec un email jetable ou non confirmés (> 48h)
--      sans activité réelle (aucun produit, aucun échange, aucun achat complété)
/*
DELETE FROM auth.users u
WHERE (
    (u.email_confirmed_at IS NULL AND u.created_at < NOW() - INTERVAL '48 hours' AND u.email NOT LIKE 'phone_%@wetio.app')
    OR SPLIT_PART(u.email, '@', 2) IN (
        'yopmail.com', 'tempmail.com', '10minutemail.com', 'guerrillamail.com',
        'mailinator.com', 'trashmail.com', 'sharklasers.com', 'getnada.com', 'temp-mail.org'
    )
)
AND NOT EXISTS (SELECT 1 FROM public.products pr WHERE pr.owner_id = u.id)
AND NOT EXISTS (SELECT 1 FROM public.exchanges ex WHERE ex.owner_id = u.id OR ex.requester_id = u.id)
AND NOT EXISTS (SELECT 1 FROM public.payment_transactions pt WHERE pt.user_id = u.id AND pt.payment_status = 'completed');
*/
