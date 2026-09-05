# Phase 03A — Position model + migration engine (no UI)

> Read [../AGENTS.md](../AGENTS.md) and [README.md](README.md) before starting. The universal agent
> rules in README.md apply in full.

**Depends on:** Phase 00 · **Estimated:** 2–3 days · **Branch:** `feat/positions-and-alerts`

## Why 03 is split into A and B

Phase 03 as originally scoped (domain + data + migration + full UI rewrite + PDF) is roughly 1500
lines across 15 files. That is too large to review properly, and it is the one phase that touches
real money history. So it is split:

- **03A (this brief)** — build the engine and *prove it with tests*. **It never runs against real
  user data.** No UI changes. Nothing the user can see changes at all.
- **03B (next brief)** — wire the UI over to positions and actually run the migration once.

Both land on the same branch before anything ships, so the split is purely for reviewability.

**Do not wire the migration into app startup in this phase.** That is 03B's job. If you find
yourself editing `main.dart` or any screen, you have left scope.

---

## The model: moving-average cost

```
state: sharesHeld, totalCost          avgCost = totalCost / sharesHeld

BUY(qty, price):
    sharesHeld += qty
    totalCost  += qty × price          → avgCost moves

SELL(qty, price):
    costBasisAtSale = avgCost          → FROZEN onto the sale record
    realizedPL      = qty × (price − costBasisAtSale)
    totalCost      -= qty × costBasisAtSale
    sharesHeld     -= qty              → avgCost unchanged
```

Worked example — the reference case, must produce these exact numbers:

| Event | Shares | Total cost | Avg cost |
|---|---|---|---|
| Buy 500 @ 8.73 (2026-08-31) | 500 | 4,365.00 | 8.7300 |
| Buy 1,200 @ 8.38 (2026-09-07) | 1,700 | 14,421.00 | **8.4829** |
| Sell 200 @ 9.00 | 1,500 | 12,724.41 | 8.4829 |
| → realized on that sale | | | **+103.41** |

*(Corrected during review — the original draft of this table had an arithmetic slip, stating 12,724.42 /
+103.42. The verified figures above are 200 × (9.00 − 14421/1700) = 200 × 0.517058... = 103.41176...,
rounding to +103.41. The implementation's own tests independently confirmed this by hand before this
correction was made — see `position_calculator_test.dart`.)*

`costBasisAtSale` is the whole point: a buy after a sale moves `avgCost` for *future* sales but can
never change a P/L already booked.

**Position resets on close — confirmed by Moazzam, 2026-09-04.** When `sharesHeld` reaches 0 the
position is closed permanently. A later buy of the same ticker opens a **new** position with a fresh
average; it never reopens the old one.

This means one ticker can have several position records over time — one per completed round trip,
plus the current open one. That is intended: each closed position is a finished trade with its own
P/L, the way a broker statement reads. The Transactions list will therefore show multiple cards for
the same ticker under the `All` and `Closed` filters, and only one under `Open`.

---

## Task 1 — Domain layer

**`lib/domain/entities/position_buy.dart`**

```dart
class PositionBuy {   // id, date, shares (int), pricePerShare (double)
```

**`lib/domain/entities/position_sale.dart`**

```dart
class PositionSale {  // id, date, shares (int), pricePerShare, costBasisAtSale (double)
  double get amountReceived  => shares * pricePerShare;
  double get realizedPL      => shares * (pricePerShare - costBasisAtSale);
}
```

**`lib/domain/entities/position.dart`**

```dart
class Position {
  final String id, ticker;
  final PositionStatus status;      // open | closed
  final DateTime openedAt;
  final DateTime? closedAt;
  final double? targetPrice;
  final List<PositionBuy> buys;
  final List<PositionSale> sales;
}
```

Follow the existing entity conventions (see `lot.dart` — immutable, `copyWith`, `equatable`).

**`lib/domain/enums/position_status.dart`** — `open`, `partiallySold`, `closed`, with a
`displayName` extension mirroring `LotStatus` (`Open` / `Partial` / `Closed`).

### Status rule — keep `partiallySold`

```
totalBought = Σ buys.shares
totalSold   = Σ sales.shares
sharesHeld  = totalBought − totalSold

sharesHeld == 0   → closed
totalSold  == 0   → open
otherwise         → partiallySold
```

This is the **exact same semantic the app already applies per ticker.**
`PortfolioCalculator.calculateStockSummaries` (see `portfolio_calculator.dart`, the
`anyPartial || sharesHeld < totalPurchased` branch) already aggregates lots into a per-ticker
`partiallySold` status, and the dashboard's stock rows already render it. A position *is* that
per-ticker grouping, so the status carries over unchanged — the filter chips
(`Open / Partial / Closed / All`) keep working exactly as they do today.

Port that existing logic rather than inventing a new rule, and keep `StatusBadge` working as-is.

---

## Task 2 — The replay engine (pure, no Firestore)

**`lib/domain/calculator/position_calculator.dart`** — all static, all pure. This is the heart of
the phase and where nearly all the test weight sits.

```dart
static List<Position> replay(String ticker, List<PositionBuy> buys, List<PositionSale> sales)
static double avgCost(Position p)
static int    sharesHeld(Position p)
static double totalCost(Position p)
static double realizedPL(Position p)        // Σ sale.realizedPL — never recomputed from avgCost
static double amountInvested(Position p)    // sharesHeld × avgCost
```

`replay` merges buys and sales into one date-sorted event stream and walks it, splitting into
multiple `Position` objects at every zero-crossing.

**Rules the engine must follow:**

1. Sort events by date. **Ties: buys before sales on the same date** (you cannot sell what you have
   not bought that day). Make this explicit — it is a real ordering decision, not an accident.
2. A sale carrying a non-null `costBasisAtSale` (i.e. migrated history) **uses that stored value**.
   A sale with a null basis takes the current `avgCost` at that point in the replay. This is what
   keeps historical P/L identical after migration.
3. `sharesHeld` reaching exactly 0 closes the position; `closedAt` = that sale's date.
4. **Never let `sharesHeld` go negative.** If a sale would overshoot, clamp it, and record the
   problem (see Task 4's report) rather than throwing. Corrupt input must not crash the app.
5. Round money to 2dp with the same `_round` approach `PortfolioCalculator` uses. Do **not** round
   `avgCost` in intermediate state — round only at the boundary when reporting. Rounding the running
   average compounds error across many events.

---

## Task 3 — Data layer

- **`lib/data/models/position_model.dart`** — `@freezed`, embedded `buys[]` and `sales[]`, following
  `lot_model.dart` exactly (including its explicit nested re-serialisation, see AGENTS.md §4.1).
  Dates must tolerate `Timestamp` *or* ISO `String` — copy the hand-written `fromJson` pattern from
  `sale_model.dart`, do not rely on generated code for the nested lists.
- **`lib/core/constants/firestore_paths.dart`** — add `positions(uid)` and `position(uid, id)` for
  `users/{uid}/positions/{positionId}`.
- **`lib/domain/repositories/position_repository.dart`** + **`lib/data/repositories/position_repository_impl.dart`** —
  mirror `LotRepository` / `LotRepositoryImpl`: `watchAllPositions()`, `addPosition`,
  `updatePosition`, `deletePosition`.
- **`FirestoreDataSource`** — add the corresponding stream + writes, each with the `.timeout(4s)` +
  `catch (_)` idiom (AGENTS.md §8), stripping `id` on write and injecting `doc.id` on read.
- **`lib/providers/repository_providers.dart`** — `positionRepositoryProvider`, nullable, gated on
  `currentUserIdProvider`, exactly like the others.
- **`firestore.rules`** — add:
  ```
  match /users/{uid}/positions/{positionId} {
    allow read, write: if request.auth != null && request.auth.uid == uid;
  }
  ```

**Leave the `lots` collection completely alone.** Do not delete it, do not write to it, do not add a
`lots_backup` collection.

> This supersedes the `lots_backup` step in `IMPLEMENTATION_PLAN.md`. Because positions are a **new**
> collection and nothing overwrites `lots`, the original data *is* the backup — untouched and
> already in Firestore. An extra copy would be one more thing to get wrong for no gain.

---

## Task 4 — The migration builder (pure) + verifier

**`lib/domain/calculator/position_migration.dart`**

```dart
class MigrationResult {
  final List<Position> positions;
  final bool           isValid;          // false ⇒ CALLER MUST NOT WRITE
  final List<String>   warnings;         // clamped sales, target conflicts, etc.
  final double         lotsGrossRealizedPL, positionsGrossRealizedPL;
  final double         lotsCurrentlyInvested, positionsCurrentlyInvested;
}

static MigrationResult buildPositions(List<Lot> lots)
```

Steps:

1. Group lots by ticker.
2. Each lot → one `PositionBuy` (`shares` = `sharesPurchased`, `pricePerShare` = `buyPricePerShare`,
   `date` = `buyDate`).
3. Each embedded sale → one `PositionSale` with
   **`costBasisAtSale` = its parent lot's `buyPricePerShare`**. This single line is what makes
   migration arithmetically invisible.
4. `replay()` per ticker → the position list.
5. `targetPrice`: take the one from the most recent buy that has a non-null value; add a warning for
   every conflict discarded.
6. **Verify, and set `isValid` accordingly:**
   - Σ position realized P/L == Σ lot realized P/L (within 0.01)
   - Σ position `sharesHeld` per ticker == Σ lot `sharesRemaining` per ticker (exact, integers)
   - Σ position `amountInvested` == Σ lot `amountInvestedRemaining` (within 0.01)

   Compare against `PortfolioCalculator`'s existing lot functions — that is the trusted reference,
   and Phase 00's characterisation tests already lock its behaviour.

`isValid == false` means the migration is wrong and must never be persisted. 03B will refuse to
write on a false. Make that contract loud in a doc comment.

---

## Required tests

`test/domain/calculator/position_calculator_test.dart`:

| # | Test | Asserts |
|---|---|---|
| 1 | STPL reference case | avg is exactly `8.4829`; realized on the 200-share sale is `+103.42` |
| 2 | Sell does not move avgCost | avg identical before/after a sale |
| 3 | Buy does move avgCost | recomputed correctly |
| 4 | **Retroactivity guard** | book a sale, then add a later buy → the earlier sale's `realizedPL` is byte-identical |
| 5 | Position reset | sell to zero then buy again → 2 positions, second starts fresh |
| 6 | Zero-crossing split | interleaved buys/sales across zero land in the right cycles |
| 7 | Same-date ordering | buy and sale on the same date → buy applies first |
| 8 | Oversell clamp | a sale exceeding holdings clamps, warns, does not throw |
| 9 | Stored basis wins | a sale with `costBasisAtSale` set ignores the running avg |
| 10 | Rounding | 1,700 shares at a 4dp average still reconciles to the invested total within 0.01 |
| 11 | Empty input | no buys → no positions, no crash |

`test/domain/calculator/position_migration_test.dart`:

| # | Test | Asserts |
|---|---|---|
| 12 | **Migration invariant — the critical one.** Reuse the *exact* Phase 00 characterisation fixture (8 lots / 12 sales / 3 tickers). | realized P/L, shares held per ticker, and currently-invested all match the lot-based figures; `isValid == true` |
| 13 | Idempotency | `buildPositions` twice → identical output |
| 14 | Deliberately broken input (a sale with no matching lot shares) | `isValid == false`, warnings populated |
| 15 | targetPrice conflict | most-recent-buy value wins; warning recorded |
| 16 | Single lot, no sales | one open position, avg == buy price |

**Test 12 must import the same fixture data as Phase 00's characterisation test.** Extract it to a
shared helper (`test/fixtures/portfolio_fixture.dart`) and have *both* test files use it — if the
two fixtures ever drift apart, the invariant proves nothing.

`test/data/models/position_model_test.dart`: round-trip; `Timestamp` and ISO-`String` dates both
parse; nested `buys`/`sales` serialise as plain maps (no `_PositionBuy` instances reaching Firestore).

---

## Acceptance criteria

- [x] `flutter analyze` — **0 errors**
- [x] `flutter test` — fully green, all Phase 00/01/02 tests still passing (85 total)
- [x] Test 12 passes against the shared fixture — lots vs. positions: realized P/L 8195.0 == 8195.0,
      currently invested 204946.0 == 204946.0, shares held agree per ticker, `isValid: true`
- [x] `build_runner` run and generated files committed
- [x] **The app looks and behaves exactly as before** — no user-visible change whatsoever
- [x] Nothing writes to Firestore's `positions` collection yet at runtime
- [x] `lots` collection untouched in code

**Status: Done — reviewed and fixed 2026-09-05.** See the review notes below for what was found and
corrected before this could be signed off.

## Out of scope

Any UI. Wiring migration into startup. Deleting or writing `lots`. Touching
`PortfolioCalculator`'s existing lot functions (03B still needs them as the verification reference).
Live prices, alerts, notifications.

## Report back

Beyond the standard report: paste the **actual numbers** from test 12 — the lot-based and
position-based totals side by side. That comparison is the single most important output of this
phase, and I want to see the figures, not just a green tick.

```
--- Migration invariant check (shared Phase 00 fixture) ---
Gross realized P/L  — lots: 8195.0, positions: 8195.0
Currently invested  — lots: 204946.0, positions: 204946.0
isValid: true, warnings: []
```

---

## Review notes (2026-09-05)

The first submission had the engine and migration logic essentially right, but wasn't safe to sign
off as-is. Found and fixed:

1. **A real rounding bug, worth $4.41 on the reference scenario.** `totalCost()`/`amountInvested()`
   computed `sharesHeld × avgCost(p)` using the *already-2dp-rounded* public `avgCost()` — which
   re-introduces exactly the "rounding an intermediate value" failure Rule 5 warns about, just via
   function composition instead of a single loop. On the STPL case (1,500 sh remaining after the
   200-share sale, avg 8.4829... rounding to 8.48): `1500 × 8.48 = 12,720.00`, against a true
   remaining cost of `12,724.41` — off by $4.41. Fixed by extracting a private
   `_preciseTotalCost()` that both `avgCost()` and `totalCost()`/`amountInvested()` now derive from,
   so none of them round until their own final return. **This is exactly the class of bug the
   required-but-missing "rounding reconciliation" test (below) exists to catch — nobody had written
   it yet.**
2. **Missing import** — `firestore_data_source.dart` never imported `position_model.dart` at all;
   `PositionModel` only resolved because nothing had actually run `flutter analyze` since it was
   added. Compiled clean once added; the stale generated mock this cascaded into
   (`lot_repository_impl_test.mocks.dart`) needed one `build_runner build` to catch up.
3. **Migration validation was only checking 2 of the 3 required invariants.** Realized P/L and
   amount-invested were compared; **shares held per ticker was not** — the one explicitly named in
   this brief's Task 4. Added it. It's not redundant with the other two: amount-invested is
   `shares × avgCost`, so a genuine share-count corruption can still leave that product looking
   plausible while the raw share count is wrong.
4. **Target-price conflicts were silently resolved with no warning**, despite Task 4 explicitly
   requiring one. Added.
5. **6 of 11 required calculator tests and 4 of 5 required migration tests were missing**, including
   the single most important one — the retroactivity guard. Added all of them; see
   `position_calculator_test.dart` and `position_migration_test.dart`. The rounding test above is
   the one that would have caught bug #1 on its own.
6. **This brief's own worked-example table had an arithmetic error** (stated 12,724.42 / +103.42;
   the correct figures, verified independently, are 12,724.41 / +103.41). Corrected above. The
   original implementation's test asserted the *correct* number and flagged the discrepancy in a
   code comment rather than blindly matching this brief — that was the right call, and is why this
   was caught.
7. Not fixed, logged for awareness: `PositionMigration` assigns the resolved `targetPrice` to a
   ticker's most recent position **regardless of whether it's open or closed**. Harmless (a closed
   position's target price is inert data no alert logic should ever read), but if 03B or Phase 06
   builds anything that reads `targetPrice` off a position without checking `status` first, this is
   where a stray value could come from.

None of the above affect the migration invariant numbers above — those were correct before and after
this pass. What changed is that the code now has the test coverage to *prove* it, and one latent
rounding bug that the missing coverage had let through is gone.
