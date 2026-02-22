import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_database.dart';

AppDatabase constructDatabase() {
  final db = LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'paperless_cache.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
  return AppDatabase(db);
}
