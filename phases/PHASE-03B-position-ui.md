# Phase 03B — Switch the UI to positions + run the migration

> Read [../AGENTS.md](../AGENTS.md) and [README.md](README.md) before starting. The universal agent
> rules in README.md apply in full.

**Depends on:** Phase 03A · **Estimated:** 2–3 days · **Branch:** `feat/positions-and-alerts`

This is the phase where the migration actually runs against real data and the user's Transactions
tab changes shape. Highest-risk phase in the project. Read
[PHASE-03A-position-model.md](PHASE-03A-position-model.md) first — the engine and its guarantees are
described there.

---

## Task 1 — Run the migration, once, safely

**`lib/data/migration/position_migration_runner.dart`**

```dart
Future<MigrationOutcome> runIfNeeded()
```

Sequence — and the order matters:

1. Read `users/{uid}.schemaVersion`. If it is `>= 2`, **return immediately**. Nothing else happens.
2. Load all lots (one read, not a stream).
3. If there are **no lots at all**, just stamp `schemaVersion: 2` and return. A new user needs no
   migration.
4. Call `PositionMigration.buildPositions(lots)`.
5. **If `result.isValid == false`: write nothing.** Stamp nothing. Log the warnings, report the
   failure, and leave the app running on the old path. A failed verification means the numbers
   would change — that is exactly the situation this whole design exists to prevent.
6. If valid: write all positions **and** `schemaVersion: 2` in a **single `WriteBatch`**, so the
   marker cannot be set without the data landing. A partial migration that stamps the version is
   unrecoverable — it would skip forever with incomplete data.
7. Never delete or modify `lots`. It remains the rollback path.

**Batch size:** Firestore caps a batch at 500 writes. Positions are far fewer than lots, so one
batch is realistic — but if `positions.length + 1 > 450`, split into chunked batches and **write the
`schemaVersion` marker last, in its own commit after all chunks succeed.**

**Where to call it:** after sign-in, once a uid exists — same place Phase 05 will later hook push
notifications. Await it before the first dashboard render, and show a brief blocking state while it
runs. Do **not** fire it from a widget `build()`.

**If migration fails:** show a non-dismissable-until-acknowledged dialog telling the user to contact
support and *not* to add transactions, then keep the app on the lot-based read path for the session.
Silent failure here is the worst possible outcome — the user would keep trading against data that
never migrated.

---

## Task 2 — Providers

`lib/presentation/dashboard/providers/dashboard_providers.dart`:

- `allPositionsProvider` — stream from `positionRepositoryProvider`
- `portfolioSummaryProvider`, `stockSummariesProvider`, `allocationDataProvider` now derive from
  positions

**Keep `PortfolioCalculator`'s lot-based functions.** They are still the verification reference and
Phase 00's characterisation test locks them. Add position-based equivalents alongside; do not delete
the old ones or edit their behaviour.

`transactions_providers.dart`:

- `filteredLotsProvider` → `filteredPositionsProvider`
- **`StatusFilter` chips stay exactly as they are** — `Open / Partial / Closed / All`, defaulting to
  `Open`. `partiallySold` carries over to positions unchanged; 03A defines the rule and notes it is
  the same one `calculateStockSummaries` already applies per ticker today. `FilterChipRow` and
  `StatusBadge` should need no behavioural change, only a type swap from `LotStatus` to
  `PositionStatus`.

---

## Task 3 — `PositionCard` replaces `LotCard`

`lib/presentation/transactions/widgets/position_card.dart`, modelled on `lot_card.dart` (657 lines —
read it fully before starting; it carries a lot of behaviour worth preserving).

Collapsed header: ticker avatar, ticker, **total shares held**, **average cost**, total invested,
status badge, realized P/L.

Expanded adds:
- **Buys list** — each with its original date, share count and price. The individual purchase
  history must remain visible; that is what makes the merge safe rather than lossy.
- **Sales list** — reuse `sale_event_row.dart`, extended to show `costBasisAtSale` so a user can see
  what basis a sale was booked at.
- Target price + estimated gain (currently computed against `buyPricePerShare` — now against
  `avgCost`).
- The existing long-press context menu (Edit / Export PDF / Delete) and the PDF button.

Preserve from `LotCard`: the expand/collapse glow, haptics, the offline-aware delete confirmation,
and the light/dark branching (Phase 02 will have touched these — rebase carefully).

---

## Task 4 — Sell flow: pick a ticker, not a lot

**`SelectLotBottomSheet` is deleted.** With one pooled position per ticker there is nothing to pick
between — this is the single most visible improvement in the whole phase.

- `AddTransactionBottomSheet` → "Add Sell" opens a **ticker picker** listing open positions
  (ticker, shares held, avg cost), or goes straight in if only one position is open.
- `AddSellBottomSheet` takes a `Position`. Max sellable = `sharesHeld`. It writes a `PositionSale`
  with `costBasisAtSale` **captured at write time from the current `avgCost`** — never recomputed later.
- `AddBuyBottomSheet` appends a `PositionBuy` to the open position for that ticker, or creates a new
  position if none is open.
- `EditLotBottomSheet` → edits a buy within a position. **Editing a buy changes `avgCost`, which
  changes the correct basis for *subsequent* sales.** Do not retroactively rewrite existing
  `costBasisAtSale` values. Surface a warning in the edit sheet that past sales keep their booked
  basis. If this proves messy, stop and ask rather than inventing a rule.
- `EditSaleBottomSheet` → edits a `PositionSale`, preserving its stored `costBasisAtSale`.

---

## Task 5 — PDF reports

`pdf_report_service.dart` — three entry points, all needing rework:

- `exportLotPdf(Lot)` → `exportPositionPdf(Position)`
- `exportStockPdf` — buys table gains its own section; sales table gains a **Cost Basis** column
- `exportOverallPortfolioPdf` — lots table becomes positions

Keep the `Rs`-prefix rule in mind (AGENTS.md §9): `AppCurrencyFormatter.format()` already emits
`Rs `. Do not reintroduce the double-prefix bug that was fixed earlier.

---

## Required tests

| # | Test | Asserts |
|---|---|---|
| 1 | **Runner skips when `schemaVersion >= 2`** | no writes issued |
| 2 | **Runner writes nothing when `isValid == false`** | no positions, no version stamp |
| 3 | Runner writes positions + marker atomically | single batch; marker present only with data |
| 4 | Runner on an empty account | stamps version, writes no positions |
| 5 | Runner is idempotent | second `runIfNeeded()` is a no-op |
| 6 | Chunked batching above 450 | marker committed last |
| 7 | **Dashboard parity** | for the shared Phase 00 fixture, position-derived `PortfolioSummary` == lot-derived, field for field |
| 8 | Sell captures basis at write time | later buys don't alter it |
| 9 | Add buy into existing open position | appends, avg recomputed |
| 10 | Add buy with no open position | creates a new one |
| 11 | Widget: `PositionCard` | two buys of one ticker → **one** card showing the blended average |
| 12 | Widget: expanded card | both original buy dates and prices still visible |

Test 7 is the user-facing version of 03A's test 12 and is the one that proves nothing moved on the
dashboard. It must use the shared `test/fixtures/portfolio_fixture.dart`.

---

## Acceptance criteria

- [ ] `flutter analyze` — 0 errors
- [ ] `flutter test` — fully green, **including Phase 00's characterisation test unchanged**
- [ ] On a real device with real data: dashboard figures **identical before and after migration** —
      screenshot both and put them in your report
- [ ] STPL (or equivalent) shows as one card at the blended average
- [ ] `lots` still present and untouched in Firestore afterwards
- [ ] Second app launch does not re-run the migration

## Out of scope

Live prices, alerts, push notifications. Deleting `lots`. Any change to withdrawal semantics.

## Stop and ask if

- Editing a buy that precedes existing sales turns out to need a rule not described here.
- Verification fails on the real dataset — **do not "fix" it by loosening the tolerance.** Report
  the actual discrepancy with numbers; a real mismatch means the model is wrong about this data and
  I need to see it.
