// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'withdrawal_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

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
///
/// Copied from [WithdrawalController].
@ProviderFor(WithdrawalController)
final withdrawalControllerProvider =
    AsyncNotifierProvider<WithdrawalController, void>.internal(
      WithdrawalController.new,
      name: r'withdrawalControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$withdrawalControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$WithdrawalController = AsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
