// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'market_prices_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(watchMarketPrice)
final watchMarketPriceProvider = WatchMarketPriceFamily._();

final class WatchMarketPriceProvider
    extends
        $FunctionalProvider<
          AsyncValue<MarketPrice?>,
          MarketPrice?,
          Stream<MarketPrice?>
        >
    with $FutureModifier<MarketPrice?>, $StreamProvider<MarketPrice?> {
  WatchMarketPriceProvider._({
    required WatchMarketPriceFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'watchMarketPriceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$watchMarketPriceHash();

  @override
  String toString() {
    return r'watchMarketPriceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<MarketPrice?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<MarketPrice?> create(Ref ref) {
    final argument = this.argument as String;
    return watchMarketPrice(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchMarketPriceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$watchMarketPriceHash() => r'cb9a0767aa6dabe0b29913da329029ec302ea794';

final class WatchMarketPriceFamily extends $Family
    with $FunctionalFamilyOverride<Stream<MarketPrice?>, String> {
  WatchMarketPriceFamily._()
    : super(
        retry: null,
        name: r'watchMarketPriceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WatchMarketPriceProvider call(String ticker) =>
      WatchMarketPriceProvider._(argument: ticker, from: this);

  @override
  String toString() => r'watchMarketPriceProvider';
}

@ProviderFor(watchMarketPrices)
final watchMarketPricesProvider = WatchMarketPricesFamily._();

final class WatchMarketPricesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, MarketPrice>>,
          Map<String, MarketPrice>,
          Stream<Map<String, MarketPrice>>
        >
    with
        $FutureModifier<Map<String, MarketPrice>>,
        $StreamProvider<Map<String, MarketPrice>> {
  WatchMarketPricesProvider._({
    required WatchMarketPricesFamily super.from,
    required List<String> super.argument,
  }) : super(
         retry: null,
         name: r'watchMarketPricesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$watchMarketPricesHash();

  @override
  String toString() {
    return r'watchMarketPricesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Map<String, MarketPrice>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, MarketPrice>> create(Ref ref) {
    final argument = this.argument as List<String>;
    return watchMarketPrices(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchMarketPricesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$watchMarketPricesHash() => r'7ea7c2d36392907f3efcb73f531ef30ff61f00be';

final class WatchMarketPricesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<Map<String, MarketPrice>>,
          List<String>
        > {
  WatchMarketPricesFamily._()
    : super(
        retry: null,
        name: r'watchMarketPricesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WatchMarketPricesProvider call(List<String> tickers) =>
      WatchMarketPricesProvider._(argument: tickers, from: this);

  @override
  String toString() => r'watchMarketPricesProvider';
}
