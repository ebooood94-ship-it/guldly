-- ============================================================
-- Guldly — Migration 003
-- Server-verified Stripe crediting.
--
-- Card payments are now credited ONLY by the stripe-webhook edge
-- function (service role) after Stripe confirms the payment.
-- Clients can no longer credit gold/balance by claiming a card
-- payment succeeded.
-- ============================================================

-- ─── 1. Idempotency key for Stripe payments ─────────────────────────────────
-- UNIQUE allows multiple NULLs, so non-Stripe transactions are unaffected.
ALTER TABLE transactions ADD COLUMN stripe_payment_intent_id TEXT;
ALTER TABLE transactions
  ADD CONSTRAINT transactions_stripe_payment_intent_id_key
  UNIQUE (stripe_payment_intent_id);

-- ─── 2. Webhook crediting function (service_role only) ──────────────────────
-- Called by supabase/functions/stripe-webhook on payment_intent.succeeded.
-- Idempotent: a PaymentIntent id can only ever credit once.
CREATE OR REPLACE FUNCTION confirm_stripe_payment(
  p_user_id           UUID,
  p_payment_intent_id TEXT,
  p_purpose           TEXT,             -- 'buy_gold' | 'add_funds'
  p_amount_sek        NUMERIC,
  p_gold_grams        NUMERIC DEFAULT NULL,
  p_price_per_gram    NUMERIC DEFAULT NULL
) RETURNS TEXT
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_inserted UUID;
BEGIN
  IF p_purpose NOT IN ('buy_gold', 'add_funds') THEN
    RAISE EXCEPTION 'Unknown purpose: %', p_purpose;
  END IF;
  IF p_payment_intent_id IS NULL OR p_payment_intent_id = '' THEN
    RAISE EXCEPTION 'Missing payment intent id';
  END IF;
  IF p_amount_sek IS NULL OR p_amount_sek <= 0 THEN
    RAISE EXCEPTION 'Invalid amount: %', p_amount_sek;
  END IF;
  IF p_purpose = 'buy_gold' AND (p_gold_grams IS NULL OR p_gold_grams <= 0) THEN
    RAISE EXCEPTION 'buy_gold requires positive gold_grams';
  END IF;

  INSERT INTO transactions
    (user_id, type, status, amount_sek, gold_grams, gold_price_per_gram_sek,
     payment_method, stripe_payment_intent_id)
  VALUES
    (p_user_id,
     CASE p_purpose WHEN 'buy_gold' THEN 'buy'::transaction_type
                    ELSE 'add_funds'::transaction_type END,
     'completed',
     p_amount_sek,
     CASE p_purpose WHEN 'buy_gold' THEN p_gold_grams ELSE NULL END,
     CASE p_purpose WHEN 'buy_gold' THEN p_price_per_gram ELSE NULL END,
     'credit_card',
     p_payment_intent_id)
  ON CONFLICT (stripe_payment_intent_id) DO NOTHING
  RETURNING id INTO v_inserted;

  -- Stripe retries webhooks; only credit on the first delivery.
  IF v_inserted IS NULL THEN
    RETURN 'duplicate';
  END IF;

  IF p_purpose = 'buy_gold' THEN
    INSERT INTO wallets (user_id, balance_sek, gold_grams)
    VALUES (p_user_id, 0, p_gold_grams)
    ON CONFLICT (user_id) DO UPDATE
      SET gold_grams = wallets.gold_grams + EXCLUDED.gold_grams;
  ELSE
    INSERT INTO wallets (user_id, balance_sek, gold_grams)
    VALUES (p_user_id, p_amount_sek, 0)
    ON CONFLICT (user_id) DO UPDATE
      SET balance_sek = wallets.balance_sek + EXCLUDED.balance_sek;
  END IF;

  RETURN 'credited';
END;
$$;

REVOKE EXECUTE ON FUNCTION
  confirm_stripe_payment(UUID, TEXT, TEXT, NUMERIC, NUMERIC, NUMERIC)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION
  confirm_stripe_payment(UUID, TEXT, TEXT, NUMERIC, NUMERIC, NUMERIC)
  TO service_role;

-- ─── 3. Harden rpc_buy_gold: wallet purchases only ──────────────────────────
-- Card payments are credited by the webhook; nothing else may credit gold.
CREATE OR REPLACE FUNCTION rpc_buy_gold(
  p_gold_grams       DOUBLE PRECISION,
  p_amount_sek       DOUBLE PRECISION,
  p_price_per_gram   DOUBLE PRECISION,
  p_payment_method   TEXT
) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  IF p_payment_method <> 'wallet' THEN
    RAISE EXCEPTION
      'Only wallet purchases may be made directly; card payments are credited after Stripe confirmation';
  END IF;

  INSERT INTO transactions
    (user_id, type, status, amount_sek, gold_grams, gold_price_per_gram_sek, payment_method)
  VALUES
    (v_uid, 'buy', 'completed', p_amount_sek, p_gold_grams, p_price_per_gram,
     'wallet'::payment_method);

  UPDATE wallets
  SET gold_grams  = gold_grams  + p_gold_grams,
      balance_sek = balance_sek - p_amount_sek
  WHERE user_id = v_uid
    AND balance_sek >= p_amount_sek;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Insufficient wallet balance';
  END IF;
END;
$$;

-- ─── 4. Retire rpc_add_funds from clients ────────────────────────────────────
-- Adding funds is card-only and now credited exclusively by the webhook.
REVOKE EXECUTE ON FUNCTION rpc_add_funds(DOUBLE PRECISION, TEXT)
  FROM PUBLIC, anon, authenticated;
