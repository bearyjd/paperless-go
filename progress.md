# Paperless Go — Build Progress

## Session Status

| Session | Description | Status |
|---------|-------------|--------|
| 1 | Project Scaffold + Auth | Done |
| 2 | Inbox + Document List | Done |
| 3 | Document Detail + Preview | Done |
| 4 | Scanner + Upload | Done |
| 5 | Search + Labels | Done |
| 6 | AI Chat | Done |
| 7 | Polish + Android Integration | Done |
| 8 | Advanced Features | Done |
| 9 | *(not in original plan)* | — |
| 10 | *(not in original plan)* | — |
| 11 | Offline Cache + UX Polish | Done |

## What's Built

### Core Infrastructure
- Flutter project with Riverpod state management, GoRouter navigation, Material 3 theme
- Dio HTTP client with API v9 headers, redirect handling, token auth
- Secure storage for credentials (flutter_secure_storage)
- Drift/SQLite offline cache with cache-aside on all API providers
- Connectivity monitoring with offline banner
- Pending upload queue with automatic drain on reconnect

### Features

**Authentication & Security**
- Login screen (credentials + token mode)
- Multi-server profile support
- Biometric lock (local_auth)
- Lock screen on app background/resume
- Cache cleared on logout

**Inbox (Home Screen)**
- Inbox-first design — home screen shows inbox documents
- Pull-to-refresh, infinite scroll
- Clean document cards (title hero, max 3 tags + "+N")

**Documents Browser**
- Browse all documents with pagination
- Filter bottom sheet (tags, correspondent, document type, date range)
- Sort options (created, added, modified, title)
- Multi-select with bulk action bar

**Document Detail**
- View/edit title, correspondent, document type, tags, custom fields
- PDF preview (pdfx)
- Notes CRUD
- Share links management
- Download + share actions
- "More like this" (similar documents)

**Scanner**
- Camera-based document scanning (cunning_document_scanner with ML Kit)
- Multi-page scan with review screen
- Image-to-PDF conversion
- Metadata entry before upload (title, correspondent, type, tags)

**Upload**
- File picker upload
- Multipart upload with task polling
- Offline queuing — uploads saved to SQLite when offline, auto-retried on reconnect
- Share intent receiver (upload from other apps)
- Upload status notifications

**Search**
- Full-text search with autocomplete
- Similar documents screen

**Labels Management**
- 4-tab interface: Tags, Correspondents, Doc Types, Storage Paths
- Full CRUD (create, edit, delete) for all label types
- Storage path management with path template field

**AI Chat**
- Chat interface connected to Paperless-AI (direct HTTP, bypasses NPM proxy)
- Configurable AI chat URL in settings

**Bulk Operations**
- Multi-select on document lists
- Add tags (multi-select picker with search)
- Set correspondent (single picker with search)
- Set document type (single picker with search)
- Set storage path (single picker with search)
- Merge documents (2+ selected)
- Rotate documents (90/180/270 degrees)
- Move to trash

**Trash**
- View trashed documents
- Restore from trash
- Permanent delete

**Settings**
- Server URL + token configuration
- AI chat URL configuration
- Theme mode (light/dark/system)
- Biometric lock toggle

**UX Polish**
- SpeedDial FAB on Inbox and Documents tabs (quick scan + file upload)
- Offline banner when disconnected
- Loading skeletons (shimmer)
- Dark/light theme support

### Offline Cache
- 7 SQLite cache tables: Documents, Tags, Correspondents, DocumentTypes, StoragePaths, SavedViews, CustomFields
- Cache-aside pattern: API call succeeds -> cache result; API fails -> serve from cache
- PendingUploads table with retry tracking
- Upload queue service drains on connectivity restore

## File Count
- 123 source files
- 7 Freezed models with generated code
- 17 Riverpod providers with generated code
- 8 Drift database tables with generated code

## Build Outputs
- Debug APK: `build/app/outputs/flutter-apk/app-debug.apk`
- Release APKs (split per ABI):
  - `app-armeabi-v7a-release.apk` (21.7MB)
  - `app-arm64-v8a-release.apk` (23.6MB)
  - `app-x86_64-release.apk` (24.9MB)

## What's Not Yet Implemented
- Thumbnail disk cache with LRU eviction (200MB) — `cached_network_image` handles basic caching but no explicit LRU management
- Saved views as tabs/dropdown in documents browser (API exists, UI not wired)
- Custom field editing in document detail (display exists)
- Document split operation
- Swipe gestures on inbox cards (swipe to remove inbox tag, swipe to quick-assign)
- mDNS/Tailscale server discovery
- ASN (archive serial number) display/edit
