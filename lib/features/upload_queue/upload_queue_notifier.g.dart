// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_queue_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pendingUploadsHash() => r'cd564af291020e83bbba45df9f434fd68bfbc245';

/// Every queued upload, live.
///
/// Copied from [pendingUploads].
@ProviderFor(pendingUploads)
final pendingUploadsProvider =
    AutoDisposeStreamProvider<List<PendingUpload>>.internal(
      pendingUploads,
      name: r'pendingUploadsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$pendingUploadsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PendingUploadsRef = AutoDisposeStreamProviderRef<List<PendingUpload>>;
String _$uploadsNeedingAttentionHash() =>
    r'ecab142acb73b5f6edd777762d8ebe873ccbe5fd';

/// How many rows need the user to do something.
///
/// Drives the Settings badge and the inbox banner, and deliberately counts only
/// failed and legacy rows — a queue of uploads waiting for signal is normal and
/// interrupting someone about it would train them to ignore the badge.
///
/// Copied from [uploadsNeedingAttention].
@ProviderFor(uploadsNeedingAttention)
final uploadsNeedingAttentionProvider = AutoDisposeProvider<int>.internal(
  uploadsNeedingAttention,
  name: r'uploadsNeedingAttentionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$uploadsNeedingAttentionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UploadsNeedingAttentionRef = AutoDisposeProviderRef<int>;
String _$uploadQueueActionsHash() =>
    r'60689e5f079b640509c2516a6c2d708273978e94';

/// Actions the queue screen can take on a row.
///
/// Separate from [UploadQueueService], which owns the drain. This is the user
/// asking for something; that is the app deciding on its own. Keeping them
/// apart means a retry button cannot accidentally change drain policy.
///
/// Copied from [UploadQueueActions].
@ProviderFor(UploadQueueActions)
final uploadQueueActionsProvider =
    AutoDisposeNotifierProvider<UploadQueueActions, void>.internal(
      UploadQueueActions.new,
      name: r'uploadQueueActionsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$uploadQueueActionsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$UploadQueueActions = AutoDisposeNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
