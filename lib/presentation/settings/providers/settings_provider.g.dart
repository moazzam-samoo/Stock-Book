// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$settingsHash() => r'f8e8dbadbdc9e1a751a937aa2b9ae3e7b0921a50';

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
    r'dbddcb17fcd3d6dbc69ee82c5908abe486d54523';

/// See also [SettingsController].
@ProviderFor(SettingsController)
final settingsControllerProvider =
    AutoDisposeAsyncNotifierProvider<SettingsController, void>.internal(
      SettingsController.new,
      name: r'settingsControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$settingsControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SettingsController = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
