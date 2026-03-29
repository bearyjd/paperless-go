import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/database/app_database.dart';
import 'package:paperless_go/core/database/database_provider.dart';
import 'package:paperless_go/features/documents/ai_edit_trail_notifier.dart';

AppDatabase _makeInMemoryDb() =>
    AppDatabase(NativeDatabase.memory());

ProviderContainer _makeContainer(AppDatabase db) {
  return ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
    ],
  );
}

void main() {
  group('AiEditTrailNotifier', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = _makeInMemoryDb();
      container = _makeContainer(db);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('starts empty for a new document', () async {
      final trail = await container
          .read(aiEditTrailProvider(99).future);
      expect(trail, isEmpty);
    });

    test('recordEdits writes entries readable by build', () async {
      final notifier = container.read(aiEditTrailProvider(1).notifier);
      await notifier.recordEdits(
        {
          'title': (oldValue: null, newValue: 'Invoice 2026'),
          'correspondent': (oldValue: null, newValue: 'ACME Corp'),
        },
        'ocr_suggestion',
      );
      final trail = await container.read(aiEditTrailProvider(1).future);
      expect(trail.length, 2);
      expect(trail.map((e) => e.fieldName).toSet(),
          containsAll(['title', 'correspondent']));
      expect(trail.first.source, 'ocr_suggestion');
    });

    test('deleteEdit removes the entry', () async {
      final notifier = container.read(aiEditTrailProvider(2).notifier);
      await notifier.recordEdits(
        {'title': (oldValue: null, newValue: 'Test')},
        'ocr_suggestion',
      );
      final before = await container.read(aiEditTrailProvider(2).future);
      expect(before.length, 1);

      await notifier.deleteEdit(before.first.id);

      final after = await container.read(aiEditTrailProvider(2).future);
      expect(after, isEmpty);
    });
  });
}
