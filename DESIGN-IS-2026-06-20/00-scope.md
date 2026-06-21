# 00 — Scope Lock

**Date:** 2026-06-20
**Skill:** design-is (Dieter Rams ten-principle audit)
**Verdict target:** one of NEW / REFINE / REDESIGN

## What is being audited

Whole-app sweep of **Paperless Go** — a Flutter mobile client for Paperless-ngx.
Source-based audit (no running web instance; this is an Android/iOS Flutter app,
so web metrics like JS bytes / network requests / live WCAG are translated to
Flutter equivalents: dependency + asset weight, widget rebuild cost, semantics).

### Design system layer
- `lib/core/theme.dart`
- `lib/core/design_tokens.dart`
- `lib/shared/widgets/loading_skeleton.dart`

### Primary screens
- Documents list — `lib/features/documents/documents_screen.dart` (hot path, 37× touched)
- Document detail — `lib/features/documents/document_detail_screen.dart`
- Inbox — `lib/features/inbox/inbox_screen.dart`
- Trash — `lib/features/trash/trash_screen.dart`
- Scanner flow — `lib/features/scanner/` (scanner, enhance, crop, pdf_preview, upload, scan_review)
- Settings — `lib/features/settings/settings_screen.dart`
- Dashboard — `lib/features/dashboard/dashboard_screen.dart`

## Primary user & task

- **User:** a self-hoster managing documents in their Paperless-ngx instance from a phone.
- **Primary task:** find and open a document; secondarily, scan/upload a new one.

## Constraints

- Flutter + Material 3, Riverpod state, dio HTTP.
- Mobile-first; per project memory, admin surfaces (mail rules, user/group perms) are out of scope.
- Source-of-truth is what ships in `lib/`, not mockups.

## Method note

Visual + accessibility evidence is read from source (theme, tokens, widgets) and
marked INFERRED where a rendered measurement would normally be taken. Weight &
Friction is adapted to Flutter: pub dependencies, asset size, idle animations,
and initial-load modal/badge count instead of JS bytes / TTI.
