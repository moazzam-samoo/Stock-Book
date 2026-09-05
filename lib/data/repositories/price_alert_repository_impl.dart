import 'package:stock_investment_tracker/domain/entities/price_alert.dart';
import 'package:stock_investment_tracker/domain/repositories/price_alert_repository.dart';
import 'package:stock_investment_tracker/data/data_sources/remote/firestore_data_source.dart';
import 'package:stock_investment_tracker/data/models/price_alert_model.dart';

class PriceAlertRepositoryImpl implements PriceAlertRepository {
  final FirestoreDataSource _firestoreDataSource;
  final String _uid;

  PriceAlertRepositoryImpl(this._firestoreDataSource, this._uid);

  @override
  Stream<List<PriceAlert>> watchAllAlerts() {
    return _firestoreDataSource.watchAllPriceAlerts(_uid).map((models) {
      return models.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Future<void> addAlert(PriceAlert alert) async {
    final model = PriceAlertModel.fromEntity(alert);
    await _firestoreDataSource.addPriceAlert(_uid, model);
  }

  @override
  Future<void> updateAlert(PriceAlert alert) async {
    final model = PriceAlertModel.fromEntity(alert);
    await _firestoreDataSource.updatePriceAlert(_uid, model);
  }

  @override
  Future<void> deleteAlert(String alertId) async {
    await _firestoreDataSource.deletePriceAlert(_uid, alertId);
  }
}
