// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transactions_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$filteredPositionsHash() => r'f024b0727b16a8ef393e122bda9f40a6be41c5d6';

/// See also [filteredPositions].
@ProviderFor(filteredPositions)
final filteredPositionsProvider = AutoDisposeProvider<List<Position>>.internal(
  filteredPositions,
  name: r'filteredPositionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$filteredPositionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FilteredPositionsRef = AutoDisposeProviderRef<List<Position>>;
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
String _$statusFilterHash() => r'713886900e1174f1c2e2b16d0cb011761ecde081';

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
