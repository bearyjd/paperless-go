# Paperless Go — Document Scanner & Pre-Upload Processing Pipeline

## Build Plan v1.0

**Goal:** Add camera-based document scanning with automatic edge detection, perspective correction, image enhancement, and PDF generation to Paperless Go — producing clean, OCR-ready PDFs before upload to Paperless-ngx.

**Constraint:** Must work on both Android and iOS. Use cross-platform Flutter packages only. No platform-specific native code unless wrapped in a cross-platform plugin.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Scanner Feature Flow                       │
│                                                              │
│  Camera ──► Edge Detection ──► Corner Adjust ──► Crop        │
│                                                              │
│  Crop ──► Perspective Warp ──► Enhance ──► Preview           │
│                                                              │
│  Preview ──► [Add More Pages] ──► PDF Build ──► Upload       │
│                                                              │
│  Each step produces an intermediate image stored in memory   │
│  User can go back to any step and redo                       │
└─────────────────────────────────────────────────────────────┘
```

### State Model (Riverpod)

```dart
// Core state for the scanning pipeline
@freezed
class ScanSession {
  List<ScannedPage> pages;       // All scanned pages
  int currentPageIndex;           // Which page is being edited
  ScanStep currentStep;           // Which step in the pipeline
  ProcessingPreset preset;        // Auto, Receipt, B&W, Color, Photo
}

@freezed
class ScannedPage {
  Uint8List rawImage;             // Original camera capture
  List<Offset> corners;           // Detected/adjusted document corners
  Uint8List croppedImage;         // After perspective transform
  Uint8List enhancedImage;        // After enhancement filters
  int rotation;                   // 0, 90, 180, 270
}

enum ScanStep { camera, cornerEdit, enhance, preview }
enum ProcessingPreset { auto, receipt, bwText, colorDocument, photo }
```

---

## Milestones (Build Order)

### Milestone 1: Camera Capture + Edge Detection
**Goal:** User can take a photo of a document and see detected edges.

**Packages:**
- `camera: ^0.11.x` — cross-platform camera access
- `google_mlkit_document_scanner: ^0.x.x` — OR `cunning_document_scanner: ^2.x.x`
  - Prefer `cunning_document_scanner` — it wraps Apple VisionKit (iOS) and Google MLKit (Android) behind one API
  - Fallback: `edge_detection: ^1.x.x` if cunning_document_scanner is too opinionated

**Tasks:**
1. Add camera permission handling (both platforms)
   - `android/app/src/main/AndroidManifest.xml` — camera permission
   - `ios/Runner/Info.plist` — NSCameraUsageDescription
   - Test: app requests camera permission, user grants, camera preview shows
2. Create `ScannerScreen` with live camera preview
   - Full-screen camera preview with capture button
   - Flash toggle, front/back camera toggle
   - Test: camera preview renders, capture button takes photo
3. Implement edge detection on captured image
   - Use cunning_document_scanner's built-in detection OR
   - Process captured frame through edge detection algorithm
   - Output: 4 corner points (Offset) defining document quadrilateral
   - Test: photograph a document on a desk, corners are detected within ~20px accuracy
4. Display detected edges as overlay on captured image
   - Draw quadrilateral overlay with draggable corner handles
   - Test: overlay matches document edges visually

**Acceptance criteria:**
- Camera opens on both Android and iOS
- Photo is captured at full resolution
- Document edges are auto-detected
- User sees the detected region highlighted

---

### Milestone 2: Corner Adjustment + Perspective Correction
**Goal:** User can fine-tune corners and get a flat, cropped document image.

**Packages:**
- `image: ^4.x.x` — pure Dart image processing (perspective transform)
  - This is critical: the `image` package is pure Dart, works on both platforms
  - Alternative: `opencv_dart: ^1.x.x` for faster native processing (has iOS + Android support)

**Tasks:**
1. Build `CornerEditorWidget` — draggable corner handles on the captured image
   - 4 circular handles at detected corners
   - Drag to reposition, with touch area larger than visual (fat-finger friendly)
   - Magnifying glass loupe on drag for precision
   - "Auto-detect" button to reset to detected corners
   - Test: drag each corner independently, positions update correctly
2. Implement perspective transform (4-point warp)
   - Input: raw image + 4 corner points
   - Output: rectangular cropped image (document only, no background)
   - Use `image` package's `copyRectify()` or manual matrix transform
   - If using opencv_dart: `cv.getPerspectiveTransform()` + `cv.warpPerspective()`
   - Test: skewed photo of document → perfectly rectangular output
3. Auto-rotation detection
   - Detect if document is landscape/portrait
   - Offer rotation buttons (90° CW/CCW)
   - Test: photograph a landscape document, rotation correctly flips it
4. Wire up: capture → detect → adjust → warp pipeline
   - State management via Riverpod
   - Back button goes to previous step (non-destructive)
   - Test: full flow from camera to cropped image

**Acceptance criteria:**
- Corners are draggable and responsive
- Perspective transform produces clean rectangular output
- No visible artifacts at document edges
- Rotation works correctly

---

### Milestone 3: Image Enhancement ✅ COMPLETE
**Goal:** Clean up the cropped image for optimal OCR readability.

**Completed:** 2026-02-28
- Built 5 filters: adaptive contrast, sharpen, denoise, shadow removal, binarize
- Filters run as pure Dart `img.Image → img.Image` functions
- 6 presets: None, Auto, Receipt, B&W Text, Color Doc, Photo
- EnhanceScreen with before/after (long-press) and preset chip selector
- All processing runs in isolates via `compute()` for UI responsiveness
- 18 unit tests covering filters and presets
- No deviations from plan; used `image` package (no opencv_dart needed)

**Packages:**
- `image: ^4.x.x` — filters, adjustments (pure Dart, cross-platform)
- Optionally `opencv_dart` for faster processing

**Tasks:**
1. Implement enhancement filter pipeline
   - Process chain: denoise → contrast → sharpen → (optional binarize)
   - Each filter is a function: `Uint8List → Uint8List`
   - Pipeline is composable and order matters
   - Test: each filter produces visible improvement on a test image
2. Build individual filters:
   a. **Adaptive contrast** (CLAHE or simpler histogram equalization)
      - Handles uneven lighting across the document
      - Test: photo with shadow on half the page → even brightness
   b. **Sharpening** (unsharp mask)
      - Crisp text edges for OCR
      - Test: slightly blurry text → sharper text
   c. **Denoise** (bilateral filter or simple gaussian)
      - Reduce camera noise without blurring text
      - Test: noisy low-light photo → cleaner with text preserved
   d. **Shadow removal** (difference of gaussians approach)
      - Remove finger shadows, fold shadows
      - Test: photo with finger shadow → shadow removed
   e. **Binarization** (adaptive threshold — Sauvola or Otsu)
      - Convert to pure B&W for text documents
      - Test: gray document → crisp black text on white background
3. Implement presets that combine filters:
   - **Auto:** contrast + sharpen + light denoise
   - **Receipt:** high contrast + binarize (thermal paper is tricky)
   - **B&W Text:** contrast + sharpen + binarize
   - **Color Document:** contrast + sharpen + denoise (preserve color)
   - **Photo:** light sharpen + denoise (preserve everything)
   - Test: each preset produces appropriate output for its document type
4. Build `EnhanceScreen` UI
   - Before/after slider (swipe to compare)
   - Preset selector (chips or bottom sheet)
   - Manual sliders for brightness, contrast, sharpness (advanced mode)
   - Apply/reset buttons
   - Test: user can switch presets and see real-time preview

**Acceptance criteria:**
- All 5 presets produce visibly improved images
- Processing time < 3 seconds per page on mid-range phone
- Before/after comparison is intuitive
- Filters don't destroy image quality (no over-sharpening, no banding)

---

### Milestone 4: Multi-Page + PDF Generation ✅ COMPLETE
**Goal:** Scan multiple pages, reorder them, and generate a single PDF.

**Completed:** 2026-02-28
- Multi-page review (ScanReviewScreen) was already built — reorder, delete, thumbnail strip
- Replaced hand-rolled PDF byte builder with `pdf` package (pw.Document)
- PDF generation runs in isolate via `Isolate.run()` for UI responsiveness
- Auto-detects landscape/portrait from image aspect ratio, fits to A4
- Added PdfPreviewScreen with page preview, file size display, and JPEG quality slider (30-100%)
- New scan flow: Camera → Review → Enhance → PDF Preview → Upload
- Deviation: used `Isolate.run()` instead of `compute()` since `pdf.save()` is async

**Packages:**
- `pdf: ^3.x.x` — pure Dart PDF generation (cross-platform)
- `printing: ^5.x.x` — optional, for print preview

**Tasks:**
1. Implement multi-page scan session
   - After processing one page, "Add Page" button returns to camera
   - Page thumbnails shown in a horizontal strip/grid
   - Tap thumbnail to edit that page (go back through pipeline)
   - Test: scan 3 pages, all appear in thumbnail strip
2. Page management UI
   - Drag to reorder pages
   - Swipe or button to delete a page
   - "Rescan" button on each page thumbnail
   - Page count indicator
   - Test: reorder pages, delete middle page, indices update correctly
3. PDF generation
   - Combine all enhanced images into single PDF
   - Each page = one image, fitted to A4/Letter (auto-detect aspect ratio)
   - JPEG compression with quality slider (default 85%)
   - Metadata: creation date, device name, page count, "Paperless Go" as creator
   - Test: generate 5-page PDF, open in viewer, all pages present and legible
4. PDF preview screen
   - Scroll through generated pages
   - Show file size estimate
   - "Regenerate" with different quality setting
   - Test: preview matches final PDF content

**Acceptance criteria:**
- Multi-page scanning is smooth (no lost state between pages)
- Page reordering works via drag
- Generated PDF is well-formed and opens in any PDF reader
- File sizes are reasonable (< 500KB per page at default quality)

---

### Milestone 5: Upload Integration
**Goal:** Send the generated PDF to Paperless-ngx with metadata.

**Tasks:**
1. Wire PDF to existing upload flow
   - Use existing Paperless-ngx API integration (Dio client)
   - POST to `/api/documents/post_document/` with multipart form
   - Include: document file, title (optional), tags (optional), correspondent (optional)
   - Test: upload scanned PDF, appears in Paperless-ngx
2. Pre-upload metadata screen
   - Title field (auto-suggest from first page OCR if available)
   - Tag selector (pull from existing tags)
   - Correspondent selector
   - Document type selector
   - Test: set title + tag, upload, document has correct metadata in Paperless
3. Upload progress + confirmation
   - Progress bar during upload
   - Success: show document in Paperless (deep link or confirmation)
   - Failure: retry button, error message
   - Test: upload on slow connection shows progress, large file completes
4. Save locally option
   - Save PDF to device gallery/files as alternative to upload
   - Test: saved PDF accessible in device file manager

**Acceptance criteria:**
- Scanned documents appear in Paperless-ngx correctly
- Metadata (tags, title, correspondent) are set correctly
- Upload handles network errors gracefully
- User can save locally without uploading

---

### Milestone 6: Polish & Edge Cases
**Goal:** Handle real-world scanning scenarios.

**Tasks:**
1. Gallery import (scan existing photos, not just camera)
   - Pick from gallery → enter pipeline at edge detection step
   - Test: import photo of document from gallery, full pipeline works
2. Batch scanning UX improvements
   - Auto-capture mode (detect document, auto-snap after 1s stability)
   - Sound/haptic feedback on capture
   - Quick-scan mode (auto preset, skip manual steps)
   - Test: auto-capture triggers on stable document detection
3. Performance optimization
   - Process images in isolate (background thread) to keep UI responsive
   - Show progress spinner during heavy processing
   - Thumbnail generation for page strip (don't render full-res)
   - Test: UI stays responsive during enhancement of 4000x3000 image
4. Error handling
   - Camera not available / permission denied
   - Image too dark / too blurry (warn user)
   - PDF generation fails (disk full, etc.)
   - Upload fails mid-transfer (resume? retry?)
   - Test: each error scenario shows helpful message

---

## Cross-Platform Package Matrix

| Package | Android | iOS | Purpose |
|---------|---------|-----|---------|
| `camera` | ✅ | ✅ | Camera preview + capture |
| `cunning_document_scanner` | ✅ (MLKit) | ✅ (VisionKit) | Edge detection |
| `image` | ✅ (Dart) | ✅ (Dart) | Image processing, filters |
| `pdf` | ✅ (Dart) | ✅ (Dart) | PDF generation |
| `image_picker` | ✅ | ✅ | Gallery import |
| `path_provider` | ✅ | ✅ | Temp file storage |
| `permission_handler` | ✅ | ✅ | Camera/storage permissions |

All packages are pure Dart or have official iOS+Android support. No platform-specific native code required.

---

## File Structure (New Files)

```
lib/
  features/
    scanner/
      providers/
        scan_session_provider.dart    # Riverpod state for scan session
        processing_provider.dart      # Async image processing state
      screens/
        scanner_screen.dart           # Camera + capture
        corner_editor_screen.dart     # Adjust detected corners
        enhance_screen.dart           # Enhancement presets + preview
        page_manager_screen.dart      # Multi-page reorder/delete
        pdf_preview_screen.dart       # Final PDF preview before upload
        scan_upload_screen.dart       # Metadata + upload
      widgets/
        corner_handle.dart            # Draggable corner point
        edge_overlay.dart             # Document boundary visualization
        page_thumbnail.dart           # Thumbnail in page strip
        before_after_slider.dart      # Enhancement comparison
        preset_chip.dart              # Enhancement preset selector
      processing/
        edge_detector.dart            # Document edge detection wrapper
        perspective_transform.dart    # 4-point warp
        image_enhancer.dart           # Filter pipeline coordinator
        filters/
          adaptive_contrast.dart      # CLAHE / histogram eq
          sharpen.dart                # Unsharp mask
          denoise.dart                # Noise reduction
          shadow_removal.dart         # Shadow detection + removal
          binarize.dart               # Adaptive threshold
        presets.dart                   # Preset definitions
      pdf/
        pdf_generator.dart            # Combine pages → PDF
        pdf_metadata.dart             # PDF metadata builder
      models/
        scan_session.dart             # ScanSession freezed model
        scanned_page.dart             # ScannedPage freezed model
        processing_preset.dart        # Preset enum + config

test/
  features/
    scanner/
      processing/
        perspective_transform_test.dart
        image_enhancer_test.dart
        filters/
          adaptive_contrast_test.dart
          sharpen_test.dart
          binarize_test.dart
      pdf/
        pdf_generator_test.dart
      providers/
        scan_session_provider_test.dart
```

---

## Testing Strategy

**Unit tests (per filter/transform):**
- Load known test images from `test/fixtures/`
- Process through filter
- Assert output dimensions, pixel value ranges, no crashes
- Compare against golden images where appropriate

**Widget tests (per screen):**
- Mock camera, mock providers
- Verify UI elements render
- Verify button taps trigger correct state changes

**Integration tests (full pipeline):**
- Load test image → detect edges → warp → enhance → generate PDF → verify PDF
- Run on both Android and iOS emulators

**Test fixtures needed:**
- `test/fixtures/skewed_document.jpg` — document photographed at angle
- `test/fixtures/shadowed_document.jpg` — document with finger shadow
- `test/fixtures/receipt.jpg` — thermal receipt
- `test/fixtures/low_light.jpg` — dark/noisy document photo
- `test/fixtures/multi_page/` — set of page photos

---

## Risk Register

| Risk | Impact | Mitigation |
|------|--------|------------|
| `cunning_document_scanner` doesn't support latest iOS/Android | High | Fallback to `edge_detection` + manual implementation |
| `image` package too slow for large photos | Medium | Use `compute()` isolates; resize before processing; offer quality tradeoff |
| Perspective transform quality poor | Medium | Consider `opencv_dart` as upgrade path |
| PDF file sizes too large | Low | JPEG quality slider, resize option |
| Camera permissions denied | Low | Clear error state, settings deep link |
