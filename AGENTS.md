# AGENTS.md — Stock Book (`stock_investment_tracker`)

> Persistent map of this codebase so an agent can act without re-reading everything.
> Verified against the tree at commit `385660b` (Flutter 3.44.8, Dart SDK `^3.12.2`), then updated
> through Phase 02 (`feat/positions-and-alerts` branch — see `phases/README.md` for the phased
> rebuild this repo is currently mid-way through; check it before starting new work here).
> **Keep this file updated when structure, schema, or the gotchas below change.**

---

## 1. What this app is

Offline-first **personal stock portfolio tracker** for the Pakistan Stock Exchange (PKR / `Rs `).
The user records **buy lots** and **sales against those lots**; the app derives every number
(shares remaining, realized P/L, allocation, free cash) locally — **there is no live market price
feed anywhere in the app today.** Google sign-in, per-user Firestore data, Hive local cache,
PDF report export.

- App display name: **Stock Book**. Package/module name: `stock_investment_tracker`.
- Android applicationId / namespace: `com.stocktracker.stock_investment_tracker`.
- Branding footer: "Powered by Coding District".
- 122 Dart files, ~14.1k LOC in `lib/` (about 4.5k of that is generated `.g` / `.freezed`).

---

## 2. Commands

```bash
flutter pub get
flutter analyze                      # Baseline: 0 errors, 25 warnings, 873 infos
flutter test                         # 60 tests, all passing (~1m30s full suite)
dart run build_runner build --delete-conflicting-outputs   # after touching @freezed / @riverpod
flutter run -t lib/main.dart         # dev (default; main.dart itself forces Environment.dev)
flutter run -t lib/main_prod.dart    # prod + Crashlytics error handlers
flutter run -t lib/main_staging.dart
flutter pub run flutter_launcher_icons   # regenerate launcher icons from assets/icon/Stockk.png
```

Lint baseline is `very_good_analysis` with `public_member_api_docs`, `sort_pub_dependencies` and
`lines_longer_than_80_chars` disabled, and `*.g.dart` / `*.freezed.dart` excluded.
**The ~898 existing issues are pre-existing noise — do not "fix the analyzer" as a side quest.**
Only care that your change adds no new *errors*. Top existing rule hits: `prefer_int_literals`,
`directives_ordering`, `deprecated_member_use`, `sort_constructors_first`, `always_use_package_imports`.

`flutter analyze` and `flutter test` both take several minutes on this machine and are prone to
timing out under a tool's default timeout — run them with a generous timeout (5–10 min) or in the
background and poll, rather than assuming a timeout means failure.

---

## 3. Architecture

Clean-architecture-ish, 4 layers, strictly one-directional (`presentation → domain ← data`):

```
lib/
├── core/            config, constants, error, services, theme, utils   (no layer deps)
├── domain/          entities, enums, repository INTERFACES, calculator (pure Dart, no Flutter/Firebase)
├── data/            freezed models, data_sources (firestore/hive), repository IMPLS
├── providers/       cross-cutting Riverpod providers (repositories, connectivity)
└── presentation/    <feature>/{screens,widgets,providers,controllers}
```

`presentation/` features: `auth`, `common`, `dashboard`, `onboarding`, `routing`, `settings`,
`splash`, `transactions`.

Import style is inconsistent by accident: `core`/`domain`/`data` use absolute
`package:stock_investment_tracker/...`, some presentation files use relative `../..`.
**Prefer absolute package imports for anything new** (the linter wants it too).

---

## 4. Data model — the single most important section

### 4.1 The critical fact: **sales are embedded, not a subcollection**

Firestore layout actually in use (`lib/core/constants/firestore_paths.dart`):

```
users/{uid}                                  # uid, email, username, createdAt (merge-written on sign-in)
users/{uid}/lots/{lotId}                     # a buy lot — sales live INSIDE this doc as an array
users/{uid}/withdrawals/{withdrawalId}       # profit cash-outs
users/{uid}/settings/preferences             # single settings doc
```

A lot document:

```json
{ "ticker":"ENGRO", "buyDate":"<Timestamp>", "sharesPurchased":100,
  "buyPricePerShare":350.0, "targetPrice":400.0,
  "sales":[ {"id":"uuid","sellDate":"<Timestamp>","sharesSold":20,"sellPricePerShare":380.0} ] }
```

`id` is **stripped before write** and re-injected from `doc.id` on read (both lots and withdrawals).
Doc IDs are client-generated `Uuid().v4()`.

Consequences you must remember:

- `SaleRepository` exists and works, but every method is a **read-modify-write of the parent lot
  document's `sales` array** (`FirestoreDataSource.addSale/updateSale/deleteSale`). Not atomic;
  no transaction. Concurrent sale edits on one lot can clobber each other.
- `firestore.rules` still declares a `lots/{lotId}/sales/{saleId}` subcollection rule. **It is dead** —
  nothing writes there. Harmless, but don't be misled by it.
- `SaleModel` and `WithdrawalModel` have **hand-written `fromJson` + `toJson`** (no `.g.dart`) because
  they must tolerate `sellDate` / `date` arriving as `Timestamp` *or* ISO `String` *or* missing.
  `LotModel`, `UserSettingsModel`, `UserModel` do have `.g.dart`.
- `LotModel.toJson()` is not trusted for nested sales — `FirestoreDataSource.addLot/updateLot`
  **explicitly re-serialize `json['sales']`** to stop raw `_SaleModel` instances reaching Firestore.
  Keep that if you touch those methods.

### 4.2 Entities (`lib/domain/entities/`)

| Entity | Notes |
|---|---|
| `Lot` | Plain class + **`equatable`**. Carries *derived* fields (`sharesRemaining`, `amountInvestedRemaining`, `realizedProfitLoss`, `status`) alongside stored ones. `holdingDays` getter: buy→now, or buy→last sale if closed. |
| `Sale` | Immutable; `amountReceived` is derived but passed in. |
| `StockSummary` | Per-ticker rollup across lots. |
| `PortfolioSummary` | Dashboard aggregate; see §5. |
| `AllocationSegment` | ticker / amount / percentage for the donut. |
| `UserSettings` | `favorites`, `startingCapital`, `currency` (default `PKR`), `themeMode` (default `dark`), `stockColors` (ticker → ARGB int). |
| `Withdrawal` | id / date / amount / note. Hand-written `==` and `hashCode`. |
| `LotStatus` enum | `open`, `partiallySold`, `closed`; `.displayName` → `Open` / `Partial` / `Closed`. |

`Lot` is the only entity using `equatable`; the rest hand-write `==` / `hashCode` or use freezed.
`equatable: ^2.1.0` is a declared direct dependency — keep it that way, since `lot.dart` imports it.

---

## 5. Business rules — `PortfolioCalculator` (`lib/domain/calculator/`)

Pure static functions, all money `_round`ed to 2dp. **This is the only place financial math belongs.**

- `sharesRemaining = sharesPurchased − Σ sharesSold`
- `amountInvestedRemaining = sharesRemaining × buyPricePerShare`
- `realizedProfitLoss = Σ (sale.amountReceived − sale.sharesSold × lot.buyPricePerShare)`
  → **FIFO / average cost is irrelevant: cost basis is always the lot's own buy price.**
- `status`: remaining == purchased → `open`; remaining == 0 → `closed`; else `partiallySold`.

`calculatePortfolioSummary(lots, startingCapital, [totalWithdrawn])` — the withdrawal semantics are
deliberate and documented in-code:

```
grossRealizedPL   = Σ per-lot realized P/L
realizedPL        = grossRealizedPL − totalWithdrawn      # what the dashboard shows
portfolioValue    = startingCapital + realizedPL          # (or currentlyInvested + realizedPL if no capital set)
totalCash         = startingCapital − currentlyInvested + realizedPL
freeCash          = startingCapital − currentlyInvested   # UNAFFECTED by withdrawals
currentlyInvested = Σ amountInvestedRemaining             # UNAFFECTED by withdrawals
```

**Withdrawing profit reduces realized P/L, portfolio value and liquid capital — and nothing else.**
There are dedicated tests for this; don't "fix" it.

If `startingCapital == 0` the app falls back to `totalInvested = currentlyInvested`, `freeCash = 0`.

Dashboard tile "TOTAL LIQUID CAPITAL" is computed in the widget as `freeCash + realizedPL`
(`stat_card_grid.dart`), not read off the summary.

---

## 6. Riverpod graph

Riverpod 2.x with `riverpod_generator` (old-style generated `Ref` types like `AllLotsRef`).
Mixed style: hand-written `Provider`s in `providers/repository_providers.dart`, `@riverpod` elsewhere.

```
authStateProvider (Stream<User?>) ──> currentUserIdProvider (String?)
        │
        ├──> lotRepositoryProvider ──────┐  all nullable: return null when uid == null
        ├──> saleRepositoryProvider      │  or Firebase isn't initialised
        ├──> withdrawalRepositoryProvider│
        └──> settingsRepositoryProvider ─┘
                     │
allLotsProvider ─────┴──> stockSummariesProvider ──> allocationDataProvider
allWithdrawalsProvider ─┐
settingsProvider ───────┴──> portfolioSummaryProvider
allLotsProvider + searchQueryProvider + statusFilterProvider ──> filteredLotsProvider
```

**Every repository provider is `?`-nullable.** Consumer code is uniformly
`final repo = ref.read(xRepositoryProvider); if (repo == null) return;`. Follow that shape.

Controllers (mutations):

- `AddBuyController.submit(...)`, `AddSellController.submit(...)` — `AsyncValue<void>` state.
- `SettingsController`, `WithdrawalController` — **both `@Riverpod(keepAlive: true)`, deliberately.**
  They are only ever reached via `ref.read(...notifier)` and never watched, so an autoDispose
  instance gets torn down mid-write and throws *"Bad state: Future already completed"* on slow
  connections. The reasoning is commented in both files. **Any new read-only-notifier controller
  needs `keepAlive: true` too.**
- `SettingsController` calls `ref.invalidate(settingsProvider)` after each write;
  `WithdrawalController` does **not** (its reads come from a live Firestore snapshot stream).
- `OnboardingController` — bool backed by Hive `auth` box, key `onboarding_seen`.

State providers: `SearchQuery` (String), `StatusFilter` (String, **default `'Open'`**).

---

## 7. Routing (`presentation/routing/app_router.dart`)

GoRouter, `initialLocation: '/splash'`.

| Route | Screen |
|---|---|
| `/splash` | animated logo, 2.2s, then routes itself (redirect skips `/splash`) |
| `/onboarding` | 3-page intro, gated by the Hive flag |
| `/sign-in` | Google sign-in |
| `/` , `/transactions` , `/settings` | `StatefulShellRoute` branches (bottom nav) |
| `/stock/:ticker` | `StockDetailScreen` (pushed, outside the shell) |
| `/add-stock` | **dead placeholder** — `Center(Text('Add Stock Placeholder'))` |

Redirect logic: not-logged-in + onboarding unseen → `/onboarding`; not-logged-in + seen → `/sign-in`;
logged-in on an auth screen → `/`.

Shell specifics:

- `navigatorContainerBuilder` wraps branches in `SwipeableNavigationShell` (a `PageView`) so tabs are
  horizontally swipeable, kept in sync with `navigationShell.currentIndex`.
- `PopScope` in the shell: back on a non-zero tab jumps to Dashboard instead of exiting.
  `TransactionsScreen` and `SettingsScreen` each *also* wrap themselves in a `PopScope` that
  calls `context.go('/')`. Belt and braces — leave both.
- The shell `Scaffold` hardcodes `backgroundColor: Color(0xFF13151B)` and `extendBody: true`
  (the nav bar is a floating pill), which is why list content pads `bottom: ~100-110`.

---

## 8. Offline-first conventions

- `LocalStorage.init()` opens three Hive boxes at startup: **`settings`, `auth`, `cache`**.
  `HiveDataSource` separately opens a box literally named **`settingsBox`** — a *different* box from
  `LocalStorage.settingsBox` (`'settings'`). Both exist. The settings cache lives in `settingsBox`
  under key `user_settings`; the onboarding flag lives in the `auth` box.
- Firestore persistence is enabled with `CACHE_SIZE_UNLIMITED` in `firebaseFirestoreProvider`.
- **Every Firestore write in `FirestoreDataSource` is wrapped in `.timeout(4s)` + empty `catch (_)`.**
  Intentional: offline writes hang on the future but are persisted locally by the SDK, so swallowing
  the timeout lets the UI proceed. Do the same for new writes.
- `SettingsRepositoryImpl.watchSettings()` yields the **Hive cache first**, then switches to the
  Firestore stream and writes each snapshot back to Hive.
- UI pattern before any mutation: `Connectivity().checkConnectivity()` → show a
  **yellow (`warningYellow`) "You're offline, will sync" snackbar** vs a **green (`moneyGreen`)
  success snackbar**. Copy this pattern for new mutations.
- `OfflineBanner` (inside `AppScaffold`) shows a yellow bar for **3 seconds only** on each offline
  transition, then auto-hides — deliberately not sticky.
- `HiveDataSource._sanitizeMap` exists because Hive returns nested `Map<dynamic, dynamic>`, which
  crashes generated `fromJson`. Keep it when adding cached maps.

---

## 9. UI conventions

- **Wrap screens in `AppScaffold`** (`SafeArea` + `OfflineBanner` + body), not raw `Scaffold`.
  `StockDetailScreen` is the exception (raw `Scaffold`, it is pushed above the shell).
- Use `CustomAppBar` (implements `PreferredSizeWidget`) as a `Column` child, not `Scaffold.appBar`.
- Bottom sheets follow a fixed idiom: `class X extends ConsumerStatefulWidget` with a
  **`static Future<void> show(BuildContext, ...)`** that calls
  `showModalBottomSheet(isScrollControlled: true)` with a 20–24px top radius and a 40×4 grab handle.
  Follow it exactly.
- Theme: `AppColors` / `AppTypography` (Google Fonts **Outfit** for headings, **Inter** for body) /
  `AppSpacing` (4/8/16/24/32/48) / `AppSemanticColors` ThemeExtension. **Both dark and light are now
  fully styled and user-switchable** (Phase 02, `feat/positions-and-alerts`) — a Theme row in
  Settings → PORTFOLIO (`Dark`/`Light`/`System`, right below Currency) calls
  `SettingsController.updateThemeMode`; `main.dart`'s top-level `themeModeFrom()` (public,
  `@visibleForTesting`, **not** a method on `StockTrackerApp` — pulled out specifically so it's unit
  testable, see `test/theme_mode_mapping_test.dart`) maps the stored string to `ThemeMode`, falling
  back to dark for `null`/unrecognised values.
  In practice **many widgets hardcode hex** (`0xFF13151B` card bg, `0xFF242731` dark border,
  `0xFFE2E8F0` light border, `0xFF1A1D27` input bg) and branch on
  `Theme.of(context).brightness == Brightness.dark`. Match the surrounding file.
  **`AppTypography.h1/h2/h3/body/display` are deliberately hardcoded to `Colors.white`** (not
  theme-derived) — every usage **must** chain `.copyWith(color: primaryTextColor)` or equivalent, or
  it renders unreadable white text in light mode. This was tried the "clean" way once already
  (stripping the literal color and relying on Flutter's ambient `DefaultTextStyle`) and reverted: the
  ambient fallback resolves to `bodyMedium`'s *muted secondary* color in both themes, not the
  intended full-contrast one — so unstyled usages don't go invisible, they go silently washed-out
  everywhere, dark mode included, which is worse because it's harder to notice. `caption`'s hardcoded
  mid-grey is the one exception that's fine as-is (legible on both grounds).
- Money is rendered via `AppCurrencyFormatter.format()` — symbol `'Rs '`, 0 decimals for whole
  numbers, 2 otherwise, optional `showSign`.
  **The formatter already emits the `Rs ` prefix — never write `'Rs ${AppCurrencyFormatter...}'`.**
  For an explicit sign, pass `.abs()` and prepend the sign yourself
  (`'${x >= 0 ? "+" : "-"}${AppCurrencyFormatter.format(x.abs())}'`); passing a negative value makes
  the formatter emit its own `-`, so doing both double-signs it.
- Ticker colors: `settings.stockColors[TICKER]` (user override, ARGB int) else
  `StockColorUtils.getColorForTicker()` — a deterministic hash into a fixed 16-color palette.
  **Long-pressing a `TickerAvatar` opens `StockColorPickerBottomSheet`.** Despite an old commit
  message mentioning a "Golden Angle HSL" generator, the current implementation is a plain
  16-entry palette.
- Animations: `flutter_animate` (`.animate().fadeIn().slideY()`), `flutter_staggered_animations`
  for lists, `shimmer` in `DashboardSkeleton`. `HapticFeedback.lightImpact()` on primary taps.
- Slide-to-edit/delete rows use `flutter_slidable` (`SaleEventRow`, `WithdrawalRow`).
  `LotCard` instead uses **long-press → `showMenu`** (Edit / Export PDF / Delete).

---

## 10. Feature map — where things live

| Feature | Entry point |
|---|---|
| Dashboard tiles + tap-to-expand detail | `dashboard/widgets/stat_card_grid.dart` (`DashboardMetricType` enum) → `metric_detail_card.dart` |
| Allocation donut (top-4 + expand, 2-way tap highlight) | `dashboard/widgets/allocation_donut_chart.dart` |
| Per-ticker list row | `dashboard/widgets/stock_row.dart` → pushes `/stock/:ticker` |
| Lot list + filter chips (`Open`/`Partial`/`Closed`/`All`) + search | `transactions/screens/transactions_screen.dart` |
| Lot card (expand, sales log, target-price est. gain, PDF, context menu) | `transactions/widgets/lot_card.dart` (657 lines — the biggest widget) |
| Add buy / add sell / select lot / edit lot / edit sale | `transactions/widgets/*_bottom_sheet.dart` |
| Ticker autocomplete (suggests from `settings.favorites` only) | `transactions/widgets/ticker_autocomplete.dart` |
| Settings: FAVORITE STOCKS / PORTFOLIO / PROFIT WITHDRAWALS / COMPANY INFO / DEVELOPER INFO / ACCOUNT | `settings/screens/settings_screen.dart` (818 lines) |
| Profit withdrawals | `settings/widgets/withdrawal_bottom_sheet.dart`, `withdrawal_row.dart` |
| PDF export (3 reports) | `core/services/pdf_report_service.dart` (808 lines) |

`DashboardMetricType`: `totalInvested`, `currentlyInvested`, `realizedPL`, `totalFree`, `freeCash`,
`openLots`. Tapping a stat card toggles a `MetricDetailCard` below the grid.

`PdfReportService` public API — all `static`, all end in `Printing.layoutPdf(...)`:

- `exportOverallPortfolioPdf({lots, summary, stockSummaries, withdrawals})` — Transactions app bar
- `exportStockPdf({ticker, stockLots, summary})` — Stock detail app bar
- `exportLotPdf(Lot)` — lot card button + context menu

---

## 11. Known issues / traps (verified, not speculation)

1. **`PortfolioCalculator.calculateStockSummaries` has an unused `anySales` local** and its status
   branch is partly redundant. Behaviour is correct; the dead line is analyzer noise.
2. **Two divergent status computations.** `LotModel.toEntity()` recomputes status/derived fields from
   the raw doc (source of truth on read), while `AddSellController` computes them optimistically from
   the in-memory entity before writing. They agree today; keep them in sync if you change either.
3. **`LotRepository.watchLotsByTicker` / `watchLotsByFilter` are dead code** — all filtering happens
   in `filteredLotsProvider` or in view-level `.where(...)`.
4. **`SparklineChart` draws fake data** — `Random(seed ?? color.value)`, 7 points, biased up or down
   by `isPositive`. It is decorative. There is no price history in this app.
5. **`/add-stock` route is a placeholder** with nothing navigating to it.
6. `lib/firebase_options.dart` **is committed**;
   `android/app/google-services.json` is gitignored and untracked.
7. `lib/main_staging.dart` has a formatting glitch (`...local_storage.dart';void main()` on one line).
8. Only `main_prod.dart` installs the Crashlytics `FlutterError.onError` /
   `PlatformDispatcher.onError` handlers. `firebase_analytics` is a dependency but **never used**
   anywhere in `lib/`.
9. `mocktail` is a dev dependency but unused. (`golden_toolkit` is now heavily used — see §12.)
10. **`DashboardScreen` is not pixel-golden-testable as written.** It keeps `_lastSyncTime =
    DateTime.now()` directly in `State` (`dashboard_screen.dart`) with no injectable clock, and
    renders it as visible "Offline (HH:MM)" text. Any golden master captured against it goes stale
    the instant a minute boundary passes before the comparison runs — which happens routinely once
    the suite is large enough to take more than a few seconds to reach that test. `theme_golden_test.dart`
    deliberately does **not** pixel-diff Dashboard for this reason (see the comment above its two
    test cases) — it asserts no-exception + correct scaffold background color instead, and leans on
    `contrast_test.dart` (which is immune to this, since it checks contrast ratios, not exact pixels)
    for Dashboard's real coverage. If you ever need Dashboard fully pixel-tested, it needs a proper
    injectable clock first — don't just re-add `screenMatchesGolden` and hope.
11. **`OfflineBanner` has a real wall-clock `Timer` (3s auto-hide) that makes it a landmine for any
    widget/golden test.** Mocking connectivity as `'none'` (offline) to exercise the banner will make
    that screen's test flaky in a large suite: enough real time can pass between the initial pump and
    a later assertion/comparison for the timer to fire mid-test, silently hiding the banner and
    shifting the entire layout up — a "regression" that has nothing to do with your change and
    everything to do with how long the rest of the suite took to get there. `theme_golden_test.dart`
    and `contrast_test.dart` both mock connectivity as **online** (`'wifi'`) for exactly this reason;
    the banner's own styling is deliberately theme-invariant (yellow-on-black regardless of light/dark,
    see `common/offline_banner.dart`) so there's no theme coverage lost by keeping it hidden in these
    tests. If a future test genuinely needs to exercise the *offline* banner rendering itself, keep it
    isolated to its own short, single-purpose test rather than layering it onto a screen-level golden.

---

## 12. Tests

`test/` mirrors `lib/`. 60 tests, all green (~1m30s for the full suite; run with a generous timeout,
see §2):

- `domain/calculator/portfolio_calculator_test.dart` (9) — includes the three withdrawal-semantics tests
- `domain/calculator/portfolio_calculator_characterisation_test.dart` (4) — **do not "fix" these
  numbers if they go red.** Locks `PortfolioCalculator`'s exact output against a fixed 8-lot/12-sale/
  3-ticker fixture, written specifically so the future position-merge migration (see
  `phases/PHASE-03A-position-model.md`) can prove it changes nothing. Header comment explains it further.
- `data/repositories/lot_repository_impl_test.dart` (4) — **mockito** with a checked-in `.mocks.dart`;
  regenerate via build_runner if the interface changes
- `data/models/model_serialization_test.dart` (2) — Lot/Sale roundtrips
- `core/utils/{currency_formatter,stock_color_utils}_test.dart` (7)
- `core/services/data_export_service_test.dart` (4) — the Settings → Account "Export data (JSON)"
  backup feature; round-trip, empty portfolio, null `targetPrice`, ISO-8601 dates
- `presentation/settings/starting_capital_input_test.dart` (8) — responsive layout + the
  thousands-separator formatter + validation (rejects negative/unparseable input rather than
  silently saving `0`)
- `presentation/settings/theme_toggle_test.dart` (1) — the Theme dropdown calls
  `updateThemeMode` with the exact persisted string
- `theme_mode_mapping_test.dart` (5) — pure unit tests of `main.dart`'s `themeModeFrom()`
- `golden/theme_golden_test.dart` (10) — full-screen goldens, light+dark, for Dashboard (smoke-test
  only, see AGENTS.md #10 above), Settings, Transactions, Lot Card, Stock Detail. Needs
  `test/flutter_test_config.dart`'s `loadAppFonts()` to render real fonts instead of tofu boxes —
  **if goldens start failing en masse with text-shaped diffs everywhere, that's a font-loading
  problem, not a real regression; regenerate with `--update-goldens` after fixing the actual cause,
  don't just accept the new pixels blind.**
- `golden/contrast_test.dart` (5) — walks every rendered `RichText`, resolves each run's *actual
  local* background (not a blanket app-wide assumption — that false-positives on `TickerAvatar`'s
  deliberate white-on-saturated-circle text) and flags anything under 5% luminance contrast. This is
  the test that would have caught the white-on-white class of bug if one shipped; golden pixel-diffs
  can't (a bad master just diffs clean against itself forever).
- `widget_test.dart` (1) — `StatusBadge`

New pure logic belongs in `PortfolioCalculator` **with a test**; that used to be the only
consistently well-tested layer, but Phase 02 added real widget/golden coverage too — follow whichever
existing test's pattern is closest to what you're adding rather than starting from scratch.

---

## 13. Adding a new feature — the established path

To add a new persisted entity, mirror `Withdrawal` end-to-end (it is the newest and cleanest):

1. `domain/entities/x.dart` — immutable class + `copyWith`.
2. `domain/repositories/x_repository.dart` — `Stream<List<X>> watchAllX()` + `add` / `update` / `delete`.
3. `data/models/x_model.dart` — `@freezed`; hand-write `fromJson` / `toJson` if dates can arrive as
   `Timestamp` *or* `String`, plus an `XModelExtension` with `toEntity()` and `static fromEntity()`.
4. `core/constants/firestore_paths.dart` — add path helpers.
5. `data/data_sources/remote/firestore_data_source.dart` — stream + writes, each with the
   `.timeout(4s)` + `catch (_)` idiom, stripping `id` on write and injecting `doc.id` on read.
6. `data/repositories/x_repository_impl.dart` — takes `uid` + `FirestoreDataSource`.
7. `providers/repository_providers.dart` — nullable provider gated on `currentUserIdProvider`.
8. `presentation/<feature>/providers/` — a `@riverpod` stream provider for reads, plus a
   `@Riverpod(keepAlive: true)` controller for writes.
9. `firestore.rules` — add the per-user match block.
10. `dart run build_runner build --delete-conflicting-outputs`, then `flutter analyze && flutter test`.

---

## 14. Open work

This repo is mid-way through a phased rebuild on the `feat/positions-and-alerts` branch. **Start at
`phases/README.md`** — it's the live index (status table, workflow, per-agent rules) for everything
below, and supersedes the older `target-price-alerts-plan.md` / `IMPLEMENTATION_PLAN.md` at the repo
root (kept for historical context, but `phases/` is where the current, reconciled plan lives).

Done: Phase 00 (safety net — characterisation tests + JSON export/backup), Phase 01 (responsive
starting-capital input), Phase 02 (full light theme + toggle), Phase 03A (position engine — see
below). Ready but not started: 03B (wire the UI to positions and actually run the migration — the
riskiest remaining step), 04 (live PSX prices, display-only), 05 (push notification infra), 06
(sell-target alert fields), 07 (buy alerts + new screen), 08 (Python/GitHub-Actions backend that
actually fetches prices and sends the pushes). Each brief is self-contained — read the target brief
plus this file before starting, not the whole chain.

### Phase 03A — the position engine (built, tested, not yet wired to anything)

A parallel domain layer alongside `Lot`/`PortfolioCalculator` now exists, built for the eventual
same-ticker-lot merge (see `phases/PHASE-03A-position-model.md`'s "Review notes" for the full story).
**None of it is active** — nothing in the running app reads or writes `positions/`, no UI references
it, and `lots` is completely untouched. It exists purely as tested, reviewed groundwork for Phase 03B.

- `domain/entities/{position,position_buy,position_sale}.dart` — `Position` holds `buys`/`sales` and
  derives everything else; it does not cache `avgCost`/`totalCost` itself.
- `domain/enums/position_status.dart` — `open`/`partiallySold`/`closed`, same semantic
  `PortfolioCalculator.calculateStockSummaries` already uses per ticker (see §5's per-ticker status
  branch) — a `Position` *is* that per-ticker grouping, so the rule carries over unchanged.
- `domain/calculator/position_calculator.dart` — moving-average cost engine.
  **`avgCost()`, `totalCost()` and `amountInvested()` all derive from one private
  `_preciseTotalCost()` helper — never call `sharesHeld(p) * avgCost(p)` yourself.** `avgCost()`
  rounds to 2dp before it returns; multiplying through that already-rounded value compounds error
  (verified: $4.41 off on a $12,724 position in the reference scenario before this was fixed). If
  you add a new derived figure to `Position`, derive it from `_preciseTotalCost()`, not from
  `avgCost()`'s return value.
- `domain/calculator/position_migration.dart` — builds `Position`s from existing `Lot`s and
  verifies the result three independent ways (realized P/L, amount invested, **and shares held per
  ticker** — all three are required; amount-invested alone can't catch a share-count corruption that
  still leaves `shares × avgCost` looking plausible). `MigrationResult.isValid == false` must never
  be persisted — 03B enforces that, this layer only computes it.
- `data/models/position_model.dart` — all three models (`PositionModel`, `PositionBuyModel`,
  `PositionSaleModel`) live in this **one file**, unlike `Lot`/`Sale` which are separate files.
  Mirrors `LotModel`'s explicit nested re-serialisation (§4.1) and `SaleModel`'s tolerant
  Timestamp-or-String date parsing.
- `data/repositories/position_repository_impl.dart`, `providers/repository_providers.dart`'s
  `positionRepositoryProvider`, and the `users/{uid}/positions/{id}` Firestore rule all follow the
  established per-entity pattern from §13 — nothing unusual there.
- **Known quirk, not a bug:** `PositionMigration` assigns a ticker's resolved `targetPrice` to its
  most recent position regardless of whether that position is open or closed. Harmless today (dead
  data on a closed position), but don't read `targetPrice` off a `Position` without checking
  `status` first once alert logic (Phase 06) exists.
- `test/fixtures/portfolio_fixture.dart` is now the **shared** fixture between Phase 00's
  characterisation test and Phase 03A's migration invariant test — if you ever need a bigger/different
  fixture, extend this one rather than forking it; the whole point of the migration invariant test is
  that both sides read the same data.

Design references (static, not code): `Stock_Tracker_PRD.md`, `Stock_Tracker_UI_UX_Design_PRD.md`,
`Stock App UI/*.png`.
