import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stock_investment_tracker/domain/entities/lot.dart';
import 'package:stock_investment_tracker/domain/enums/lot_status.dart';
import 'package:stock_investment_tracker/presentation/dashboard/providers/dashboard_providers.dart';

part 'transactions_providers.g.dart';

@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';

  void updateQuery(String query) {
    state = query;
  }
}

@riverpod
class StatusFilter extends _$StatusFilter {
  @override
  String build() => 'Open';

  void updateFilter(String filter) {
    state = filter;
  }
}

@riverpod
List<Lot> filteredLots(FilteredLotsRef ref) {
  final allLots = ref.watch(allLotsProvider).valueOrNull ?? [];
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
  final statusFilter = ref.watch(statusFilterProvider);

  final filteredList = allLots.where((lot) {
    final matchesSearch = lot.ticker.toLowerCase().contains(searchQuery);
    
    bool matchesStatus = true;
    if (statusFilter != 'All') {
      if (statusFilter.toLowerCase() == 'partial') {
        matchesStatus = lot.status == LotStatus.partiallySold;
      } else {
        final targetStatus = LotStatus.values.firstWhere(
          (e) => e.name.toLowerCase() == statusFilter.toLowerCase(),
          orElse: () => LotStatus.open,
        );
        matchesStatus = lot.status == targetStatus;
      }
    }

    return matchesSearch && matchesStatus;
  }).toList();

  // Sort by buyDate descending (latest date on top)
  filteredList.sort((a, b) => b.buyDate.compareTo(a.buyDate));

  return filteredList;
}
