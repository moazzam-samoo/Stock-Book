# Phase 06 — Sell-target alert fields

> Read [../AGENTS.md](../AGENTS.md) and [README.md](README.md) before starting. The universal agent
> rules in README.md apply in full.

**Depends on:** Phases 03B, 04, 05 · **Estimated:** 1 day · **Branch:** `feat/positions-and-alerts`

Small phase. It adds the client-side state that stops a sell alert firing over and over. The backend
that reads these fields and actually sends the push is Phase 08.

---

## Background

A `Position` already carries `targetPrice` (moved there from `Lot` in Phase 03A). When the live price
reaches it, the user should get **one** notification — not one every 15 minutes for the rest of the
day. That requires a persisted "already told you" flag, and a rule for when to re-arm it.

---

## Task 1 — Fields

`Position` entity and `PositionModel` gain:

- `targetAlertSent` — `bool`, default `false`
- `targetAlertSentAt` — `DateTime?`, default `null`

Follow the existing freezed/equatable patterns. Run `build_runner` and commit generated files.

---

## Task 2 — The re-arm rule

**Any write that sets, changes, or clears `targetPrice` must reset `targetAlertSent` to `false` in
the same write.**

Same write, not a follow-up write. A separate write can fail independently and leave a position with
a new target that can never fire.

Audit **every** path that can touch `targetPrice`. As of Phase 03C, that's at least:

- `AddBuyBottomSheet` / `AddBuyController` — sets it when creating a new position, or carries the
  existing target forward when appending a buy to an already-open one (`copyWith(targetPrice: ...)`)
- `EditBuyBottomSheet` — the field is directly editable there
- `PositionMigration` (03A) — sets it once, at migration time; not a live app write path, but confirm
  it isn't somehow re-run against an already-migrated account
- Any other position write you find via `grep -rn targetPrice lib/` — the list above is what existed
  when this brief was last checked (2026-09-04); re-run the grep, don't trust this list blindly

**Also decide:** should a sell alert be able to fire at all on a `partiallySold` position, or only
`open`? (AGENTS.md documents a known quirk: `PositionMigration` can leave a stale `targetPrice` on a
position, and `historicalAvgCost`/`PositionCard` already treat `closed` specially — `targetPrice` is
never shown on a closed card.) This phase doesn't decide firing logic — that's Phase 08 — but if the
UI is going to show "alert sent" (Task 3) on a partial position, make sure that's a state you intend.

Grep for `targetPrice` across `lib/` and check each hit. Missing one produces a target that silently
never alerts — a failure the user cannot see and would only notice by missing a sale.

**Best approach:** put the reset inside the repository or a single `updateTargetPrice()` method so
callers cannot forget it, rather than repeating the rule at each call site. If you do that, say so —
it changes where the test should point.

**Do not reset on unrelated edits.** Changing share count or buy date must *not* re-arm an alert that
already fired; only a `targetPrice` change does.

---

## Task 3 — Optional UI touch

If cheap, show a small "alert sent" indicator on a position whose `targetAlertSent` is true, so the
user understands why no further notifications arrive. Keep it subtle. Skip it if it costs more than
an hour and say so.

---

## Required tests

| # | Test | Asserts |
|---|---|---|
| 1 | Set a target on a position with `targetAlertSent: true` | flag resets to `false` **in the same write** |
| 2 | Change an existing target | flag resets |
| 3 | Clear the target (set null) | flag resets |
| 4 | Edit shares/date only | flag **unchanged** |
| 5 | Add a buy that sets a target | flag `false` from the start |
| 6 | Model round-trip | both new fields serialise, `null` timestamp survives |
| 7 | Defaults on an existing doc without the fields | `false` / `null`, no crash reading pre-Phase-06 data |

Test 7 matters: positions written by Phase 03B's migration won't have these fields, and the model
must tolerate their absence.

---

## Acceptance criteria

- [ ] `flutter analyze` — 0 errors; `flutter test` fully green
- [ ] Every `targetPrice` write path resets the flag — **list them in your report** so I can verify
      the audit was complete rather than take it on trust
- [ ] Positions written before this phase still read correctly

## Out of scope

Sending notifications (08). Buy alerts (07). Changing how `targetPrice` is entered or displayed
beyond the optional indicator.
