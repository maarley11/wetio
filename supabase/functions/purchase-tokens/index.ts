import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.21.0';
import Stripe from 'https://esm.sh/stripe@12.0.0?target=deno';

const ALLOWED_ORIGINS = [
    'https://www.kaywetio.com',
    'https://kaywetio.com',
    'https://wetio.sn',
];

function getCorsHeaders(req: Request) {
    const origin = req.headers.get('Origin') ?? '';
    const allowedOrigin = ALLOWED_ORIGINS.includes(origin) ? origin : ALLOWED_ORIGINS[0];
    return {
        'Access-Control-Allow-Origin': allowedOrigin,
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-idempotency-key',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
    };
}

// Grille tarifaire officielle côté serveur (JAMAIS dictée par le client)
const TOKEN_PACKAGES: Record<number, { fcfa: number; usd_cents: number }> = {
    50:   { fcfa: 500,   usd_cents: 90 },
    100:  { fcfa: 1000,  usd_cents: 180 },
    250:  { fcfa: 2500,  usd_cents: 450 },
    300:  { fcfa: 2500,  usd_cents: 450 },
    500:  { fcfa: 4000,  usd_cents: 720 },
    1000: { fcfa: 7500,  usd_cents: 1350 },
};

serve(async (req) => {
    const corsHeaders = getCorsHeaders(req);

    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders });
    }

    try {
        const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
        const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
        const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

        const authClient = createClient(supabaseUrl, supabaseAnonKey);
        const adminClient = createClient(supabaseUrl, supabaseServiceRoleKey);

        const authHeader = req.headers.get('Authorization');
        if (!authHeader) {
            throw new Error('En-tête Authorization manquant');
        }

        const token = authHeader.replace('Bearer ', '');
        const { data: { user }, error: userError } = await authClient.auth.getUser(token);

        if (userError || !user) {
            throw new Error('Utilisateur non authentifié');
        }

        const requestData = await req.json();
        const tokensToPurchase = Number(requestData.tokens_to_purchase);
        const paymentMethod = requestData.payment_method === 'wave' ? 'wave' : 'stripe';

        // VALIDATION SERVEUR STRICTE DU FORFAIT (anti-falsification de prix)
        const selectedPackage = TOKEN_PACKAGES[tokensToPurchase];
        if (!selectedPackage) {
            throw new Error(`Forfait de jetons invalide (${tokensToPurchase}). Forfaits autorisés : 50, 100, 250, 300, 500, 1000.`);
        }

        const serverAmountFcfa = selectedPackage.fcfa;
        const serverAmountCents = selectedPackage.usd_cents;

        let paymentIntentId = '';
        let clientSecret: string | null = null;
        let waveCheckoutUrl: string | null = null;

        if (paymentMethod === 'stripe') {
            const stripeKey = Deno.env.get('STRIPE_SECRET_KEY');
            if (!stripeKey) throw new Error('Clé Stripe STRIPE_SECRET_KEY non configurée');

            // Garde-fou Production : alerter ou bloquer toute clé sk_test_ si ENVIRONMENT=strict_live
            const envMode = Deno.env.get('ENVIRONMENT') ?? 'production';
            if (stripeKey.startsWith('sk_test_')) {
                console.warn('[SECURITY WARNING] Clé STRIPE_SECRET_KEY en mode TEST (sk_test_) utilisée.');
                if (envMode === 'strict_live') {
                    throw new Error('Configuration de paiement indisponible (clé de test détectée en production).');
                }
            }

            const stripe = new Stripe(stripeKey, { apiVersion: '2022-11-15' });

            // Idempotency key déterministe (header client ou fenêtre d'une minute par utilisateur/forfait)
            const clientIdempotency = req.headers.get('x-idempotency-key');
            const idempotencyKey = clientIdempotency || `tokens_${user.id}_${tokensToPurchase}_${Math.floor(Date.now() / 60000)}`;

            const paymentIntent = await stripe.paymentIntents.create({
                amount: serverAmountCents,
                currency: 'usd',
                automatic_payment_methods: { enabled: true },
                description: `Achat de ${tokensToPurchase} jetons WETIO - ${user.email ?? user.id}`,
                metadata: {
                    user_id: user.id,
                    tokens_to_purchase: tokensToPurchase.toString(),
                    amount_fcfa: serverAmountFcfa.toString(),
                    expected_usd_cents: serverAmountCents.toString(),
                    purchase_type: 'tokens',
                },
            }, {
                idempotencyKey,
            });

            paymentIntentId = paymentIntent.id;
            clientSecret = paymentIntent.client_secret;
        } else {
            // Wave : identifiant unique généré exclusivement côté serveur
            paymentIntentId = `WAVE_${user.id.substring(0, 8)}_${Date.now()}`;
            const waveMerchantBase = Deno.env.get('WAVE_MERCHANT_URL') || 'https://pay.wave.com/m/M_sn_F7IKNV0jou_P/c/sn/';
            waveCheckoutUrl = `${waveMerchantBase}?amount=${serverAmountFcfa}`;
        }

        // Journalisation systématique en base de données (statut non crédité)
        const { data: transactionRecord, error: txError } = await adminClient
            .from('payment_transactions')
            .insert({
                user_id: user.id,
                payment_intent_id: paymentIntentId,
                amount_fcfa: serverAmountFcfa,
                tokens_purchased: tokensToPurchase,
                payment_status: paymentMethod === 'wave' ? 'awaiting_verification' : 'pending',
                payment_method: paymentMethod,
            })
            .select()
            .single();

        if (txError) {
            console.error('[purchase-tokens] Erreur enregistrement transaction:', txError);
            throw new Error('Erreur lors de la préparation de la transaction en base de données');
        }

        console.log(`[purchase-tokens] Intention créée: user=${user.id} ref=${paymentIntentId} tokens=${tokensToPurchase} fcfa=${serverAmountFcfa} method=${paymentMethod}`);

        return new Response(JSON.stringify({
            success: true,
            client_secret: clientSecret,
            payment_intent_id: paymentIntentId,
            payment_transaction_id: transactionRecord.id,
            tokens_to_purchase: tokensToPurchase,
            amount_fcfa: serverAmountFcfa,
            payment_url: waveCheckoutUrl,
            message: `Intention de paiement créée pour ${tokensToPurchase} jetons via ${paymentMethod}`,
        }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 200,
        });

    } catch (error) {
        console.error('[purchase-tokens] Erreur:', error.message);
        return new Response(JSON.stringify({
            success: false,
            error: error.message,
        }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 400,
        });
    }
});
