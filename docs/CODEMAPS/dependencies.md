<!-- Generated: 2026-04-23 | Files scanned: 152 | Token estimate: ~700 -->

# Dependencies

## External Services

| Service | Purpose | Integration Point |
|---------|---------|-------------------|
| Paperless-ngx | Document management backend | core/api/paperless_api.dart (528L) |
| Paperless-AI | AI chat (LiteLLM → Claude) | features/ai_chat/chat_service.dart (349L) |

## Runtime Dependencies (pubspec.yaml)

### Core

| Package | Version | Purpose |
|---------|---------|---------|
| flutter_riverpod | ^2.6.1 | State management |
| riverpod_annotation | ^2.6.1 | Riverpod codegen annotations |
| dio | ^5.7.0 | HTTP client |
| go_router | ^14.0.0 | Declarative routing |
| drift | ^2.22.1 | SQLite ORM (offline cache) |
| sqlite3_flutter_libs | ^0.5.28 | SQLite native bindings |
| flutter_secure_storage | ^9.2.4 | Keychain/EncryptedSharedPrefs |

### UI

| Package | Version | Purpose |
|---------|---------|---------|
| google_fonts | ^6.2.1 | Typography |
| cached_network_image | ^3.4.1 | Image caching with auth headers |
| flutter_cache_manager | ^3.4.1 | Disk cache for images |
| flutter_markdown | ^0.7.4 | Markdown rendering (AI chat) |
| shimmer | ^3.0.0 | Loading skeleton effects |

### Features

| Package | Version | Purpose |
|---------|---------|---------|
| pdfx | ^2.8.0 | PDF viewing |
| pdf | ^3.11.1 | PDF generation (scanner output) |
| cunning_document_scanner | ^1.4.0 | Camera document scanning |
| file_picker | ^8.1.7 | File selection for upload |
| image | ^4.3.0 | Image processing (enhance pipeline) |
| local_auth | ^2.3.0 | Biometric authentication |
| home_widget | ^0.7.0 | Android home screen widget |
| share_plus | ^10.1.4 | Share documents |
| receive_sharing_intent | ^1.8.1 | Receive files from other apps |
| url_launcher | ^6.3.1 | Open URLs |
| connectivity_plus | ^6.1.1 | Network status detection |
| flutter_local_notifications | ^18.0.1 | Upload/task notifications |
| google_mlkit_text_recognition | ^0.15.1 | OCR (stripped for F-Droid) |
| intl | ^0.19.0 | Date/number formatting |

### Build-time

| Package | Version | Purpose |
|---------|---------|---------|
| build_runner | ^2.4.14 | Code generation runner |
| drift_dev | ^2.22.1 | Drift codegen |
| json_serializable | ^6.9.4 | JSON codegen |
| riverpod_generator | ^2.6.3 | Riverpod codegen |
| freezed | ^2.5.7 | Immutable model codegen |
| flutter_lints | ^5.0.0 | Lint rules |
| flutter_launcher_icons | ^0.14.3 | App icon generation |

## F-Droid vs Play Store

| Capability | Play Store (ML Kit) | F-Droid (stub) |
|------------|--------------------|--------------------|
| Document deskew | google_mlkit_text_recognition | pure-Dart deskew (filters/deskew.dart) |
| OCR suggestions | ocr_extractor.dart | ocr_extractor_stub.dart (no-op) |

Swap files: `mlkit_deskew.dart` ↔ `mlkit_deskew_stub.dart`, `ocr_extractor.dart` ↔ `ocr_extractor_stub.dart`
