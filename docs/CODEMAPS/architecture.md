<!-- Generated: 2026-04-23 | Files scanned: 152 | Token estimate: ~900 -->

# Architecture

## System Overview

```
Mobile App (Flutter)
    │
    ├── Riverpod (state management)
    ├── Drift/SQLite (offline cache)
    ├── flutter_secure_storage (auth tokens)
    │
    ▼
Paperless-ngx REST API (user-hosted)
    │
    └── Paperless-AI (optional, AI chat via LiteLLM → Claude)
```

## App Architecture

```
main.dart → ProviderScope → PaperlessGoApp (app.dart)
                                │
                    GoRouter (auth-gated redirect)
                                │
               ┌────────────────┼────────────────┐
               ▼                ▼                ▼
          Login Flow      Main Screens      Scanner Flow
          (login/)        (documents/       (scanner/
                           dashboard/        upload/)
                           inbox/
                           search/
                           labels/
                           settings/)
```

## Layer Diagram

```
┌─────────────────────────────────────────┐
│  Screens (ConsumerWidget / StatefulWidget)│
│  features/*_screen.dart                  │
├─────────────────────────────────────────┤
│  Notifiers (@riverpod)                   │
│  features/*_notifier.dart                │
├─────────────────────────────────────────┤
│  API Client (PaperlessApi)               │
│  core/api/paperless_api.dart (528L)      │
├─────────────────────────────────────────┤
│  Models (@freezed + @JsonSerializable)   │
│  core/models/*.dart                      │
├─────────────────────────────────────────┤
│  Cache (Drift/SQLite)                    │
│  core/database/cache_repository.dart     │
├─────────────────────────────────────────┤
│  Auth (token-based, secure storage)      │
│  core/auth/auth_provider.dart            │
└─────────────────────────────────────────┘
```

## Key Patterns

- **State**: Riverpod `@riverpod` annotation → code-gen `.g.dart`
- **Models**: Freezed + json_serializable → `.freezed.dart` + `.g.dart`
- **Offline**: SQLite cache via Drift; edit queue for offline mutations
- **Upload**: Background queue with task polling (`/api/tasks/`)
- **Auth**: Multi-server profiles stored in flutter_secure_storage
- **Navigation**: GoRouter with auth redirect guard
- **Scanner**: Camera → crop → enhance → PDF gen → upload pipeline

## Entry Points

- `lib/main.dart` — app bootstrap (10L)
- `lib/app.dart` — router + theme + share intent handler (633L)
