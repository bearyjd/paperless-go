import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../auth/auth_provider.dart';
import '../database/cache_provider.dart';
import '../models/correspondent.dart';
import '../models/custom_field.dart';
import '../models/document_type.dart';
import '../models/saved_view.dart';
import '../models/storage_path.dart';
import '../models/tag.dart';
import 'paperless_api.dart';

part 'api_providers.g.dart';

@riverpod
PaperlessApi paperlessApi(Ref ref) {
  final dio = ref.watch(dioProvider);
  return PaperlessApi(dio);
}

/// All tags, keyed by ID for fast lookup.
@Riverpod(keepAlive: true)
Future<Map<int, Tag>> tags(Ref ref) async {
  final api = ref.watch(paperlessApiProvider);
  final cache = ref.watch(cacheRepositoryProvider);
  try {
    final response = await api.getTags(pageSize: 10000);
    final result = {for (final tag in response.results) tag.id: tag};
    await cache.cacheTags(result);
    return result;
  } catch (e) {
    final cached = await cache.getCachedTags();
    if (cached.isNotEmpty) return cached;
    rethrow;
  }
}

/// All correspondents, keyed by ID.
@Riverpod(keepAlive: true)
Future<Map<int, Correspondent>> correspondents(Ref ref) async {
  final api = ref.watch(paperlessApiProvider);
  final cache = ref.watch(cacheRepositoryProvider);
  try {
    final response = await api.getCorrespondents(pageSize: 10000);
    final result = {for (final c in response.results) c.id: c};
    await cache.cacheCorrespondents(result);
    return result;
  } catch (e) {
    final cached = await cache.getCachedCorrespondents();
    if (cached.isNotEmpty) return cached;
    rethrow;
  }
}

/// All document types, keyed by ID.
@Riverpod(keepAlive: true)
Future<Map<int, DocumentType>> documentTypes(Ref ref) async {
  final api = ref.watch(paperlessApiProvider);
  final cache = ref.watch(cacheRepositoryProvider);
  try {
    final response = await api.getDocumentTypes(pageSize: 10000);
    final result = {for (final dt in response.results) dt.id: dt};
    await cache.cacheDocumentTypes(result);
    return result;
  } catch (e) {
    final cached = await cache.getCachedDocumentTypes();
    if (cached.isNotEmpty) return cached;
    rethrow;
  }
}

/// All storage paths, keyed by ID.
@Riverpod(keepAlive: true)
Future<Map<int, StoragePath>> storagePaths(Ref ref) async {
  final api = ref.watch(paperlessApiProvider);
  final cache = ref.watch(cacheRepositoryProvider);
  try {
    final response = await api.getStoragePaths(pageSize: 10000);
    final result = {for (final sp in response.results) sp.id: sp};
    await cache.cacheStoragePaths(result);
    return result;
  } catch (e) {
    final cached = await cache.getCachedStoragePaths();
    if (cached.isNotEmpty) return cached;
    rethrow;
  }
}

/// All saved views.
@Riverpod(keepAlive: true)
Future<List<SavedView>> savedViews(Ref ref) async {
  final api = ref.watch(paperlessApiProvider);
  final cache = ref.watch(cacheRepositoryProvider);
  try {
    final response = await api.getSavedViews(pageSize: 10000);
    final result = response.results;
    await cache.cacheSavedViews(result);
    return result;
  } catch (e) {
    final cached = await cache.getCachedSavedViews();
    if (cached.isNotEmpty) return cached;
    rethrow;
  }
}

/// All custom fields, keyed by ID.
@Riverpod(keepAlive: true)
Future<Map<int, CustomField>> customFields(Ref ref) async {
  final api = ref.watch(paperlessApiProvider);
  final cache = ref.watch(cacheRepositoryProvider);
  try {
    final response = await api.getCustomFields(pageSize: 10000);
    final result = {for (final cf in response.results) cf.id: cf};
    await cache.cacheCustomFields(result);
    return result;
  } catch (e) {
    final cached = await cache.getCachedCustomFields();
    if (cached.isNotEmpty) return cached;
    rethrow;
  }
}
