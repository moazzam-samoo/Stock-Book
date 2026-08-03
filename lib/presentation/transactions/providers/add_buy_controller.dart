import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stock_investment_tracker/domain/entities/lot.dart';
import 'package:stock_investment_tracker/domain/enums/lot_status.dart';
import 'package:stock_investment_tracker/providers/repository_providers.dart';
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
  }) async {
    state = const AsyncLoading();
    try {
      final amountInvested = sharesPurchased * buyPricePerShare;
      
      final lot = Lot(
        id: const Uuid().v4(),
        ticker: ticker,
        buyDate: buyDate,
        sharesPurchased: sharesPurchased,
        buyPricePerShare: buyPricePerShare,
        amountInvested: amountInvested,
        sharesRemaining: sharesPurchased,
        amountInvestedRemaining: amountInvested,
        realizedProfitLoss: 0.0,
        status: LotStatus.open,
      );

      final repo = ref.read(lotRepositoryProvider);
      if (repo != null) {
        await repo.addLot(lot);
      }
      
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
