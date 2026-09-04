# Phase 05 — Push notification infrastructure

> Read [../AGENTS.md](../AGENTS.md) and [README.md](README.md) before starting. The universal agent
> rules in README.md apply in full.

**Depends on:** nothing (can run in parallel with 03/04) · **Estimated:** 2 days · **Branch:** `feat/positions-and-alerts`

Plumbing only. This phase makes the app *able* to receive a push and route it. Nothing sends one
until Phase 08.

---

## Task 1 — Dependency and platform setup

- Add `firebase_messaging` to `pubspec.yaml`. Verify it resolves against the existing
  `firebase_core: ^4.12.1` — if it forces a major bump of other Firebase packages, **stop and report
  before proceeding**; a forced Firebase upgrade is its own piece of work, not a side effect of this one.
- Android: notification channel + icon per the `firebase_messaging` docs.
- Consider `flutter_local_notifications` for foreground display. Adding it is acceptable; say so
  prominently if you do.

### Manual steps you cannot do — list them in your report

1. Xcode: enable **Push Notifications** and **Background Modes → Remote notifications**.
2. Firebase console: upload an **APNs key**.

iOS push will not work until Moazzam does both. Say so plainly rather than implying iOS is done.

---

## Task 2 — Token storage

`users/{uid}` gains `fcmToken` (string, nullable) and `fcmTokenUpdatedAt` (timestamp).

The existing per-user rule in `firestore.rules` already covers `users/{uid}`, so no rule change is
needed — **verify that and state it in your report** rather than assuming.

Writing the token belongs in the data layer, not in a service reaching for Firestore directly.
`FirebaseAuthRepository` already merge-writes the user doc on sign-in (see `signInWithGoogle`) — the
cleanest fit is a small `UserRepository`, or an addition to that existing write. **Pick one and
explain the choice**; do not scatter Firestore calls into a service class.

---

## Task 3 — `PushNotificationService`

`lib/core/services/push_notification_service.dart`:

- `requestPermission()` — and handle **denial gracefully**. A user who says no must keep a fully
  working app with no errors, no retry loops, no nagging.
- `getToken()` → persist to `users/{uid}`.
- Listen to `onTokenRefresh` → re-persist. Tokens rotate; a stale token means silently missing alerts.
- `FirebaseMessaging.onMessage` (foreground) → in-app banner/snackbar.
- `FirebaseMessaging.onMessageOpenedApp` (background tap) → route.
- `FirebaseMessaging.instance.getInitialMessage()` (cold start from terminated) → route. **This one
  is the most commonly missed** — without it, tapping a notification when the app is fully closed
  opens the dashboard instead of the alert's target.

### Payload contract

Agree it now; Phase 08 must send exactly this:

```json
{ "type": "sell" | "buy", "ticker": "ENGRO", "positionId": "...", "alertId": "..." }
```

Routing:
- `type: "sell"` → `/stock/{ticker}`
- `type: "buy"`  → `/stock/{ticker}` (Phase 07 may refine this once the Alerts screen exists)
- unknown or malformed `type` → **dashboard, no crash.** Treat the payload as untrusted input.

Document this contract in the service's doc comment — Phase 08 will be written against it.

---

## Task 4 — Wiring

Initialise after successful sign-in, where a uid exists — the same place Phase 03B's migration runs.
Order matters: **migration first, then push init.** Coordinate rather than racing them.

Navigation from a tap needs a `GoRouter` reference outside widget context. The router is already a
provider (`appRouterProvider`) — read it through the Riverpod container rather than adding a global
navigator key, unless that proves impossible; if it does, explain why.

---

## Required tests

Mock `FirebaseMessaging` — do not hit the network.

| # | Test | Asserts |
|---|---|---|
| 1 | Token persisted on init | correct value written to `users/{uid}` |
| 2 | `onTokenRefresh` re-persists | new token written |
| 3 | Permission denied | init completes, no throw, app usable |
| 4 | Route `type: "sell"` | navigates to `/stock/{ticker}` |
| 5 | Route `type: "buy"` | navigates as specified |
| 6 | **Malformed payload** (missing `ticker`, unknown `type`, empty map) | no crash, lands on dashboard |
| 7 | `getInitialMessage` cold start | routes correctly |
| 8 | No uid | init is a safe no-op |

Test 6 matters most: the payload arrives from outside the app and must be treated as untrusted.

---

## Acceptance criteria

- [ ] `flutter analyze` — 0 errors; `flutter test` fully green
- [ ] Android: a manual FCM test message from the Firebase console arrives in foreground, background
      **and** terminated states, and taps route correctly — report which you actually verified
- [ ] Token visible in Firestore at `users/{uid}.fcmToken` after sign-in
- [ ] Denying permission leaves the app fully functional
- [ ] iOS manual steps clearly listed as outstanding

## Out of scope

Alert logic (06/07). The backend sender (08). Any UI beyond the foreground notification display.
