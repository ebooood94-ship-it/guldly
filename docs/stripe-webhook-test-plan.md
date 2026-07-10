# Stripe webhook e2e test plan

Verifies that card payments are credited **only** by the `stripe-webhook`
edge function after Stripe confirms the payment (migration 003 +
`supabase/functions/stripe-webhook`).

Project: `njcwivpthvrpqocibrpb` · All steps use **Stripe test mode**.

## 0. One-time setup

1. **Set the webhook secret.** For local CLI testing, get it from
   `stripe listen` (step 1 below prints `whsec_...`). For production, create
   an endpoint in the Stripe dashboard (Developers → Webhooks →
   Add endpoint) pointing at
   `https://njcwivpthvrpqocibrpb.supabase.co/functions/v1/stripe-webhook`
   listening to `payment_intent.succeeded`, and copy its signing secret.

   ```sh
   supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_... --project-ref njcwivpthvrpqocibrpb
   ```

2. Log in to the Stripe CLI in test mode: `stripe login`.

3. Have a test user's UUID handy (Supabase Dashboard → Authentication →
   Users), referred to as `$USER_ID` below. Note their starting balances:

   ```sql
   select balance_sek, gold_grams from wallets where user_id = '$USER_ID';
   ```

## 1. Forward events to the deployed function

```sh
stripe listen --forward-to https://njcwivpthvrpqocibrpb.supabase.co/functions/v1/stripe-webhook
```

Use the `whsec_...` this prints as `STRIPE_WEBHOOK_SECRET` while testing
(re-run `supabase secrets set` if it differs from the dashboard secret).

## 2. Happy path: buy gold credits gold_grams once

```sh
stripe trigger payment_intent.succeeded \
  --add "payment_intent:metadata[user_id]=$USER_ID" \
  --add "payment_intent:metadata[purpose]=buy_gold" \
  --add "payment_intent:metadata[gold_grams]=0.5" \
  --add "payment_intent:metadata[price_per_gram]=1000" \
  --add "payment_intent:amount=50000" \
  --add "payment_intent:currency=sek"
```

Expected:
- `stripe listen` shows `200` from the function; function logs show
  `payment ... : credited`.
- A new row in `transactions`: `type=buy`, `status=completed`,
  `payment_method=credit_card`, `amount_sek=500`, `gold_grams=0.5`, and
  `stripe_payment_intent_id=pi_...`.
- `wallets.gold_grams` increased by exactly 0.5; `balance_sek` unchanged.

## 3. Happy path: add funds credits balance_sek

Same command with `metadata[purpose]=add_funds` and no gold metadata.
Expected: `type=add_funds` transaction, `balance_sek` +500, `gold_grams`
unchanged.

## 4. Idempotency: replay does not double-credit

In the Stripe dashboard (Developers → Events), open the event from step 2
and **Resend** it (or `stripe events resend <evt_id>`). Expected:
- Function returns `200` with `"result":"duplicate"`.
- No new `transactions` row, `wallets` unchanged.

## 5. Signature rejection

```sh
curl -i -X POST \
  https://njcwivpthvrpqocibrpb.supabase.co/functions/v1/stripe-webhook \
  -H "Content-Type: application/json" \
  -H "stripe-signature: t=1,v1=garbage" \
  -d '{"type":"payment_intent.succeeded"}'
```

Expected: `400 Invalid signature`, nothing written to the database.

## 6. Foreign events are acknowledged but ignored

`stripe trigger payment_intent.succeeded` **without** any `--add` metadata.
Expected: `200` with `"skipped":"missing metadata"`, no database writes.

## 7. Client can no longer self-credit (regression)

As an authenticated **non-service** user (e.g. from the SQL editor's
impersonation or a REST call with the user's JWT):

```sql
select rpc_buy_gold(1.0, 1000, 1000, 'credit_card');
-- expected: ERROR: Only wallet purchases may be made directly...

select rpc_add_funds(1000, 'credit_card');
-- expected: permission denied for function rpc_add_funds

select confirm_stripe_payment('$USER_ID', 'pi_fake', 'buy_gold', 1000, 1.0, 1000);
-- expected: permission denied for function confirm_stripe_payment
```

Forged-receipt check (web): navigate to
`https://<app>/#/receipt?type=Buy%20Gold&amount=0&grams=1000&price=0&success=true`
while logged in. Expected: receipt renders but **no** transaction is created
and `gold_grams` is unchanged (the screen no longer records anything).

## 8. Full in-app flow (test cards)

1. In the app, buy gold with card `4242 4242 4242 4242` (any future expiry,
   any CVC), on both mobile (payment sheet) and web (Checkout redirect).
2. Expected: Stripe confirms → webhook fires → wallet shows the new gold
   after the receipt screen's ~2 s refresh. Exactly one `transactions` row
   per payment, carrying the `pi_...` id.
3. Mispricing rejection: `create-payment-intent` returns
   `400 pricePerGram deviates from the live gold price` if a tampered client
   claims a price >5% off the live quote, or grams×price ≠ amount (±1%).
   Verify with curl using a user JWT:

   ```sh
   curl -s -X POST \
     https://njcwivpthvrpqocibrpb.supabase.co/functions/v1/create-payment-intent \
     -H "Authorization: Bearer $USER_JWT" -H "Content-Type: application/json" \
     -d '{"amount":100,"purpose":"buy_gold","goldGrams":1000,"pricePerGram":0.1}'
   ```

## Notes

- `stripe trigger` creates and confirms a real test-mode PaymentIntent; the
  triggered event's PI carries the `--add` metadata, which is exactly what
  the app sets via `create-payment-intent`.
- The webhook returns `500` on database errors so Stripe retries with
  backoff — safe because crediting is idempotent on
  `stripe_payment_intent_id`.
- If events show `401` in `stripe listen`, the function was deployed with
  JWT verification on; redeploy `stripe-webhook` with `--no-verify-jwt`
  (config.toml already sets `verify_jwt = false` for CLI deploys).
