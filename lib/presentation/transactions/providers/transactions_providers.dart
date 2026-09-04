import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stock_investment_tracker/domain/entities/position.dart';
import 'package:stock_investment_tracker/domain/enums/position_status.dart';
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
List<Position> filteredPositions(FilteredPositionsRef ref) {
  final allPositions = ref.watch(allPositionsProvider).valueOrNull ?? [];
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
  final statusFilter = ref.watch(statusFilterProvider);

  final filteredList = allPositions.where((pos) {
    final matchesSearch = pos.ticker.toLowerCase().contains(searchQuery);
    
    bool matchesStatus = true;
    switch (statusFilter.toLowerCase()) {
      case 'all':
        matchesStatus = true;
        break;
      case 'open':
        // "Open" means "still holding" — a position that's been partially sold
        // is still yours, so it belongs in the default view. Only fully-closed
        // cycles drop out.
        matchesStatus = pos.status != PositionStatus.closed;
        break;
      case 'partial':
        matchesStatus = pos.status == PositionStatus.partiallySold;
        break;
      case 'closed':
        matchesStatus = pos.status == PositionStatus.closed;
        break;
    }

    return matchesSearch && matchesStatus;
  }).toList();

  // Sort by openedAt descending (latest date on top)
  filteredList.sort((a, b) => b.openedAt.compareTo(a.openedAt));

  return filteredList;
}
