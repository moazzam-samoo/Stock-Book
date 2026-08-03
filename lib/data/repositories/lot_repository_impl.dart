import 'package:stock_investment_tracker/data/data_sources/remote/firestore_data_source.dart';
import 'package:stock_investment_tracker/data/models/lot_model.dart';
import 'package:stock_investment_tracker/domain/entities/lot.dart';
import 'package:stock_investment_tracker/domain/repositories/lot_repository.dart';

class LotRepositoryImpl implements LotRepository {
  final String _uid;
  final FirestoreDataSource _firestoreDataSource;

  LotRepositoryImpl({
    required String uid,
    required FirestoreDataSource firestoreDataSource,
  })  : _uid = uid,
        _firestoreDataSource = firestoreDataSource;

  @override
  Stream<List<Lot>> watchAllLots() {
    return _firestoreDataSource.watchAllLots(_uid).map((models) {
      return models.map((model) {
        return model.toEntity(
          amountInvested: model.sharesPurchased * model.buyPricePerShare,
        );
      }).toList();
    });
  }

  @override
  Stream<List<Lot>> watchLotsByTicker(String ticker) {
    return watchAllLots().map(
      (lots) => lots.where((lot) => lot.ticker == ticker).toList(),
    );
  }

  @override
  Stream<List<Lot>> watchLotsByFilter(String statusFilter) {
    return watchAllLots().map((lots) {
      if (statusFilter.toLowerCase() == 'all') return lots;
      return lots.where((lot) => lot.status.name.toLowerCase() == statusFilter.toLowerCase()).toList();
    });
  }

  @override
  Future<void> addLot(Lot lot) async {
    final model = LotModelExtension.fromEntity(lot);
    await _firestoreDataSource.addLot(_uid, model);
  }

  @override
  Future<void> updateLot(Lot lot) async {
    final model = LotModelExtension.fromEntity(lot);
    await _firestoreDataSource.updateLot(_uid, model);
  }

  @override
  Future<void> deleteLot(String lotId) async {
    await _firestoreDataSource.deleteLot(_uid, lotId);
  }
}
