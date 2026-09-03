# Stock Book — Implementation Plan (4 workstreams)

Written 2026-09-03 against commit `385660b`. Companion to [AGENTS.md](AGENTS.md) (codebase map)
and [target-price-alerts-plan.md](target-price-alerts-plan.md) (the original alerts draft, now
superseded by Phases 5–8 below).

---

## Decisions locked

| # | Decision | Choice |
|---|---|---|
| 1 | Starting-capital input | Responsive layout fix |
| 2 | Same-ticker buys | **Merge** into one position, moving-average cost |
| 2b | Existing Firestore data | Migrate, gated behind backup + `lots_backup` |
| 3 | White theme | Complete light styling + Settings toggle, **dark stays default** |
| 4 | PSX price source | `psxdata` (PyPI 1.1.0) on GitHub Actions cron |

**There is no PSX API key.** PSX publishes no public developer API; `marketdatarequest@psx.com.pk`
sells a commercial data licence. Every free route (`psxdata`, `dps.psx.com.pk`) scrapes the public
site. Two consequences to be aware of:

- **Fragility** — a PSX HTML change breaks price fetching. Phase 8 puts the fetch behind a one-function
  interface so swapping to direct JSON or a paid feed is a small change, not a redesign.
- **Licensing** — PSX states that commercial use of their market data without a licence is prohibited.
  Personal use is the normal reading; if Stock Book is ever monetised or published commercially,
  that needs a licence conversation. Flagging, not advising.

---

## Phase 0 — Safety net (do first, ~half a day)

Nothing else starts until this is in place, because Phase 3 rewrites live financial data.

1. **Characterisation tests on today's behaviour** — lock in the current numbers before changing the
   engine. Extend `test/domain/calculator/portfolio_calculator_test.dart` with a realistic
   multi-lot, multi-sale, multi-withdrawal fixture and assert every `PortfolioSummary` field.
   These must produce identical values after Phase 3.
2. **Backup export** — "Export data (JSON)" button in Settings → ACCOUNT, dumping all lots, sales,
   withdrawals and settings via `share_plus`/`printing`'s share sheet. Reused as the pre-migration gate.
3. **Branch** — `feat/positions-and-alerts`, so `main` stays shippable.

**Tests:** golden `PortfolioSummary` snapshot; export produces valid re-importable JSON.

---

## Phase 1 — Starting Capital responsive input (~2 hours)

**Problem** — [settings_screen.dart:240](lib/presentation/settings/screens/settings_screen.dart#L240)
wraps the field in `Container(width: 140, height: 48)`. That fixed 140px holds the `Rs` prefix, the
`TextField` *and* the save `IconButton` that appears once dirty (~48px on its own), so anything past
about 6 digits is clipped or squeezed to unreadable.

**Fix**

- Replace the fixed-width `Container` with a `Flexible` + `ConstrainedBox(minWidth: 120, maxWidth: 220)`,
  and let the label `Expanded` shrink first.
- Move the save action out of the width budget: keep it inline on wide screens, but below `360dp`
  drop the label to its own line and give the field the full row (`LayoutBuilder`).
- Add thousands-separator formatting while typing (`intl` `NumberFormat` + a `TextInputFormatter`),
  so `10000000` reads `10,000,000`. Strip separators before `double.tryParse`.
- Cap input length at 12 digits; show a validation message instead of silently doing nothing when
  `double.tryParse` fails (today `_save()` quietly no-ops on unparseable input).

**Tests**

- Widget test: enter `123456789012`, assert no `RenderFlex` overflow at 320dp, 360dp and 480dp widths.
- Widget test: typing `10000000` displays `10,000,000` and saves `10000000.0`.
- Widget test: garbage input surfaces an error and does not call `updateStartingCapital`.

**Acceptance** — a 12-digit capital is fully visible and editable on a 320dp-wide screen.

---

## Phase 2 — Complete white theme + toggle (~2–3 days)

Roughly 60% done already: 19 of 57 presentation files branch on `Brightness.dark`. The work is the
other 40% plus one systemic fix.

**2a. The systemic fix — `AppTypography` bakes in `Colors.white`.**
There are 106 `AppTypography.*` usages and only 11 override the colour, so ~95 render white-on-white
in light mode. Convert the static `TextStyle`s to colour-less styles and let `ThemeData.textTheme`
supply the colour, or expose `AppTypography.of(context)`. This one change fixes most of the screens
at once. Do it first and re-screenshot.

**2b. Remaining hardcoded files** (no `isDark` branch today):

| File | Notes |
|---|---|
| `common/animated_pdf_button.dart` | 10 hardcoded colours |
| `dashboard/widgets/dashboard_skeleton.dart` | 11 — shimmer base/highlight need light variants |
| `auth/screens/sign_in_screen.dart` | 5 |
| `common/ticker_avatar.dart` | 3 — already luminance-aware, just needs the shadow tuned |
| `dashboard/screens/dashboard_screen.dart` | 3 |
| `transactions/widgets/ticker_autocomplete.dart` | 2 |
| `common/offline_banner.dart`, `splash_screen.dart` | 2 each |
| `filter_chip_row.dart`, `transaction_search_bar.dart`, `onboarding_line_chart.dart`, `app_router.dart` | 1 each |

`app_router.dart` also hardcodes the shell `Scaffold` background to `0xFF13151B` — that must become
theme-driven or every tab keeps a dark frame in light mode.

**2c. Replace dark-only aliases.** `AppColors.textPrimaryDark` / `backgroundDark` / `surfaceDark` are
used directly in 11 presentation files. Route them through `Theme.of(context)` or `AppSemanticColors`.

**2d. The toggle.** Add a Theme row to Settings → PORTFOLIO (next to Currency) with Dark / Light /
System, calling the existing `SettingsController.updateThemeMode`. The rest of that chain
(entity → Firestore → `MaterialApp.themeMode`) already works as of the last fix.

**Tests**

- Golden tests (`golden_toolkit`, already a dev dependency but unused) for Dashboard, Transactions,
  Lot card, Settings and Stock detail in **both** themes — 10 goldens. This is the only practical way
  to stop light-mode regressions.
- Widget test: switching the toggle rebuilds `MaterialApp` with the matching `ThemeMode`.
- Contrast check: assert no widget renders text within 5% luminance of its background in light mode.

**Acceptance** — every screen and bottom sheet legible in light mode; toggle persists across restart
and syncs across devices.

---

## Phase 3 — Merge same-ticker buys into one position (~4–5 days, highest risk)

### The model: moving-average cost

```
state: sharesHeld, totalCost        avgCost = totalCost / sharesHeld

BUY(qty, price):
    sharesHeld += qty
    totalCost  += qty × price        → avgCost moves

SELL(qty, price):
    costBasisAtSale = avgCost        → FROZEN onto the sale record
    realizedPL      = qty × (price − costBasisAtSale)
    totalCost      -= qty × costBasisAtSale
    sharesHeld     -= qty            → avgCost unchanged
```

Worked example (yours):

| Event | Shares | Total cost | Avg |
|---|---|---|---|
| Buy 500 @ 8.73 (31 Aug) | 500 | 4,365.00 | 8.7300 |
| Buy 1,200 @ 8.38 (7 Sep) | 1,700 | 14,421.00 | **8.4829** |
| Sell 200 @ 9.00 | 1,500 | 12,724.41 | 8.4829 |
| → realized | | | 200 × (9.00 − 8.4829) = **+103.42**, frozen |

`costBasisAtSale` is what makes this safe: a buy after that sale moves `avgCost` for *future* sales
but can never touch the +103.42 already booked.

**Position resets on close.** When `sharesHeld` hits 0 the position is archived and a later buy of the
same ticker starts a fresh position with a fresh average — it does not resurrect the old one.

### Data model

New collection `users/{uid}/positions/{positionId}`, one doc per ticker per open cycle:

```json
{ "ticker": "STPL", "status": "open", "openedAt": "<ts>", "closedAt": null,
  "targetPrice": 9.50,
  "buys":  [ { "id":"uuid", "date":"<ts>", "shares":500,  "pricePerShare":8.73 },
             { "id":"uuid", "date":"<ts>", "shares":1200, "pricePerShare":8.38 } ],
  "sales": [ { "id":"uuid", "date":"<ts>", "shares":200, "pricePerShare":9.00,
               "costBasisAtSale":8.4829 } ] }
```

Mirrors the existing embedded-`sales[]` shape, so `FirestoreDataSource`'s explicit nested
re-serialisation pattern carries over unchanged. `targetPrice` moves from lot to position — one
target per ticker, which also simplifies Phase 6.

### Migration (one-way, gated)

1. Require a successful Phase 0 backup export within the session.
2. Copy every `lots/{lotId}` doc verbatim to `users/{uid}/lots_backup/{lotId}`.
3. Group lots by ticker; split into cycles wherever cumulative shares reach 0.
4. Each old lot → one `buys[]` entry. Each old sale → one `sales[]` entry with
   **`costBasisAtSale` = that lot's `buyPricePerShare`**.
5. Replay chronologically, deducting `qty × costBasisAtSale` (the stored value, never a recomputed
   one) so the running average stays consistent with locked history.
6. `targetPrice` conflicts across merged lots → keep the one from the most recent buy; log every
   conflict to a migration report shown once to the user.
7. Write a `schemaVersion: 2` marker so migration never runs twice.

**Step 4 is why totals do not move.** Every historical sale keeps the exact basis it already used, so
gross realized P/L, portfolio value and every dashboard figure are bit-identical before and after —
which is precisely what the Phase 0 golden test asserts.

### App changes

- `Position` entity + `PositionModel`; `PortfolioCalculator` gains `avgCost`, and `Lot` math is
  retired once nothing reads it. ~70 references to `realizedProfitLoss`/`realizedPL` across the app
  need auditing — most are display-only and unaffected.
- **`SelectLotBottomSheet` disappears.** Selling picks a *ticker*, not a lot — matching your broker.
  This is the most visible UX change in the whole plan.
- `LotCard` → `PositionCard`: header shows ticker, total shares, avg cost; expanding lists the
  individual buys (dates and prices preserved) and the sales log.
- `AddBuyBottomSheet` routes into the existing open position for that ticker, or opens a new one.
- PDF reports: buy table becomes per-buy-within-position; sales table gains a "cost basis" column.

### Tests (the heaviest test phase — this is money math)

- **Migration invariant** (critical): for a fixture of 8 lots / 12 sales / 3 tickers, assert
  `PortfolioSummary` is field-for-field identical pre- and post-migration.
- Moving average: your exact STPL numbers → `8.4829`.
- Sell does not change avg cost; buy does.
- **Retroactivity guard**: book a sale, then add a buy, assert the earlier sale's `realizedPL`
  is byte-identical.
- Position reset: sell to zero, buy again → new cycle, average restarts.
- Cycle splitting: lots interleaved across a zero-crossing land in the right cycles.
- Idempotency: running migration twice changes nothing.
- Rounding: 1,700 shares at 3-decimal averages still sum to the exact invested total.
- Partial sale across a buy boundary.
- Widget: `PositionCard` shows one card for two same-ticker buys.

**Acceptance** — dashboard totals unchanged post-migration; STPL shows one card at Rs 8.48;
`lots_backup` restorable.

---

## Phase 4 — Live PSX prices in-app (~3 days)

- `market_prices/{ticker}` top-level collection: `{ ticker, price, previousClose, updatedAt }`.
  Client-readable, admin-write only.
- `MarketPriceRepository` + Firestore source (`whereIn` batched at 30) + a `market_prices_cache`
  Hive box for instant offline display, following the existing Hive-then-Firestore pattern.
- UI: live price on the position card and stock detail, plus **unrealized P/L** as a new
  `PortfolioCalculator` function — `sharesHeld × (livePrice − avgCost)` — not computed ad hoc in widgets.
- A visible "prices as of HH:mm" stamp, since this refreshes every 15 minutes, not tick-by-tick.
- **Not doing without your say-so:** folding live prices into "Total Portfolio Value". That silently
  redefines an existing metric. Recommend adding a separate "Market Value" tile instead.

**Tests** — repository maps snapshots correctly; cache serves on cold start then updates; `whereIn`
batching splits at 31 tickers; unrealized P/L math incl. zero/negative shares; UI shows a
"—" placeholder, never a stale price, when a ticker has no `market_prices` doc.

---

## Phase 5 — Push notification infrastructure (~2 days)

- `firebase_messaging`; `PushNotificationService` handling permission, token → `users/{uid}.fcmToken`,
  `onTokenRefresh`, foreground messages, and taps (`onMessageOpenedApp` + `getInitialMessage`)
  routed by a `type` field (`sell` / `buy`) to `/stock/:ticker`.
- Init after successful sign-in in `auth_controller.dart` (needs the uid).
- **Manual steps I cannot do:** enable Push Notifications + Background Modes in Xcode, and upload an
  APNs key to the Firebase console. Android needs a notification channel + icon.

**Tests** — token written on sign-in and on refresh; payload routing table (`sell` → detail,
`buy` → detail, malformed → no crash); permission denial degrades quietly.

---

## Phase 6 — Sell-target alerts (~1 day)

`targetAlertSent` / `targetAlertSentAt` on the **position** (not lot — Phase 3 moved `targetPrice`
there). Any write that sets or clears `targetPrice` resets `targetAlertSent` in the same operation,
so a re-armed target can fire again.

**Tests** — editing the target resets the flag; a fired alert does not re-fire on the next run.

---

## Phase 7 — Buy alerts + Alerts screen (~3 days)

`users/{uid}/price_alerts/{alertId}` with `{ ticker, targetPrice, tolerancePercent (default 1.0),
isActive, alertSent, alertSentAt, createdAt }`. Fires when
`currentPrice <= targetPrice × (1 + tolerancePercent/100)`. One-shot for v1.

Entity → model → repository → providers → `alerts_screen.dart` (slidable rows) →
`add_alert_bottom_sheet.dart` (reusing `ticker_autocomplete.dart`) → nav entry.

**Nav is now 4 tabs** (Dashboard / Transactions / Alerts / Settings) — the floating pill bar and its
`SwipeableNavigationShell` `PageView` both need re-measuring at 320dp.

**Tests** — tolerance boundary at exactly `targetPrice × 1.01` (fires) vs a hair above (doesn't);
CRUD round-trip; one-shot deactivation.

---

## Phase 8 — Backend: psxdata on GitHub Actions (~2 days)

Your repo is **public**, so Actions minutes are free and unlimited — the cost concern in the original
draft doesn't apply.

**Two corrections to the original plan:**

1. **Use `psxdata.screener()`, not a per-ticker loop.** `screener()` returns the full board
   (~729 symbols) in **one** request. The draft's `for ticker in all_tickers: psxdata.quote(ticker)`
   would fire ~30 sequential scrapes per run, 28 runs a day — slower, far more fragile, and much
   heavier on PSX's site. Fetch once, filter locally.
2. **Pin the version.** `pip install firebase-admin psxdata` floats. `psxdata` hit 1.1.0 on
   2026-09-02 and its 0.1.0a\* line is recent alpha history — pin `psxdata==1.1.0` and bump deliberately.

**Structure** — `scripts/price_alerts/` with `main.py` (orchestration), `price_source.py` (the swappable
interface: `fetch_prices(tickers) -> dict[str, float]`, with `PsxdataScreenerSource` as the first
implementation), and `alerts.py` (pure decision logic, no I/O — so it's unit-testable without Firebase).

Workflow `*/15 4-10 * * 1-5` (09:15–15:30 PKT, no DST in Pakistan) + `workflow_dispatch`.
Secret `FIREBASE_SERVICE_ACCOUNT_JSON`; `service-account.json` added to `.gitignore`.

**Operational caveats**

- GitHub cron can run several minutes late under load — fine at 15-minute granularity.
- **Scheduled workflows are auto-disabled after 60 days of repo inactivity.** If Stock Book goes quiet,
  alerts silently stop. Add a monthly heartbeat commit or a "last price update" staleness warning in-app.
- Both collection-group queries (`positions` by status, `price_alerts` by `isActive`+`alertSent`) need
  composite indexes. The first run throws `FailedPrecondition` with console links — capture both into
  `firestore.indexes.json`.

**Tests** — `pytest` over `alerts.py`: sell fires at `price >= target` and not below; buy fires within
tolerance; already-sent alerts skip; missing `fcmToken` skips without crashing; a ticker absent from
the screener is skipped, never treated as price 0. Plus a `price_source` contract test against a
recorded screener fixture so a psxdata upgrade that changes column names fails in CI, not in production.

**Manual setup (yours):** Firebase Console → Project Settings → Service Accounts → Generate new private
key; then GitHub → Settings → Secrets and variables → Actions → new secret `FIREBASE_SERVICE_ACCOUNT_JSON`.

---

## Firestore rules (Phases 3–7)

```
match /market_prices/{ticker}      { allow read: if request.auth != null; }   // no client write
match /users/{uid}/positions/{id}  { allow read, write: if request.auth != null && request.auth.uid == uid; }
match /users/{uid}/price_alerts/{id} { allow read, write: if request.auth != null && request.auth.uid == uid; }
match /users/{uid}/lots_backup/{id} { allow read, write: if request.auth != null && request.auth.uid == uid; }
```

Also drop the dead `lots/{lotId}/sales/{saleId}` block (nothing has ever written there).

---

## Sequencing

```
Phase 0  Safety net            ██                      ← gate for everything
Phase 1  Capital input         █                       ← ship independently
Phase 2  White theme           ██████                  ← ship independently
Phase 3  Position merge        ██████████              ← gate for 4, 6
Phase 4  Live prices           ██████
Phase 5  Push infra            ████                    ← parallel with 4
Phase 6  Sell alerts           ██                      ← needs 3, 4, 5
Phase 7  Buy alerts            ██████                  ← needs 5
Phase 8  Backend               ████                    ← needs 4, 6, 7 schemas
```

Phases 1 and 2 are independent of everything and can ship to users while Phase 3 is in progress.
Phase 3 is the gate for the rest, because `targetPrice` moving from lot to position changes the
schema the alert backend reads.

Rough total: **3–4 weeks** of focused work. Phases 1+2 alone: about 3 days.

---

## Open items needing your call

1. **Confirm the Phase 3 migration** before I write it — it is one-way, even with the backup.
2. **Live prices in "Total Portfolio Value"?** Recommend no; separate "Market Value" tile instead.
3. **Alerts as a 4th nav tab, or a section inside Settings?** Four tabs crowds the pill bar at 320dp.
4. **Do you want Phase 1 + 2 shipped and merged first**, or everything on one branch?
