import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_investment_tracker/domain/entities/ticker_info.dart';
import 'package:stock_investment_tracker/domain/entities/user_settings.dart';
import 'package:stock_investment_tracker/presentation/settings/providers/settings_provider.dart';
import 'package:stock_investment_tracker/presentation/transactions/widgets/ticker_autocomplete.dart';
import 'package:stock_investment_tracker/providers/ticker_providers.dart';

void main() {
  group('TickerAutocomplete Widget', () {
    late TextEditingController controller;
    late FocusNode focusNode;
    String? selectedValue;

    setUp(() {
      controller = TextEditingController();
      focusNode = FocusNode();
      selectedValue = null;
    });

    tearDown(() {
      controller.dispose();
      focusNode.dispose();
    });

    Widget buildTestWidget({
      required List<TickerInfo> allTickers,
      required List<String> favorites,
    }) {
      return ProviderScope(
        overrides: [
          allTickersProvider.overrideWith((ref) => allTickers),
          // settingsProvider is a @riverpod Stream<UserSettings> function, so
          // overrideWith needs a Stream, not an AsyncValue — that mismatch
          // was a compile error blocking this entire file from loading.
          settingsProvider.overrideWith((ref) => Stream.value(
                UserSettings(
                  favorites: favorites,
                  startingCapital: 100000,
                  currency: 'PKR',
                  themeMode: 'dark',
                  stockColors: const {},
                ),
              )),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: TickerAutocomplete(
              controller: controller,
              focusNode: focusNode,
              onSelected: (val) {
                selectedValue = val;
              },
            ),
          ),
        ),
      );
    }

    final testTickers = [
      const TickerInfo(symbol: 'SYS', name: 'Systems Limited', sector: 'Tech'),
      const TickerInfo(symbol: 'ENGRO', name: 'Engro Corp', sector: 'Fertilizer'),
      const TickerInfo(symbol: 'EFERT', name: 'Engro Fertilizers', sector: 'Fertilizer'),
      const TickerInfo(symbol: 'UBL', name: 'United Bank Limited', sector: 'Bank'),
    ];

    testWidgets('Searching by symbol substring', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        allTickers: testTickers,
        favorites: [],
      ));

      await tester.enterText(find.byType(TextField), 'sys');
      await tester.pumpAndSettle();

      expect(find.text('SYS'), findsOneWidget);
      expect(find.text('Systems Limited'), findsOneWidget);
    });

    testWidgets('Searching by company name substring', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        allTickers: testTickers,
        favorites: [],
      ));

      await tester.enterText(find.byType(TextField), 'united');
      await tester.pumpAndSettle();

      expect(find.text('UBL'), findsOneWidget);
      expect(find.text('United Bank Limited'), findsOneWidget);
    });

    testWidgets('A favorited ticker among the matches sorts first', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        allTickers: testTickers,
        favorites: ['EFERT'],
      ));

      await tester.enterText(find.byType(TextField), 'engro');
      await tester.pumpAndSettle();

      // ENGRO and EFERT should match. EFERT is favorited, so it should be first.
      final listTiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
      expect(listTiles.length, 2);
      
      final firstTileText = ((listTiles[0].title) as Text).data;
      final secondTileText = ((listTiles[1].title) as Text).data;
      
      expect(firstTileText, 'EFERT');
      expect(secondTileText, 'ENGRO');
    });

    testWidgets('No full list loaded yet falls back to Favorites-only search, no crash', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        allTickers: [], // Empty list simulates not loaded yet
        favorites: ['SYS', 'EFERT'],
      ));

      await tester.enterText(find.byType(TextField), 's');
      await tester.pumpAndSettle();

      expect(find.text('SYS'), findsOneWidget);
      expect(find.text('Systems Limited'), findsNothing); // No full list, no name lookup
    });

    testWidgets('Widget: typing a company name and selecting fills the ticker field', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        allTickers: testTickers,
        favorites: [],
      ));

      await tester.enterText(find.byType(TextField), 'united');
      await tester.pumpAndSettle();

      await tester.tap(find.text('UBL'));
      await tester.pumpAndSettle();

      expect(selectedValue, 'UBL');
    });
  });
}
