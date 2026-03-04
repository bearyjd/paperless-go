// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metadata_suggestion_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$metadataSuggestionsHash() =>
    r'84fc1970c864efe9b1eb65a6e754e943d4f5a9f9';

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

/// Extracts text from a scanned image via OCR and matches it against
/// cached correspondents, document types, and tags to generate suggestions.
///
/// Copied from [metadataSuggestions].
@ProviderFor(metadataSuggestions)
const metadataSuggestionsProvider = MetadataSuggestionsFamily();

/// Extracts text from a scanned image via OCR and matches it against
/// cached correspondents, document types, and tags to generate suggestions.
///
/// Copied from [metadataSuggestions].
class MetadataSuggestionsFamily
    extends Family<AsyncValue<MetadataSuggestions>> {
  /// Extracts text from a scanned image via OCR and matches it against
  /// cached correspondents, document types, and tags to generate suggestions.
  ///
  /// Copied from [metadataSuggestions].
  const MetadataSuggestionsFamily();

  /// Extracts text from a scanned image via OCR and matches it against
  /// cached correspondents, document types, and tags to generate suggestions.
  ///
  /// Copied from [metadataSuggestions].
  MetadataSuggestionsProvider call(String imagePath) {
    return MetadataSuggestionsProvider(imagePath);
  }

  @override
  MetadataSuggestionsProvider getProviderOverride(
    covariant MetadataSuggestionsProvider provider,
  ) {
    return call(provider.imagePath);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'metadataSuggestionsProvider';
}

/// Extracts text from a scanned image via OCR and matches it against
/// cached correspondents, document types, and tags to generate suggestions.
///
/// Copied from [metadataSuggestions].
class MetadataSuggestionsProvider
    extends AutoDisposeFutureProvider<MetadataSuggestions> {
  /// Extracts text from a scanned image via OCR and matches it against
  /// cached correspondents, document types, and tags to generate suggestions.
  ///
  /// Copied from [metadataSuggestions].
  MetadataSuggestionsProvider(String imagePath)
    : this._internal(
        (ref) => metadataSuggestions(ref as MetadataSuggestionsRef, imagePath),
        from: metadataSuggestionsProvider,
        name: r'metadataSuggestionsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$metadataSuggestionsHash,
        dependencies: MetadataSuggestionsFamily._dependencies,
        allTransitiveDependencies:
            MetadataSuggestionsFamily._allTransitiveDependencies,
        imagePath: imagePath,
      );

  MetadataSuggestionsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.imagePath,
  }) : super.internal();

  final String imagePath;

  @override
  Override overrideWith(
    FutureOr<MetadataSuggestions> Function(MetadataSuggestionsRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MetadataSuggestionsProvider._internal(
        (ref) => create(ref as MetadataSuggestionsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        imagePath: imagePath,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<MetadataSuggestions> createElement() {
    return _MetadataSuggestionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MetadataSuggestionsProvider && other.imagePath == imagePath;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, imagePath.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MetadataSuggestionsRef
    on AutoDisposeFutureProviderRef<MetadataSuggestions> {
  /// The parameter `imagePath` of this provider.
  String get imagePath;
}

class _MetadataSuggestionsProviderElement
    extends AutoDisposeFutureProviderElement<MetadataSuggestions>
    with MetadataSuggestionsRef {
  _MetadataSuggestionsProviderElement(super.provider);

  @override
  String get imagePath => (origin as MetadataSuggestionsProvider).imagePath;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
