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

const DELIVERY_FEES_FCFA: Record<string, number> = {
  pickup: 0,
  retrait: 0,
  standard: 2000,
  express: 3500,
};

serve(async (req) => {
  const corsHeaders = getCorsHeaders(req);

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const stripeKey = Deno.env.get('STRIPE_SECRET_KEY')!;

    const envMode = Deno.env.get('ENVIRONMENT') ?? 'production';
    if (envMode === 'strict_live' && stripeKey.startsWith('sk_test_')) {
      throw new Error('Configuration de paiement indisponible (clé de test détectée en production).');
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);
    const stripe = new Stripe(stripeKey, { apiVersion: '2023-10-16' });

    // Authenticate buyer
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) throw new Error('Missing Authorization header');

    const token = authHeader.replace('Bearer ', '');
    const { data: { user }, error: userError } = await createClient(supabaseUrl, Deno.env.get('SUPABASE_ANON_KEY')!).auth.getUser(token);
    if (userError || !user) throw new Error('User not authenticated');

    const body = await req.json();
    const {
      product_id,
      quantity = 1,
      delivery_method = 'standard',
    } = body;

    if (!product_id) {
      throw new Error('Missing required field: product_id');
    }

    const safeQuantity = Math.max(1, Math.min(20, Math.floor(Number(quantity) || 1)));

    // LECTURE SERVEUR DU PRIX DU PRODUIT ET DU VENDEUR (JAMAIS DE CONFIANCE AU CLIENT)
    const { data: productRecord, error: productError } = await supabase
      .from('products')
      .select('id, title, price, owner_id, is_active')
      .eq('id', product_id)
      .single();

    if (productError || !productRecord || productRecord.is_active === false) {
      throw new Error('Produit introuvable ou indisponible');
    }

    const unitPriceFcfa = Number(productRecord.price);
    if (!unitPriceFcfa || unitPriceFcfa <= 0) {
      throw new Error('Ce produit n\'a pas de prix de vente valide');
    }

    const seller_id = productRecord.owner_id;
    const serverDeliveryFeeFcfa = DELIVERY_FEES_FCFA[delivery_method] ?? 2000;
    const serverAmountFcfa = unitPriceFcfa * safeQuantity;
    const serverTotalFcfa = serverAmountFcfa + serverDeliveryFeeFcfa;

    // Get seller's Stripe Connect account
    const { data: sellerProfile, error: sellerError } = await supabase
      .from('user_profiles')
      .select('stripe_connect_account_id, full_name')
      .eq('id', seller_id)
      .single();

    if (sellerError) throw new Error('Seller not found');

    // Convert FCFA to USD cents for Stripe (1 USD ≈ 600 FCFA)
    const FCFA_TO_USD_RATE = 600;
    const amountUsdCents = Math.round((serverTotalFcfa / FCFA_TO_USD_RATE) * 100);
    const minimumAmount = 50; // Stripe minimum: 50 cents USD
    const finalAmountCents = Math.max(amountUsdCents, minimumAmount);

    let paymentIntentParams: Stripe.PaymentIntentCreateParams = {
      amount: finalAmountCents,
      currency: 'usd',
      automatic_payment_methods: { enabled: true },
      description: `Achat produit WETIO (${productRecord.title}) - ${safeQuantity}x article`,
      metadata: {
        product_id,
        seller_id,
        buyer_id: user.id,
        amount_fcfa: serverTotalFcfa.toString(),
        expected_usd_cents: finalAmountCents.toString(),
        quantity: safeQuantity.toString(),
        delivery_method,
        platform: 'wetio',
        commission_rate: '0',
      },
    };

    if (sellerProfile?.stripe_connect_account_id) {
      paymentIntentParams = {
        ...paymentIntentParams,
        transfer_data: {
          destination: sellerProfile.stripe_connect_account_id,
        },
        application_fee_amount: 0,
      };
    }

    const idempotencyKey = req.headers.get('x-idempotency-key') || `prod_${user.id}_${product_id}_${safeQuantity}_${Math.floor(Date.now() / 60000)}`;
    const paymentIntent = await stripe.paymentIntents.create(paymentIntentParams, { idempotencyKey });

    // Save order record
    const { data: order, error: orderError } = await supabase
      .from('product_orders')
      .insert({
        buyer_id: user.id,
        seller_id,
        product_id,
        stripe_payment_intent_id: paymentIntent.id,
        amount_fcfa: serverAmountFcfa,
        quantity: safeQuantity,
        delivery_method,
        delivery_fee_fcfa: serverDeliveryFeeFcfa,
        total_fcfa: serverTotalFcfa,
        payment_status: 'pending',
      })
      .select()
      .single();

    if (orderError) {
      console.error('Order creation error:', orderError);
      throw new Error('Failed to create order record');
    }

    return new Response(JSON.stringify({
      success: true,
      client_secret: paymentIntent.client_secret,
      payment_intent_id: paymentIntent.id,
      order_id: order.id,
      total_fcfa: serverTotalFcfa,
      seller_has_connect: !!sellerProfile?.stripe_connect_account_id,
      message: 'Paiement créé — 0% de commission WETIO',
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });

  } catch (error) {
    console.error('create-product-payment error:', error.message);
    return new Response(JSON.stringify({
      success: false,
      error: error.message,
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    });
  }
});
