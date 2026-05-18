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
    const {
      amount,
      currency = "sek",
      cardNumber,
      expMonth,
      expYear,
      cvc,
      name,
    } = await req.json();

    if (!amount || typeof amount !== "number" || amount <= 0) {
      return new Response(JSON.stringify({ error: "Invalid amount" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // If card details are provided, confirm the payment server-side
    // (secret key has no tokenization surface restrictions)
    if (cardNumber && expMonth && expYear && cvc) {
      const paymentMethod = await stripe.paymentMethods.create({
        type: "card",
        card: {
          number: String(cardNumber).replace(/\s/g, ""),
          exp_month: Number(expMonth),
          exp_year: Number(expYear),
          cvc: String(cvc),
        },
        billing_details: { name: name ?? "" },
      });

      const paymentIntent = await stripe.paymentIntents.create({
        amount: Math.round(amount * 100),
        currency,
        payment_method_types: ["card"],
        payment_method: paymentMethod.id,
        confirm: true,
        metadata: { source: "guldly_app" },
      });

      const succeeded = paymentIntent.status === "succeeded";
      return new Response(
        JSON.stringify({ succeeded, status: paymentIntent.status }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Mobile path: just create the PaymentIntent and let flutter_stripe confirm it
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
