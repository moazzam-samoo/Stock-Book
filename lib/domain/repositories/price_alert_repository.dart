import 'package:stock_investment_tracker/domain/entities/price_alert.dart';

abstract class PriceAlertRepository {
  Stream<List<PriceAlert>> watchAllAlerts();
  Future<void> addAlert(PriceAlert alert);
  Future<void> updateAlert(PriceAlert alert);
  Future<void> deleteAlert(String alertId);
}
