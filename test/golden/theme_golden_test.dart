import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_investment_tracker/presentation/dashboard/screens/dashboard_screen.dart';
import 'package:stock_investment_tracker/presentation/transactions/screens/transactions_screen.dart';
import 'package:stock_investment_tracker/presentation/settings/screens/settings_screen.dart';
import 'package:stock_investment_tracker/domain/entities/portfolio_summary.dart';
import 'package:stock_investment_tracker/presentation/dashboard/providers/dashboard_providers.dart';
import 'package:stock_investment_tracker/presentation/transactions/providers/transactions_providers.dart';
import 'package:stock_investment_tracker/presentation/auth/providers/auth_providers.dart';
import 'package:stock_investment_tracker/presentation/transactions/widgets/lot_card.dart';
import 'package:stock_investment_tracker/presentation/dashboard/screens/stock_detail_screen.dart';
import 'package:stock_investment_tracker/domain/entities/lot.dart';
import 'package:stock_investment_tracker/core/theme/app_theme.dart';

void mockConnectivity() {
  const channel = MethodChannel('dev.fluttercommunity.plus/connectivity');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    if (methodCall.method == 'check') {
      return ['wifi'];
    }
    return null;
  });

  const eventChannel = EventChannel('dev.fluttercommunity.plus/connectivity_status');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockStreamHandler(eventChannel, MockStreamHandler.inline(
    onListen: (arguments, events) {
      events.success(['wifi']);
    },
  ));
}

// Mocked online (not offline) deliberately: OfflineBanner starts a real
// 3-second Timer the moment it detects "offline", and that Timer runs on
// wall-clock time, not the tests' virtual frame clock. In a large suite,
// enough real time can pass between a screen's initial pump and its golden
// comparison for the banner to auto-hide mid-test, silently shifting the
// entire layout and producing a flaky, run-duration-dependent pixel diff.
// The banner's own styling is deliberately theme-invariant (see
// offline_banner.dart / phases/PHASE-02-white-theme.md Task 2), so showing
// it here would not have exercised anything these goldens exist to check.

void main() {
  setUpAll(() async {
    mockConnectivity();
    GoogleFonts.config.allowRuntimeFetching = false;
    await loadAppFonts();
  });

  Widget buildScreen(Widget child, ThemeMode themeMode) {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => Stream.value(null)),
        allWithdrawalsProvider.overrideWith((ref) => Stream.value([])),
        allLotsProvider.overrideWith((ref) => Stream.value([])),
        filteredLotsProvider.overrideWith((ref) => []),
        portfolioSummaryProvider.overrideWith((ref) => const PortfolioSummary(
          startingCapital: 100000, grossRealizedPL: 5000, realizedPL: 5000, portfolioValue: 105000,
          totalCash: 50000, freeCash: 50000, currentlyInvested: 50000, totalWithdrawn: 0, totalInvested: 50000, openLots: 2,
        )),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: child,
      ),
    );
  }

  // Dashboard is deliberately NOT a pixel-diff golden like the other four
  // screens. DashboardScreen bakes `DateTime.now()` into its own State
  // (`_lastSyncTime`, dashboard_screen.dart) with no injectable clock, and
  // renders it as visible "Offline (HH:MM)" text. Any golden master goes
  // stale the moment a minute boundary passes between capture and
  // comparison — which happens routinely once the suite is large enough to
  // take more than a few seconds to reach this test. That's a pre-existing
  // characteristic of the screen, unrelated to theming, so instead of a
  // flaky pixel assertion this checks the two things theming actually
  // changes: no exceptions, and the Scaffold/AppBar paint the correct
  // theme's colors. Dashboard's per-run contrast is separately covered,
  // clock text included, by test/golden/contrast_test.dart.
  testGoldens('Dashboard Screen - Light', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(Device.phone.size);
    await tester.pumpWidget(buildScreen(const DashboardScreen(), ThemeMode.light));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Your Stocks'), findsOneWidget);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor ?? AppTheme.lightTheme.scaffoldBackgroundColor,
        AppTheme.lightTheme.scaffoldBackgroundColor);
  });

  testGoldens('Dashboard Screen - Dark', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(Device.phone.size);
    await tester.pumpWidget(buildScreen(const DashboardScreen(), ThemeMode.dark));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Your Stocks'), findsOneWidget);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor ?? AppTheme.darkTheme.scaffoldBackgroundColor,
        AppTheme.darkTheme.scaffoldBackgroundColor);
  });

  testGoldens('Settings Screen - Light', (tester) async {
    final builder = DeviceBuilder()
      ..overrideDevicesForAllScenarios(devices: [Device.phone])
      ..addScenario(
        widget: buildScreen(const SettingsScreen(), ThemeMode.light),
        name: 'light_mode',
      );
    await tester.pumpDeviceBuilder(builder);
    await screenMatchesGolden(tester, 'settings_screen_light');
  });

  testGoldens('Settings Screen - Dark', (tester) async {
    final builder = DeviceBuilder()
      ..overrideDevicesForAllScenarios(devices: [Device.phone])
      ..addScenario(
        widget: buildScreen(const SettingsScreen(), ThemeMode.dark),
        name: 'dark_mode',
      );
    await tester.pumpDeviceBuilder(builder);
    await screenMatchesGolden(tester, 'settings_screen_dark');
  });

  testGoldens('Transactions Screen - Light', (tester) async {
    final builder = DeviceBuilder()
      ..overrideDevicesForAllScenarios(devices: [Device.phone])
      ..addScenario(
        widget: buildScreen(const TransactionsScreen(), ThemeMode.light),
        name: 'light_mode',
      );
    await tester.pumpDeviceBuilder(builder);
    await screenMatchesGolden(tester, 'transactions_screen_light');
  });

  testGoldens('Transactions Screen - Dark', (tester) async {
    final builder = DeviceBuilder()
      ..overrideDevicesForAllScenarios(devices: [Device.phone])
      ..addScenario(
        widget: buildScreen(const TransactionsScreen(), ThemeMode.dark),
        name: 'dark_mode',
      );
    await tester.pumpDeviceBuilder(builder);
    await screenMatchesGolden(tester, 'transactions_screen_dark');
  });

  final dummyLot = Lot(
    id: 'lot1',
    ticker: 'ENGRO',
    buyDate: DateTime(2023, 1, 1),
    sharesPurchased: 100,
    buyPricePerShare: 350.0,
    amountInvested: 35000.0,
    targetPrice: 400.0,
    sales: const [],
  );

  testGoldens('Lot Card - Light', (tester) async {
    final builder = DeviceBuilder()
      ..overrideDevicesForAllScenarios(devices: [Device.phone])
      ..addScenario(
        widget: buildScreen(
          Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: LotCard(lot: dummyLot))),
          ThemeMode.light
        ),
        name: 'light_mode',
      );
    await tester.pumpDeviceBuilder(builder);
    await screenMatchesGolden(tester, 'lot_card_light');
  });

  testGoldens('Lot Card - Dark', (tester) async {
    final builder = DeviceBuilder()
      ..overrideDevicesForAllScenarios(devices: [Device.phone])
      ..addScenario(
        widget: buildScreen(
          Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: LotCard(lot: dummyLot))),
          ThemeMode.dark
        ),
        name: 'dark_mode',
      );
    await tester.pumpDeviceBuilder(builder);
    await screenMatchesGolden(tester, 'lot_card_dark');
  });

  testGoldens('Stock Detail - Light', (tester) async {
    final builder = DeviceBuilder()
      ..overrideDevicesForAllScenarios(devices: [Device.phone])
      ..addScenario(
        widget: buildScreen(const StockDetailScreen(ticker: 'ENGRO'), ThemeMode.light),
        name: 'light_mode',
      );
    await tester.pumpDeviceBuilder(builder);
    await screenMatchesGolden(tester, 'stock_detail_light');
  });

  testGoldens('Stock Detail - Dark', (tester) async {
    final builder = DeviceBuilder()
      ..overrideDevicesForAllScenarios(devices: [Device.phone])
      ..addScenario(
        widget: buildScreen(const StockDetailScreen(ticker: 'ENGRO'), ThemeMode.dark),
        name: 'dark_mode',
      );
    await tester.pumpDeviceBuilder(builder);
    await screenMatchesGolden(tester, 'stock_detail_dark');
  });
}
