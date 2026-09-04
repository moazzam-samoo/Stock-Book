// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(allPositions)
final allPositionsProvider = AllPositionsProvider._();

final class AllPositionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Position>>,
          List<Position>,
          Stream<List<Position>>
        >
    with $FutureModifier<List<Position>>, $StreamProvider<List<Position>> {
  AllPositionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allPositionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allPositionsHash();

  @$internal
  @override
  $StreamProviderElement<List<Position>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Position>> create(Ref ref) {
    return allPositions(ref);
  }
}

String _$allPositionsHash() => r'90dd0e68b6e2c6508d6c1f3a6506ec2ec6fe1978';

/// Lots are never deleted by the position migration — they remain the
/// rollback path and the source of truth for the JSON backup export, so this
/// stays available alongside [allPositionsProvider].

@ProviderFor(allLots)
final allLotsProvider = AllLotsProvider._();

/// Lots are never deleted by the position migration — they remain the
/// rollback path and the source of truth for the JSON backup export, so this
/// stays available alongside [allPositionsProvider].

final class AllLotsProvider
    extends
        $FunctionalProvider<AsyncValue<List<Lot>>, List<Lot>, Stream<List<Lot>>>
    with $FutureModifier<List<Lot>>, $StreamProvider<List<Lot>> {
  /// Lots are never deleted by the position migration — they remain the
  /// rollback path and the source of truth for the JSON backup export, so this
  /// stays available alongside [allPositionsProvider].
  AllLotsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allLotsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allLotsHash();

  @$internal
  @override
  $StreamProviderElement<List<Lot>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Lot>> create(Ref ref) {
    return allLots(ref);
  }
}

String _$allLotsHash() => r'3a7a2df8945eacc6e8069b7153a5e6d8cd709454';

@ProviderFor(allWithdrawals)
final allWithdrawalsProvider = AllWithdrawalsProvider._();

final class AllWithdrawalsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Withdrawal>>,
          List<Withdrawal>,
          Stream<List<Withdrawal>>
        >
    with $FutureModifier<List<Withdrawal>>, $StreamProvider<List<Withdrawal>> {
  AllWithdrawalsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allWithdrawalsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allWithdrawalsHash();

  @$internal
  @override
  $StreamProviderElement<List<Withdrawal>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Withdrawal>> create(Ref ref) {
    return allWithdrawals(ref);
  }
}

String _$allWithdrawalsHash() => r'3aca2d19da53373ff8600693942e9b6f2fed184f';

@ProviderFor(portfolioSummary)
final portfolioSummaryProvider = PortfolioSummaryProvider._();

final class PortfolioSummaryProvider
    extends
        $FunctionalProvider<
          PortfolioSummary,
          PortfolioSummary,
          PortfolioSummary
        >
    with $Provider<PortfolioSummary> {
  PortfolioSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'portfolioSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$portfolioSummaryHash();

  @$internal
  @override
  $ProviderElement<PortfolioSummary> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PortfolioSummary create(Ref ref) {
    return portfolioSummary(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PortfolioSummary value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PortfolioSummary>(value),
    );
  }
}

String _$portfolioSummaryHash() => r'42dfb9b2e2efb6ae906ca7e2c3493bf47ba7964f';

@ProviderFor(stockSummaries)
final stockSummariesProvider = StockSummariesProvider._();

final class StockSummariesProvider
    extends
        $FunctionalProvider<
          List<StockSummary>,
          List<StockSummary>,
          List<StockSummary>
        >
    with $Provider<List<StockSummary>> {
  StockSummariesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'stockSummariesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$stockSummariesHash();

  @$internal
  @override
  $ProviderElement<List<StockSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<StockSummary> create(Ref ref) {
    return stockSummaries(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<StockSummary> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<StockSummary>>(value),
    );
  }
}

String _$stockSummariesHash() => r'417f5321a996b0a930c93b71d8316f3248345750';

@ProviderFor(allocationData)
final allocationDataProvider = AllocationDataProvider._();

final class AllocationDataProvider
    extends
        $FunctionalProvider<
          List<AllocationSegment>,
          List<AllocationSegment>,
          List<AllocationSegment>
        >
    with $Provider<List<AllocationSegment>> {
  AllocationDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allocationDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allocationDataHash();

  @$internal
  @override
  $ProviderElement<List<AllocationSegment>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<AllocationSegment> create(Ref ref) {
    return allocationData(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<AllocationSegment> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<AllocationSegment>>(value),
    );
  }
}

String _$allocationDataHash() => r'9511e3032feaeda34368e5b5992600dd72d73de8';
