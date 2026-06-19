<!-- Generated: 2026-06-19 | Files scanned: 160+ | Token estimate: ~950 -->

# Frontend (Screens & State)

## Screen Tree (GoRouter)

```
App shell (ShellRoute — bottom nav):
/                      → DashboardScreen (190L)
/documents             → DocumentsScreen (793L)
/scan                  → ScannerScreen (208L)
/chat                  → ChatScreen (481L)

Top-level routes:
/login                 → LoginScreen (285L)
/search                → SearchScreen (209L)
/search/similar/:id    → SimilarScreen (94L)
/inbox                 → InboxScreen (320L)
/labels                → LabelsScreen (677L)
/custom-fields         → CustomFieldsScreen (298L)
/templates             → TemplatesScreen (231L)
/workflows             → WorkflowsScreen (82L)
/workflows/:id         → WorkflowDetailScreen (352L)
/trash                 → TrashScreen (236L)
/settings              → SettingsScreen (443L)
/annotate              → AnnotateScreen (502L)  [extra: pdfPath, title]
/documents/:id         → DocumentDetailScreen (1833L)
/documents/:id/preview → DocumentPreviewScreen (86L)
/documents/:id/chat    → ChatScreen (481L)

Scan pipeline (pushed routes, outside shell):
/scan/review           → ScanReviewScreen (273L)
/scan/enhance          → EnhanceScreen (382L)
/scan/pdf-preview      → PdfPreviewScreen (233L)
/scan/upload           → UploadScreen (676L)

Biometric lock renders as a full-screen overlay (Stack in app.dart), not a route.
```

## State Management (Riverpod Notifiers)

| Notifier | File | State |
|----------|------|-------|
| DocumentsNotifier | documents/documents_notifier.dart (172L) | Paginated doc list, filters, sort |
| DocumentDetailNotifier | documents/document_detail_notifier.dart (86L) | Single doc CRUD, notes, custom fields |
| AiEditTrailNotifier | documents/ai_edit_trail_notifier.dart (79L) | AI-suggested metadata edits |
| InboxNotifier | inbox/inbox_notifier.dart (117L) | Inbox items, swipe assign |
| SearchNotifier | search/search_notifier.dart (104L) | Search query, autocomplete, results |
| LabelsNotifier | labels/labels_notifier.dart (168L) | Tags, correspondents, doc types, storage paths |
| ChatNotifier | ai_chat/chat_notifier.dart (244L) | AI chat messages, streaming |
| TrashNotifier | trash/trash_notifier.dart (116L) | Deleted docs, restore/purge |
| UploadNotifier | scanner/upload_notifier.dart (325L) | Upload queue, task polling |
| TemplateService | core/services/template_service.dart (78L) | Document upload templates |

## Shared Widgets

- `DocumentCard` — shared/widgets/document_card.dart (165L)
- `EmptyState` — shared/widgets/empty_state.dart (60L)
- `LoadingSkeleton` — shared/widgets/loading_skeleton.dart (259L)
- `TagChip` — shared/widgets/tag_chip.dart (86L)
- `BulkActionBar` — documents/bulk_action_bar.dart (693L)
- `FilterBottomSheet` — documents/filter_bottom_sheet.dart (287L)
- `CropOverlay` — scanner/widgets/crop_overlay.dart (262L)

## Scan / Share-to-PDF Pipeline

Entry points:
```
ScannerScreen "Scan"/"Batch Scan" (camera)  → /scan/review
ScannerScreen "Upload File" (file_picker)    → /scan/upload  (direct, any file)
Share from another app (receive_sharing_intent)
    → upload/share_intent_handler.dart::resolveShareRoute (routes by file TYPE)
        images (1+)            → /scan/review   (wrapped to PDF via the pipeline)
        non-image (PDF, etc.)  → /scan/upload   (direct upload)
```

Pipeline:
```
/scan/review  ScanReviewScreen (reorder/rotate/crop/delete pages)
    → /scan/enhance  EnhanceScreen (presets: Auto, Receipt, B&W, Color, Photo, Original)
        → image_enhancer.dart (314L) — contrast, binarize, sharpen, shadow removal, deskew
        → mlkit_deskew.dart (48L) — ML Kit deskew (stub on F-Droid)
    → /scan/pdf-preview  PdfPreviewScreen — PdfGenerator.generatePdf (quality slider)
    → /scan/upload  UploadScreen (metadata, tags, correspondent, template)
        → upload_notifier.dart → PaperlessApi.uploadDocument() → poll /api/tasks/
```
