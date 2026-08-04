import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/routing/app_router.dart';

import 'package:stock_investment_tracker/presentation/settings/providers/settings_provider.dart';

class StockTrackerApp extends ConsumerWidget {
  const StockTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final settingsAsync = ref.watch(settingsProvider);
    
    final themeMode = settingsAsync.maybeWhen(
      data: (s) => s.themeMode == 'light' ? ThemeMode.light : ThemeMode.dark,
      orElse: () => ThemeMode.dark,
    );

    return MaterialApp.router(
      title: 'Stock Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
