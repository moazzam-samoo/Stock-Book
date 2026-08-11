import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stock_investment_tracker/domain/entities/withdrawal.dart';
import 'package:stock_investment_tracker/providers/repository_providers.dart';
import 'package:uuid/uuid.dart';

part 'withdrawal_provider.g.dart';

/// Mutations for profit withdrawals.
///
/// Reads go through `allWithdrawalsProvider`, which is a live Firestore
/// snapshot stream, so no manual invalidation is needed after a write.
///
/// keepAlive is required here: this notifier is only ever reached via
/// `ref.read(...notifier)`, never `ref.watch`, so nothing keeps a plain
/// autoDispose instance alive. Riverpod tears an unwatched autoDispose
/// provider down as soon as the current widget build ends, which can land
/// mid-flight on a slow Firestore write (e.g. under a weak connection) and
/// throws "Bad state: Future already completed" when the disposed notifier
/// tries to finalize its state afterwards.
@Riverpod(keepAlive: true)
class WithdrawalController extends _$WithdrawalController {
  @override
  FutureOr<void> build() {}

  Future<void> addWithdrawal({
    required double amount,
    required DateTime date,
    String note = '',
  }) async {
    final repo = ref.read(withdrawalRepositoryProvider);
    if (repo == null) return;

    final withdrawal = Withdrawal(
      id: const Uuid().v4(),
      date: date,
      amount: amount,
      note: note.trim(),
    );

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repo.addWithdrawal(withdrawal));
  }

  Future<void> updateWithdrawal(Withdrawal withdrawal) async {
    final repo = ref.read(withdrawalRepositoryProvider);
    if (repo == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repo.updateWithdrawal(withdrawal));
  }

  Future<void> deleteWithdrawal(String withdrawalId) async {
    final repo = ref.read(withdrawalRepositoryProvider);
    if (repo == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repo.deleteWithdrawal(withdrawalId));
  }
}
