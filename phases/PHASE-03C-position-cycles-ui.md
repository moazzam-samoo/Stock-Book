# Phase 03C — Show every position cycle separately (closed cycles as their own cards)

> Follow-up to [PHASE-03B-position-ui.md](PHASE-03B-position-ui.md), from manual testing on 2026-09-04.
> Read [../AGENTS.md](../AGENTS.md) §14 first.

**Depends on:** 03B · **Estimated:** ~half a day · **Branch:** `feat/positions-and-alerts`

---

## The problem

The data model is already right. `PositionCalculator.replay()` splits a ticker's history into a
**separate `Position` per holding cycle**, ending one and starting the next every time shares hit zero.
The reported STPL case — buy 31 Aug + 2 Sep, sell 600, sell the rest — is already stored as one closed
position; a later re-buy already creates a second, open one.

**Every bug here is in how the UI reads that data.**

| # | Symptom | Cause |
|---|---|---|
| **0** | **Every position badge reads `OPEN`, even a fully-sold one** | **`StatusBadge` (`presentation/common/badges.dart`) handles `TradeStatus` and `LotStatus` but *not* `PositionStatus`. Its `status` field is `dynamic`, and the unrecognised-type fallback is `return TradeStatus.open`, so all four call sites that pass a `PositionStatus` silently render OPEN.** |
| 1 | Stock Detail shows only one card; closed cycles are invisible | `stock_detail_screen.dart:135` takes `.firstOrNull` of the ticker's positions. Firestore orders `openedAt` descending, so only the newest cycle ever renders. |
| 2 | A position disappears from Transactions once it's partially sold | `filteredPositionsProvider`'s default `'Open'` filter matches `PositionStatus.open` **exactly**, excluding `partiallySold`. |
| 3 | A closed card shows "Rs 0" for avg cost and total invested | `PositionCalculator.avgCost()` / `amountInvested()` return `0.0` when no shares remain — correct for "what am I still holding", useless as a historical record. |
| 4 | A ticker would appear twice in the dashboard's "Your Stocks" list | `calculateStockSummariesFromPositions` emits one `StockSummary` per **position**, not per ticker. Latent until a cycle closes and the ticker is re-bought. |
| 5 | Editing a buy can leave `status` stale | `edit_buy_bottom_sheet.dart` writes `copyWith(buys: ...)` without re-running `computeStatus`. Changing a buy's share count can close or reopen a position; the stored status won't follow. |

### Confirmed against real data (2026-09-04 screenshot)

An STPL card showed `OPEN`, 3,650 sh, "Bought Jun 19 @ **Rs 0**", "Total Invested: **Rs 0**", "3,650 of
3,650 shares sold", "+Rs 3,010", "Holding Period: 54 days".

That card is **already stored correctly as a closed position** — `holdingDays` only uses `closedAt`
when `status == closed`, and Jun 19 → 54 days lands on Aug 12, not today. So the stored status is
`closed`; symptom 0 is what printed `OPEN` over it, and symptom 3 is what printed the two `Rs 0`s. The
underlying migration/split logic is doing its job.

Its three buys (Jun 19, Jul 8, Aug 3) all precede its sales (Aug 6+), so shares never returned to zero
mid-way — that is genuinely **one** holding cycle, and therefore correctly one card with one sale
history. Cycles only split when holdings actually hit zero and buying restarts.

Note on migrated sales: their `costBasisAtSale` (8.40, 8.41) are the *original per-lot* buy prices, not
the blended average — `PositionMigration` freezes them that way on purpose so historical realized P/L
is bit-identical to what the app showed pre-migration. Sales recorded *after* migration use the blended
average. Do not "fix" this; it would rewrite booked profit.

Decisions taken (confirmed 2026-09-04):

- Dashboard "Your Stocks": **one row per ticker**, aggregating all cycles.
- Transactions: the **"Open" chip means "still holding"** — open + partial, never closed. Stays the default.
- Closed cards: **show historical figures** (what that cycle actually cost), not zeros.
- Fully-closed tickers (nothing re-bought): **drop off the dashboard list** — still reachable in
  Transactions' Closed filter and on Stock Detail.

---

## Task 0 — `StatusBadge` must understand `PositionStatus` (do this first)

`presentation/common/badges.dart`. Add the missing branch:

```dart
if (status is PositionStatus) {
  switch (status as PositionStatus) {
    case PositionStatus.open:          return TradeStatus.open;
    case PositionStatus.partiallySold: return TradeStatus.partial;
    case PositionStatus.closed:        return TradeStatus.closed;
  }
}
```

And make the fallback stop lying: keep returning `TradeStatus.open` in release (a badge should never
crash the screen) but add `assert(false, 'StatusBadge got an unhandled status type: ${status.runtimeType}')`
so this can't silently regress again. The root cause is that `status` is typed `dynamic` — that's what
let a whole enum go unhandled with no compile error. Leaving it `dynamic` is acceptable for now given
three enums flow into it, but the assert is not optional.

This one change fixes the badge everywhere at once: `PositionCard`, `SelectPositionBottomSheet`,
`AddSellBottomSheet`, `EditSaleBottomSheet`.

---

## Task 1 — Calculator: historical figures for a closed cycle

`domain/calculator/position_calculator.dart` — three additions. All pure, all unit-testable.

```dart
static int totalSharesBought(Position p)        // sum of buys' shares
static double totalCapitalDeployed(Position p)  // sum of shares × pricePerShare across buys
static double historicalAvgCost(Position p)     // totalCapitalDeployed / totalSharesBought
```

These describe **the whole cycle as it happened**, and are what a closed card reads. They are
deliberately *not* replacements for `avgCost()`/`amountInvested()`, which answer "what am I holding
right now" and must keep returning 0 for a closed position — the dashboard's `currentlyInvested`
depends on exactly that.

Also add, for Task 3's per-ticker grouping:

```dart
static double blendedAvgCost(List<Position> positionsForOneTicker)
```

It must sum the **unrounded** remaining cost across positions and round **once** at the end. Do not
build it by summing `amountInvested(p)` (each already rounded to 2dp) or by
`sharesHeld × avgCost` — that's the compounding-rounding trap documented in AGENTS.md §14 that cost
Rs 4.41 on the reference position. This needs `_preciseTotalCost` exposed to it (keep it private,
add the helper inside the same class).

---

## Task 2 — Transactions: "Open" means "still holding"

`presentation/transactions/providers/transactions_providers.dart`, in `filteredPositions`:

| Chip | Matches |
|---|---|
| **Open** (default) | `status != closed` — open **and** partiallySold |
| Partial | `partiallySold` only |
| Closed | `closed` only |
| All | everything |

`FilterChipRow` needs no change — same four chips, same labels. Sorting stays `openedAt` descending,
so the newest cycle sits above older closed ones when "All"/"Closed" is selected.

---

## Task 3 — Dashboard: one row per ticker, holdings only

`domain/calculator/portfolio_calculator.dart` → `calculateStockSummariesFromPositions`: **group by
ticker first**, then aggregate, mirroring what the lot-based `calculateStockSummaries` already does:

- `sharesHeld` — summed across the ticker's positions (only non-closed ones contribute)
- `avgBuyPrice` — `blendedAvgCost` over the ticker's positions (Task 1)
- `amountInvestedOpen` — summed
- `realizedPL` — summed across **all** cycles including closed ones; that profit is booked and must
  not vanish
- `status` — from the aggregate: 0 shares held → `closed`; else any sales anywhere → `partiallySold`;
  else `open`
- `allocationPercent` — `amountInvestedOpen` ÷ portfolio total, computed after grouping

**Dropping fully-closed tickers happens in the dashboard widget, not the calculator.**
In `dashboard_screen.dart`, filter the list it renders to `sharesHeld > 0`. Keeping the calculator
complete matters: `exportOverallPortfolioPdf` and `MetricDetailCard` both read `stockSummaries`, and a
portfolio report that silently omits closed tickers' booked profit would be wrong. The allocation donut
already filters `sharesHeld > 0` inside `calculateAllocation`, so it needs no change.

**Do not touch** `PortfolioSummary` — `realizedPL`, `portfolioValue` and `currentlyInvested` must keep
counting every cycle. Only the visible *list* shrinks.

---

## Task 4 — Stock Detail: one card per cycle

`presentation/dashboard/screens/stock_detail_screen.dart`:

- Replace `.firstOrNull` with **all** positions for the ticker, rendered as a list of `PositionCard`s.
- Order: still-held cycles first (open/partial), then closed ones newest-first.
- The header stat block (Shares / Avg Price / Total P/L) keeps reading the per-ticker `StockSummary`
  from Task 3 — that's the whole-ticker view, which is what a header should show.
- Section heading: "Position" → **"Positions"** when more than one exists.
- Empty state stays as-is for a ticker with no positions at all.

**Also fix the Export PDF action on this screen**, which currently passes `.firstOrNull` to
`exportStockPdf`. A per-stock report that drops a closed cycle's sales is wrong. `exportStockPdf`
should take `List<Position>` for the ticker and render each cycle's buys/sales, or at minimum a
combined sales table across cycles.

Related, same reasoning: `transactions_screen.dart`'s Export PDF passes `filteredPositionsProvider`.
With Task 2's default filter that now **excludes closed positions from the overall portfolio report**.
It should pass `allPositionsProvider` instead — the overall report should not depend on which chip
happens to be selected.

---

## Task 5 — `PositionCard`: closed-cycle presentation

`presentation/transactions/widgets/position_card.dart`, branching on `status == closed`:

| Line | Open / partial card | Closed card |
|---|---|---|
| Header shares | total bought (unchanged) | unchanged |
| "Bought … @ …" | `avgCost` (current) | `historicalAvgCost` — what the cycle actually cost |
| "Total Invested" | `amountInvested` (current) | `totalCapitalDeployed` |
| "Remaining" pill | shares held | hide it (always 0) |
| "Add Sale from this position" | shown | already hidden — keep |
| Realized P/L banner | shown once partial | shown |
| BUY HISTORY / SALE HISTORY | shown when expanded | shown when expanded |

The status badge already renders `CLOSED` from `position.status`, so each closed cycle is visually
tagged with no extra work. Sale history is already per-position, so a closed cycle shows only its own
sales — which is the behaviour asked for.

---

## Task 6 — Restamp status when a buy is edited

`edit_buy_bottom_sheet.dart`'s `_submit` writes `copyWith(buys: updatedBuys)` and persists it without
recomputing status. Editing a buy's share count changes `sharesHeld`, which can legitimately close or
reopen the position. Route it through `PositionCalculator.computeStatus` the same way
`EditSaleBottomSheet` and both delete handlers already do, and clear/set `closedAt` to match.

While there: that sheet also lets the ticker be edited (`_ticker.toUpperCase()`), which can move a
position onto a ticker that already has an open position — leaving two open positions for one ticker
and breaking the invariant `findOpenPosition` relies on. Either drop the ticker field from the edit
sheet (a buy belongs to the position's ticker) or block a rename that would collide. **Ask before
choosing** — dropping the field is simpler but removes a way to fix a typo'd ticker.

---

## Required tests

| # | Test | Asserts |
|---|---|---|
| 0 | `StatusBadge` with each `PositionStatus` | renders OPEN / PARTIAL / CLOSED respectively — the regression that made every position look OPEN |
| 1 | `historicalAvgCost` / `totalCapitalDeployed` on a closed position | non-zero, and equal to the cycle's real buy figures — while `avgCost`/`amountInvested` still return 0 |
| 2 | `blendedAvgCost` across two cycles of one ticker | matches a single-shot precise computation; no rounding drift vs. summing rounded per-position values |
| 3 | `filteredPositions` with 'Open' | includes `partiallySold`, excludes `closed` |
| 4 | `filteredPositions` with 'Closed' / 'Partial' / 'All' | unchanged behaviour |
| 5 | `calculateStockSummariesFromPositions` on a ticker with a closed + an open cycle | **one** row; `sharesHeld` from the open cycle; `realizedPL` summed across both |
| 6 | Same, for a fully-closed ticker | one row, `sharesHeld == 0`, realized P/L preserved (so the dashboard's *widget-level* filter is the only thing hiding it) |
| 7 | `PortfolioSummary` unchanged by all of the above | re-run the existing parity test — money figures must still match the lot-based reference |
| 8 | Widget: Stock Detail with 2 cycles | renders 2 `PositionCard`s, one badged CLOSED |
| 9 | Widget: closed `PositionCard` | shows the historical avg cost, not "Rs 0" |

Existing `dashboard_position_parity_test.dart` should get **stronger**, not weaker, once Task 3 groups
by ticker — the position-based summaries then group the same way the lot-based ones always have. If a
test needs loosening to pass, stop: that means an aggregate moved that shouldn't have.

## Acceptance criteria

- [ ] `flutter analyze` — 0 errors
- [ ] `flutter test` — fully green, Phase 00 characterisation test unchanged
- [ ] A fully-sold position is badged **CLOSED**, a partially-sold one **PARTIAL** — on the card, in
      the sell sheets, and in the position picker
- [ ] STPL with a closed cycle + a new open cycle: **two cards** on Stock Detail, the old one badged
      CLOSED with its own profit and its own sale history
- [ ] Transactions default view shows open **and** partial, never closed
- [ ] A closed card never displays "Rs 0" as its cost basis
- [ ] Dashboard lists each ticker once, and drops tickers with nothing held — while total realized P/L
      and portfolio value are unchanged by that

## Out of scope

Live prices, alerts. Any change to how positions are *split* (that logic is correct). Any change to
`PortfolioSummary`'s figures. Deleting `lots`.

---

## Implementation notes (2026-09-04)

All tasks done in one pass. `flutter analyze` — 0 errors, 22 warnings (all pre-existing baseline; one
fewer than before, `_lotStatusFor` became unused once the aggregate status is built directly).
`flutter test` — **120/120 passing**, up from 102.

Two things found while implementing that weren't in the plan:

1. **The target-price line rendered `Infinity% Est.` on a closed card.** It computes
   `(target - avgCost) / avgCost`, and `avgCost` is 0 once nothing is held. Now hidden entirely for a
   closed cycle — a sell target on a position you no longer hold is meaningless anyway, and this is the
   same stale-`targetPrice`-on-a-closed-position quirk AGENTS.md §14 already warned about.
2. **`_lotStatusFor` is gone.** Task 3's grouping derives the ticker's aggregate status directly
   (nothing held → closed; any sales → partial; else open) rather than mapping a single position's
   status, so the `PositionStatus → LotStatus` mapper had no callers left.

The `dashboard_position_parity_test.dart` suite needed **no** loosening — grouping by ticker made the
position-based summaries group the same way the lot-based reference always has, so parity got stronger,
exactly as this brief predicted.

**Deferred, by agreement:** the Edit Buy sheet's editable ticker field (Task 6's second half). It can
still move a position onto a ticker that already has an open position and break the
one-open-position-per-ticker invariant. Untouched for now; to be discussed.

---

## Task 7 — A closed cycle shows one card per buy (added 2026-09-04, after review)

Fixing the badge and the Rs 0 figures wasn't enough: a closed cycle still rendered as a *single* card
listing every buy and every sale together. Confirmed with the user — closed history should read the way
it did before positions existed, **one card per purchase**, while what's still held stays pooled into
the single averaged card that the merge feature exists to provide.

`PositionCalculator.splitByBuy(Position)` does the work. For a **closed** position with more than one
buy it returns one display position per buy, oldest first, with sales attributed FIFO — a sale that
covered several buys is divided across their cards, carrying its original `costBasisAtSale` into each
slice so realized P/L still totals exactly what the merged card showed. Open and partial positions, and
closed ones with a single buy, come back untouched.

The returned positions are **display-only**: synthetic ids (`<positionId>::<buyId>`) and sales that may
be partial slices of a real sale. `PositionCard` therefore gained one optional parameter,
`writePosition` — the real document that delete and edit-buy must target — and puts its sale rows into
read-only mode whenever it's rendering a slice (`PositionSaleRow.readOnly`), since editing half of a
real sale would write back nonsense. The delete confirmation also states that it removes the whole
cycle, not just the buy on the card. `stock_detail_screen` and `transactions_screen` both expand
through `splitByBuy` and pass the real position along.

The user's reported STPL cycle now renders as the three cards it should: 1,200 @ 8.40 (+780),
650 @ 8.41 (+286), 1,800 @ 8.59 (+1,944) — summing to the same +3,010 the merged card showed.

**Not split:** partial positions. A partially-sold position keeps its buys pooled, because that pooling
*is* the averaging feature. Only fully-closed cycles break apart.

---

## Task 8 — Delete-sale didn't restore status (found in manual testing, 2026-09-04)

`PositionSaleRow._confirmDelete` wrote the shrunken `sales` list without recomputing `status`. Deleting
a position's only sale left it stamped `partiallySold` forever, even once nothing was sold and every
share was held again — the same class of bug as Task 6 (edit-buy), just on the delete-sale path, which
Task 6 didn't cover. `EditSaleBottomSheet` already restamped `status` correctly but left `closedAt`
stale on the same kind of transition; fixed there too for consistency, even though nothing currently
reads a stale `closedAt` once `status` isn't `closed` (`holdingDays` checks status first).

Added a widget-level regression test (`position_sale_row_test.dart`, fake `PositionRepository`) that
drives the real slidable delete flow end-to-end and asserts the repository receives `status: open` —
a pure `computeStatus` unit test wouldn't have caught this class of bug, since the defect was the widget
never calling it, not the function itself being wrong.

## Task 9 — Stock Detail: add Total Invested to the summary row (requested 2026-09-04)

The header stat block showed Shares / Avg Price / Total P/L. Added **Total Invested**
(`StockSummary.amountInvestedOpen`) alongside them. Laid out as two rows of two — Shares/Avg Price,
then Total Invested/Total P/L — rather than cramming four columns into one row, since currency strings
at that width risk overflow on narrower phones.

## Stop and ask if

- Grouping per ticker changes any `PortfolioSummary` money figure — it must not; if it does, the
  aggregation is wrong, not the reference.
- A ticker turns out to have more than one *non-closed* position. That should be impossible
  (`findOpenPosition` + `applyBuy` guarantee at most one), and would mean a data bug worth reporting
  rather than papering over in the UI.
