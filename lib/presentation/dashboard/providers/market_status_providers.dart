import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../domain/entities/market_status.dart';
import '../../../providers/repository_providers.dart';

part 'market_status_providers.g.dart';

@riverpod
Stream<MarketStatus?> watchMarketStatus(WatchMarketStatusRef ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) {
    return Stream.value(null);
  }

  final repository = ref.watch(marketStatusRepositoryProvider);
  if (repository == null) {
    return Stream.value(null);
  }

  return repository.watchStatus();
}

/// Whether the market is confidently open right now, or `null` if the status
/// itself is missing/too old to trust (mirrors `_MarketClock`'s own 30-minute
/// freshness rule) — callers must treat `null` as "don't know", never guess
/// open or closed from a stale reading.
bool? currentlyOpen(MarketStatus? status) {
  if (status == null || DateTime.now().difference(status.checkedAt).inMinutes > 30) {
    return null;
  }
  return status.isOpen;
}
