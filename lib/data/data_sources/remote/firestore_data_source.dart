import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stock_investment_tracker/core/constants/firestore_paths.dart';
import 'package:stock_investment_tracker/data/models/lot_model.dart';
import 'package:stock_investment_tracker/data/models/sale_model.dart';
import 'package:stock_investment_tracker/data/models/user_settings_model.dart';

class FirestoreDataSource {
  final FirebaseFirestore _firestore;

  FirestoreDataSource(this._firestore);

  // LOTS
  Stream<List<LotModel>> watchAllLots(String uid) {
    return _firestore
        .collection(FirestorePaths.lots(uid))
        .orderBy('buyDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LotModel.fromJson(doc.data()..['id'] = doc.id))
            .toList());
  }

  Future<void> addLot(String uid, LotModel lot) async {
    await _firestore
        .collection(FirestorePaths.lots(uid))
        .doc(lot.id)
        .set(lot.toJson()..remove('id'));
  }

  Future<void> updateLot(String uid, LotModel lot) async {
    await _firestore
        .collection(FirestorePaths.lots(uid))
        .doc(lot.id)
        .update(lot.toJson()..remove('id'));
  }

  Future<void> deleteLot(String uid, String lotId) async {
    await _firestore.collection(FirestorePaths.lots(uid)).doc(lotId).delete();
  }

  // SALES
  Stream<List<SaleModel>> watchAllSales(String uid, String lotId) {
    return _firestore
        .collection(FirestorePaths.sales(uid, lotId))
        .orderBy('sellDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SaleModel.fromJson(doc.data()..['id'] = doc.id))
            .toList());
  }

  Future<void> addSale(String uid, String lotId, SaleModel sale) async {
    await _firestore
        .collection(FirestorePaths.sales(uid, lotId))
        .doc(sale.id)
        .set(sale.toJson()..remove('id'));
  }

  Future<void> updateSale(String uid, String lotId, SaleModel sale) async {
    await _firestore
        .collection(FirestorePaths.sales(uid, lotId))
        .doc(sale.id)
        .update(sale.toJson()..remove('id'));
  }

  Future<void> deleteSale(String uid, String lotId, String saleId) async {
    await _firestore
        .collection(FirestorePaths.sales(uid, lotId))
        .doc(saleId)
        .delete();
  }

  // SETTINGS
  Stream<UserSettingsModel?> watchSettings(String uid) {
    return _firestore
        .doc(FirestorePaths.settings(uid))
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserSettingsModel.fromJson(doc.data()!);
      }
      return null;
    });
  }

  Future<void> updateSettings(String uid, UserSettingsModel settings) async {
    await _firestore
        .doc(FirestorePaths.settings(uid))
        .set(settings.toJson(), SetOptions(merge: true));
  }
}
