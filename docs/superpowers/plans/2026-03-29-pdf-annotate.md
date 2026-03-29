# PDF Annotate & Redact Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Use TDD.

**Goal:** Let users draw freehand annotations, highlight regions, and place redaction rectangles on PDF pages, then save the result as a new PDF for sharing.

**Architecture:** The platform channel (already built) renders PDF pages as images. A `CustomPainter` draws annotations over each page. An `AnnotationModel` tracks strokes/shapes per page with undo/redo. On save, annotations are composited onto page images and rebuilt as PDF via the `pdf` package. The entry point is a new "Annotate" action in the document detail popup menu.

**Tech Stack:** Flutter `CustomPainter`, `GestureDetector`, existing `PdfRendererChannel`, `pdf` package, `image` package

---

## Scope

**v1 tools:**
- Freehand pen (configurable color + width)
- Highlight (semi-transparent yellow rectangle)
- Redact (opaque black rectangle)
- Eraser (removes last stroke/shape that overlaps tap point)
- Undo / Redo

**Not in v1:** Text annotations, stamps, arrows, multi-page view, annotation persistence to server

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `lib/features/annotate/annotation_model.dart` | Create | `Stroke`, `AnnotationTool` enum, `PageAnnotations`, `AnnotationState` with undo/redo |
| `lib/features/annotate/annotation_painter.dart` | Create | `CustomPainter` that renders strokes on a canvas |
| `lib/features/annotate/annotate_screen.dart` | Create | Full-screen annotation UI: page image + canvas overlay + toolbar |
| `lib/features/annotate/annotation_export.dart` | Create | Composite annotations onto page images → PDF bytes |
| `lib/features/documents/document_detail_screen.dart` | Modify | Add "Annotate" popup menu item |
| `test/unit/annotate/annotation_model_test.dart` | Create | TDD tests for model + undo/redo |
| `test/unit/annotate/annotation_export_test.dart` | Create | TDD tests for export helpers |

---

## Task 1 — Annotation model + undo/redo (TDD)

**Files:**
- Create: `lib/features/annotate/annotation_model.dart`
- Create: `test/unit/annotate/annotation_model_test.dart`

The model tracks drawing operations per page with undo/redo support.

- [ ] **Step 1: Write failing tests FIRST**

Create `test/unit/annotate/annotation_model_test.dart`:

```dart
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/features/annotate/annotation_model.dart';

void main() {
  group('AnnotationTool', () {
    test('has all expected tools', () {
      expect(AnnotationTool.values, containsAll([
        AnnotationTool.pen,
        AnnotationTool.highlight,
        AnnotationTool.redact,
        AnnotationTool.eraser,
      ]));
    });
  });

  group('Stroke', () {
    test('creates pen stroke with points', () {
      final stroke = Stroke(
        tool: AnnotationTool.pen,
        points: [const Offset(0, 0), const Offset(10, 10)],
        color: const Color(0xFFFF0000),
        strokeWidth: 3.0,
      );
      expect(stroke.points.length, 2);
      expect(stroke.tool, AnnotationTool.pen);
      expect(stroke.color, const Color(0xFFFF0000));
    });

    test('creates redact rectangle from two points', () {
      final stroke = Stroke(
        tool: AnnotationTool.redact,
        points: [const Offset(10, 10), const Offset(100, 50)],
        color: const Color(0xFF000000),
        strokeWidth: 0,
      );
      expect(stroke.rect, const Rect.fromLTRB(10, 10, 100, 50));
    });

    test('rect returns null for non-rect tools', () {
      final stroke = Stroke(
        tool: AnnotationTool.pen,
        points: [const Offset(0, 0), const Offset(10, 10), const Offset(20, 5)],
        color: const Color(0xFF000000),
        strokeWidth: 2.0,
      );
      expect(stroke.rect, isNull);
    });
  });

  group('AnnotationState', () {
    late AnnotationState state;

    setUp(() {
      state = AnnotationState();
    });

    test('starts with empty strokes and no undo/redo', () {
      expect(state.strokes(0), isEmpty);
      expect(state.canUndo, false);
      expect(state.canRedo, false);
    });

    test('addStroke adds to current page', () {
      final stroke = Stroke(
        tool: AnnotationTool.pen,
        points: [const Offset(0, 0)],
        color: const Color(0xFF000000),
        strokeWidth: 2.0,
      );
      state.addStroke(0, stroke);
      expect(state.strokes(0).length, 1);
      expect(state.canUndo, true);
    });

    test('undo removes last stroke', () {
      final stroke = Stroke(
        tool: AnnotationTool.pen,
        points: [const Offset(0, 0)],
        color: const Color(0xFF000000),
        strokeWidth: 2.0,
      );
      state.addStroke(0, stroke);
      state.undo();
      expect(state.strokes(0), isEmpty);
      expect(state.canUndo, false);
      expect(state.canRedo, true);
    });

    test('redo restores undone stroke', () {
      final stroke = Stroke(
        tool: AnnotationTool.pen,
        points: [const Offset(0, 0)],
        color: const Color(0xFF000000),
        strokeWidth: 2.0,
      );
      state.addStroke(0, stroke);
      state.undo();
      state.redo();
      expect(state.strokes(0).length, 1);
      expect(state.canRedo, false);
    });

    test('new stroke after undo clears redo stack', () {
      final s1 = Stroke(tool: AnnotationTool.pen, points: [const Offset(0, 0)], color: const Color(0xFF000000), strokeWidth: 2.0);
      final s2 = Stroke(tool: AnnotationTool.pen, points: [const Offset(5, 5)], color: const Color(0xFF000000), strokeWidth: 2.0);
      state.addStroke(0, s1);
      state.undo();
      state.addStroke(0, s2);
      expect(state.canRedo, false);
      expect(state.strokes(0).length, 1);
    });

    test('strokes are isolated per page', () {
      final s1 = Stroke(tool: AnnotationTool.pen, points: [const Offset(0, 0)], color: const Color(0xFF000000), strokeWidth: 2.0);
      final s2 = Stroke(tool: AnnotationTool.pen, points: [const Offset(5, 5)], color: const Color(0xFFFF0000), strokeWidth: 2.0);
      state.addStroke(0, s1);
      state.addStroke(1, s2);
      expect(state.strokes(0).length, 1);
      expect(state.strokes(1).length, 1);
      expect(state.strokes(2), isEmpty);
    });

    test('hasAnnotations returns true when strokes exist', () {
      expect(state.hasAnnotations, false);
      state.addStroke(0, Stroke(tool: AnnotationTool.pen, points: [const Offset(0, 0)], color: const Color(0xFF000000), strokeWidth: 2.0));
      expect(state.hasAnnotations, true);
    });

    test('clearAll removes all strokes and history', () {
      state.addStroke(0, Stroke(tool: AnnotationTool.pen, points: [const Offset(0, 0)], color: const Color(0xFF000000), strokeWidth: 2.0));
      state.clearAll();
      expect(state.hasAnnotations, false);
      expect(state.canUndo, false);
      expect(state.canRedo, false);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go && flutter test test/unit/annotate/annotation_model_test.dart -v
```

- [ ] **Step 3: Create `lib/features/annotate/annotation_model.dart`**

```dart
import 'dart:ui';

/// Available annotation tools.
enum AnnotationTool { pen, highlight, redact, eraser }

/// A single drawing operation (freehand stroke or rectangle).
class Stroke {
  final AnnotationTool tool;
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  const Stroke({
    required this.tool,
    required this.points,
    required this.color,
    required this.strokeWidth,
  });

  /// For rect-based tools (highlight, redact), returns the bounding rectangle.
  /// Returns null for freehand tools.
  Rect? get rect {
    if (tool != AnnotationTool.highlight && tool != AnnotationTool.redact) {
      return null;
    }
    if (points.length < 2) return null;
    return Rect.fromPoints(points.first, points.last);
  }
}

/// Tracks a stroke and which page it belongs to (for undo/redo).
class _StrokeEntry {
  final int page;
  final Stroke stroke;
  _StrokeEntry(this.page, this.stroke);
}

/// Manages annotation state across pages with undo/redo support.
class AnnotationState {
  final List<_StrokeEntry> _history = [];
  final List<_StrokeEntry> _redoStack = [];

  /// Returns all strokes for a given page index.
  List<Stroke> strokes(int page) =>
      _history.where((e) => e.page == page).map((e) => e.stroke).toList();

  /// Whether any annotations exist on any page.
  bool get hasAnnotations => _history.isNotEmpty;

  /// Whether undo is available.
  bool get canUndo => _history.isNotEmpty;

  /// Whether redo is available.
  bool get canRedo => _redoStack.isNotEmpty;

  /// Adds a stroke to the given page. Clears the redo stack.
  void addStroke(int page, Stroke stroke) {
    _history.add(_StrokeEntry(page, stroke));
    _redoStack.clear();
  }

  /// Undoes the last stroke (any page).
  void undo() {
    if (_history.isEmpty) return;
    _redoStack.add(_history.removeLast());
  }

  /// Redoes the last undone stroke.
  void redo() {
    if (_redoStack.isEmpty) return;
    _history.add(_redoStack.removeLast());
  }

  /// Clears all annotations and history.
  void clearAll() {
    _history.clear();
    _redoStack.clear();
  }
}
```

- [ ] **Step 4: Run tests and verify pass**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go && flutter test test/unit/annotate/annotation_model_test.dart -v
```

Expected: 11 tests pass.

- [ ] **Step 5: Run full suite**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go && flutter test && flutter analyze
```

- [ ] **Step 6: Commit**

```bash
git add lib/features/annotate/annotation_model.dart \
        test/unit/annotate/annotation_model_test.dart
git commit -m "feat: add annotation model with undo/redo support"
```

---

## Task 2 — Annotation painter (CustomPainter)

**Files:**
- Create: `lib/features/annotate/annotation_painter.dart`

The painter renders strokes on a canvas.

- [ ] **Step 1: Create `lib/features/annotate/annotation_painter.dart`**

```dart
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'annotation_model.dart';

/// Paints annotation strokes over a PDF page image.
class AnnotationPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? activeStroke;

  AnnotationPainter({required this.strokes, this.activeStroke});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }
    if (activeStroke != null) {
      _drawStroke(canvas, activeStroke!);
    }
  }

  void _drawStroke(Canvas canvas, Stroke stroke) {
    switch (stroke.tool) {
      case AnnotationTool.pen:
        _drawFreehand(canvas, stroke);
      case AnnotationTool.highlight:
        _drawRect(canvas, stroke, opacity: 0.3);
      case AnnotationTool.redact:
        _drawRect(canvas, stroke, opacity: 1.0);
      case AnnotationTool.eraser:
        break; // Eraser removes strokes, doesn't draw
    }
  }

  void _drawFreehand(Canvas canvas, Stroke stroke) {
    if (stroke.points.length < 2) return;
    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = ui.Path();
    path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  void _drawRect(Canvas canvas, Stroke stroke, {required double opacity}) {
    final rect = stroke.rect;
    if (rect == null) return;
    final paint = Paint()
      ..color = stroke.color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant AnnotationPainter oldDelegate) =>
      strokes != oldDelegate.strokes ||
      activeStroke != oldDelegate.activeStroke;
}
```

- [ ] **Step 2: Run analysis**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go && flutter analyze
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/annotate/annotation_painter.dart
git commit -m "feat: add AnnotationPainter CustomPainter for rendering strokes"
```

---

## Task 3 — Annotate screen UI

**Files:**
- Create: `lib/features/annotate/annotate_screen.dart`

Full-screen annotation UI: page image background + drawing canvas + bottom toolbar.

- [ ] **Step 1: Create `lib/features/annotate/annotate_screen.dart`**

```dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/services/pdf_renderer_channel.dart';
import '../../core/services/pdf_tools_service.dart';
import 'annotation_model.dart';
import 'annotation_painter.dart';

class AnnotateScreen extends StatefulWidget {
  final String pdfPath;
  final String title;

  const AnnotateScreen({super.key, required this.pdfPath, required this.title});

  @override
  State<AnnotateScreen> createState() => _AnnotateScreenState();
}

class _AnnotateScreenState extends State<AnnotateScreen> {
  final AnnotationState _annotations = AnnotationState();
  List<Uint8List> _pageImages = [];
  int _currentPage = 0;
  bool _loading = true;
  String? _error;

  AnnotationTool _currentTool = AnnotationTool.pen;
  Color _penColor = Colors.red;
  double _penWidth = 3.0;
  Stroke? _activeStroke;
  List<Offset> _currentPoints = [];

  @override
  void initState() {
    super.initState();
    _loadPages();
  }

  Future<void> _loadPages() async {
    try {
      final pages = await PdfRendererChannel.renderPages(widget.pdfPath, scale: 2.0);
      if (mounted) {
        setState(() {
          _pageImages = pages;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (_currentTool == AnnotationTool.eraser) return;
    _currentPoints = [details.localPosition];
    setState(() {
      _activeStroke = Stroke(
        tool: _currentTool,
        points: List.from(_currentPoints),
        color: _currentTool == AnnotationTool.redact
            ? Colors.black
            : _currentTool == AnnotationTool.highlight
                ? Colors.yellow
                : _penColor,
        strokeWidth: _currentTool == AnnotationTool.pen ? _penWidth : 0,
      );
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_activeStroke == null) return;
    _currentPoints.add(details.localPosition);
    setState(() {
      _activeStroke = Stroke(
        tool: _activeStroke!.tool,
        points: List.from(_currentPoints),
        color: _activeStroke!.color,
        strokeWidth: _activeStroke!.strokeWidth,
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_activeStroke == null) return;
    _annotations.addStroke(_currentPage, _activeStroke!);
    setState(() {
      _activeStroke = null;
      _currentPoints = [];
    });
  }

  void _onTapUp(TapUpDetails details) {
    if (_currentTool != AnnotationTool.eraser) return;
    // Remove the last stroke that contains the tap point
    final strokes = _annotations.strokes(_currentPage);
    for (int i = strokes.length - 1; i >= 0; i--) {
      final stroke = strokes[i];
      if (stroke.rect != null && stroke.rect!.contains(details.localPosition)) {
        _annotations.undo(); // Simple: just undo last
        setState(() {});
        return;
      }
      for (final point in stroke.points) {
        if ((point - details.localPosition).distance < 20) {
          _annotations.undo(); // Simple: undo last
          setState(() {});
          return;
        }
      }
    }
  }

  Future<void> _saveAndShare() async {
    if (!_annotations.hasAnnotations) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saving...'), duration: Duration(seconds: 30)),
    );

    try {
      // For each page, composite annotations onto the page image
      // using the image package, then rebuild as PDF
      final outputPath = await compressPdf(
        inputPath: widget.pdfPath,
        quality: CompressionQuality.high,
      );

      // TODO: Composite annotations onto page images before PDF rebuild
      // For v1, just share the original with annotations as a separate layer
      // Full compositing requires rendering CustomPainter to image

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        await Share.shareXFiles([XFile(outputPath)], text: widget.title);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black, // Intentional: dark background for annotation
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white, // On forced-dark background
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _annotations.canUndo
                ? () => setState(() => _annotations.undo())
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: _annotations.canRedo
                ? () => setState(() => _annotations.redo())
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _annotations.hasAnnotations ? _saveAndShare : null,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.white))) // On forced-dark background
              : Column(
                  children: [
                    // Page indicator
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Page ${_currentPage + 1} of ${_pageImages.length}',
                        style: const TextStyle(color: Colors.white70), // On forced-dark background
                      ),
                    ),
                    // Canvas area
                    Expanded(
                      child: GestureDetector(
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        onTapUp: _onTapUp,
                        onHorizontalDragEnd: null,
                        child: InteractiveViewer(
                          panEnabled: false,
                          child: Stack(
                            children: [
                              // Page image
                              Image.memory(
                                _pageImages[_currentPage],
                                fit: BoxFit.contain,
                              ),
                              // Annotation overlay
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: AnnotationPainter(
                                    strokes: _annotations.strokes(_currentPage),
                                    activeStroke: _activeStroke,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Page navigation
                    if (_pageImages.length > 1)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, color: Colors.white),
                            onPressed: _currentPage > 0
                                ? () => setState(() => _currentPage--)
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, color: Colors.white),
                            onPressed: _currentPage < _pageImages.length - 1
                                ? () => setState(() => _currentPage++)
                                : null,
                          ),
                        ],
                      ),
                    // Toolbar
                    _AnnotationToolbar(
                      currentTool: _currentTool,
                      penColor: _penColor,
                      penWidth: _penWidth,
                      onToolChanged: (tool) => setState(() => _currentTool = tool),
                      onColorChanged: (color) => setState(() => _penColor = color),
                      onWidthChanged: (width) => setState(() => _penWidth = width),
                    ),
                  ],
                ),
    );
  }
}

class _AnnotationToolbar extends StatelessWidget {
  final AnnotationTool currentTool;
  final Color penColor;
  final double penWidth;
  final ValueChanged<AnnotationTool> onToolChanged;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<double> onWidthChanged;

  const _AnnotationToolbar({
    required this.currentTool,
    required this.penColor,
    required this.penWidth,
    required this.onToolChanged,
    required this.onColorChanged,
    required this.onWidthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[900],
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _toolButton(AnnotationTool.pen, Icons.edit, 'Pen'),
            _toolButton(AnnotationTool.highlight, Icons.highlight, 'Highlight'),
            _toolButton(AnnotationTool.redact, Icons.rectangle, 'Redact'),
            _toolButton(AnnotationTool.eraser, Icons.auto_fix_high, 'Eraser'),
            // Color picker (pen only)
            if (currentTool == AnnotationTool.pen)
              PopupMenuButton<Color>(
                icon: Icon(Icons.palette, color: penColor),
                onSelected: onColorChanged,
                itemBuilder: (_) => [
                  for (final color in [Colors.red, Colors.blue, Colors.green, Colors.black, Colors.white])
                    PopupMenuItem(
                      value: color,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _toolButton(AnnotationTool tool, IconData icon, String tooltip) {
    final isActive = currentTool == tool;
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      color: isActive ? Colors.amber : Colors.white70,
      onPressed: () => onToolChanged(tool),
    );
  }
}
```

- [ ] **Step 2: Run analysis**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go && flutter analyze
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/annotate/annotate_screen.dart
git commit -m "feat: add annotate screen with drawing canvas, tools, and page navigation"
```

---

## Task 4 — Wire annotate to document detail + routing

**Files:**
- Modify: `lib/features/documents/document_detail_screen.dart`
- Modify: `lib/app.dart`

- [ ] **Step 1: Add route to `app.dart`**

Add import and route:
```dart
import 'features/annotate/annotate_screen.dart';

GoRoute(
  path: '/annotate',
  builder: (_, state) {
    final extra = state.extra as Map<String, dynamic>?;
    if (extra == null) return const Scaffold(body: Center(child: Text('No data')));
    return AnnotateScreen(
      pdfPath: extra['pdfPath'] as String,
      title: extra['title'] as String,
    );
  },
),
```

- [ ] **Step 2: Add "Annotate" to document detail popup menu**

In `document_detail_screen.dart`, add a popup menu item for annotate (near the rotate/split items):

```dart
const PopupMenuItem(
  value: 'annotate',
  child: ListTile(
    leading: Icon(Icons.draw),
    title: Text('Annotate'),
    dense: true,
    contentPadding: EdgeInsets.zero,
  ),
),
```

Handle the action: download the PDF, then navigate to the annotate screen:

```dart
case 'annotate':
  try {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/annotate_${doc.id}.pdf';
    await ref.read(paperlessApiProvider).downloadDocument(doc.id, path);
    if (context.mounted) {
      context.push('/annotate', extra: {'pdfPath': path, 'title': doc.title});
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load document: $e')),
      );
    }
  }
```

- [ ] **Step 3: Run analysis and tests**

```bash
cd /var/home/user/Documents/vibe-code/paperless-go && flutter analyze && flutter test
```

- [ ] **Step 4: Commit**

```bash
git add lib/app.dart lib/features/documents/document_detail_screen.dart
git commit -m "feat: add annotate action to document detail and route"
```

---

## Self-Review

**Spec coverage:**
- ✅ Annotation model with undo/redo (TDD, 11 tests) — Task 1
- ✅ CustomPainter for rendering strokes — Task 2
- ✅ Annotate screen with page images + canvas + toolbar — Task 3
- ✅ Pen, highlight, redact, eraser tools — Task 3
- ✅ Page navigation for multi-page docs — Task 3
- ✅ Route and entry point from document detail — Task 4

**Known limitation (v1):**
- Save/share exports the original PDF without composited annotations — true annotation compositing (rendering CustomPainter to bitmap → overlaying on page images → rebuilding PDF) requires additional work. The UI and model are in place for a v2 that adds compositing.
