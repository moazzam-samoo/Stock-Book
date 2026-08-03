// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$allLotsHash() => r'f297a6da8772ba98da58121b74937c1f9bd3b23f';

/// See also [allLots].
@ProviderFor(allLots)
final allLotsProvider = AutoDisposeStreamProvider<List<Lot>>.internal(
  allLots,
  name: r'allLotsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$allLotsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllLotsRef = AutoDisposeStreamProviderRef<List<Lot>>;
String _$portfolioSummaryHash() => r'8e0d5eb1ff38a04278a56169331339e1348b2d7e';

/// See also [portfolioSummary].
@ProviderFor(portfolioSummary)
final portfolioSummaryProvider = AutoDisposeProvider<PortfolioSummary>.internal(
  portfolioSummary,
  name: r'portfolioSummaryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$portfolioSummaryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PortfolioSummaryRef = AutoDisposeProviderRef<PortfolioSummary>;
String _$stockSummariesHash() => r'7d310aec7f1e308259318d576e44e9c3baeb055d';

/// See also [stockSummaries].
@ProviderFor(stockSummaries)
final stockSummariesProvider = AutoDisposeProvider<List<StockSummary>>.internal(
  stockSummaries,
  name: r'stockSummariesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$stockSummariesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StockSummariesRef = AutoDisposeProviderRef<List<StockSummary>>;
String _$allocationDataHash() => r'9511e3032feaeda34368e5b5992600dd72d73de8';

/// See also [allocationData].
@ProviderFor(allocationData)
final allocationDataProvider =
    AutoDisposeProvider<List<AllocationSegment>>.internal(
      allocationData,
      name: r'allocationDataProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$allocationDataHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllocationDataRef = AutoDisposeProviderRef<List<AllocationSegment>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
