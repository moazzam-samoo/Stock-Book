# AGENTS.md — Stock Book (`stock_investment_tracker`)

> Persistent map of this codebase so an agent can act without re-reading everything.
> Verified against the tree at commit `385660b` (Flutter 3.44.8, Dart SDK `^3.12.2`).
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
flutter analyze                      # Baseline: 0 errors, 26 warnings, 713 infos
flutter test                         # 23 tests, all passing (~15s)
dart run build_runner build --delete-conflicting-outputs   # after touching @freezed / @riverpod
flutter run -t lib/main.dart         # dev (default; main.dart itself forces Environment.dev)
flutter run -t lib/main_prod.dart    # prod + Crashlytics error handlers
flutter run -t lib/main_staging.dart
flutter pub run flutter_launcher_icons   # regenerate launcher icons from assets/icon/Stockk.png
```

Lint baseline is `very_good_analysis` with `public_member_api_docs`, `sort_pub_dependencies` and
`lines_longer_than_80_chars` disabled, and `*.g.dart` / `*.freezed.dart` excluded.
**The 739 existing issues are pre-existing noise — do not "fix the analyzer" as a side quest.**
Only care that your change adds no new *errors*. Top existing rule hits: `prefer_int_literals` (152),
`directives_ordering` (95), `deprecated_member_use` (59), `sort_constructors_first` (58),
`always_use_package_imports` (56).

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
  `AppSpacing` (4/8/16/24/32/48) / `AppSemanticColors` ThemeExtension.
  `main.dart` drives `MaterialApp.themeMode` from `settings.themeMode` via `_themeModeFrom()`
  (`'light'` / `'system'` / anything else → dark, which is also the loading fallback).
  **There is still no UI control that calls `SettingsController.updateThemeMode`,** so in practice
  every user is on dark until such a toggle is added.
  In practice **many widgets hardcode hex** (`0xFF13151B` card bg, `0xFF242731` dark border,
  `0xFFE2E8F0` light border, `0xFF1A1D27` input bg) and branch on
  `Theme.of(context).brightness == Brightness.dark`. Match the surrounding file.
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

1. **No UI exposes `themeMode`.** The plumbing is complete end to end (entity → Firestore →
   `SettingsController.updateThemeMode` → `MaterialApp.themeMode`), but nothing in
   `settings_screen.dart` calls the setter, so the app is always dark in practice. Adding the
   toggle is a UI-only change — a row in the `PORTFOLIO` section alongside Currency.
2. **`PortfolioCalculator.calculateStockSummaries` has an unused `anySales` local** and its status
   branch is partly redundant. Behaviour is correct; the dead line is analyzer noise.
3. **Two divergent status computations.** `LotModel.toEntity()` recomputes status/derived fields from
   the raw doc (source of truth on read), while `AddSellController` computes them optimistically from
   the in-memory entity before writing. They agree today; keep them in sync if you change either.
4. **`LotRepository.watchLotsByTicker` / `watchLotsByFilter` are dead code** — all filtering happens
   in `filteredLotsProvider` or in view-level `.where(...)`.
5. **`SparklineChart` draws fake data** — `Random(seed ?? color.value)`, 7 points, biased up or down
   by `isPositive`. It is decorative. There is no price history in this app.
6. **`/add-stock` route is a placeholder** with nothing navigating to it.
7. `lib/firebase_options.dart` **is committed**;
   `android/app/google-services.json` is gitignored and untracked.
8. `lib/main_staging.dart` has a formatting glitch (`...local_storage.dart';void main()` on one line).
9. Only `main_prod.dart` installs the Crashlytics `FlutterError.onError` /
    `PlatformDispatcher.onError` handlers. `firebase_analytics` is a dependency but **never used**
    anywhere in `lib/`.
10. `mocktail` and `golden_toolkit` are dev dependencies but unused.

---

## 12. Tests

`test/` mirrors `lib/`. 23 tests, all green:

- `domain/calculator/portfolio_calculator_test.dart` (9) — includes the three withdrawal-semantics tests
- `data/repositories/lot_repository_impl_test.dart` (4) — **mockito** with a checked-in `.mocks.dart`;
  regenerate via build_runner if the interface changes
- `data/models/model_serialization_test.dart` (2) — Lot/Sale roundtrips
- `core/utils/{currency_formatter,stock_color_utils}_test.dart` (7)
- `widget_test.dart` (1) — `StatusBadge`

New pure logic belongs in `PortfolioCalculator` **with a test**; that is the only well-tested layer.

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

`target-price-alerts-plan.md` (repo root, **untracked**) is a detailed, not-yet-implemented plan for:
live PSX market prices in a shared top-level `market_prices/{ticker}` collection, FCM push when a
lot's `targetPrice` is hit (sell alert), and a new "buy alerts" feature
(`users/{uid}/price_alerts/{alertId}` + a new screen + nav entry). The backend is specified as a
**Python script on a GitHub Actions cron**, deliberately *not* Cloud Functions, because the Firebase
project is on the Spark/free plan. `firebase_messaging` is not yet a dependency and there is no
`functions/` or `scripts/` directory. Read that file before touching anything alert- or price-related.

Design references (static, not code): `Stock_Tracker_PRD.md`, `Stock_Tracker_UI_UX_Design_PRD.md`,
`Stock App UI/*.png`.
