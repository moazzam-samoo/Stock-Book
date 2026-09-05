# Target Price Alerts + Live Market Prices — Implementation Plan (Stock Book)

Repo: `moazzam-samoo/Stock-Book`
Stack: Flutter + Riverpod + Hive (offline-first) + Firebase (Auth, Firestore, Crashlytics, Analytics)

Goals:
1. When a stock's live market price reaches/exceeds the `targetPrice` set on a `Lot`, send the user a push notification (a **sell alert** — you already own it, waiting to hit your sell target).
2. Show the real current PSX market price for each held ticker in the app (lot cards, stock detail, dashboard) — not just the static buy price — so users see live gain/loss.
3. A separate **buy alert** feature: let the user watch a ticker they don't yet own and get notified when its price hits or comes near a target buy price (e.g. "notify me when GUSM is at or near 8.60"). This is independent of any `Lot`, since the stock isn't held yet — it needs its own screen and its own Firestore data.

All three goals are fed by **one shared backend job**: a scheduled Cloud Function fetches live prices once (for every ticker that's either held or being watched) and writes them to a shared Firestore collection. Both the sell-alert check and the buy-alert check read from that same collection, and the Flutter app reads from it too for live price display (offline-cached via Hive like everything else in the app). This avoids building three separate price-fetching paths.

---

## 1. Current State (already in repo)

- `Lot` entity (`lib/domain/entities/lot.dart`) already has `targetPrice` (nullable double).
- `LotModel` (`lib/data/models/lot_model.dart`) already persists `targetPrice` to Firestore.
- Firestore layout: `users/{uid}/lots/{lotId}` (see `lib/core/constants/firestore_paths.dart`).
- `LotStatus`: `open`, `partiallySold`, `closed`.
- Dashboard/lot cards currently only show buy price and derived values (`PortfolioCalculator`) — no live market price anywhere.
- No `firebase_messaging` package yet.
- No Cloud Functions directory yet.
- No field on the user for storing a device/FCM token.
- No concept of a shared/global (non-per-user) Firestore collection yet — everything is scoped under `users/{uid}`.

## 2. What's Missing

| Piece | Where |
|---|---|
| A shared collection of live prices per ticker | Firestore (new, top-level, not per-user) |
| Scheduled job to fetch PSX prices and populate it | Cloud Functions backend |
| Client read + display of live price | Flutter app (dashboard, lot card, stock detail) |
| FCM client setup (permission, token, foreground/background handling) | Flutter app |
| Store FCM token per user | Firestore `users/{uid}` |
| Prevent duplicate/repeat alerts once target is hit | Firestore `users/{uid}/lots/{lotId}` |
| Sell alert-check logic (reuses the shared prices collection) | Cloud Functions backend |
| New "buy alert" entity + screen (watch a ticker you don't own) | Flutter app (new screen) + Firestore (new collection) |
| Buy alert-check logic (at-or-near target) | Cloud Functions backend |
| Sending the actual push (sell or buy) | Cloud Functions backend (Admin SDK) |
| Notification tap → navigate to stock detail (or an "add to holdings" flow for buy alerts) | Flutter app (GoRouter) |

## 3. Data Model Changes

**New top-level collection: `market_prices/{ticker}`** (shared across all users, not per-uid):
```json
{
  "ticker": "ENGRO",
  "price": 350.25,
  "updatedAt": "timestamp"
}
```
- Written only by the Cloud Function (Admin SDK). Read-only from the client.
- One doc per ticker that at least one user currently holds **or is watching via a buy alert** — no point fetching prices for tickers nobody cares about.

**New collection: `users/{uid}/price_alerts/{alertId}`** (buy alerts — for tickers not yet owned):
```json
{
  "id": "auto-id",
  "ticker": "GUSM",
  "targetPrice": 8.60,
  "tolerancePercent": 1.0,
  "isActive": true,
  "alertSent": false,
  "alertSentAt": null,
  "createdAt": "timestamp"
}
```
- `tolerancePercent` is what makes this "at or near" rather than an exact match — e.g. `1.0` means the alert fires once the live price is at or below `targetPrice * 1.01` (so a small margin above the buy target counts as "near", not just exactly at or below it).
- Trigger condition: `currentPrice <= targetPrice * (1 + tolerancePercent / 100)`.
- After firing, `isActive` can be set to `false` automatically (one-shot, like the sell alert) — or the user can leave it active and just get one notification per drop-below event (`alertSent` guards against repeat spam the same way `targetAlertSent` does for sell alerts). Recommend one-shot for v1; add re-arming as a later refinement if wanted.
- This is intentionally a **separate collection from `lots`**, since the ticker isn't held yet — it has no buy price, no shares, nothing that belongs on a `Lot`.

**`users/{uid}` document** — add:
```json
{
  "fcmToken": "string | null",
  "fcmTokenUpdatedAt": "timestamp"
}
```

**`users/{uid}/lots/{lotId}` document** — add:
```json
{
  "targetAlertSent": false,
  "targetAlertSentAt": null
}
```
- `targetAlertSent` resets to `false` whenever `targetPrice` is changed/cleared by the user, or when a new buy is added to the lot (edit paths already exist in `edit_lot_bottom_sheet.dart` / `add_buy_controller.dart`).

## 4. Flutter Client Changes

### 4a. Live market price display (new)
1. **New data source**: `lib/data/data_sources/remote/market_price_data_source.dart` — wraps a Firestore listener on `market_prices/{ticker}` (single doc stream) and `market_prices` (multi-doc, `whereIn` batched by held tickers, Firestore limits `whereIn` to 30 values so batch if a user holds more).
2. **New repository**: `MarketPriceRepository` (domain interface + impl), following the exact pattern already used by `LotRepository`/`SaleRepository`. Expose `Stream<double?> watchPrice(String ticker)` and `Stream<Map<String, double>> watchPrices(List<String> tickers)`.
3. **Hive cache**: add a small Hive box (`market_prices_cache`) so the last-known price displays instantly offline, same offline-first pattern as `HiveDataSource` for lots — write-through on every Firestore update, read on cold start before the stream emits.
4. **UI updates**:
   - `lib/presentation/transactions/widgets/lot_card.dart`: show live price next to buy price, plus a live "+X.X% vs current" using live price instead of (or alongside) the existing target-based estimate.
   - `lib/presentation/dashboard/screens/stock_detail_screen.dart`: show current market price prominently, likely feeding into a new "unrealized P/L" figure (current holdings valued at market price vs. amount invested) — note this is a new metric not currently in `PortfolioCalculator`; extend it there rather than computing ad hoc in the widget.
   - `lib/presentation/dashboard/widgets/portfolio_header.dart` / `stat_card_grid.dart`: optionally roll live prices into total portfolio value if that's wanted (confirm with user before making this the default — it changes what "Total Portfolio Value" means).
   - Show a "last updated" timestamp (from `market_prices.updatedAt`) somewhere visible, since prices refresh every ~15 min, not real-time tick-by-tick.

### 4b. Push notifications for target price hits
1. **Add dependency**: `firebase_messaging` in `pubspec.yaml`.
2. **New service**: `lib/core/services/push_notification_service.dart`
   - Request notification permission (`FirebaseMessaging.instance.requestPermission`).
   - Get token (`FirebaseMessaging.instance.getToken()`), save to `users/{uid}.fcmToken` via the same repository pattern as the settings/user repo.
   - Listen to `FirebaseMessaging.instance.onTokenRefresh` and re-save.
   - Handle `FirebaseMessaging.onMessage` (foreground) — show an in-app snackbar/local notification.
   - Handle `FirebaseMessaging.onMessageOpenedApp` and the initial message (app opened from terminated state) — parse a `ticker` field from the notification's `data` payload and navigate via GoRouter to `stock_detail_screen.dart`.
3. **Wire into app startup**: call the service's `init()` right after successful sign-in (in `auth_controller.dart`), since it needs a `uid` to write the token to.
4. **iOS**: enable Push Notifications + Background Modes (remote notification) capability in Xcode project; APNs key uploaded to Firebase console (manual step, not code).
5. **Android**: default notification icon/channel setup per `firebase_messaging` docs.

### 4c. Buy alerts screen (new)
1. **New entity + model**: `PriceAlert` (domain entity) and `PriceAlertModel` (freezed, mirrors `LotModel`'s structure) with fields `id`, `ticker`, `targetPrice`, `tolerancePercent`, `isActive`, `alertSent`, `alertSentAt`, `createdAt`.
2. **New repository**: `PriceAlertRepository` (domain interface) / `PriceAlertRepositoryImpl`, following the exact CRUD + `watchAll` pattern already used by `LotRepository`. Firestore path: `users/{uid}/price_alerts/{alertId}` (add a helper to `FirestorePaths`).
3. **New screen**: `lib/presentation/alerts/screens/alerts_screen.dart` — a list of the user's buy alerts (ticker, target price, tolerance, active/triggered state), each row swipeable to delete/deactivate (reuse `flutter_slidable`, already a dependency, same as elsewhere in the app).
4. **New "Add Alert" bottom sheet**: `lib/presentation/alerts/widgets/add_alert_bottom_sheet.dart` — reuse the existing `ticker_autocomplete.dart` widget for ticker entry, a price input, and an optional tolerance input (default e.g. 1%, explained in-UI as "notify me at or within X% of this price").
5. **Navigation**: add an "Alerts" entry to `app_bottom_nav_bar.dart` and a route in `app_router.dart`, alongside Dashboard/Transactions/Settings.
6. **Providers**: `lib/presentation/alerts/providers/alerts_providers.dart`, following the Riverpod generator pattern used in `transactions_providers.dart`.
7. **Notification tap for a buy alert**: since there's no existing lot to open, tapping should navigate to the stock's ticker (e.g. via `stock_detail_screen.dart` if it can render an unheld ticker, or a simpler "prompt to add a buy" flow) — distinguish sell vs. buy alerts in the FCM `data` payload (e.g. `type: "sell"` / `type: "buy"`) so the tap handler in `push_notification_service.dart` can route accordingly.

## 5. Backend: Scheduled Script via GitHub Actions (not Firebase Cloud Functions)

**Decision: since the Firebase project is on the Spark (free) plan, and Cloud Scheduler + outbound network calls from Cloud Functions require the Blaze plan, this job runs as a scheduled GitHub Actions workflow instead.** Firestore and FCM themselves are free on Spark — only the "run this on a schedule with internet access" part needed a home, and GitHub Actions provides that for free without requiring any Firebase billing upgrade. This keeps the whole script in Python (so `psxdata` + `firebase-admin` work exactly as planned, no rewrite needed for a different runtime).

**New directory**: `scripts/price_alerts/` at repo root (kept separate from `functions/`, since there is no Cloud Functions deployment in this setup).

**`scripts/price_alerts/main.py`** — same logic as before, just triggered differently (a plain script run by a workflow, not a Cloud Functions entry point):

```python
import firebase_admin
from firebase_admin import credentials, firestore, messaging
import psxdata
import os

cred = credentials.Certificate(os.environ["FIREBASE_SERVICE_ACCOUNT_PATH"])
firebase_admin.initialize_app(cred)
db = firestore.client()

def _send_push(token, title, body, data):
    messaging.send(messaging.Message(
        notification=messaging.Notification(title=title, body=body),
        data=data,
        token=token,
    ))

def refresh_prices_and_check_alerts():
    # 1a. Every distinct ticker any user currently holds (open/partiallySold lots)
    held_lots = list(
        db.collection_group("lots")
        .where("status", "in", ["open", "partiallySold"])
        .stream()
    )
    held_tickers = {doc.get("ticker") for doc in held_lots}

    # 1b. Every distinct ticker being watched by an active buy alert
    buy_alerts = list(
        db.collection_group("price_alerts")
        .where("isActive", "==", True)
        .where("alertSent", "==", False)
        .stream()
    )
    watched_tickers = {doc.get("ticker") for doc in buy_alerts}

    all_tickers = held_tickers | watched_tickers
    if not all_tickers:
        return

    # 2. Fetch live prices once per ticker, write to shared market_prices collection
    prices = {}
    for ticker in all_tickers:
        try:
            price = psxdata.quote(ticker)  # adapt to actual psxdata return shape
        except Exception:
            continue
        prices[ticker] = price
        db.collection("market_prices").document(ticker).set({
            "ticker": ticker,
            "price": price,
            "updatedAt": firestore.SERVER_TIMESTAMP,
        })

    # 3. Check SELL targets (existing lots) — fire when price >= target
    for doc in held_lots:
        data = doc.to_dict()
        target = data.get("targetPrice")
        if not target or data.get("targetAlertSent"):
            continue
        current_price = prices.get(data["ticker"])
        if current_price is None or current_price < target:
            continue

        uid = doc.reference.parent.parent.id  # users/{uid}/lots/{lotId}
        user_doc = db.collection("users").document(uid).get()
        token = user_doc.get("fcmToken") if user_doc.exists else None
        if not token:
            continue

        _send_push(
            token,
            title=f"{data['ticker']} hit your sell target!",
            body=f"{data['ticker']} reached Rs {current_price:.2f} (target Rs {target:.2f})",
            data={"type": "sell", "ticker": data["ticker"], "lotId": doc.id},
        )
        doc.reference.update({
            "targetAlertSent": True,
            "targetAlertSentAt": firestore.SERVER_TIMESTAMP,
        })

    # 4. Check BUY alerts (watchlist, not yet owned) — fire when price is at or near target
    for doc in buy_alerts:
        data = doc.to_dict()
        target = data.get("targetPrice")
        tolerance_pct = data.get("tolerancePercent", 0)
        ticker = data["ticker"]
        current_price = prices.get(ticker)
        if current_price is None:
            continue

        threshold = target * (1 + tolerance_pct / 100)
        if current_price > threshold:
            continue

        uid = doc.reference.parent.parent.id  # users/{uid}/price_alerts/{alertId}
        user_doc = db.collection("users").document(uid).get()
        token = user_doc.get("fcmToken") if user_doc.exists else None
        if not token:
            continue

        _send_push(
            token,
            title=f"{ticker} is at your buy price!",
            body=f"{ticker} is now Rs {current_price:.2f} (target Rs {target:.2f})",
            data={"type": "buy", "ticker": ticker, "alertId": doc.id},
        )
        doc.reference.update({
            "alertSent": True,
            "isActive": False,
            "alertSentAt": firestore.SERVER_TIMESTAMP,
        })

if __name__ == "__main__":
    refresh_prices_and_check_alerts()
```

**GitHub Actions workflow** — `.github/workflows/price-alerts.yml`:
```yaml
name: PSX Price Alerts

on:
  schedule:
    # every 15 min, 04:15–10:30 UTC = 09:15–15:30 PKT, Mon–Fri
    - cron: '*/15 4-10 * * 1-5'
  workflow_dispatch: {}  # allows manual trigger from the Actions tab for testing

jobs:
  check-prices:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      - name: Install dependencies
        run: pip install firebase-admin psxdata
      - name: Write service account key
        run: echo '${{ secrets.FIREBASE_SERVICE_ACCOUNT_JSON }}' > service-account.json
      - name: Run price check
        env:
          FIREBASE_SERVICE_ACCOUNT_PATH: service-account.json
        run: python scripts/price_alerts/main.py
```

**One-time setup steps (manual, not code):**
1. Firebase Console → Project Settings → Service Accounts → "Generate new private key" → downloads a JSON file.
2. In the GitHub repo → Settings → Secrets and variables → Actions → New repository secret named `FIREBASE_SERVICE_ACCOUNT_JSON` → paste the entire JSON file content as the value.
3. Since this key is never committed to the repo (only pulled from the GitHub secret at run time), it stays out of version control — confirm `service-account.json` is in `.gitignore` regardless, as a safety net.
4. GitHub Actions cron times are in UTC — PSX market hours (9:15am–3:30pm PKT) convert to roughly 04:15–10:30 UTC (adjust for PKT having no daylight saving, so this offset is fixed at UTC+5).

**Note on GitHub Actions cron reliability**: scheduled workflows can run a few minutes late during high load on GitHub's infrastructure — acceptable for a 15-minute-interval price check, not suitable if sub-minute precision is ever needed.

**Firestore indexes** — the `collection_group("lots")` query filtering by `status`, and the `collection_group("price_alerts")` query filtering by `isActive` + `alertSent`, each need a composite index. The script's first run will throw a `FailedPrecondition` error containing a direct link to auto-create each index in the Firebase console — capture both into `firestore.indexes.json` afterward so they're versioned (deploy indexes with `firebase deploy --only firestore:indexes`, which works fine on the Spark plan).

**Reset `targetAlertSent`** — when the client updates a lot's `targetPrice` (new value or cleared), also set `targetAlertSent: false` in the same write, so a new target can trigger a fresh alert. Similarly, if a buy alert is ever re-activated after firing, reset `alertSent: false` in that same write.

## 6. Security / Firestore Rules

- The script uses the Firebase Admin SDK (via the service account key), which bypasses `firestore.rules` entirely — no rule changes needed for the script itself, regardless of whether it runs on GitHub Actions or Cloud Functions.
- **New rule needed**: `market_prices/{ticker}` should be readable by any authenticated user, but writable only by the Admin SDK (i.e., no `allow write` rule for clients at all).
- **New rule needed**: `users/{uid}/price_alerts/{alertId}` should follow the same per-user read/write pattern already used for `users/{uid}/lots/{lotId}` — a user can only read/write their own alerts.
- Double-check existing rules still only allow a user to read/write their **own** `fcmToken` and `targetAlertSent` fields (should already be covered by existing per-user rules on `users/{uid}` and `users/{uid}/lots/{lotId}`).
- The service account JSON key is powerful (full Admin SDK access) — it lives only in the GitHub Actions secret, never in the repo itself.

## 7. Rollout Steps

1. Add `MarketPriceRepository` + Hive cache + wire live price into lot card / stock detail UI (can ship this before push notifications work, using manually-seeded `market_prices` docs for testing).
2. Add `firebase_messaging`, implement `PushNotificationService`, wire into auth flow.
3. Add `fcmToken` to user doc write path; add `targetAlertSent` to lot create/update paths.
4. Build the `PriceAlert` entity/model/repository, Alerts screen, Add Alert bottom sheet, and navigation entry.
5. Add `market_prices` and `price_alerts` rules to `firestore.rules`.
6. Generate a Firebase service account key and add it as a GitHub Actions secret (`FIREBASE_SERVICE_ACCOUNT_JSON`).
7. Write `scripts/price_alerts/main.py` and `.github/workflows/price-alerts.yml` per above.
8. Trigger the workflow manually once (`workflow_dispatch`) to confirm it runs, verify both composite index prompts in the error output, and add them to `firestore.indexes.json`.
9. Confirm the app shows a live price for a held ticker after that run.
10. Manually set a low target price on a test lot in a live market session, trigger the workflow, and confirm the sell push arrives and taps through to the right stock.
11. Add a buy alert for a ticker currently trading near your test target and confirm the buy push arrives, with the "near" tolerance behaving as expected.
12. Let the cron schedule run on its own for a day and confirm no duplicate notifications on repeated runs for either alert type.

---

## Prompt for Claude Code

Copy everything below into Claude Code in the repo root:

```
I'm adding three related features to this Flutter + Firebase app (Stock Book):
(1) live PSX market price display for held stocks,
(2) a push notification when a held stock's live price hits the sell target price set on a Lot,
(3) a separate "buy alerts" screen where the user can watch a ticker they don't yet own and get notified when its price hits or comes near a target buy price (e.g. "notify me when GUSM is at or near 8.60").
All three share one backend job. IMPORTANT: the Firebase project is on the Spark (free) plan, so this job runs as a scheduled GitHub Actions workflow (Python script + firebase-admin), NOT as a Firebase Cloud Function — Cloud Scheduler and outbound network calls from Cloud Functions require the paid Blaze plan. Implement step by step, confirming file changes as you go.

CONTEXT:
- Lot entity (lib/domain/entities/lot.dart) and LotModel (lib/data/models/lot_model.dart) already have a nullable `targetPrice` field — this is the SELL target for an owned lot. Buy alerts are a completely separate concept and must NOT be added to Lot; the ticker isn't owned yet.
- Firestore layout so far is entirely per-user: users/{uid}/lots/{lotId} (see lib/core/constants/firestore_paths.dart for path helpers).
- State management is Riverpod (riverpod_annotation + generators, *.g.dart files).
- Data layer follows domain/repositories (interfaces) + data/repositories (impl) + data/data_sources (Hive local + Firestore remote), e.g. LotRepository / LotRepositoryImpl / FirestoreDataSource.
- Offline-first: writes go to Hive first, then sync to Firestore; reads prefer Hive on cold start, then stream from Firestore.
- Auth flow is in lib/presentation/auth/controllers/auth_controller.dart.
- Navigation uses GoRouter (lib/presentation/routing/app_router.dart) and a bottom nav bar (lib/presentation/common/app_bottom_nav_bar.dart) with existing sections for Dashboard/Transactions/Settings.
- The ticker_autocomplete.dart widget (lib/presentation/transactions/widgets/) already exists for entering a stock ticker and should be reused rather than rebuilt.
- Dashboard/lot card widgets (lib/presentation/dashboard/, lib/presentation/transactions/widgets/lot_card.dart) currently only show the buy price and derived values from PortfolioCalculator (lib/domain/calculator/portfolio_calculator.dart) — no live market price exists anywhere yet.
- No firebase_messaging package, no scripts/ directory, and no GitHub Actions workflows exist yet.

TASKS:

1. NEW TOP-LEVEL FIRESTORE COLLECTION `market_prices/{ticker}` (not per-user): { ticker, price, updatedAt }. Written only by the backend script (Admin SDK); read-only for authenticated clients. Add a firestore.rules entry allowing `allow read: if request.auth != null;` and no client write rule for this collection.

2. CLIENT — live price display:
   - Add a MarketPriceRepository (domain interface + impl) following the exact pattern LotRepository/LotRepositoryImpl already use.
   - Add a Firestore data source that streams market_prices docs for a given ticker or a list of tickers (batch whereIn queries in groups of 30, Firestore's limit).
   - Add a Hive cache box for last-known prices so they display instantly offline and update the cache on every Firestore emission, mirroring how HiveDataSource already caches lots.
   - Wire live price into lot_card.dart (show next to buy price) and stock_detail_screen.dart (prominent current price + a live unrealized P/L, extending PortfolioCalculator with this new calculation rather than computing it ad hoc in a widget). Show a "prices updated at HH:mm" indicator somewhere visible since this refreshes every ~15 minutes, not real time.
   - Do NOT fold live prices into the existing "Total Portfolio Value" metric on the dashboard without flagging it to me first — that changes an existing metric's meaning and I want to review it.

3. CLIENT — push notifications infrastructure (shared by sell and buy alerts):
   - Add `firebase_messaging` to pubspec.yaml.
   - Create lib/core/services/push_notification_service.dart that: requests notification permission; fetches the FCM token and saves it to users/{uid}.fcmToken (+ fcmTokenUpdatedAt) via the existing settings/user repository pattern (check lib/data/repositories/ and lib/domain/repositories/ for the right place — ask me if it's unclear which file should own this); listens for token refresh and re-saves; handles foreground messages with an in-app snackbar/local notification; handles notification taps (foreground-opened and app-launched-from-terminated) by reading a `type` field ("sell" or "buy") plus `ticker` from the FCM data payload, routing sell taps to stock_detail_screen.dart for that ticker's lot, and buy taps to the ticker's detail view or an "add holding" entry point — ask me which makes more sense once you see what stock_detail_screen.dart currently requires as input (an owned Lot vs. a bare ticker).
   - Wire this service's init() call into the point right after a successful sign-in in auth_controller.dart, since it needs the uid.
   - iOS: note in your output that Push Notifications + Background Modes capability needs enabling in Xcode and an APNs key needs uploading in the Firebase console — these are manual steps you can't do, just flag them.

4. CLIENT — sell target alerts (existing Lot feature):
   - Add `targetAlertSent` (bool, default false) and `targetAlertSentAt` (nullable timestamp) fields to LotModel and the Lot entity, following the existing freezed/equatable patterns in those files. Any code path that sets or clears targetPrice (add buy, edit lot) must reset targetAlertSent to false in the same write.

5. CLIENT — buy alerts (new feature, new screen):
   - Create a PriceAlert domain entity and PriceAlertModel (freezed), mirroring Lot/LotModel's structure, with fields: id, ticker, targetPrice, tolerancePercent (double, default 1.0), isActive (bool, default true), alertSent (bool, default false), alertSentAt (nullable timestamp), createdAt.
   - Create PriceAlertRepository (domain interface) + PriceAlertRepositoryImpl, mirroring LotRepository/LotRepositoryImpl's CRUD + watchAll(Stream) pattern. Firestore path: users/{uid}/price_alerts/{alertId} — add a helper to FirestorePaths for this.
   - Add a firestore.rules entry for users/{uid}/price_alerts/{alertId} matching the existing per-user rule pattern used for lots.
   - Build a new screen lib/presentation/alerts/screens/alerts_screen.dart listing the user's buy alerts (ticker, target price, tolerance, active/triggered state), swipeable to delete/deactivate using flutter_slidable (already a dependency).
   - Build lib/presentation/alerts/widgets/add_alert_bottom_sheet.dart to create a new alert: reuse ticker_autocomplete.dart for the ticker field, a price input for targetPrice, and a tolerance input (default 1%, label it something like "notify me at or within X% of this price").
   - Add Riverpod providers in lib/presentation/alerts/providers/alerts_providers.dart following the generator pattern used in transactions_providers.dart.
   - Add an "Alerts" entry to the bottom nav bar and a route in app_router.dart.

6. BACKEND (Python script + GitHub Actions, NOT Firebase Cloud Functions — the Firebase project is on the Spark/free plan, which doesn't support Cloud Scheduler or outbound network calls from Cloud Functions):
   - Create scripts/price_alerts/main.py as a plain Python script (not a Cloud Functions entry point) that:
     a) authenticates to Firebase using a service account JSON key (path passed via the FIREBASE_SERVICE_ACCOUNT_PATH env var, read with firebase_admin.credentials.Certificate),
     b) queries the `lots` collection group across all users for status in [open, partiallySold] to find every distinct ticker currently held by anyone,
     c) queries the `price_alerts` collection group across all users for isActive == true and alertSent == false to find every distinct ticker being watched,
     d) fetches each distinct ticker's live price once (use the `psxdata` PyPI package) across the union of held + watched tickers, and writes each to market_prices/{ticker},
     e) using those same fetched prices (don't re-fetch): for every lot with targetPrice set and targetAlertSent == false, if current price >= targetPrice, sends an FCM push (data: type=sell, ticker, lotId) to that user's fcmToken and sets targetAlertSent = true with a server timestamp; for every active, not-yet-sent price_alert, computes threshold = targetPrice * (1 + tolerancePercent/100), and if current price <= threshold, sends an FCM push (data: type=buy, ticker, alertId) to that user's fcmToken and sets alertSent = true, isActive = false, alertSentAt = server timestamp.
   - Create .github/workflows/price-alerts.yml: a scheduled workflow (cron, every 15 min, roughly 04:15–10:30 UTC Mon–Fri to cover PSX market hours in PKT, plus a workflow_dispatch trigger for manual testing) that checks out the repo, sets up Python, installs firebase-admin and psxdata, writes the service account JSON from a GitHub Actions secret named FIREBASE_SERVICE_ACCOUNT_JSON to a local file, and runs the script with FIREBASE_SERVICE_ACCOUNT_PATH pointing at that file.
   - Add service-account.json (or whatever local filename is used) to .gitignore as a safety net, even though it's only ever written at workflow runtime from the secret.
   - Tell me the two manual one-time setup steps I need to do myself: generating the service account key in Firebase Console → Project Settings → Service Accounts, and adding its full JSON content as the FIREBASE_SERVICE_ACCOUNT_JSON secret in the GitHub repo's Settings → Secrets and variables → Actions.
   - Generate the Firestore composite indexes both collection-group queries need — the first manual run will throw a FailedPrecondition error with a direct console link to create each one — and once created, add them to firestore.indexes.json so they're versioned (deployable via `firebase deploy --only firestore:indexes`, which works fine on Spark).

7. After implementation, tell me exactly how to test all three features end-to-end: confirming a live price shows up in the app after manually triggering the workflow once (via workflow_dispatch); setting a low target price on a real lot, triggering the workflow, and confirming the sell push arrives and deep-links correctly; and adding a buy alert near a real current price, triggering the workflow, and confirming the buy push arrives with the tolerance behaving as expected.

Work through this in this order: market_prices collection + rules, then the live-price client feature, then the push notification service, then sell-target fields, then the full buy-alerts feature (entity → repository → screen → nav), then the Python script, then the GitHub Actions workflow + index setup. Ask me before making assumptions about which repository/provider file anything new should live in, and flag anywhere you're deviating from the existing offline-first Hive-then-Firestore pattern.
```
