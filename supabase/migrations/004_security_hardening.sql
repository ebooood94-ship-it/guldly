-- ============================================================
-- Guldly — Migration 004
-- Security-advisor hardening:
--   1. Pin search_path on all SECURITY DEFINER functions
--      (mutable search_path allows privilege escalation via
--      schema/object shadowing).
--   2. Trigger/cron-only functions must not be callable through
--      PostgREST (anon could e.g. run billing on demand via
--      process_due_subscriptions).
--   3. App-facing rpc_* functions: callable by authenticated
--      only, never anon.
--
-- NOTE: rpc_add_funds stays revoked from ALL client roles
-- (migration 003): it credits the wallet unconditionally and its
-- only legitimate caller path is the stripe-webhook flow.
-- ============================================================

-- ─── 1. Pin search_path ──────────────────────────────────────────────────────
-- ALTER (not CREATE OR REPLACE) so definitions are untouched; the end state
-- in pg_proc.proconfig is identical.
ALTER FUNCTION handle_gift_sent()                 SET search_path = public, pg_temp;
ALTER FUNCTION handle_new_profile()               SET search_path = public, pg_temp;
ALTER FUNCTION handle_new_profile_notifications() SET search_path = public, pg_temp;
ALTER FUNCTION process_due_subscriptions()        SET search_path = public, pg_temp;
ALTER FUNCTION rpc_buy_gold(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, TEXT)
                                                  SET search_path = public, pg_temp;
ALTER FUNCTION rpc_sell_gold(DOUBLE PRECISION, DOUBLE PRECISION)
                                                  SET search_path = public, pg_temp;
ALTER FUNCTION rpc_add_funds(DOUBLE PRECISION, TEXT)
                                                  SET search_path = public, pg_temp;
ALTER FUNCTION rpc_send_gift(DOUBLE PRECISION, DOUBLE PRECISION, TEXT, TEXT, DOUBLE PRECISION, BOOLEAN)
                                                  SET search_path = public, pg_temp;
ALTER FUNCTION rpc_request_delivery(DOUBLE PRECISION, TEXT)
                                                  SET search_path = public, pg_temp;
ALTER FUNCTION confirm_stripe_payment(UUID, TEXT, TEXT, NUMERIC, NUMERIC, NUMERIC)
                                                  SET search_path = public, pg_temp;
-- handle_new_user and rls_auto_enable already pin a search_path
-- (public and pg_catalog respectively) — left as-is.

-- ─── 2. Trigger/cron-only functions: not callable via PostgREST ──────────────
REVOKE EXECUTE ON FUNCTION handle_gift_sent()                 FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION handle_new_profile()               FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION handle_new_profile_notifications() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION handle_new_user()                  FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION rls_auto_enable()                  FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION process_due_subscriptions()        FROM PUBLIC, anon, authenticated;
-- Triggers and pg_cron run as the function owner (postgres), which is
-- unaffected by these revokes.

-- ─── 3. App-facing RPCs: authenticated only, never anon ─────────────────────
REVOKE EXECUTE ON FUNCTION rpc_buy_gold(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, TEXT)
  FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION rpc_buy_gold(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, TEXT)
  TO authenticated;

REVOKE EXECUTE ON FUNCTION rpc_sell_gold(DOUBLE PRECISION, DOUBLE PRECISION)
  FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION rpc_sell_gold(DOUBLE PRECISION, DOUBLE PRECISION)
  TO authenticated;

REVOKE EXECUTE ON FUNCTION rpc_send_gift(DOUBLE PRECISION, DOUBLE PRECISION, TEXT, TEXT, DOUBLE PRECISION, BOOLEAN)
  FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION rpc_send_gift(DOUBLE PRECISION, DOUBLE PRECISION, TEXT, TEXT, DOUBLE PRECISION, BOOLEAN)
  TO authenticated;

REVOKE EXECUTE ON FUNCTION rpc_request_delivery(DOUBLE PRECISION, TEXT)
  FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION rpc_request_delivery(DOUBLE PRECISION, TEXT)
  TO authenticated;

-- rpc_add_funds: intentionally NO grant here — see header note.
