// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_sell_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AddSellController)
final addSellControllerProvider = AddSellControllerProvider._();

final class AddSellControllerProvider
    extends $NotifierProvider<AddSellController, AsyncValue<void>> {
  AddSellControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addSellControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addSellControllerHash();

  @$internal
  @override
  AddSellController create() => AddSellController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$addSellControllerHash() => r'122db3d579be048beed20f7fc61027917d174bb4';

abstract class _$AddSellController extends $Notifier<AsyncValue<void>> {
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
