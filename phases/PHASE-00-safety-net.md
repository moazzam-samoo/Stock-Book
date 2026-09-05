# Phase 00 — Safety net

> Read [../AGENTS.md](../AGENTS.md) and [README.md](README.md) before starting. The universal agent
> rules in README.md apply in full.

**Depends on:** nothing · **Estimated:** half a day · **Branch:** `feat/positions-and-alerts`

## Why this phase exists

Phase 03 rewrites live financial data — it merges same-ticker lots into positions with a new cost
basis. Before anything touches that data, we need two guarantees:

1. **A way to prove the numbers didn't change.** Migration must be arithmetically invisible: same
   portfolio value, same realized P/L, same everything. That's only provable against a recorded baseline.
2. **A way back.** A JSON export the user can keep off-device.

This phase produces both. It changes no existing behaviour.

---

## Task 1 — Characterisation tests

**File:** `test/domain/calculator/portfolio_calculator_characterisation_test.dart` (new)

Build one realistic fixture and assert **every** field of the resulting `PortfolioSummary`. This is the
baseline Phase 03 must reproduce exactly.

### The fixture

Hard-code this. Do not randomise, do not use `DateTime.now()` — the fixture must be byte-stable across
runs and machines.

- **Starting capital:** `500000.0`
- **Three tickers, eight lots, twelve sales.** Include all of:
  - a ticker with **two lots at different prices** (this is what Phase 03 will merge) — use STPL:
    500 @ 8.73 on 2026-08-31, and 1200 @ 8.38 on 2026-09-07
  - a lot that is fully sold (`LotStatus.closed`)
  - a lot that is partially sold (`LotStatus.partiallySold`)
  - a lot with no sales at all (`LotStatus.open`)
  - at least one **loss-making** sale (sell price below buy price)
  - a lot with a non-null `targetPrice`, and one with `targetPrice: null`
- **Two withdrawals**, e.g. `15000.0` and `7500.0`

### What to assert

Assert every field individually with the literal expected value — not a recomputation:

```
startingCapital · totalInvested · currentlyInvested · realizedPL · grossRealizedPL
totalWithdrawn  · freeCash      · totalCash         · openLots   · portfolioValue
```

Compute the expected numbers **by hand** (or from a one-off print) and paste them in as literals.
A test that recomputes the value using the same code it is testing proves nothing.

Also assert:

- `calculateStockSummaries` — length, and for each ticker: `sharesHeld`, `amountInvestedOpen`,
  `realizedPL`, `avgBuyPrice`, `status`, `allocationPercent`
- `calculateAllocation` — segments, and that percentages sum to ~100 (within 0.05 for rounding)
- per-lot `enrichLot` output for the STPL lots specifically, since those are the ones Phase 03 merges

Use `closeTo(expected, 0.01)` for doubles. Exact `equals` on doubles will flake.

### Header comment

Put this at the top of the file, verbatim:

```dart
// CHARACTERISATION TEST — DO NOT "FIX" THESE NUMBERS.
//
// This file records what PortfolioCalculator produced BEFORE the Phase 03
// position-merge migration. Phase 03 must reproduce every value here exactly.
//
// If a change makes this file fail, the change altered user-visible financial
// figures. That is the signal this test exists to raise. Investigate the change
// — do not update the expected values to match new output.
```

---

## Task 2 — Backup export

Give the user a JSON dump of everything, so migration is recoverable.

**New file:** `lib/core/services/data_export_service.dart`

```dart
static Future<String> buildExportJson({
  required List<Lot> lots,
  required List<Withdrawal> withdrawals,
  required UserSettings settings,
})
```

Returns pretty-printed JSON:

```json
{
  "schemaVersion": 1,
  "exportedAt": "2026-09-03T12:00:00.000Z",
  "appVersion": "1.0.0+1",
  "lots": [ { "id": "...", "ticker": "STPL", "buyDate": "ISO-8601",
              "sharesPurchased": 500, "buyPricePerShare": 8.73,
              "targetPrice": null,
              "sales": [ { "id": "...", "sellDate": "ISO-8601",
                           "sharesSold": 200, "sellPricePerShare": 9.0 } ] } ],
  "withdrawals": [ { "id": "...", "date": "ISO-8601", "amount": 15000.0, "note": "" } ],
  "settings": { "startingCapital": 500000.0, "currency": "PKR",
                "themeMode": "dark", "favorites": [], "stockColors": {} }
}
```

**Dates as ISO-8601 strings, not Firestore `Timestamp`** — the file must be readable without Firebase.

### UI

Add an "Export data (JSON)" row to **Settings → ACCOUNT**
(`lib/presentation/settings/screens/settings_screen.dart`, `_buildAccountSection`).

- Match the existing row styling in that section exactly — do not invent a new visual language.
- Read from `allLotsProvider`, `allWithdrawalsProvider`, `settingsProvider`.
- Share via the `printing` package's share sheet (`Printing.sharePdf` has a bytes-sharing sibling) or
  add `share_plus`. **If you add a dependency, say so prominently in your report.**
- Filename: `stock-book-backup-YYYY-MM-DD.json`
- Follow the app's offline snackbar convention (AGENTS.md §8): green on success, and a clear error
  message on failure. Never fail silently.

---

## Task 3 — Branch

```
git checkout -b feat/positions-and-alerts
```

All phases land here. Do not merge to `main`.

---

## Required tests

| Test | Proves |
|---|---|
| `portfolio_calculator_characterisation_test.dart` — full summary | Baseline locked for Phase 03 |
| ” — stock summaries per ticker | Per-ticker aggregation locked |
| ” — allocation segments | Allocation locked |
| `data_export_service_test.dart` — round-trip | Export parses back to identical values |
| ” — empty portfolio | No crash, valid JSON with empty arrays |
| ” — null `targetPrice` | Serialises as `null`, not `0` or omitted |
| ” — dates are ISO-8601 strings | Readable without Firebase |

---

## Acceptance criteria

- [ ] `flutter test` fully green; new tests included in the count
- [ ] `flutter analyze` reports 0 errors
- [ ] Characterisation test fails loudly if any `PortfolioCalculator` output changes
      (verify by temporarily perturbing a constant, confirming red, then reverting)
- [ ] Export produces valid JSON that parses back to identical values
- [ ] Export button visible in Settings → ACCOUNT and works on a real device/emulator
- [ ] No existing behaviour changed

## Out of scope

Import/restore (export only), any Phase 03 work, any UI beyond the single export row, touching
`PortfolioCalculator` logic itself.

## Note on the verification step

The "perturb a constant, confirm red, revert" check in the acceptance criteria is the only thing that
proves the characterisation test actually bites. Please actually do it and report what you saw — a
characterisation test that passes unconditionally is worse than none, because Phase 03 will trust it.
