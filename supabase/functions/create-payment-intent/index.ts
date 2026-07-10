/// <reference types="https://esm.sh/@supabase/functions-js/src/edge-runtime.d.ts" />
import Stripe from "npm:stripe@14";
import { createClient } from "npm:@supabase/supabase-js@2";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!, {
  apiVersion: "2024-06-20",
  httpClient: Stripe.createFetchHttpClient(),
});

const TROY_OZ_TO_GRAMS = 31.1035;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

// Live price per gram in SEK — same sources as the get-gold-price function.
// Used to reject PaymentIntents whose claimed gold amount doesn't match what
// is actually being paid.
async function fetchLivePricePerGramSek(): Promise<number> {
  const yahooRes = await fetch(
    "https://query1.finance.yahoo.com/v8/finance/chart/GC%3DF?interval=1d&range=1d",
    { headers: { "User-Agent": "Mozilla/5.0" } },
  );
  if (!yahooRes.ok) throw new Error(`Yahoo Finance ${yahooRes.status}`);
  const yahooData = await yahooRes.json();
  const pricePerOzUsd: number =
    yahooData?.chart?.result?.[0]?.meta?.regularMarketPrice;
  if (!pricePerOzUsd) throw new Error("Could not parse gold price");

  const fxRes = await fetch("https://api.frankfurter.app/latest?from=USD&to=SEK");
  if (!fxRes.ok) throw new Error(`Frankfurter ${fxRes.status}`);
  const fxData = await fxRes.json();
  const usdToSek: number = fxData?.rates?.SEK;
  if (!usdToSek) throw new Error("Could not parse USD/SEK rate");

  return (pricePerOzUsd * usdToSek) / TROY_OZ_TO_GRAMS;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // ── Authenticate the caller ────────────────────────────────────────────
    // The user id goes into the PaymentIntent metadata; the stripe-webhook
    // function credits that user once Stripe confirms the payment.
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return json({ error: "Not authenticated" }, 401);
    const supabaseAuth = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: userData, error: userError } =
      await supabaseAuth.auth.getUser();
    const user = userData?.user;
    if (userError || !user) return json({ error: "Not authenticated" }, 401);

    const body = await req.json();
    const {
      mode,
      amount,
      currency = "sek",
      purpose = "buy_gold", // 'buy_gold' | 'add_funds'
      goldGrams,
      pricePerGram,
      successUrl,
      cancelUrl,
      clientSecret,
      paymentMethodId,
    } = body;

    // ── Path B: Confirm existing PaymentIntent with a tokenised pm id ─────────
    // Used by flutter_stripe on mobile: CardField → createPaymentMethod → here.
    // Metadata was already attached and validated when the intent was created.
    if (clientSecret && paymentMethodId) {
      const piId = (clientSecret as string).split("_secret_")[0];
      const confirmed = await stripe.paymentIntents.confirm(piId, {
        payment_method: paymentMethodId,
      });
      return json({
        succeeded: confirmed.status === "succeeded",
        status: confirmed.status,
      });
    }

    // ── Validate the purchase before creating any payment object ──────────────
    if (!amount || typeof amount !== "number" || amount <= 0) {
      return json({ error: "Invalid amount" }, 400);
    }
    if (purpose !== "buy_gold" && purpose !== "add_funds") {
      return json({ error: "Invalid purpose" }, 400);
    }

    const metadata: Record<string, string> = {
      source: "guldly_app",
      user_id: user.id,
      purpose,
    };

    if (purpose === "buy_gold") {
      const grams = Number(goldGrams);
      const price = Number(pricePerGram);
      if (!grams || grams <= 0 || !price || price <= 0) {
        return json(
          { error: "buy_gold requires positive goldGrams and pricePerGram" },
          400,
        );
      }
      // grams × price must equal what is actually being paid (±1%).
      if (Math.abs(grams * price - amount) > Math.max(1, amount * 0.01)) {
        return json({ error: "Amount does not match goldGrams × pricePerGram" }, 400);
      }
      // The claimed price must be the real gold price (±5% for quote drift).
      const livePrice = await fetchLivePricePerGramSek();
      if (Math.abs(price - livePrice) > livePrice * 0.05) {
        return json({ error: "pricePerGram deviates from the live gold price" }, 400);
      }
      metadata.gold_grams = grams.toFixed(6);
      metadata.price_per_gram = price.toFixed(4);
    }

    // ── Path A: Web Checkout Session (redirect-based) ─────────────────────────
    // Used by Flutter web — avoids all flutter_stripe Platform issues.
    if (mode === "web_checkout") {
      const gramsStr = purpose === "buy_gold"
        ? `${Number(goldGrams).toFixed(4)}g of physical gold`
        : undefined;

      const session = await stripe.checkout.sessions.create({
        mode: "payment",
        payment_method_types: ["card"],
        client_reference_id: user.id,
        // On the PaymentIntent (not just the session) so the webhook's
        // payment_intent.succeeded handler covers this flow too.
        payment_intent_data: { metadata },
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

      return json({ checkoutUrl: session.url });
    }

    // ── Path C: Create new PaymentIntent, return client secret ────────────────
    // Used by flutter_stripe payment sheet on mobile.
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount * 100),
      currency,
      payment_method_types: ["card"],
      metadata,
    });

    return json({ clientSecret: paymentIntent.client_secret });
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    return json({ error: message }, 500);
  }
});
