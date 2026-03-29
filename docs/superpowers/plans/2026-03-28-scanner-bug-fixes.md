# Scanner Bug Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix 4 confirmed bugs in the scanner pipeline: broken case-sensitive exact matching, silent SpeedDialFab errors, missing single-page preview on preset change, and temp file leaks from crop/rotate.

**Architecture:** All fixes are minimal, isolated, and confined to the file(s) listed. No new dependencies. No refactoring of adjacent code.

**Tech Stack:** Flutter, Dart, Riverpod, file I/O (dart:io), GoRouter

---

## Pre-flight: Bug 1 Already Fixed — Verify Only

Bug 1 (concurrent processing race on rapid preset switching) was already fixed: `enhance_screen.dart` has `_processingGeneration` (line 27) and checks it throughout `_processAllPages()` and `_processPage()`. No code change needed — just confirm analysis.

**Evidence:**
- `_processAllPages()` line 76: `final generation = ++_processingGeneration;`
- line 89: `if (generation != _processingGeneration) return;` — aborts stale runs
- line 100: `if (mounted && generation == _processingGeneration)` — guards final setState

---

## File Map

| File | Change |
|---|---|
| `lib/features/scanner/processing/metadata_matcher.dart` | Fix case-sensitive exact match (lines 114-119) |
| `lib/app.dart` | Show SnackBar on non-cancellation errors in SpeedDialFab |
| `lib/features/scanner/enhance_screen.dart` | Remove `> 1` guard so single-page scans get fast preview |
| `lib/features/scanner/scan_review_screen.dart` | Delete old temp files after rotate and crop |

---

## Task 1: Fix Case-Sensitive Exact Match in MetadataMatcher

**Root cause:** Both branches of the `isInsensitive` ternary on line 116-118 call `.toLowerCase()` on the needle, making case-sensitive exact match impossible. The haystack is also always `textLower`, so even if the needle were correct, the match would be case-insensitive regardless.

**Files:**
- Modify: `lib/features/scanner/processing/metadata_matcher.dart`

- [ ] **Step 1: Read the current broken code**

Open `lib/features/scanner/processing/metadata_matcher.dart` and confirm lines 114-119 read:

```dart
case 3: // exact match
  if (entity.matchStr.isEmpty) return false;
  final needle = entity.isInsensitive
      ? entity.matchStr.toLowerCase()
      : entity.matchStr.toLowerCase(); // BUG: both branches lowercase
  return textLower.contains(needle); // BUG: always uses lowercased haystack
```

- [ ] **Step 2: Fix the case-sensitive exact match**

Replace lines 114-119 with:

```dart
case 3: // exact match
  if (entity.matchStr.isEmpty) return false;
  if (entity.isInsensitive) {
    return textLower.contains(entity.matchStr.toLowerCase());
  }
  return text.contains(entity.matchStr);
```

- [ ] **Step 3: Run static analysis**

```bash
export PATH="$HOME/flutter/bin:$PATH" && flutter analyze 2>&1
```

Expected: no new issues.

- [ ] **Step 4: Commit**

```bash
git add lib/features/scanner/processing/metadata_matcher.dart
git commit -m "fix: case-sensitive exact match was always case-insensitive

Both ternary branches in matchingAlgorithm case 3 called toLowerCase()
and used textLower as haystack. Now case-sensitive path uses original
text and matchStr without lowercasing."
```

---

## Task 2: Show Errors from SpeedDialFab Actions

**Root cause:** `_onScan`, `_onBatchScan`, and `_onUploadFile` catch all exceptions with `catch (_) {}`. Scanner launch failures and file picker errors are silently ignored, leaving the user with no feedback. The fix: distinguish user cancellations (ignore) from real errors (show SnackBar).

**Files:**
- Modify: `lib/app.dart`

**Notes on cancellation detection:**
- `CunningDocumentScanner.getPictures()` returns `null` (not an exception) when the user cancels — there is no cancellation exception to suppress. The `catch` block is for genuine platform errors only.
- `FilePicker.platform.pickFiles()` returns `null` on cancellation — same pattern.
- Therefore the `catch (_) {}` block is only needed for unexpected errors and should show a SnackBar instead of silently swallowing them.

- [ ] **Step 1: Open `lib/app.dart` and locate the three methods**

Find `_onScan` (around line 381), `_onBatchScan` (around line 393), and `_onUploadFile` (around line 413).

- [ ] **Step 2: Replace the catch blocks in all three methods**

In `_onScan`, replace:
```dart
    } catch (_) {
      // User cancelled or error
    }
```

With:
```dart
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scanner error: $e')),
        );
      }
    }
```

In `_onBatchScan`, replace:
```dart
    } catch (_) {
      // User cancelled or error
    }
```

With:
```dart
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scanner error: $e')),
        );
      }
    }
```

In `_onUploadFile`, replace:
```dart
    } catch (_) {
      // User cancelled or error
    }
```

With:
```dart
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File picker error: $e')),
        );
      }
    }
```

- [ ] **Step 3: Run static analysis**

```bash
export PATH="$HOME/flutter/bin:$PATH" && flutter analyze 2>&1
```

Expected: no new issues.

- [ ] **Step 4: Commit**

```bash
git add lib/app.dart
git commit -m "fix: show SnackBar instead of silently swallowing SpeedDialFab errors

Scanner and file picker failures were caught with catch(_){} and
discarded. Cancellations return null (not exceptions) so the catch
block was masking genuine errors. Now shows a SnackBar on failure."
```

---

## Task 3: Fast Preview for Single-Page Preset Changes

**Root cause:** `_onPresetChanged` only calls `_updatePreviewEnhanced()` when `_originalPaths.length > 1`. For single-page scans, users change the preset and get no visual feedback until the full processing completes (which can take several seconds). The `> 1` guard was likely added by mistake — the preview logic works fine for single pages.

**Files:**
- Modify: `lib/features/scanner/enhance_screen.dart`

- [ ] **Step 1: Open `lib/features/scanner/enhance_screen.dart` and find `_onPresetChanged`**

Locate the method at around line 158. The relevant section is:

```dart
Future<void> _onPresetChanged(ProcessingPreset preset) async {
  if (preset == _selectedPreset) return;
  setState(() {
    _selectedPreset = preset;
    _enhancedPaths = List.filled(_originalPaths.length, null);
    _previewEnhanced = null;
  });
  // Only generate a separate fast preview for multi-page scans
  if (_originalPaths.length > 1 && _previewOriginal != null) {
    _updatePreviewEnhanced(_previewOriginal!);
  }
  _processAllPages();
}
```

- [ ] **Step 2: Remove the `> 1` length guard**

Replace the `_onPresetChanged` method body from:
```dart
  // Only generate a separate fast preview for multi-page scans
  if (_originalPaths.length > 1 && _previewOriginal != null) {
    _updatePreviewEnhanced(_previewOriginal!);
  }
```

With:
```dart
  // Generate a fast low-res preview immediately for all scan sizes
  if (_previewOriginal != null) {
    _updatePreviewEnhanced(_previewOriginal!);
  }
```

- [ ] **Step 3: Run static analysis**

```bash
export PATH="$HOME/flutter/bin:$PATH" && flutter analyze 2>&1
```

Expected: no issues.

- [ ] **Step 4: Commit**

```bash
git add lib/features/scanner/enhance_screen.dart
git commit -m "fix: show fast preview on preset change for single-page scans

The length > 1 guard prevented _updatePreviewEnhanced from being
called for single-page scans, leaving the preview stale until full
processing completed. The preview logic works for any page count."
```

---

## Task 4: Delete Temp Files After Rotate and Crop

**Root cause:** `_rotatePage()` and `_cropPage()` in `scan_review_screen.dart` replace `_pages[_currentPage]` with a new temp file path but never delete the old temp file. Each rotate or crop operation leaks a temp image file. Over a multi-page session with several rotations, this can accumulate dozens of MB of abandoned files in the temp directory.

**Files:**
- Modify: `lib/features/scanner/scan_review_screen.dart`

- [ ] **Step 1: Open `lib/features/scanner/scan_review_screen.dart` and find `_rotatePage` and `_cropPage`**

`_rotatePage` is at around line 188. The relevant section after getting `newPath`:
```dart
      final oldPath = _pages[_currentPage];
      final newPath = await CropRotate.rotateImage90(
        inputPath: oldPath,
        clockwise: clockwise,
      );
      if (!mounted) return;
      // Evict only the old image from Flutter's cache instead of clearing
      // the entire cache, which would affect unrelated screens.
      final oldFileKey = FileImage(File(oldPath));
      imageCache.evict(oldFileKey);
      setState(() {
        _pages[_currentPage] = newPath;
        _isProcessing = false;
      });
```

`_cropPage` is at around line 214. The relevant section:
```dart
    if (result != null && mounted) {
      // Evict only the old image from Flutter's cache
      final oldFileKey = FileImage(File(_pages[_currentPage]));
      imageCache.evict(oldFileKey);
      setState(() {
        _pages[_currentPage] = result;
      });
    }
```

- [ ] **Step 2: Delete old temp file in `_rotatePage` after evicting from image cache**

In `_rotatePage`, after `imageCache.evict(oldFileKey)` and before `setState`, add a fire-and-forget delete:

```dart
      final oldPath = _pages[_currentPage];
      final newPath = await CropRotate.rotateImage90(
        inputPath: oldPath,
        clockwise: clockwise,
      );
      if (!mounted) return;
      final oldFileKey = FileImage(File(oldPath));
      imageCache.evict(oldFileKey);
      File(oldPath).delete().ignore(); // clean up temp file
      setState(() {
        _pages[_currentPage] = newPath;
        _isProcessing = false;
      });
```

- [ ] **Step 3: Delete old temp file in `_cropPage` after evicting from image cache**

In `_cropPage`, capture the old path before setState and add delete. Replace:

```dart
    if (result != null && mounted) {
      // Evict only the old image from Flutter's cache
      final oldFileKey = FileImage(File(_pages[_currentPage]));
      imageCache.evict(oldFileKey);
      setState(() {
        _pages[_currentPage] = result;
      });
    }
```

With:
```dart
    if (result != null && mounted) {
      // Evict only the old image from Flutter's cache
      final oldPath = _pages[_currentPage];
      final oldFileKey = FileImage(File(oldPath));
      imageCache.evict(oldFileKey);
      File(oldPath).delete().ignore(); // clean up temp file
      setState(() {
        _pages[_currentPage] = result;
      });
    }
```

- [ ] **Step 4: Verify `dart:io` import is present**

Check the imports at the top of `scan_review_screen.dart` for `import 'dart:io';`. If missing, add it.

- [ ] **Step 5: Run static analysis**

```bash
export PATH="$HOME/flutter/bin:$PATH" && flutter analyze 2>&1
```

Expected: no new issues.

- [ ] **Step 6: Commit**

```bash
git add lib/features/scanner/scan_review_screen.dart
git commit -m "fix: delete old temp files after rotate and crop in scan review

Each rotate or crop created a new temp file but the old one was never
deleted. Over multiple operations this accumulated leaked files in the
system temp directory. Use File.delete().ignore() for async cleanup."
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
  - Configure an entity with algorithm=3 (exact), case-sensitive, matchStr="Invoice" → document containing "Invoice" matches ✓, "invoice" does not ✓
  - Configure an entity with algorithm=3 (exact), case-insensitive, matchStr="Invoice" → both "Invoice" and "invoice" match ✓
  - Trigger a real scanner error (e.g., deny camera permission) → SnackBar appears ✓ (if testable)
  - Scan a single page, change preset → preview updates immediately without waiting for full processing ✓
  - Scan multiple pages, change preset → preview updates immediately ✓ (regression check)
  - Rotate a page, then rotate again → no orphaned files accumulate in temp dir ✓
  - Crop a page → no orphaned files in temp dir ✓
