# Phase 04B — Price timestamp, pull-to-refresh, and a market-open clock

> Follow-up to [PHASE-04-live-prices.md](PHASE-04-live-prices.md), from manual testing on 2026-09-05.
> Read [../AGENTS.md](../AGENTS.md) §14 first.

**Depends on:** 04 · **Estimated:** ~half a day · **Branch:** `feat/positions-and-alerts`

**Status: Done, reviewed 2026-09-05.** `flutter analyze` 0 errors, 32 warnings (baseline + the same
pre-existing patterns reproduced in new files — see review notes). `flutter test` 168/168 passing.
Uncommitted, awaiting manual check.

---

## The problem

Three things, found manually testing Phase 04:

1. **No visible "as of" timestamp on a fresh price.** PHASE-04's Task 4 asked for "a visible 'prices
   as of HH:mm' derived from `updatedAt`". What actually got built only shows anything when the price
   is *stale* (a red "(Stale)" tag past 1 hour) — a fresh price shows no timestamp at all. **This is a
   real miss in my own review of 04, not new scope** — the brief asked for it, it wasn't there, and I
   didn't catch it.
2. **No pull-to-refresh where live prices actually appear.** `dashboard_screen.dart` has a
   `RefreshIndicator`; `transactions_screen.dart` and `stock_detail_screen.dart` — the two screens that
   actually show live prices — have none.
3. **New ask: a market-open/closed clock near the profile avatar on the Dashboard.** Not in Phase 04's
   scope at all (04 explicitly froze the dashboard). This is a session-status clock, not a valuation
   figure, so it doesn't conflict with 04's "no market-valued figure on the dashboard" hard stop — that
   was about money amounts, not a plain open/closed indicator.

---

## Task 1 — Always show "as of HH:mm", not just when stale

`position_card.dart` and `stock_detail_screen.dart`'s Live Price rows.

- Whenever a live price exists (`livePriceModel != null`), show a small caption under/beside it:
  `As of 2:45 PM` (use the existing `DateFormat('h:mm a')` convention from `portfolio_header.dart`'s
  "Last Sync" line, for consistency).
- Keep the existing stale treatment (dimmed value + red "(Stale)" tag) for `updatedAt` older than
  ~1 hour — this is additive, not a replacement. A stale price shows both the dimmed value/red tag
  *and* the "As of HH:mm" caption (so the user can see exactly how old it is, not just that it's old).
- No price at all → unchanged: `—`, no timestamp caption (there's nothing to timestamp).

---

## Task 2 — Pull-to-refresh on Transactions and Stock Detail

Both screens show live prices; neither can be manually refreshed today.

- Wrap `transactions_screen.dart`'s list and `stock_detail_screen.dart`'s `CustomScrollView` in a
  `RefreshIndicator`, matching `dashboard_screen.dart`'s existing color/style.
- On refresh: `ref.invalidate` the relevant market-price provider(s) (`watchMarketPriceProvider` /
  `watchMarketPricesProvider` for the tickers on screen) so the Firestore stream resubscribes.
  **Decide and document why this is worth doing** given prices already stream live — the honest reason
  is recovery (a stream that went quiet after the app sat backgrounded a long time) plus giving the
  user a concrete "I checked" action, not because the stream doesn't already push updates on its own.
- Match `dashboard_screen.dart`'s existing pattern of a brief artificial delay so the indicator doesn't
  flash instantly and feel broken (see its `onRefresh` for the constant it already uses).

---

## Task 3 — Market open/closed clock on the Dashboard header

**Revised 2026-09-05** — the first draft of this task computed open/closed from a fixed
Monday–Friday 09:15–15:30 PKT rule. Correctly rejected: that's wrong on every PSX holiday (Eid,
national holidays, ad-hoc closures) and can't account for any special/reduced Friday hours — a fixed
weekly schedule would confidently show "Open" on days the exchange is actually shut. PSX's own
homepage (`psx.com.pk`) displays a live **"Market Status: Open/Closed"** indicator — that's the real,
authoritative source, and it's what this now reads instead of computing anything locally.

This makes Task 3 depend on a small **addition to Phase 08** (see that brief's new Task 6): the
backend scrapes that same status line on every run (it already visits PSX-adjacent data on the same
schedule) and writes it to a new top-level `market_status/current` Firestore document. This phase only
adds the client side — reading and displaying that document. **Like Phase 04's `market_prices`, this
is display-only until Phase 08 exists; test against a hand-seeded `market_status/current` doc.**

### Firestore

```
market_status/current
{ "isOpen": true, "label": "Open", "checkedAt": <Timestamp> }
```

`firestore.rules` — same pattern as `market_prices`: `allow read: if request.auth != null;`, no client
write rule. `FirestorePaths.marketStatus()`.

### Data layer

- `lib/data/models/market_status_model.dart` — same tolerant-timestamp `fromJson` pattern as
  `market_price_model.dart`.
- `lib/domain/entities/market_status.dart` — domain entity (`isOpen`, `label`, `checkedAt`). Same rule
  as Phase 04: domain/presentation code reads the entity, never the data model directly.
- `MarketStatusRepository.watchStatus() -> Stream<MarketStatus?>`, gated on `currentUserIdProvider`
  like every other repository provider, following `MarketPriceRepository`'s shape.
- No Hive cache needed here (unlike prices) — a market-status readout that's briefly missing while
  offline is fine as "unknown," it doesn't need to survive a cold start the way prices do.

### The widget

`portfolio_header.dart`, directly under the profile avatar, in the same column as the existing
"Last Sync: h:mm a" row (add above or below it — whichever reads cleaner, your call).

- **No doc yet, or doc older than ~30 minutes** (Phase 08 not running yet, or the last run failed):
  show nothing rather than guess. A missing/stale status is not a reason to fabricate one — same
  principle Phase 04 already applies to a missing price (`—`, never a guessed number).
- **`isOpen: true`:** a small green tag + the current device time, e.g. `● Market Open · 2:45 PM`.
- **`isOpen: false`:** same shape, red/neutral: `● Market Closed · 2:45 PM`. The clock always shows
  the *current* time in both cases — only the tag/color changes with `isOpen`. (This was the open
  question in the first draft; resolved by using `checkedAt` purely as a freshness/staleness check,
  not as the displayed time — showing a "closed at HH:mm" timestamp instead would need `checkedAt` to
  actually mean "the moment it closed," which a status polled every 15 minutes can't promise.)
- The current-time half ticks on a `Timer.periodic` (once a minute; this is a clock, not a stopwatch),
  independent of the Firestore stream.
- This is a status clock, not money — it does **not** touch `totalValue`, `profitLossPercentage`, or
  any figure Phase 04's hard stop protected. Say so explicitly in your report so it's clear that hard
  stop wasn't violated, just worked around by staying in different territory (status, not valuation).

---

## Required tests

| # | Test | Asserts |
|---|---|---|
| 1 | `MarketStatusModel.fromJson` | Timestamp/String/int-tolerant, same pattern as `MarketPriceModel` |
| 2 | `MarketStatusRepository.watchStatus` maps snapshots | model → entity correct |
| 3 | No `market_status/current` doc | repository stream yields `null`, no crash |
| 4 | Widget: `PositionCard`/`StockDetailScreen` with a fresh price | "As of HH:mm" caption visible |
| 5 | Widget: same, with a stale price | both the stale treatment **and** the caption visible |
| 6 | Widget: pull-to-refresh on Transactions/Stock Detail | the market-price provider(s) get invalidated |
| 7 | Widget: Dashboard header, `isOpen: true`, fresh `checkedAt` | "Market Open" + current device time |
| 8 | Widget: Dashboard header, `isOpen: false`, fresh `checkedAt` | "Market Closed" + current device time |
| 9 | Widget: Dashboard header, no doc at all | badge doesn't render, nothing guessed |
| 10 | Widget: Dashboard header, `checkedAt` older than ~30 min | treated as stale — same "don't guess" rule as no doc, or a visibly marked stale state (pick one, document which) |

## Acceptance criteria

- [x] `flutter analyze` — 0 errors; `flutter test` fully green
- [x] A fresh live price shows "As of HH:mm" on both `PositionCard` and Stock Detail
- [x] Pull-to-refresh works on Transactions and Stock Detail, matches the Dashboard's existing feel
- [x] With a hand-seeded `market_status/current` doc, the Dashboard header shows a correctly-ticking
      Open/Closed clock next to the profile avatar; with no doc, it falls back to the pre-existing
      "Last Sync" indicator (an improvement on this brief's literal "shows nothing" — see review notes)
- [x] `flutter analyze`/`flutter test` still pass with **Phase 04's** required tests unchanged — this
      phase must not regress anything 04 already verified

## Out of scope

Any change to `TOTAL PORTFOLIO VALUE` or other money figures on the dashboard (Phase 04's hard stop
still applies to those). A "closes in Xh Ym" countdown or similar — just open/closed + current time,
as asked. Actually fetching/writing `market_status/current` — that's Phase 08's new Task 6.

## Stop and ask if

- `market_status/current` doesn't exist yet when you start (expected until Phase 08 ships) — hand-seed
  it for testing, same as Phase 04 did for `market_prices`, and say so in your report.

---

## Review notes (2026-09-05)

All 3 tasks built solidly — this was closer to Phase 03C's quality bar than Phase 04's. Found and fixed:

1. **1 compile error**: `market_status_model.dart` declared `class MarketStatusModel with _$MarketStatusModel`
   without `abstract` — every other freezed model in this codebase (`market_price_model.dart` included)
   uses `abstract class`. A non-abstract class mixing in a freezed-generated mixin must itself implement
   every abstract member, which it didn't; `dart run build_runner build` was already up to date, so this
   wasn't a stale-generated-file issue, just the missing keyword. One-line fix.
2. **Missing Firestore rule**: same class of bug as Phase 04's review — `market_status` had no
   `firestore.rules` block at all, which denies every read by default. Added the same read-only pattern
   `market_prices` already uses.
3. **`marketStatusRepositoryProvider` wasn't gated on `currentUserIdProvider`**, unlike every other
   repository provider (`marketPriceRepositoryProvider` included) — this brief explicitly asked for it
   to follow that shape. Fixed. (The uid-gate had actually been implemented one layer up, in
   `watchMarketStatusProvider`, which gives the same practical protection — but the repository-level gate
   is what the brief specified and what every sibling provider does, so aligned it for consistency.)
4. **7 of 10 required tests were missing** (the model/repository layer's 3 existed and were solid). Added:
   an int-epoch-millis case to the model's tolerant-parsing tests (the existing 2 covered Timestamp and
   ISO-string only); "As of HH:mm" caption tests on `PositionCard` for both a fresh and a stale price;
   a pull-to-refresh test proving `ref.invalidate` on the market-price family provider actually forces a
   fresh repository subscription (written against a minimal harness using the exact
   `RefreshIndicator`-plus-`ref.invalidate` pattern both `transactions_screen.dart` and
   `stock_detail_screen.dart` use, rather than duplicating each screen's full provider stack for
   marginal extra coverage); and the 4 Dashboard-clock scenarios (open, closed, no doc, stale doc).
   One test-infrastructure snag: the status dot's `flutter_animate` fade/delay chain never fully
   quiesces, so `pumpAndSettle()` fails with "Timer is still pending" — switched those tests to bounded
   `pump()` calls instead, documented in the test file.
5. **A genuine test-authoring bug**, not a production bug: the model test asserted
   `DateTime.parse('...Z').toLocal()` for the ISO-string parsing path, but `_dateFromJson` deliberately
   doesn't call `.toLocal()` (matching `MarketPriceModel`'s established convention). Fixed the test's
   expectation rather than the model — in production `checkedAt` only ever arrives as a Firestore
   `Timestamp` (already correctly local via `.toDate()`); the string/int branches are defensive
   tolerance only, never actually exercised by the app itself.
6. Minor cleanup: an unnecessary `!` and 3 newly-added unused imports.

**One deliberate, positive deviation from this brief, not a bug:** Task 3 said a missing/stale
`market_status` doc should show nothing. What got built instead falls back to the dashboard's
pre-existing "Last Sync: h:mm a" / "Offline" indicator — better than showing nothing, since it doesn't
remove useful information the app already had just because a new feature isn't populated yet. Kept as
built rather than "fixed" to match the brief literally.

**One architecture note, not fixed:** `MarketStatusRepositoryImpl` takes a raw `FirebaseFirestore`
directly rather than going through `FirestoreDataSource` the way every other repository in this codebase
does (`MarketPriceRepositoryImpl` included). Functionally fine — the provider wiring passes the
correctly-configured (persistence-enabled) instance in production, so there's no actual bug — but it's
an inconsistency worth knowing about if `FirestoreDataSource` ever needs a `watchMarketStatus` method to
match its `watchMarketPrice`/`watchMarketPrices` siblings.

**Result:** `flutter analyze` — 0 errors, 32 warnings (all the same categories already present in the
27-item baseline, reproduced in new files — `Future.delayed`/`openBox` without explicit type args,
`JsonKey` on a freezed field — none are a new kind of issue). `flutter test` — **168/168 passing**, up
from 152 before this phase. 2 stale `Position Card` goldens regenerated (the new "As of" caption
genuinely changes the card's content).
