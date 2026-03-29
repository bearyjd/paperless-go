import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';

part 'ai_edit_trail_notifier.g.dart';

class AiEditEntry {
  final int id;
  final int documentId;
  final String fieldName;
  final String? oldValue;
  final String? newValue;
  final String source;
  final DateTime appliedAt;

  const AiEditEntry({
    required this.id,
    required this.documentId,
    required this.fieldName,
    this.oldValue,
    this.newValue,
    required this.source,
    required this.appliedAt,
  });
}

typedef EditMap = Map<String, ({String? oldValue, String? newValue})>;

@riverpod
class AiEditTrail extends _$AiEditTrail {
  @override
  Future<List<AiEditEntry>> build(int documentId) async {
    final db = ref.watch(appDatabaseProvider);
    final rows = await (db.select(db.aiEdits)
          ..where((t) => t.documentId.equals(documentId))
          ..orderBy([(t) => OrderingTerm.desc(t.appliedAt)]))
        .get();
    return rows
        .map(
          (r) => AiEditEntry(
            id: r.id,
            documentId: r.documentId,
            fieldName: r.fieldName,
            oldValue: r.oldValue,
            newValue: r.newValue,
            source: r.source,
            appliedAt: r.appliedAt,
          ),
        )
        .toList();
  }

  Future<void> recordEdits(EditMap edits, String source) async {
    final db = ref.read(appDatabaseProvider);
    for (final entry in edits.entries) {
      await db.into(db.aiEdits).insert(
            AiEditsCompanion.insert(
              documentId: documentId,
              fieldName: entry.key,
              oldValue: Value(entry.value.oldValue),
              newValue: Value(entry.value.newValue),
              source: source,
              appliedAt: DateTime.now(),
            ),
          );
    }
    ref.invalidateSelf();
  }

  Future<void> deleteEdit(int editId) async {
    final db = ref.read(appDatabaseProvider);
    await (db.delete(db.aiEdits)..where((t) => t.id.equals(editId))).go();
    ref.invalidateSelf();
  }
}
