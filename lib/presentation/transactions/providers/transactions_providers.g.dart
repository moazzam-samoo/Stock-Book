// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transactions_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SearchQuery)
final searchQueryProvider = SearchQueryProvider._();

final class SearchQueryProvider extends $NotifierProvider<SearchQuery, String> {
  SearchQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchQueryHash();

  @$internal
  @override
  SearchQuery create() => SearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$searchQueryHash() => r'32848c18dd36b350439a45fa6338bf2df6758978';

abstract class _$SearchQuery extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(StatusFilter)
final statusFilterProvider = StatusFilterProvider._();

final class StatusFilterProvider
    extends $NotifierProvider<StatusFilter, String> {
  StatusFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'statusFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$statusFilterHash();

  @$internal
  @override
  StatusFilter create() => StatusFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$statusFilterHash() => r'713886900e1174f1c2e2b16d0cb011761ecde081';

abstract class _$StatusFilter extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(filteredPositions)
final filteredPositionsProvider = FilteredPositionsProvider._();

final class FilteredPositionsProvider
    extends $FunctionalProvider<List<Position>, List<Position>, List<Position>>
    with $Provider<List<Position>> {
  FilteredPositionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredPositionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredPositionsHash();

  @$internal
  @override
  $ProviderElement<List<Position>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Position> create(Ref ref) {
    return filteredPositions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Position> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Position>>(value),
    );
  }
}

String _$filteredPositionsHash() => r'8398e38b10b0062296be8dbafc555ef265d55c9d';
