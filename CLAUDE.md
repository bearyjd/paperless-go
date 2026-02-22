# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Paperless Go (`cc.grepon.paperless_go`) is a Flutter mobile client for Paperless-ngx, targeting Android. It connects to a Paperless-ngx instance via REST API v9 and optionally to Paperless-AI for chat features. The full architecture and implementation plan is in `paperless-flutter-build-plan.md`.

## Build Commands

```bash
# Install dependencies
flutter pub get

# Code generation (Freezed, Retrofit, Drift, Riverpod)
dart run build_runner build --delete-conflicting-outputs

# Watch mode for code generation during development
dart run build_runner watch --delete-conflicting-outputs

# Debug APK
flutter build apk --debug

# Release APK (split by ABI)
flutter build apk --release --split-per-abi

# Run on connected device
flutter run

# Run tests
flutter test

# Run a single test file
flutter test test/path/to/test_file.dart

# Analyze/lint
flutter analyze

# Install release APK
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

## Architecture

**Layered structure:**
- `lib/core/` — API client (Dio + Retrofit), local database (Drift/SQLite), auth/secure storage, models (Freezed), theme, constants
- `lib/features/` — Feature modules: inbox, documents, scanner, upload, search, labels, ai_chat, settings, login. Each feature owns its screens, widgets, and Riverpod providers
- `lib/shared/` — Reusable widgets (tag chips, document cards, loading skeletons) and Dart extensions

**State management:** Riverpod (with code generation via `riverpod_generator`)

**Navigation:** GoRouter with a bottom-nav ShellRoute (inbox `/`, documents `/documents`, scan `/scan`, chat `/chat`) and detail overlays (`/documents/:id`, `/labels`, `/settings`, `/login`)

**Data flow:** Screens -> Riverpod providers -> Retrofit API client (Dio) -> Paperless-ngx API v9. Local cache via Drift/SQLite for offline support.

## Key Implementation Details

- **API headers:** All requests must include `Accept: application/json; version=9` and `Authorization: Token <api_token>`
- **Dio redirect handling:** Must set `followRedirects: true` and `maxRedirects: 5` — the AI chat endpoint returns 302s that break if not followed
- **Offline strategy:** Metadata cached in Drift/SQLite, thumbnails cached on disk (200MB LRU), uploads queued offline and retried on reconnect
- **Scanner:** Uses `cunning_document_scanner` with ML Kit edge detection (not OpenCV)
- **Code generation is required** after modifying any model, API interface, database table, or Riverpod provider — run `build_runner build`

## Server Configuration

- Paperless-ngx API: `paperless.grepon.cc:8082`
- Paperless-AI (chat): `http://192.168.1.21:8083` (connect directly, not through reverse proxy)
- AI chat must bypass NPM proxy to avoid 302 redirect issues

## Design Principles

- **Inbox-first:** Home screen is the inbox, not a statistics dashboard
- **Scan is first-class:** One-tap scan accessible from anywhere via FAB
- **Clean cards:** Title prominent, max 3 visible tags with "+N" overflow, correspondent + document type as secondary text
- **Material 3** with `google_fonts`
