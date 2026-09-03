# Phase 02 — Complete white theme + toggle

> Read [../AGENTS.md](../AGENTS.md) and [README.md](README.md) before starting. The universal agent
> rules in README.md apply in full.

**Depends on:** nothing · **Estimated:** 2–3 days · **Branch:** `feat/positions-and-alerts`

Dark stays the default. This phase makes light mode actually usable and adds the switch.

---

## Current state

The plumbing is already complete and working:

```
UserSettings.themeMode → Firestore → settingsProvider
  → main.dart _themeModeFrom() → MaterialApp.themeMode
```

`AppTheme.lightTheme` exists. 19 of 57 presentation files already branch on
`Theme.of(context).brightness == Brightness.dark`.

Two things are missing: **~40% of the UI has no light styling**, and **nothing calls
`SettingsController.updateThemeMode`** so the user can't switch.

---

## Task 1 — Fix `AppTypography` first (highest leverage, do this before anything else)

`lib/core/theme/app_typography.dart` hardcodes colours into its static styles:

```dart
static TextStyle h1 = GoogleFonts.outfit(..., color: Colors.white);   // ← always white
static TextStyle body = GoogleFonts.inter(fontSize: 14, color: Colors.white);
```

There are **106 `AppTypography.*` usages across the app and only 11 override the colour.** The other
~95 render white text in light mode. This one file is most of the bug.

**Approach — pick one and apply it consistently:**

- **Preferred:** strip `color:` from the static styles entirely and let `ThemeData.textTheme` (already
  defined for both themes further down the same file) supply it. Widgets that need a specific colour
  already use `.copyWith(color:)`.
- **Alternative** if the above causes too much churn: add `AppTypography.of(context)` returning a
  brightness-aware set, and migrate usages to it.

Do this first, then rebuild and screenshot both themes. Many of the files listed below may already
look correct afterwards — **re-check before editing them**, and say in your report which ones the
typography fix resolved on its own.

`caption` uses `Color(0xFF718096)` — a mid grey that is legible on both grounds. It can stay, but
verify contrast in light mode.

---

## Task 2 — Files with hardcoded colours and no brightness branch

Verified list. Counts are hardcoded colour literals per file.

| File | Count | Notes |
|---|---|---|
| `common/animated_pdf_button.dart` | 10 | |
| `dashboard/widgets/dashboard_skeleton.dart` | 11 | Shimmer base/highlight need light variants or it flashes dark |
| `auth/screens/sign_in_screen.dart` | 5 | |
| `common/ticker_avatar.dart` | 3 | Already luminance-aware; only the shadow needs tuning |
| `dashboard/screens/dashboard_screen.dart` | 3 | |
| `transactions/widgets/ticker_autocomplete.dart` | 2 | |
| `common/offline_banner.dart` | 2 | Yellow-on-black is intentional — verify, probably leave |
| `splash/screens/splash_screen.dart` | 2 | Brand moment; may stay dark deliberately — your call, but say which |
| `transactions/widgets/filter_chip_row.dart` | 1 | |
| `transactions/widgets/transaction_search_bar.dart` | 1 | |
| `onboarding/widgets/onboarding_line_chart.dart` | 1 | |
| `routing/app_router.dart` | 1 | **See Task 3** |

Use the pattern already established in the codebase — see
`transactions/widgets/add_buy_bottom_sheet.dart` for a clean example:

```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
final cardBg      = isDark ? const Color(0xFF13151B) : Colors.white;
final borderColor = isDark ? const Color(0xFF242731) : const Color(0xFFE2E8F0);
final primaryText = isDark ? Colors.white : AppColors.textPrimaryLight;
```

Those four literals are the app's de facto light/dark pairs. Reuse them; don't invent new ones.

---

## Task 3 — The shell background (easy to miss, very visible)

`lib/presentation/routing/app_router.dart`, inside `StatefulShellRoute`:

```dart
child: Scaffold(
  extendBody: true,
  backgroundColor: const Color(0xFF13151B),   // ← hardcoded dark
  ...
)
```

Every tab renders inside this. Left as-is, **the entire app keeps a dark frame in light mode** no
matter how well the individual screens are styled. Make it theme-driven.

Check `AppBottomNavBar` (the floating pill) in the same pass — it sits on this background.

---

## Task 4 — Bottom sheets that force a dark backdrop

Some `static show()` methods hardcode the sheet background:

- `transactions/widgets/add_transaction_bottom_sheet.dart` → `backgroundColor: AppColors.backgroundDark`
- `transactions/widgets/select_lot_bottom_sheet.dart` → same

`add_buy_bottom_sheet.dart` already does this correctly:

```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
backgroundColor: isDark ? const Color(0xFF13151B) : Colors.white,
```

Bring the others in line. **Audit every `showModalBottomSheet` and `showDialog` call in the app** —
these are easy to miss because they only appear on interaction, so they won't show up in a static
screenshot pass.

---

## Task 5 — Dark-only colour aliases used directly

`AppColors.textPrimaryDark`, `backgroundDark` and `surfaceDark` are dark-mode values being used as if
they were neutral. Verified usages:

```
metric_detail_card.dart (8)   dashboard_screen.dart (4)
empty_state_view.dart (2)     add_transaction_bottom_sheet.dart (2)
select_lot_bottom_sheet.dart (2)
stock_detail_screen.dart, portfolio_header.dart, stat_card.dart,
filter_chip_row.dart, ticker_autocomplete.dart, transaction_search_bar.dart (1 each)
```

Route each through `Theme.of(context)` or the existing `AppSemanticColors` ThemeExtension
(`AppColors` also defines `AppSemanticColors.light` / `.dark` — use them).

---

## Task 6 — The toggle

Add a **Theme** row to Settings → PORTFOLIO, directly below Currency
(`settings_screen.dart`, `_buildPortfolioPreferences`).

- Three options: **Dark** / **Light** / **System**
- Match the Currency row's existing `DropdownButton` styling exactly — same container, same padding,
  same icon. Do not introduce a new control style
- Wire to `ref.read(settingsControllerProvider.notifier).updateThemeMode(value)`
- Values must be exactly `'dark'`, `'light'`, `'system'` — `main.dart`'s `_themeModeFrom()` already
  maps these three strings and falls back to dark for anything else
- Setting persists to Firestore and syncs across devices automatically via the existing chain

---

## Required tests

### Golden tests — the main deliverable

`golden_toolkit` is already a dev dependency and currently unused. This is the only practical guard
against light-mode regressions.

`test/golden/theme_golden_test.dart`, **10 goldens** — five screens × two themes:

| Screen | Why it's on the list |
|---|---|
| Dashboard | Stat cards, donut, stock rows — densest colour surface |
| Transactions (populated) | Position/lot cards, filter chips, search |
| Lot card expanded | The most complex single widget, 657 lines |
| Settings | Every row style in the app, plus the new toggle |
| Stock detail | The one screen outside the shell |

Use fixed fake data (no `DateTime.now()`, no random colours) or goldens will flake. Ticker colours are
hash-derived and stable — good. Commit the generated `.png` files.

### Widget tests

| Test | Asserts |
|---|---|
| Toggle → Light | `MaterialApp.themeMode == ThemeMode.light` |
| Toggle → System | `ThemeMode.system` |
| Toggle → Dark | `ThemeMode.dark` |
| Toggle persists | `updateThemeMode` called with the exact string |
| Shell background follows theme | Not `0xFF13151B` in light mode |
| Bottom sheets in light mode | `add_transaction` and `select_lot` backdrops are light |

### Contrast check

`test/golden/contrast_test.dart` — walk the widget tree in light mode and assert no `Text` renders
within 5% relative luminance of the surface behind it. Catches white-on-white that a golden might
pass if a human doesn't look closely.

---

## Acceptance criteria

- [ ] `flutter analyze` — 0 errors
- [ ] `flutter test` — fully green including all 10 goldens
- [ ] Every screen **and every bottom sheet and dialog** legible in light mode
- [ ] No dark frame anywhere in light mode (Task 3)
- [ ] Toggle works, persists across app restart, syncs across devices
- [ ] Dark mode is **pixel-unchanged** — verify with the dark goldens; existing users see nothing new
      until they opt in
- [ ] Manual pass on a real device in light mode: dashboard → transactions → expand a card → add buy
      → add sell → settings → stock detail

## Out of scope

Redesigning anything, new colours beyond the established light/dark pairs, the PDF report's colours
(`pdf_report_service.dart` is deliberately always light — it's a printed document), Phase 01's
capital input.

## Reporting note

Please list **which files the Task 1 typography fix resolved on its own**, versus which still needed
individual work. That tells us how much of the remaining app is genuinely theme-coupled — useful
signal for future work.
