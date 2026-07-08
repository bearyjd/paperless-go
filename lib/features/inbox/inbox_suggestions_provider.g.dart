// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inbox_suggestions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$inboxSuggestionsHash() => r'73183bb344387057a92e57060c61bca4779fdbbb';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Metadata suggestions for an inbox document, matched from the server-side
/// OCR text ([Document.content]) — no local OCR needed, so this works in the
/// degoogled build too.
///
/// Suggestions are pre-filtered for the accept flow:
///  - inbox tags and tags already on the document are dropped
///  - correspondent/document type are only suggested when currently unset
///
/// Copied from [inboxSuggestions].
@ProviderFor(inboxSuggestions)
const inboxSuggestionsProvider = InboxSuggestionsFamily();

/// Metadata suggestions for an inbox document, matched from the server-side
/// OCR text ([Document.content]) — no local OCR needed, so this works in the
/// degoogled build too.
///
/// Suggestions are pre-filtered for the accept flow:
///  - inbox tags and tags already on the document are dropped
///  - correspondent/document type are only suggested when currently unset
///
/// Copied from [inboxSuggestions].
class InboxSuggestionsFamily extends Family<AsyncValue<MetadataSuggestions>> {
  /// Metadata suggestions for an inbox document, matched from the server-side
  /// OCR text ([Document.content]) — no local OCR needed, so this works in the
  /// degoogled build too.
  ///
  /// Suggestions are pre-filtered for the accept flow:
  ///  - inbox tags and tags already on the document are dropped
  ///  - correspondent/document type are only suggested when currently unset
  ///
  /// Copied from [inboxSuggestions].
  const InboxSuggestionsFamily();

  /// Metadata suggestions for an inbox document, matched from the server-side
  /// OCR text ([Document.content]) — no local OCR needed, so this works in the
  /// degoogled build too.
  ///
  /// Suggestions are pre-filtered for the accept flow:
  ///  - inbox tags and tags already on the document are dropped
  ///  - correspondent/document type are only suggested when currently unset
  ///
  /// Copied from [inboxSuggestions].
  InboxSuggestionsProvider call(Document doc) {
    return InboxSuggestionsProvider(doc);
  }

  @override
  InboxSuggestionsProvider getProviderOverride(
    covariant InboxSuggestionsProvider provider,
  ) {
    return call(provider.doc);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'inboxSuggestionsProvider';
}

/// Metadata suggestions for an inbox document, matched from the server-side
/// OCR text ([Document.content]) — no local OCR needed, so this works in the
/// degoogled build too.
///
/// Suggestions are pre-filtered for the accept flow:
///  - inbox tags and tags already on the document are dropped
///  - correspondent/document type are only suggested when currently unset
///
/// Copied from [inboxSuggestions].
class InboxSuggestionsProvider
    extends AutoDisposeFutureProvider<MetadataSuggestions> {
  /// Metadata suggestions for an inbox document, matched from the server-side
  /// OCR text ([Document.content]) — no local OCR needed, so this works in the
  /// degoogled build too.
  ///
  /// Suggestions are pre-filtered for the accept flow:
  ///  - inbox tags and tags already on the document are dropped
  ///  - correspondent/document type are only suggested when currently unset
  ///
  /// Copied from [inboxSuggestions].
  InboxSuggestionsProvider(Document doc)
    : this._internal(
        (ref) => inboxSuggestions(ref as InboxSuggestionsRef, doc),
        from: inboxSuggestionsProvider,
        name: r'inboxSuggestionsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$inboxSuggestionsHash,
        dependencies: InboxSuggestionsFamily._dependencies,
        allTransitiveDependencies:
            InboxSuggestionsFamily._allTransitiveDependencies,
        doc: doc,
      );

  InboxSuggestionsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.doc,
  }) : super.internal();

  final Document doc;

  @override
  Override overrideWith(
    FutureOr<MetadataSuggestions> Function(InboxSuggestionsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: InboxSuggestionsProvider._internal(
        (ref) => create(ref as InboxSuggestionsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        doc: doc,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<MetadataSuggestions> createElement() {
    return _InboxSuggestionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is InboxSuggestionsProvider && other.doc == doc;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, doc.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin InboxSuggestionsRef on AutoDisposeFutureProviderRef<MetadataSuggestions> {
  /// The parameter `doc` of this provider.
  Document get doc;
}

class _InboxSuggestionsProviderElement
    extends AutoDisposeFutureProviderElement<MetadataSuggestions>
    with InboxSuggestionsRef {
  _InboxSuggestionsProviderElement(super.provider);

  @override
  Document get doc => (origin as InboxSuggestionsProvider).doc;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
