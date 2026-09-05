// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$allPositionsHash() => r'90dd0e68b6e2c6508d6c1f3a6506ec2ec6fe1978';

/// See also [allPositions].
@ProviderFor(allPositions)
final allPositionsProvider = AutoDisposeStreamProvider<List<Position>>.internal(
  allPositions,
  name: r'allPositionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$allPositionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllPositionsRef = AutoDisposeStreamProviderRef<List<Position>>;
String _$allLotsHash() => r'3a7a2df8945eacc6e8069b7153a5e6d8cd709454';

/// Lots are never deleted by the position migration — they remain the
/// rollback path and the source of truth for the JSON backup export, so this
/// stays available alongside [allPositionsProvider].
///
/// Copied from [allLots].
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
String _$allWithdrawalsHash() => r'3aca2d19da53373ff8600693942e9b6f2fed184f';

/// See also [allWithdrawals].
@ProviderFor(allWithdrawals)
final allWithdrawalsProvider =
    AutoDisposeStreamProvider<List<Withdrawal>>.internal(
      allWithdrawals,
      name: r'allWithdrawalsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$allWithdrawalsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllWithdrawalsRef = AutoDisposeStreamProviderRef<List<Withdrawal>>;
String _$portfolioSummaryHash() => r'42dfb9b2e2efb6ae906ca7e2c3493bf47ba7964f';

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
String _$stockSummariesHash() => r'417f5321a996b0a930c93b71d8316f3248345750';

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
