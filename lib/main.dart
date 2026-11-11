import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/config/environment_config.dart';
import 'core/services/push_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'data/local/local_storage.dart';
import 'firebase_options.dart';
import 'presentation/routing/app_router.dart';
import 'presentation/settings/providers/settings_provider.dart';

Future<void> bootstrapApp({Environment? environment}) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable runtime fetching of fonts since bundled fonts are packaged with the app
  GoogleFonts.config.allowRuntimeFetching = false;

  // Set environment: defaults to prod in release mode, otherwise dev
  EnvironmentConfig.environment = environment ??
      (kReleaseMode ? Environment.prod : Environment.dev);

  // Initialize Crashlytics error handlers in release mode or prod environment
  if (kReleaseMode || EnvironmentConfig.environment == Environment.prod) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    } catch (_) {
      // Allow startup to proceed if Firebase setup fails initially
    }
  }

  // Initialize local storage with corruption recovery
  try {
    await LocalStorage.init();
  } catch (_) {
    await LocalStorage.recoverFromCorruption();
  }

  // Ensure Firebase is initialized if not done already
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Styled error screen for release mode
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (kReleaseMode) {
      return Material(
        color: const Color(0xFF13151B),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.amber, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'An unexpected error occurred. Please restart Shares Book.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return ErrorWidget(details.exception);
  };

  // Must be registered before runApp, and must be a top-level function — this
  // is what lets a push alert display even when the app is fully closed, not
  // just backgrounded.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const ProviderScope(child: StockTrackerApp()));
}

void main() async {
  await bootstrapApp();
}

class StockTrackerApp extends ConsumerWidget {
  const StockTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final themeModeStr =
        settingsAsync.valueOrNull?.themeMode ?? LocalStorage.getCachedThemeMode();

    return MaterialApp.router(
      title: 'Shares Book',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeModeFrom(themeModeStr),
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
