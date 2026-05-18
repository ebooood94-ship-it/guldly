/// <reference types="https://esm.sh/@supabase/functions-js/src/edge-runtime.d.ts" />
import Stripe from "npm:stripe@14";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!, {
  apiVersion: "2024-06-20",
  httpClient: Stripe.createFetchHttpClient(),
});

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json();
    const {
      mode,
      amount,
      currency = "sek",
      goldGrams,
      successUrl,
      cancelUrl,
      clientSecret,
      paymentMethodId,
    } = body;

    // ── Path A: Web Checkout Session (redirect-based) ─────────────────────────
    // Used by Flutter web — avoids all flutter_stripe Platform issues.
    if (mode === "web_checkout") {
      if (!amount || typeof amount !== "number" || amount <= 0) {
        return new Response(JSON.stringify({ error: "Invalid amount" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      const gramsStr = goldGrams != null
        ? `${Number(goldGrams).toFixed(4)}g of physical gold`
        : undefined;

      const session = await stripe.checkout.sessions.create({
        mode: "payment",
        payment_method_types: ["card"],
        line_items: [
          {
            price_data: {
              currency,
              product_data: {
                name: "Guldly – Gold Purchase",
                ...(gramsStr ? { description: gramsStr } : {}),
              },
              unit_amount: Math.round(amount * 100),
            },
            quantity: 1,
          },
        ],
        success_url: successUrl,
        cancel_url: cancelUrl,
      });

      return new Response(
        JSON.stringify({ checkoutUrl: session.url }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // ── Path B: Confirm existing PaymentIntent with a tokenised pm id ─────────
    // Used by flutter_stripe on mobile: CardField → createPaymentMethod → here.
    if (clientSecret && paymentMethodId) {
      const piId = (clientSecret as string).split("_secret_")[0];
      const confirmed = await stripe.paymentIntents.confirm(piId, {
        payment_method: paymentMethodId,
      });
      return new Response(
        JSON.stringify({
          succeeded: confirmed.status === "succeeded",
          status: confirmed.status,
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // ── Path C: Create new PaymentIntent, return client secret ────────────────
    // Used by flutter_stripe payment sheet on mobile.
    if (!amount || typeof amount !== "number" || amount <= 0) {
      return new Response(JSON.stringify({ error: "Invalid amount" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount * 100),
      currency,
      payment_method_types: ["card"],
      metadata: { source: "guldly_app" },
    });

    return new Response(
      JSON.stringify({ clientSecret: paymentIntent.client_secret }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
