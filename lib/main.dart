import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';

class StockTrackerApp extends ConsumerWidget {
  const StockTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Connect GoRouter here when ready
    return MaterialApp(
      title: 'Stock Tracker',
      theme: AppTheme.darkTheme,
      home: const Scaffold(
        body: Center(
          child: Text('Stock Tracker - MVP Scaffold'),
        ),
      ),
    );
  }
}
