// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'market_status_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(watchMarketStatus)
final watchMarketStatusProvider = WatchMarketStatusProvider._();

final class WatchMarketStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<MarketStatus?>,
          MarketStatus?,
          Stream<MarketStatus?>
        >
    with $FutureModifier<MarketStatus?>, $StreamProvider<MarketStatus?> {
  WatchMarketStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchMarketStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchMarketStatusHash();

  @$internal
  @override
  $StreamProviderElement<MarketStatus?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<MarketStatus?> create(Ref ref) {
    return watchMarketStatus(ref);
  }
}

String _$watchMarketStatusHash() => r'19a9ff6425adcb308557472eff5b32514225d32b';
