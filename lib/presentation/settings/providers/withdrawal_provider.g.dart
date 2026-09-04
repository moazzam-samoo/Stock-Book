// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'withdrawal_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Mutations for profit withdrawals.
///
/// Reads go through `allWithdrawalsProvider`, which is a live Firestore
/// snapshot stream, so no manual invalidation is needed after a write.
///
/// keepAlive is required here: this notifier is only ever reached via
/// `ref.read(...notifier)`, never `ref.watch`, so nothing keeps a plain
/// autoDispose instance alive. Riverpod tears an unwatched autoDispose
/// provider down as soon as the current widget build ends, which can land
/// mid-flight on a slow Firestore write (e.g. under a weak connection) and
/// throws "Bad state: Future already completed" when the disposed notifier
/// tries to finalize its state afterwards.

@ProviderFor(WithdrawalController)
final withdrawalControllerProvider = WithdrawalControllerProvider._();

/// Mutations for profit withdrawals.
///
/// Reads go through `allWithdrawalsProvider`, which is a live Firestore
/// snapshot stream, so no manual invalidation is needed after a write.
///
/// keepAlive is required here: this notifier is only ever reached via
/// `ref.read(...notifier)`, never `ref.watch`, so nothing keeps a plain
/// autoDispose instance alive. Riverpod tears an unwatched autoDispose
/// provider down as soon as the current widget build ends, which can land
/// mid-flight on a slow Firestore write (e.g. under a weak connection) and
/// throws "Bad state: Future already completed" when the disposed notifier
/// tries to finalize its state afterwards.
final class WithdrawalControllerProvider
    extends $AsyncNotifierProvider<WithdrawalController, void> {
  /// Mutations for profit withdrawals.
  ///
  /// Reads go through `allWithdrawalsProvider`, which is a live Firestore
  /// snapshot stream, so no manual invalidation is needed after a write.
  ///
  /// keepAlive is required here: this notifier is only ever reached via
  /// `ref.read(...notifier)`, never `ref.watch`, so nothing keeps a plain
  /// autoDispose instance alive. Riverpod tears an unwatched autoDispose
  /// provider down as soon as the current widget build ends, which can land
  /// mid-flight on a slow Firestore write (e.g. under a weak connection) and
  /// throws "Bad state: Future already completed" when the disposed notifier
  /// tries to finalize its state afterwards.
  WithdrawalControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'withdrawalControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$withdrawalControllerHash();

  @$internal
  @override
  WithdrawalController create() => WithdrawalController();
}

String _$withdrawalControllerHash() =>
    r'4e313f2d100722981d210a221ef9bd4a01e08825';

/// Mutations for profit withdrawals.
///
/// Reads go through `allWithdrawalsProvider`, which is a live Firestore
/// snapshot stream, so no manual invalidation is needed after a write.
///
/// keepAlive is required here: this notifier is only ever reached via
/// `ref.read(...notifier)`, never `ref.watch`, so nothing keeps a plain
/// autoDispose instance alive. Riverpod tears an unwatched autoDispose
/// provider down as soon as the current widget build ends, which can land
/// mid-flight on a slow Firestore write (e.g. under a weak connection) and
/// throws "Bad state: Future already completed" when the disposed notifier
/// tries to finalize its state afterwards.

abstract class _$WithdrawalController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
