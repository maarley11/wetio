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

serve(async (req) => {
  const corsHeaders = getCorsHeaders(req);

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const stripeKey = Deno.env.get('STRIPE_SECRET_KEY')!;

    const authHeader = req.headers.get('Authorization');
    if (!authHeader) throw new Error('Missing Authorization header');

    const token = authHeader.replace('Bearer ', '');
    const { data: { user }, error: userError } = await createClient(supabaseUrl, supabaseAnonKey).auth.getUser(token);
    if (userError || !user) throw new Error('User not authenticated');

    const supabase = createClient(supabaseUrl, supabaseServiceKey);
    const stripe = new Stripe(stripeKey, { apiVersion: '2023-10-16' });

    const body = await req.json();
    const { payment_intent_id, order_id } = body;

    if (!payment_intent_id) throw new Error('Missing payment_intent_id');

    // Retrieve payment intent from Stripe server-side to verify status & buyer ownership
    const paymentIntent = await stripe.paymentIntents.retrieve(payment_intent_id);

    if (paymentIntent.metadata?.buyer_id && paymentIntent.metadata.buyer_id !== user.id) {
      throw new Error('Unauthorized: payment does not belong to current user');
    }

    const expectedCents = Number(paymentIntent.metadata?.expected_usd_cents || 0);
    if (expectedCents > 0 && paymentIntent.amount_received < expectedCents && paymentIntent.status === 'succeeded') {
      throw new Error('Amount received mismatch');
    }

    const paymentStatus = paymentIntent.status === 'succeeded' ? 'completed' : 
                          paymentIntent.status === 'canceled' ? 'failed' : 'pending';

    const updateQuery = order_id
      ? supabase.from('product_orders').update({
          payment_status: paymentStatus,
          updated_at: new Date().toISOString(),
        }).eq('id', order_id).eq('buyer_id', user.id)
      : supabase.from('product_orders').update({
          payment_status: paymentStatus,
          updated_at: new Date().toISOString(),
        }).eq('stripe_payment_intent_id', payment_intent_id).eq('buyer_id', user.id);

    const { error: updateError } = await updateQuery;

    if (updateError) {
      console.error('Order update error:', updateError);
    }

    return new Response(JSON.stringify({
      success: true,
      payment_status: paymentStatus,
      stripe_status: paymentIntent.status,
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });

  } catch (error) {
    console.error('confirm-product-payment error:', error.message);
    return new Response(JSON.stringify({
      success: false,
      error: error.message,
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    });
  }
});
