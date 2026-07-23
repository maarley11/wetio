import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.21.0';
import Stripe from 'https://esm.sh/stripe@12.0.0?target=deno';

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': '*'
};

serve(async (req) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders });
    }
    
    try {
        const supabase = createClient(
            Deno.env.get('SUPABASE_URL')!,
            Deno.env.get('SUPABASE_ANON_KEY')!
        );
        
        const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!);
        
        const authHeader = req.headers.get('Authorization');
        if (!authHeader) {
            throw new Error('Missing Authorization header');
        }

        const requestData = await req.json();
        const { payment_intent_id } = requestData;

        if (!payment_intent_id) {
            throw new Error('Missing payment_intent_id');
        }

        // Get user from auth
        const token = authHeader.replace('Bearer ', '');
        const { data: { user }, error: userError } = await supabase.auth.getUser(token);
        
        if (userError || !user) {
            throw new Error('User not authenticated');
        }

        // Get payment transaction from database
        const { data: paymentTransaction, error: fetchError } = await supabase
            .from('payment_transactions')
            .select('*')
            .eq('payment_intent_id', payment_intent_id)
            .eq('user_id', user.id)
            .single();

        if (fetchError || !paymentTransaction) {
            throw new Error('Payment transaction not found');
        }

        // Verify payment intent with Stripe ONLY if it's a stripe payment
        if (paymentTransaction.payment_method === 'stripe') {
            const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!);
            const paymentIntent = await stripe.paymentIntents.retrieve(payment_intent_id);
            
            if (paymentIntent.status !== 'succeeded') {
                throw new Error('Payment not completed successfully');
            }
        } else if (paymentTransaction.payment_method === 'wave') {
            // For Wave, we mark as awaiting_verification if it's currently pending
            if (paymentTransaction.payment_status === 'pending') {
                await supabase
                    .from('payment_transactions')
                    .update({ payment_status: 'awaiting_verification' })
                    .eq('id', paymentTransaction.id);
            }
            
            return new Response(JSON.stringify({
                success: true,
                status: 'awaiting_verification',
                message: 'Votre paiement est en attente de validation par l\'administrateur.',
                tokens_added: paymentTransaction.tokens_purchased
            }), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' },
                status: 200
            });
        }

        if (paymentTransaction.payment_status === 'completed') {
            return new Response(JSON.stringify({
                success: true,
                status: 'completed',
                message: 'Tokens already added to account',
                tokens_added: paymentTransaction.tokens_purchased
            }), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' },
                status: 200
            });
        }

        // Add tokens to user account (only for automatic methods like Stripe)
        const { data: tokenResult, error: tokenError } = await supabase
            .rpc('add_tokens_after_payment', {
                user_uuid: user.id,
                tokens_to_add: paymentTransaction.tokens_purchased,
                payment_reference: payment_intent_id
            });

        if (tokenError) {
            throw new Error(`Failed to add tokens: ${tokenError.message}`);
        }

        // Update payment transaction status
        const { error: updateError } = await supabase
            .from('payment_transactions')
            .update({
                payment_status: 'completed',
                completed_at: new Date().toISOString()
            })
            .eq('id', paymentTransaction.id);

        if (updateError) {
            console.error('Failed to update payment status:', updateError);
        }

        return new Response(JSON.stringify({
            success: true,
            status: 'completed',
            message: 'Jetons ajoutés avec succès à votre compte',
            tokens_added: paymentTransaction.tokens_purchased,
            new_balance: tokenResult ? tokenResult.new_balance : null
        }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 200
        });

    } catch (error) {
        console.error('Confirm token purchase error:', error.message);
        return new Response(JSON.stringify({
            success: false,
            error: error.message
        }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 400
        });
    }
});