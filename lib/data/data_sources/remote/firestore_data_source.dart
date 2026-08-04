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
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return LotModel.fromJson(data);
            }).toList());
  }

  Future<void> addLot(String uid, LotModel lot) async {
    final json = lot.toJson()..remove('id');
    // Explicitly serialize nested sales to avoid _SaleModel instances
    json['sales'] = lot.sales.map((s) => s.toJson()..remove('id')).toList();
    await _firestore
        .collection(FirestorePaths.lots(uid))
        .doc(lot.id)
        .set(json);
  }

  Future<void> updateLot(String uid, LotModel lot) async {
    final json = lot.toJson()..remove('id');
    // Explicitly serialize nested sales to avoid _SaleModel instances
    json['sales'] = lot.sales.map((s) => s.toJson()..remove('id')).toList();
    await _firestore
        .collection(FirestorePaths.lots(uid))
        .doc(lot.id)
        .update(json);
  }

  Future<void> deleteLot(String uid, String lotId) async {
    await _firestore.collection(FirestorePaths.lots(uid)).doc(lotId).delete();
  }

  // SALES (Embedded in Lots)
  Stream<List<SaleModel>> watchAllSales(String uid, String lotId) {
    return _firestore
        .collection(FirestorePaths.lots(uid))
        .doc(lotId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        data['id'] = doc.id;
        final lot = LotModel.fromJson(data);
        return lot.sales;
      }
      return [];
    });
  }

  Future<void> addSale(String uid, String lotId, SaleModel sale) async {
    final docRef = _firestore.collection(FirestorePaths.lots(uid)).doc(lotId);
    final doc = await docRef.get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      data['id'] = doc.id;
      final lot = LotModel.fromJson(data);
      final updatedSales = List<SaleModel>.from(lot.sales)..add(sale);
      await docRef.update({'sales': updatedSales.map((e) => e.toJson()..remove('id')).toList()});
    }
  }

  Future<void> updateSale(String uid, String lotId, SaleModel sale) async {
    final docRef = _firestore.collection(FirestorePaths.lots(uid)).doc(lotId);
    final doc = await docRef.get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      data['id'] = doc.id;
      final lot = LotModel.fromJson(data);
      final updatedSales = lot.sales.map((s) => s.id == sale.id ? sale : s).toList();
      await docRef.update({'sales': updatedSales.map((e) => e.toJson()..remove('id')).toList()});
    }
  }

  Future<void> deleteSale(String uid, String lotId, String saleId) async {
    final docRef = _firestore.collection(FirestorePaths.lots(uid)).doc(lotId);
    final doc = await docRef.get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      data['id'] = doc.id;
      final lot = LotModel.fromJson(data);
      final updatedSales = lot.sales.where((s) => s.id != saleId).toList();
      await docRef.update({'sales': updatedSales.map((e) => e.toJson()..remove('id')).toList()});
    }
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
