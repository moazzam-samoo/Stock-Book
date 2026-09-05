# Phase 01 — Responsive starting-capital input

> Read [../AGENTS.md](../AGENTS.md) and [README.md](README.md) before starting. The universal agent
> rules in README.md apply in full.

**Depends on:** nothing · **Estimated:** ~2 hours · **Branch:** `feat/positions-and-alerts`

Small, self-contained, and shippable on its own. Touches exactly one file.

---

## The bug

`lib/presentation/settings/screens/settings_screen.dart`

The Starting Capital field lives in a **fixed-width box** at
[line 241](../lib/presentation/settings/screens/settings_screen.dart#L241):

```dart
Container(
  width: 140,   // ← the problem
  height: 48,
  child: Row(children: [
    Text('Rs'),                    // ~24px
    Expanded(child: _StartingCapitalInput(...)),
  ]),
)
```

`_StartingCapitalInput` (class at line 731) is itself a `Row` of `[TextField, IconButton]`, and the
save `IconButton` **only appears once the field is dirty** (`_isDirty`). So:

- idle: 140px holds `Rs` + text — fine for small numbers
- while typing: 140px must hold `Rs` + text + a ~48px icon button → roughly 68px left for the number

Anything past about six digits is clipped or unreadably squeezed. A realistic PKR capital
(`10,000,000`) does not fit.

### Second, quieter bug

`_save()` at line 766:

```dart
final parsed = double.tryParse(_controller.text) ?? 0.0;
if (parsed >= 0) { ...save... }
```

Unparseable input becomes `0.0`, which passes `>= 0` and **silently saves zero** — wiping the user's
starting capital. Actually-negative input falls through and does nothing at all, with no feedback.
Both need fixing.

---

## What to build

### 1. Responsive layout

Replace the fixed `width: 140` with a flexible box:

- `ConstrainedBox(minWidth: 120, maxWidth: 220)` inside a `Flexible`
- The `Text('Starting Capital')` label column already sits in `Expanded` — make sure it is the side
  that yields first when space is tight
- Wrap the row in a `LayoutBuilder`: **below 360dp**, stack instead — label and subtitle on one line,
  the input row full-width beneath it
- The save button must never eat the field's width. Either reserve its space permanently
  (`SizedBox(width: 40)` occupied by the button or an equal-sized empty box) so the field width does
  not jump when `_isDirty` flips, or move the button outside the constrained box

Field width must not visibly change the moment the user starts typing — that jump is itself a bug.

### 2. Thousands separators while typing

- `10000000` should display as `10,000,000` as it is typed
- Implement with a `TextInputFormatter` + `intl`'s `NumberFormat('#,##0')` — `intl` is already a dependency
- **Strip separators before parsing.** `double.tryParse('10,000,000')` returns `null`
- Keep the cursor in a sensible place after reformatting — a naive formatter jumps the caret to the
  end on every keystroke, which makes mid-number edits impossible. Test this by hand
- Also update `initState` (line ~749) and `didUpdateWidget` (line ~753), which currently do
  `startingCapital.toInt().toString()` — they must produce the formatted string too

### 3. Fix `_save()`

```dart
final raw = _controller.text.replaceAll(',', '').trim();
final parsed = double.tryParse(raw);
if (parsed == null || parsed < 0) {
  // show an inline error or red-bordered field — do NOT save, do NOT save 0
  return;
}
```

- Never silently save `0.0` for unparseable input
- Give the user visible feedback on rejection. Prefer an inline error under the field over a snackbar,
  since the field is small and the error is about the field
- Keep the existing green success snackbar for the success path

### 4. Length cap

Cap at 12 digits (excluding separators) via `LengthLimitingTextInputFormatter` on the raw value.
A trillion-rupee portfolio is not the target user.

---

## Constraints

- **One file only:** `lib/presentation/settings/screens/settings_screen.dart`
- **No new dependencies.** `intl` and `flutter/services` cover all of this
- Keep both themes working — the file branches on `isDark` throughout; match that pattern
- Do not change what gets persisted: still a plain `double` in `UserSettings.startingCapital`
- Do not touch the Currency dropdown below it, beyond what layout changes require

---

## Required tests

New file: `test/presentation/settings/starting_capital_input_test.dart`

| # | Test | Asserts |
|---|---|---|
| 1 | Renders at 320dp with `999999999999` | No `RenderFlex` overflow; `tester.takeException()` is null |
| 2 | Renders at 360dp and 480dp with the same value | No overflow at either |
| 3 | Type `10000000` | Field displays `10,000,000` |
| 4 | Type `10000000` then save | `updateStartingCapital` called with `10000000.0` |
| 5 | Type `abc` then save | `updateStartingCapital` **not** called; error visible |
| 6 | Type `-5` then save | `updateStartingCapital` **not** called; error visible |
| 7 | Field width before vs. after first keystroke | Width unchanged (no jump when save button appears) |
| 8 | 13th digit | Rejected by the length cap |

Tests 5 and 6 are the regression guards for the silent-zero-save bug — they matter most.

For overflow tests, pump inside a sized container:

```dart
await tester.binding.setSurfaceSize(const Size(320, 800));
```

and reset it in `tearDown`. Mock or override the settings providers rather than hitting Firebase.

---

## Acceptance criteria

- [ ] `flutter analyze` — 0 errors
- [ ] `flutter test` — fully green, all 8 new tests included
- [ ] A 12-digit capital is fully visible and editable at 320dp
- [ ] Field width does not jump when the save button appears
- [ ] `10000000` shows as `10,000,000` and saves as `10000000.0`
- [ ] Invalid input never saves and never silently writes `0`
- [ ] Caret behaves sanely when editing mid-number (verify by hand, report what you saw)
- [ ] Both light and dark themes still correct

## Out of scope

The Currency dropdown's own layout, any other Settings section, the Phase 02 theme work,
changing how starting capital is stored or used in `PortfolioCalculator`.
