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

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  final instance = FirebaseFirestore.instance;
  // Enable offline persistence
  instance.settings = const Settings(persistenceEnabled: true);
  return instance;
});

final firestoreDataSourceProvider = Provider<FirestoreDataSource>((ref) {
  return FirestoreDataSource(ref.watch(firebaseFirestoreProvider));
});

final hiveDataSourceProvider = Provider<HiveDataSource>((ref) {
  return HiveDataSource();
});

final lotRepositoryProvider = Provider<LotRepository?>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.maybeWhen(
    data: (user) {
      if (user == null) return null;
      return LotRepositoryImpl(
        uid: user.id,
        firestoreDataSource: ref.watch(firestoreDataSourceProvider),
      );
    },
    orElse: () => null,
  );
});

final saleRepositoryProvider = Provider<SaleRepository?>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.maybeWhen(
    data: (user) {
      if (user == null) return null;
      return SaleRepositoryImpl(
        uid: user.id,
        firestoreDataSource: ref.watch(firestoreDataSourceProvider),
      );
    },
    orElse: () => null,
  );
});

final settingsRepositoryProvider = Provider<SettingsRepository?>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.maybeWhen(
    data: (user) {
      if (user == null) return null;
      return SettingsRepositoryImpl(
        uid: user.id,
        firestoreDataSource: ref.watch(firestoreDataSourceProvider),
        hiveDataSource: ref.watch(hiveDataSourceProvider),
      );
    },
    orElse: () => null,
  );
});
