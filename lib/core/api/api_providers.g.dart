// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$paperlessApiHash() => r'c7a787cc2cad9ca5a0313cf25e55b69cb6d84b31';

/// See also [paperlessApi].
@ProviderFor(paperlessApi)
final paperlessApiProvider = AutoDisposeProvider<PaperlessApi>.internal(
  paperlessApi,
  name: r'paperlessApiProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$paperlessApiHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PaperlessApiRef = AutoDisposeProviderRef<PaperlessApi>;
String _$tagsHash() => r'8fcd9242a0c34e787404bbd2734d87a96933d75a';

/// All tags, keyed by ID for fast lookup.
///
/// Copied from [tags].
@ProviderFor(tags)
final tagsProvider = FutureProvider<Map<int, Tag>>.internal(
  tags,
  name: r'tagsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$tagsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TagsRef = FutureProviderRef<Map<int, Tag>>;
String _$correspondentsHash() => r'f1c9e5fa4b8143a45d2a6b57d9c8ac5f6261bbc7';

/// All correspondents, keyed by ID.
///
/// Copied from [correspondents].
@ProviderFor(correspondents)
final correspondentsProvider = FutureProvider<Map<int, Correspondent>>.internal(
  correspondents,
  name: r'correspondentsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$correspondentsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CorrespondentsRef = FutureProviderRef<Map<int, Correspondent>>;
String _$documentTypesHash() => r'181fb5597c30138d877615b57c041c0537ac6ecf';

/// All document types, keyed by ID.
///
/// Copied from [documentTypes].
@ProviderFor(documentTypes)
final documentTypesProvider = FutureProvider<Map<int, DocumentType>>.internal(
  documentTypes,
  name: r'documentTypesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$documentTypesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DocumentTypesRef = FutureProviderRef<Map<int, DocumentType>>;
String _$storagePathsHash() => r'ef3508b10e29053b07175e1baf24261c841ea796';

/// All storage paths, keyed by ID.
///
/// Copied from [storagePaths].
@ProviderFor(storagePaths)
final storagePathsProvider = FutureProvider<Map<int, StoragePath>>.internal(
  storagePaths,
  name: r'storagePathsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$storagePathsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StoragePathsRef = FutureProviderRef<Map<int, StoragePath>>;
String _$savedViewsHash() => r'205db81f0ef4c47e7acb349dd824f525dd88733c';

/// All saved views.
///
/// Copied from [savedViews].
@ProviderFor(savedViews)
final savedViewsProvider = FutureProvider<List<SavedView>>.internal(
  savedViews,
  name: r'savedViewsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$savedViewsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SavedViewsRef = FutureProviderRef<List<SavedView>>;
String _$customFieldsHash() => r'0ef29124adbf9ea2a61e0cb73fe9480023dc7c7f';

/// All custom fields, keyed by ID.
///
/// Copied from [customFields].
@ProviderFor(customFields)
final customFieldsProvider = FutureProvider<Map<int, CustomField>>.internal(
  customFields,
  name: r'customFieldsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$customFieldsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CustomFieldsRef = FutureProviderRef<Map<int, CustomField>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
