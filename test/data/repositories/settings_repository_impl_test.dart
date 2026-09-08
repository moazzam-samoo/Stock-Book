import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stock_investment_tracker/data/data_sources/local/hive_data_source.dart';
import 'package:stock_investment_tracker/data/data_sources/remote/firestore_data_source.dart';
import 'package:stock_investment_tracker/data/models/user_settings_model.dart';
import 'package:stock_investment_tracker/data/repositories/settings_repository_impl.dart';
import 'package:stock_investment_tracker/domain/entities/pin_result.dart';
import 'package:stock_investment_tracker/domain/entities/premium_code_result.dart';

import 'settings_repository_impl_test.mocks.dart';

@GenerateMocks([FirestoreDataSource, HiveDataSource])
void main() {
  late MockFirestoreDataSource mockFirestore;
  late MockHiveDataSource mockHive;
  late SettingsRepositoryImpl repository;
  const uid = 'test-uid';

  UserSettingsModel settingsWith({
    List<String> pinnedTickers = const [],
    bool isPremiumUnlocked = false,
  }) {
    return UserSettingsModel(
      favorites: const [],
      startingCapital: 0.0,
      currency: 'PKR',
      themeMode: 'light',
      pinnedTickers: pinnedTickers,
      isPremiumUnlocked: isPremiumUnlocked,
    );
  }

  setUp(() {
    mockFirestore = MockFirestoreDataSource();
    mockHive = MockHiveDataSource();
    repository = SettingsRepositoryImpl(
      uid: uid,
      firestoreDataSource: mockFirestore,
      hiveDataSource: mockHive,
    );
    when(mockHive.saveSettings(any)).thenAnswer((_) async {});
    when(mockFirestore.updateSettings(uid, any)).thenAnswer((_) async {});
  });

  group('togglePin', () {
    test('pins a ticker when under the free limit', () async {
      when(mockHive.getSettings()).thenAnswer((_) async => settingsWith());

      final result = await repository.togglePin('gusm');

      expect(result, PinResult.pinned);
      final saved = verify(mockHive.saveSettings(captureAny)).captured.single as UserSettingsModel;
      expect(saved.pinnedTickers, ['GUSM']);
    });

    test('unpins an already-pinned ticker', () async {
      when(mockHive.getSettings()).thenAnswer((_) async => settingsWith(pinnedTickers: ['GUSM']));

      final result = await repository.togglePin('GUSM');

      expect(result, PinResult.unpinned);
      final saved = verify(mockHive.saveSettings(captureAny)).captured.single as UserSettingsModel;
      expect(saved.pinnedTickers, isEmpty);
    });

    test('blocks a 6th pin on the free tier without writing anything', () async {
      when(mockHive.getSettings()).thenAnswer(
        (_) async => settingsWith(pinnedTickers: ['A', 'B', 'C', 'D', 'E']),
      );

      final result = await repository.togglePin('F');

      expect(result, PinResult.limitReached);
      verifyNever(mockHive.saveSettings(any));
    });

    test('allows a 6th pin when premium is unlocked', () async {
      when(mockHive.getSettings()).thenAnswer(
        (_) async => settingsWith(pinnedTickers: ['A', 'B', 'C', 'D', 'E'], isPremiumUnlocked: true),
      );

      final result = await repository.togglePin('F');

      expect(result, PinResult.pinned);
    });
  });

  group('redeemPremiumCode', () {
    test('unlocks premium on a valid, unredeemed code', () async {
      when(mockHive.getSettings()).thenAnswer((_) async => settingsWith());
      when(mockFirestore.redeemPremiumCode(code: 'STCK-AAAA-BBBB', uid: uid))
          .thenAnswer((_) async => 'success');

      final result = await repository.redeemPremiumCode('stck-aaaa-bbbb');

      expect(result.outcome, PremiumCodeOutcome.success);
      final saved = verify(mockHive.saveSettings(captureAny)).captured.single as UserSettingsModel;
      expect(saved.isPremiumUnlocked, isTrue);
    });

    test('reports invalidCode without touching local settings', () async {
      when(mockFirestore.redeemPremiumCode(code: 'BADCODE', uid: uid))
          .thenAnswer((_) async => 'invalidCode');

      final result = await repository.redeemPremiumCode('BADCODE');

      expect(result.outcome, PremiumCodeOutcome.invalidCode);
      verifyNever(mockHive.saveSettings(any));
    });

    test('reports alreadyRedeemed without touching local settings', () async {
      when(mockFirestore.redeemPremiumCode(code: 'USED-CODE', uid: uid))
          .thenAnswer((_) async => 'alreadyRedeemed');

      final result = await repository.redeemPremiumCode('USED-CODE');

      expect(result.outcome, PremiumCodeOutcome.alreadyRedeemed);
      verifyNever(mockHive.saveSettings(any));
    });

    test('reports networkError when the data source throws', () async {
      when(mockFirestore.redeemPremiumCode(code: 'ANY-CODE', uid: uid))
          .thenThrow(Exception('timeout'));

      final result = await repository.redeemPremiumCode('ANY-CODE');

      expect(result.outcome, PremiumCodeOutcome.networkError);
    });
  });
}
