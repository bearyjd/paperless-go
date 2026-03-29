import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/database/app_database.dart';
import 'package:paperless_go/core/services/document_lock_service.dart';

void main() {
  group('DocumentLockService', () {
    late AppDatabase db;
    late DocumentLockService service;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      service = DocumentLockService(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('isLocked returns false for unlocked doc', () async {
      expect(await service.isLocked(42), false);
    });

    test('isLocked returns true after locking', () async {
      await service.lock(42);
      expect(await service.isLocked(42), true);
    });

    test('unlock removes the lock', () async {
      await service.lock(42);
      await service.unlock(42);
      expect(await service.isLocked(42), false);
    });

    test('getLockedIds returns all locked IDs', () async {
      await service.lock(1);
      await service.lock(5);
      expect(await service.getLockedIds(), containsAll([1, 5]));
    });

    test('locking same doc twice is idempotent', () async {
      await service.lock(42);
      await service.lock(42);
      expect(await service.isLocked(42), true);
      final ids = await service.getLockedIds();
      expect(ids.where((id) => id == 42).length, 1);
    });
  });
}
