import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:stock_investment_tracker/presentation/dashboard/screens/dashboard_screen.dart';
import 'package:stock_investment_tracker/presentation/transactions/screens/transactions_screen.dart';
import 'package:stock_investment_tracker/presentation/settings/screens/settings_screen.dart';
import 'package:stock_investment_tracker/domain/entities/portfolio_summary.dart';
import 'package:stock_investment_tracker/presentation/dashboard/providers/dashboard_providers.dart';
import 'package:stock_investment_tracker/presentation/transactions/providers/transactions_providers.dart';
import 'package:stock_investment_tracker/presentation/auth/providers/auth_providers.dart';
import 'package:stock_investment_tracker/presentation/dashboard/screens/stock_detail_screen.dart';
import 'package:stock_investment_tracker/domain/entities/lot.dart';
import 'package:stock_investment_tracker/presentation/transactions/widgets/lot_card.dart';
import 'package:stock_investment_tracker/core/theme/app_theme.dart';

// Catches the specific failure mode a golden-image diff CANNOT catch: text
// that was already invisible-on-its-surface the moment the golden master was
// captured. A pixel diff only flags CHANGES from that master, so a baseline
// captured with white-on-white text would pass forever.
//
// Resolves each text run's *actual local background* by walking up its
// render-object ancestry to the nearest opaque painted surface (a
// DecoratedBox with a solid color, or a Material with one) and compares
// luminance against that — not against a single app-wide assumption. That
// distinction matters concretely here: TickerAvatar deliberately renders
// white text on saturated ticker-color circles (see
// lib/presentation/common/ticker_avatar.dart's isLightBg check), which is
// correct contrast against ITS background, not a bug. A blanket "flag all
// near-white text" rule flags that as a false positive; this doesn't.
void main() {
  const kMinLuminanceDelta = 0.05;

  void mockConnectivity() {
    const channel = MethodChannel('dev.fluttercommunity.plus/connectivity');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'check') return ['wifi'];
      return null;
    });
    const eventChannel = EventChannel('dev.fluttercommunity.plus/connectivity_status');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(eventChannel, MockStreamHandler.inline(
      onListen: (arguments, events) => events.success(['wifi']),
    ));
  }

  setUpAll(() async {
    mockConnectivity();
    GoogleFonts.config.allowRuntimeFetching = false;
    await loadAppFonts();
  });

  Widget buildLightScreen(Widget child) {
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
        themeMode: ThemeMode.light,
        home: child,
      ),
    );
  }

  /// Walks up from [start] to the nearest ancestor that paints an opaque
  /// solid-color background, returning that color. Falls back to
  /// [AppTheme.lightTheme]'s scaffold background if none is found (the
  /// outermost, ultimate backdrop every screen sits on).
  Color resolveLocalBackground(RenderObject start) {
    RenderObject? node = start;
    while (node != null) {
      if (node is RenderDecoratedBox) {
        final decoration = node.decoration;
        if (decoration is BoxDecoration && decoration.color != null && decoration.color!.alpha == 255) {
          return decoration.color!;
        }
      }
      if (node is RenderPhysicalModel && node.color.alpha == 255) {
        return node.color;
      }
      node = node.parent;
    }
    return AppTheme.lightTheme.scaffoldBackgroundColor;
  }

  /// Walks every currently-rendered [RichText] node, resolves each run's
  /// actual local background, and returns the (textColor, backgroundColor,
  /// luminanceDelta) triples whose contrast is too low to read.
  List<(Color text, Color background, double delta)> collectLowContrastRuns(WidgetTester tester) {
    final offenders = <(Color, Color, double)>[];

    void checkSpan(InlineSpan span, RenderObject anchor) {
      if (span is TextSpan) {
        final color = span.style?.color;
        if (color != null) {
          final bg = resolveLocalBackground(anchor);
          final delta = (color.computeLuminance() - bg.computeLuminance()).abs();
          if (delta < kMinLuminanceDelta) {
            offenders.add((color, bg, delta));
          }
        }
        span.children?.forEach((child) => checkSpan(child, anchor));
      }
    }

    for (final element in tester.elementList(find.byType(RichText))) {
      final renderObject = element.renderObject;
      if (renderObject is RenderParagraph) {
        checkSpan(renderObject.text, renderObject);
      }
    }
    return offenders;
  }

  void expectNoInvisibleText(WidgetTester tester, String screenName) {
    final richTextCount = tester.elementList(find.byType(RichText)).length;
    expect(richTextCount, greaterThan(0), reason: '$screenName rendered no text at all — harness problem, not a real pass');

    final offenders = collectLowContrastRuns(tester);
    expect(
      offenders,
      isEmpty,
      reason: '$screenName has ${offenders.length} text run(s) with less than '
          '${(kMinLuminanceDelta * 100).toStringAsFixed(0)}% luminance contrast against their own local '
          'background in light mode: $offenders — this text would be hard or impossible to read.',
    );
  }

  // Matches golden_toolkit's Device.phone (375x667) so results are
  // consistent with the goldens in theme_golden_test.dart rather than
  // whatever flutter_test's default surface happens to be.
  const phoneSize = Size(375, 667);

  testWidgets('Dashboard: no near-invisible text in light mode', (tester) async {
    await tester.binding.setSurfaceSize(phoneSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildLightScreen(const DashboardScreen()));
    await tester.pumpAndSettle();
    expectNoInvisibleText(tester, 'Dashboard');
  });

  testWidgets('Transactions: no near-invisible text in light mode', (tester) async {
    await tester.binding.setSurfaceSize(phoneSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildLightScreen(const TransactionsScreen()));
    await tester.pumpAndSettle();
    expectNoInvisibleText(tester, 'Transactions');
  });

  testWidgets('Settings: no near-invisible text in light mode', (tester) async {
    await tester.binding.setSurfaceSize(phoneSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildLightScreen(const SettingsScreen()));
    await tester.pumpAndSettle();
    expectNoInvisibleText(tester, 'Settings');
  });

  testWidgets('Lot card: no near-invisible text in light mode', (tester) async {
    await tester.binding.setSurfaceSize(phoneSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
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
    await tester.pumpWidget(buildLightScreen(
      Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: LotCard(lot: dummyLot))),
    ));
    await tester.pumpAndSettle();
    expectNoInvisibleText(tester, 'Lot card');
  });

  testWidgets('Stock detail: no near-invisible text in light mode', (tester) async {
    await tester.binding.setSurfaceSize(phoneSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildLightScreen(const StockDetailScreen(ticker: 'ENGRO')));
    await tester.pumpAndSettle();
    expectNoInvisibleText(tester, 'Stock detail');
  });
}
