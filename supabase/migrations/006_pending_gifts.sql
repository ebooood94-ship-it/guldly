-- ============================================================
-- Guldly — Migration 006
-- Claimable pending gifts + gift-minting hole closed.
--
-- Before: rpc_send_gift debited the sender unconditionally and
-- handle_gift_sent credited the recipient only when
-- recipient_email matched an existing auth.users row (case
-- sensitively). No match → the gold silently vanished.
--
-- After:
--   * unmatched gifts land in pending_gifts and the sender's
--     gift_sent transaction shows status 'pending';
--   * handle_new_user claims any pending gifts for the new
--     user's email at signup and flips the sender's transaction
--     to 'completed';
--   * email matching is case-insensitive everywhere;
--   * rpc_send_gift returns 'delivered' | 'pending' so the app
--     can tell the sender what actually happened;
--   * the "transactions: own insert" RLS policy is dropped —
--     inserting a gift_sent row directly via PostgREST fired the
--     crediting trigger with no balance check (free gold). All
--     legitimate transaction writes happen inside SECURITY
--     DEFINER functions, which bypass RLS.
-- ============================================================

-- ─── 1. pending_gifts ────────────────────────────────────────────────────────
CREATE TABLE pending_gifts (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id               UUID NOT NULL REFERENCES profiles(id),
  transaction_id          UUID REFERENCES transactions(id),
  recipient_email         TEXT NOT NULL,
  recipient_name          TEXT,
  amount_sek              NUMERIC NOT NULL,
  gold_grams              NUMERIC NOT NULL,
  gold_price_per_gram_sek NUMERIC,
  claimed_at              TIMESTAMPTZ,
  claimed_by              UUID REFERENCES profiles(id),
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX pending_gifts_unclaimed_email_idx
  ON pending_gifts (lower(recipient_email))
  WHERE claimed_at IS NULL;

ALTER TABLE pending_gifts ENABLE ROW LEVEL SECURITY;

-- Senders may see their own outstanding gifts; nobody writes from the
-- client — only the SECURITY DEFINER functions below.
CREATE POLICY "pending_gifts: sender read" ON pending_gifts
  FOR SELECT USING (auth.uid() = sender_id);

-- ─── 2. handle_gift_sent: pend instead of losing unmatched gifts ─────────────
CREATE OR REPLACE FUNCTION handle_gift_sent()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE
  v_recipient_id UUID;
BEGIN
  SELECT id INTO v_recipient_id
  FROM auth.users
  WHERE lower(email) = lower(NEW.recipient_email)
  LIMIT 1;

  IF v_recipient_id IS NOT NULL THEN
    INSERT INTO wallets (user_id, balance_sek, gold_grams)
    VALUES (v_recipient_id, 0, COALESCE(NEW.gold_grams, 0))
    ON CONFLICT (user_id) DO UPDATE
      SET gold_grams = wallets.gold_grams + COALESCE(NEW.gold_grams, 0);

    INSERT INTO transactions
      (user_id, type, status, amount_sek, gold_grams, gold_price_per_gram_sek)
    VALUES
      (v_recipient_id, 'gift_received', 'completed',
       NEW.amount_sek, NEW.gold_grams, NEW.gold_price_per_gram_sek);
  ELSE
    -- Recipient hasn't signed up yet: hold the gold in pending_gifts and
    -- mark the sender's transaction pending. handle_new_user settles it.
    INSERT INTO pending_gifts
      (sender_id, transaction_id, recipient_email, recipient_name,
       amount_sek, gold_grams, gold_price_per_gram_sek)
    VALUES
      (NEW.user_id, NEW.id, lower(NEW.recipient_email), NEW.recipient_name,
       NEW.amount_sek, COALESCE(NEW.gold_grams, 0), NEW.gold_price_per_gram_sek);

    UPDATE transactions SET status = 'pending' WHERE id = NEW.id;
  END IF;

  RETURN NEW;
END;
$$;

-- ─── 3. rpc_send_gift: report 'delivered' or 'pending' ───────────────────────
-- Return type changes VOID → TEXT, which requires DROP + CREATE.
DROP FUNCTION rpc_send_gift(DOUBLE PRECISION, DOUBLE PRECISION, TEXT, TEXT, DOUBLE PRECISION, BOOLEAN);

CREATE FUNCTION rpc_send_gift(
  p_amount_sek       DOUBLE PRECISION,
  p_gold_grams       DOUBLE PRECISION,
  p_recipient_name   TEXT,
  p_recipient_email  TEXT,
  p_price_per_gram   DOUBLE PRECISION,
  p_is_sek_mode      BOOLEAN
) RETURNS TEXT
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE
  v_uid       UUID := auth.uid();
  v_recipient UUID;
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

  -- Insert gift_sent (handle_gift_sent credits the recipient or pends the gift)
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

  SELECT id INTO v_recipient
  FROM auth.users
  WHERE lower(email) = lower(p_recipient_email)
  LIMIT 1;

  RETURN CASE WHEN v_recipient IS NULL THEN 'pending' ELSE 'delivered' END;
END;
$$;

REVOKE EXECUTE ON FUNCTION rpc_send_gift(DOUBLE PRECISION, DOUBLE PRECISION, TEXT, TEXT, DOUBLE PRECISION, BOOLEAN)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION rpc_send_gift(DOUBLE PRECISION, DOUBLE PRECISION, TEXT, TEXT, DOUBLE PRECISION, BOOLEAN)
  TO authenticated;

-- ─── 4. handle_new_user: claim pending gifts at signup ───────────────────────
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE
  g RECORD;
BEGIN
  INSERT INTO public.profiles (id, full_name)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'full_name', ''))
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.wallets (user_id, balance_sek, gold_grams)
  VALUES (NEW.id, 0, 0)
  ON CONFLICT (user_id) DO NOTHING;

  INSERT INTO public.notification_preferences (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;

  -- Settle gifts that were sent to this email before the account existed.
  FOR g IN
    SELECT * FROM pending_gifts
    WHERE lower(recipient_email) = lower(NEW.email)
      AND claimed_at IS NULL
    FOR UPDATE
  LOOP
    UPDATE wallets SET gold_grams = gold_grams + g.gold_grams
    WHERE user_id = NEW.id;

    INSERT INTO transactions
      (user_id, type, status, amount_sek, gold_grams, gold_price_per_gram_sek)
    VALUES
      (NEW.id, 'gift_received', 'completed',
       g.amount_sek, g.gold_grams, g.gold_price_per_gram_sek);

    UPDATE transactions SET status = 'completed' WHERE id = g.transaction_id;

    UPDATE pending_gifts SET claimed_at = now(), claimed_by = NEW.id
    WHERE id = g.id;
  END LOOP;

  RETURN NEW;
END;
$$;

-- ─── 5. Close the gift-minting hole ──────────────────────────────────────────
-- Direct PostgREST inserts into transactions fired handle_gift_sent with no
-- balance check. All legitimate writes go through SECURITY DEFINER functions.
--
-- NOTE: transactions carried TWO permissive INSERT policies — migration 001
-- added "transactions: own insert" alongside a pre-existing "Users can insert
-- own transactions". RLS OR's permissive policies, so both must go or neither
-- has any effect.
DROP POLICY IF EXISTS "transactions: own insert" ON transactions;
DROP POLICY IF EXISTS "Users can insert own transactions" ON transactions;
