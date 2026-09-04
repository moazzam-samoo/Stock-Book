// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_buy_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AddBuyController)
final addBuyControllerProvider = AddBuyControllerProvider._();

final class AddBuyControllerProvider
    extends $NotifierProvider<AddBuyController, AsyncValue<void>> {
  AddBuyControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addBuyControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addBuyControllerHash();

  @$internal
  @override
  AddBuyController create() => AddBuyController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$addBuyControllerHash() => r'88ad7a1d4cc77ce0b0b81288dd051678b2424102';

abstract class _$AddBuyController extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
