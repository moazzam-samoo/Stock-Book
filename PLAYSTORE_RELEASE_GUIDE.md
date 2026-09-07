# Play Store Release Guide — Stock Book

> Audit date: 2026-09-07, against `feat/positions-and-alerts` @ `d59eeb6` (+ uncommitted
> notification/alert fixes from this session). Re-run this checklist before every submission —
> some findings here are point-in-time (git state, dependency versions).

Findings are grouped by how much they block you. **Fix every 🔴 before you submit anything.**
🟠 will get you rejected or file a policy strike on a specific run, not always immediately.
🟡 won't block submission but will bite you operationally or looks unprofessional.

---

## 🔴 Blockers — fix these first, in this order

### 1. Release builds are signed with the **debug** keystore

`android/app/build.gradle.kts:38-44`:
```kotlin
buildTypes {
    release {
        // TODO: Add your own signing config for the release build.
        signingConfig = signingConfigs.getByName("debug")
    }
}
```
This has never been changed from the Flutter template default. You cannot publish a build signed
with the debug key — the debug keystore is a shared, non-secret, well-known key meant only for
local `flutter run --release` testing. If you've never uploaded to Play Console, this is
harmless so far; if you ever *have* uploaded a debug-signed AAB, treat that upload key as
compromised.

**Fix:**
1. Generate a real upload keystore (keep it **outside** the repo, back it up somewhere durable —
   losing it means you can never update this app again under the same listing):
   ```
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Create `android/key.properties` (add it to `.gitignore` — it is **not** there yet, add it now):
   ```
   storePassword=<...>
   keyPassword=<...>
   keyAlias=upload
   storeFile=<absolute path to upload-keystore.jks>
   ```
3. Wire it into `build.gradle.kts` — add a `signingConfigs { create("release") { ... } }` block that
   reads `key.properties`, and point `buildTypes.release.signingConfig` at it instead of `debug`.
4. Prefer **Play App Signing** (opt in when you create the release in Play Console) — Google then
   holds the real app signing key and your upload key only needs to sign the upload artifact,
   which is easier to rotate if it ever leaks.

### 2. No Privacy Policy

`sign_in_screen.dart:149` shows the text *"By signing in, you agree to our Terms & Privacy
Policy"* — as plain, unlinked text. There is no privacy policy document, URL, or webpage
anywhere in this repo or referenced by the app.

A live, publicly-reachable Privacy Policy URL is **mandatory** in the Play Console listing for
every app, and doubly so here: this app uses Google Sign-In, stores personal financial data
(portfolio holdings, invested amounts) in Firestore, and sends data to Firebase Crashlytics.
Play Console will not let you publish without this field filled with a working URL.

**Fix:** write one covering — what's collected (Google account email/name, portfolio/financial
data you enter, crash reports via Crashlytics, FCM push token), why, how it's stored (Firebase/
Google Cloud), that it's never sold/shared with third parties, and how a user can request
deletion (see next item). Host it somewhere permanent (GitHub Pages off this same repo is fine
and free) and link it both in the Play Console listing and from the sign-in screen's existing text.

### 3. No account/data deletion — required, and currently completely missing

Google Play's **Account Deletion** policy (mandatory since Nov 2023 for any app that lets a user
create an account) requires **both**:
- An in-app way to delete the account and its data, reachable without needing to contact support.
- A **web page** offering the same, reachable by someone who already uninstalled the app.

Checked `settings_screen.dart` — the ACCOUNT section (`_buildAccountSection`,
`settings_screen.dart:769`) only has **Sign Out** (`_confirmLogout:885`). There is no delete-account
flow anywhere in `lib/`, and no web page for it either.

**Fix:**
1. Add a "Delete Account" action in Settings → Account: confirm twice (this is destructive),
   then delete the user's Firestore data (`users/{uid}` and everything under it — positions,
   price_alerts, withdrawals, settings) and call `FirebaseAuth.instance.currentUser.delete()`
   (Google Sign-In users may need a fresh re-auth first — `delete()` throws
   `requires-recent-login` if the session is old; catch it and prompt a re-sign-in).
2. Publish a simple public web page (can live on the same GitHub Pages site as the privacy
   policy) explaining how to request deletion by email if they no longer have the app installed.
3. Fill in the "Data deletion" link field in Play Console's Data Safety section with that page.

### 4. On-demand refresh is broken for every real user except you

`workflow_trigger_service.dart` + `secure_token_storage.dart`, wired into Settings and
Transactions' pull-to-refresh: a user is expected to **generate their own GitHub personal access
token with write access to your private GitHub repo's Actions**, and paste it into Settings.
Without one, pull-to-refresh just shows *"Add a GitHub token in Settings to refresh prices on
demand."* forever (`WorkflowTriggerResult.message`, `noToken` case).

No real Play Store user will ever have a token for your GitHub repo — and even if a user
somehow obtained one, handing out `Actions: write` tokens to your private repo to the public is
a real abuse vector (anyone with a token can spam your Actions minutes/quota). This whole
feature only works because it's currently *your own* token on *your own* dev device.

**This is not a Play Store policy violation — it's a broken feature for 100% of your actual user
base**, and worth fixing before launch regardless of store review, or the "refresh" button (and
the confusing token field in Settings) is just dead weight that will generate support questions
and bad reviews from day one.

**Fix, pick one:**
- **Simplest — remove it for the public release.** Delete/hide the token field in Settings and
  the "trigger on pull-to-refresh" call; rely purely on the scheduled backend job (which already
  serves `market_prices/{ticker}` as one shared, top-level collection for *all* users — that part
  is architecturally fine and doesn't need per-user credentials). Pull-to-refresh can just re-read
  the current Firestore snapshot instead of trying to force a new backend run.
- **Better, more work — a real on-demand endpoint.** Stand up a small authenticated HTTP endpoint
  (Cloud Function is the natural fit, same Firebase project) that any signed-in app user can call
  to nudge a price refresh, without needing their own GitHub credentials — rate-limit it
  server-side so pull-to-refresh spam can't blow through your GitHub Actions minutes.

---

## 🟠 High priority — will get a specific submission rejected

### 5. Data Safety form accuracy (Play Console, not code)

Based on what this app actually does, the Data Safety declaration needs to include, at minimum:
- **Personal info**: name, email address (Google Sign-In)
- **Financial info**: user-entered purchase/sale prices, quantities, portfolio value — this is
  "Financial info" in Play's taxonomy and requires explicit disclosure
- **App activity / diagnostics**: crash logs and device info via Firebase Crashlytics
- **Device/other IDs**: FCM push token
- Declare whether data is encrypted in transit (yes, Firestore/Firebase — standard TLS) and
  whether users can request deletion (yes, once #3 above is built)

Mismatches between what's declared here and what the app actually does is one of the more common
real rejection/suspension reasons — don't rush this form.

### 6. Store listing assets — none of this exists yet in the repo

You'll need, outside the codebase, before you can even create the listing:
- App icon (512×512 PNG) — you have source art in `assets/icon/` (`Stockk.png`, `app_icon.png`)
  to derive it from, but it needs exporting at the exact required size.
- Feature graphic (1024×500 PNG/JPG)
- At least 2 phone screenshots (the files in `assets/screenshots/` — `dashboard.jpg`,
  `transations.jpg`, `settings.jpg`, `pdf.jpg` — are unused by the app itself, see #9 below, but
  could be a starting point for real store screenshots after a re-crop/re-export at current UI)
- Short description (≤80 chars) and full description (≤4000 chars) — `pubspec.yaml`'s
  `description:` field is still the Flutter template default `"A new Flutter project."`
  (`pubspec.yaml:2`) — harmless for the build itself, but fix it, it's sloppy if anyone checks
- Category (Finance is the obvious fit) and content rating questionnaire

### 7. Content rating questionnaire — likely fine, but do it carefully

This is a personal finance/investment tracker, not gambling or trading execution (no real broker
integration, no ability to place actual trades) — should land in a low content-rating tier, but
answer Google's questionnaire honestly rather than assuming; a financial-data app can trigger
extra scrutiny questions about real-money handling even without literal transactions.

---

## 🟡 Cleanup — not blockers, but worth doing before or shortly after launch

### 8. `firebase_analytics` is a declared dependency, never used

Confirmed via grep — zero references to `FirebaseAnalytics`/`firebase_analytics` anywhere in
`lib/`. Either wire it up for real usage insight (recommended before a public launch — you'll
want to know retention/funnel data) or drop the dependency to trim app size. Currently it's
dead weight either way.

### 9. `assets/screenshots/*.jpg` (4 files, unused) and other stray unused assets

`assets/screenshots/` is declared in `pubspec.yaml:117` and bundled into every build, but nothing
in `lib/` references it (`grep -rn "assets/screenshots" lib/` → 0 hits). Also worth checking
`assets/icon/` — several files there (`stock wallet.jpg` at 1.4MB, `dev.png` at 2MB, `google.png`)
look like leftover source art rather than things the running app actually loads at runtime.
Trimming these reduces your AAB size, which matters for install conversion.

### 10. No ProGuard/R8 minification configured

`build.gradle.kts`'s `release` block doesn't set `isMinifyEnabled`/`isShrinkResources`. Flutter
apps ship fine without this, but enabling it (with a `proguard-rules.pro` tuned for
Firebase/Riverpod/Freezed reflection-sensitive bits, tested carefully — R8 misconfiguration is a
classic "works in debug, crashes only in release" trap) shrinks the download size further.
Optional, not urgent.

### 11. `versionName`/`versionCode` housekeeping

`pubspec.yaml:19` → `version: 1.0.0+1`. Fine as your first release. Just remember Play Console
requires every subsequent upload to strictly increase the build number (`+1`, `+2`, ...) — decide
your versioning convention now (e.g. bump `+N` per upload, bump `1.0.x` per user-facing release)
so you're not improvising it under submission pressure later.

### 12. INTERNET permission — verify it survives into the release manifest

`android/app/src/main/AndroidManifest.xml` only explicitly declares `POST_NOTIFICATIONS`; `INTERNET`
only appears in `src/debug/` and `src/profile/` manifests. This is very likely fine in practice —
Firebase/`cloud_firestore`/`http`'s own Android library manifests each declare `INTERNET`
themselves, and Gradle's manifest merger folds that into the final release manifest automatically
— but **verify it for real** before submission rather than trusting this note:
```
flutter build appbundle --release
# then inspect the merged manifest, e.g. via bundletool or:
unzip -p build/app/outputs/bundle/release/app-release.aab base/manifest/AndroidManifest.xml | ...
```
or simpler: install the actual release build on a device and confirm sign-in/Firestore/network
calls all work (if INTERNET were truly missing, everything network-related would hard-fail).

---

## Suggested order of operations

1. Fix #4 (on-demand refresh) first — it's the one thing that actively embarrasses you in front
   of real users from minute one, and touching it is pure app code, no external accounts needed.
2. Fix #1 (signing) — mechanical, no design decisions, unblocks you actually producing a
   real release artifact to test everything else against.
3. Write and host the privacy policy + deletion page (#2 + #3's web half), build the in-app
   deletion flow (#3's app half).
4. Do a full real-device test of a **release-signed** build (not debug) — sign-in, add a
   position, live price refresh via the scheduled backend, a price alert firing, notification
   delivery, PDF export, theme toggle, offline behavior.
5. Prepare store listing assets + fill Data Safety form (#5, #6, #7) accurately against what the
   app in front of you actually does.
6. Clean up #8-#12 — can happen in parallel with the above or right after, none of it blocks
   submission.
7. Submit to the internal testing track first, not straight to production — cheaper to catch a
   mistake there.

---

## Operational note (not a Play Store issue, but real for launch)

The live price backend (`scripts/price_alerts/` + `.github/workflows/price-alerts.yml`) — the
thing that keeps every user's prices and alerts current — currently depends on: your personal
GitHub account (Actions minutes on the free tier), a personal access token you generated, and a
free cron-job.org account under your email pinging it every 5 minutes. None of this is visible to
users or reviewers, so it won't block a submission — but once real people depend on this app
working, it's worth treating this chain (GitHub Actions quota, your PAT's expiry date, the
cron-job.org account staying active) as production infrastructure, not a side project detail.
Put a reminder somewhere for your PAT's expiry date, and periodically confirm cron-job.org's job
is still enabled and firing.
