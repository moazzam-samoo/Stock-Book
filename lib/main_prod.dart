import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/environment_config.dart';
import 'data/local/local_storage.dart';
import 'main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  EnvironmentConfig.environment = Environment.prod;
  
  await LocalStorage.init();
  // TODO: Initialize Firebase, Crashlytics
  
  runApp(const ProviderScope(child: StockTrackerApp()));
}
