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

- [ ] `flutter analyze` — 0 errors; `flutter test` fully green
- [ ] Create, edit, delete an alert end to end on a device
- [ ] Alerts tab reachable, four-tab nav verified at 320dp (report a screenshot)
- [ ] Light and dark both correct
- [ ] Threshold shown to the user matches the tested formula

## Out of scope

Sending the notification (08). Re-arming a fired alert. Sell-target alerts (06). Any change to
positions.
