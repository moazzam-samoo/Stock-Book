import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_investment_tracker/domain/entities/ticker_info.dart';
import 'package:stock_investment_tracker/providers/repository_providers.dart';

final allTickersProvider = FutureProvider<List<TickerInfo>>((ref) async {
  final repository = ref.watch(tickerRepositoryProvider);
  if (repository == null) {
    return [];
  }
  return repository.getAll();
});
