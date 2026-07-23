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

    // Authenticate user
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) throw new Error('Missing Authorization header');

    const token = authHeader.replace('Bearer ', '');
    const { data: { user }, error: userError } = await createClient(
      supabaseUrl,
      Deno.env.get('SUPABASE_ANON_KEY')!
    ).auth.getUser(token);
    if (userError || !user) throw new Error('User not authenticated');

    const body = await req.json();
    const { return_url, refresh_url } = body;

    // Check if user already has a Stripe Connect account
    const { data: profile } = await supabase
      .from('user_profiles')
      .select('stripe_connect_account_id, full_name, email')
      .eq('id', user.id)
      .single();

    let accountId = profile?.stripe_connect_account_id;

    // Create Stripe Connect account if not exists
    if (!accountId) {
      const account = await stripe.accounts.create({
        type: 'express',
        country: 'SN', // Sénégal — fallback to FR if SN not supported
        email: user.email,
        capabilities: {
          card_payments: { requested: true },
          transfers: { requested: true },
        },
        business_type: 'individual',
        metadata: {
          user_id: user.id,
          platform: 'wetio',
        },
      }).catch(async () => {
        // Fallback: create without country restriction
        return await stripe.accounts.create({
          type: 'express',
          email: user.email,
          capabilities: {
            card_payments: { requested: true },
            transfers: { requested: true },
          },
          business_type: 'individual',
          metadata: {
            user_id: user.id,
            platform: 'wetio',
          },
        });
      });

      accountId = account.id;

      // Save account ID to user profile
      await supabase
        .from('user_profiles')
        .update({ stripe_connect_account_id: accountId })
        .eq('id', user.id);
    }

    // Check account status
    const account = await stripe.accounts.retrieve(accountId);
    const isOnboarded = account.details_submitted && account.charges_enabled;

    if (isOnboarded) {
      // Account already fully onboarded — create a login link to dashboard
      const loginLink = await stripe.accounts.createLoginLink(accountId);
      return new Response(JSON.stringify({
        success: true,
        already_onboarded: true,
        url: loginLink.url,
        charges_enabled: account.charges_enabled,
        details_submitted: account.details_submitted,
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      });
    }

    // Create onboarding link
    const accountLink = await stripe.accountLinks.create({
      account: accountId,
      refresh_url: refresh_url || 'https://wetio4029.builtwithrocket.new',
      return_url: return_url || 'https://wetio4029.builtwithrocket.new',
      type: 'account_onboarding',
    });

    return new Response(JSON.stringify({
      success: true,
      already_onboarded: false,
      url: accountLink.url,
      account_id: accountId,
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });

  } catch (error) {
    console.error('create-stripe-connect-link error:', error.message);
    return new Response(JSON.stringify({
      success: false,
      error: error.message,
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    });
  }
});
