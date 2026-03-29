import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/database/app_database.dart';
import 'package:paperless_go/core/services/template_service.dart';

void main() {
  group('TemplateService', () {
    late AppDatabase db;
    late TemplateService service;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      service = TemplateService(db);
    });

    tearDown(() async => await db.close());

    test('getAll returns empty list initially', () async {
      expect(await service.getAll(), isEmpty);
    });

    test('create adds a template', () async {
      final t = await service.create(
        name: 'Invoice',
        correspondentId: 5,
        documentTypeId: 3,
        tagIds: [1, 2],
      );
      expect(t.name, 'Invoice');
      expect(t.correspondentId, 5);
      expect(t.tagIds, [1, 2]);
      expect(t.id, greaterThan(0));
    });

    test('getAll returns created templates', () async {
      await service.create(name: 'A');
      await service.create(name: 'B');
      final all = await service.getAll();
      expect(all.length, 2);
    });

    test('delete removes template', () async {
      final t = await service.create(name: 'Temp');
      await service.delete(t.id);
      expect(await service.getAll(), isEmpty);
    });

    test('update changes name', () async {
      final t = await service.create(name: 'Old');
      await service.update(t.id, name: 'New');
      final all = await service.getAll();
      expect(all.first.name, 'New');
    });
  });
}
