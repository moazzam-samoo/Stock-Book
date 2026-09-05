// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'market_prices_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$watchMarketPriceHash() => r'cb9a0767aa6dabe0b29913da329029ec302ea794';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [watchMarketPrice].
@ProviderFor(watchMarketPrice)
const watchMarketPriceProvider = WatchMarketPriceFamily();

/// See also [watchMarketPrice].
class WatchMarketPriceFamily extends Family<AsyncValue<MarketPrice?>> {
  /// See also [watchMarketPrice].
  const WatchMarketPriceFamily();

  /// See also [watchMarketPrice].
  WatchMarketPriceProvider call(String ticker) {
    return WatchMarketPriceProvider(ticker);
  }

  @override
  WatchMarketPriceProvider getProviderOverride(
    covariant WatchMarketPriceProvider provider,
  ) {
    return call(provider.ticker);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'watchMarketPriceProvider';
}

/// See also [watchMarketPrice].
class WatchMarketPriceProvider extends AutoDisposeStreamProvider<MarketPrice?> {
  /// See also [watchMarketPrice].
  WatchMarketPriceProvider(String ticker)
    : this._internal(
        (ref) => watchMarketPrice(ref as WatchMarketPriceRef, ticker),
        from: watchMarketPriceProvider,
        name: r'watchMarketPriceProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$watchMarketPriceHash,
        dependencies: WatchMarketPriceFamily._dependencies,
        allTransitiveDependencies:
            WatchMarketPriceFamily._allTransitiveDependencies,
        ticker: ticker,
      );

  WatchMarketPriceProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.ticker,
  }) : super.internal();

  final String ticker;

  @override
  Override overrideWith(
    Stream<MarketPrice?> Function(WatchMarketPriceRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WatchMarketPriceProvider._internal(
        (ref) => create(ref as WatchMarketPriceRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        ticker: ticker,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<MarketPrice?> createElement() {
    return _WatchMarketPriceProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchMarketPriceProvider && other.ticker == ticker;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, ticker.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin WatchMarketPriceRef on AutoDisposeStreamProviderRef<MarketPrice?> {
  /// The parameter `ticker` of this provider.
  String get ticker;
}

class _WatchMarketPriceProviderElement
    extends AutoDisposeStreamProviderElement<MarketPrice?>
    with WatchMarketPriceRef {
  _WatchMarketPriceProviderElement(super.provider);

  @override
  String get ticker => (origin as WatchMarketPriceProvider).ticker;
}

String _$watchMarketPricesHash() => r'7ea7c2d36392907f3efcb73f531ef30ff61f00be';

/// See also [watchMarketPrices].
@ProviderFor(watchMarketPrices)
const watchMarketPricesProvider = WatchMarketPricesFamily();

/// See also [watchMarketPrices].
class WatchMarketPricesFamily
    extends Family<AsyncValue<Map<String, MarketPrice>>> {
  /// See also [watchMarketPrices].
  const WatchMarketPricesFamily();

  /// See also [watchMarketPrices].
  WatchMarketPricesProvider call(List<String> tickers) {
    return WatchMarketPricesProvider(tickers);
  }

  @override
  WatchMarketPricesProvider getProviderOverride(
    covariant WatchMarketPricesProvider provider,
  ) {
    return call(provider.tickers);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'watchMarketPricesProvider';
}

/// See also [watchMarketPrices].
class WatchMarketPricesProvider
    extends AutoDisposeStreamProvider<Map<String, MarketPrice>> {
  /// See also [watchMarketPrices].
  WatchMarketPricesProvider(List<String> tickers)
    : this._internal(
        (ref) => watchMarketPrices(ref as WatchMarketPricesRef, tickers),
        from: watchMarketPricesProvider,
        name: r'watchMarketPricesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$watchMarketPricesHash,
        dependencies: WatchMarketPricesFamily._dependencies,
        allTransitiveDependencies:
            WatchMarketPricesFamily._allTransitiveDependencies,
        tickers: tickers,
      );

  WatchMarketPricesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.tickers,
  }) : super.internal();

  final List<String> tickers;

  @override
  Override overrideWith(
    Stream<Map<String, MarketPrice>> Function(WatchMarketPricesRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WatchMarketPricesProvider._internal(
        (ref) => create(ref as WatchMarketPricesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        tickers: tickers,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<Map<String, MarketPrice>> createElement() {
    return _WatchMarketPricesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchMarketPricesProvider && other.tickers == tickers;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, tickers.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin WatchMarketPricesRef
    on AutoDisposeStreamProviderRef<Map<String, MarketPrice>> {
  /// The parameter `tickers` of this provider.
  List<String> get tickers;
}

class _WatchMarketPricesProviderElement
    extends AutoDisposeStreamProviderElement<Map<String, MarketPrice>>
    with WatchMarketPricesRef {
  _WatchMarketPricesProviderElement(super.provider);

  @override
  List<String> get tickers => (origin as WatchMarketPricesProvider).tickers;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
