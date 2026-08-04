import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/config/environment_config.dart';
import 'data/local/local_storage.dart';
import 'main.dart';void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  EnvironmentConfig.environment = Environment.dev;
  
  await LocalStorage.init();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const ProviderScope(child: StockTrackerApp()));
}
