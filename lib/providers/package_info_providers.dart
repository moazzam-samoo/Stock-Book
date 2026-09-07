import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// App version/build number, read from the platform (versionName/versionCode
/// on Android) rather than hardcoded — this is the one place it should ever
/// be read from, so a version bump in pubspec.yaml is reflected everywhere
/// without touching UI code.
final packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});
