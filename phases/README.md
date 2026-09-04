# Phase briefs — how this works

Each file in this folder is a **self-contained work order for one phase**, written to be handed to a
fresh coding agent that has never seen this repo.

## The cycle

```
1. Claude writes phases/PHASE-NN-*.md          ← work order
2. Coding agent implements it                  ← writes the code
3. Moazzam reviews manually                    ← your check
4. Claude runs the tests                       ← flutter analyze + flutter test
5. Claude reviews the code and fixes if needed ← correctness pass
6. Phase marked Done → next brief written
```

All briefs are now written. **Briefs 03A onward were authored before their dependencies landed** —
re-read the relevant source files before starting one, and tell me if reality has drifted from what
the brief describes. Each has a "stop and ask" section for exactly that.

## Status

| Phase | Brief | Depends on | Status |
|---|---|---|---|
| 00 — Safety net | [PHASE-00-safety-net.md](PHASE-00-safety-net.md) | — | **Done** — reviewed, 3 bugs fixed, committed (`b24e78c`) |
| 01 — Starting-capital input | [PHASE-01-capital-input.md](PHASE-01-capital-input.md) | — | **Done** — reviewed clean, committed (`9f3ec26`) |
| 02 — Complete white theme | [PHASE-02-white-theme.md](PHASE-02-white-theme.md) | — | **Done** — reviewed, fixed, committed (`808b811`, `3f3db52`) |
| 03A — Position model + migration engine | [PHASE-03A-position-model.md](PHASE-03A-position-model.md) | 00 | **Done** — original commit `08b9450`; review found and fixed a real rounding bug, a missing import, 2 gaps in migration validation, and 10 missing required tests — fix commit `0aaecb0` |
| 03B — Position UI + run migration | [PHASE-03B-position-ui.md](PHASE-03B-position-ui.md) | 03A | **Done** — all 5 tasks built, reviewed, fixed (including a real profit-calc bug and an app-wide compile break), committed (`51be44b`, together with 03A's fixes and all of 03C) — see brief's "Review notes, part 2" |
| 03C — Position cycles in the UI | [PHASE-03C-position-cycles-ui.md](PHASE-03C-position-cycles-ui.md) | 03B | **Done** — closed cycles split into one card per buy; fixed `StatusBadge` silently labelling every position OPEN, and a delete-sale path that left status stuck on PARTIAL. 126/126 tests, committed (`51be44b`) |
| 04 — Live PSX prices | [PHASE-04-live-prices.md](PHASE-04-live-prices.md) | 03C | **Done** — reviewed, fixed 5 compile errors, a missing Firestore rule (would have denied all reads), a dropped Task 4 requirement (unrealized P/L on Stock Detail), and 7 of 11 missing required tests. 152/152 tests, uncommitted, awaiting manual check — see brief's "Review notes" |
| 04B — Price freshness + market clock | [PHASE-04B-price-freshness-and-market-clock.md](PHASE-04B-price-freshness-and-market-clock.md) | 04, 08's new Task 6 | **Done** — reviewed, fixed a compile error, a missing Firestore rule, and 7 of 10 missing required tests. 168/168 tests, uncommitted, awaiting manual check — needs a hand-seeded `market_prices` doc **and** the updated `firestore.rules` actually deployed to the live project (`firebase deploy --only firestore:rules`) before anything will show in the app |
| 05 — Push notification infra | [PHASE-05-push-infra.md](PHASE-05-push-infra.md) | — | Ready — can run in parallel |
| 06 — Sell-target alert fields | [PHASE-06-sell-alerts.md](PHASE-06-sell-alerts.md) | 03B, 04, 05 | Ready — `targetPrice` write-path audit list updated 2026-09-04 for the current controllers |
| 07 — Buy alerts + Alerts screen | [PHASE-07-buy-alerts.md](PHASE-07-buy-alerts.md) | 05 | Ready |
| 08 — Backend on GitHub Actions | [PHASE-08-backend.md](PHASE-08-backend.md) | 04, 06, 07 | Ready — fixed a real bug 2026-09-04: the held-tickers query filtered `status == "open"`, which would have silently dropped partially-sold positions from both price-fetching and sell alerts. Gained Task 6 2026-09-05: scrape PSX's own live Market Status indicator, write `market_status/current` — this is what 04B's dashboard clock reads |

### Why 03 became 03A + 03B

Phase 03 as originally scoped was ~1500 lines across ~15 files, and it is the one phase that rewrites
real money history. Split so each half is reviewable: **03A builds the engine and proves it with
tests, never touching real data; 03B wires the UI and runs the migration once.** Both land on the
same branch before anything ships.

### Suggested order

`02` (in progress) → `03A` → `03B` → then `04` and `05` in either order (05 has no dependencies and
can run in parallel with anything) → `06` and `07` → `08` last, since it is written against the
Firestore schemas the earlier phases define.

Full reasoning behind the phasing lives in [../IMPLEMENTATION_PLAN.md](../IMPLEMENTATION_PLAN.md).

---

## Rules for every coding agent

These apply to **every** brief in this folder. A brief may add rules; it never removes these.

### Before starting

1. **Read [../AGENTS.md](../AGENTS.md) first.** It is the codebase map — architecture, data model,
   conventions, and eleven known traps. It will save you from re-reading the whole repo.
2. Work on the branch the brief names. Never commit to `main`.
3. Run `flutter pub get` if `pubspec.yaml` changed since your last run.

### While working

4. **Stay inside the brief's scope.** If you find an unrelated bug, write it in your report — do not
   fix it. Out-of-scope changes make review impossible.
5. **Do not "fix the analyzer."** The repo has ~739 pre-existing lint infos and 26 warnings. They are
   deliberate noise. Only care that *your* change introduces no new **errors**.
6. **Match the surrounding file's style** — its import convention, its `isDark` branching, its comment
   density. Consistency with the file beats consistency with your preferences.
7. **Never reformat a file you didn't otherwise need to change.** No blanket `dart format` runs.
8. If a required decision is genuinely ambiguous, **stop and ask** rather than guessing. A wrong guess
   in money math is worse than a delay.

### Before declaring done

9. Run both, and paste the real output into your report:
   ```
   flutter analyze
   flutter test
   ```
10. `flutter test` must be **fully green**. `flutter analyze` must show **0 errors** (warnings/infos
    may remain at or below the baseline in AGENTS.md §2).
11. Every brief lists required tests. All of them must exist and pass. Tests that assert nothing, or
    that were weakened to make them pass, count as failure.

### Your report back

End with:

- **Files changed** — path + one line on what changed in each
- **Tests added** — names, and what each actually proves
- **Commands run** — verbatim output of `flutter analyze` and `flutter test`
- **Deviations** — anything you did differently from the brief, and why
- **Found but not fixed** — out-of-scope issues you noticed

### Hard stops

Do not, in any phase, without explicit instruction:

- delete or overwrite user data in Firestore
- change `PortfolioCalculator`'s withdrawal semantics (documented in AGENTS.md §5, has dedicated tests)
- fold live prices into the existing "Total Portfolio Value" metric
- push, force-push, or open a PR
