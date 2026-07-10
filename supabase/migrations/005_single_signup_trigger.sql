-- ============================================================
-- Guldly — Migration 005
-- One signup trigger, one source of truth.
--
-- Previously auth.users INSERT fired handle_new_user (profiles +
-- wallets + notification_preferences, all ON CONFLICT DO NOTHING),
-- and the profile insert then cascaded two older triggers on
-- public.profiles that inserted wallets / notification_preferences
-- WITHOUT conflict guards. The result happened to be one row each
-- (the cascade won the race, handle_new_user's guarded inserts
-- no-op'd), but any direct profiles insert — e.g. the app's
-- first-login upsert racing its own wallet upsert — could raise a
-- unique violation via the unguarded cascade.
--
-- handle_new_user on auth.users is now the only signup trigger.
-- ============================================================

DROP TRIGGER IF EXISTS on_profile_created ON public.profiles;
DROP TRIGGER IF EXISTS on_profile_created_notifications ON public.profiles;

DROP FUNCTION IF EXISTS handle_new_profile();
DROP FUNCTION IF EXISTS handle_new_profile_notifications();

-- Align handle_new_user's search_path with the other hardened
-- functions (was 'public' without pg_temp).
ALTER FUNCTION handle_new_user() SET search_path = public, pg_temp;
