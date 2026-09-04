# Phase 04 — Live PSX prices in the app

> Read [../AGENTS.md](../AGENTS.md) and [README.md](README.md) before starting. The universal agent
> rules in README.md apply in full.

**Depends on:** Phase 03B · **Estimated:** 3 days · **Branch:** `feat/positions-and-alerts`

Display-only. This phase reads prices that something else writes — the backend that populates them
is Phase 08. Until then you test against manually-seeded Firestore docs.

---

## Task 1 — The shared collection

New **top-level** collection (not per-user — this is the first non-`users/` collection in the app):

```
market_prices/{ticker}
{ "ticker": "ENGRO", "price": 350.25, "previousClose": 347.10, "updatedAt": <Timestamp> }
```

`firestore.rules`:

```
match /market_prices/{ticker} {
  allow read: if request.auth != null;
  // no client write rule — only the Admin SDK writes here
}
```

The absent write rule is deliberate: clients must never be able to forge a price.

`FirestorePaths` — add `marketPrice(ticker)` and `marketPrices()`.

---

## Task 2 — Data layer

- **`lib/data/models/market_price_model.dart`** — `@freezed`; tolerate `Timestamp` or ISO `String`
  for `updatedAt`, same defensive `fromJson` as `sale_model.dart`.
- **`MarketPriceRepository`** (domain interface) + impl:
  ```dart
  Stream<double?>              watchPrice(String ticker);
  Stream<Map<String, MarketPrice>> watchPrices(List<String> tickers);
  ```
- **Firestore `whereIn` is capped at 30 values.** Batch the ticker list into chunks of 30 and merge
  the streams. A user holding 31 tickers must not silently lose the 31st — there is a required test
  for exactly this.
- **Hive cache** — new box `market_prices_cache`, registered in `LocalStorage.init()`. Write through
  on every Firestore emission; read on cold start so a price shows instantly offline. Mirror
  `HiveDataSource`'s existing approach, **including `_sanitizeMap`** (AGENTS.md §8 — Hive returns
  `Map<dynamic, dynamic>`, which crashes generated `fromJson`).
- `marketPriceRepositoryProvider` — nullable, gated on `currentUserIdProvider`, like the others.

---

## Task 3 — Calculations

Extend `position_calculator.dart` (**not** ad-hoc arithmetic in widgets):

```dart
static double unrealizedPL(Position p, double livePrice)   // sharesHeld × (livePrice − avgCost)
static double marketValue(Position p, double livePrice)     // sharesHeld × livePrice
static double unrealizedPLPercent(Position p, double livePrice)
```

All must handle `sharesHeld == 0` (closed position → 0, not a divide-by-zero) and a null/missing
price (return null or 0 explicitly — decide, document it, and test it).

---

## Task 4 — UI

- **`PositionCard`** — live price beside avg cost, plus unrealized P/L with the app's
  green/red convention.
- **`StockDetailScreen`** — current price prominent; unrealized P/L as a headline figure.
- **Staleness indicator** — a visible "prices as of HH:mm" derived from `updatedAt`. Prices refresh
  roughly every 15 minutes, not tick-by-tick, and the UI must not imply otherwise.
- **Missing price** — show `—`, never a stale number and never `0`. A ticker with no
  `market_prices` doc is normal (PSX may not list it, or the backend hasn't run).
- **Stale price** — if `updatedAt` is older than ~1 hour during market hours, mark it visually
  (dimmed, or a small "stale" chip). A silently frozen price is worse than a visibly absent one.

### Explicitly NOT in this phase — decided by Moazzam, 2026-09-04

**The dashboard summary tiles do not change at all in this phase.** Live prices appear only on
position cards and the stock detail screen.

- Do **not** fold live prices into "Total Portfolio Value". It means
  `startingCapital + realizedPL` and keeps meaning exactly that.
- Do **not** add a "Market Value" tile either. That option was considered and declined.
- Do **not** add any portfolio-wide market-valued figure anywhere on the dashboard.

Rationale: the dashboard stays stable and cost-based, so it doesn't drift with market noise on days
you haven't traded. Live valuation belongs where you're looking at one specific stock.

This is a hard stop. If live prices seem to belong on the dashboard, raise it — don't implement it.

---

## Required tests

| # | Test | Asserts |
|---|---|---|
| 1 | Repository maps snapshots | model → entity correct |
| 2 | **`whereIn` batching at 31 tickers** | 2 queries issued, all 31 present in the merged result |
| 3 | Batching at exactly 30 | 1 query |
| 4 | Cache serves on cold start | value available before any Firestore emission |
| 5 | Cache updated on emission | later cold start returns the newer value |
| 6 | Hive `Map<dynamic,dynamic>` sanitised | no crash |
| 7 | `unrealizedPL` normal case | correct sign and magnitude |
| 8 | `unrealizedPL` on a closed position | 0, no divide-by-zero |
| 9 | Missing price | documented null/0 behaviour, no crash |
| 10 | Widget: no price doc | shows `—` |
| 11 | Widget: stale `updatedAt` | staleness treatment applied |

---

## Acceptance criteria

- [ ] `flutter analyze` — 0 errors; `flutter test` fully green
- [ ] With hand-seeded `market_prices` docs, live price and unrealized P/L appear correctly
- [ ] Airplane mode: last-known price still displays, marked stale
- [ ] **Every dashboard tile is byte-identical to before this phase** — same numbers, same meanings,
      no new tiles. Screenshot the dashboard before and after and put both in your report.
- [ ] A ticker with no price doc renders `—` everywhere, no crash

## Out of scope

Fetching prices (Phase 08). Alerts (06/07). FCM (05). Changing existing dashboard metrics.
