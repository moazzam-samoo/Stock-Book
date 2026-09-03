import 'dart:convert';
import 'package:stock_investment_tracker/domain/entities/lot.dart';
import 'package:stock_investment_tracker/domain/entities/withdrawal.dart';
import 'package:stock_investment_tracker/domain/entities/user_settings.dart';

class DataExportService {
  static Future<String> buildExportJson({
    required List<Lot> lots,
    required List<Withdrawal> withdrawals,
    required UserSettings settings,
  }) async {
    final data = {
      'schemaVersion': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'appVersion': '1.0.0+1',
      'lots': lots.map((lot) => {
        'id': lot.id,
        'ticker': lot.ticker,
        'buyDate': lot.buyDate.toIso8601String(),
        'sharesPurchased': lot.sharesPurchased,
        'buyPricePerShare': lot.buyPricePerShare,
        'targetPrice': lot.targetPrice,
        'sales': lot.sales.map((sale) => {
          'id': sale.id,
          'sellDate': sale.sellDate.toIso8601String(),
          'sharesSold': sale.sharesSold,
          'sellPricePerShare': sale.sellPricePerShare,
          // amountReceived is derived (sharesSold * sellPricePerShare) and
          // intentionally omitted — re-derivable on import, keeps the file smaller.
        }).toList(),
      }).toList(),
      'withdrawals': withdrawals.map((w) => {
        'id': w.id,
        'date': w.date.toIso8601String(),
        'amount': w.amount,
        'note': w.note,
      }).toList(),
      'settings': {
        'startingCapital': settings.startingCapital,
        'currency': settings.currency,
        'themeMode': settings.themeMode,
        'favorites': settings.favorites,
        'stockColors': settings.stockColors,
      }
    };

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }
}
