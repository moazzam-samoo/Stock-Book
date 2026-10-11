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
String _$adminTaxRatesHash() => r'10c717bb8738a623cea591e329aea52c6642e473';

/// See also [adminTaxRates].
@ProviderFor(adminTaxRates)
final adminTaxRatesProvider = AutoDisposeStreamProvider<AdminTaxRates>.internal(
  adminTaxRates,
  name: r'adminTaxRatesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$adminTaxRatesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AdminTaxRatesRef = AutoDisposeStreamProviderRef<AdminTaxRates>;
String _$effectiveTaxRatesHash() => r'0b3cfcf6afe62ed158c8165b8384ebf189c27ecb';

/// See also [effectiveTaxRates].
@ProviderFor(effectiveTaxRates)
final effectiveTaxRatesProvider =
    AutoDisposeProvider<EffectiveTaxRates>.internal(
      effectiveTaxRates,
      name: r'effectiveTaxRatesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$effectiveTaxRatesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef EffectiveTaxRatesRef = AutoDisposeProviderRef<EffectiveTaxRates>;
String _$settingsControllerHash() =>
    r'bc04fce7ed43700c1450ceb2b946fbdf9bdbb21b';

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
