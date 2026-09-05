import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stock_investment_tracker/domain/calculator/position_calculator.dart';
import 'package:stock_investment_tracker/domain/entities/position.dart';
import 'package:stock_investment_tracker/providers/repository_providers.dart';
import 'package:uuid/uuid.dart';

part 'add_sell_controller.g.dart';

@riverpod
class AddSellController extends _$AddSellController {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  Future<void> submit({
    required Position position,
    required DateTime sellDate,
    required int sharesSold,
    required double sellPricePerShare,
  }) async {
    state = const AsyncLoading();
    try {
      final updatedPosition = PositionCalculator.applySell(
        position,
        saleId: const Uuid().v4(),
        date: sellDate,
        shares: sharesSold,
        pricePerShare: sellPricePerShare,
      );

      final repo = ref.read(positionRepositoryProvider);
      if (repo != null) {
        await repo.updatePosition(updatedPosition);
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    } finally {
      if (!state.hasError) {
        state = const AsyncData(null);
      }
    }
  }
}
