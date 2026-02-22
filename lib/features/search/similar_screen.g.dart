// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'similar_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$similarDocumentsHash() => r'eb2c28930d60496502dcdd106cb9684b84c9dd43';

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

/// See also [similarDocuments].
@ProviderFor(similarDocuments)
const similarDocumentsProvider = SimilarDocumentsFamily();

/// See also [similarDocuments].
class SimilarDocumentsFamily extends Family<AsyncValue<List<Document>>> {
  /// See also [similarDocuments].
  const SimilarDocumentsFamily();

  /// See also [similarDocuments].
  SimilarDocumentsProvider call(int documentId) {
    return SimilarDocumentsProvider(documentId);
  }

  @override
  SimilarDocumentsProvider getProviderOverride(
    covariant SimilarDocumentsProvider provider,
  ) {
    return call(provider.documentId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'similarDocumentsProvider';
}

/// See also [similarDocuments].
class SimilarDocumentsProvider
    extends AutoDisposeFutureProvider<List<Document>> {
  /// See also [similarDocuments].
  SimilarDocumentsProvider(int documentId)
    : this._internal(
        (ref) => similarDocuments(ref as SimilarDocumentsRef, documentId),
        from: similarDocumentsProvider,
        name: r'similarDocumentsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$similarDocumentsHash,
        dependencies: SimilarDocumentsFamily._dependencies,
        allTransitiveDependencies:
            SimilarDocumentsFamily._allTransitiveDependencies,
        documentId: documentId,
      );

  SimilarDocumentsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.documentId,
  }) : super.internal();

  final int documentId;

  @override
  Override overrideWith(
    FutureOr<List<Document>> Function(SimilarDocumentsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SimilarDocumentsProvider._internal(
        (ref) => create(ref as SimilarDocumentsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        documentId: documentId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Document>> createElement() {
    return _SimilarDocumentsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SimilarDocumentsProvider && other.documentId == documentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, documentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SimilarDocumentsRef on AutoDisposeFutureProviderRef<List<Document>> {
  /// The parameter `documentId` of this provider.
  int get documentId;
}

class _SimilarDocumentsProviderElement
    extends AutoDisposeFutureProviderElement<List<Document>>
    with SimilarDocumentsRef {
  _SimilarDocumentsProviderElement(super.provider);

  @override
  int get documentId => (origin as SimilarDocumentsProvider).documentId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
