import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stock_investment_tracker/core/constants/firestore_paths.dart';
import 'package:stock_investment_tracker/data/models/lot_model.dart';
import 'package:stock_investment_tracker/data/models/market_price_model.dart';
import 'package:stock_investment_tracker/data/models/position_model.dart';
import 'package:stock_investment_tracker/data/models/sale_model.dart';
import 'package:stock_investment_tracker/data/models/user_settings_model.dart';
import 'package:stock_investment_tracker/data/models/withdrawal_model.dart';
import 'package:stock_investment_tracker/data/models/price_alert_model.dart';
import 'package:stock_investment_tracker/data/models/admin_tax_rates_model.dart';

class FirestoreDataSource {
  final FirebaseFirestore _firestore;

  FirestoreDataSource(this._firestore);

  /// Executes [op] with a 4s timeout. TimeoutExceptions are swallowed because
  /// Firestore's offline queue handles local persistence when offline or on slow
  /// networks. Transient network FirebaseExceptions ('unavailable',
  /// 'deadline-exceeded', 'aborted', 'cancelled') are safely queued, whereas
  /// non-retryable errors (e.g. permission-denied, unauthenticated) are rethrown.
  Future<void> _write(Future<void> Function() op, String label) async {
    try {
      await op().timeout(const Duration(seconds: 4));
    } on TimeoutException {
      // Offline / slow network — Firestore local queue owns it
      return;
    } on FirebaseException catch (e) {
      final retryable = {'unavailable', 'deadline-exceeded', 'aborted', 'cancelled'};
      if (retryable.contains(e.code)) return;
      rethrow;
    }
  }

  @visibleForTesting
  Future<void> writeWithTimeoutGuard(Future<void> Function() op, String label) =>
      _write(op, label);

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
    json['sales'] = lot.sales.map((s) => s.toJson()).toList();
    await _write(
      () => _firestore
          .collection(FirestorePaths.lots(uid))
          .doc(lot.id)
          .set(json),
      'addLot',
    );
  }

  Future<void> updateLot(String uid, LotModel lot) async {
    final json = lot.toJson()..remove('id');
    // Explicitly serialize nested sales to avoid _SaleModel instances
    json['sales'] = lot.sales.map((s) => s.toJson()).toList();
    await _write(
      () => _firestore
          .collection(FirestorePaths.lots(uid))
          .doc(lot.id)
          .set(json, SetOptions(merge: true)),
      'updateLot',
    );
  }

  Future<void> deleteLot(String uid, String lotId) async {
    await _write(
      () => _firestore
          .collection(FirestorePaths.lots(uid))
          .doc(lotId)
          .delete(),
      'deleteLot',
    );
  }

  // POSITIONS
  Stream<List<PositionModel>> watchAllPositions(String uid) {
    return _firestore
        .collection(FirestorePaths.positions(uid))
        .orderBy('openedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return PositionModel.fromJson(data);
            }).toList());
  }

  Future<void> addPosition(String uid, PositionModel position) async {
    final json = position.toJson()..remove('id');
    // Explicitly serialize nested buys and sales
    json['buys'] = position.buys.map((b) => b.toJson()).toList();
    json['sales'] = position.sales.map((s) => s.toJson()).toList();
    await _write(
      () => _firestore
          .collection(FirestorePaths.positions(uid))
          .doc(position.id)
          .set(json),
      'addPosition',
    );
  }

  Future<void> updatePosition(String uid, PositionModel position) async {
    final json = position.toJson()..remove('id');
    // Explicitly serialize nested buys and sales
    json['buys'] = position.buys.map((b) => b.toJson()).toList();
    json['sales'] = position.sales.map((s) => s.toJson()).toList();
    await _write(
      () => _firestore
          .collection(FirestorePaths.positions(uid))
          .doc(position.id)
          .set(json, SetOptions(merge: true)),
      'updatePosition',
    );
  }

  Future<void> deletePosition(String uid, String positionId) async {
    await _write(
      () => _firestore
          .collection(FirestorePaths.positions(uid))
          .doc(positionId)
          .delete(),
      'deletePosition',
    );
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
    await _write(() async {
      final docRef = _firestore.collection(FirestorePaths.lots(uid)).doc(lotId);
      final doc = await docRef.get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        data['id'] = doc.id;
        final lot = LotModel.fromJson(data);
        final updatedSales = List<SaleModel>.from(lot.sales)..add(sale);
        await docRef.set(
          {'sales': updatedSales.map((e) => e.toJson()).toList()},
          SetOptions(merge: true),
        );
      }
    }, 'addSale');
  }

  Future<void> updateSale(String uid, String lotId, SaleModel sale) async {
    await _write(() async {
      final docRef = _firestore.collection(FirestorePaths.lots(uid)).doc(lotId);
      final doc = await docRef.get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        data['id'] = doc.id;
        final lot = LotModel.fromJson(data);
        final updatedSales = lot.sales.map((s) => s.id == sale.id ? sale : s).toList();
        await docRef.set(
          {'sales': updatedSales.map((e) => e.toJson()).toList()},
          SetOptions(merge: true),
        );
      }
    }, 'updateSale');
  }

  Future<void> deleteSale(String uid, String lotId, String saleId) async {
    await _write(() async {
      final docRef = _firestore.collection(FirestorePaths.lots(uid)).doc(lotId);
      final doc = await docRef.get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        data['id'] = doc.id;
        final lot = LotModel.fromJson(data);
        final updatedSales = lot.sales.where((s) => s.id != saleId).toList();
        await docRef.set(
          {'sales': updatedSales.map((e) => e.toJson()).toList()},
          SetOptions(merge: true),
        );
      }
    }, 'deleteSale');
  }

  // MIGRATION HELPER METHODS
  Future<int?> getUserSchemaVersion(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      if (data.containsKey('schemaVersion')) {
        return data['schemaVersion'] as int?;
      }
    }
    return null;
  }

  Future<List<LotModel>> getAllLotsOnce(String uid) async {
    final snapshot = await _firestore.collection(FirestorePaths.lots(uid)).get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return LotModel.fromJson(data);
    }).toList();
  }

  Future<void> stampSchemaVersion(String uid, int version) async {
    await _firestore.collection('users').doc(uid).set({
      'schemaVersion': version,
    }, SetOptions(merge: true));
  }

  Future<void> runPositionMigrationBatches(String uid, List<PositionModel> positions, int version) async {
    if (positions.length + 1 <= 450) {
      // Single batch
      final batch = _firestore.batch();
      
      for (final pos in positions) {
        final posRef = _firestore.collection(FirestorePaths.positions(uid)).doc(pos.id);
        final json = pos.toJson()..remove('id');
        json['buys'] = pos.buys.map((b) => b.toJson()).toList();
        json['sales'] = pos.sales.map((s) => s.toJson()).toList();
        batch.set(posRef, json);
      }
      
      final userRef = _firestore.collection('users').doc(uid);
      batch.set(userRef, {'schemaVersion': version}, SetOptions(merge: true));
      
      await batch.commit();
    } else {
      // Chunked batches
      final chunks = <List<PositionModel>>[];
      for (var i = 0; i < positions.length; i += 450) {
        chunks.add(positions.sublist(
          i,
          i + 450 > positions.length ? positions.length : i + 450,
        ));
      }

      for (final chunk in chunks) {
        final batch = _firestore.batch();
        for (final pos in chunk) {
          final posRef = _firestore.collection(FirestorePaths.positions(uid)).doc(pos.id);
          final json = pos.toJson()..remove('id');
          json['buys'] = pos.buys.map((b) => b.toJson()).toList();
          json['sales'] = pos.sales.map((s) => s.toJson()).toList();
          batch.set(posRef, json);
        }
        await batch.commit();
      }
      
      // Write the schemaVersion marker last
      final finalBatch = _firestore.batch();
      final userRef = _firestore.collection('users').doc(uid);
      finalBatch.set(userRef, {'schemaVersion': version}, SetOptions(merge: true));
      await finalBatch.commit();
    }
  }

  // WITHDRAWALS
  Stream<List<WithdrawalModel>> watchAllWithdrawals(String uid) {
    return _firestore
        .collection(FirestorePaths.withdrawals(uid))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return WithdrawalModel.fromJson(data);
            }).toList());
  }

  Future<void> addWithdrawal(String uid, WithdrawalModel withdrawal) async {
    final json = withdrawal.toJson()..remove('id');
    await _write(
      () => _firestore
          .collection(FirestorePaths.withdrawals(uid))
          .doc(withdrawal.id)
          .set(json),
      'addWithdrawal',
    );
  }

  Future<void> updateWithdrawal(String uid, WithdrawalModel withdrawal) async {
    final json = withdrawal.toJson()..remove('id');
    await _write(
      () => _firestore
          .collection(FirestorePaths.withdrawals(uid))
          .doc(withdrawal.id)
          .set(json, SetOptions(merge: true)),
      'updateWithdrawal',
    );
  }

  Future<void> deleteWithdrawal(String uid, String withdrawalId) async {
    await _write(
      () => _firestore
          .collection(FirestorePaths.withdrawals(uid))
          .doc(withdrawalId)
          .delete(),
      'deleteWithdrawal',
    );
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
    final json = settings.toJson();
    json['taxSettings'] = settings.taxSettings.toJson();
    await _write(
      () => _firestore
          .doc(FirestorePaths.settings(uid))
          .set(json),
      'updateSettings',
    );
  }

  // GLOBAL TAX RATES (Configured centrally by Admin)
  Stream<AdminTaxRatesModel?> watchGlobalTaxRates() {
    return _firestore
        .doc(FirestorePaths.globalTaxRates())
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return AdminTaxRatesModel.fromJson(doc.data()!);
      }
      return null;
    });
  }

  // PREMIUM CODES

  /// Atomically checks-and-flips `premium_codes/{code}.redeemed` inside a
  /// Firestore transaction, so two simultaneous redemptions of the same
  /// code can't both succeed (`firestore.rules`' own `resource.data.redeemed
  /// == false` guard enforces this server-side too, but the transaction
  /// gives a clean read of *why* it failed instead of a raw permission
  /// error). Returns `'success'` / `'invalidCode'` / `'alreadyRedeemed'` —
  /// mapped to [PremiumCodeOutcome] by the repository, which is what
  /// actually decides `isPremiumUnlocked`; this layer only touches the
  /// code document itself. Throws on a genuine network/timeout failure —
  /// the caller maps that to [PremiumCodeOutcome.networkError].
  Future<String> redeemPremiumCode({required String code, required String uid}) {
    final ref = _firestore.doc(FirestorePaths.premiumCode(code));
    return _firestore.runTransaction<String>((transaction) async {
      final snap = await transaction.get(ref);
      if (!snap.exists) return 'invalidCode';
      final data = snap.data();
      if (data == null || data['redeemed'] == true) return 'alreadyRedeemed';

      transaction.update(ref, {
        'redeemed': true,
        'redeemedBy': uid,
        'redeemedAt': FieldValue.serverTimestamp(),
      });
      return 'success';
    }).timeout(const Duration(seconds: 8));
  }

  // MARKET PRICES

  /// `market_prices` document IDs are always the clean PSX symbol, but a
  /// position's stored `ticker` can carry stray whitespace or lowercase from
  /// free-text entry (the ticker field has never been strictly validated).
  /// Looking up the raw value silently finds nothing and shows "—" forever,
  /// so every lookup normalises first.
  static String normalizeTicker(String ticker) => ticker.trim().toUpperCase();

  Stream<MarketPriceModel?> watchMarketPrice(String ticker) {
    return _firestore
        .collection(FirestorePaths.marketPrices())
        .doc(normalizeTicker(ticker))
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      final data = snapshot.data()!;
      data['ticker'] ??= snapshot.id;
      return MarketPriceModel.fromJson(data);
    });
  }

  /// Firestore's `whereIn` accepts at most 30 values per query, so a ticker
  /// list longer than that has to be split and the resulting streams merged
  /// (see [watchMarketPrices]). Pulled out as its own static method so the
  /// batch-boundary behaviour (list length 30 vs. 31 vs. a multiple of 30)
  /// is directly unit-testable without touching Firestore at all.
  static List<List<String>> chunkTickers(List<String> tickers, {int chunkSize = 30}) {
    final chunks = <List<String>>[];
    for (var i = 0; i < tickers.length; i += chunkSize) {
      chunks.add(tickers.sublist(i, i + chunkSize > tickers.length ? tickers.length : i + chunkSize));
    }
    return chunks;
  }

  Stream<List<MarketPriceModel>> watchMarketPrices(List<String> tickers) {
    if (tickers.isEmpty) return Stream.value([]);

    final chunks = chunkTickers(
      tickers.map(normalizeTicker).toSet().toList(),
    );

    final streams = chunks.map((chunk) {
      return _firestore
          .collection(FirestorePaths.marketPrices())
          .where(FieldPath.documentId, whereIn: chunk)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) {
                final data = doc.data();
                data['ticker'] ??= doc.id;
                return MarketPriceModel.fromJson(data);
              }).toList());
    }).toList();
    
    return Rx.combineLatestList(streams).map((lists) {
      return lists.expand((element) => element).toList();
    });
  }

  // --- Price Alerts ---

  Stream<List<PriceAlertModel>> watchAllPriceAlerts(String uid) {
    return _firestore
        .collection(FirestorePaths.priceAlerts(uid))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return PriceAlertModel.fromJson(data);
            }).toList());
  }

  Future<void> addPriceAlert(String uid, PriceAlertModel alert) async {
    final json = alert.toJson()..remove('id');
    await _write(
      () => _firestore
          .collection(FirestorePaths.priceAlerts(uid))
          .doc(alert.id)
          .set(json),
      'addPriceAlert',
    );
  }

  Future<void> updatePriceAlert(String uid, PriceAlertModel alert) async {
    final json = alert.toJson()..remove('id');
    await _write(
      () => _firestore
          .collection(FirestorePaths.priceAlerts(uid))
          .doc(alert.id)
          .set(json, SetOptions(merge: true)),
      'updatePriceAlert',
    );
  }

  Future<void> deletePriceAlert(String uid, String alertId) async {
    await _write(
      () => _firestore
          .collection(FirestorePaths.priceAlerts(uid))
          .doc(alertId)
          .delete(),
      'deletePriceAlert',
    );
  }
}
