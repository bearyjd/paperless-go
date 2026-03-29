# Scanner Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix 4 remaining scanner issues: double-tap race on rotate, crop minimum size after edge clamping, missing OCR suggestions for image file picker uploads, and double image read in CropScreen.

**Architecture:** All fixes are minimal, isolated, and single-concern. No new dependencies.

**Tech Stack:** Flutter, Dart, dart:io, dart:ui

---

## Pre-flight: Already Fixed / No Change Needed

These findings from the audit are already resolved or require no code change:
- **Finding 13** (`applyDeskewAsync` dead code): function not present in `deskew.dart`
- **Finding 15** (codec not disposed in CropScreen): `codec.dispose()` already at `crop_screen.dart:44`
- **Finding 5** (in-place mutation `ProcessingPreset.none`): already returns `source` directly, no clone
- **Finding 8** (ReDoS via regex): admin-controlled + try/catch — no code change warranted
- **Finding 12** (batch vs regular scan): intentional design choice — no code change

---

## File Map

| File | Change |
|---|---|
| `lib/features/scanner/scan_review_screen.dart` | Add early-return guard in `_rotatePage` |
| `lib/features/scanner/widgets/crop_overlay.dart` | Enforce min width/height after right/bottom edge clamping |
| `lib/app.dart` | Pass `ocrImagePath` for image file types in `_onUploadFile` |
| `lib/features/scanner/crop_screen.dart` | Read image bytes once; use `Image.memory` instead of `Image.file` |

---

## Task 1: Fix Double-Tap Race in _rotatePage

**Root cause:** `_isProcessing = true` is set inside `setState()`, which schedules a rebuild rather than taking effect immediately. A double-tap fires before the rebuild disables the button, queuing two concurrent rotations that both read the same `_pages[_currentPage]` path and produce conflicting results.

**Fix:** Add `if (_isProcessing) return;` at the very top of `_rotatePage`, before any `await` or `setState`.

**Files:**
- Modify: `lib/features/scanner/scan_review_screen.dart`

- [ ] **Step 1: Read current _rotatePage**

Read `lib/features/scanner/scan_review_screen.dart` lines 185-215. Confirm it currently starts with:
```dart
Future<void> _rotatePage({required bool clockwise}) async {
  setState(() => _isProcessing = true);
```

- [ ] **Step 2: Add early-return guard**

Replace:
```dart
Future<void> _rotatePage({required bool clockwise}) async {
  setState(() => _isProcessing = true);
```

With:
```dart
Future<void> _rotatePage({required bool clockwise}) async {
  if (_isProcessing) return;
  setState(() => _isProcessing = true);
```

- [ ] **Step 3: Run static analysis**

```bash
export PATH="$HOME/flutter/bin:$PATH" && flutter analyze 2>&1
```

Expected: no new issues.

- [ ] **Step 4: Commit**

```bash
git add lib/features/scanner/scan_review_screen.dart
git commit -m "fix: prevent double-tap race in scan page rotation

setState schedules a rebuild rather than taking effect immediately,
leaving a one-frame window where a rapid double-tap could queue two
concurrent _rotatePage calls. Early-return guard fixes this."
```

---

## Task 2: Enforce Minimum Crop Size After Edge Clamping

**Root cause:** In `_updateFromDisplay`, width and height are clamped to `_minCropFraction` (0.05) during normalization. But then right and bottom are clamped to 1.0, which can silently reduce width/height below the minimum without re-enforcing the constraint. Result: a very narrow/short crop region near the edge.

**Note:** `_onHandleDrag` already enforces pixel-level minimums before calling `_updateFromDisplay`, so this path is not reachable through normal handle dragging. However, `_updateFromDisplay` is a public-ish method and the constraint should be correct on its own.

**Files:**
- Modify: `lib/features/scanner/widgets/crop_overlay.dart`

- [ ] **Step 1: Read current _updateFromDisplay**

Read `lib/features/scanner/widgets/crop_overlay.dart` lines 45-62. Confirm it currently reads:
```dart
void _updateFromDisplay(Rect displayCrop) {
  _crop = Rect.fromLTWH(
    (displayCrop.left / widget.displaySize.width).clamp(0.0, 1.0),
    (displayCrop.top / widget.displaySize.height).clamp(0.0, 1.0),
    (displayCrop.width / widget.displaySize.width)
        .clamp(_minCropFraction, 1.0),
    (displayCrop.height / widget.displaySize.height)
        .clamp(_minCropFraction, 1.0),
  );
  // Clamp right/bottom edges
  if (_crop.right > 1.0) {
    _crop = Rect.fromLTRB(_crop.left, _crop.top, 1.0, _crop.bottom);
  }
  if (_crop.bottom > 1.0) {
    _crop = Rect.fromLTRB(_crop.left, _crop.top, _crop.right, 1.0);
  }
  widget.onCropChanged(_crop);
}
```

- [ ] **Step 2: Re-enforce minimum width/height after edge clamping**

Replace `_updateFromDisplay` with:
```dart
void _updateFromDisplay(Rect displayCrop) {
  _crop = Rect.fromLTWH(
    (displayCrop.left / widget.displaySize.width).clamp(0.0, 1.0),
    (displayCrop.top / widget.displaySize.height).clamp(0.0, 1.0),
    (displayCrop.width / widget.displaySize.width)
        .clamp(_minCropFraction, 1.0),
    (displayCrop.height / widget.displaySize.height)
        .clamp(_minCropFraction, 1.0),
  );
  // Clamp right/bottom edges, then re-enforce minimum dimensions
  if (_crop.right > 1.0) {
    _crop = Rect.fromLTRB(
      (_crop.right - _minCropFraction).clamp(0.0, 1.0 - _minCropFraction),
      _crop.top,
      1.0,
      _crop.bottom,
    );
  }
  if (_crop.bottom > 1.0) {
    _crop = Rect.fromLTRB(
      _crop.left,
      (_crop.bottom - _minCropFraction).clamp(0.0, 1.0 - _minCropFraction),
      _crop.right,
      1.0,
    );
  }
  widget.onCropChanged(_crop);
}
```

- [ ] **Step 3: Run static analysis**

```bash
export PATH="$HOME/flutter/bin:$PATH" && flutter analyze 2>&1
```

Expected: no issues.

- [ ] **Step 4: Commit**

```bash
git add lib/features/scanner/widgets/crop_overlay.dart
git commit -m "fix: re-enforce minimum crop size after right/bottom edge clamping

Clamping right or bottom to 1.0 could reduce width/height below
_minCropFraction without correcting left/top. Now adjusts left/top
to maintain the minimum dimension when the edge is clamped."
```

---

## Task 3: Pass ocrImagePath for Image File Types in File Picker

**Root cause:** The file picker flow in `_onUploadFile` (app.dart) navigates to `/scan/upload` without `ocrImagePath`. The upload screen only generates OCR metadata suggestions when `ocrImagePath` is non-null. PDF files are not suitable for image OCR, but image files (png, jpg, jpeg, tiff, webp) are — and these are exactly the non-PDF types allowed by the file picker.

**Files:**
- Modify: `lib/app.dart`

- [ ] **Step 1: Read current _onUploadFile**

Read `lib/app.dart` lines 413-430. Confirm the navigation currently reads:
```dart
GoRouter.of(context).push('/scan/upload', extra: {
  'filePath': file.path!,
  'filename': file.name,
});
```

- [ ] **Step 2: Add ocrImagePath for image file types**

Replace the navigation block inside `_onUploadFile`:
```dart
      if (result != null && result.files.single.path != null && mounted) {
        final file = result.files.single;
        GoRouter.of(context).push('/scan/upload', extra: {
          'filePath': file.path!,
          'filename': file.name,
        });
      }
```

With:
```dart
      if (result != null && result.files.single.path != null && mounted) {
        final file = result.files.single;
        final ext = file.extension?.toLowerCase();
        final isImage = ext == 'png' || ext == 'jpg' || ext == 'jpeg' ||
            ext == 'tiff' || ext == 'webp';
        GoRouter.of(context).push('/scan/upload', extra: {
          'filePath': file.path!,
          'filename': file.name,
          if (isImage) 'ocrImagePath': file.path!,
        });
      }
```

- [ ] **Step 3: Run static analysis**

```bash
export PATH="$HOME/flutter/bin:$PATH" && flutter analyze 2>&1
```

Expected: no issues.

- [ ] **Step 4: Commit**

```bash
git add lib/app.dart
git commit -m "feat: enable OCR metadata suggestions for image file picker uploads

Upload screen only ran OCR suggestions when ocrImagePath was provided.
File picker uploads never set it. Now image types (png/jpg/jpeg/tiff/webp)
pass ocrImagePath so metadata is auto-suggested, matching scan flow behavior."
```

---

## Task 4: Read Image Bytes Once in CropScreen

**Root cause:** `_loadImageSize()` reads the full file bytes to decode image dimensions via `ui.instantiateImageCodec`. Then `Image.file()` in the widget reads the same file again to display it. For large scanned images (4000x3000, 8-10 MB), this briefly doubles memory usage. The fix: store the bytes, use `Image.memory` for display so the file is read exactly once.

**Files:**
- Modify: `lib/features/scanner/crop_screen.dart`

- [ ] **Step 1: Read current crop_screen.dart**

Read `lib/features/scanner/crop_screen.dart`. Confirm:
- `_loadImageSize()` at line 31 reads bytes, decodes codec, disposes at line 44
- The widget at line 121 uses `Image.file(File(widget.imagePath), ...)`

- [ ] **Step 2: Add _imageBytes field and update _loadImageSize**

In `_CropScreenState`, add a field alongside `_imageSize`:
```dart
  Size? _imageSize;
  Uint8List? _imageBytes;
```

Add the import for `dart:typed_data` if not present (check existing imports first — `dart:io` is already imported; `dart:typed_data` may also already be present via `dart:ui`). Add it if missing:
```dart
import 'dart:typed_data';
```

Update `_loadImageSize` to store the bytes:
```dart
  Future<void> _loadImageSize() async {
    final bytes = await File(widget.imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        _imageSize = Size(
          frame.image.width.toDouble(),
          frame.image.height.toDouble(),
        );
        _imageBytes = bytes;
      });
    }
    frame.image.dispose();
    codec.dispose();
  }
```

- [ ] **Step 3: Replace Image.file with Image.memory in the widget**

In the `build` method, find:
```dart
                      child: Image.file(
                        File(widget.imagePath),
                        fit: BoxFit.contain,
                      ),
```

Replace with:
```dart
                      child: Image.memory(
                        _imageBytes!,
                        fit: BoxFit.contain,
                      ),
```

Note: `_imageBytes` is guaranteed non-null here because the `Image` widget is only shown when `_imageSize != null`, and both are set together in the same `setState` call.

- [ ] **Step 4: Run static analysis**

```bash
export PATH="$HOME/flutter/bin:$PATH" && flutter analyze 2>&1
```

Expected: no issues. If `Uint8List` is unresolved, add `import 'dart:typed_data';` to the imports.

- [ ] **Step 5: Commit**

```bash
git add lib/features/scanner/crop_screen.dart
git commit -m "perf: read crop screen image bytes once instead of twice

_loadImageSize decoded the full file bytes to get dimensions, then
Image.file re-read the same file for display. Now bytes are stored
and reused via Image.memory, halving file I/O for the crop screen."
```

---

## Final Verification

- [ ] Run full analysis:
  ```bash
  export PATH="$HOME/flutter/bin:$PATH" && flutter analyze 2>&1
  ```

- [ ] Build debug APK:
  ```bash
  export PATH="$HOME/flutter/bin:$PATH" && flutter build apk --debug 2>&1
  ```

- [ ] Manual test checklist:
  - Rotate page rapidly (double-tap rotation buttons) → only rotates once per tap, no double rotation ✓
  - Drag crop handle to right edge → crop rect stays at minimum width, no zero-width crop ✓
  - Pick a JPG from file picker → upload screen shows OCR metadata suggestions ✓
  - Pick a PDF from file picker → upload screen shows no OCR suggestions (PDF not suitable) ✓
  - Open crop screen on large image → no visible lag from double file read ✓
