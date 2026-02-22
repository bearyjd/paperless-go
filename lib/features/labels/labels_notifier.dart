import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/api/api_providers.dart';

part 'labels_notifier.g.dart';

@riverpod
class LabelsNotifier extends _$LabelsNotifier {
  String? _lastError;
  String? get lastError => _lastError;

  @override
  void build() {
    _lastError = null;
  }

  // Tags

  Future<bool> createTag(Map<String, dynamic> data) async {
    try {
      final api = ref.read(paperlessApiProvider);
      await api.createTag(data);
      ref.invalidate(tagsProvider);
      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  Future<bool> updateTag(int id, Map<String, dynamic> data) async {
    try {
      final api = ref.read(paperlessApiProvider);
      await api.updateTag(id, data);
      ref.invalidate(tagsProvider);
      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  Future<bool> deleteTag(int id) async {
    try {
      final api = ref.read(paperlessApiProvider);
      await api.deleteTag(id);
      ref.invalidate(tagsProvider);
      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  // Correspondents

  Future<bool> createCorrespondent(Map<String, dynamic> data) async {
    try {
      final api = ref.read(paperlessApiProvider);
      await api.createCorrespondent(data);
      ref.invalidate(correspondentsProvider);
      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  Future<bool> updateCorrespondent(int id, Map<String, dynamic> data) async {
    try {
      final api = ref.read(paperlessApiProvider);
      await api.updateCorrespondent(id, data);
      ref.invalidate(correspondentsProvider);
      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  Future<bool> deleteCorrespondent(int id) async {
    try {
      final api = ref.read(paperlessApiProvider);
      await api.deleteCorrespondent(id);
      ref.invalidate(correspondentsProvider);
      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  // Document Types

  Future<bool> createDocumentType(Map<String, dynamic> data) async {
    try {
      final api = ref.read(paperlessApiProvider);
      await api.createDocumentType(data);
      ref.invalidate(documentTypesProvider);
      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  Future<bool> updateDocumentType(int id, Map<String, dynamic> data) async {
    try {
      final api = ref.read(paperlessApiProvider);
      await api.updateDocumentType(id, data);
      ref.invalidate(documentTypesProvider);
      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  Future<bool> deleteDocumentType(int id) async {
    try {
      final api = ref.read(paperlessApiProvider);
      await api.deleteDocumentType(id);
      ref.invalidate(documentTypesProvider);
      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  // Storage Paths

  Future<bool> createStoragePath(Map<String, dynamic> data) async {
    try {
      final api = ref.read(paperlessApiProvider);
      await api.createStoragePath(data);
      ref.invalidate(storagePathsProvider);
      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  Future<bool> updateStoragePath(int id, Map<String, dynamic> data) async {
    try {
      final api = ref.read(paperlessApiProvider);
      await api.updateStoragePath(id, data);
      ref.invalidate(storagePathsProvider);
      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  Future<bool> deleteStoragePath(int id) async {
    try {
      final api = ref.read(paperlessApiProvider);
      await api.deleteStoragePath(id);
      ref.invalidate(storagePathsProvider);
      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }
}
