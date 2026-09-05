import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_investment_tracker/data/data_sources/local/hive_data_source.dart';
import 'package:stock_investment_tracker/data/data_sources/remote/firestore_data_source.dart';
import 'package:stock_investment_tracker/data/repositories/lot_repository_impl.dart';
import 'package:stock_investment_tracker/data/repositories/position_repository_impl.dart';
import 'package:stock_investment_tracker/data/repositories/sale_repository_impl.dart';
import 'package:stock_investment_tracker/data/repositories/settings_repository_impl.dart';
import 'package:stock_investment_tracker/data/repositories/withdrawal_repository_impl.dart';
import 'package:stock_investment_tracker/domain/repositories/lot_repository.dart';
import 'package:stock_investment_tracker/domain/repositories/position_repository.dart';
import 'package:stock_investment_tracker/domain/repositories/sale_repository.dart';
import 'package:stock_investment_tracker/domain/repositories/settings_repository.dart';
import 'package:stock_investment_tracker/domain/repositories/withdrawal_repository.dart';
import 'package:stock_investment_tracker/domain/repositories/market_price_repository.dart';
import 'package:stock_investment_tracker/data/repositories/market_price_repository_impl.dart';
import 'package:stock_investment_tracker/data/repositories/market_status_repository_impl.dart';
import 'package:stock_investment_tracker/domain/repositories/market_status_repository.dart';
import 'package:stock_investment_tracker/domain/repositories/user_repository.dart';
import 'package:stock_investment_tracker/data/repositories/user_repository_impl.dart';
import 'package:stock_investment_tracker/domain/repositories/price_alert_repository.dart';
import 'package:stock_investment_tracker/data/repositories/price_alert_repository_impl.dart';
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
  final firestoreSource = ref.watch(firestoreDataSourceProvider);
  if (uid == null || firestoreSource == null) return null;
  return SaleRepositoryImpl(
    uid: uid,
    firestoreDataSource: firestoreSource,
  );
});

final positionRepositoryProvider = Provider<PositionRepository?>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  final firestoreSource = ref.watch(firestoreDataSourceProvider);
  if (uid == null || firestoreSource == null) return null;
  return PositionRepositoryImpl(firestoreSource, uid);
});

final withdrawalRepositoryProvider = Provider<WithdrawalRepository?>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  final dataSource = ref.watch(firestoreDataSourceProvider);
  if (uid == null || dataSource == null) return null;
  return WithdrawalRepositoryImpl(
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

final marketPriceRepositoryProvider = Provider<MarketPriceRepository?>((ref) {
  final firestoreSource = ref.watch(firestoreDataSourceProvider);
  final hiveSource = ref.watch(hiveDataSourceProvider);
  final uid = ref.watch(currentUserIdProvider);
  
  if (uid == null || firestoreSource == null) return null;
  
  return MarketPriceRepositoryImpl(
    firestoreDataSource: firestoreSource,
    hiveDataSource: hiveSource,
  );
});

final marketStatusRepositoryProvider = Provider<MarketStatusRepository?>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final uid = ref.watch(currentUserIdProvider);

  if (uid == null || firestore == null) return null;

  return MarketStatusRepositoryImpl(firestore: firestore);
});

final userRepositoryProvider = Provider<UserRepository?>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  final firestore = ref.watch(firebaseFirestoreProvider);
  
  if (uid == null || firestore == null) return null;
  
  return UserRepositoryImpl(
    uid: uid,
    firestore: firestore,
  );
});

final priceAlertRepositoryProvider = Provider<PriceAlertRepository?>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  final firestoreSource = ref.watch(firestoreDataSourceProvider);
  if (uid == null || firestoreSource == null) return null;
  return PriceAlertRepositoryImpl(firestoreSource, uid);
});
