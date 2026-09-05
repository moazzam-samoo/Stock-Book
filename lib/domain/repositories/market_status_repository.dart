import '../entities/market_status.dart';

abstract class MarketStatusRepository {
  Stream<MarketStatus?> watchStatus();
}
