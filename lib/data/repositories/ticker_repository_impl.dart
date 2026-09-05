import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stock_investment_tracker/core/constants/firestore_paths.dart';
import 'package:stock_investment_tracker/data/data_sources/local/hive_data_source.dart';
import 'package:stock_investment_tracker/data/models/ticker_info_model.dart';
import 'package:stock_investment_tracker/domain/entities/ticker_info.dart';
import 'package:stock_investment_tracker/domain/repositories/ticker_repository.dart';

class TickerRepositoryImpl implements TickerRepository {
  final FirebaseFirestore firestore;
  final HiveDataSource hiveDataSource;

  TickerRepositoryImpl({
    required this.firestore,
    required this.hiveDataSource,
  });

  @override
  Future<List<TickerInfo>> getAll({bool forceRefresh = false}) async {
    try {
      final docSnapshot = await firestore
          .doc(FirestorePaths.tickersDoc())
          .get()
          .timeout(const Duration(seconds: 4));

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        // The backend (scripts/price_alerts/firestore_io.py::write_tickers_doc)
        // writes this list under the key `companies`, not `tickers` — reading
        // the wrong key meant this branch never matched against the real
        // document, so search silently fell back to Favorites-only, always,
        // even with tickers/all fully populated in Firestore.
        if (data['companies'] is List) {
          final list = data['companies'] as List;
          final models = list
              .whereType<Map<String, dynamic>>()
              .map((e) => TickerInfoModel.fromJson(e))
              .toList();
          
          await hiveDataSource.saveTickers(
            models.map((e) => e.toJson()).toList(),
          );
          
          return models.map((e) => e.toEntity()).toList();
        }
      }
    } catch (_) {
      // Timeout, no network, or other error. Fall back to cache.
    }

    // Fallback to cache
    try {
      final cachedList = await hiveDataSource.getTickers();
      final models = cachedList
          .map((e) => TickerInfoModel.fromJson(e))
          .toList();
      return models.map((e) => e.toEntity()).toList();
    } catch (_) {
      return [];
    }
  }
}
