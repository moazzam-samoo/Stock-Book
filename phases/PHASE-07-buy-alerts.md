# Phase 07 — Buy alerts + Alerts screen

> Read [../AGENTS.md](../AGENTS.md) and [README.md](README.md) before starting. The universal agent
> rules in README.md apply in full.

**Depends on:** Phase 05 · **Estimated:** 3 days · **Branch:** `feat/positions-and-alerts`

A watchlist for tickers the user does **not** own: "tell me when GUSM drops to around 8.60."
Deliberately separate from `Position` — there is no holding, no cost basis, nothing a position means.

---

## Task 1 — Data model

```
users/{uid}/price_alerts/{alertId}
{
  "ticker": "GUSM",
  "targetPrice": 8.60,
  "tolerancePercent": 1.0,
  "isActive": true,
  "alertSent": false,
  "alertSentAt": null,
  "createdAt": <Timestamp>
}
```

**Trigger condition** (Phase 08 implements it; define it here so both sides agree):

```
currentPrice <= targetPrice × (1 + tolerancePercent / 100)
```

Tolerance is what makes it "at or near" rather than an exact match. At `targetPrice: 8.60` and
`tolerancePercent: 1.0`, the threshold is `8.686`.

**One-shot for v1:** on firing, `alertSent: true` and `isActive: false`. Re-arming is a later
refinement — do not build it now.

`firestore.rules` — the standard per-user block:

```
match /users/{uid}/price_alerts/{alertId} {
  allow read, write: if request.auth != null && request.auth.uid == uid;
}
```

---

## Task 2 — Entity → model → repository → providers

Mirror the established chain exactly (see AGENTS.md §13):

- `lib/domain/entities/price_alert.dart`
- `lib/data/models/price_alert_model.dart` (`@freezed`; defensive date parsing as always)
- `FirestorePaths.priceAlerts(uid)` / `priceAlert(uid, id)`
- `PriceAlertRepository` + impl — `watchAllAlerts()`, `add`, `update`, `delete`
- `FirestoreDataSource` additions with the `.timeout(4s)` + `catch (_)` idiom
- `priceAlertRepositoryProvider` — nullable, gated on `currentUserIdProvider`
- `lib/presentation/alerts/providers/alerts_providers.dart` — `@riverpod` stream for reads, plus a
  **`@Riverpod(keepAlive: true)`** controller for writes

> The `keepAlive` is not optional. A controller reached only via `ref.read(...notifier)` gets torn
> down mid-write and throws *"Bad state: Future already completed"* on slow connections. This is a
> bug already hit twice in this codebase — see the comments in `withdrawal_provider.dart`.

---

## Task 3 — Alerts screen

`lib/presentation/alerts/screens/alerts_screen.dart`:

- List of alerts: ticker avatar, target price, tolerance, state (active / triggered)
- Swipe actions via `flutter_slidable` (already a dependency) — edit and delete, matching
  `withdrawal_row.dart`'s existing pattern
- Empty state via `EmptyStateView`
- Wrap in `AppScaffold` + `CustomAppBar`, like every other screen
- **Full light/dark support** — Phase 02 will have set the standard; match it, don't regress it

`lib/presentation/alerts/widgets/add_alert_bottom_sheet.dart`:

- Reuse `ticker_autocomplete.dart` — do not rebuild ticker entry
- Target price input, tolerance input defaulting to `1.0`
- Label the tolerance in plain language: *"Notify me at or within X% of this price"* — not
  "tolerance percent". Show the computed threshold live (e.g. "fires at or below Rs 8.69") so the
  setting is concrete rather than abstract
- Follow the app's bottom-sheet idiom exactly: `static show()`, `isScrollControlled: true`, 20–24px
  top radius, 40×4 grab handle
- Offline snackbar convention (AGENTS.md §8): yellow offline / green success

---

## Task 4 — Navigation: this makes it four tabs

Dashboard / Transactions / **Alerts** / Settings.

- Add a `StatefulShellBranch` + route in `app_router.dart`
- Add the item to `app_bottom_nav_bar.dart`

**The nav bar is a floating pill and was designed for three items.** Four labels at 320dp will be
tight. Check it at 320dp and report how it looks. If labels collide, **stop and ask** — options are
shorter labels, icon-only, or moving Alerts elsewhere. Do not silently ship a broken nav bar, and do
not unilaterally redesign it either.

Also verify `SwipeableNavigationShell` (the `PageView` wrapper) still behaves with four branches, and
that the shell `PopScope` still routes back to Dashboard from the new tab.

---

## Required tests

| # | Test | Asserts |
|---|---|---|
| 1 | **Threshold boundary — exactly `target × 1.01`** | fires |
| 2 | **A hair above the threshold** | does not fire |
| 3 | Exactly at target | fires |
| 4 | `tolerancePercent: 0` | exact-or-below only |
| 5 | Repository CRUD round-trip | add/update/delete |
| 6 | One-shot | firing sets `alertSent: true`, `isActive: false` |
| 7 | Model round-trip incl. null `alertSentAt` | serialises correctly |
| 8 | Widget: empty state | `EmptyStateView` shown |
| 9 | Widget: swipe to delete | removes the alert |
| 10 | Widget: add sheet computes threshold | correct live value displayed |
| 11 | Nav: 4 tabs render at 320dp | no overflow |

Tests 1–4 pin the trigger maths. Put that calculation in a **pure, testable function** — Phase 08
reimplements the same rule in Python, and these tests are the reference definition.

---

## Acceptance criteria

- [x] `flutter analyze` — 0 errors; `flutter test` fully green
- [ ] Create, edit, delete an alert end to end on a device — **your turn to verify manually**
- [x] Alerts tab reachable, four-tab nav verified at 320dp (widget test; icon-only design confirmed
      with Moazzam 2026-09-05)
- [ ] Light and dark both correct — **your turn to verify manually**
- [x] Threshold shown to the user matches the tested formula (both now call the same
      `alertThreshold()` function the tests pin)

## Out of scope

Sending the notification (08). Re-arming a fired alert. Sell-target alerts (06). Any change to
positions.

---

## Review notes (2026-09-05)

### Critical: the app did not compile — two hallucinated widget APIs

`add_alert_bottom_sheet.dart` called two widgets with parameters that don't exist:

- `AppNumberInput(...)` — this widget **does not exist anywhere in the codebase**. `inputs.dart` only
  defines `AppTextField` and `NumericInput` (both String-based, not double-based, no `prefix` param).
  Fixed by switching both usages (Target Price, Tolerance) to the existing `NumericInput`, matching the
  exact pattern already used in `add_buy_bottom_sheet.dart` for its own price fields
  (`double.tryParse(val)` in `onChanged`, no `prefix`).
- `TickerAutocomplete(validator: ..., onSaved: ...)` — `TickerAutocomplete` is a bare `ConsumerWidget`,
  not a `FormField`; it has no `validator`/`onSaved` parameters, so it can never participate in the
  wrapping `Form`'s `validate()`/`save()`. Fixed by removing both, and moving the "ticker required"
  check into `_submit()` directly (shown as a SnackBar) since `Form.validate()` cannot cover this field.

Neither of these could have been caught by only reading the brief — they're only visible by checking
what the reused widgets actually expose, which is exactly why "reuse `ticker_autocomplete.dart`" needs
checking its real API, not assuming one.

### Real bug: offline detection could never fire

`connectivity_plus: ^7.3.1`'s `checkConnectivity()` returns `Future<List<ConnectivityResult>>`, not a
single `ConnectivityResult` (this is the same version already used correctly elsewhere in this
codebase, e.g. `connectivity_provider.dart`'s `!results.contains(ConnectivityResult.none)`). The bottom
sheet compared the list directly against `ConnectivityResult.none` — a list is never `==` to an enum
value, so the offline snackbar could never show, and the "success" snackbar would show even while
offline. Fixed by checking `connectivityResult.contains(ConnectivityResult.none)`, matching the
established pattern.

### Firestore rules — missing entirely

`firestore.rules` has no wildcard/recursive rule; every subcollection under `users/{userId}` is
individually declared (`lots`, `positions`, `withdrawals`, `settings`). `price_alerts` was missing, which
would have silently denied all reads/writes in production despite working fine against a local/emulator
setup. Added the standard per-user block, matching every sibling subcollection.

### Task 1 — Data model

Done correctly, including the hand-written defensive `fromJson` (matches `PositionBuyModel`/
`SaleModel`'s established pattern for tolerating both `Timestamp` and ISO-8601 string dates).

### Duplicated trigger formula

`isAlertTriggered` (the required pure, testable reference function) existed correctly in
`alerts_providers.dart`, but the live threshold preview in `add_alert_bottom_sheet.dart` and the display
in `alert_row.dart` each re-derived `targetPrice * (1 + tolerancePercent / 100)` inline instead of calling
it — three copies of the same formula that could silently drift apart. Extracted a shared
`alertThreshold(targetPrice, tolerancePercent)` function that `isAlertTriggered` and both UI call sites
now all use, so there is exactly one place this math lives (the thing Phase 08 mirrors in Python).

### Task 2 — Entity → model → repository → providers

Done correctly. Chain matches AGENTS.md §13 exactly; `priceAlertRepositoryProvider` correctly goes
through `FirestoreDataSource` (not a raw `FirebaseFirestore`, unlike a couple of earlier phases'
repositories); `AlertsController` correctly has `@Riverpod(keepAlive: true)` as the brief demanded.

### Task 3 — Alerts screen

Done well: `AppScaffold`/`CustomAppBar`, `EmptyStateView`, staggered list animation, `flutter_slidable`
edit/delete matching the established pattern, state badge (ACTIVE/TRIGGERED), threshold and
`alertSentAt` both shown. `PopScope` correctly routes back to Dashboard, matching
`transactions_screen.dart`/`settings_screen.dart`'s own pattern.

### Task 4 — Navigation

Router branch and nav bar item added correctly; `SwipeableNavigationShell` and the shell-level `PopScope`
(`canPop: navigationShell.currentIndex == 0`) both generalize to 4 branches with no special-casing
needed, confirmed by reading them.

**However:** the brief explicitly said "if labels collide, **stop and ask**... do not unilaterally
redesign it either." Labels were removed entirely from all 4 tabs (icon-only) without asking — this
technically violates that instruction, even though icon-only was one of the offered options. It also
briefly left the nav bar with **zero accessible labels at all** (no visible text, no `Semantics`, no
`Tooltip`) — a real accessibility regression on top of the process question. Fixed the accessibility
gap by wrapping each `_NavItem` in `Semantics(label: ..., selected: ..., button: true)`. Asked Moazzam
directly whether to keep icon-only or restore labels — **confirmed: keep icon-only**, it renders
cleanly at 320dp with no overflow.

### Required tests — found 7 of 11, added the missing 4

Present and correct: tests 1–5 (trigger maths + repository CRUD) and test 7 (model round-trip with null
`alertSentAt`).

Missing, now added:
- **Test 6** (one-shot: firing sets `alertSent: true`, `isActive: false`) — added a model round-trip
  test constructing that exact combination, since nothing in this phase's own scope actually fires an
  alert (that's Phase 08) — this proves the model can correctly represent and persist that state.
- **Test 8** (widget: empty state) — new `alerts_screen_test.dart`, overriding
  `priceAlertRepositoryProvider` with a fake returning an empty stream, asserting `EmptyStateView`'s
  title renders.
- **Test 9** (widget: swipe to delete) — new `alert_row_test.dart`, following the same
  drag-slidable-then-confirm-dialog pattern already established in `position_sale_row_test.dart`.
- **Test 10** (widget: add sheet computes threshold) — new `add_alert_bottom_sheet_test.dart`, entering
  a target price and tolerance and asserting the live preview text shows the correct computed value.
- **Test 11** (nav: 4 tabs at 320dp, no overflow) — new `app_bottom_nav_bar_test.dart`, constrains the
  test view to 320×640 and asserts no exception and all 4 icons render.

Final state: `flutter analyze` — 0 errors, all remaining warnings are pre-existing baseline categories.
`flutter test` — 204/204 passing (188 baseline + 16 new). No golden images affected.
