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

- [x] `flutter analyze` — 0 errors; `flutter test` fully green
- [x] Android: a manual FCM test message from the Firebase console arrives and taps route correctly —
      verified foreground on a real device (SM-A175F); background/terminated not separately confirmed
- [x] Token visible in Firestore at `users/{uid}.fcmToken` after sign-in
- [ ] Denying permission leaves the app fully functional — implemented and unit-tested, not yet
      manually re-verified on-device (device already had permission granted from earlier testing)
- [x] iOS manual steps clearly listed as outstanding

## Out of scope

Alert logic (06/07). The backend sender (08). Any UI beyond the foreground notification display.

---

## Review notes (2026-09-05)

Reviewed the implementation against this brief. All 4 tasks have real, substantial code; 8/8 required
tests were present but one was subtly wrong. Found and fixed:

- **`android/app/src/main/AndroidManifest.xml` was missing `POST_NOTIFICATIONS`.** On Android 13+
  (API 33+) this permission must be declared or `FirebaseMessaging.requestPermission()` has nothing
  to grant — notifications are silently blocked by the OS regardless of what the app does. This
  directly affects a real Android 13+ test device. Added `<uses-permission
  android:name="android.permission.POST_NOTIFICATIONS" />`.
- **`test/data/repositories/user_repository_impl_test.dart`'s "swallows timeout (offline tolerance)"
  test asserted nothing** (`expect(true, isTrue)`). Rewrote it to stub a 5s-delayed mock write and
  assert the call returns in well under the internal 4s timeout — proving the timeout genuinely fires
  rather than the test just passing regardless.
- **`test/core/services/push_notification_service_test.dart` test 8 was mislabeled.** Its docstring
  claimed "no uid → safe no-op" but its body only checked that calling `initialize()` twice requests
  permission once (a real behavior, just not this one). Renamed that test and wrote a genuine test 8
  using a `ProviderContainer` with `currentUserIdProvider` overridden to `null`, asserting
  `pushNotificationServiceProvider` resolves to `null`.
- **`mockGoRouter.push(...)` was never stubbed**, so tests 4, 5, and 7 (all three routing tests) were
  passing for the wrong reason: Mockito throws `MissingStubError` on an unstubbed non-void mock call,
  `_routeData`'s own try/catch silently swallowed it and fired the `go('/')` fallback, and Mockito's
  `verify()` still recorded the `push()` attempt as having happened — so the assertions passed even
  though the fallback path was *also* firing right after, undetected. Added the missing stub to
  `setUp()` and `verifyNever(mockGoRouter.go(any))` to tests 4/5/7 to prove the fallback genuinely
  isn't taken on the success path. Re-ran the file — clean, no more `MissingStubError` in the log.
- Removed a handful of unused imports/locals introduced alongside the feature: an unused `android`
  local in `_onForegroundMessage`, an unused `cloud_firestore` import in the domain-layer
  `user_repository.dart` (a layering smell — domain must not import data-layer packages), an unused
  `firestore_data_source.dart` import in `user_repository_impl.dart`, and an unused
  `market_prices_providers.dart` import in `dashboard_screen.dart`.

Verified, not changed:
- `firestore.rules` needs no changes — the existing per-user `users/{userId}` rule already covers
  arbitrary field writes including `fcmToken`/`fcmTokenUpdatedAt`. Confirmed correct as the brief
  claimed.
- Foreground messages are shown via `flutter_local_notifications` rather than an in-app
  banner/snackbar — this deviates from Task 3's literal wording but was pre-approved by Task 1
  ("Consider `flutter_local_notifications`... say so prominently if you do"). Noting it here as that
  disclosure.
- `pubspec.lock`: adding `firebase_messaging: ^16.6.0` bumped `firebase_core` 4.12.1 → 4.14.0 and its
  own transitive deps (`firebase_core_platform_interface`, `firebase_core_web`,
  `_flutterfire_internals`) — all minor/patch bumps within `firebase_core`'s own family.
  `firebase_auth`, `cloud_firestore`, `firebase_crashlytics`, and `firebase_storage` versions are
  untouched. This does not trigger the brief's "major bump" stop-and-report condition.
- `UserRepositoryImpl` takes a raw `FirebaseFirestore` instead of going through the shared
  `FirestoreDataSource` abstraction every other repository uses — same judgment call already made (and
  left as-is) for `MarketStatusRepositoryImpl` in Phase 04B: low-risk, noted, not fixed.
  `pushNotificationServiceProvider` is a plain `Provider` while the `appRouterProvider` it reads is
  `AutoDisposeProvider` — a Riverpod anti-pattern that compiles fine and is low-risk since the router
  provider is kept alive by the root widget for the app's whole session. Not fixed.

Not addressed (flagged, out of the coding agent's reach):
- No iOS notification sound resource exists anywhere in the iOS project (`DarwinNotificationDetails`
  references `'stock_alert.wav'`, but only `android/app/src/main/res/raw/stock_alert.wav` exists).
  Lower priority since iOS push is already non-functional pending the two manual Xcode/Firebase
  Console steps below — but add the sound file before iOS push is otherwise wired up.
- The two manual iOS steps listed in Task 1 are still outstanding and must be done by Moazzam:
  Xcode Push Notifications + Background Modes capabilities, and uploading an APNs key in the Firebase
  console.

**Addendum (2026-09-05, after a real device build attempt):** `flutter run` failed with `Dependency
':flutter_local_notifications' requires core library desugaring to be enabled for :app` — a Gradle-level
requirement that `flutter analyze`/`flutter test` cannot catch, since it only surfaces at actual build
time. Fixed in `android/app/build.gradle.kts`: added `isCoreLibraryDesugaringEnabled = true` to
`compileOptions`, and a `dependencies { coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") }`
block (the file had no `dependencies` block before).

**Second addendum (2026-09-05, same device build attempt):** after the desugaring fix, the build failed
again — `firebase_auth`'s Android plugin (`FlutterFirebaseAuthPlugin.java:140`) couldn't find
`FlutterFirebaseCorePlugin.customAuthDomain`. Root cause: `firebase_messaging: ^16.6.0` requires
`firebase_core: ^4.14.0` as a hard floor, and `firebase_core` 4.14.0 did a full Kotlin rewrite of its
Android native code — `customAuthDomain` moved from a static field on `FlutterFirebaseCorePlugin` to an
instance field on `FlutterFirebasePlugin`. The pinned `firebase_auth: ^6.5.6` predates that rewrite and
still called the old location; its own `pubspec.yaml` only requires `firebase_core: ^4.12.1`, so pub's
resolver considered 6.5.6 + 4.14.0 a valid combination even though the native code doesn't actually
support it — a real instance of the version-skew risk this brief's Task 1 flagged, just one dependency
removed from the direct bump, so the earlier "no major bump" `pubspec.lock` check didn't catch it (this
is a minor-version but still build-breaking native-code change). Confirmed via the FlutterFire
changelog that `firebase_auth` 6.6.0 was released as part of the same coordinated
core+auth-migrate-to-Kotlin release wave as `firebase_core` 4.14.0. Fixed by bumping
`firebase_auth: ^6.5.6` → `^6.6.1` in `pubspec.yaml`. Verified with a full local `flutter build apk
--flavor dev --debug` (no device needed) — built cleanly, `app-dev-debug.apk` produced.

**Third addendum (2026-09-05, first real on-device run):** the app installed and launched, but
`push_notification_service.dart`'s `_localNotifications.initialize(...)` threw
`PlatformException(invalid_icon, ...)` on every launch — `AndroidInitializationSettings('ic_launcher')`
references a **drawable** resource, but `ic_launcher` only exists as a **mipmap** resource (the
generated adaptive launcher icon). Because this call sits early in `initialize()`'s try block, the
exception was caught by the outer catch and silently aborted the *entire* method — meaning nothing
after it (token retrieval/save, `onTokenRefresh`, `onMessage`, `onMessageOpenedApp`,
`getInitialMessage`) ever ran on a real device, despite every mocked unit test passing (the tests mock
`FlutterLocalNotificationsPlugin` entirely, so this never surfaced there). Fixed by pointing at
`ic_launcher_foreground` instead — the adaptive icon's foreground layer, which does exist as a drawable
across all density buckets. Dart-only change, no native rebuild needed. Cosmetic note for later polish:
Android renders notification-tray icons as a white silhouette from the alpha channel, and
`ic_launcher_foreground` wasn't designed for that — a dedicated small monochrome notification icon
would look better, but this unblocks functional testing now.

Separately observed on the same run, unrelated to this phase: an unhandled `Bad state: Future already
completed` exception inside `AuthController.signInWithGoogle` (`auth_controller.dart:13`), thrown from
Riverpod's internal `AsyncNotifier` state machinery. Sign-in appeared to succeed anyway (Firebase Auth
logged the user in immediately after). This is pre-existing auth-flow code untouched by Phase 05 and
only surfaced now because this is the first real on-device Google Sign-In test in this engagement
(earlier phases were only tested via widget tests with mocked repositories) — flagging for a future
look, not fixed here as out of this phase's scope.

Final state: `flutter analyze` — 0 errors, 34 warnings (all pre-existing baseline categories: `openBox`
type inference, `JsonKey` annotation targets, unrelated unused imports, `Future.delayed` inference, and
the generator-side `.mocks.dart` `duplicate_ignore` quirk already seen in Phase 04B). `flutter test` —
180/180 passing. No golden images affected (expected — this phase is non-UI plumbing). Uncommitted,
awaiting manual verification.

**Fourth addendum (2026-09-05, manual on-device verification by Moazzam):** confirmed on a real Android
device (Samsung SM-A175F, Android 16/API 36): notification received and displayed correctly; tapping a
test push sent with `type`/`ticker` custom data routed to the correct `/stock/{ticker}` screen. First
tap attempt landed on the dashboard instead — traced to the test message not having the custom `data`
payload set (Firebase Console's "Send test message" only includes custom data if it's added under
"Additional options" on the campaign form first); once resent correctly, routing worked as designed.
This also incidentally re-confirms Test 6's malformed-payload fallback behavior for free, since that's
exactly what a payload with no `ticker`/`type` correctly falls back to.

Android acceptance criteria now verified: token appears at `users/{uid}.fcmToken` in the live Firestore
project, permission prompt appears and is handled, notification displays, and tap-routing works. Not
separately confirmed: background and fully-terminated states specifically (only one on-device pass was
reported) — worth a quick recheck before considering Android fully signed off, but the core plumbing is
proven working end-to-end.

**Still outstanding:**
- Background and terminated-state tap-routing on Android — not separately confirmed (see above).
- iOS: both manual steps (Xcode Push Notifications + Background Modes capability, APNs key upload in
  Firebase console) still outstanding, plus the missing `stock_alert.wav`-equivalent sound resource in
  the iOS project noted earlier.
