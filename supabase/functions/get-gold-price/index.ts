/// <reference types="https://esm.sh/@supabase/functions-js/src/edge-runtime.d.ts" />

// No API keys required — both sources are completely free and unlimited.
//
// Gold price:  Yahoo Finance (GC=F gold futures)
// USD → SEK:   Frankfurter (European Central Bank rates)

const TROY_OZ_TO_GRAMS = 31.1035;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // ── Step 1: Gold price in USD from Yahoo Finance (GC=F futures) ──────────
    const yahooRes = await fetch(
      "https://query1.finance.yahoo.com/v8/finance/chart/GC%3DF?interval=1d&range=1d",
      { headers: { "User-Agent": "Mozilla/5.0" } }
    );
    if (!yahooRes.ok) {
      throw new Error(`Yahoo Finance ${yahooRes.status}: ${await yahooRes.text()}`);
    }
    const yahooData = await yahooRes.json();
    const pricePerOzUsd: number =
      yahooData?.chart?.result?.[0]?.meta?.regularMarketPrice;
    if (!pricePerOzUsd) {
      throw new Error("Yahoo Finance: could not parse gold price");
    }

    // ── Step 2: USD → SEK from Frankfurter (ECB rates, always free) ──────────
    const fxRes = await fetch(
      "https://api.frankfurter.app/latest?from=USD&to=SEK"
    );
    if (!fxRes.ok) {
      throw new Error(`Frankfurter ${fxRes.status}: ${await fxRes.text()}`);
    }
    const fxData = await fxRes.json();
    const usdToSek: number = fxData?.rates?.SEK;
    if (!usdToSek) {
      throw new Error("Frankfurter: could not parse USD/SEK rate");
    }

    return new Response(
      JSON.stringify({ pricePerOzUsd, usdToSek }),
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
