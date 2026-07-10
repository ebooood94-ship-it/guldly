-- ============================================================
-- Guldly — pending-gifts verification script (migration 006)
--
-- Verifies: gift to a non-existent email pends (sender debited,
-- nothing lost), and signing up with that email claims it.
--
-- Run against a TEST project, or wrap in BEGIN/ROLLBACK.
-- Replace :sender_id with a real user id that owns >= 1g gold.
-- ============================================================

BEGIN;

\set sender_id '00000000-0000-0000-0000-000000000000'
\set recipient_email 'pending-gift-verify@example.test'
\set recipient_id 'bbbbbbbb-1111-2222-3333-444444444444'

-- ─── Step 0: baseline ───────────────────────────────────────────────────────
CREATE TEMP TABLE _baseline AS
SELECT gold_grams AS sender_gold FROM wallets WHERE user_id = :'sender_id';

-- ─── Step 1: gift to an email with no account → 'pending' ───────────────────
SELECT set_config('request.jwt.claims',
  json_build_object('sub', :'sender_id', 'role', 'authenticated')::text, true);

SELECT rpc_send_gift(250, 0.25, 'Verify Recipient', :'recipient_email', 1000, false)
  AS must_be_pending;   -- expect: pending

-- Sender debited exactly 0.25g, gift held, sender's tx marked pending.
SELECT
  (SELECT sender_gold FROM _baseline)
    - (SELECT gold_grams FROM wallets WHERE user_id = :'sender_id') AS must_be_0_25,
  (SELECT count(*) FROM pending_gifts
     WHERE lower(recipient_email) = lower(:'recipient_email')
       AND claimed_at IS NULL)                                      AS must_be_1,
  (SELECT status::text FROM transactions
     WHERE user_id = :'sender_id' AND type = 'gift_sent'
     ORDER BY created_at DESC LIMIT 1)                              AS must_be_pending_status;

-- ─── Step 2: that email signs up → handle_new_user claims the gift ──────────
INSERT INTO auth.users
  (instance_id, id, aud, role, email, encrypted_password,
   email_confirmed_at, created_at, updated_at,
   raw_app_meta_data, raw_user_meta_data,
   confirmation_token, recovery_token, email_change_token_new, email_change)
VALUES
  ('00000000-0000-0000-0000-000000000000', :'recipient_id',
   'authenticated', 'authenticated', :'recipient_email',
   crypt('Verify-Pass!123', gen_salt('bf')),
   now(), now(), now(),
   '{"provider":"email","providers":["email"]}',
   '{"full_name":"Verify Recipient"}',
   '', '', '', '');

-- ─── Step 3: gold delivered, gift settled on both sides ─────────────────────
SELECT
  (SELECT gold_grams FROM wallets WHERE user_id = :'recipient_id')  AS must_be_0_25,
  (SELECT count(*) FROM transactions
     WHERE user_id = :'recipient_id'
       AND type = 'gift_received' AND status = 'completed')         AS must_be_1,
  (SELECT claimed_at IS NOT NULL FROM pending_gifts
     WHERE lower(recipient_email) = lower(:'recipient_email'))      AS must_be_true,
  (SELECT claimed_by FROM pending_gifts
     WHERE lower(recipient_email) = lower(:'recipient_email'))      AS must_be_recipient_id,
  (SELECT status::text FROM transactions
     WHERE user_id = :'sender_id' AND type = 'gift_sent'
     ORDER BY created_at DESC LIMIT 1)                              AS must_be_completed;

-- Recipient's profile/wallet/prefs still created exactly once each.
SELECT
  (SELECT count(*) FROM profiles WHERE id = :'recipient_id')                  AS must_be_1,
  (SELECT count(*) FROM wallets WHERE user_id = :'recipient_id')              AS must_be_1,
  (SELECT count(*) FROM notification_preferences WHERE user_id = :'recipient_id') AS must_be_1;

-- ─── Step 4: forged gift_sent insert is blocked by RLS ──────────────────────
-- transactions has no INSERT policy: crediting only happens inside
-- SECURITY DEFINER functions. This must raise insufficient_privilege.
DO $$
BEGIN
  PERFORM set_config('request.jwt.claims',
    '{"sub":"00000000-0000-0000-0000-000000000000","role":"authenticated"}', true);
  SET LOCAL ROLE authenticated;
  BEGIN
    INSERT INTO transactions (user_id, type, status, amount_sek, gold_grams, recipient_email)
    VALUES ('00000000-0000-0000-0000-000000000000', 'gift_sent', 'completed', 0, 9999, 'victim@example.test');
    RAISE EXCEPTION 'SECURITY REGRESSION: forged gift_sent insert succeeded';
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'OK: forged insert blocked by RLS';
  END;
  RESET ROLE;
END $$;

ROLLBACK;  -- change to COMMIT only on a throwaway project
