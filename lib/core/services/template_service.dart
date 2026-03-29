import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../models/document_template.dart';

part 'template_service.g.dart';

class TemplateService {
  final AppDatabase _db;
  TemplateService(this._db);

  Future<List<DocumentTemplate>> getAll() async {
    final rows = await _db.select(_db.documentTemplates).get();
    return rows.map((r) {
      final json = jsonDecode(r.jsonData) as Map<String, dynamic>;
      json['id'] = r.id;
      return DocumentTemplate.fromJson(json);
    }).toList();
  }

  Future<DocumentTemplate> create({
    required String name,
    int? correspondentId,
    int? documentTypeId,
    List<int> tagIds = const [],
    int? storagePathId,
  }) async {
    final template = DocumentTemplate(
      id: 0,
      name: name,
      correspondentId: correspondentId,
      documentTypeId: documentTypeId,
      tagIds: tagIds,
      storagePathId: storagePathId,
    );
    final jsonMap = template.toJson()..remove('id');
    final id = await _db.into(_db.documentTemplates).insert(
      DocumentTemplatesCompanion.insert(jsonData: jsonEncode(jsonMap)),
    );
    return template.copyWith(id: id);
  }

  Future<void> delete(int id) async {
    await (_db.delete(_db.documentTemplates)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  Future<void> update(int id, {required String name}) async {
    final row = await (_db.select(_db.documentTemplates)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    final json = jsonDecode(row.jsonData) as Map<String, dynamic>;
    json['name'] = name;
    await (_db.update(_db.documentTemplates)
          ..where((t) => t.id.equals(id)))
        .write(
      DocumentTemplatesCompanion(jsonData: Value(jsonEncode(json))),
    );
  }
}

@Riverpod(keepAlive: true)
TemplateService templateService(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return TemplateService(db);
}

@riverpod
Future<List<DocumentTemplate>> templates(Ref ref) async {
  final service = ref.watch(templateServiceProvider);
  return service.getAll();
}
