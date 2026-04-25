# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Add offline edit queue with coalescing and auto-sync on reconnect
- Add Android home screen widget with document count and quick scan/upload buttons
- Add document templates with Drift storage, management UI, and upload integration
- Add per-document biometric lock with Drift storage
- Add annotation compositing export service
- Add batch OCR re-run to bulk action bar

### Changed
- Wire annotation compositing into save/share flow

### Fixed
- Fix atomic edit queue coalescing, secure biometric gate default, efficient hasPending, and widget dark mode

## [1.1.2] - 2026-04-24

### Changed
- Per-architecture APKs (arm, arm64, x86_64) for smaller download size on F-Droid

## [1.1.1] - 2026-04-24

### Fixed
- Fix login failing on servers behind reverse proxies (HTTP 302)
- Fix "Connection failed: null" error message on login failure
- Fix circular dependency crash when logging in

## [1.1.0] - 2026-03-29

### Added
- Add annotate action to document detail with drawing canvas, tools, and page navigation
- Add annotation model with undo/redo support
- Add workflow caching for offline mode with complete cache coverage
- Add shimmer skeleton loaders for dashboard and workflows screens
- Add shared EmptyState widget standardized across screens
- Add compress, share, and password protect actions to document detail
- Add PDF compress and password protect service
- Add native PDF page renderer via platform channel
- Add rotate and split PDF tools to document detail popup menu
- Add page range parser with validation for split operations
- Add custom fields management screen with create, rename, and delete operations
- Add custom field data type helpers and CRUD API methods
- Add workflows list screen with toggle and workflow detail screen
- Add workflow helper functions for type and source label lookups
- Add DashboardScreen with pull-to-refresh stat card grid
- Add DashboardStatistics model and provider
- Add long-press chip management for saved view delete and rename
- Add save-as-view button and dialog for filter-based saved views
- Add createSavedView, deleteSavedView, updateSavedView API methods
- Add AI edit trail section in document detail showing OCR-suggested metadata
- Add scan date shortcut below created date in document detail
- Add fastlane metadata for F-Droid
- Add OCR metadata suggestions for image file picker uploads
- Add Share button to bulk document selection bar
- Add long-press context menu with Share action on document cards

### Changed
- Wire DashboardScreen as home tab and move Inbox to /inbox
- Standardize error states with icon, message, and retry button across all screens
- Replace hardcoded colors with theme-aware alternatives for dark mode
- Show fast preview on preset change for single-page scans
- Read crop screen image bytes once instead of twice

### Fixed
- Fix DropdownButtonFormField value and remove controller disposal
- Fix empty select options guard in forms
- Fix typed maps in filters bar and detail screen
- Fix scrollable dashboard layout and loading state
- Fix document tag rule type limitation
- Fix paginated workflows provider and keepAlive behavior
- Fix RefreshIndicator placement and error detail display
- Fix related_document field handling as int or string from API
- Fix expose documentId in UploadState after successful upload
- Fix custom field select picker using extraData options
- Fix re-enforce minimum crop size after edge clamping
- Fix prevent double-tap race in scan page rotation
- Fix delete old temp files after rotate and crop in scan review
- Fix share context.mounted guard and clear selection after bulk share
- Fix case-sensitive exact match behavior
- Fix Android VIEW intent URI handling in router redirect
- Fix auth guard application after VIEW intent redirect

## [1.0.3] - 2026-03-08

### Added
- Extract ML Kit into swappable modules for F-Droid FOSS builds
- Add speed optimizations for image filters: separable box blur, fast 3×3 sharpen, inline binarize

### Changed
- Unify preset pipeline and remove duplicate filter logic

### Fixed
- Fix upload state, share intent, image cache, regex matcher, and polling auth bugs
- Fix CSRF race condition and retry interceptor silent hang
- Fix F-Droid build recipe and disable dependency metadata

## [1.0.2] - 2026-03-08

### Added
- Add crop/rotate tools for document images
- Add batch scan feature
- Add OCR metadata suggestions
- Add VIEW intent filter and expand share support for all document types

### Changed
- Speed up image filters with detailed processing progress UI
- Optimize enhance pipeline

### Fixed
- Fix nullable created date field handling
- Fix bulk trash operations
- Fix upload retry cap
- Fix documents disappearing after re-login
- Fix PDF rendering speed
- Fix adaptive contrast artifacts
- Fix tag picker keyboard behavior

## [1.0.1] - 2026-03-08

### Added
- Add ML Kit deskew for document image enhancement
- Add ProGuard rules for ML Kit release builds
- Enable login autofill on authentication screen
- Parallelize image enhancement pipeline

### Changed
- Rename package to com.ventoux.paperlessgo
- Improve AppBar button styling and contrast
- Auto-orient EXIF images in scanner to match device orientation

### Fixed
- Fix CSRF 403 error on bulk edit operations
- Fix scanner UX issues with image orientation

## [1.0.0] - 2026-02-26

### Added
- Add offline cache with Drift/SQLite storage
- Add storage paths management
- Add speed dial FAB for quick actions
- Add bulk operations support
- Add document-specific AI chat with SSE streaming
- Add biometric authentication
- Add app icon, feature graphic, and Play Store listing
- Add privacy policy and F-Droid metadata

### Fixed
- Fix AI chat authentication and race conditions
- Fix settings dialog crashes
- Fix note adding functionality
- Fix delete operation to use REST endpoint
- Fix bulk action count display
- Resolve 60+ bugs from multiple codebase audits

### Security
- License under AGPL-3.0
