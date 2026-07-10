# Claude Code Prompts — Guldly

Copy/paste these into Claude Code inside VS Code, one at a time, in order. Each one is self-contained (states the context, the file, the fix, and how to verify it). Run them from the repo root (`C:\dev\guldly`). Claude Code has the Flutter SDK and Supabase CLI available here, which I didn't in this session — use that to actually run `flutter analyze` / `flutter test` / a build after each fix.

---

## 0. Baseline sanity check (run first, before any fixes)

```
Run `flutter pub get`, then `flutter analyze`, then `flutter test`. Report every warning, error, and failing test verbatim — don't summarize or filter anything out. Also run `flutter build web --debug` and paste the last 40 lines of output whether it succeeds or fails. Don't fix anything yet, just give me the full baseline so we know what's pre-existing vs. what we introduce.
```

---

## 1. Fix instant-credit exploit on "bank transfer" payments

```
In this Flutter/Supabase app (Guldly), the "bank transfer" payment method is a security/business-logic bug: selecting it credits gold or wallet balance instantly with zero payment verification.

Look at:
- lib/presentation/screens/wallet/add_funds_screen.dart (_onContinue)
- lib/presentation/screens/buy_gold/buy_gold_screen.dart (payment method picker)
- lib/presentation/screens/buy_gold/buy_onetime_screen.dart / buy_recurring_screen.dart
- lib/core/providers/providers.dart (GoldTransactionService, _paymentToDb)
- The Supabase RPCs rpc_buy_gold and rpc_add_funds (use the Supabase MCP tools or `supabase db dump` / migrations in supabase/migrations/001_rls_functions_triggers.sql) — note that rpc_buy_gold only checks balance when payment_method = 'wallet'; for anything else it credits gold_grams unconditionally.

Decide and implement one of these two fixes (ask me if unsure which):
(a) Remove the "bank transfer" option entirely from the UI until real bank-transfer verification exists (simplest, safest short-term fix), or
(b) Make bank-transfer transactions insert with status = 'pending' instead of 'completed', do NOT credit the wallet/gold_grams until a separate confirmation step marks it completed (e.g. an admin action or a webhook), and update the UI to show a "pending" state on the receipt screen instead of an instant success.

After implementing, write a widget test that asserts a bank-transfer purchase does not immediately increase gold_grams in a mocked wallet state (or, if using the RPC path, a note describing manual verification steps against a Supabase test project). Run `flutter analyze` and `flutter test` and fix anything that breaks.
```

---

## 2. Verify Stripe payments before crediting (server-side trust boundary)

```
In Guldly, gold purchases via card go through this flow: client calls Stripe's payment sheet or Checkout, and once the client-side call reports success, the client itself calls the Supabase RPC rpc_buy_gold to credit gold. Nothing server-side verifies with Stripe that the payment actually completed — the RPC trusts the client's payment_method string.

Files involved:
- supabase/functions/create-payment-intent/index.ts (creates PaymentIntent / Checkout Session)
- lib/presentation/screens/buy_gold/card_checkout_sheet.dart (mobile payment sheet)
- lib/presentation/screens/buy_gold/buy_onetime_screen.dart, buy_recurring_screen.dart, wallet/add_funds_screen.dart (_webStripeRedirect methods)
- The rpc_buy_gold / rpc_add_funds Postgres functions

I want to close this gap. The right approach: add a Stripe webhook handler (new Supabase edge function, e.g. supabase/functions/stripe-webhook/index.ts) that listens for `payment_intent.succeeded` / `checkout.session.completed`, and have THAT be what inserts the completed transaction and credits the wallet — using the Supabase service role key, not something the client can trigger. The client-side RPC call after payment should either be removed (rely entirely on the webhook) or the webhook should be idempotent against the transaction the client also tries to create (e.g. match on a payment_intent_id column so double-crediting can't happen).

Before writing code, propose the exact schema change needed (probably a `stripe_payment_intent_id` column on `transactions` with a unique constraint) and the webhook's full logic, and show me the plan before implementing. Then implement it, deploy the new edge function, and write a test plan for verifying it end-to-end using Stripe's test mode and the Stripe CLI's `stripe trigger payment_intent.succeeded` command.
```

---

## 3. Lock down Supabase function permissions (security advisor warnings)

```
Supabase's security advisor flags these issues on the Guldly project (njcwivpthvrpqocibrpb):

1. These SECURITY DEFINER functions are directly callable via PostgREST by anon and/or authenticated roles, when they should only ever run as triggers or via pg_cron: handle_gift_sent, handle_new_profile, handle_new_profile_notifications, handle_new_user, rls_auto_enable, process_due_subscriptions. In particular, process_due_subscriptions being callable by anon means anyone could trigger recurring billing runs on demand from the public API.

2. These functions have a mutable search_path (missing `SET search_path`): handle_new_profile, handle_new_profile_notifications, rpc_sell_gold, rpc_send_gift, rpc_request_delivery, handle_gift_sent, process_due_subscriptions, rpc_buy_gold, rpc_add_funds.

Write a new migration file (supabase/migrations/003_security_hardening.sql) that:
- Revokes EXECUTE on the trigger/cron-only functions from PUBLIC, anon, and authenticated (they only need to run as SECURITY DEFINER triggers/cron, not be publicly callable).
- Adds `SET search_path = public, pg_temp` to every function listed above that's missing it (use `CREATE OR REPLACE FUNCTION` with `SECURITY DEFINER SET search_path = public, pg_temp`).
- Leaves the rpc_* functions that the Flutter app legitimately calls (rpc_buy_gold, rpc_sell_gold, rpc_add_funds, rpc_send_gift, rpc_request_delivery) executable by `authenticated` only (not anon).

Apply the migration to the project and then re-run the security advisor to confirm the warnings are gone. Also check whether "Leaked Password Protection" can be enabled via a migration or whether it requires a dashboard/API toggle, and tell me which.
```

---

## 4. Consolidate duplicate signup triggers

```
In Guldly's Supabase project, there appear to be two overlapping sets of triggers on auth.users insert: an older pair (handle_new_profile, handle_new_profile_notifications — each does one INSERT) and a newer, more complete handle_new_user (which inserts into profiles, wallets, AND notification_preferences, all with ON CONFLICT DO NOTHING).

Check pg_trigger / information_schema.triggers on auth.users to see which of these are actually still attached. If both handle_new_user and the older pair are firing on the same insert, that's redundant (harmless today due to ON CONFLICT guards, but confusing and risky for future changes). Remove the redundant ones, keep handle_new_user as the single source of truth, and write a migration for it. After the change, sign up a fresh test user (or explain how you verified) and confirm profiles/wallets/notification_preferences rows are still created exactly once each.
```

---

## 5. Fix the silent-gift-loss bug

```
In Guldly, sending a gift (lib/presentation/screens/gift/gift_screen.dart → rpc_send_gift) debits the sender's wallet/gold unconditionally. The recipient side is handled by a trigger (handle_gift_sent) that looks up the recipient by email in auth.users — if there's no match (recipient hasn't signed up yet), the trigger does nothing and the gold is just gone with no error, no pending state, and no way to recover it.

Fix this properly:
1. Add a `gift_status` concept — either a new column on transactions (e.g. `gift_claimed boolean default true`, set false when no matching user is found) or a small `pending_gifts` table keyed by recipient_email that gets claimed when that email eventually signs up (check it in handle_new_user and settle it then).
2. Update handle_gift_sent (or add a new trigger) so an unmatched recipient email results in a pending/claimable gift rather than silent loss.
3. Update gift_screen.dart to show the user a clear message when they're gifting to an email that isn't a Guldly user yet — e.g. "They'll receive this gold once they sign up with this email" — instead of implying instant delivery.
4. Write a test (or a manual verification script using the Supabase MCP / SQL) that: sends a gift to a non-existent email, confirms a pending record exists and sender is debited, then simulates that email signing up, and confirms the gift gets credited to the new account.

Show me the schema/trigger plan before implementing.
```

---

## 6. Wire up real push notifications (or clearly disable the toggles)

```
In Guldly, lib/presentation/screens/more/notifications_screen.dart lets users toggle push_price_alerts, push_transaction_updates, and push_promotions, which persist to the notification_preferences table via lib/core/providers/providers.dart's NotificationPrefsNotifier. But there's no actual push delivery: lib/core/services/notification_service.dart has a savePushToken() method that is never called anywhere in the app, there's no Firebase/APNs setup, no permission request flow, and the push_tokens table has zero rows in production.

I want a real decision here, not a silent no-op. Two options:
(a) Implement real push notifications using Firebase Cloud Messaging: add the firebase_messaging package, request notification permission on first login, call NotificationService.savePushToken() with the FCM token, add a Supabase edge function or trigger that sends a push via FCM's HTTP v1 API when relevant events happen (e.g. a completed transaction, or a price-alert threshold), or
(b) If we're not ready to build FCM infrastructure yet, update notifications_screen.dart's copy so it's honest about what these toggles currently do (email/in-app only, not push) and remove the "push" framing until (a) is built, so we're not shipping controls that silently do nothing.

Tell me which one you're going with and why given the state of the rest of the app, then implement it. If (a), test it by sending yourself a test push via the Firebase console or FCM API and confirming it arrives on both Android and iOS (or web push, whichever this app targets).
```

---

## 7. Clean up hardcoded colors

```
Guldly's own convention (documented in the codebase) is: always use AppConstants.<token> for colors, never hardcode Color(0x...) or Colors.* in screens. Two files violate this: lib/presentation/screens/auth/splash_screen.dart and lib/presentation/screens/portfolio/portfolio_screen.dart. Find every hardcoded color literal in those two files, map each to the closest existing AppConstants token (in lib/core/constants/app_constants.dart), and replace them. If a needed color doesn't exist as a token yet, add it to AppConstants rather than leaving it hardcoded. Run `flutter analyze` after and confirm no visual regression by describing what changed in each spot.
```

---

## 8. Add real test coverage

```
Guldly currently has zero test coverage — test/widget_test.dart is an empty stub. Set up a real starting test suite:

1. Unit tests for the pure logic in lib/core/models/models.dart and lib/core/models/gold_price.dart (especially GoldPrice.pricePerGramSek's conversion math: pricePerOzUsd × usdToSek / 31.1035 — verify this against hand-calculated values).
2. Unit tests for lib/core/providers/providers.dart's GoldTransactionService._paymentToDb mapping (card→credit_card, bank→bank_transfer, else→wallet).
3. A widget test for the amount-entry flow in lib/presentation/screens/buy_gold/buy_onetime_screen.dart — verify tapping a suggestion pill sets the amount, and that the continue button is disabled at 0 kr and enabled above it.
4. A widget test for lib/presentation/screens/wallet/add_funds_screen.dart verifying the same pill/continue-button behavior.

Use Riverpod's ProviderScope overrides to mock the Supabase client / providers rather than hitting the real backend. Run `flutter test` and make sure everything passes before reporting back.
```

---

## 9. Stop the line-ending diff noise and push to GitHub

```
The Guldly repo has ~50 files showing as "modified" in `git status`, but `git diff --stat` shows symmetric +N/-N line counts on every one of them (e.g. providers.dart | 802 ++++++++++-----------), which is the signature of CRLF/LF line-ending churn, not real content changes — likely from a Windows checkout of a repo committed with LF endings.

1. Add a `.gitattributes` file at the repo root that pins text files to LF (`* text=auto eol=lf`), so this doesn't keep happening.
2. Run `git add --renormalize .` to apply it retroactively, then confirm with `git diff --stat` that the noise is gone (or reduced to only real changes).
3. Show me a diff of anything that ISN'T pure whitespace/line-ending change — I want to review real content changes separately before committing them.
4. Once confirmed clean, commit the line-ending normalization as its own commit (message like "chore: normalize line endings to LF"), separate from any real code changes.
5. The local branch is currently 13 commits ahead of origin/main and none of it is pushed. After the normalization commit, run `git log origin/main..HEAD --oneline` to show me exactly what's about to go to GitHub, then push with `git push origin main` once I confirm.
```

---

## 10. Audit error messages end-to-end

```
Guldly has a friendlyError() utility in lib/core/utils/error_utils.dart that's supposed to map raw Supabase/Postgres/Stripe exceptions into friendly Swedish user-facing text. Go through every place an RPC or Stripe call can throw — rpc_buy_gold ("Insufficient wallet balance"), rpc_sell_gold / rpc_request_delivery ("Insufficient gold"), rpc_send_gift ("Insufficient wallet balance" / "Insufficient gold"), Stripe's StripeException cases in card_checkout_sheet.dart, and network failures from the get-gold-price / create-payment-intent edge functions — and confirm each one is actually caught and passed through friendlyError() rather than showing a raw exception string to the user. Fix any that aren't, and list every distinct error case you found with its current user-facing message.
```

---

### Suggested order

Run 0 first always. Then 1 → 2 → 3 (money/security, in that order since 1 and 2 are the most exploitable). Then 4, 5, 6 (functional gaps). Then 7, 8 (polish/tests) and 9 (git hygiene) can happen anytime, ideally before 9 rather than after so the real fixes land in clean commits. Finish with 10 as a final sweep once everything else is settled.
