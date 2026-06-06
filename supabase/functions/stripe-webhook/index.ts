// Stripe → Supabase webhook handler
//
// DEPLOY:
//   supabase functions deploy stripe-webhook --no-verify-jwt
//
// ENV VARS (set in Supabase dashboard → Settings → Edge Functions):
//   STRIPE_SECRET_KEY     = sk_live_xxx
//   STRIPE_WEBHOOK_SECRET = whsec_xxx   (from Stripe dashboard → Webhooks)
//
// STRIPE SETUP:
//   1. Stripe dashboard → Webhooks → Add endpoint
//   2. URL: https://YOUR_PROJECT_ID.supabase.co/functions/v1/stripe-webhook
//   3. Events to listen: checkout.session.completed, customer.subscription.deleted

import Stripe from 'https://esm.sh/stripe@14.21.0?target=deno';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') ?? '', {
  apiVersion: '2024-06-20',
  httpClient: Stripe.createFetchHttpClient(),
});

const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
);

Deno.serve(async (req) => {
  const signature = req.headers.get('stripe-signature');
  const body = await req.text();
  const webhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET') ?? '';

  let event: Stripe.Event;
  try {
    event = await stripe.webhooks.constructEventAsync(body, signature!, webhookSecret);
  } catch (err) {
    console.error('Webhook signature verification failed:', err);
    return new Response('Webhook Error', { status: 400 });
  }

  if (event.type === 'checkout.session.completed') {
    const session = event.data.object as Stripe.Checkout.Session;
    const userId = session.client_reference_id; // passed when creating the Checkout Session
    const customerEmail = session.customer_details?.email;
    // session.customer is a string ID in webhook payloads; guard for the full object form
    const customerId = typeof session.customer === 'string'
      ? session.customer
      : (session.customer as { id?: string } | null)?.id ?? null;

    const patch: Record<string, unknown> = { isPro: true };
    if (customerId) patch.stripeCustomerId = customerId;

    if (userId) {
      await _mergeState(userId, patch);
      console.log(`Pro unlocked for user ${userId} (customer ${customerId})`);
    } else if (customerEmail) {
      // Fallback: look up by email when client_reference_id was not set
      const { data: user } = await supabase.auth.admin.getUserByEmail(customerEmail);
      if (user?.user?.id) {
        await _mergeState(user.user.id, patch);
        console.log(`Pro unlocked via email fallback for ${customerEmail}`);
      }
    }
  }

  if (event.type === 'customer.subscription.deleted') {
    const sub = event.data.object as Stripe.Subscription;
    const customerId = sub.customer as string;

    const { data: rows } = await supabase
      .from('neuro_state')
      .select('user_id')
      .eq('state_json->>stripeCustomerId', customerId)
      .limit(1);

    if (rows?.[0]?.user_id) {
      await _mergeState(rows[0].user_id, { isPro: false });
      console.log(`Pro revoked for user ${rows[0].user_id} (customer ${customerId})`);
    } else {
      console.warn(`customer.subscription.deleted: no user found for customer ${customerId}`);
    }
  }

  return new Response('ok', { status: 200 });
});

// Shallow-merges `patch` into the existing state_json for the given user.
async function _mergeState(userId: string, patch: Record<string, unknown>) {
  const { data: row } = await supabase
    .from('neuro_state')
    .select('state_json')
    .eq('user_id', userId)
    .single();

  const existing = (row?.state_json as Record<string, unknown>) ?? {};
  await supabase.from('neuro_state').upsert({
    user_id: userId,
    state_json: { ...existing, ...patch },
    updated_at: new Date().toISOString(),
  });
}
