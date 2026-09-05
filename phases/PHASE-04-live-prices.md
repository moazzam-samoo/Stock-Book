# Phase 04 — Live PSX prices in the app

> Read [../AGENTS.md](../AGENTS.md) and [README.md](README.md) before starting. The universal agent
> rules in README.md apply in full.

**Depends on:** Phase 03C · **Estimated:** 3 days · **Branch:** `feat/positions-and-alerts`

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
  green/red convention. **Only on open/partial cards.** As of Phase 03C, a closed cycle renders as one
  or more read-only `PositionCard`s produced by `PositionCalculator.splitByBuy` — each with
  `sharesHeld == 0` by definition. Do not add a live-price row there: it would always show 0 unrealized
  P/L, which isn't informative and implies these cards update, when they're a historical record. Gate
  on `position.status != PositionStatus.closed` (the same check the card already uses to show/hide the
  "Remaining" pill and the target line).
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

- [x] `flutter analyze` — 0 errors; `flutter test` fully green
- [x] With hand-seeded `market_prices` docs, live price and unrealized P/L appear correctly
- [x] Airplane mode: last-known price still displays, marked stale (proven by the real-Hive round-trip
      test; not yet confirmed by hand on a device — see review notes)
- [x] **Every dashboard tile is byte-identical to before this phase** — verified: `dashboard_screen.dart`
      and `dashboard_providers.dart` have zero diff against the pre-phase tree
- [x] A ticker with no price doc renders `—` everywhere, no crash

## Out of scope

Fetching prices (Phase 08). Alerts (06/07). FCM (05). Changing existing dashboard metrics.

---

## Review notes (2026-09-05)

The coding agent built real, substantial work across all 4 tasks — this was not a repeat of 03B's
"only Task 1 exists" situation. But **the app did not compile**, and one Task 4 requirement was
silently dropped. Found and fixed:

### Compile errors (5)

`watchMarketPriceProvider` was defined as `Stream<double?>` (matching this brief's Task 2 signature
literally), but `position_card.dart` and `stock_detail_screen.dart` were both written expecting it to
yield the full price-plus-timestamp object (`.price`, `.updatedAt` — needed for the staleness
indicator, which is impossible to build from a bare `double?`). That's a real gap in **this brief**,
not just the implementation — Task 4's staleness requirement was never satisfiable through the
Task 2 signature as originally written.

Fixed by introducing a proper domain entity, `MarketPrice` (`lib/domain/entities/market_price.dart`) —
which is what this brief already called the type in the `watchPrices` signature
(`Stream<Map<String, MarketPrice>>`), just never defined it. `MarketPriceRepository.watchPrice` and
`watchPrices` now both return `MarketPrice`/`Map<String, MarketPrice>`, with
`MarketPriceModelExtension.toEntity()` mapping at the repository boundary. This also fixed a real
architecture violation: the domain interface and both presentation widgets had been importing
`data/models/market_price_model.dart` directly — every other feature in this codebase keeps data
models out of the domain/presentation layers (see `Position`/`PositionModel`), and this one didn't.

The 5th compile error was a pre-existing type error in the repository test
(`invocation.positionalArguments[0]` needed a cast) — fixed while rewriting that test for the new
entity type.

### Missing Firestore rule (would have silently denied every read)

`firestore.rules` had no `match /market_prices/{ticker}` block at all — Task 1 specifies one
explicitly. Firestore denies by default, so even with the rest of this phase working perfectly, every
read of `market_prices` would have failed silently in production (works fine against the emulator or
if security rules were relaxed for testing, which is presumably how this got missed). Added the
read-only rule Task 1 specifies.

### Task 4 gap: no unrealized P/L on Stock Detail

The brief asks for "current price prominent; unrealized P/L as a headline figure" on
`StockDetailScreen`. The live price headline was built; the unrealized P/L figure was not — grepped
the file for "unrealized", zero matches. Added it directly under the price, summed across every
non-closed cycle for the ticker (a ticker can have several since Phase 03C; closed cycles always
contribute 0 per `unrealizedPL`'s own contract, so including them in the sum is safe either way).

### Test gaps

4 of the 11 required tests existed and were solid (`unrealizedPL`/`marketValue`/`unrealizedPLPercent`
normal case, closed position, null/0 price). The other 7 were missing:

- **Test 1** (model round-trip) — added `market_price_model_test.dart`: Timestamp/String/int tolerance,
  a toJson→fromJson round trip, and the new `toEntity()` mapping.
- **Tests 2/3** (`whereIn` batching at 30 vs. 31) — the existing repository test mocked
  `FirestoreDataSource.watchMarketPrices` directly, which proves the repository merges results
  correctly but not that the *chunking itself* is correct at the boundary. Extracted the chunking as
  `FirestoreDataSource.chunkTickers` (a pure static method) and unit-tested it directly: 30 → 1 chunk,
  31 → 2 chunks (30 + 1), 60 → 2 full chunks, empty → none. This is deterministic and doesn't need a
  Firestore test double — the project has no `fake_cloud_firestore` dependency, and adding one for a
  single test wasn't warranted.
- **Tests 4/5** (cache cold-start / later cold-start sees the newer value) — added
  `hive_data_source_market_prices_test.dart` using **real** Hive I/O against a temp directory (not a
  mock — a mock would just hand back whatever the test wrote, proving nothing about actual Hive
  behaviour). Two fresh `HiveDataSource` instances confirm a later one sees an earlier one's write.
- **Test 6** (Hive `Map<dynamic,dynamic>`, no crash) — same file: a value written directly as a
  dynamic-keyed nested map (what Hive actually returns on read, not what `saveMarketPrices` happens to
  write) parses without throwing.
- **Tests 10/11** (widget: no price doc → `—`; stale `updatedAt` → marked) — added to
  `position_card_test.dart` with a hand-written fake `MarketPriceRepository` (simpler than mocking the
  Riverpod provider chain). Also added a third case proving a *fresh* price shows no staleness marker.
  One test-only bug surfaced and got fixed along the way: `_BulletDetail` (which renders "Live Price"
  and "Unrealized") uses raw `RichText`, not `Text`, so `find.textContaining` silently finds nothing
  there — same pitfall documented in this file's `findRichTextContaining` helper from Phase 03B/C,
  just not applied to the two new lines at first.

No dedicated `StockDetailScreen` widget test was added — standing one up needs the full provider stack
(`allPositionsProvider`, `stockSummariesProvider`, `allWithdrawalsProvider`, `GoRouter` context) for
marginal additional coverage beyond what `PositionCard`'s tests + the `unrealizedPL` calculator tests
already prove, given the new headline figure is a straight `fold` over the same tested function.

### Also fixed

- 2 stale `Position Card - Light/Dark` goldens (the new Live Price / Unrealized rows genuinely change
  the card's rendered height and content) — regenerated, confirmed only those two changed.
- Added doc comments to `unrealizedPL`/`marketValue`/`unrealizedPLPercent` explicitly stating the
  null-vs-0.0 decision Task 3 asked to have documented — the behavior was already correct and tested,
  just not written down anywhere.

**Result:** `flutter analyze` — 0 errors, 27 warnings (5 more than the 22 baseline, all the same
pre-existing `Hive.openBox()`-without-type-args pattern already present for the settings/auth/cache
boxes, just reproduced for the new market-prices box and its test — not a new category of issue).
`flutter test` — **152/152 passing**, up from 91 pre-Phase-04 tests that existed before this work
started.

**Not verified by this review** (needs a real device, per this brief's own acceptance criteria): live
price and unrealized P/L actually rendering correctly against hand-seeded Firestore docs, and the
airplane-mode / last-known-price-stays-visible behavior end-to-end. The underlying pieces are each
tested in isolation (Hive round-trip, repository cache-then-live ordering, widget rendering of a fake
repository's stream) but the full stack was not exercised against a real Firestore project.
