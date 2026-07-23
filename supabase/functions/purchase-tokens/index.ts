import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.21.0';
import Stripe from 'https://esm.sh/stripe@12.0.0?target=deno';

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': '*' // DO NOT CHANGE THIS
};

serve(async (req) => {
    // Handle CORS preflight request
    if (req.method === 'OPTIONS') {
        return new Response('ok', {
            headers: corsHeaders
        });
    }
    
    try {
        // Create a Supabase client
        const supabaseUrl = Deno.env.get('SUPABASE_URL');
        const supabaseKey = Deno.env.get('SUPABASE_ANON_KEY');
        const supabase = createClient(supabaseUrl, supabaseKey);
        
        // Get the authorization header for user authentication
        const authHeader = req.headers.get('Authorization');
        if (!authHeader) {
            throw new Error('Missing Authorization header');
        }

        // Get the request body
        const requestData = await req.json();
        const { tokens_to_purchase = 100, amount_fcfa = 1000, payment_method = 'stripe' } = requestData;

        // Validate input data
        if (typeof tokens_to_purchase !== 'number' || tokens_to_purchase <= 0) {
            throw new Error('Invalid tokens_to_purchase: Must be a positive number');
        }
        if (typeof amount_fcfa !== 'number' || amount_fcfa <= 0) {
            throw new Error('Invalid amount_fcfa: Must be a positive number');
        }

        // Get user information from the JWT token
        const token = authHeader.replace('Bearer ', '');
        const { data: { user }, error: userError } = await supabase.auth.getUser(token);
        
        if (userError || !user) {
            throw new Error('User not authenticated or token invalid');
        }

        let paymentIntent = null;
        let paymentIntentId = `WAVE_${user.id}_${Date.now()}`;
        let clientSecret = null;

        if (payment_method === 'stripe') {
            // Create a Stripe client
            const stripeKey = Deno.env.get('STRIPE_SECRET_KEY');
            if (!stripeKey) throw new Error('Stripe secret key not configured');
            const stripe = new Stripe(stripeKey);

            // Create a Stripe payment intent
            paymentIntent = await stripe.paymentIntents.create({
                amount: Math.round(amount_fcfa * 100), 
                currency: 'usd', 
                automatic_payment_methods: { enabled: true },
                description: `Achat de ${tokens_to_purchase} jetons WETIO`,
                metadata: {
                    user_id: user.id,
                    tokens_to_purchase: tokens_to_purchase.toString(),
                    amount_fcfa: amount_fcfa.toString(),
                    purchase_type: 'tokens'
                }
            });
            paymentIntentId = paymentIntent.id;
            clientSecret = paymentIntent.client_secret;
        }

        // Create payment transaction record in database
        let paymentTransaction = { id: null };
        try {
            const { data, error: paymentError } = await supabase
                .from('payment_transactions')
                .insert({
                    user_id: user.id,
                    payment_intent_id: paymentIntentId,
                    amount_fcfa: amount_fcfa,
                    tokens_purchased: tokens_to_purchase,
                    payment_status: payment_method === 'wave' ? 'awaiting_verification' : 'pending',
                    payment_method: payment_method
                })
                .select()
                .single();

            if (paymentError) {
                console.error('Database Error (Non-blocking):', paymentError);
                // We don't throw here to avoid blocking the user redirect
            } else {
                paymentTransaction = data;
            }
        } catch (dbErr) {
            console.error('Database exception (Non-blocking):', dbErr);
        }

        // Return the payment intent info or Wave info
        return new Response(JSON.stringify({
            success: true,
            client_secret: clientSecret,
            payment_intent_id: paymentIntentId,
            payment_transaction_id: paymentTransaction.id,
            tokens_to_purchase,
            amount_fcfa,
            payment_url: payment_method === 'wave' ? 'https://pay.wave.com/m/M_sn_F7IKNV0jou_P/c/sn/' : null,
            message: `Paiement créé pour ${tokens_to_purchase} jetons via ${payment_method}`
        }), {
            headers: {
                ...corsHeaders,
                'Content-Type': 'application/json'
            },
            status: 200
        });
        
    } catch (error) {
        console.error('Purchase tokens error:', error.message);
        return new Response(JSON.stringify({
            success: false,
            error: error.message
        }), {
            headers: {
                ...corsHeaders,
                'Content-Type': 'application/json'
            },
            status: 400
        });
    }
});