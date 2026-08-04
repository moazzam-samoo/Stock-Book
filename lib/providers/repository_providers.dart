import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_investment_tracker/data/data_sources/local/hive_data_source.dart';
import 'package:stock_investment_tracker/data/data_sources/remote/firestore_data_source.dart';
import 'package:stock_investment_tracker/data/repositories/lot_repository_impl.dart';
import 'package:stock_investment_tracker/data/repositories/sale_repository_impl.dart';
import 'package:stock_investment_tracker/data/repositories/settings_repository_impl.dart';
import 'package:stock_investment_tracker/domain/repositories/lot_repository.dart';
import 'package:stock_investment_tracker/domain/repositories/sale_repository.dart';
import 'package:stock_investment_tracker/domain/repositories/settings_repository.dart';
import 'package:stock_investment_tracker/presentation/auth/providers/auth_providers.dart';

final firebaseFirestoreProvider = Provider<FirebaseFirestore?>((ref) {
  try {
    final instance = FirebaseFirestore.instance;
    instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    return instance;
  } catch (e) {
    // Firebase is not initialized yet in this environment
    return null;
  }
});

final firestoreDataSourceProvider = Provider<FirestoreDataSource?>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  if (firestore == null) return null;
  return FirestoreDataSource(firestore);
});

final hiveDataSourceProvider = Provider<HiveDataSource>((ref) {
  return HiveDataSource();
});

final lotRepositoryProvider = Provider<LotRepository?>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  final dataSource = ref.watch(firestoreDataSourceProvider);
  if (uid == null || dataSource == null) {
    return null; // Return null if not authenticated
  }
  return LotRepositoryImpl(
    uid: uid,
    firestoreDataSource: dataSource,
  );
});

final saleRepositoryProvider = Provider<SaleRepository?>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  final dataSource = ref.watch(firestoreDataSourceProvider);
  if (uid == null || dataSource == null) return null;
  return SaleRepositoryImpl(
    uid: uid,
    firestoreDataSource: dataSource,
  );
});

final settingsRepositoryProvider = Provider<SettingsRepository?>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  final dataSource = ref.watch(firestoreDataSourceProvider);
  if (uid == null || dataSource == null) return null;
  return SettingsRepositoryImpl(
    uid: uid,
    firestoreDataSource: dataSource,
    hiveDataSource: ref.watch(hiveDataSourceProvider),
  );
});
