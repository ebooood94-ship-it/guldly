# Push Notifications — Implementation Plan (Option A)

**Status:** Not started. This is the design to execute when push becomes a
priority. Audit item 7 was resolved with option (b) (honest UI copy); this doc
is the deferred option (a).

**Context for whoever picks this up:** Today the notification toggles in
`notifications_screen.dart` only persist to `notification_preferences`. There
is no delivery for *any* channel — push, email, or SMS. `NotificationService`
(`savePushToken`, `initialize`, `listenForTransactions`) is dead code, never
called from anywhere. This plan covers **push only**; email/SMS are separate
builds.

---

## 1. Platform reality — decide this first

The app declares four targets (`flutter_launcher_icons`: android, ios, web,
windows). FCM does **not** cover them evenly:

| Target  | FCM support | Notes |
|---------|-------------|-------|
| Android | Full        | Native FCM. Needs `google-services.json`. |
| iOS     | Full        | FCM over APNs. Needs APNs auth key (.p8) + push entitlement + real device (no Simulator before iOS 16, flaky after). |
| Web     | Partial     | FCM JS SDK + service worker + VAPID key. Safari/iOS-web support is unreliable; desktop Chrome/Firefox/Edge are fine. |
| Windows | **None**    | FCM has no Windows transport. A Windows build silently gets no push. |

**Recommendation:** Scope the first release to **Android + iOS**, treat **web
as a fast-follow** (desktop browsers only, no promises on Safari/iOS-web), and
**explicitly exclude Windows** — guard all messaging code behind
platform checks so the Windows build compiles and no-ops rather than crashing.
Because the app's current live surface is web + Windows, be honest that this
work primarily benefits the *mobile* apps; if mobile isn't shipping soon, that
is itself an argument to keep deferring (a).

---

## 2. What already exists (don't rebuild)

- **`push_tokens` table** — `id`, `user_id` (FK auth.users), `token`,
  `platform`, `created_at`. RLS policy `push_tokens: own all`
  (`auth.uid() = user_id`) already allows the client to insert/update/delete
  its own rows.
- **Unique index** `push_tokens_user_id_token_key` on `(user_id, token)` —
  verified present, so `NotificationService.savePushToken`'s
  `upsert(..., onConflict: 'user_id, token')` works today without change.
- **`NotificationService.savePushToken(token, platform)`** — ready to call.
- **`notification_preferences`** — `push_price_alerts`,
  `push_transaction_updates`, `push_promotions` booleans already stored per
  user; the send path just needs to honor them.

So the token-storage half is done. The missing pieces are: the Firebase/FCM
SDK + credentials, the permission/registration flow, and the server-side send.

---

## 3. Prerequisites (infra & credentials)

1. **Firebase project** (one project, multiple apps registered under it).
2. **Android app** in Firebase → download `google-services.json` →
   `android/app/`.
3. **iOS app** in Firebase → download `GoogleService-Info.plist` →
   `ios/Runner/`. Create an **APNs auth key (.p8)** in the Apple Developer
   portal and upload it to Firebase → Project Settings → Cloud Messaging.
   Enable the Push Notifications capability + Background Modes (Remote
   notifications) in Xcode.
4. **Web app** (if/when web push ships) → generate a **Web Push certificate
   (VAPID key pair)** in Firebase → Cloud Messaging → and add a
   `firebase-messaging-sw.js` service worker under `web/`.
5. **Service account for FCM HTTP v1** — Firebase → Project Settings →
   Service accounts → generate a private key JSON. This is what the edge
   function uses to mint OAuth2 access tokens. **Store it as a Supabase
   secret, never in the repo.**

---

## 4. Client work (Flutter)

### 4a. Dependencies
Add to `pubspec.yaml`: `firebase_core`, `firebase_messaging`. Run
`flutterfire configure` to generate `lib/firebase_options.dart`.

### 4b. Init
- `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` in
  `main.dart`, guarded so Windows is skipped (`defaultTargetPlatform` check).
- Keep `NotificationService.initialize(supabase)` — it's already the right home
  for this.

### 4c. Permission + registration (on first login, not app start)
Do this **after** authentication, so the token is tied to a real user and the
OS prompt appears in a meaningful context (Apple/Google both penalize
prompting cold at launch):

1. `FirebaseMessaging.instance.requestPermission()` (iOS/web require it;
   Android 13+ needs the `POST_NOTIFICATIONS` runtime permission too).
2. If granted → `getToken()` (pass `vapidKey` on web) →
   `NotificationService.savePushToken(token, <platform>)`.
3. Register `onTokenRefresh.listen(...)` → re-save on rotation.
4. On explicit sign-out, delete the current device's row (so a shared device
   doesn't leak the previous user's pushes) — add a
   `NotificationService.removePushToken(token)` and call it from `signOut`.

Wire this into the existing first-login path (`firstLoginSetupProvider` in
`providers.dart` is the natural anchor — it already runs idempotent per-user
setup on auth).

### 4d. Message handling
- **Foreground:** `FirebaseMessaging.onMessage` → reuse the existing in-app
  banner (`NotificationService._showBanner`), so foreground pushes and the
  realtime transaction banner look consistent.
- **Background/terminated:** a top-level `@pragma('vm:entry-point')`
  `onBackgroundMessage` handler; tapping a notification →
  `onMessageOpenedApp` → deep-link into the relevant screen (e.g. `/receipt`
  or `/portfolio`) via the existing `go_router`.
- **Web:** the `firebase-messaging-sw.js` service worker handles background
  display.

---

## 5. Server work (Supabase + FCM HTTP v1)

### 5a. New edge function `send-push`
- Reads the target user's `push_tokens` and their `notification_preferences`.
- Mints an OAuth2 token from the service-account JSON (JWT grant against
  `https://oauth2.googleapis.com/token`, scope
  `https://www.googleapis.com/auth/firebase.messaging`) — cache it for its
  ~1h lifetime.
- POSTs to
  `https://fcm.googleapis.com/v1/projects/<PROJECT_ID>/messages:send` once per
  token.
- **Token hygiene:** on `404`/`400 UNREGISTERED` responses, delete that
  `push_tokens` row (stale tokens accumulate fast otherwise).
- Deploy with `verify_jwt = true` if only called from other trusted
  server contexts, or gate with a shared secret if called from a DB webhook.
- Secret: `FCM_SERVICE_ACCOUNT` (the JSON), plus `FCM_PROJECT_ID`.

### 5b. Triggering — two categories

**Transaction events** (`push_transaction_updates`): the cleanest hook is a
row-level `AFTER INSERT` on `transactions` that calls `send-push` via `pg_net`
(async HTTP from Postgres; already available on Supabase). Filter to the
statuses/types worth pushing (e.g. `gift_received`, completed `buy` from the
Stripe webhook, `recurring_buy`). Alternatively, call `send-push` directly from
the existing `stripe-webhook` and gift-claim paths — more explicit, avoids a
DB-triggered fan-out. Prefer folding it into those existing server flows over a
broad table trigger.

**Price alerts** (`push_price_alerts`): this is a **bigger sub-project**, not a
quick add. It needs (1) a per-user threshold model — there is no schema for
"notify me when gold crosses X" today, only a boolean — and (2) a scheduled
job (extend the existing `pg_cron` setup that already runs
`process_due_subscriptions`) that pulls the live price via the `get-gold-price`
function and diffs it against each user's threshold with debouncing so one
crossing doesn't spam. Recommend shipping transaction pushes first and treating
price alerts as a follow-up milestone.

### 5c. Respect preferences
`send-push` must check the matching `notification_preferences` flag before
sending and skip users who toggled it off. This is the payoff that makes the
toggles real.

---

## 6. Testing plan

1. **Raw FCM sanity (no app logic):** grab a real device token (log it from
   `getToken()`), then send via the FCM HTTP v1 API using the service account
   — confirm it arrives. This isolates credentials/APNs setup from app code.
2. **Firebase console test:** Cloud Messaging → "Send test message" → paste the
   token → confirm foreground + background + terminated delivery on a physical
   Android device and a physical iOS device (iOS **must** be a real device).
3. **Web (if in scope):** desktop Chrome, confirm the service worker shows a
   background notification; note Safari/iOS-web as known-flaky.
4. **End-to-end via the app:** buy gold with a test card → Stripe webhook
   credits → `send-push` fires → push arrives with the right copy and
   deep-links to the receipt.
5. **Preference honored:** toggle `push_transaction_updates` off → repeat →
   confirm **no** push.
6. **Stale-token cleanup:** uninstall/reinstall to invalidate a token → send →
   confirm the `push_tokens` row is deleted on the `UNREGISTERED` response.
7. **Windows no-op:** confirm the Windows build compiles and runs with
   messaging guarded off (no crash, no prompt).

---

## 7. When it ships — revert the honest-copy UI

In `notifications_screen.dart`, once push is live for a channel:
- Remove the `BannerVariant.warning` `InfoBanner`.
- Drop the `(KOMMER SNART)` suffix from the section header(s) that are now
  real (do it per-channel — don't un-hide email/SMS if only push shipped).
- Restore active-delivery subtitles for the push rows (the item-7 change
  neutralized them to non-promising descriptions).

---

## 8. Rough sequencing & effort

1. Firebase project + Android/iOS credentials + `flutterfire configure` — ~0.5 day.
2. Client: init, permission/registration on login, token refresh, sign-out
   cleanup, foreground/background handlers — ~1–2 days.
3. `send-push` edge function (OAuth2, HTTP v1, token hygiene) + secrets — ~1 day.
4. Wire transaction pushes into the Stripe webhook + gift-claim paths — ~0.5 day.
5. Testing across real devices — ~1 day.
6. **Price alerts (separate milestone):** threshold schema + cron diff +
   debounce — ~2–3 days on its own.

**Biggest risks / footguns:** iOS APNs setup (auth key, entitlements, real
device required); prompting for permission at the right moment (not cold at
launch); stale-token accumulation if `UNREGISTERED` cleanup is skipped; and web
push being quietly unreliable on Safari/iOS. None are blockers — they're the
usual FCM tax, which is exactly why (b) was the right first call.
