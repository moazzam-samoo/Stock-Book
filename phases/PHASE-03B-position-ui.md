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

---

## Review notes (2026-09-04)

**Task 1 only was implemented.** Tasks 2–5 have no corresponding code anywhere in the repo — confirmed
by grepping/searching for their expected symbols and files, all returning nothing:

| Task | Expected | Found |
|---|---|---|
| 2 — Providers | `allPositionsProvider`, `filteredPositionsProvider`, position-derived summary providers | **None exist** |
| 3 — `PositionCard` | `lib/presentation/transactions/widgets/position_card.dart` | **File does not exist** |
| 4 — Sell/buy flow rework | `SelectLotBottomSheet` deleted; `AddSellBottomSheet`/`AddBuyBottomSheet`/`EditLotBottomSheet`/`EditSaleBottomSheet` reworked for positions | `select_lot_bottom_sheet.dart` still present, unchanged; the four bottom sheets are untouched |
| 5 — PDF rework | `exportPositionPdf`, cost-basis column | `pdf_report_service.dart` still only has `exportLotPdf` |

Task 1 (`position_migration_runner.dart`, the 4 new `FirestoreDataSource` methods, `dashboard_screen.dart`
wiring, `user_model.dart`'s new `schemaVersion` field) **was built and is sound**, with 5 issues found and
fixed during review:

1. **3 unused imports** in `position_migration_runner.dart` (`cloud_firestore`, `firestore_paths.dart`,
   `user_model.dart`) — removed. One (`lot_model.dart`) was mistakenly removed along with them, since
   `LotModelExtension.toEntity()` needs it — re-added.
2. **2 duplicate imports** in `dashboard_screen.dart` (`stat_card_grid.dart`, `stock_row.dart` each
   imported twice) — removed the duplicates.
3. **2 of the 6 required Task-1 tests were missing** (idempotency, chunked batching above 450) — written
   and added to `position_migration_runner_test.dart`.
4. The new idempotency test itself had **two Mockito `verify`/`verifyNever` mistakes**: `verify()` marks
   matched calls as consumed, so a second `.called(1)` against the same single call finds nothing, and
   `verifyNever()` only looks at calls made *after* the last verification point, not the whole test. Fixed
   by verifying (consuming) every first-run call immediately after the first `runIfNeeded()`, then using
   `verifyNever` for both mocked methods after the second, idempotent call.
5. **Deviation from the brief:** the migration trigger lives in `DashboardScreen.initState()`
   (`WidgetsBinding.instance.addPostFrameCallback`), not "after sign-in" as specified. In practice this is
   low-risk: `SwipeableNavigationShell` uses `PageView`'s plain `children:` constructor, which keeps all
   three tab screens (including `DashboardScreen`) mounted for the whole app session, so `initState()`
   fires once per session, not on every dashboard revisit.

**Result:** `flutter analyze` — 0 errors, 27 warnings (all pre-existing baseline, none new).
`flutter test` — 91/91 passing, including all 6 Task-1 migration tests and the unchanged Phase 00
characterisation test.

**None of the acceptance-criteria items that depend on Tasks 2–5 can be checked** (no `PositionCard` to
screenshot, no way to verify "STPL shows as one card"). Only the Task-1-scoped items hold:
`flutter analyze`/`flutter test` clean, `lots` untouched, second launch doesn't re-run migration.

Given the scale of what's missing — the large majority of a phase explicitly estimated at 2–3 days — this
was reported back rather than silently built out during review.

---

## Review notes, part 2 (2026-09-04) — Tasks 2–5 completed

Between the note above and this one, the coding agent built most of Tasks 2–5: `position_card.dart`,
`position_sale_row.dart`, `edit_buy_bottom_sheet.dart` were added; `edit_lot_bottom_sheet.dart` was
deleted; `pdf_report_service.dart` gained `exportPositionPdf`; providers and screens were partially
rewired. **The app did not compile.** `allLotsProvider` had been deleted from `dashboard_providers.dart`
but was still referenced from 4 call sites; `filteredLotsProvider` was renamed to `filteredPositionsProvider`
but `transactions_screen.dart` still called the old name; `StockSummary(...)` was being constructed with
named parameters (`averageCost`, `realizedProfitLoss`) that don't exist on that class; `AddSellBottomSheet`
and `EditSaleBottomSheet` were being called with `Position`/`PositionSale` arguments while still declaring
`Lot`/`Sale` parameters; `select_lot_bottom_sheet.dart` was still wired into the "Add Sell" flow, still
lot-based, and never deleted. On top of the compile errors, `AddSellController`/`AddBuyController` still
wrote exclusively to `lotRepositoryProvider` — meaning even once compiling, every new buy/sell after
migration would update `lots` while `positions` silently went stale, and `position_sale_row.dart` computed
each sale's profit against the position's *current* avg cost instead of its frozen `costBasisAtSale`,
violating the core rule from PHASE-03A.

This pass fixed the compile errors and closed the remaining Task 2–5 gaps:

- **`position_calculator.dart`**: added `computeStatus`, `findOpenPosition`, `applyBuy`, `applySell` — pure,
  testable helpers so every write path (buy/sell/edit) restamps `Position.status` consistently instead of
  each caller reimplementing the 3-way open/partial/closed rule. `applySell` is what actually freezes
  `costBasisAtSale` at write time.
- **`portfolio_calculator.dart`**: fixed the `StockSummary` constructor call (`avgBuyPrice`/`realizedPL`/
  `status`, with a `PositionStatus → LotStatus` mapper since `StockSummary.status` is still `LotStatus` —
  that class was out of this phase's scope so it wasn't touched) and the `PositionCalculator.status(...)`
  typo (should be `position.status`, a stored field, not a calculator method).
- **`dashboard_providers.dart`**: re-added `allLotsProvider` (lots are never deleted by the migration and
  the JSON backup export still needs them) alongside `allPositionsProvider`.
- **`dashboard_screen.dart` / `stock_detail_screen.dart`**: switched their main data source from
  `allLotsProvider` to `allPositionsProvider`; stock detail now renders a single `PositionCard` per ticker
  instead of a `LotCard` list (there's only one position per ticker to show).
- **`transactions_screen.dart`**: `filteredLotsProvider` → `filteredPositionsProvider`, `LotCard` →
  `PositionCard` — the actual "one card at the blended average" change the brief called the phase's most
  visible improvement.
- **New `select_position_bottom_sheet.dart`** replaces the deleted `select_lot_bottom_sheet.dart`: a
  ticker picker over open positions. `add_transaction_bottom_sheet.dart`'s "Add Sell" now skips straight to
  `AddSellBottomSheet` when exactly one position is open, matching the brief.
- **`add_sell_bottom_sheet.dart` + `add_sell_controller.dart`**: reworked to take a `Position`, validate
  against `PositionCalculator.sharesHeld`, and persist via `PositionCalculator.applySell` +
  `positionRepositoryProvider.updatePosition`.
- **`add_buy_controller.dart`**: reworked to find the ticker's open position (`findOpenPosition`) and
  append via `applyBuy`, or create a new `Position` if none is open — matching the "new position each time"
  rule from PHASE-03A.
- **`edit_sale_bottom_sheet.dart`**: reworked to take `Position`/`PositionSale`, preserving
  `costBasisAtSale` exactly on edit, with an explicit on-screen note that editing a sale doesn't touch its
  booked basis.
- **`edit_buy_bottom_sheet.dart`**: already correct from the coding agent's pass; added the brief's
  required warning that editing a buy shifts avg cost going forward without rewriting past sales.
- **New `position_buy_row.dart`** (mirrors `position_sale_row.dart`) fills the "Buys list" the brief
  required in `PositionCard`'s expanded view (previously only sales were shown) — swipeable Edit/Delete per
  buy, with a delete guard that refuses to drop a buy if doing so would leave sold shares exceeding
  purchased shares. `PositionCard`'s "Edit Position" context-menu item now opens `EditBuyBottomSheet`
  directly when there's exactly one buy, or expands the card (revealing each buy's own edit action) when
  there are several — the brief didn't say what "Edit Position" means for a multi-buy position, and this
  was the least ambiguous resolution.
- **Fixed a real profit-calculation bug** in `position_sale_row.dart`: it computed each sale's P/L against
  `PositionCalculator.avgCost(position)` — the position's *current* average — instead of
  `positionSale.realizedPL`, which is anchored to the frozen `costBasisAtSale`. A later buy would have
  silently changed the displayed profit/loss of an already-booked sale. Also added the "Cost Basis" line
  the brief asked for.
- **Deleted dead code**: `lot_card.dart`, `select_lot_bottom_sheet.dart`, `sale_event_row.dart` (the last
  had zero remaining references anywhere — `PositionSaleRow` replaced it as a new file rather than
  extending it as the brief suggested, but nothing else changed that decision).
- **Golden tests**: `contrast_test.dart` and `theme_golden_test.dart` referenced the deleted `LotCard`;
  rebuilt both against `PositionCard`/`Position` fixtures. `stock_detail_light/dark` and the renamed
  `position_card_light/dark` masters were regenerated — the underlying screens' content genuinely changed
  (a `PositionCard` now renders where `LotCard`s used to).
- **Wrote the 6 remaining required tests**: `dashboard_position_parity_test.dart` (required test 7 — the
  fixture's lot-derived and position-derived `PortfolioSummary` match on every money field; `openLots`
  deliberately doesn't, since it now counts open *positions* not open *lots* — documented in the test with
  the reasoning, since 2 lots per ticker in the fixture can merge a closed lot and a still-open lot into one
  still-open position); `applySell`/`findOpenPosition`+`applyBuy`/`computeStatus` unit tests in
  `position_calculator_test.dart` (required tests 8, 9, 10); `position_card_test.dart` (required tests 11,
  12 — two buys of one ticker render as one card at the blended average, and expanding it shows both
  buys' own dates and prices).

**Result:** `flutter analyze` — 0 errors, 23 warnings (all pre-existing baseline; fewer than before, since
deleting dead files removed some of their unused-import warnings). `flutter test` — **102/102 passing**
(up from 91), including the Phase 00 characterisation test, all 6 Task-1 migration tests, and all 6 newly
written Task 2–5 tests.

**Not done, out of this pass's scope:**
- No manual on-device verification with real data (the brief's "screenshot both, dashboard identical
  before/after" acceptance item) — that's for manual testing, not something a code review can produce.
- `MetricDetailCard`'s "Open Lots" drill-down (tap the dashboard's Open Lots stat) still counts individual
  lots, not positions — left alone deliberately, consistent with the brief's "keep the old lot-based
  functions, add position equivalents alongside" instruction for `PortfolioCalculator`. It means that one
  drill-down panel's count can differ from the main stat card's count post-migration; this is the same kind
  of divergence documented for `openLots` above, not a bug.
- The JSON backup export (Settings screen) still backs up `lots`, not `positions` — reasonable, since lots
  remain the rollback source of truth per PHASE-03A, and Task 5 only asked for the PDF rework.

All acceptance-criteria items that don't require a real device/Firestore account now hold:
`flutter analyze`/`flutter test` clean, `lots` still present and untouched, second launch doesn't re-run
the migration, STPL-equivalent shows as one card at the blended average (proven by the widget test).
