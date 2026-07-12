import 'dart:convert';

import 'package:drift/drift.dart';

import '../models/correspondent.dart';
import '../models/custom_field.dart';
import '../models/document_type.dart';
import '../models/saved_view.dart';
import '../models/storage_path.dart';
import '../models/tag.dart';
import '../models/workflow.dart';
import 'app_database.dart';

class CacheRepository {
  final AppDatabase _db;

  CacheRepository(this._db);

  // Tags

  Future<Map<int, Tag>> getCachedTags() async {
    final rows = await _db.select(_db.cachedTags).get();
    return {
      for (final row in rows)
        row.id: Tag.fromJson(jsonDecode(row.jsonData) as Map<String, dynamic>),
    };
  }

  Future<void> cacheTags(Map<int, Tag> tags) async {
    await _db.batch((batch) {
      batch.deleteAll(_db.cachedTags);
      batch.insertAll(
        _db.cachedTags,
        tags.entries.map((e) => CachedTagsCompanion.insert(
              id: Value(e.key),
              jsonData: jsonEncode(e.value.toJson()),
              cachedAt: DateTime.now(),
            )),
      );
    });
  }

  // Correspondents

  Future<Map<int, Correspondent>> getCachedCorrespondents() async {
    final rows = await _db.select(_db.cachedCorrespondents).get();
    return {
      for (final row in rows)
        row.id: Correspondent.fromJson(
            jsonDecode(row.jsonData) as Map<String, dynamic>),
    };
  }

  Future<void> cacheCorrespondents(Map<int, Correspondent> items) async {
    await _db.batch((batch) {
      batch.deleteAll(_db.cachedCorrespondents);
      batch.insertAll(
        _db.cachedCorrespondents,
        items.entries.map((e) => CachedCorrespondentsCompanion.insert(
              id: Value(e.key),
              jsonData: jsonEncode(e.value.toJson()),
              cachedAt: DateTime.now(),
            )),
      );
    });
  }

  // Document Types

  Future<Map<int, DocumentType>> getCachedDocumentTypes() async {
    final rows = await _db.select(_db.cachedDocumentTypes).get();
    return {
      for (final row in rows)
        row.id: DocumentType.fromJson(
            jsonDecode(row.jsonData) as Map<String, dynamic>),
    };
  }

  Future<void> cacheDocumentTypes(Map<int, DocumentType> items) async {
    await _db.batch((batch) {
      batch.deleteAll(_db.cachedDocumentTypes);
      batch.insertAll(
        _db.cachedDocumentTypes,
        items.entries.map((e) => CachedDocumentTypesCompanion.insert(
              id: Value(e.key),
              jsonData: jsonEncode(e.value.toJson()),
              cachedAt: DateTime.now(),
            )),
      );
    });
  }

  // Storage Paths

  Future<Map<int, StoragePath>> getCachedStoragePaths() async {
    final rows = await _db.select(_db.cachedStoragePaths).get();
    return {
      for (final row in rows)
        row.id: StoragePath.fromJson(
            jsonDecode(row.jsonData) as Map<String, dynamic>),
    };
  }

  Future<void> cacheStoragePaths(Map<int, StoragePath> items) async {
    await _db.batch((batch) {
      batch.deleteAll(_db.cachedStoragePaths);
      batch.insertAll(
        _db.cachedStoragePaths,
        items.entries.map((e) => CachedStoragePathsCompanion.insert(
              id: Value(e.key),
              jsonData: jsonEncode(e.value.toJson()),
              cachedAt: DateTime.now(),
            )),
      );
    });
  }

  // Saved Views

  Future<List<SavedView>> getCachedSavedViews() async {
    final rows = await _db.select(_db.cachedSavedViews).get();
    return rows
        .map((row) => SavedView.fromJson(
            jsonDecode(row.jsonData) as Map<String, dynamic>))
        .toList();
  }

  Future<void> cacheSavedViews(List<SavedView> items) async {
    await _db.batch((batch) {
      batch.deleteAll(_db.cachedSavedViews);
      batch.insertAll(
        _db.cachedSavedViews,
        items.map((e) => CachedSavedViewsCompanion.insert(
              id: Value(e.id),
              jsonData: jsonEncode(e.toJson()),
              cachedAt: DateTime.now(),
            )),
      );
    });
  }

  // Custom Fields

  Future<Map<int, CustomField>> getCachedCustomFields() async {
    final rows = await _db.select(_db.cachedCustomFields).get();
    return {
      for (final row in rows)
        row.id: CustomField.fromJson(
            jsonDecode(row.jsonData) as Map<String, dynamic>),
    };
  }

  Future<void> cacheCustomFields(Map<int, CustomField> items) async {
    await _db.batch((batch) {
      batch.deleteAll(_db.cachedCustomFields);
      batch.insertAll(
        _db.cachedCustomFields,
        items.entries.map((e) => CachedCustomFieldsCompanion.insert(
              id: Value(e.key),
              jsonData: jsonEncode(e.value.toJson()),
              cachedAt: DateTime.now(),
            )),
      );
    });
  }

  // Workflows

  Future<List<Workflow>> getCachedWorkflows() async {
    final rows = await _db.select(_db.cachedWorkflows).get();
    return rows
        .map((row) => Workflow.fromJson(
            jsonDecode(row.jsonData) as Map<String, dynamic>))
        .toList();
  }

  Future<void> cacheWorkflows(List<Workflow> items) async {
    await _db.batch((batch) {
      batch.deleteAll(_db.cachedWorkflows);
      batch.insertAll(
        _db.cachedWorkflows,
        items.map((e) => CachedWorkflowsCompanion.insert(
              id: Value(e.id),
              jsonData: jsonEncode(e.toJson()),
              cachedAt: DateTime.now(),
            )),
      );
    });
  }

  // Pending Uploads

  Future<void> enqueueUpload({
    required String filePath,
    required String filename,
    String? title,
    int? correspondent,
    int? documentType,
    List<int>? tags,
    DateTime? created,
  }) async {
    await _db.into(_db.pendingUploads).insert(PendingUploadsCompanion.insert(
          filePath: filePath,
          filename: filename,
          title: Value(title),
          correspondent: Value(correspondent),
          documentType: Value(documentType),
          tagsJson: Value(tags != null ? jsonEncode(tags) : null),
          created: Value(created),
          queuedAt: DateTime.now(),
        ));
  }

  Future<List<PendingUpload>> getPendingUploads() async {
    return _db.select(_db.pendingUploads).get();
  }

  Future<List<PendingUpload>> getFailedUploads() async {
    return (_db.select(_db.pendingUploads)
          ..where((t) => t.isFailed.equals(true)))
        .get();
  }

  Future<void> removePendingUpload(int id) async {
    await (_db.delete(_db.pendingUploads)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  /// Records a failed upload attempt. Once [maxRetries] is reached the
  /// upload is marked terminally failed so the drain loop stops retrying it
  /// silently forever and the UI can surface it.
  Future<void> incrementRetryCount(
    int id,
    String error, {
    required int maxRetries,
  }) async {
    final row = await (_db.select(_db.pendingUploads)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    final newRetryCount = row.retryCount + 1;
    await (_db.update(_db.pendingUploads)..where((t) => t.id.equals(id)))
        .write(PendingUploadsCompanion(
      retryCount: Value(newRetryCount),
      lastError: Value(error),
      isFailed: Value(newRetryCount >= maxRetries),
    ));
  }

  // Clear all

  Future<void> clearAll() async {
    await _db.batch((batch) {
      batch.deleteAll(_db.cachedDocuments);
      batch.deleteAll(_db.cachedTags);
      batch.deleteAll(_db.cachedCorrespondents);
      batch.deleteAll(_db.cachedDocumentTypes);
      batch.deleteAll(_db.cachedStoragePaths);
      batch.deleteAll(_db.cachedSavedViews);
      batch.deleteAll(_db.cachedCustomFields);
      batch.deleteAll(_db.cachedWorkflows);
      batch.deleteAll(_db.pendingUploads);
    });
  }
}
