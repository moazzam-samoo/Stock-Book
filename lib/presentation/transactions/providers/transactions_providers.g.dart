// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transactions_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$filteredLotsHash() => r'255c431fb9dec36b5833fd35199eb3ee914680ab';

/// See also [filteredLots].
@ProviderFor(filteredLots)
final filteredLotsProvider = AutoDisposeProvider<List<Lot>>.internal(
  filteredLots,
  name: r'filteredLotsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$filteredLotsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FilteredLotsRef = AutoDisposeProviderRef<List<Lot>>;
String _$searchQueryHash() => r'32848c18dd36b350439a45fa6338bf2df6758978';

/// See also [SearchQuery].
@ProviderFor(SearchQuery)
final searchQueryProvider =
    AutoDisposeNotifierProvider<SearchQuery, String>.internal(
      SearchQuery.new,
      name: r'searchQueryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$searchQueryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SearchQuery = AutoDisposeNotifier<String>;
String _$statusFilterHash() => r'85ae72f38ec9f9b0030a662608a87076c99ea915';

/// See also [StatusFilter].
@ProviderFor(StatusFilter)
final statusFilterProvider =
    AutoDisposeNotifierProvider<StatusFilter, String>.internal(
      StatusFilter.new,
      name: r'statusFilterProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$statusFilterHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$StatusFilter = AutoDisposeNotifier<String>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
