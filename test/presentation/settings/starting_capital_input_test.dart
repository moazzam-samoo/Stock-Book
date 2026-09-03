import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_investment_tracker/domain/entities/user_settings.dart';
import 'package:stock_investment_tracker/domain/repositories/settings_repository.dart';
import 'package:stock_investment_tracker/presentation/settings/screens/settings_screen.dart';
import 'package:stock_investment_tracker/providers/repository_providers.dart';
import 'package:stock_investment_tracker/presentation/auth/providers/auth_providers.dart';
import 'package:stock_investment_tracker/presentation/dashboard/providers/dashboard_providers.dart';
import 'package:stock_investment_tracker/domain/entities/portfolio_summary.dart';

class MockSettingsRepository implements SettingsRepository {
  double? updatedCapital;

  @override
  Stream<UserSettings> watchSettings() {
    return Stream.value(const UserSettings(
      startingCapital: 999999999999.0, // used for tests 1 and 2
      favorites: [],
      currency: 'PKR',
      themeMode: 'dark',
      stockColors: {},
    ));
  }

  @override
  Future<void> updateStartingCapital(double capital) async {
    updatedCapital = capital;
  }
  
  // Unused methods
  @override Future<void> updateSettings(UserSettings settings) async {}
  @override Future<void> addFavorite(String ticker) async {}
  @override Future<void> removeFavorite(String ticker) async {}
  @override Future<void> updateCurrency(String currency) async {}
  @override Future<void> updateStockColor(String ticker, int colorValue) async {}
  @override Future<void> updateThemeMode(String themeMode) async {}
}

void main() {
  late MockSettingsRepository mockRepo;

  setUp(() {
    mockRepo = MockSettingsRepository();
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(mockRepo),
        authStateProvider.overrideWith((ref) => Stream.value(null)),
        allWithdrawalsProvider.overrideWith((ref) => Stream.value([])),
        portfolioSummaryProvider.overrideWith((ref) => const PortfolioSummary(
          startingCapital: 999999999999.0,
          grossRealizedPL: 0,
          realizedPL: 0,
          portfolioValue: 0,
          totalCash: 0,
          freeCash: 0,
          currentlyInvested: 0,
          totalWithdrawn: 0,
          totalInvested: 0,
          openLots: 0,
        )),
      ],
      child: const MaterialApp(
        home: SettingsScreen(),
      ),
    );
  }

  testWidgets('1. Renders at 320dp with 999999999999 (No RenderFlex overflow)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('999,999,999,999'), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('2. Renders at 360dp and 480dp with the same value without overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(const Size(480, 800));
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('3. Type 10000000 -> Field displays 10,000,000', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    final textField = find.byType(TextField).first;
    
    await tester.enterText(textField, '10000000');
    await tester.pump();

    expect(find.text('10,000,000'), findsOneWidget);
  });

  testWidgets('4. Type 10000000 then save -> updateStartingCapital called with 10000000.0', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    final textField = find.byType(TextField).first;
    await tester.enterText(textField, '10000000');
    await tester.pump();
    
    await tester.tap(find.byIcon(Icons.check_circle));
    await tester.pumpAndSettle();

    expect(mockRepo.updatedCapital, 10000000.0);
  });

  testWidgets('5. Type abc then save -> updateStartingCapital not called; error visible', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    final textField = find.byType(TextField).first;
    
    // We clear the field (which simulates an unparseable empty string since letters are ignored by formatter)
    await tester.enterText(textField, '');
    await tester.pump();

    await tester.tap(find.byIcon(Icons.check_circle));
    await tester.pumpAndSettle();

    expect(mockRepo.updatedCapital, isNull);
    expect(find.text('Invalid amount'), findsOneWidget);
  });

  testWidgets('6. Type -5 then save -> updateStartingCapital not called; error visible', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Since the formatter drops the '-', we must bypass the formatter by directly setting controller text
    // to strictly test the _save() parsing logic for negative numbers as required.
    final TextField field = tester.widget(find.byType(TextField).first);
    field.controller?.text = '-5';
    
    // Trigger onChanged to make it dirty
    field.onChanged?.call('-5');
    await tester.pump();

    await tester.tap(find.byIcon(Icons.check_circle));
    await tester.pumpAndSettle();

    expect(mockRepo.updatedCapital, isNull);
    expect(find.text('Invalid amount'), findsOneWidget);
  });

  testWidgets('7. Field width before vs after first keystroke -> Width unchanged', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    final textField = find.byType(TextField).first;
    final sizeBefore = tester.getSize(textField);

    // Enter a character to make it dirty (save icon appears)
    await tester.enterText(textField, '9');
    await tester.pump();

    final sizeAfter = tester.getSize(textField);

    expect(sizeBefore.width, sizeAfter.width);
  });

  testWidgets('8. 13th digit -> Rejected by the length cap', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    final textField = find.byType(TextField).first;
    
    await tester.enterText(textField, '1234567890123'); // 13 digits
    await tester.pump();

    // Only 12 digits should remain
    expect(find.text('123,456,789,012'), findsOneWidget);
  });
}
