<!-- Generated: 2026-04-25 | Files scanned: 30+ | Token estimate: ~800 -->

# Paperless Go Codemaps — Index

**Last Updated:** 2026-04-25

Paperless Go is a modern Flutter client for Paperless-ngx with:
- **State Management:** Riverpod + Notifiers
- **HTTP Client:** Dio
- **Database:** Drift/SQLite
- **Navigation:** GoRouter
- **Code Generation:** freezed, json_serializable, riverpod_generator

## Codemap Files

| File | Scope | Purpose |
|------|-------|---------|
| [`architecture.md`](./architecture.md) | System-wide | High-level layers, data flow, auth pipeline |
| [`frontend.md`](./frontend.md) | UI/Navigation | Page tree, widgets, navigation structure, Riverpod providers |
| [`data.md`](./data.md) | API & Models | Paperless-ngx API endpoints, models, Drift tables |
| [`dependencies.md`](./dependencies.md) | External | Pub packages, versions, native integrations |

## Quick Navigation

**User Flow (Login → Browse → Upload):**
1. Start: `LoginScreen` → `auth_provider.dart`
2. Navigate: `DashboardScreen` → `DocumentsScreen`
3. Upload: `ScannerScreen` → `UploadScreen`

**State Management Pattern:**
- Providers: `lib/core/auth/auth_provider.dart`, `lib/core/api/api_providers.dart`
- Notifiers: `lib/features/<feature>/*_notifier.dart`
- Riverpod Generators: `@riverpod` + `dart run build_runner build`

**Data Sources:**
- Remote: `PaperlessApi` → Dio HTTP client
- Local: Drift database + `CacheRepository`
- Queue: `UploadQueueService`, `EditQueueProcessor`

## Key Files Reference

### Core Layer
- `lib/main.dart` — App entry point, ProviderScope setup
- `lib/app.dart` — GoRouter, auth redirect, shell UI
- `lib/core/auth/` — Authentication state, login logic
- `lib/core/api/` — Dio client, API endpoints
- `lib/core/database/` — Drift schema, cache repository

### Feature Screens
- `lib/features/login/` — Credentials & token login
- `lib/features/documents/` — Document list, detail, bulk edit
- `lib/features/scanner/` — Image capture, PDF generation, upload flow
- `lib/features/search/` — Full-text search, similar documents
- `lib/features/upload/` — Upload queue, share intent handler

### Shared
- `lib/shared/widgets/` — Reusable UI components
- `lib/shared/extensions/` — Dart extensions

## Architecture Diagram

```
┌─────────────────────────────────────────────────┐
│            Flutter UI Layer (widgets)            │
│  DocumentsScreen, ScannerScreen, ChatScreen...  │
└────────────────────┬────────────────────────────┘
                     │ ref.watch(provider)
┌────────────────────▼────────────────────────────┐
│     Riverpod State Management Layer              │
│ authStateProvider, documentsProvider, etc.       │
└────────────────────┬────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
    ┌───▼──────┐         ┌──────▼──────┐
    │ Remote   │         │ Local       │
    │ (API)    │         │ (Drift/DB)  │
    │          │         │             │
    │Dio Client│         │CacheRepo    │
    │PaperlessAPI        │EditQueue    │
    └──────────┘         │UploadQueue  │
                         └─────────────┘
                         │
        ┌────────────────┴────────────────┐
        │                                 │
   ┌────▼─────┐                    ┌────▼──────┐
   │ Paperless-│                   │ Native    │
   │ ngx Server│                   │Platforms  │
   │           │                   │(iOS/And)  │
   └───────────┘                   └───────────┘
```

## Testing Structure

```
test/
├── unit/                        # Business logic tests
│   ├── api/                     # API client + mocking
│   ├── models/                  # Serialization tests
│   └── providers/               # Riverpod logic tests
├── widget/                      # Widget tests
└── integration/                 # Critical user flows (device tests)
```

## Development Commands

```bash
# Code generation
dart run build_runner build --delete-conflicting-outputs

# Testing
flutter test                    # All tests
flutter test --coverage         # With coverage report

# Analysis
dart analyze                    # Lint warnings
dart format --set-exit-if-changed .

# Building
flutter build apk --release --obfuscate --split-debug-info=./debug-info/
```

---

**For detailed breakdowns, see individual codemap files.**
