<!-- Generated: 2026-04-23 | Files scanned: 152 | Token estimate: ~950 -->

# Frontend (Screens & State)

## Screen Tree (GoRouter)

```
/                     → DashboardScreen (190L)
/login                → LoginScreen (285L)
/lock                 → LockScreen (71L)
/documents            → DocumentsScreen (793L)
/documents/:id        → DocumentDetailScreen (1833L)
/documents/:id/preview → DocumentPreviewScreen (86L)
/documents/:id/annotate → AnnotateScreen (502L)
/documents/:id/similar → SimilarScreen (94L)
/inbox                → InboxScreen (320L)
/search               → SearchScreen (209L)
/labels               → LabelsScreen (677L)
/custom-fields        → CustomFieldsScreen (298L)
/templates            → TemplatesScreen (231L)
/workflows            → WorkflowsScreen (82L)
/workflows/:id        → WorkflowDetailScreen (352L)
/trash                → TrashScreen (236L)
/settings             → SettingsScreen (443L)
/scanner              → ScannerScreen (208L)
/scanner/review       → ScanReviewScreen (268L)
/scanner/enhance      → EnhanceScreen (382L)
/scanner/pdf-preview  → PdfPreviewScreen (233L)
/scanner/upload       → UploadScreen (675L)
/chat                 → ChatScreen (481L)
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

## Scanner Pipeline

```
ScannerScreen (camera capture)
    → ScanReviewScreen (reorder/delete pages)
    → EnhanceScreen (6 presets: Auto, Receipt, B&W, Color, Photo, Original)
        → image_enhancer.dart (314L) — adaptive contrast, binarize, sharpen, shadow removal, deskew
        → mlkit_deskew.dart (48L) — ML Kit deskew (stub on F-Droid)
    → PdfPreviewScreen (multi-page PDF preview)
    → UploadScreen (metadata, tags, correspondent, template)
        → upload_notifier.dart → PaperlessApi.uploadDocument()
```
