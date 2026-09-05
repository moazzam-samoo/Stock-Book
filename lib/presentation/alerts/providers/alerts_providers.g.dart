// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alerts_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$allAlertsHash() => r'957ebb3b195aac6040309d1f52d6026db7fe0956';

/// See also [allAlerts].
@ProviderFor(allAlerts)
final allAlertsProvider = AutoDisposeStreamProvider<List<PriceAlert>>.internal(
  allAlerts,
  name: r'allAlertsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$allAlertsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllAlertsRef = AutoDisposeStreamProviderRef<List<PriceAlert>>;
String _$alertsControllerHash() => r'b940c04fc6208146a610568f2322ba56758bef30';

/// See also [AlertsController].
@ProviderFor(AlertsController)
final alertsControllerProvider =
    AsyncNotifierProvider<AlertsController, void>.internal(
      AlertsController.new,
      name: r'alertsControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$alertsControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AlertsController = AsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
