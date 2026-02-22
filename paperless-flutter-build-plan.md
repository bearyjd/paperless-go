# Paperless Go — Fresh Flutter Client for Paperless-ngx

## Project: `paperless_go`
**Goal:** A clean, modern Flutter Android client for Paperless-ngx that connects to your self-hosted instance at `paperless.grepon.cc` (VM-201 @ `192.168.1.21:8082`) over Tailscale. Built from scratch against API v9 with zero legacy debt.

**Why "Go":** Short, memorable, implies action. `cc.grepon.paperless_go` as the package ID.

---

## Design Philosophy

1. **Clean over clever** — Material 3, sensible defaults, nothing cluttered
2. **Inbox-first** — the home screen IS the inbox. New docs demand action, not statistics
3. **Scan is a first-class citizen** — one tap from anywhere to scan
4. **AI-native** — integrate with your Paperless-AI (LiteLLM) for chat/search from day one
5. **Offline-capable** — cache document metadata + thumbnails locally
6. **Your infrastructure** — Tailscale-aware, direct server comms, no cloud dependency

---

## Architecture

```
┌──────────────────────────────────────────────────────┐
│                   Flutter App (Dart)                  │
│                                                       │
│  ┌───────────┐ ┌───────────┐ ┌──────────┐ ┌────────┐│
│  │  Inbox    │ │ Documents │ │ Scanner  │ │ AI Chat││
│  │  (home)   │ │ Browser   │ │ (camera) │ │        ││
│  └─────┬─────┘ └─────┬─────┘ └────┬─────┘ └───┬────┘│
│        │              │            │            │     │
│  ┌─────┴──────────────┴────────────┴────────────┴───┐│
│  │              Riverpod State Layer                 ││
│  │  • DocumentsNotifier  • LabelsNotifier           ││
│  │  • InboxNotifier      • TasksNotifier            ││
│  │  • AuthNotifier       • SettingsNotifier         ││
│  └──────────────────────┬───────────────────────────┘│
│                         │                             │
│  ┌──────────────────────┴───────────────────────────┐│
│  │            PaperlessApiClient (Dio)               ││
│  │  • Token auth (Authorization: Token <token>)      ││
│  │  • API v9 Accept header                           ││
│  │  • Auto-retry + exponential backoff               ││
│  │  • Request/response logging (debug)               ││
│  │  • Redirect handling (followRedirects: true)      ││
│  └──────────────────────┬───────────────────────────┘│
│                         │                             │
│  ┌──────────────────────┴───────────────────────────┐│
│  │         Local Cache (Drift / SQLite)              ││
│  │  • Document metadata    • Thumbnail cache         ││
│  │  • Tags/correspondents  • Offline queue           ││
│  └──────────────────────────────────────────────────┘│
│                                                       │
│  ┌──────────────────────────────────────────────────┐│
│  │       Secure Storage (flutter_secure_storage)     ││
│  │  • Server URL    • API token    • Biometric flag  ││
│  └──────────────────────────────────────────────────┘│
└────────────────────────┬─────────────────────────────┘
                         │ HTTPS
                         ▼
          ┌─────────────────────────────┐
          │   Paperless-ngx (VM-201)    │
          │   paperless.grepon.cc:8082  │
          │   API v9 + Django REST      │
          └─────────────┬───────────────┘
                        │
          ┌─────────────┴───────────────┐
          │   Paperless-AI (VM-201)     │
          │   :8083 → LiteLLM → Claude  │
          └─────────────────────────────┘
```

---

## API v9 Endpoints Map

All requests include:
```
Accept: application/json; version=9
Authorization: Token <api_token>
```

### Core CRUD Endpoints (Django REST standard)

| Endpoint | Methods | Purpose |
|----------|---------|---------|
| `/api/token/` | POST | Auth — exchange username/password for token |
| `/api/documents/` | GET, POST | List/filter documents, full-text search via `?query=` |
| `/api/documents/{id}/` | GET, PUT, PATCH, DELETE | Single document CRUD |
| `/api/documents/{id}/preview/` | GET | PDF preview (or `?original=true`) |
| `/api/documents/{id}/thumb/` | GET | Thumbnail image |
| `/api/documents/{id}/download/` | GET | Download file |
| `/api/documents/{id}/metadata/` | GET | File metadata |
| `/api/documents/{id}/notes/` | GET, POST, DELETE | Document notes |
| `/api/documents/{id}/share_links/` | GET, POST, DELETE | Share links |
| `/api/documents/post_document/` | POST | Upload new document (multipart) |
| `/api/documents/bulk_edit/` | POST | Bulk operations (tag, delete, merge, split, rotate, etc.) |
| `/api/tags/` | GET, POST | List/create tags |
| `/api/tags/{id}/` | GET, PUT, PATCH, DELETE | Single tag CRUD |
| `/api/correspondents/` | GET, POST | List/create correspondents |
| `/api/correspondents/{id}/` | GET, PUT, PATCH, DELETE | Single correspondent CRUD |
| `/api/document_types/` | GET, POST | List/create document types |
| `/api/document_types/{id}/` | GET, PUT, PATCH, DELETE | Single document type CRUD |
| `/api/storage_paths/` | GET, POST | List/create storage paths |
| `/api/storage_paths/{id}/` | GET, PUT, PATCH, DELETE | Single storage path CRUD |
| `/api/saved_views/` | GET, POST | List/create saved views |
| `/api/saved_views/{id}/` | GET, PUT, PATCH, DELETE | Single saved view CRUD |
| `/api/custom_fields/` | GET, POST | List/create custom fields |
| `/api/custom_fields/{id}/` | GET, PUT, PATCH, DELETE | Single custom field CRUD |
| `/api/tasks/` | GET | List background tasks (consumption status) |
| `/api/tasks/acknowledge/` | POST | Acknowledge completed tasks |
| `/api/search/autocomplete/` | GET | Search term autocomplete (`?term=&limit=`) |
| `/api/statistics/` | GET | Dashboard statistics |
| `/api/ui_settings/` | GET, POST | User UI preferences |
| `/api/workflows/` | GET, POST | Automation workflows |
| `/api/logs/` | GET | Server logs (admin only) |
| `/api/trash/` | GET | Trashed documents |
| `/api/bulk_edit_objects/` | POST | Bulk edit tags/correspondents/types |

### Key Query Parameters for `/api/documents/`

| Parameter | Example | Purpose |
|-----------|---------|---------|
| `query` | `?query=invoice 2024` | Full-text search |
| `more_like_id` | `?more_like_id=123` | Similar documents |
| `tags__id__in` | `?tags__id__in=1,2,3` | Filter by tag IDs |
| `correspondent__id` | `?correspondent__id=5` | Filter by correspondent |
| `document_type__id` | `?document_type__id=2` | Filter by document type |
| `is_in_inbox` | `?is_in_inbox=true` | Inbox documents only |
| `created__date__gt` | `?created__date__gt=2024-01-01` | Date range filter |
| `ordering` | `?ordering=-created` | Sort order |
| `page` | `?page=2` | Pagination |
| `page_size` | `?page_size=25` | Results per page |
| `custom_field_query` | `?custom_field_query=[...]` | Custom field filters (JSON) |
| `truncate_content` | `?truncate_content=true` | Truncate content field |

### Upload (POST `/api/documents/post_document/`)

Multipart form with fields:
- `document` (required): The file
- `title`: Override title
- `created`: Date string
- `correspondent`: ID
- `document_type`: ID
- `storage_path`: ID
- `tags`: ID (repeat for multiple)
- `archive_serial_number`: ASN
- `custom_fields`: JSON array of IDs or object of ID→value

Returns `200` with task UUID. Poll `/api/tasks/?task_id={uuid}` for status.

---

## Dependencies (`pubspec.yaml`)

```yaml
name: paperless_go
description: A modern Paperless-ngx client
version: 1.0.0

environment:
  sdk: ">=3.2.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1

  # Networking
  dio: ^5.7.0
  retrofit: ^4.4.1
  # NOTE: Configure Dio with followRedirects: true and
  # validateStatus that accepts 2xx to avoid 302 errors
  # (the exact issue that broke Paperless Mobile's chat)

  # Local Database
  drift: ^2.22.1
  sqlite3_flutter_libs: ^0.5.28

  # Secure Storage
  flutter_secure_storage: ^9.2.4

  # Document Scanner
  cunning_document_scanner: ^2.2.2
  # Modern replacement for edge_detection (which used OpenCV 3.4.5)
  # Uses ML Kit for edge detection — no native OpenCV dependency

  # PDF Viewing
  pdfx: ^2.8.0

  # Image Caching
  cached_network_image: ^3.4.1

  # UI
  flutter_markdown: ^0.7.4
  google_fonts: ^6.2.1
  shimmer: ^3.0.0              # Loading skeletons
  pull_to_refresh: ^2.0.0

  # Utilities
  json_annotation: ^4.9.0
  freezed_annotation: ^2.4.6
  connectivity_plus: ^6.1.1
  share_plus: ^10.1.4
  url_launcher: ^6.3.1
  path_provider: ^2.1.5
  file_picker: ^8.1.6
  intl: ^0.19.0
  local_auth: ^2.3.0          # Biometric lock
  permission_handler: ^11.3.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.14
  json_serializable: ^6.9.4
  riverpod_generator: ^2.6.3
  freezed: ^2.5.7
  retrofit_generator: ^9.1.7
  drift_dev: ^2.22.1
  flutter_lints: ^5.0.0
```

---

## Directory Structure

```
lib/
├── main.dart                        # App entry, ProviderScope, MaterialApp
├── app.dart                         # GoRouter config, theme
│
├── core/
│   ├── api/
│   │   ├── paperless_api.dart       # Retrofit interface (all endpoints)
│   │   ├── paperless_api.g.dart     # Generated
│   │   ├── dio_client.dart          # Dio setup: interceptors, auth, API v9 header
│   │   └── api_interceptors.dart    # Logging, retry, redirect handling
│   ├── db/
│   │   ├── app_database.dart        # Drift database definition
│   │   ├── app_database.g.dart      # Generated
│   │   └── tables.dart              # Document, Tag, Correspondent tables
│   ├── auth/
│   │   ├── auth_service.dart        # Login, token management, biometric
│   │   └── secure_storage.dart      # flutter_secure_storage wrapper
│   ├── models/                      # Freezed data classes
│   │   ├── document.dart
│   │   ├── tag.dart
│   │   ├── correspondent.dart
│   │   ├── document_type.dart
│   │   ├── saved_view.dart
│   │   ├── custom_field.dart
│   │   ├── task.dart
│   │   └── api_response.dart        # Paginated response wrapper
│   ├── theme.dart                   # Material 3 theme, color scheme
│   └── constants.dart               # API version, defaults
│
├── features/
│   ├── inbox/
│   │   ├── inbox_screen.dart        # HOME SCREEN — inbox-first design
│   │   ├── inbox_card.dart          # Clean document card widget
│   │   └── inbox_notifier.dart      # Riverpod notifier
│   │
│   ├── documents/
│   │   ├── documents_screen.dart    # Browse all documents
│   │   ├── document_detail.dart     # View/edit single document
│   │   ├── document_preview.dart    # PDF viewer
│   │   ├── documents_notifier.dart
│   │   └── document_filter.dart     # Filter/sort UI
│   │
│   ├── scanner/
│   │   ├── scanner_screen.dart      # Camera-based document scanner
│   │   ├── scan_review.dart         # Preview + crop before upload
│   │   ├── scan_metadata.dart       # Set tags/correspondent/type pre-upload
│   │   └── scanner_service.dart     # Scanner → PDF → upload pipeline
│   │
│   ├── upload/
│   │   ├── upload_screen.dart       # Pick file from device
│   │   ├── upload_metadata.dart     # Set metadata before upload
│   │   └── upload_service.dart      # Multipart upload + task polling
│   │
│   ├── search/
│   │   ├── search_screen.dart       # Full-text search + autocomplete
│   │   └── search_notifier.dart
│   │
│   ├── labels/
│   │   ├── labels_screen.dart       # Manage tags, correspondents, types
│   │   ├── tag_editor.dart
│   │   ├── correspondent_editor.dart
│   │   └── labels_notifier.dart
│   │
│   ├── ai_chat/
│   │   ├── chat_screen.dart         # Chat with Paperless-AI
│   │   ├── chat_service.dart        # HTTP client → Paperless-AI :8083
│   │   └── chat_notifier.dart
│   │
│   ├── settings/
│   │   ├── settings_screen.dart
│   │   ├── server_config.dart       # Server URL, token, connection test
│   │   └── appearance.dart          # Theme, density, etc.
│   │
│   └── login/
│       ├── login_screen.dart        # Server URL + credentials
│       ├── server_discovery.dart    # Optional: mDNS/Tailscale detection
│       └── login_notifier.dart
│
└── shared/
    ├── widgets/
    │   ├── tag_chip.dart            # Colored tag chip
    │   ├── document_card.dart       # Reusable document card
    │   ├── empty_state.dart         # "No documents" placeholder
    │   ├── error_state.dart         # Error with retry
    │   └── loading_skeleton.dart    # Shimmer loading
    └── extensions/
        ├── date_extensions.dart
        └── string_extensions.dart
```

---

## Screen-by-Screen Design

### 1. Login Screen
- Server URL field (with `https://` prefix auto-add)
- Username / password fields
- "Login with Token" toggle (paste API token directly)
- Connection test button (hits `/api/statistics/` to verify)
- After login: store token in secure storage, navigate to inbox
- Support for multiple servers (switch between home/remote)

### 2. Inbox (HOME SCREEN)
This is the most important screen. It replaces the useless statistics dashboard.

```
┌─────────────────────────────────┐
│  🔍 Search documents...     [≡] │  ← Search bar + hamburger
├─────────────────────────────────┤
│  Inbox (12 new)                 │  ← Section header with count
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │
│ │ 📄 Tax Return 2024          │ │  ← Clean card: title prominent
│ │ Klausner & Co · Tax Doc     │ │  ← Correspondent · Type (small)
│ │ Jan 3, 2024                 │ │  ← Date
│ │ [Income] [Tax] [Self-Emp..] │ │  ← Tags: max 3 visible + "+N"
│ └─────────────────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ 📄 Wicked Musical Ticket    │ │
│ │ Wicked the Musical · Ticket │ │
│ │ Sep 14, 2024                │ │
│ │ [Entertainment] [Tickets]   │ │
│ └─────────────────────────────┘ │
│                                 │
│          ... more cards ...     │
│                                 │
├────────┬────────┬───────┬───────┤
│  📥    │  📄    │  📷   │  💬  │  ← Bottom nav
│ Inbox  │ Docs   │ Scan  │ Chat │
└────────┴────────┴───────┴───────┘
```

**Key design decisions:**
- NO thumbnail in list view (wastes space, PDFs all look the same)
- Title is the hero — large, bold, single line with ellipsis
- Correspondent + Document Type on one line, smaller text
- Tags: show max 3 chips + "+N" overflow — NEVER clip/overflow
- Swipe left: mark as seen (remove inbox tag)
- Swipe right: quick assign (correspondent, type)
- Pull to refresh
- FAB: floating action button for scan/upload

### 3. Documents Browser
- Same card style as inbox
- Filter bar: tags, correspondent, type, date range, custom fields
- Sort: created, added, modified, title, ASN
- Saved views as tabs or dropdown
- Infinite scroll pagination

### 4. Document Detail
- Title (editable inline)
- PDF preview (tap to full-screen)
- Metadata section: correspondent, type, date, ASN, storage path
- Tags (add/remove with autocomplete)
- Custom fields
- Notes section (add/view/delete)
- Share links
- Actions: download, share, delete, move to trash
- "More like this" button (uses `more_like_id` API)

### 5. Scanner
- Full-screen camera with edge detection overlay
- Multi-page: keep scanning, reorder, delete pages
- Auto-crop + perspective correction (via cunning_document_scanner)
- Review screen: preview each page, adjust crop
- Metadata screen: set title, correspondent, type, tags BEFORE upload
- Upload as PDF with progress indicator
- Task polling: show processing status until consumed

### 6. AI Chat
- Chat interface connected to Paperless-AI at `:8083`
- Send queries about your documents
- Display document references inline (tap to open)
- Connection: direct HTTP to `http://192.168.1.21:8083/api/chat`
  (NOT through NPM proxy to avoid 302 redirects)

### 7. Labels Manager
- Tabs: Tags | Correspondents | Document Types | Storage Paths
- List with search/filter
- Create/edit/delete
- Show document count per label
- Color picker for tags

---

## Navigation (GoRouter)

```dart
// Bottom nav shell
ShellRoute(
  builder: (context, state, child) => AppShell(child: child),
  routes: [
    GoRoute(path: '/', builder: (_, __) => InboxScreen()),
    GoRoute(path: '/documents', builder: (_, __) => DocumentsScreen()),
    GoRoute(path: '/scan', builder: (_, __) => ScannerScreen()),
    GoRoute(path: '/chat', builder: (_, __) => ChatScreen()),
  ],
)

// Detail routes (push on top of shell)
GoRoute(path: '/documents/:id', builder: (_, state) =>
  DocumentDetailScreen(id: int.parse(state.pathParameters['id']!))),
GoRoute(path: '/labels', builder: (_, __) => LabelsScreen()),
GoRoute(path: '/settings', builder: (_, __) => SettingsScreen()),
GoRoute(path: '/login', builder: (_, __) => LoginScreen()),
```

**Back gesture:** GoRouter handles this correctly — back from detail goes to list, back from home tab exits app. No `PopScope` hacks needed when using proper route hierarchy.

---

## Dio Client Setup (Fixing the 302 Problem)

The Paperless Mobile 302 error happens because Dio defaults to `followRedirects: false` for non-GET requests, and NPM can redirect HTTP→HTTPS or add trailing slashes.

```dart
class DioClient {
  static Dio create(String baseUrl, String token) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl.endsWith('/') ? baseUrl : '$baseUrl/',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      followRedirects: true,         // CRITICAL: follow 302s
      maxRedirects: 5,
      validateStatus: (status) => status != null && status < 500,
      headers: {
        'Accept': 'application/json; version=9',
        'Authorization': 'Token $token',
      },
    ));

    dio.interceptors.addAll([
      // Retry interceptor (network flakes over Tailscale)
      RetryInterceptor(dio: dio, retries: 3),
      // Logging in debug mode
      if (kDebugMode) LogInterceptor(
        requestBody: true,
        responseBody: true,
      ),
    ]);

    return dio;
  }
}
```

---

## Offline Strategy

### Cache Layers

1. **Metadata cache (Drift/SQLite):**
   - All document metadata synced on first load + periodic refresh
   - Tags, correspondents, document types cached locally
   - Enables instant search/filter even offline

2. **Thumbnail cache (disk):**
   - Download thumbnails on first view
   - LRU eviction at 200MB
   - `cached_network_image` handles this

3. **Offline queue:**
   - Uploads queued when offline
   - Auto-retry when connectivity returns
   - Show pending uploads in UI

### Sync Strategy

```
App launch → Check connectivity
  ├── Online:  Fetch /api/statistics/ for counts
  │            Background sync: tags, correspondents, types
  │            Inbox poll every 60s
  └── Offline: Serve from local cache
              Queue any writes
              Show "offline" indicator
```

---

## Implementation Plan (Claude Code Sessions)

### Session 1: Project Scaffold + Auth
1. Create Flutter project with all dependencies
2. Set up Riverpod, GoRouter, theme
3. Implement `DioClient` with API v9 headers + redirect handling
4. Build Login screen (URL + credentials + token mode)
5. Implement secure token storage
6. **Milestone:** Successfully authenticate and hit `/api/statistics/`

### Session 2: Inbox + Document List
1. Define Freezed models for Document, Tag, Correspondent, DocumentType
2. Implement documents API layer (list, filter, search)
3. Build Inbox screen with clean card design
4. Implement pull-to-refresh + infinite scroll
5. Implement swipe-to-dismiss (remove inbox tag)
6. **Milestone:** Browse inbox, see documents with tags

### Session 3: Document Detail + Preview
1. Build document detail screen (view + edit)
2. PDF preview with pdfx
3. Tag add/remove with autocomplete
4. Notes CRUD
5. Download + share actions
6. **Milestone:** Full document lifecycle (view, edit, share)

### Session 4: Scanner + Upload
1. Integrate cunning_document_scanner
2. Build multi-page scan flow
3. Metadata entry screen (pre-upload)
4. Implement multipart upload to `/api/documents/post_document/`
5. Task polling for consumption status
6. Implement file picker upload (non-scan)
7. **Milestone:** Scan a document, upload it, see it in inbox

### Session 5: Search + Labels
1. Full-text search with autocomplete
2. Advanced filter UI (tags, correspondent, type, date, custom fields)
3. Saved views integration
4. Labels management (CRUD for tags, correspondents, types)
5. **Milestone:** Find any document quickly

### Session 6: AI Chat
1. HTTP client for Paperless-AI at `:8083`
2. Chat UI with message history
3. Document reference links (tap to open detail)
4. Connection config in settings (separate URL from Paperless-ngx)
5. **Milestone:** Ask questions about your documents

### Session 7: Polish + Android Integration
1. Biometric lock (local_auth)
2. Offline cache (Drift) + sync strategy
3. Dark/light theme toggle
4. Share intent receiver (upload from other apps)
5. Notification for completed consumption tasks
6. Build release APK
7. **Milestone:** Daily-driver ready

### Session 8: Advanced Features
1. Bulk operations (multi-select + bulk tag/delete)
2. Custom fields display + edit
3. Document merge/split/rotate
4. Share links management
5. Trash management
6. Multi-server support
7. **Milestone:** Feature parity with PaperNext

---

## Key Differences from Paperless Mobile

| Issue in Paperless Mobile | Fix in Paperless Go |
|---------------------------|---------------------|
| Cluttered inbox cards with overflow | Clean cards: title hero, max 3 tags + "+N" |
| Upload/Scan buttons do nothing | Scanner works day 1 (cunning_document_scanner) |
| Back gesture exits app | GoRouter handles navigation stack correctly |
| AI chat 302 DioException | `followRedirects: true` + direct server URL (not via NPM) |
| Statistics home screen is useless | Inbox IS the home screen |
| OpenCV 3.4.5 from 2019 | ML Kit via cunning_document_scanner |
| No API v9 support | Built for v9 from the start |
| No MFA/TOTP support | Login screen handles token-based auth |
| Stale dependencies, abandoned | Fresh deps, your codebase, your rules |
| No offline capability | Drift SQLite cache + offline queue |

---

## Shared Code with OpenClaw Mobile

If you build both this and the OpenClaw Flutter app, share these across a monorepo:

```
apps/
├── paperless_go/           # This app
├── openclaw_mobile/        # OpenClaw app
└── shared/
    ├── theme/              # Material 3 theme, grepon brand
    ├── networking/          # Dio client setup, retry logic, Tailscale helpers
    ├── auth/               # Secure storage, biometric patterns
    └── widgets/            # Common UI components
```

Both apps connect to services on your homelab over Tailscale, use Dio for HTTP, Riverpod for state, and share the same design language. Building them as siblings avoids duplicating ~30% of the infrastructure code.

---

## Build & Release

```bash
# Debug (testing)
flutter build apk --debug

# Release
flutter build apk --release --split-per-abi

# Generate keystore (one time)
keytool -genkey -v -keystore ~/paperless-go-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias paperless_go

# Install
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

---

## Server-Side Prerequisites

Your Paperless-ngx is already running at `paperless.grepon.cc`. Just ensure:

1. **API token exists:** Profile → Generate/copy API token
2. **User permissions:** The API user needs `Users → View` and `UISettings → View` at minimum
3. **CORS (optional):** Only needed if you ever do web — native apps don't need CORS
4. **Paperless-AI for chat:** Running at `http://192.168.1.21:8083`
   - Ensure `OPENAI_BASE_URL` points to LiteLLM at `http://192.168.1.20:4000/v1`
   - Test the chat endpoint directly: `curl http://192.168.1.21:8083/api/chat`

---

## Why This Over Forking Paperless Mobile

- **Zero tech debt:** No 2-year-old Flutter SDK, no pinned deps, no workarounds for bugs that were never fixed
- **API v9 native:** No compatibility layers, no deprecated field handling
- **Modern scanner:** ML Kit instead of OpenCV 3.4.5
- **Your design:** Built for how YOU use Paperless, not a general-purpose app
- **Maintainable:** You understand every line because Claude Code wrote it for you
- **Monorepo potential:** Shares infrastructure with your OpenClaw app
