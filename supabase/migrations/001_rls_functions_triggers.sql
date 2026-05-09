-- ============================================================
-- Guldly — Backend Migration 001
-- Run this in the Supabase SQL Editor (Project → SQL Editor)
-- ============================================================


-- ─── 1. ROW LEVEL SECURITY ───────────────────────────────────────────────────

ALTER TABLE profiles                ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallets                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions            ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions           ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;

-- profiles  (PK = id)
CREATE POLICY "profiles: own read"   ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "profiles: own insert" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "profiles: own update" ON profiles FOR UPDATE USING (auth.uid() = id);

-- wallets
CREATE POLICY "wallets: own read"   ON wallets FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "wallets: own insert" ON wallets FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "wallets: own update" ON wallets FOR UPDATE USING (auth.uid() = user_id);

-- transactions  (insert-only for users; no delete/update from client)
CREATE POLICY "transactions: own read"   ON transactions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "transactions: own insert" ON transactions FOR INSERT WITH CHECK (auth.uid() = user_id);

-- subscriptions
CREATE POLICY "subscriptions: own read"   ON subscriptions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "subscriptions: own insert" ON subscriptions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "subscriptions: own update" ON subscriptions FOR UPDATE USING (auth.uid() = user_id);

-- notification_preferences
CREATE POLICY "notif_prefs: own all" ON notification_preferences
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);


-- ─── 2. ATOMIC WALLET RPC FUNCTIONS ─────────────────────────────────────────
-- These replace the client-side read→write pattern, eliminating race conditions.
-- SECURITY DEFINER runs as the function owner, bypassing RLS for internal writes.

-- 2a. Buy gold (one-time)
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
  -- Insert transaction record
  INSERT INTO transactions
    (user_id, type, status, amount_sek, gold_grams, gold_price_per_gram_sek, payment_method)
  VALUES
    (v_uid, 'buy', 'completed', p_amount_sek, p_gold_grams, p_price_per_gram, p_payment_method);

  IF p_payment_method = 'wallet' THEN
    -- Deduct SEK balance atomically, fail if insufficient
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

-- 2b. Sell gold
CREATE OR REPLACE FUNCTION rpc_sell_gold(
  p_gold_grams     DOUBLE PRECISION,
  p_price_per_gram DOUBLE PRECISION
) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_uid        UUID             := auth.uid();
  v_amount_sek DOUBLE PRECISION := p_gold_grams * p_price_per_gram;
BEGIN
  INSERT INTO transactions
    (user_id, type, status, amount_sek, gold_grams, gold_price_per_gram_sek)
  VALUES
    (v_uid, 'sell', 'completed', v_amount_sek, p_gold_grams, p_price_per_gram);

  UPDATE wallets
  SET gold_grams  = gold_grams  - p_gold_grams,
      balance_sek = balance_sek + v_amount_sek
  WHERE user_id = v_uid
    AND gold_grams >= p_gold_grams;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Insufficient gold';
  END IF;
END;
$$;

-- 2c. Add funds
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
    (v_uid, 'add_funds', 'completed', p_amount_sek, p_payment_method);

  UPDATE wallets
  SET balance_sek = balance_sek + p_amount_sek
  WHERE user_id = v_uid;
END;
$$;

-- 2d. Send gift
CREATE OR REPLACE FUNCTION rpc_send_gift(
  p_amount_sek       DOUBLE PRECISION,
  p_gold_grams       DOUBLE PRECISION,
  p_recipient_name   TEXT,
  p_recipient_email  TEXT,
  p_price_per_gram   DOUBLE PRECISION,
  p_is_sek_mode      BOOLEAN
) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  -- Validate balance before any writes
  IF p_is_sek_mode THEN
    IF (SELECT balance_sek FROM wallets WHERE user_id = v_uid) < p_amount_sek THEN
      RAISE EXCEPTION 'Insufficient wallet balance';
    END IF;
  ELSE
    IF (SELECT gold_grams FROM wallets WHERE user_id = v_uid) < p_gold_grams THEN
      RAISE EXCEPTION 'Insufficient gold';
    END IF;
  END IF;

  -- Insert gift_sent (the trigger below handles recipient crediting)
  INSERT INTO transactions
    (user_id, type, status, amount_sek, gold_grams, gold_price_per_gram_sek,
     recipient_name, recipient_email, payment_method)
  VALUES
    (v_uid, 'gift_sent', 'completed', p_amount_sek, p_gold_grams, p_price_per_gram,
     p_recipient_name, p_recipient_email, 'wallet');

  -- Deduct from sender
  IF p_is_sek_mode THEN
    UPDATE wallets SET balance_sek = balance_sek - p_amount_sek WHERE user_id = v_uid;
  ELSE
    UPDATE wallets SET gold_grams  = gold_grams  - p_gold_grams  WHERE user_id = v_uid;
  END IF;
END;
$$;

-- 2e. Request delivery
CREATE OR REPLACE FUNCTION rpc_request_delivery(
  p_gold_grams      DOUBLE PRECISION,
  p_delivery_address TEXT
) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  INSERT INTO transactions
    (user_id, type, status, amount_sek, gold_grams, delivery_address)
  VALUES
    (v_uid, 'delivery', 'pending', 0, p_gold_grams, p_delivery_address);

  UPDATE wallets
  SET gold_grams = gold_grams - p_gold_grams
  WHERE user_id = v_uid
    AND gold_grams >= p_gold_grams;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Insufficient gold';
  END IF;
END;
$$;


-- ─── 3. GIFT RECIPIENT TRIGGER ───────────────────────────────────────────────
-- When a gift_sent transaction is inserted, look up the recipient by email
-- and credit their wallet automatically.

CREATE OR REPLACE FUNCTION handle_gift_sent()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_recipient_id UUID;
BEGIN
  -- Look up recipient in auth.users by email
  SELECT id INTO v_recipient_id
  FROM auth.users
  WHERE email = NEW.recipient_email
  LIMIT 1;

  IF v_recipient_id IS NOT NULL THEN
    -- Credit recipient's wallet (upsert in case they have no wallet yet)
    INSERT INTO wallets (user_id, balance_sek, gold_grams)
    VALUES (v_recipient_id, 0, COALESCE(NEW.gold_grams, 0))
    ON CONFLICT (user_id) DO UPDATE
      SET gold_grams = wallets.gold_grams + COALESCE(NEW.gold_grams, 0);

    -- Record gift_received transaction for recipient
    INSERT INTO transactions
      (user_id, type, status, amount_sek, gold_grams, gold_price_per_gram_sek)
    VALUES
      (v_recipient_id, 'gift_received', 'completed',
       NEW.amount_sek, NEW.gold_grams, NEW.gold_price_per_gram_sek);
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER on_gift_sent
  AFTER INSERT ON transactions
  FOR EACH ROW
  WHEN (NEW.type = 'gift_sent')
  EXECUTE FUNCTION handle_gift_sent();


-- ─── 4. RECURRING SUBSCRIPTION PROCESSING ───────────────────────────────────
-- Requires pg_cron extension. Enable it in Supabase:
--   Dashboard → Database → Extensions → search "pg_cron" → Enable

CREATE OR REPLACE FUNCTION process_due_subscriptions()
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  rec RECORD;
BEGIN
  FOR rec IN
    SELECT * FROM subscriptions
    WHERE is_active = true
      AND next_payment_date::date <= CURRENT_DATE
  LOOP
    -- Record the recurring purchase (no gold_grams — price unknown server-side;
    -- use a separate gold_price_snapshots table or call an Edge Function with price)
    INSERT INTO transactions (user_id, type, status, amount_sek, payment_method)
    VALUES (rec.user_id, 'recurring_buy', 'completed', rec.amount_sek, rec.payment_method);

    -- Advance next payment date
    UPDATE subscriptions
    SET next_payment_date = CASE rec.frequency
          WHEN 'daily'   THEN rec.next_payment_date + INTERVAL '1 day'
          WHEN 'weekly'  THEN rec.next_payment_date + INTERVAL '7 days'
          WHEN 'monthly' THEN rec.next_payment_date + INTERVAL '1 month'
        END
    WHERE id = rec.id;
  END LOOP;
END;
$$;

-- Schedule daily at 08:00 UTC
-- Uncomment after enabling pg_cron:
-- SELECT cron.schedule('process-subscriptions', '0 8 * * *', 'SELECT process_due_subscriptions()');
