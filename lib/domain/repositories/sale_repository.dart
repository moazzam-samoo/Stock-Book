import 'package:stock_investment_tracker/domain/entities/sale.dart';

abstract class SaleRepository {
  Stream<List<Sale>> watchAllSales(String lotId);
  Future<void> addSale(String lotId, Sale sale);
  Future<void> updateSale(String lotId, Sale sale);
  Future<void> deleteSale(String lotId, String saleId);
}
