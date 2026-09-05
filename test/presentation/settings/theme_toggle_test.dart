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
  String updatedTheme = '';

  @override
  Stream<UserSettings> watchSettings() {
    return Stream.value(const UserSettings(
      startingCapital: 0,
      favorites: [],
      currency: 'PKR',
      themeMode: 'dark',
      stockColors: {},
    ));
  }

  @override Future<void> updateThemeMode(String themeMode) async {
    updatedTheme = themeMode;
  }
  
  // Unused methods
  @override Future<void> updateSettings(UserSettings settings) async {}
  @override Future<void> addFavorite(String ticker) async {}
  @override Future<void> removeFavorite(String ticker) async {}
  @override Future<void> updateCurrency(String currency) async {}
  @override Future<void> updateStockColor(String ticker, int colorValue) async {}
  @override Future<void> updateStartingCapital(double capital) async {}
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
          startingCapital: 0, grossRealizedPL: 0, realizedPL: 0, portfolioValue: 0,
          totalCash: 0, freeCash: 0, currentlyInvested: 0, totalWithdrawn: 0, totalInvested: 0, openLots: 0,
        )),
      ],
      child: const MaterialApp(
        home: SettingsScreen(),
      ),
    );
  }

  testWidgets('Toggle persists -> updateThemeMode called with the exact string', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    final dropdowns = find.byType(DropdownButton<String>);
    // The second dropdown is Theme
    expect(dropdowns, findsNWidgets(2));
    
    await tester.tap(dropdowns.last);
    await tester.pumpAndSettle();
    
    // Tap 'Light'
    await tester.tap(find.text('Light').last);
    await tester.pumpAndSettle();

    expect(mockRepo.updatedTheme, 'light');
    
    await tester.tap(dropdowns.last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('System').last);
    await tester.pumpAndSettle();
    expect(mockRepo.updatedTheme, 'system');
  });
}
