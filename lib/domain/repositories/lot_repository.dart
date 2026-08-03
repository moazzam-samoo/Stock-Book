import 'package:stock_investment_tracker/domain/entities/lot.dart';

abstract class LotRepository {
  Stream<List<Lot>> watchAllLots();
  Stream<List<Lot>> watchLotsByTicker(String ticker);
  Stream<List<Lot>> watchLotsByFilter(String statusFilter);
  Future<void> addLot(Lot lot);
  Future<void> updateLot(Lot lot);
  Future<void> deleteLot(String lotId);
}
