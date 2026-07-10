/// <reference types="https://esm.sh/@supabase/functions-js/src/edge-runtime.d.ts" />
// Stripe webhook — the ONLY path that credits card payments.
//
// Deployed with verify_jwt = false: Stripe cannot send a Supabase JWT.
// Authentication is the Stripe signature check below instead.
//
// Required secrets (supabase secrets set ...):
//   STRIPE_SECRET_KEY      — already used by create-payment-intent
//   STRIPE_WEBHOOK_SECRET  — whsec_... from the Stripe endpoint / `stripe listen`
import Stripe from "npm:stripe@14";
import { createClient } from "npm:@supabase/supabase-js@2";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!, {
  apiVersion: "2024-06-20",
  httpClient: Stripe.createFetchHttpClient(),
});

// Deno has no synchronous crypto; Stripe needs the SubtleCrypto provider
// together with constructEventAsync.
const cryptoProvider = Stripe.createSubtleCryptoProvider();

// Service-role client: bypasses RLS and is the only role granted
// EXECUTE on confirm_stripe_payment.
const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const signature = req.headers.get("stripe-signature");
  if (!signature) {
    return new Response("Missing stripe-signature header", { status: 400 });
  }

  const body = await req.text();
  let event: Stripe.Event;
  try {
    event = await stripe.webhooks.constructEventAsync(
      body,
      signature,
      Deno.env.get("STRIPE_WEBHOOK_SECRET")!,
      undefined,
      cryptoProvider,
    );
  } catch (err) {
    console.error("Webhook signature verification failed:", err);
    return new Response("Invalid signature", { status: 400 });
  }

  // Checkout Sessions also end in payment_intent.succeeded (metadata is set
  // via payment_intent_data.metadata), so one event type covers both flows
  // and there is exactly one crediting path per payment.
  if (event.type !== "payment_intent.succeeded") {
    return new Response(
      JSON.stringify({ received: true, ignored: event.type }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  }

  const pi = event.data.object as Stripe.PaymentIntent;
  const meta = pi.metadata ?? {};
  const userId = meta.user_id;
  const purpose = meta.purpose; // 'buy_gold' | 'add_funds'

  if (!userId || !purpose) {
    // Not created by the Guldly app (or a legacy intent) — acknowledge so
    // Stripe stops retrying, but credit nothing.
    console.warn(`payment_intent.succeeded ${pi.id} without Guldly metadata; skipped`);
    return new Response(
      JSON.stringify({ received: true, skipped: "missing metadata" }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  }

  // Trust Stripe for the amount, never the metadata.
  const amountSek = pi.amount_received / 100;
  const goldGrams = meta.gold_grams ? Number(meta.gold_grams) : null;
  const pricePerGram = meta.price_per_gram ? Number(meta.price_per_gram) : null;

  const { data, error } = await supabase.rpc("confirm_stripe_payment", {
    p_user_id: userId,
    p_payment_intent_id: pi.id,
    p_purpose: purpose,
    p_amount_sek: amountSek,
    p_gold_grams: goldGrams,
    p_price_per_gram: pricePerGram,
  });

  if (error) {
    console.error(`confirm_stripe_payment failed for ${pi.id}:`, error.message);
    // 500 → Stripe retries with backoff; safe because crediting is idempotent.
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  console.log(`payment ${pi.id}: ${data} (user ${userId}, ${purpose}, ${amountSek} SEK)`);
  return new Response(JSON.stringify({ received: true, result: data }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
