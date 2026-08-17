import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pending_upload_store.g.dart';

/// Persistent home for files waiting in the upload queue.
///
/// Everything that feeds the queue hands us an *evictable* path: shares are
/// copied by SharePlugin into Android's `cacheDir`, and generated PDFs land in
/// `getTemporaryDirectory()` (also cacheDir). The OS is free to delete both
/// under storage pressure, and the drain loop drops queue rows whose file has
/// vanished — so a document queued overnight could disappear with no trace.
///
/// Queued files are therefore copied into app-private *documents* storage,
/// which is only cleared when the user clears app data, and removed again once
/// the upload succeeds or is abandoned.
class PendingUploadStore {
  PendingUploadStore(this.directory);

  /// Where persisted copies live. Created lazily on first [persist].
  final Directory directory;

  static const _dirName = 'pending_uploads';

  /// Copies [sourcePath] into persistent storage and returns the new path.
  ///
  /// Returns the input unchanged when it already lives in [directory] (an
  /// upload retried from the queue must not be copied again on every attempt)
  /// or when the source no longer exists — callers keep whatever path they had
  /// rather than losing the reference entirely.
  Future<String> persist(String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) return sourcePath;
    if (p.isWithin(directory.path, sourcePath)) return sourcePath;

    await directory.create(recursive: true);
    final target = _uniqueTarget(p.basename(sourcePath));
    await source.copy(target.path);
    return target.path;
  }

  /// Deletes a persisted copy once its upload has succeeded or been abandoned.
  ///
  /// A path outside [directory] is left alone — it belongs to the caller (an
  /// original scan, a user-picked file), not to this store.
  Future<void> discard(String path) async {
    if (!p.isWithin(directory.path, path)) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  /// Monotonic within the isolate, so two [persist] calls that land on the
  /// same millisecond with the same basename cannot pick the same name.
  /// Checking `existsSync()` first would not be enough — the check and the
  /// copy are separated by an await, so concurrent callers could both observe
  /// "free" and the second copy would overwrite the first.
  static int _sequence = 0;

  File _uniqueTarget(String basename) {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final seq = _sequence++;
    return File(p.join(directory.path, '${stamp}_${seq}_$basename'));
  }
}

@Riverpod(keepAlive: true)
Future<PendingUploadStore> pendingUploadStore(Ref ref) async {
  final documents = await getApplicationDocumentsDirectory();
  return PendingUploadStore(
    Directory(p.join(documents.path, PendingUploadStore._dirName)),
  );
}
