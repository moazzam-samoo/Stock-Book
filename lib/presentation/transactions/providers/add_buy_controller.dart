import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stock_investment_tracker/data/data_sources/remote/firestore_data_source.dart';
import 'package:stock_investment_tracker/domain/calculator/position_calculator.dart';
import 'package:stock_investment_tracker/domain/entities/position.dart';
import 'package:stock_investment_tracker/domain/entities/position_buy.dart';
import 'package:stock_investment_tracker/domain/enums/position_status.dart';
import 'package:stock_investment_tracker/presentation/dashboard/providers/dashboard_providers.dart';
import 'package:stock_investment_tracker/providers/repository_providers.dart';
import 'package:stock_investment_tracker/providers/workflow_trigger_providers.dart';
import 'package:uuid/uuid.dart';

part 'add_buy_controller.g.dart';

@riverpod
class AddBuyController extends _$AddBuyController {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  Future<void> submit({
    required String ticker,
    required DateTime buyDate,
    required double sharesPurchased,
    required double buyPricePerShare,
    double? targetPrice,
  }) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(positionRepositoryProvider);
      if (repo == null) {
        state = const AsyncData(null);
        return;
      }

      // Ticker entry is free text, so a stray space or lowercase can be
      // saved verbatim — and then never matches the clean PSX symbol the
      // backend writes prices under, leaving that holding permanently
      // showing "—". Normalise once, here, at the only write path.
      ticker = FirestoreDataSource.normalizeTicker(ticker);

      final positions = ref.read(allPositionsProvider).valueOrNull ?? [];
      final openPosition = PositionCalculator.findOpenPosition(
        positions,
        ticker,
      );

      if (openPosition != null) {
        final updated = PositionCalculator.applyBuy(
          openPosition,
          buyId: const Uuid().v4(),
          date: buyDate,
          shares: sharesPurchased.toInt(),
          pricePerShare: buyPricePerShare,
        ).copyWith(targetPrice: targetPrice ?? openPosition.targetPrice);
        await repo.updatePosition(updated);
      } else {
        final newPosition = Position(
          id: const Uuid().v4(),
          ticker: ticker,
          status: PositionStatus.open,
          openedAt: buyDate,
          targetPrice: targetPrice,
          buys: [
            PositionBuy(
              id: const Uuid().v4(),
              date: buyDate,
              shares: sharesPurchased.toInt(),
              pricePerShare: buyPricePerShare,
            ),
          ],
        );
        await repo.addPosition(newPosition);

        // A brand-new ticker has no market_prices document yet, so the card
        // would show "—" until the next scheduled run (up to 5 minutes, or
        // until Monday outside market hours). Ask the backend to fetch it now.
        //
        // Only for a genuinely new holding: adding another buy to a position
        // that already exists means prices for that ticker are already
        // flowing, so a run there would achieve nothing.
        //
        // Deliberately fire-and-forget and deliberately silent: this is a
        // background convenience on top of a save that has already succeeded,
        // and it must never delay or fail the add. If the token is missing or
        // expired, pull-to-refresh is the path that reports exactly why.
        unawaited(ref.read(triggerWorkflowProvider)());
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
