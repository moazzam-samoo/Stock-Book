import 'package:stock_investment_tracker/domain/entities/ticker_info.dart';

abstract class TickerRepository {
  Future<List<TickerInfo>> getAll({bool forceRefresh = false});
}
