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
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
    };
}

// Grille tarifaire officielle côté serveur pour vérification croisée du montant payé
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
        const { payment_intent_id } = requestData;

        if (!payment_intent_id || typeof payment_intent_id !== 'string') {
            throw new Error('Identifiant payment_intent_id manquant ou invalide');
        }

        // 1. Récupérer la transaction enregistrée côté serveur dans payment_transactions
        const { data: tx, error: txError } = await adminClient
            .from('payment_transactions')
            .select('*')
            .eq('payment_intent_id', payment_intent_id)
            .eq('user_id', user.id)
            .single();

        if (txError || !tx) {
            throw new Error('Transaction de paiement introuvable pour cet utilisateur');
        }

        // 2. Si déjà créditée (par ex. via le webhook Stripe arrivé avant l'appel client), retourner succès idempotent
        if (tx.payment_status === 'completed') {
            const { data: profile } = await adminClient
                .from('user_profiles')
                .select('tokens')
                .eq('id', user.id)
                .single();

            return new Response(JSON.stringify({
                success: true,
                status: 'completed',
                already_processed: true,
                message: 'Jetons déjà crédités sur votre compte',
                tokens_added: tx.tokens_purchased,
                new_balance: profile?.tokens ?? 0,
            }), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' },
                status: 200,
            });
        }

        // 3. Si paiement Wave : JAMAIS d'auto-validation par le client.
        //    Doit être validé par le webhook Wave B2B ou par un administrateur après contrôle du reçu Wave.
        if (tx.payment_method === 'wave') {
            return new Response(JSON.stringify({
                success: true,
                status: 'awaiting_verification',
                message: 'Votre paiement Wave est en cours de vérification côté serveur.',
                tokens_purchased: tx.tokens_purchased,
            }), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' },
                status: 200,
            });
        }

        // 4. Pour Stripe : vérification serveur-à-serveur auprès de l'API Stripe
        const stripeKey = Deno.env.get('STRIPE_SECRET_KEY');
        if (!stripeKey) throw new Error('STRIPE_SECRET_KEY non configurée');

        const envMode = Deno.env.get('ENVIRONMENT') ?? 'production';
        if (envMode === 'strict_live' && stripeKey.startsWith('sk_test_')) {
            throw new Error('Validation refusée : clé Stripe de test détectée en environnement de production');
        }

        const stripe = new Stripe(stripeKey, { apiVersion: '2022-11-15' });
        const paymentIntent = await stripe.paymentIntents.retrieve(payment_intent_id);

        // 4a. Vérification du statut
        if (paymentIntent.status !== 'succeeded') {
            throw new Error(`Le statut du paiement Stripe est '${paymentIntent.status}' (attendu: 'succeeded')`);
        }

        // 4b. Vérification que le PaymentIntent est bien en mode LIVE si strict_live activé
        if (envMode === 'strict_live' && !paymentIntent.livemode) {
            throw new Error('Tentative de validation d\'un paiement de test en production rejetée');
        }

        // 4c. Vérification stricte de la devise et du montant encaissé par Stripe
        const expectedPackage = TOKEN_PACKAGES[tx.tokens_purchased];
        if (!expectedPackage) {
            throw new Error('Forfait associé à la transaction invalide');
        }
        if (paymentIntent.currency.toLowerCase() !== 'usd' || paymentIntent.amount_received < expectedPackage.usd_cents) {
            console.error(`[SECURITY ALERT] Incohérence montant Stripe: reçu=${paymentIntent.amount_received} ${paymentIntent.currency}, attendu=${expectedPackage.usd_cents} usd`);
            throw new Error('Montant ou devise du paiement incohérent avec le forfait demandé');
        }

        // 4d. Vérification de propriété (anti-usurpation de PaymentIntent)
        if (paymentIntent.metadata?.user_id !== user.id) {
            throw new Error('Tentative de réclamation frauduleuse : ce paiement appartient à un autre compte');
        }

        // 5. Crédit atomique et idempotent en base de données (verrouillage FOR UPDATE)
        const { data: creditResult, error: creditError } = await adminClient.rpc(
            'credit_tokens_idempotent',
            {
                p_user_id: user.id,
                p_tokens: tx.tokens_purchased,
                p_payment_intent_id: payment_intent_id,
                p_amount_fcfa: tx.amount_fcfa,
                p_payment_method: 'stripe',
            }
        );

        if (creditError) {
            console.error('[confirm-token-purchase] Erreur crédit jetons:', creditError);
            throw new Error(`Échec de l'attribution des jetons : ${creditError.message}`);
        }

        console.log(`[confirm-token-purchase] Crédit confirmé: user=${user.id} ref=${payment_intent_id} tokens=${tx.tokens_purchased}`);

        return new Response(JSON.stringify({
            success: true,
            status: 'completed',
            message: `${tx.tokens_purchased} jetons crédités avec succès sur votre compte`,
            tokens_added: tx.tokens_purchased,
            new_balance: creditResult?.new_balance,
        }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 200,
        });

    } catch (error) {
        console.error('[confirm-token-purchase] Erreur:', error.message);
        return new Response(JSON.stringify({
            success: false,
            error: error.message,
        }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 400,
        });
    }
});
