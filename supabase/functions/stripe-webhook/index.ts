import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.21.0';
import Stripe from 'https://esm.sh/stripe@12.0.0?target=deno';

const TOKEN_PACKAGES: Record<number, { fcfa: number; usd_cents: number }> = {
    50:   { fcfa: 500,   usd_cents: 90 },
    100:  { fcfa: 1000,  usd_cents: 180 },
    250:  { fcfa: 2500,  usd_cents: 450 },
    300:  { fcfa: 2500,  usd_cents: 450 },
    500:  { fcfa: 4000,  usd_cents: 720 },
    1000: { fcfa: 7500,  usd_cents: 1350 },
};

serve(async (req) => {
    const signature = req.headers.get('stripe-signature');
    if (!signature) {
        return new Response('Missing stripe-signature header', { status: 400 });
    }

    try {
        const stripeKey = Deno.env.get('STRIPE_SECRET_KEY')!;
        const webhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET')!;
        const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
        const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

        if (!stripeKey || !webhookSecret) {
            console.error('[Stripe Webhook] STRIPE_SECRET_KEY ou STRIPE_WEBHOOK_SECRET manquant');
            return new Response('Server configuration error', { status: 500 });
        }

        const stripe = new Stripe(stripeKey, { apiVersion: '2022-11-15' });
        const adminClient = createClient(supabaseUrl, supabaseServiceRoleKey);

        const body = await req.text();
        // Vérification cryptographique de la signature du webhook Stripe
        const event = await stripe.webhooks.constructEventAsync(body, signature, webhookSecret);

        if (event.type === 'payment_intent.succeeded') {
            const paymentIntent = event.data.object as Stripe.PaymentIntent;
            const purchaseType = paymentIntent.metadata?.purchase_type;
            const userId = paymentIntent.metadata?.user_id;
            const tokens = Number(paymentIntent.metadata?.tokens_to_purchase);
            const amountFcfa = Number(paymentIntent.metadata?.amount_fcfa);

            // Cas 1 : Achat de jetons
            if (userId && tokens > 0 && (purchaseType === 'tokens' || TOKEN_PACKAGES[tokens])) {
                const expectedPackage = TOKEN_PACKAGES[tokens];
                if (!expectedPackage || paymentIntent.currency.toLowerCase() !== 'usd' || paymentIntent.amount_received < expectedPackage.usd_cents) {
                    console.error(`[Stripe Webhook] Montant invalide pour ${paymentIntent.id}: reçu=${paymentIntent.amount_received}, attendu=${expectedPackage?.usd_cents}`);
                    return new Response('Invalid amount or currency', { status: 400 });
                }

                console.log(`[Stripe Webhook] Crédit idempotent pour user=${userId} : ${tokens} jetons (${paymentIntent.id})`);

                const { error } = await adminClient.rpc('credit_tokens_idempotent', {
                    p_user_id: userId,
                    p_tokens: tokens,
                    p_payment_intent_id: paymentIntent.id,
                    p_amount_fcfa: amountFcfa || expectedPackage.fcfa,
                    p_payment_method: 'stripe',
                });

                if (error) {
                    console.error('[Stripe Webhook] Erreur credit_tokens_idempotent:', error);
                    return new Response('Database error', { status: 500 });
                }
            }

            // Cas 2 : Achat de produit
            if (paymentIntent.metadata?.product_id) {
                await adminClient
                    .from('product_orders')
                    .update({
                        payment_status: 'completed',
                        updated_at: new Date().toISOString(),
                    })
                    .eq('stripe_payment_intent_id', paymentIntent.id);
            }
        } else if (event.type === 'payment_intent.payment_failed') {
            const paymentIntent = event.data.object as Stripe.PaymentIntent;
            await adminClient
                .from('payment_transactions')
                .update({
                    payment_status: 'failed',
                    updated_at: new Date().toISOString(),
                })
                .eq('payment_intent_id', paymentIntent.id);
        }

        return new Response(JSON.stringify({ received: true }), {
            headers: { 'Content-Type': 'application/json' },
            status: 200,
        });
    } catch (err) {
        console.error('[Stripe Webhook Error]:', err.message);
        return new Response(`Webhook Error: ${err.message}`, { status: 400 });
    }
});
