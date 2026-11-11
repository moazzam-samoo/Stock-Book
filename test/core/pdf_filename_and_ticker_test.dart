import 'package:flutter_test/flutter_test.dart';
import 'package:stock_investment_tracker/core/services/pdf_report_service.dart';
import 'package:stock_investment_tracker/data/models/market_price_model.dart';
import 'package:stock_investment_tracker/data/models/price_alert_model.dart';

void main() {
  group('PdfReportService filename sanitization (H8, M5)', () {
    test('preserves valid alphanumeric tickers and hyphens/dots', () {
      expect(PdfReportService.sanitizeFileName('ENGRO'), 'ENGRO');
      expect(PdfReportService.sanitizeFileName('SYS.A'), 'SYS.A');
      expect(PdfReportService.sanitizeFileName('OGDC-1'), 'OGDC-1');
    });

    test('replaces path traversal characters and slashes with underscores', () {
      expect(
        PdfReportService.sanitizeFileName('ENGRO/../../secret'),
        'ENGRO_.._.._secret',
      );
      expect(
        PdfReportService.sanitizeFileName(r'TICKER\subdir\file'),
        'TICKER_subdir_file',
      );
    });

    test('replaces illegal filesystem characters (Windows/Linux/macOS)', () {
      expect(
        PdfReportService.sanitizeFileName('STOCK*?<>|:"'),
        'STOCK_______',
      );
    });
  });

  group('Ticker regex validation (H8)', () {
    final tickerRegex = RegExp(r'^[A-Za-z0-9.-]{1,12}$');

    test('accepts clean PSX tickers up to 12 chars', () {
      expect(tickerRegex.hasMatch('ENGRO'), isTrue);
      expect(tickerRegex.hasMatch('SYS'), isTrue);
      expect(tickerRegex.hasMatch('OGDC-1'), isTrue);
      expect(tickerRegex.hasMatch('PTCL.A'), isTrue);
    });

    test('rejects path traversal, spaces, and punctuation', () {
      expect(tickerRegex.hasMatch('../ENGRO'), isFalse);
      expect(tickerRegex.hasMatch('EN GRO'), isFalse);
      expect(tickerRegex.hasMatch('ENGRO/SYS'), isFalse);
      expect(tickerRegex.hasMatch('ENGRO*'), isFalse);
      expect(tickerRegex.hasMatch('LONGLONGTICKERNAME'), isFalse); // > 12 chars
    });
  });

  group('Defensive Numeric Parsing (M7)', () {
    test('PriceAlertModel handles String and num targetPrice and tolerance', () {
      final jsonWithString = {
        'id': 'alert-1',
        'ticker': 'ENGRO',
        'targetPrice': '450.75',
        'tolerancePercent': '2.5',
        'lastAlertPrice': '449.0',
        'createdAt': '2026-09-01T12:00:00.000',
      };

      final alert = PriceAlertModel.fromJson(jsonWithString);
      expect(alert.targetPrice, 450.75);
      expect(alert.tolerancePercent, 2.5);
      expect(alert.lastAlertPrice, 449.0);
    });

    test('PriceAlertModel handles integer targetPrice and tolerance without TypeError', () {
      final jsonWithInt = {
        'id': 'alert-2',
        'ticker': 'SYS',
        'targetPrice': 500,
        'tolerancePercent': 1,
        'createdAt': '2026-09-01T12:00:00.000',
      };

      final alert = PriceAlertModel.fromJson(jsonWithInt);
      expect(alert.targetPrice, 500.0);
      expect(alert.tolerancePercent, 1.0);
    });

    test('MarketPriceModel handles String and integer price and previousClose', () {
      final jsonWithString = {
        'ticker': 'HUBC',
        'price': '125.80',
        'previousClose': '122.50',
        'updatedAt': '2026-09-01T12:00:00.000Z',
      };

      final priceModel = MarketPriceModel.fromJson(jsonWithString);
      expect(priceModel.price, 125.80);
      expect(priceModel.previousClose, 122.50);

      final jsonWithInt = {
        'ticker': 'HUBC',
        'price': 130,
        'previousClose': 128,
        'updatedAt': '2026-09-01T12:00:00.000Z',
      };

      final priceModelInt = MarketPriceModel.fromJson(jsonWithInt);
      expect(priceModelInt.price, 130.0);
      expect(priceModelInt.previousClose, 128.0);
    });
  });
}

