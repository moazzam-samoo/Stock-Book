import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/core/services/data_export_service.dart';
import 'package:stock_investment_tracker/domain/entities/lot.dart';
import 'package:stock_investment_tracker/domain/entities/sale.dart';
import 'package:stock_investment_tracker/domain/entities/user_settings.dart';
import 'package:stock_investment_tracker/domain/entities/withdrawal.dart';
import 'package:stock_investment_tracker/domain/enums/lot_status.dart';

void main() {
  group('DataExportService', () {
    final sampleLots = [
      Lot(
        id: 'lot-1',
        ticker: 'STPL',
        buyDate: DateTime.utc(2026, 9, 3, 12),
        sharesPurchased: 500,
        buyPricePerShare: 8.73,
        amountInvested: 4365.0,
        targetPrice: 10.00,
        status: LotStatus.partiallySold,
        sharesRemaining: 300,
        amountInvestedRemaining: 2619.0,
        realizedProfitLoss: 54.0,
        sales: [
          Sale(
            id: 'sale-1',
            sellDate: DateTime.utc(2026, 9, 4, 12),
            sharesSold: 200,
            sellPricePerShare: 9.0,
            amountReceived: 1800.0,
          )
        ],
      ),
      Lot(
        id: 'lot-2',
        ticker: 'ENGRO',
        buyDate: DateTime.utc(2026, 9, 1, 10),
        sharesPurchased: 300,
        buyPricePerShare: 350.0,
        amountInvested: 105000.0,
        targetPrice: null,
      )
    ];

    final sampleWithdrawals = [
      Withdrawal(id: 'w-1', date: DateTime.utc(2026, 9, 2), amount: 15000.0, note: 'w note'),
    ];

    const sampleSettings = UserSettings(
      favorites: ['STPL'],
      startingCapital: 500000.0,
      currency: 'PKR',
      themeMode: 'dark',
      stockColors: {'STPL': 0xFFFF0000},
    );

    test('round-trip export parses back to identical values', () async {
      final jsonString = await DataExportService.buildExportJson(
        lots: sampleLots,
        withdrawals: sampleWithdrawals,
        settings: sampleSettings,
      );

      final Map<String, dynamic> decoded = jsonDecode(jsonString) as Map<String, dynamic>;

      expect(decoded['schemaVersion'], 1);
      expect(decoded['appVersion'], '1.0.0+1');
      
      final decodedLots = decoded['lots'] as List;
      expect(decodedLots.length, 2);
      expect(decodedLots[0]['id'], 'lot-1');
      expect(decodedLots[0]['ticker'], 'STPL');
      expect(decodedLots[0]['buyDate'], sampleLots[0].buyDate.toIso8601String());
      expect(decodedLots[0]['sharesPurchased'], 500);
      expect(decodedLots[0]['buyPricePerShare'], 8.73);
      expect(decodedLots[0]['targetPrice'], 10.0);
      
      final decodedSales = decodedLots[0]['sales'] as List;
      expect(decodedSales.length, 1);
      expect(decodedSales[0]['id'], 'sale-1');
      expect(decodedSales[0]['sellDate'], sampleLots[0].sales[0].sellDate.toIso8601String());
      expect(decodedSales[0]['sharesSold'], 200);
      expect(decodedSales[0]['sellPricePerShare'], 9.0);
      expect(decodedSales[0].containsKey('amountReceived'), isFalse);

      expect(decodedLots[1]['targetPrice'], isNull);

      final decodedWithdrawals = decoded['withdrawals'] as List;
      expect(decodedWithdrawals.length, 1);
      expect(decodedWithdrawals[0]['id'], 'w-1');
      expect(decodedWithdrawals[0]['amount'], 15000.0);
      expect(decodedWithdrawals[0]['note'], 'w note');

      final decodedSettings = decoded['settings'] as Map<String, dynamic>;
      expect(decodedSettings['startingCapital'], 500000.0);
      expect(decodedSettings['currency'], 'PKR');
      expect(decodedSettings['themeMode'], 'dark');
      expect(decodedSettings['favorites'], ['STPL']);
      expect(decodedSettings['stockColors'], {'STPL': 0xFFFF0000});
    });

    test('empty portfolio produces valid JSON with empty arrays', () async {
      final jsonString = await DataExportService.buildExportJson(
        lots: [],
        withdrawals: [],
        settings: const UserSettings(favorites: [], startingCapital: 0, currency: 'PKR', themeMode: 'dark'),
      );

      final Map<String, dynamic> decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      expect(decoded['lots'], isEmpty);
      expect(decoded['withdrawals'], isEmpty);
      expect(decoded['settings']['favorites'], isEmpty);
      expect(decoded['settings']['stockColors'], isEmpty);
    });

    test('null targetPrice serialises as explicitly null', () async {
      final jsonString = await DataExportService.buildExportJson(
        lots: [
          Lot(id: '1', ticker: 'A', buyDate: DateTime.now(), sharesPurchased: 1, buyPricePerShare: 1.0, amountInvested: 1.0, targetPrice: null)
        ],
        withdrawals: [],
        settings: const UserSettings(favorites: [], startingCapital: 0, currency: 'PKR', themeMode: 'dark'),
      );

      // We don't just want to know jsonDecode returns null, we want to know the string literally contains "targetPrice": null
      expect(jsonString.contains('"targetPrice": null'), isTrue);
    });

    test('dates are serialised as ISO-8601 strings', () async {
      final date = DateTime.utc(2026, 9, 3, 12, 34, 56, 789);
      final jsonString = await DataExportService.buildExportJson(
        lots: [
          Lot(
            id: '1',
            ticker: 'A',
            buyDate: date,
            sharesPurchased: 1,
            buyPricePerShare: 1.0,
            amountInvested: 1.0,
            sales: [Sale(id: 's1', sellDate: date, sharesSold: 1, sellPricePerShare: 1.0, amountReceived: 1.0)],
          )
        ],
        withdrawals: [
          Withdrawal(id: 'w1', date: date, amount: 1.0)
        ],
        settings: const UserSettings(favorites: [], startingCapital: 0, currency: 'PKR', themeMode: 'dark'),
      );

      final Map<String, dynamic> decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      
      final isoString = date.toIso8601String();
      expect(decoded['exportedAt'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z$')));
      expect(decoded['lots'][0]['buyDate'], isoString);
      expect(decoded['lots'][0]['sales'][0]['sellDate'], isoString);
      expect(decoded['withdrawals'][0]['date'], isoString);
    });
  });
}
