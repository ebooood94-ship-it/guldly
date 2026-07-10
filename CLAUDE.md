# Guldly — Project Instructions

Flutter app for buying, selling, gifting, and taking delivery of physical gold, priced live in SEK. Read this before making changes.

## Tech stack

- **Flutter (Dart)** — `sdk: '>=3.0.0 <4.0.0'`
- **go_router ^13** for navigation
- **flutter_riverpod ^2.5** for state management (no other state approach — don't introduce Provider, Bloc, GetX, etc.)
- **Supabase** (`supabase_flutter`) for auth, Postgres, RLS, edge functions, and realtime. Project ref: `njcwivpthvrpqocibrpb`.
- **Stripe** (`flutter_stripe` on mobile, Stripe Checkout redirect on web via an edge function — `flutter_stripe` does not work on web, don't try to make it)
- **google_fonts** (Plus Jakarta Sans / Playfair Display / Inter — check `app_theme.dart` before adding a new font)
- **intl** for number/date formatting, always Swedish locale (`sv_SE`) for currency
- Gold price: Supabase edge function `get-gold-price` → Yahoo Finance (XAU futures) + Frankfurter (USD→SEK), refreshed every 60s client-side. Not GoldAPI/MetalPriceAPI — that's what an earlier version used, it's been replaced.
- Money math for buys/sells/gifts/delivery happens in Postgres `SECURITY DEFINER` RPCs (`rpc_buy_gold`, `rpc_sell_gold`, `rpc_send_gift`, `rpc_request_delivery`, `rpc_add_funds`), not in Dart. Never write a screen that mutates `wallets` or `transactions` directly from the client — always go through the RPC.

## Repo layout

```
lib/
├── main.dart                    Supabase + Stripe init, ProviderScope, GoRouter
├── core/
│   ├── constants/app_constants.dart   Colors, spacing, radii — the ONLY source of design tokens
│   ├── models/models.dart             GoldPrice, UserProfile, Wallet, Transaction, Subscription, NotificationPreferences
│   ├── router/router.dart             GoRouter + Routes class + auth/onboarding redirect logic
│   ├── providers/providers.dart       All Riverpod providers + GoldTransactionService + AuthNotifier
│   ├── services/                      stripe_service.dart, notification_service.dart
│   ├── utils/                         error_utils.dart (friendlyError), web_redirect.dart (conditional web/native)
│   └── theme/app_theme.dart
└── presentation/
    ├── screens/           one folder per feature (auth, buy_gold, wallet, portfolio, more, sell, gift, delivery, transaction, shell, dashboard)
    └── widgets/
        ├── common/        shared, generic widgets
        └── gold/          gold-domain-specific widgets (chart, portfolio card, live badge, etc.)

supabase/
├── migrations/            numbered SQL migrations — always add a new one, never hand-edit an old one
└── functions/             edge functions (get-gold-price, create-payment-intent)
```

## Hard rules — don't violate these

- **Never** use `Navigator.push` — always `context.push('/route')` / `context.go('/route')` via go_router.
- **Never** use Flutter's built-in `TextField` directly in a screen — always `GoldTextField`.
- **Never** hardcode a `Color(0x...)` or `Colors.*` in a screen — always `AppConstants.<token>`. If the token doesn't exist, add it to `AppConstants` first.
- **Never** write business logic (balance checks, gold-gram math, transaction status) in Dart that should live in a Postgres RPC. The RPC is the source of truth for money; Dart just calls it and renders the result.
- All shared widgets are public (no underscore prefix) and live in `widgets/common/` or `widgets/gold/`. Screen-specific state classes keep the underscore (`_HomeScreenState`).
- Import `package:flutter_riverpod/flutter_riverpod.dart` in any file using `ConsumerWidget` / `ConsumerStatefulWidget` / `ref.watch` / `ref.read`. Import `package:go_router/go_router.dart` in any file using `context.push` / `context.go` / `context.pop`.
- All user-facing copy is Swedish. Keep it that way — don't introduce English strings into screens.

## Security posture (read before touching auth, payments, or RPCs)

This app moves real money and real gold grams. Treat every change here more carefully than a typical CRUD screen:

- Any new payment method must either go through a verified server-side flow (Stripe webhook, not just a client-side "it succeeded" callback) or be explicitly marked `pending` until verified. Do not add a payment path that credits gold/balance based solely on the client telling the server it paid.
- New Postgres functions default to being callable over PostgREST by `anon`/`authenticated` if you don't lock them down. If a function is trigger-only or cron-only, `REVOKE EXECUTE` from those roles. If it's a client-facing RPC, restrict to `authenticated` only.
- Every `SECURITY DEFINER` function needs `SET search_path = public, pg_temp` — this is not optional, it's a standard Postgres hardening step.
- Run the Supabase advisor (`get_advisors`, security type) after any migration that adds/changes a function. Don't consider a migration done until it's clean or you've consciously accepted a flagged risk.
- RLS must stay enabled on every table. If you add a table, enable RLS and write policies before shipping, not after.

## Keep it simple

- Prefer editing an existing screen/widget over creating a new abstraction. This is a small app — don't introduce a repository layer, a DI framework, or a new state-management pattern to solve a problem `ref.watch`/`FutureProvider` already solves.
- Don't add a new package for something two lines of Dart can do.
- If a fix touches more than the file(s) the bug is actually in, stop and explain why before widening the change.
- Favor one Postgres migration per logical change, with a clear filename (`00N_description.sql`), over editing history.

## Skills to reach for

- **`engineering:code-review`** before merging anything that touches money (buy/sell/gift/delivery/wallet flows) or Supabase RPCs/RLS — treat these diffs as higher stakes than a UI tweak.
- **`engineering:debug`** for anything that "works in one place but not another" (e.g. web vs. mobile Stripe paths, which have bitten this app before).
- **`engineering:testing-strategy`** — this project currently has zero test coverage; use this skill when adding the first real test suite rather than guessing structure.
- **`engineering:deploy-checklist`** before pushing schema migrations or edge function changes to the live Supabase project — there's no staging environment, changes go straight to production data.
- **Supabase agent skill** (`npx skills add supabase/agent-skills`) for anything involving migrations, RLS policies, or RPC design — install it if not already present.
- **`design-taste-frontend`** / **`impeccable`** if asked to touch visual design — but check `app_theme.dart` and `AppConstants` first; this app already has an established look, don't reinvent it.

## Review checklist before calling anything "done"

1. `flutter analyze` — zero new warnings.
2. `flutter test` — passes (and add a test if you touched money math or a provider).
3. If you touched a Supabase function: re-run the security advisor and confirm no new warnings.
4. If you touched a payment or balance flow: trace through what happens if the RPC throws mid-way, and what the user sees — never leave a debited wallet with no completed transaction, or vice versa.
5. Read your own diff once, end to end, before saying you're done. Don't ship the first version that compiles.

## Known unresolved issues

See `docs/audit-2026-07-10.md` for the full list (bank-transfer instant-credit bug, unverified Stripe payments, exposed RPCs, silent gift loss for non-users, non-functional push toggles, zero test coverage). See `docs/claude-code-prompts.md` for the fix plan, in priority order. Check both before assuming something is "already working."
