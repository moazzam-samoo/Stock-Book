import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/config/environment_config.dart';
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
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}

