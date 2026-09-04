import 'package:stock_investment_tracker/domain/entities/market_price.dart';

abstract class MarketPriceRepository {
  Stream<MarketPrice?> watchPrice(String ticker);
  Stream<Map<String, MarketPrice>> watchPrices(List<String> tickers);
}
