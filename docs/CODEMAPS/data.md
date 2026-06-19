<!-- Generated: 2026-04-23 | Files scanned: 152 | Token estimate: ~800 -->

# Data Layer

## Models (core/models/)

All models use `@freezed` + `@JsonSerializable` with `explicit_to_json: true` in build.yaml.

| Model | File | Key Fields |
|-------|------|------------|
| Document | document.dart (31L) | id, title, content, tags[], correspondent?, document_type?, storage_path?, created, custom_fields[], notes[], permissions |
| Tag | tag.dart (21L) | id, name, color, text_color, is_inbox_tag, document_count |
| Correspondent | correspondent.dart (21L) | id, name, match, matching_algorithm, document_count |
| DocumentType | document_type.dart (20L) | id, name, match, matching_algorithm |
| StoragePath | storage_path.dart (21L) | id, name, path, match, matching_algorithm |
| CustomField | custom_field.dart (30L) | id, name, data_type (string/url/date/int/float/monetary/document_link/select) |
| SavedView | saved_view.dart (31L) | id, name, sort_field, sort_reverse, filter_rules[] |
| Note | note.dart (27L) | id, note, created, user{id, username} |
| Workflow | workflow.dart (62L) | id, name, order, enabled, triggers[], actions[] |
| DocumentTemplate | document_template.dart (19L) | id, name, correspondent?, document_type?, tags[] |
| PaginatedResponse | api_response.dart (21L) | count, next?, previous?, results[] |

## SQLite Cache (Drift)

Defined in `core/database/app_database.dart` (165L).

| Table | Columns | Purpose |
|-------|---------|---------|
| CachedDocuments | id, jsonData, cachedAt | Offline document browsing |
| CachedTags | id, jsonData, cachedAt | Tag list cache |
| CachedCorrespondents | id, jsonData, cachedAt | Correspondent cache |
| CachedDocumentTypes | id, jsonData, cachedAt | Doc type cache |
| CachedStoragePaths | id, jsonData, cachedAt | Storage path cache |
| CachedSavedViews | id, jsonData, cachedAt | Saved view cache |
| CachedCustomFields | id, jsonData, cachedAt | Custom field cache |
| CachedWorkflows | id, jsonData, cachedAt | Workflow cache |
| PendingUploads | id, filePath, filename, title, correspondent, documentType, tags, customFields, createdDate, asn, status, taskId, errorMessage, createdAt | Upload queue |
| PendingEdits | id, documentId, fieldName, oldValue, newValue, createdAt, synced | Offline edit queue |
| DocumentTemplates | id, name, correspondentId, documentTypeId, tagIds, customFieldValues | Upload presets |

## Cache Strategy

```
Request → CacheRepository.get()
            ├── cache hit + fresh → return cached
            └── cache miss/stale → API fetch → cache upsert → return
```

- `cache_repository.dart` (250L) — all cache read/write logic
- JSON stored as text blobs, deserialized on read
- No TTL enforcement — stale data served if offline

## Auth Storage

- `flutter_secure_storage` for tokens and server profiles
- `secure_storage.dart` (79L) — read/write/delete helpers
- `server_profiles.dart` (181L) — multi-server profile management
- `auth_provider.dart` (266L) — auth state, login, logout, token refresh
