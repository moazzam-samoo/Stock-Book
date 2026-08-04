import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stock_investment_tracker/domain/entities/lot.dart';
import 'package:stock_investment_tracker/domain/entities/sale.dart';
import 'package:stock_investment_tracker/domain/enums/lot_status.dart';
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
    required Lot lot,
    required DateTime sellDate,
    required double sharesSold,
    required double sellPricePerShare,
  }) async {
    state = const AsyncLoading();
    try {
      final amountReceived = sharesSold * sellPricePerShare;
      final realizedProfitLoss = (sellPricePerShare - lot.buyPricePerShare) * sharesSold;

      final sale = Sale(
        id: const Uuid().v4(),
        sellDate: sellDate,
        sharesSold: sharesSold.toInt(),
        sellPricePerShare: sellPricePerShare,
        amountReceived: amountReceived,
      );

      final newSales = List<Sale>.from(lot.sales)..add(sale);
      
      final sharesRemaining = lot.sharesRemaining - sharesSold;
      final amountInvestedRemaining = lot.amountInvestedRemaining - (sharesSold * lot.buyPricePerShare);
      final totalRealizedProfitLoss = lot.realizedProfitLoss + realizedProfitLoss;
      
      LotStatus newStatus = lot.status;
      if (sharesRemaining <= 0.001) {
        newStatus = LotStatus.closed;
      } else if (sharesRemaining < lot.sharesPurchased) {
        newStatus = LotStatus.partiallySold;
      }

      final updatedLot = lot.copyWith(
        sales: newSales,
        sharesRemaining: sharesRemaining.toInt(),
        amountInvestedRemaining: amountInvestedRemaining,
        realizedProfitLoss: totalRealizedProfitLoss,
        status: newStatus,
      );

      final repo = ref.read(lotRepositoryProvider);
      if (repo != null) {
        await repo.updateLot(updatedLot);
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
