import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'core/config/environment_config.dart';
import 'core/services/push_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'data/local/local_storage.dart';
import 'presentation/routing/app_router.dart';
import 'presentation/settings/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  EnvironmentConfig.environment = Environment.dev;

  await LocalStorage.init();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Must be registered before runApp, and must be a top-level function — this
  // is what lets a push alert display even when the app is fully closed, not
  // just backgrounded.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const ProviderScope(child: StockTrackerApp()));
}

class StockTrackerApp extends ConsumerWidget {
  const StockTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final settingsAsync = ref.watch(settingsProvider);

    return MaterialApp.router(
      title: 'Stock Book',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeModeFrom(settingsAsync.valueOrNull?.themeMode),
      routerConfig: router,
    );
  }
}

/// Maps the persisted `themeMode` string onto Flutter's [ThemeMode].
/// Falls back to light, which is both the stored default and what the app
/// shows while settings are still loading.
@visibleForTesting
ThemeMode themeModeFrom(String? themeMode) {
  switch (themeMode) {
    case 'dark':
      return ThemeMode.dark;
    case 'system':
      return ThemeMode.system;
    case 'light':
    default:
      return ThemeMode.light;
  }
}
