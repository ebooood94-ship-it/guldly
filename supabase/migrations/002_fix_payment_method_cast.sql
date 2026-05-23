-- ============================================================
-- Guldly — Migration 002
-- Fix: cast TEXT → payment_method enum in all RPC functions
-- ============================================================

-- 2a. Buy gold (one-time) — add ::payment_method cast
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
  INSERT INTO transactions
    (user_id, type, status, amount_sek, gold_grams, gold_price_per_gram_sek, payment_method)
  VALUES
    (v_uid, 'buy', 'completed', p_amount_sek, p_gold_grams, p_price_per_gram,
     p_payment_method::payment_method);

  IF p_payment_method = 'wallet' THEN
    UPDATE wallets
    SET gold_grams  = gold_grams  + p_gold_grams,
        balance_sek = balance_sek - p_amount_sek
    WHERE user_id = v_uid
      AND balance_sek >= p_amount_sek;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Insufficient wallet balance';
    END IF;
  ELSE
    -- Card / bank: payment already confirmed by Stripe; just add gold
    UPDATE wallets
    SET gold_grams = gold_grams + p_gold_grams
    WHERE user_id = v_uid;
  END IF;
END;
$$;

-- 2c. Add funds — add ::payment_method cast
CREATE OR REPLACE FUNCTION rpc_add_funds(
  p_amount_sek     DOUBLE PRECISION,
  p_payment_method TEXT
) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  INSERT INTO transactions
    (user_id, type, status, amount_sek, payment_method)
  VALUES
    (v_uid, 'add_funds', 'completed', p_amount_sek,
     p_payment_method::payment_method);

  UPDATE wallets
  SET balance_sek = balance_sek + p_amount_sek
  WHERE user_id = v_uid;
END;
$$;
