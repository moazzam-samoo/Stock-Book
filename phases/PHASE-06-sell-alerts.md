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

- [x] `flutter analyze` — 0 errors; `flutter test` fully green
- [x] Every `targetPrice` write path resets the flag — see "Review notes" below for the full audit list
- [x] Positions written before this phase still read correctly (verified with a new test — see below)

## Out of scope

Sending notifications (08). Buy alerts (07). Changing how `targetPrice` is entered or displayed
beyond the optional indicator.

---

## Review notes (2026-09-05)

### Critical, unrelated to this phase: an accidental Riverpod major-version bump broke the entire app

The working tree (and the commit `4ccd4dc` "feat: Add target alert status fields to Position and UI
indicator") bundled in `flutter_riverpod: ^2.6.1 → ^3.4.3` and `riverpod_annotation: ^2.6.1 → ^4.0.7` —
both **major** bumps with real breaking changes — alongside this phase's actual work, plus
`json_annotation` moving off its exact `4.9.0` pin and `custom_lint`/`riverpod_lint` getting commented
out entirely. None of this was asked for by this brief. Riverpod 3.x removed the `.valueOrNull` getter
used everywhere in this codebase and changed how codegen types the `Ref` parameter of `@riverpod`
functions — the result was **44 compile errors app-wide** (`undefined_getter` on `valueOrNull` in a
dozen+ files, `undefined_class` on every hand-written `XxxRef` parameter type). The app did not compile
at all. Disabling `custom_lint`/`riverpod_lint` alongside this looks like an attempt to silence the
errors that surfaced from the bump rather than fix them.

Fixed by reverting `pubspec.yaml` to the exact dependency versions from the last known-good commit
(`HEAD~1`, Phase 05): `flutter_riverpod: ^2.6.1`, `riverpod_annotation: ^2.6.1`, `json_annotation:
4.9.0` (exact pin restored), `custom_lint`/`riverpod_lint` re-enabled. Restored `pubspec.lock` to that
same commit's exact content (rather than letting the resolver re-derive versions, which briefly
surfaced a second, unrelated problem — see below), then regenerated every `.g.dart`/`.freezed.dart` file
via `dart run build_runner build --delete-conflicting-outputs` so they match Riverpod 2.x's codegen
shape again, while keeping this phase's new `targetAlertSent`/`targetAlertSentAt` fields intact (they
live in the hand-written freezed source, not in anything regenerated away).

**A proper Riverpod 3.x migration is real, valuable work this codebase may want eventually — the
`.valueOrNull` and `Ref`-typing changes are estuary-wide but mechanical — but it is its own deliberate
phase with its own review, not a silent side effect of a 1-day "add two fields" brief.**

### Separate, also unrelated: a corrupted pub cache entry

While first attempting to regenerate code, `dart run build_runner build` failed with `dart_style`
compile errors ("'Expression' isn't a type", "'AstNode' isn't a type", etc.) even after the Riverpod
revert above and with the exact known-good `pubspec.lock` restored. Root cause: the `analyzer-7.6.0`
package in the local pub cache
(`%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\analyzer-7.6.0\`) was missing its entire `lib/` directory —
a corrupted/incomplete cache entry, unrelated to any dependency version. Fixed by deleting that cache
folder and running `flutter pub get` again to force a clean re-fetch. Purely a local-machine issue, not
a project file — nothing in the repo changed for this fix.

### Task 1 — Fields

Done correctly. `targetAlertSent` (`@Default(false) bool`) and `targetAlertSentAt` (`DateTime?`) added
to both `Position` and `PositionModel`, matching the existing freezed/equatable patterns exactly.

### Task 2 — The re-arm rule

Done, and via a stronger mechanism than the brief's own suggestion. Rather than a repository method or
scattered per-call-site resets, the reset lives **inside `Position.copyWith()` itself**: it compares the
resolved new `targetPrice` against the current one and forces `targetAlertSent: false` /
`targetAlertSentAt: null` whenever they differ, regardless of which field parameters the caller passed.
This is stronger than "repository method" — it is impossible to bypass by calling `copyWith` directly
from anywhere, not just through one blessed method. A `clearTargetPrice` bool flag disambiguates "set to
null" from "don't touch."

Verified every write path via `grep -rn targetPrice lib/` (re-run fresh, not trusted from the brief's
2026-09-04 list):
- `AddBuyController.submit` — new position: fresh `Position()`, flag defaults false. Existing position:
  `PositionCalculator.applyBuy(...).copyWith(targetPrice: targetPrice ?? openPosition.targetPrice)` —
  correctly resets when a new target is supplied, correctly does not reset when the old one is just
  carried forward (verified with new tests, see below).
- `EditBuyBottomSheet` — `copyWith(targetPrice: _targetPrice, clearTargetPrice: _targetPrice == null,
  ...)` — correctly handles both "set a new value" and "clear the field" through the new API.
- `PositionMigration` — constructs a brand-new `Position()` (not `copyWith`), so the flag naturally
  starts `false`; confirmed `PositionMigrationRunner.runIfNeeded()` still has its Phase 03A idempotency
  guard (`schemaVersion >= 2` short-circuit) intact, so migration cannot re-run against an
  already-migrated account and re-touch these fields.
- No other write path found.

Decided: a sell alert firing on a `partiallySold` position is left as Phase 08's call (not decided
here, matching the brief) — the UI indicator (Task 3) shows on any position with `targetAlertSent: true`
regardless of status, which is consistent since the flag only means "already notified," not "still
eligible to notify."

### Task 3 — Optional UI touch

Done, cheap and subtle as asked: a small `Icons.notifications_active` bell (14px, the existing money-
green accent color) appended next to the Target line via a `WidgetSpan`, shown only when
`targetAlertSent` is true. `_BulletDetail.valueSpans` widened from `List<TextSpan>?` to
`List<InlineSpan>?` to allow the icon `WidgetSpan` alongside the existing price/percent `TextSpan` —
backward compatible with existing callers.

### Required tests — found 4 of 7 present, added the missing 3 (plus one extra for symmetry)

`test/domain/entities/position_test.dart` (new file) had 3 tests covering required tests 1–3 (set
target with alert already sent → resets; change existing target → resets; clear target → resets — 1
and 2 collapse into the same scenario given the test's base fixture, which is fine, they exercise the
identical code path). `test/data/models/position_model_test.dart` had required test 6's non-null-
timestamp half only.

Missing, now added:
- **Test 4** (edit unrelated fields → flag unchanged): the existing test used a `status` change; added
  an explicit test using a **buys** list change (closer to the brief's literal "shares/date" wording).
- **Test 5** (a buy that also sets a target → flag false from the start): added as an integration-style
  test using the *real* `PositionCalculator.applyBuy(...).copyWith(targetPrice: ...)` chain that
  `AddBuyController` actually uses, not just `Position.copyWith` in isolation — proving the two-step
  chain interacts correctly (the interim `applyBuy` result must not itself reset or block the reset).
  Added a complementary test for the "carries the target forward" case too, confirming it does *not*
  reset.
- **Test 6's missing half**: added a round-trip test with `targetAlertSentAt: null`, confirming the
  null timestamp survives `toJson`/`fromJson` (not omitted, not coerced to something else).
- **Test 7** (defaults on a pre-Phase-06 doc): added, constructing a raw JSON map with `targetPrice` set
  but `targetAlertSent`/`targetAlertSentAt` keys absent entirely (as any position written before this
  phase would be) — confirms `PositionModel.fromJson` defaults to `false`/`null` without crashing.
  Also confirmed by reading the generated `_$PositionModelFromJson`: `targetAlertSent: json[...] as
  bool? ?? false` and the timestamp converter both null-guard correctly on a missing key.

Final state: `flutter analyze` — 0 errors, all remaining items are pre-existing baseline `info`-level
lints. `flutter test` — 188/188 passing (180 baseline + 8 new). No golden images affected.

### A note on git history

This phase's work landed in commit `4ccd4dc` ("feat: Add target alert status fields to Position and UI
indicator"), which — as described above — also contains the broken Riverpod bump. My fixes (the
revert, the regenerated codegen, and the added tests) are **currently uncommitted working-tree changes
on top of that commit**, not yet folded into any commit. You'll want to commit this fix yourself; you
may also want to consider whether to `git commit --amend` that commit to fold the fix in cleanly (since
the bad state was never itself a good checkpoint) versus a separate follow-up commit — your call, not
done here.
