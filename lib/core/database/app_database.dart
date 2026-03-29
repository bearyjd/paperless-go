import 'package:drift/drift.dart';

part 'app_database.g.dart';

class CachedDocuments extends Table {
  IntColumn get id => integer()();
  TextColumn get jsonData => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedTags extends Table {
  IntColumn get id => integer()();
  TextColumn get jsonData => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedCorrespondents extends Table {
  IntColumn get id => integer()();
  TextColumn get jsonData => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedDocumentTypes extends Table {
  IntColumn get id => integer()();
  TextColumn get jsonData => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedStoragePaths extends Table {
  IntColumn get id => integer()();
  TextColumn get jsonData => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedSavedViews extends Table {
  IntColumn get id => integer()();
  TextColumn get jsonData => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedCustomFields extends Table {
  IntColumn get id => integer()();
  TextColumn get jsonData => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class PendingUploads extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get filePath => text()();
  TextColumn get filename => text()();
  TextColumn get title => text().nullable()();
  IntColumn get correspondent => integer().nullable()();
  IntColumn get documentType => integer().nullable()();
  TextColumn get tagsJson => text().nullable()();
  DateTimeColumn get created => dateTime().nullable()();
  DateTimeColumn get queuedAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
}

/// Records metadata fields auto-applied from AI suggestions (OCR or chat).
class AiEdits extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get documentId => integer()();
  TextColumn get fieldName => text()();
  TextColumn get oldValue => text().nullable()();
  TextColumn get newValue => text().nullable()();
  /// Source: 'ocr_suggestion' or 'chat'
  TextColumn get source => text()();
  DateTimeColumn get appliedAt => dateTime()();
}

@DriftDatabase(tables: [
  CachedDocuments,
  CachedTags,
  CachedCorrespondents,
  CachedDocumentTypes,
  CachedStoragePaths,
  CachedSavedViews,
  CachedCustomFields,
  PendingUploads,
  AiEdits,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(aiEdits);
      }
    },
  );
}
