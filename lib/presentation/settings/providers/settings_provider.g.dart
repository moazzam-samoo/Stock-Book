// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$settingsHash() => r'0b9500b18ce54c7080ca3ca19452dd33a489b463';

/// See also [settings].
@ProviderFor(settings)
final settingsProvider = AutoDisposeStreamProvider<UserSettings>.internal(
  settings,
  name: r'settingsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$settingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SettingsRef = AutoDisposeStreamProviderRef<UserSettings>;
String _$settingsControllerHash() =>
    r'b896b5f8ce84c8accbcbc7c7a3c2c53701ed2db4';

/// See also [SettingsController].
@ProviderFor(SettingsController)
final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, void>.internal(
      SettingsController.new,
      name: r'settingsControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$settingsControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SettingsController = AsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
