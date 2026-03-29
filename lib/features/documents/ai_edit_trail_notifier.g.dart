// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_edit_trail_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$aiEditTrailHash() => r'bd03a29296bcc6a5054e2d982f5279d03bd1841b';

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

abstract class _$AiEditTrail
    extends BuildlessAutoDisposeAsyncNotifier<List<AiEditEntry>> {
  late final int documentId;

  FutureOr<List<AiEditEntry>> build(int documentId);
}

/// See also [AiEditTrail].
@ProviderFor(AiEditTrail)
const aiEditTrailProvider = AiEditTrailFamily();

/// See also [AiEditTrail].
class AiEditTrailFamily extends Family<AsyncValue<List<AiEditEntry>>> {
  /// See also [AiEditTrail].
  const AiEditTrailFamily();

  /// See also [AiEditTrail].
  AiEditTrailProvider call(int documentId) {
    return AiEditTrailProvider(documentId);
  }

  @override
  AiEditTrailProvider getProviderOverride(
    covariant AiEditTrailProvider provider,
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
  String? get name => r'aiEditTrailProvider';
}

/// See also [AiEditTrail].
class AiEditTrailProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<AiEditTrail, List<AiEditEntry>> {
  /// See also [AiEditTrail].
  AiEditTrailProvider(int documentId)
    : this._internal(
        () => AiEditTrail()..documentId = documentId,
        from: aiEditTrailProvider,
        name: r'aiEditTrailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$aiEditTrailHash,
        dependencies: AiEditTrailFamily._dependencies,
        allTransitiveDependencies: AiEditTrailFamily._allTransitiveDependencies,
        documentId: documentId,
      );

  AiEditTrailProvider._internal(
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
  FutureOr<List<AiEditEntry>> runNotifierBuild(covariant AiEditTrail notifier) {
    return notifier.build(documentId);
  }

  @override
  Override overrideWith(AiEditTrail Function() create) {
    return ProviderOverride(
      origin: this,
      override: AiEditTrailProvider._internal(
        () => create()..documentId = documentId,
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
  AutoDisposeAsyncNotifierProviderElement<AiEditTrail, List<AiEditEntry>>
  createElement() {
    return _AiEditTrailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AiEditTrailProvider && other.documentId == documentId;
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
mixin AiEditTrailRef on AutoDisposeAsyncNotifierProviderRef<List<AiEditEntry>> {
  /// The parameter `documentId` of this provider.
  int get documentId;
}

class _AiEditTrailProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<AiEditTrail, List<AiEditEntry>>
    with AiEditTrailRef {
  _AiEditTrailProviderElement(super.provider);

  @override
  int get documentId => (origin as AiEditTrailProvider).documentId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
