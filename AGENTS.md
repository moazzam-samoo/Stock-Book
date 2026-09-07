# AGENTS.md — Stock Book (`stock_investment_tracker`)

> Persistent map of this codebase so an agent can act without re-reading everything.
> Verified against the tree at commit `385660b` (Flutter 3.44.8, Dart SDK `^3.12.2`), then updated
> through Phase 09 (`feat/positions-and-alerts` branch — see `phases/README.md` for the phased
> rebuild this repo is currently mid-way through; check it before starting new work here). All
> phases 00-09 are marked **Done** in that table — there is no "not started" phase left. Further
> updated same day (2026-09-07) for account deletion, real release signing, the 5-page onboarding
> flow, the Company & Owners page, and two dashboard bugfixes (§9, §11 #14-15, §12, §18) — see
> `PLAYSTORE_RELEASE_GUIDE.md` for what's still missing before this app can actually be published
> (as of this update, only the on-demand-refresh item remains open there).
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
flutter test                         # ~55 test files, ~239 test()/testWidgets() cases — the old
                                      # "60 tests" figure is stale; re-run for an exact live count
                                      # rather than quoting one (see §12)
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
| `/` , `/transactions` , `/alerts` , `/settings` | `StatefulShellRoute` branches (bottom nav) — **four** branches now, `/alerts` (`AlertsScreen`, Phase 07) added since this doc's original 3-branch snapshot |
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
- Slide-to-edit/delete rows use `flutter_slidable` (`PositionSaleRow`, `WithdrawalRow`, `AlertRow`).
  `PositionCard` instead uses **long-press → `showMenu`** (Edit / Export PDF / Delete) — same idiom
  `LotCard` used before its Phase 03B redesign/rename.
- `LotCard` (657 lines) was fully redesigned and renamed to `PositionCard`
  (`presentation/transactions/widgets/position_card.dart`, now the biggest widget in the app at
  ~1245 lines).
- Dashboard stat cards (`dashboard/widgets/stat_card.dart`) have a `StatCardDecoration` enum
  (`ghostIcon` / `sparkline` / `wave`) — each card picks whichever decoration matches what the
  metric actually means (a faint icon watermark, a reused `SparklineChart`, or
  `wave_decoration.dart`'s wave silhouette for "liquid" capital), not one style forced on all six.
  Badge/ghost icons come from `font_awesome_flutter: ^11.0.0` via `FontAwesomeIcons.*.data`
  (`.data` unwraps the package's `FaIconData` wrapper into a plain `IconData` — it is not an
  `IconData` subtype itself), used in `stat_card_grid.dart` and `allocation_donut_chart.dart`.
- **Settings' old two inline "Coding District" / "Moazzam Samoo — Lead Developer" cards are
  gone.** `settings_screen.dart` deleted `_buildCompanySection`/`_buildDeveloperSection`
  entirely and replaced them with one clickable nav card, `_buildCompanyOwnersNavCard`, under
  "ABOUT US" that pushes `/company` → `CompanyOwnersScreen`
  (`presentation/settings/screens/company_owners_screen.dart`, new). Same pushed-above-shell
  raw-`Scaffold` pattern as `StockDetailScreen` (`CustomAppBar(showBackButton: true)`, not
  `AppScaffold`). Covers: the Coding District card, a "why we built Stock Book" motivation
  paragraph, and both owner cards — **Moazzam Samoo** (Owner & Lead Developer,
  `assets/icon/dev-mozzam.jpg`, has a portfolio link) and **Kheeraj Das** (Owner & Developer,
  `assets/icon/dev-kheeraj.jpg`, `portfolioUrl: null` → renders a "Portfolio — Coming Soon"
  chip instead of a broken/empty link). The old single `assets/icon/dev.png` was replaced by
  these two per-owner photos.
- "ABOUT US" also has a version label — `_buildVersionLabel` reads `packageInfoProvider`
  (`providers/package_info_providers.dart`, new, wraps `package_info_plus`) and renders
  `'Version ${info.version} (${info.buildNumber})'`. **This is the one place app version should
  ever be read from** — don't hardcode it elsewhere.
- **Onboarding is now 5 pages, not 2** (`presentation/onboarding/screens/onboarding_screen.dart`).
  Order: Track Every Trade (`OnboardingLineChart`) → Analyze Your Portfolio
  (`OnboardingDonutChart`) → Live Market Prices (`OnboardingLivePrice`, new) → Never Miss Your
  Target (`OnboardingAlertBell`, new) → Buy Anytime, One Clear Average
  (`OnboardingPositionAverage`, new). All three new widgets live in
  `presentation/onboarding/widgets/`, same `CustomPainter`/`AnimationController`-driven approach
  as the original two (no external animation library):
  - `OnboardingLivePrice` — price ticks from a base value to a "live" value while a sparkline
    draws in, plus a pulsing "LIVE" dot.
  - `OnboardingAlertBell` — a hand-painted bell rings once (`Curves.elasticOut`), then a
    "target hit" notification card slides/fades in.
  - `OnboardingPositionAverage` — three staggered "buy" chips (via `Interval`s on one
    `AnimationController`) converge into an average-cost line, then a two-segment
    realized/unrealized profit bar builds up.
  - `PageIndicatorDots` needed **no changes** (already page-count-agnostic).
  - The screen's "is this the last page" check is a top-level `const int _lastPageIndex = 4;`
    compared against `_currentPage` — if you add/remove a page, update this constant, don't
    hand-edit the comparisons.
- Sign-in screen now links Privacy Policy (`auth/screens/sign_in_screen.dart`, via
  `Uri.parse(LegalLinks.privacyPolicy)`) — see §18 for the full legal-links/GitHub-Pages picture.

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
12. **`ListView.builder` items without `key: ValueKey(id)` can make Flutter reuse a stale
    Element/State across a list-index reassignment when the underlying data reorders** — e.g. a
    filter-tab switch that changes which item sits at index 3. This was a real, confirmed bug:
    `PositionCard` rendered its header visually overlapping the ticker after switching filter tabs,
    because the widget at a given index kept its old state while the data underneath it changed.
    Fixed by keying each card `ValueKey(card.display.id)` in `transactions_screen.dart`. The same
    class of bug was suspected (and preemptively fixed, `key: ValueKey(alert.id)`) in `AlertRow`
    for intermittent swipe-gesture failures — **any new `ListView.builder`/`AnimationLimiter` list
    over reorderable data needs an explicit `ValueKey` on each item**, don't rely on the default
    index-based key.
13. **`UserRepositoryImpl.savePushToken` and both `_localNotifications.show()` call sites in
    `push_notification_service.dart` used to swallow failures with zero logging** (a bare
    `.catchError((_) => null)` / no error handling at all) — a token-save failure or a
    local-notification display failure would leave no trace anywhere, meaning the backend could
    silently keep pushing to a stale/missing token, or an alert could silently never appear, with
    nothing in logcat/Console to explain why. Both now log via `Logger().e(...)`. If you add a new
    fire-and-forget write or display call in a notification/background code path, log the failure —
    don't just swallow it, even when it's correct for the exception to not propagate.
14. **Two real dashboard bugs found and fixed together (`df323c8`).** (a)
    `PortfolioCalculator.calculateStockSummariesFromPositions` used to read
    `pos.sales.isNotEmpty` across **every** position for a ticker to decide "Partial" status —
    meaning a fully-closed, unrelated historical buy/sell cycle for a ticker could make a
    brand-new, never-touched open position for that same ticker wrongly read as "Partial".
    Fixed: only a position **still contributing to `sharesHeld`**
    (`posSharesHeld > 0 && pos.sales.isNotEmpty`) can trigger "Partial" now — a closed older
    cycle's sales are ignored for status purposes (its realized P/L still counts, just not its
    status). See `test/domain/calculator/stock_summary_grouping_test.dart` for the worked
    examples. (b) `MetricDetailCard`'s Open Lots drill-down (`_buildOpenLotsBody`) used to read
    the **legacy `lots` collection directly** instead of `positions` — since nothing writes to
    `lots` after the position-model migration (§17), any position created post-migration could
    **never** appear in that one panel, no matter how long the app was used, even though the
    stat card above it (position-based) already counted correctly. The constructor param was
    renamed `lots` (`List<Lot>`) → `positions` (`List<Position>`); it now filters
    `positions.where((p) => PositionCalculator.sharesHeld(p) > 0)`. If you add a new
    drill-down panel here, read from `positions`, never `lots` — `lots` is migration-frozen.
15. **`android/key.properties` (gitignored, real values, not tracked) now gates release
    signing.** `build.gradle.kts` reads it via `Properties()`/`FileInputStream` at Gradle config
    time; when absent, `release` builds fall back to the **debug** keystore (not a build
    failure), so `flutter run --release` still works locally without it. **Before any Play
    Store upload, verify `signingConfig` actually resolved to `"release"`, not `"debug"`** —
    there is no build-time error to catch a missing/misconfigured `key.properties` on a
    store-bound build. Template at `android/key.properties.example`.

---

## 12. Tests

`test/` mirrors `lib/` — the "60 tests" figure in older revisions of this doc is stale. Live run
as of 2026-09-07 (post account-deletion/onboarding-5-page/company-owners-page/dashboard-fixes
work): **252 tests total, 240 passing, 12 failing** (~5-8 min for the full suite; run with a
generous timeout, see §2). All 12 failures are in `golden/theme_golden_test.dart` (Position Card
Dark/Light, Settings Screen Dark/Light, +8 more) — **expected, not a regression to chase**: the
UI-redesign work (`stat_card.dart`'s `StatCardDecoration`, `wave_decoration.dart`,
`app_bottom_nav_bar.dart`, `allocation_donut_chart.dart`, the `LotCard`→`PositionCard` redesign,
and now the Settings/Company-Owners page changes) changed real pixels the checked-in golden
masters predate. Regenerate with `flutter test --update-goldens` and review the diffs before
committing — don't blind-accept, per the existing font-loading caveat below, but do expect these
12 specifically to need a refresh rather than a code fix.

Original core coverage, still present:

- `domain/calculator/portfolio_calculator_test.dart` (9) — includes the three withdrawal-semantics tests
- `domain/calculator/portfolio_calculator_characterisation_test.dart` (4) — **do not "fix" these
  numbers if they go red.** Locks `PortfolioCalculator`'s exact output against a fixed 8-lot/12-sale/
  3-ticker fixture, written specifically so the position-merge migration can prove it changes
  nothing. Header comment explains it further.
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
  only, see AGENTS.md #10 above), Settings, Transactions, Position Card, Stock Detail. Needs
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

New test coverage since the original set, by area (non-exhaustive — see `test/` for the full tree):

- `core/services/push_notification_service_test.dart` — `buildNotificationContent` payload parsing,
  cold-start routing branches, background-handler behaviour (mocked).
- `core/services/workflow_trigger_service_test.dart` — every `WorkflowTriggerOutcome` branch against
  mocked HTTP responses (204/401/403/404/timeout/unknown).
- `data/models/{price_alert_model,market_price_model,market_status_model,position_model,ticker_info_model}_test.dart`
  — serialization round-trips, tolerant date parsing.
- `data/repositories/{price_alert_repository_impl,market_price_repository,market_status_repository,
  ticker_repository_impl,user_repository_impl}_test.dart` — mockito, checked-in `.mocks.dart` per file.
- `data/data_sources/{hive_data_source_market_prices,local/hive_data_source_tickers,
  market_prices_chunking}_test.dart`.
- `data/migration/position_migration_runner_test.dart`.
- `domain/calculator/{position_calculator_live_prices,position_migration,split_by_buy,
  stock_summary_grouping,dashboard_position_parity}_test.dart`.
- `domain/entities/{position,price_alert}_test.dart`.
- `presentation/alerts/**` — `alerts_providers_test.dart`, `alerts_screen_test.dart`,
  `add_alert_bottom_sheet_test.dart`, `alert_row_test.dart`.
- `presentation/common/{app_bottom_nav_bar,market_price_pull_to_refresh,status_badge}_test.dart`.
- `presentation/dashboard/widgets/portfolio_header_market_clock_test.dart`.
- `presentation/transactions/{providers/filtered_positions,widgets/position_card,
  widgets/position_sale_row,widgets/ticker_autocomplete}_test.dart`.
- `presentation/auth/controllers/auth_controller_test.dart` — covers `deleteAccount()` using a
  **hand-written fake `AuthRepository`** (not Mockito, unlike most repo-backed controller tests
  elsewhere) — asserts success ends in non-error state, and a thrown repository exception is
  caught by `AsyncValue.guard` and surfaces as controller error state rather than propagating.
- `domain/calculator/stock_summary_grouping_test.dart` was **updated, not just added to** — an
  existing test previously asserted the old/buggy `LotStatus.partiallySold` outcome for a ticker
  with a closed cycle plus a fresh open one; it now asserts `LotStatus.open` instead (§11 #14a).

Python: `scripts/price_alerts/tests/` — `test_alerts.py` (repeat-fire semantics), `test_firestore_io.py`,
`test_main.py` (orchestration/step isolation), `test_market_status_source.py`, `test_price_source.py`,
`test_tickers_source.py`, with real captured fixture data (`tests/fixtures/*.json`), not synthetic —
run via `pytest scripts/price_alerts` (needs `requirements-dev.txt`). 26/26 passing per Phase 08's brief.

New pure logic belongs in the relevant calculator **with a test**; follow whichever existing test's
pattern is closest to what you're adding rather than starting from scratch.

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

## 15. Push notifications & price alerts (Phase 05-09)

### 15.1 Push notification infrastructure (Phase 05)

`lib/core/services/push_notification_service.dart` + `lib/providers/push_notification_providers.dart`.

- Backend sends **data-only FCM messages** — deliberately no `notification` field, so the client's
  own `buildNotificationContent(Map data)` (pure, top-level, unit-testable without Firebase) is the
  single source of truth for what's shown. Payload contract: `{type: "sell"|"buy", ticker,
  positionId|alertId, price, targetPrice}`. **The notification shows `targetPrice` (what the user
  set), never `price`** (the live price that triggered it) — those only coincide by chance.
- `firebaseMessagingBackgroundHandler` — top-level function, `@pragma('vm:entry-point')`, required
  because Android/iOS spin up a throwaway isolate to run it when the app is backgrounded or fully
  terminated; it reinitializes Firebase from scratch (`Firebase.apps.isEmpty` guard) since nothing
  else in the app is alive in that isolate. This was **the missing piece that made push alerts
  invisible whenever the app was closed** — a data-only message has zero automatic OS display
  without a registered background handler.
- Foreground path: `FirebaseMessaging.onMessage` → `_onForegroundMessage` → `_localNotifications.show()`.
- Cold-start routing has **two distinct origins**, both handled in `PushNotificationService.initialize()`:
  (A) `FirebaseMessaging.getInitialMessage()` — launched via an OS-auto-displayed notification; never
  actually fires today since this app never sends a `notification` field, kept as a defensive
  fallback. (B) `_localNotifications.getNotificationAppLaunchDetails()` — launched by tapping a
  notification the app itself displayed (via the background handler or foreground path); **this is
  what fires in practice**.
- `PushNotificationService._coldStartRouteHandled` is a **static, process-lifetime** guard, not
  instance-lifetime — a new `PushNotificationService` is constructed per signed-in user
  (`pushNotificationServiceProvider` depends on `userRepositoryProvider`), but "how was this process
  launched" doesn't change on logout/login. Without the guard, switching accounts replayed the
  original cold-start notification's route onto a brand-new account with no such position (real bug,
  fixed — `resetColdStartRouteHandledForTesting()` exists for tests).
- Android notification channel id `stock_alerts`, sound resource `android/app/src/main/res/raw/stock_alert.wav`
  (`RawResourceAndroidNotificationSound('stock_alert')`); iOS uses `DarwinNotificationDetails(sound: 'stock_alert.wav')`.
  Android init icon is `'ic_launcher_foreground'` (a drawable) — `'ic_launcher'` is mipmap-only and
  `flutter_local_notifications` requires a drawable.
- Token saved via `UserRepositoryImpl.savePushToken(token)` → `users/{uid}.fcmToken` +
  `fcmTokenUpdatedAt` (merge write). See §11 #13 for the silent-failure bug found and fixed here.

### 15.2 Buy-side price alerts (Phase 07)

New `Alerts` tab (`lib/presentation/alerts/` — `screens/alerts_screen.dart`,
`widgets/alert_row.dart`, `widgets/add_alert_bottom_sheet.dart`, `providers/alerts_providers.dart`),
4th `StatefulShellBranch` in the router at `/alerts`.

- `domain/entities/price_alert.dart` — `PriceAlert(id, ticker, targetPrice, tolerancePercent=1.0,
  isActive=true, alertSent=false, alertSentAt, lastAlertPrice, createdAt)`. `Equatable`.
- `data/models/price_alert_model.dart` (`@freezed`, hand-written `fromJson`/tolerant date parsing —
  same pattern as `PositionBuyModel`) / `data/repositories/price_alert_repository_impl.dart` — plain
  CRUD over `FirestoreDataSource`, follows the established §13 pattern exactly.
- `FirestorePaths.priceAlerts(uid)` → `users/{uid}/price_alerts`, `priceAlert(uid, id)` → `.../{id}`.
- **Alerts are not one-shot — they re-fire.** Once a target is first crossed, an alert keeps
  notifying on every further move in the user's favor rather than going silent after the first push.
  A repeat only fires once price has moved **at least 1% further** since the *last* notification
  (`REPEAT_ALERT_STEP_PERCENT = 1.0` in `scripts/price_alerts/alerts.py`), not merely still-past-target
  — otherwise it would refire on every 5-minute check while price merely hovers past the line.
  `should_fire_buy`/`should_fire_sell` in that file are the canonical decision logic (pure, no
  Firebase/network imports, unit-tested standalone) — mirror them exactly if you touch the Dart-side
  threshold math (`alertThreshold()`/`isAlertTriggered()`).
  - Buy: fires first at `price <= targetPrice * (1 + tolerancePercent/100)`; each repeat needs
    `price <= lastAlertPrice * (1 - 1%)`. `isActive` no longer flips false on firing (that was the
    old one-shot design) — it now only means "not manually paused/deleted"; repeat-firing is gated
    purely on `lastAlertPrice`.
  - Sell (on `Position`, not a separate entity — see Phase 06 fields on `Position`): fires first at
    `price >= targetPrice`; each repeat needs `price >= lastAlertPrice * (1 + 1%)`.
- **`PriceAlert.copyWith`'s re-arm rule**: editing `targetPrice` or `tolerancePercent`
  (`targetChanged`) resets `isActive = true`, `alertSent = false`, `alertSentAt = null`,
  `lastAlertPrice = null` — otherwise lowering an already-fired alert's target would silently stay
  dormant forever, since nothing else flips `isActive` back on.
- `PositionCard`/`AlertRow` both key their `ListView.builder` items with `key: ValueKey(id)` — see
  §11 #12 for why this matters.

### 15.3 Market status

`domain/entities/market_status.dart` — `MarketStatus(isOpen, label, checkedAt)`, `Equatable`.
`FirestorePaths.marketStatus()` → top-level `market_status/current` doc, written by the Python
backend's `_run_market_status_step` (scrapes the PSX homepage). Client:
`market_status_repository.dart` / `_impl.dart` (`watchStatus()`), wired through
`presentation/dashboard/providers/market_status_providers.dart`'s `watchMarketStatusProvider`.
**`currentlyOpen(MarketStatus?)`** is the freshness gate — returns `null` (not a guess) if the doc is
missing or `checkedAt` is more than 30 minutes old; callers must treat `null` as "don't know," never
infer open/closed from a stale reading. Powers the pulsing green "Live" / red "at Closed" badge on
Transactions and Stock Detail (replaced an older, less useful "fetched N minutes ago" marker).

`FirestorePaths.tickersDoc()` → `tickers/all`, the PSX-listed reference set (symbol + company name)
written by `_run_tickers_refresh_step`, at most once/day (skipped if unchanged from the last write) —
backs the searchable ticker autocomplete (Phase 09) shared by Add Buy, Add Alert, and Favorites.

---

## 16. Live-price backend & external scheduling

### 16.1 Python backend (`scripts/price_alerts/`)

Orchestration/logic split cleanly for testability:

| File | Role |
|---|---|
| `main.py` | Orchestration only, no business logic. `run(db, price_source=None)`: gather held positions + watched alerts → fetch prices (one batched call) → write `market_prices/` → market status step → sell-alert step → buy-alert step → tickers-refresh step. Each step is wrapped so one failing scrape (price/market-status/tickers) doesn't abort the others. |
| `alerts.py` | Pure decision logic — `should_fire_sell`/`should_fire_buy`/`REPEAT_ALERT_STEP_PERCENT` (see §15.2). No Firebase or network imports, deliberately, so it's unit-testable with plain dicts. |
| `firestore_io.py` | All Firestore/FCM I/O — `get_held_positions`, `get_watched_alerts`, `write_market_prices`, `write_market_status`, `get_fcm_token`, `send_push`, `mark_sell_alert_sent`/`mark_buy_alert_sent`, tickers-doc read/write. |
| `price_source.py` | `PsxdataScreenerSource` — scrapes via the `psxdata` package. |
| `market_status_source.py` | Scrapes the PSX homepage for open/closed. |
| `tickers_source.py` | Scrapes the full listed-symbols reference set. |

- `main._normalize_ticker` mirrors the Dart client's `FirestoreDataSource.normalizeTicker`
  (`ticker.strip().upper()`) **exactly** — both sides must agree or the backend writes
  `market_prices/BNL` while the app looks up `market_prices/'BNL '` and finds nothing (this was a
  real bug, since fixed).
- `psxdata`'s `screener()` endpoint — the backend's main price source — **silently omits ~120 real,
  actively-traded PSX equities** (confirmed live: 1016 listed symbols vs. 745 in `screener()`).
  `price_source.py` has a per-ticker historical-price fallback specifically for those.
- **The bulk `psxdata.screener()` call itself is wrapped in its own `try/except`** — a hard
  failure there (network error, PSX briefly down, rate-limited) used to abort price-fetching for
  **every ticker that run**, not just the ones the screener call was responsible for. Confirmed
  as a real bug: two unrelated tickers went stale at the identical timestamp across two
  consecutive runs, which only makes sense if one bulk-call failure silently skipped the whole
  run. On failure it now falls through to an empty `DataFrame` and the per-ticker fallback still
  runs normally for every requested ticker — a bulk failure degrades gracefully instead of
  zeroing out the run. Relatedly, `_fetch_from_history` (the per-ticker fallback every
  screener-absent ticker goes through on **every run**) retries once (~1s pause) before giving
  up, for the same reason — that path is hit every run, not just as a fallback, so it's more
  exposed to a one-off transient failure.
- Push, then flip the flag: `_run_sell_alerts_step`/`_run_buy_alerts_step` send the push **before**
  calling `mark_*_alert_sent` — a flag write failing after a successful send means at most one
  duplicate notification; the reverse order can silently notify nobody.
- Test suite: `scripts/price_alerts/tests/` — `test_alerts.py`, `test_firestore_io.py`, `test_main.py`,
  `test_market_status_source.py`, `test_price_source.py`, `test_tickers_source.py`, with
  `conftest.py`/`fakes.py`/`fixtures/*.json` (real captured screener/symbols data, not synthetic).

### 16.2 The GitHub cron trigger has never actually fired — confirmed, not speculation

`.github/workflows/price-alerts.yml` — the workflow's own comments document a real, verified bug:
**GitHub's `schedule:` trigger has never fired once on this repo**, despite being correctly
configured on the default branch (`main`) — confirmed empirically via the GitHub Actions API across
its entire first eligible day, tested at `*/5`, `*/10` and `*/15` minute intervals, zero
schedule-triggered runs recorded while `workflow_dispatch` worked every single time.

**The actual 5-minute market-hours price refresh is driven externally by a cron-job.org account**
hitting the same workflow's `dispatches` API endpoint directly
(`POST /repos/{owner}/{repo}/actions/workflows/price-alerts.yml/dispatches`) — the identical call
`WorkflowTriggerService` (below) makes on-demand from the app. GitHub's own `schedule:` trigger is
kept only as an unreliable backup, demoted to `*/15` on `main`. `schedule:` only ever fires from
whatever's on the **default branch** (GitHub ignores it on any other branch); `workflow_dispatch`
works from any branch/ref, which is why manual/on-demand runs work regardless of merge state.

Also documented in-file: GitHub auto-disables scheduled workflows after 60 days of zero repo
activity — if this repo goes quiet, the (already-unreliable) schedule stops firing with no error
anywhere in the workflow's own logs. The market-status staleness indicator (§15.3) is the user-facing
mitigation. **See `PLAYSTORE_RELEASE_GUIDE.md` for why this whole chain (personal GitHub account +
personal PAT + a personal cron-job.org account) needs to be treated as real production
infrastructure once this app has actual users, not a side-project detail.**

### 16.3 On-demand trigger from the app

`lib/core/services/workflow_trigger_service.dart` (`WorkflowTriggerService`) + `lib/providers/workflow_trigger_providers.dart` + `lib/data/data_sources/local/secure_token_storage.dart` (`SecureTokenStorage`).

- `SecureTokenStorage` wraps `flutter_secure_storage` (Android Keystore /
  `encryptedSharedPreferences: true`, iOS Keychain) — deliberately **not** Firestore (would sync the
  credential off-device) and **not** Hive (unencrypted at rest). The GitHub PAT is pasted by the user
  in Settings, never committed, never compiled into the APK. A keystore read failure (e.g. after an
  OS restore-to-new-device) degrades to "no token" rather than crashing pull-to-refresh.
- `WorkflowTriggerService.trigger(token)` POSTs to
  `api.github.com/repos/moazzam-samoo/Stock-Book/actions/workflows/price-alerts.yml/dispatches` with
  `ref: 'main'` (hardcoded — an on-demand run always targets the same ref the schedule does, so a
  manual refresh can't silently run different code). Returns a `WorkflowTriggerResult` /
  `WorkflowTriggerOutcome` enum (`queued`/`noToken`/`badToken`/`forbidden`/`notFound`/`networkError`/
  `unknownError`) with a user-safe `.message` per case.
- `workflow_trigger_providers.dart` exposes `secureTokenStorageProvider`,
  `workflowTriggerServiceProvider`, `hasGithubTokenProvider` (drives Settings' saved/not-saved
  indicator), and `triggerWorkflowProvider`.
- Two call sites: **pull-to-refresh on Transactions** (`transactions_screen.dart`), and
  **`AddBuyController`** (fire-and-forget, only on a brand-new position, since a new ticker has no
  `market_prices` doc yet). Settings also has a manual "test connection" button and token save/clear UI.
- **Product-readiness note**: today this only works for whoever's device already has a personal
  GitHub PAT with `Actions: write` on this private repo — i.e. only the developer. See
  `PLAYSTORE_RELEASE_GUIDE.md` item #4 before shipping this to real users; a real user with no token
  just sees "Add a GitHub token in Settings to refresh prices on demand" forever.

---

## 17. Open work

This repo is mid-way through a phased rebuild on the `feat/positions-and-alerts` branch. **Start at
`phases/README.md`** — it's the live index (status table, workflow, per-agent rules) for everything
below, and supersedes the older `target-price-alerts-plan.md` / `IMPLEMENTATION_PLAN.md` at the repo
root (kept for historical context, but `phases/` is where the current, reconciled plan lives).

**All of Phase 00-09 are Done** (`phases/README.md`'s status table) — there is currently no phase
marked "ready but not started." An older revision of this file read "Ready but not started: 05
(push notification infra), 06 (sell-target alert fields), 07 (buy alerts + new screen), 08
(Python/GitHub-Actions backend)" — **no longer accurate**; all four shipped, see §15/§16 below for
what they actually built. Remaining loose ends, per `phases/README.md`'s own per-phase notes:

- Phase 04/04B: uncommitted at review time, awaiting manual check — confirm committed before
  assuming clean.
- Phase 05: iOS still needs 2 manual Xcode/Firebase Console steps + a bundled notification sound
  file; background/terminated states and permission-denial were not separately re-verified beyond
  one real-device manual test (2026-09-05).
- Phase 06: uncommitted at review time, awaiting commit.
- Phase 07: uncommitted at review time.
- Phase 08: needs its 2 manual setup steps done if not already (service-account key + GitHub repo
  secret `FIREBASE_SERVICE_ACCOUNT_JSON`) and the composite Firestore indexes it added were
  "best-effort, unvalidated" per the brief — confirm they actually work rather than assuming.
- **The GitHub Actions cron schedule itself is confirmed non-functional** — see §16.2. Don't treat
  `schedule:` firing as something you can rely on; the real cadence is the external cron-job.org job.

### Phase 04 — live prices

`market_prices/{ticker}` is a **top-level** Firestore collection (not per-user), read-only from the
client (`firestore.rules` has no client write rule — only the Admin SDK, Phase 08, writes here).
`domain/entities/market_price.dart` is the domain entity; `MarketPriceRepository.watchPrice`/
`watchPrices` return it (never the data model — presentation code should never import
`data/models/market_price_model.dart` directly, same rule as everywhere else in this codebase).
`FirestoreDataSource.chunkTickers` is a pure static method Firestore's 30-value `whereIn` cap forces —
call it, don't reinline the chunking logic. `PositionCalculator.unrealizedPL`/`marketValue`/
`unrealizedPLPercent` all return `0.0` (never `null`) for a missing price or a closed position — see
their doc comments. Live price only ever renders on open/partial `PositionCard`s, never the closed
per-buy slices `splitByBuy` produces (there's nothing to mark to market on a position with 0 shares
held). Dashboard tiles are untouched by design — live valuation lives on `PositionCard` and
`StockDetailScreen` only, never folded into "Total Portfolio Value" or any portfolio-wide figure.

### Phase 03A/03B — positions are now the live UI data source

The dashboard, transactions list, stock-detail screen, PDF exports, and the buy/sell/edit flows all
read and write `Position`s now (`PositionCard` replaced `LotCard` everywhere). `lots` still exists,
is never deleted or written to by the position flows, and remains the migration's rollback path — but
new activity after migration only updates `positions`, not `lots`, so **don't assume `lots` is
up to date for anything except the one-time migration and the JSON backup export.**

- `domain/entities/{position,position_buy,position_sale}.dart` — `Position` holds `buys`/`sales` and
  derives everything else; it does not cache `avgCost`/`totalCost` itself. `Position.status` **is**
  stored (not derived) — every write path that mutates `buys`/`sales` must restamp it via
  `PositionCalculator.computeStatus()`, or it goes stale.
- `domain/enums/position_status.dart` — `open`/`partiallySold`/`closed`, same semantic
  `PortfolioCalculator.calculateStockSummaries` already uses per ticker (see §5's per-ticker status
  branch) — a `Position` *is* that per-ticker grouping, so the rule carries over unchanged.
- `domain/calculator/position_calculator.dart` — moving-average cost engine, plus the write-path
  helpers every buy/sell/edit flow should go through rather than reimplementing:
  - `applyBuy(position, ...)` — appends a `PositionBuy`, clears `closedAt`, restamps `status`.
  - `applySell(position, ...)` — appends a `PositionSale` with `costBasisAtSale` frozen to the
    position's **current** `avgCost` at the moment of the call — never recomputed later. Restamps
    `status`/`closedAt`.
  - `findOpenPosition(positions, ticker)` — the "append to the open position, or start a new one"
    check `AddBuyController` uses. A closed position for a ticker never gets reopened; a fresh buy on
    an already-fully-sold ticker starts a brand-new `Position` (deliberate — see PHASE-03A's review).
  - `computeStatus(position)` — the shared open/partial/closed rule; call this after any manual
    `buys`/`sales` mutation instead of hand-rolling the three-way check.
  - **`avgCost()`, `totalCost()` and `amountInvested()` all derive from one private
    `_preciseTotalCost()` helper — never call `sharesHeld(p) * avgCost(p)` yourself.** `avgCost()`
    rounds to 2dp before it returns; multiplying through that already-rounded value compounds error
    (verified: $4.41 off on a $12,724 position in the reference scenario before this was fixed). If
    you add a new derived figure to `Position`, derive it from `_preciseTotalCost()`, not from
    `avgCost()`'s return value.
  - **A sale's realized P/L must always read `PositionSale.realizedPL`** (which uses
    `costBasisAtSale`), never recompute it against the position's current `avgCost` — a later buy
    would silently change an already-booked sale's displayed profit. This was a real bug found and
    fixed in `position_sale_row.dart` during the 03B review; don't reintroduce it elsewhere.
  - **`avgCost()`/`amountInvested()` return 0 for a closed position** — correct ("what am I still
    holding"), but useless on any UI that records what *happened*. Use `historicalAvgCost()` /
    `totalCapitalDeployed()` / `totalSharesBought()` there, as `PositionCard` does. Anything dividing
    by `avgCost` must guard against a closed position too, or it renders `Infinity%`.
  - `blendedAvgCost(List<Position>)` is the per-ticker average across cycles, for the dashboard's
    one-row-per-ticker view. It sums unrounded cost and rounds once — don't rebuild it by summing
    `amountInvested`.
  - `splitByBuy(Position)` breaks a **closed** cycle into one display position per buy (sales
    attributed FIFO, share counts and realized P/L both conserved) — that's how closed history renders
    as separate cards while what you still hold stays pooled in one averaged card. **Its output is
    display-only**: synthetic `<positionId>::<buyId>` ids and possibly-partial sale slices. Never
    persist one — `PositionCard.writePosition` carries the real document for delete/edit, and
    `PositionSaleRow.readOnly` blocks editing a slice of a sale. Open and partial positions come back
    untouched; pooling them is the averaging feature, not a bug to fix.
- `domain/calculator/portfolio_calculator.dart` — `calculatePortfolioSummaryFromPositions` and
  `calculateStockSummariesFromPositions` are the position-based siblings of the original lot-based
  functions, kept side by side (the lot-based ones are still the verification reference — Phase 00's
  characterisation test locks them). `StockSummary.status` is still typed `LotStatus` (that entity
  predates positions), so the aggregate status is built as a `LotStatus` directly.
  **`calculateStockSummariesFromPositions` returns one row per *ticker*, not per position** — a ticker
  sold out and re-bought has several cycles and must still show once. Closed cycles keep contributing
  their realized P/L; **hiding sold-out tickers is `dashboard_screen.dart`'s job** (it filters
  `sharesHeld > 0` for the "Your Stocks" list only), because `exportOverallPortfolioPdf` and
  `MetricDetailCard` read the same list and need it complete.
- **`openLots` means something different depending on which summary you're looking at, by design.**
  From lots, it counts individual open/partial *lots*. From positions, it counts open/partial
  *positions*. A ticker with two lots — one fully sold, one still open — is 1 open lot pre-migration
  but folds into 1 still-open position either way; the divergent case is a ticker where **both** lots
  are non-closed individually but merge into a single position (2 open lots → 1 open position). This
  is the intended effect of the merge feature, not a bug — see
  `test/domain/calculator/dashboard_position_parity_test.dart` for the worked example.
  `MetricDetailCard`'s "Open Lots" drill-down still counts raw lots (deliberately left alone per the
  "keep the lot-based functions, add position equivalents alongside" rule), so that one panel can show
  a different count than the dashboard's stat card — also expected.
- **`StatusBadge` (`presentation/common/badges.dart`) takes a `dynamic status`** and switches on three
  different enums. A `PositionStatus` once fell straight through its unrecognised-type fallback to
  `TradeStatus.open`, with no compile error — every position in the app rendered a green OPEN badge,
  fully-sold ones included, for the whole of Phase 03B. There is now an `assert` on that fallback.
  If you pass a new enum in, add a branch; never rely on the default.
- **A ticker has at most one non-closed position at a time.** `findOpenPosition` + `applyBuy` maintain
  that, and the "one row per ticker" grouping assumes it. Two open positions for one ticker is a data
  bug worth reporting, not something to handle in the UI. Note `edit_buy_bottom_sheet.dart` still lets
  the *ticker* be edited, which could break this — an open question, not yet resolved.
- `domain/calculator/position_migration.dart` — builds `Position`s from existing `Lot`s and
  verifies the result three independent ways (realized P/L, amount invested, **and shares held per
  ticker** — all three are required; amount-invested alone can't catch a share-count corruption that
  still leaves `shares × avgCost` looking plausible). `MigrationResult.isValid == false` must never
  be persisted — `PositionMigrationRunner` enforces that.
- `data/migration/position_migration_runner.dart` runs once per account, triggered from
  `DashboardScreen.initState()` (not literally "after sign-in" as PHASE-03B specified, but low-risk:
  `SwipeableNavigationShell`'s `PageView` keeps all three tabs mounted for the whole app session, so
  this only fires once). Reads/writes `users/{uid}.schemaVersion`; `>= 2` means migrated.
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

---

## 18. Account deletion, release signing & legal pages

### 18.1 Account deletion (Play Store Account Deletion policy requirement)

`domain/repositories/auth_repository.dart` — `deleteAccount()` added to the interface (doc
comment states the contract: deletes all Firestore data + the Firebase Auth account, and
implementations must handle `requires-recent-login` by re-authenticating rather than
surfacing the raw error).

`data/repositories/firebase_auth_repository.dart`'s `deleteAccount()`:

- Deletes Firestore data **before** `user.delete()` — required, since `firestore.rules` gates
  every write on `request.auth.uid == userId`, which stops being true the instant the auth
  account itself is gone. Clears (via `firestore.batch()` per collection, `Future.wait` in
  parallel): `lots`, `positions`, `price_alerts`, `withdrawals`, then the `settings` doc and
  the `users/{uid}` doc itself. `lots/{id}/sales` is deliberately excluded — nothing writes
  there (§4.1).
- On `FirebaseAuthException(code: 'requires-recent-login')` (a stale session — Firebase
  requires a fresh credential for destructive account operations), it re-runs Google Sign-In
  via `_reauthenticate()`, then **retries both steps** (Firestore delete + `user.delete()`).
  Safe to re-run: every delete here is idempotent (deleting an already-absent doc is a no-op).
  If the user cancels the re-auth Google picker, throws a user-facing
  `AuthException('Re-authentication was cancelled...')`.
- `AuthController.deleteAccount()` — deliberately has **no timeout** unlike
  `signInWithGoogle`/`signOut` (both 15s), since a re-authentication round trip (picking a
  Google account again) could exceed a fixed budget on a slow connection. Wrapped in
  `AsyncValue.guard`, so a thrown `AuthException` never propagates to the caller — it surfaces
  as controller error state instead. Covered by
  `test/presentation/auth/controllers/auth_controller_test.dart` (hand-written fake
  `AuthRepository`, not Mockito).
- UI flow (`settings_screen.dart`'s `_confirmDeleteAccount`) is **two-step**: a first
  yes/no `AlertDialog` warning what gets deleted, then `_DeleteAccountTypeToConfirmDialog`
  requiring the user to type the literal word `DELETE` (case-sensitive, trimmed) before the
  "Delete Permanently" button enables. On success, no manual navigation — the auth state
  stream emits `null` and the router's existing redirect logic sends the user to `/sign-in`
  on its own. On failure, the error is read straight off `authControllerProvider.error` and
  shown in a snackbar.

### 18.2 Release signing

`android/app/build.gradle.kts` reads `android/key.properties` (gitignored; template at
`key.properties.example`) when present — `keyAlias`/`keyPassword`/`storeFile`/`storePassword`
feed a real `signingConfigs.create("release")`. Falls back to the **debug** keystore, not a
build error, when the file is absent (keeps `flutter run --release` working for local dev
before the file exists). **See §11 #15 — verify `signingConfig` resolves to `"release"`
before any Play Store upload; there's no automatic guard against shipping debug-signed.**
A real upload keystore has since been generated and `key.properties` filled in locally — it
is not and will never be committed.

### 18.3 Legal pages (GitHub Pages)

`docs/privacy-policy.html` and `docs/account-deletion.html`, published via GitHub
Pages from this repo's `/docs` folder on `main`. **This is the concrete reason the repo must
stay public on the free GitHub plan** — private-repo Pages requires a paid GitHub plan (also
relevant to §16.2's context for why the repo is public). URLs are centralized in
`core/constants/legal_links.dart` (`LegalLinks.privacyPolicy`, `LegalLinks.accountDeletion`)
— `sign_in_screen.dart` links Privacy Policy; the privacy policy page itself links onward
to the account-deletion page, and both name **Moazzam Samoo** and **Kheeraj Das** as the
app's owners with a contact email. If GitHub Pages isn't enabled (Settings → Pages → Source:
`main` / `/docs`) these URLs 404 — nothing in the app detects or warns about that.

See also `PLAYSTORE_RELEASE_GUIDE.md` for the full, regularly re-audited Play Store readiness
checklist (signed builds, Data Safety form, store listing assets, the still-open on-demand
refresh issue).
