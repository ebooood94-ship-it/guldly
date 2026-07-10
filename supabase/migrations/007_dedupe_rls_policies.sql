-- ============================================================
-- Guldly — Migration 007
-- Remove duplicate legacy RLS policies.
--
-- Migration 001 introduced a "<table>: own <action>" policy set
-- but never dropped the original "Users can …" policies, leaving
-- two permissive policies per action on several tables. Postgres
-- OR's permissive policies, so the duplicates were redundant —
-- and redundancy is exactly what hid the double-INSERT-policy bug
-- on transactions (migration 006). This drops the legacy set so
-- each action has a single policy.
--
-- Every dropped policy uses the identical auth.uid() = user_id
-- (or = id) predicate as its surviving counterpart, so access is
-- unchanged. The two legacy ALL policies additionally granted
-- DELETE, which the newer sets omit; the app never deletes these
-- rows (no .delete() call exists), so nothing legitimate breaks.
-- ============================================================

-- profiles — keep "profiles: own read/insert/update"
DROP POLICY IF EXISTS "Users can view own profile"   ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;

-- wallets — keep "wallets: own read/insert/update"
DROP POLICY IF EXISTS "Users can view own wallet"   ON wallets;
DROP POLICY IF EXISTS "Users can update own wallet" ON wallets;

-- subscriptions — keep "subscriptions: own read/insert/update"
DROP POLICY IF EXISTS "Users can manage own subscriptions" ON subscriptions;

-- notification_preferences — keep "notif_prefs: own all"
DROP POLICY IF EXISTS "Users can manage own notification prefs" ON notification_preferences;

-- transactions — keep "transactions: own read" (the INSERT duplicate was
-- already handled in migration 006; this drops the leftover legacy SELECT).
DROP POLICY IF EXISTS "Users can view own transactions" ON transactions;
