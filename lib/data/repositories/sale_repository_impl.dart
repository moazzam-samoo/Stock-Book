import 'package:stock_investment_tracker/data/data_sources/remote/firestore_data_source.dart';
import 'package:stock_investment_tracker/data/models/sale_model.dart';
import 'package:stock_investment_tracker/domain/entities/sale.dart';
import 'package:stock_investment_tracker/domain/repositories/sale_repository.dart';

class SaleRepositoryImpl implements SaleRepository {
  final String _uid;
  final FirestoreDataSource _firestoreDataSource;

  SaleRepositoryImpl({
    required String uid,
    required FirestoreDataSource firestoreDataSource,
  })  : _uid = uid,
        _firestoreDataSource = firestoreDataSource;

  @override
  Stream<List<Sale>> watchAllSales(String lotId) {
    return _firestoreDataSource.watchAllSales(_uid, lotId).map((models) {
      return models.map((model) {
        return model.toEntity(model.sharesSold * model.sellPricePerShare);
      }).toList();
    });
  }

  @override
  Future<void> addSale(String lotId, Sale sale) async {
    final model = SaleModelExtension.fromEntity(sale);
    await _firestoreDataSource.addSale(_uid, lotId, model);
  }

  @override
  Future<void> updateSale(String lotId, Sale sale) async {
    final model = SaleModelExtension.fromEntity(sale);
    await _firestoreDataSource.updateSale(_uid, lotId, model);
  }

  @override
  Future<void> deleteSale(String lotId, String saleId) async {
    await _firestoreDataSource.deleteSale(_uid, lotId, saleId);
  }
}
