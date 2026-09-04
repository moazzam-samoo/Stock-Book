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
