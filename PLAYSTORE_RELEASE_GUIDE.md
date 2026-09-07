# Play Store Release Guide — Stock Book

> Audit date: 2026-09-07, against `feat/positions-and-alerts` @ `d59eeb6`, **re-audited same day**
> after a full session of fixes — re-run this checklist before every submission, some findings
> are point-in-time (git state, dependency versions).

Findings are grouped by how much they block you. **Fix every 🔴 before you submit anything.**
🟠 will get you rejected or file a policy strike on a specific run, not always immediately.
🟡 won't block submission but will bite you operationally or looks unprofessional.

**Status since the original audit: items 1-3 below are now done.** Only #4 remains open, by
your own choice (deferred, not forgotten) — see its updated risk assessment below.

---

## ✅ Resolved

### 1. Release signing — DONE, code + real keystore both in place

`android/app/build.gradle.kts` now reads a real `signingConfigs.release` from `android/key.properties`
when present, falling back to the debug keystore only if that file is missing (so
`flutter run --release` still works before you've set it up). You've since generated a real
upload keystore and filled in `key.properties` yourself. **Before every real submission build**,
double check the resolved `signingConfig` was actually `"release"`, not `"debug"` — see the
AAB build section below for how to verify this from the built artifact itself.

### 2. Privacy Policy — DONE, live on GitHub Pages

`docs/privacy-policy.html` + `docs/account-deletion.html`, published via GitHub Pages from this
repo's `/docs` folder, linked from the sign-in screen. Both now also name the two owners by name.
Confirm the URL actually loads before you paste it into Play Console (GitHub Pages can take a
minute to rebuild after a push).

### 3. Account/data deletion — DONE, in-app + web both shipped

Settings → Account → Delete Account: two-step confirm (the second requiring you to type DELETE),
deletes every Firestore doc under `users/{uid}`, then the Firebase Auth account itself, handling
`requires-recent-login` with a fresh re-auth prompt. `docs/account-deletion.html` covers the
"I don't have the app installed" path with an email request. Fill in the "Data deletion" link
field in Play Console's Data Safety section with the `account-deletion.html` URL.

---

## 🔴 Still open

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

**Correction from the original audit** (you asked directly whether this risks a rejection —
researched properly rather than assumed): Google Play does have an actively-enforced
**"Broken Functionality" policy** — real developers get rejected/suspended under this exact name
for shipping a visible feature that doesn't work (confirmed via multiple live Google Play
Developer Community threads on this, e.g.
[thread 343091346](https://support.google.com/googleplay/android-developer/thread/343091346),
[thread 288394910](https://support.google.com/googleplay/android-developer/thread/288394910)).
I could not pull the exact verbatim policy wording (Google's own help pages didn't return full
text via fetch), so I can't promise a reviewer would flag *this specific* feature — but "a
Settings field asking for a personal access token to someone else's private GitHub repo, with a
refresh button that shows an error to literally every user who doesn't have one" is precisely the
shape of thing this policy exists to catch. Treat it as a real, not hypothetical, submission risk
— not just a UX problem — until it's fixed. This is true regardless of whether it's also
embarrassing in front of real users, which it independently is.

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

## Building the AAB for submission

Google Play has **required the Android App Bundle (`.aab`) format for all new app submissions
since August 2021** — a plain `.apk` upload is no longer accepted for a new listing. Enrolling in
**Play App Signing** (offered automatically the first time you upload an `.aab`) is effectively
mandatory alongside it — Google then re-signs your bundle with its own key for distribution,
which is also what lets Google generate optimized, smaller per-device APKs from your one bundle.

Build it with (this app has flavors — `prod` is the one that matters for a real release):
```
flutter build appbundle --release --flavor prod -t lib/main_prod.dart
```
Output lands at `build/app/outputs/bundle/prodRelease/app-prod-release.aab`. This is the file
you upload to Play Console, not any `.apk`.

**Verify it's actually signed with your release key, not debug**, before uploading — use
`jarsigner` (ships with the same JDK as `keytool`) against the bundle:
```
jarsigner -verify -verbose -certs build/app/outputs/bundle/prodRelease/app-prod-release.aab
```
and confirm the certificate fingerprint matches your `upload-keystore.jks`, not the well-known
public Android debug certificate.

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

### 6. Store listing assets — exact specs (verified against Google's own official page,
`support.google.com/googleplay/android-developer/answer/9866151`, 2026-09-07)

| Asset | Size | Format | Notes |
|---|---|---|---|
| **App icon** | exactly **512 × 512 px** | 32-bit PNG **with alpha** | max 1024 KB. You have source art in `assets/icon/` (`Stockk.png`) to derive it from — needs exporting at this exact size. |
| **Feature graphic** | exactly **1024 × 500 px** | JPEG or 24-bit PNG, **no alpha** | Required for every listing — the banner shown at the top of your store page. Nothing in the repo yet to derive this from; needs designing fresh. |
| **Phone screenshots** | **minimum 2, maximum 8** | JPEG or 24-bit PNG, no alpha | Each side between 320px–3840px; the longer side can be at most **2× the shorter side**. For a chance at "prominent placement" (Google's featuring algorithm), aim for **at least 4 screenshots at 1080×1920 (portrait, 9:16)** — comfortably matches this app's phone-only UI. |

The 4 files in `assets/screenshots/` (`dashboard.jpg`, `transations.jpg`, `settings.jpg`,
`pdf.jpg`) are old design-reference mockups, already un-bundled from the shipped app (see 🟡 #9)
— usable only as a rough starting point, since the UI has changed substantially since they were
captured; re-shoot real screenshots from a current build rather than editing these.

Also needed: short description (≤80 chars), full description (≤4000 chars) — `pubspec.yaml`'s
`description:` field (used for the Flutter package metadata, **not** the Play Store listing
copy — those are entered separately in Play Console) has already been updated away from the
template default, but you still need to write the actual Play Store listing copy separately —
and category (Finance is the obvious fit) plus the content rating questionnaire.

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
