import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stock_investment_tracker/domain/entities/market_price.dart';

part 'market_price_model.freezed.dart';

@freezed
abstract class MarketPriceModel with _$MarketPriceModel {
  const factory MarketPriceModel({
    required String ticker,
    required double price,
    required double previousClose,
    required DateTime updatedAt,
  }) = _MarketPriceModel;

  factory MarketPriceModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    if (json['updatedAt'] is Timestamp) {
      parsedDate = (json['updatedAt'] as Timestamp).toDate();
    } else if (json['updatedAt'] is String) {
      parsedDate = DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now();
    } else if (json['updatedAt'] is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int);
    } else {
      parsedDate = DateTime.now();
    }

    // Defensive parsing per AGENTS.md §4.1: a document written with a field
    // missing must degrade to a usable value, never throw. `fromJson` runs
    // inside the market-price stream's `.map()`, so a single bad document
    // used to error the whole stream — every ticker in the app showed "—",
    // indistinguishable from "no data", with the real cause invisible.
    final price = (json['price'] as num?)?.toDouble() ?? 0.0;
    return MarketPriceModel(
      ticker: (json['ticker'] as String?) ?? '',
      price: price,
      // No previousClose (or a malformed one) means "no day change known",
      // which is price itself — not a crash, and not a fake 0 that would
      // render as a -100% day move.
      previousClose: (json['previousClose'] as num?)?.toDouble() ?? price,
      updatedAt: parsedDate,
    );
  }
}

extension MarketPriceModelExtension on MarketPriceModel {
  MarketPrice toEntity() {
    return MarketPrice(
      ticker: ticker,
      price: price,
      previousClose: previousClose,
      updatedAt: updatedAt,
    );
  }

  /// Manual toJson since we use a custom fromJson
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'ticker': ticker,
      'price': price,
      'previousClose': previousClose,
      // Hive needs strings or ints if not Timestamp, but since this might be cached
      // we usually just write String. Let's use iso8601 string for Hive safety,
      // or Timestamp for Firestore. Since we hand-roll, we should match the use case.
      // Actually, if we use this to write to Firestore, we'd use Timestamp.
      // But we don't write to Firestore from the client.
      // So toJson is mostly for Hive caching. We can use iso8601String.
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
