import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:stock_investment_tracker/data/data_sources/local/hive_data_source.dart';
import 'package:stock_investment_tracker/data/local/local_storage.dart';
import 'package:stock_investment_tracker/data/models/tax_settings_model.dart';
import 'package:stock_investment_tracker/data/models/user_settings_model.dart';

void main() {
  late Directory tempDir;
  late HiveDataSource dataSource;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_user_isolation_test');
    Hive.init(tempDir.path);
    dataSource = HiveDataSource();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  UserSettingsModel createSettings({
    required double capital,
    required List<String> pinned,
    String theme = 'dark',
  }) {
    return UserSettingsModel(
      favorites: const ['SYS', 'ENGRO'],
      startingCapital: capital,
      currency: 'PKR',
      themeMode: theme,
      pinnedTickers: pinned,
      isPremiumUnlocked: true,
      taxSettings: const TaxSettingsModel(),
    );
  }

  group('Hive per-user settings isolation (C2)', () {
    test('settings are namespaced by uid and do not bleed across accounts', () async {
      const userA = 'uid_user_a';
      const userB = 'uid_user_b';

      final settingsA = createSettings(capital: 150000, pinned: ['OGDC'], theme: 'dark');
      final settingsB = createSettings(capital: 900000, pinned: ['HUBC', 'LUCK'], theme: 'light');

      // Save for both users
      await dataSource.saveSettings(userA, settingsA);
      await dataSource.saveSettings(userB, settingsB);

      // Verify user A reads only user A's settings
      final readA = await dataSource.getSettings(userA);
      expect(readA, isNotNull);
      expect(readA!.startingCapital, 150000);
      expect(readA.pinnedTickers, ['OGDC']);
      expect(readA.themeMode, 'dark');

      // Verify user B reads only user B's settings
      final readB = await dataSource.getSettings(userB);
      expect(readB, isNotNull);
      expect(readB!.startingCapital, 900000);
      expect(readB.pinnedTickers, ['HUBC', 'LUCK']);
      expect(readB.themeMode, 'light');
    });

    test('clearSettings clears only the targeted user settings', () async {
      const userA = 'uid_user_a';
      const userB = 'uid_user_b';

      await dataSource.saveSettings(userA, createSettings(capital: 10000, pinned: ['SYS']));
      await dataSource.saveSettings(userB, createSettings(capital: 20000, pinned: ['ENGRO']));

      // Clear user A on sign-out
      await dataSource.clearSettings(userA);

      expect(await dataSource.getSettings(userA), isNull);
      final readB = await dataSource.getSettings(userB);
      expect(readB, isNotNull);
      expect(readB!.startingCapital, 20000);
    });

    test('clearAllUserSettings removes all user settings keys', () async {
      await dataSource.saveSettings('u1', createSettings(capital: 10, pinned: []));
      await dataSource.saveSettings('u2', createSettings(capital: 20, pinned: []));

      await dataSource.clearAllUserSettings();

      expect(await dataSource.getSettings('u1'), isNull);
      expect(await dataSource.getSettings('u2'), isNull);
    });

    test('LocalStorage.getCachedThemeMode retrieves un-namespaced theme cache', () async {
      await dataSource.saveSettings('user_xyz', createSettings(capital: 500, pinned: [], theme: 'dark'));

      final cachedTheme = LocalStorage.getCachedThemeMode();
      expect(cachedTheme, 'dark');
    });
  });
}

