import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.21.0';
import Stripe from 'https://esm.sh/stripe@12.0.0?target=deno';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': '*',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const stripeKey = Deno.env.get('STRIPE_SECRET_KEY')!;

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
      seller_id,
      amount_fcfa,
      quantity = 1,
      delivery_method = 'standard',
      delivery_fee_fcfa = 0,
      total_fcfa,
    } = body;

    if (!product_id || !seller_id || !amount_fcfa || !total_fcfa) {
      throw new Error('Missing required fields: product_id, seller_id, amount_fcfa, total_fcfa');
    }

    // Get seller's Stripe Connect account
    const { data: sellerProfile, error: sellerError } = await supabase
      .from('user_profiles')
      .select('stripe_connect_account_id, full_name')
      .eq('id', seller_id)
      .single();

    if (sellerError) throw new Error('Seller not found');

    // Convert FCFA to USD cents for Stripe (1 USD ≈ 600 FCFA approximately)
    // Using a fixed conversion rate — in production, use a live rate API
    const FCFA_TO_USD_RATE = 600;
    const amountUsdCents = Math.round((total_fcfa / FCFA_TO_USD_RATE) * 100);
    const minimumAmount = 50; // Stripe minimum: 50 cents USD

    const finalAmountCents = Math.max(amountUsdCents, minimumAmount);

    let paymentIntentParams: Stripe.PaymentIntentCreateParams = {
      amount: finalAmountCents,
      currency: 'usd',
      automatic_payment_methods: { enabled: true },
      description: `Achat produit WETIO - ${quantity}x article`,
      metadata: {
        product_id,
        seller_id,
        buyer_id: user.id,
        amount_fcfa: total_fcfa.toString(),
        quantity: quantity.toString(),
        delivery_method,
        platform: 'wetio',
        commission_rate: '0', // 0% commission for WETIO
      },
    };

    // If seller has a Stripe Connect account, send money directly to them (0% commission)
    if (sellerProfile?.stripe_connect_account_id) {
      paymentIntentParams = {
        ...paymentIntentParams,
        transfer_data: {
          destination: sellerProfile.stripe_connect_account_id,
        },
        // 0% application_fee_amount means WETIO takes nothing
        application_fee_amount: 0,
      };
    }

    const paymentIntent = await stripe.paymentIntents.create(paymentIntentParams);

    // Save order record
    const { data: order, error: orderError } = await supabase
      .from('product_orders')
      .insert({
        buyer_id: user.id,
        seller_id,
        product_id,
        stripe_payment_intent_id: paymentIntent.id,
        amount_fcfa,
        quantity,
        delivery_method,
        delivery_fee_fcfa,
        total_fcfa,
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
