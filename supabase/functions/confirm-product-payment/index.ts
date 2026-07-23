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

    const body = await req.json();
    const { payment_intent_id, order_id } = body;

    if (!payment_intent_id) throw new Error('Missing payment_intent_id');

    // Retrieve payment intent from Stripe to verify status
    const paymentIntent = await stripe.paymentIntents.retrieve(payment_intent_id);

    const paymentStatus = paymentIntent.status === 'succeeded' ? 'completed' : 
                          paymentIntent.status === 'canceled' ? 'failed' : 'pending';

    // Update order status
    const updateQuery = order_id
      ? supabase.from('product_orders').update({
          payment_status: paymentStatus,
          updated_at: new Date().toISOString(),
        }).eq('id', order_id)
      : supabase.from('product_orders').update({
          payment_status: paymentStatus,
          updated_at: new Date().toISOString(),
        }).eq('stripe_payment_intent_id', payment_intent_id);

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
