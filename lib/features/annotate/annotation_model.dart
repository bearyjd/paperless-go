import 'dart:ui';

enum AnnotationTool { pen, highlight, redact, eraser }

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

  Rect? get rect {
    if (tool != AnnotationTool.highlight && tool != AnnotationTool.redact) return null;
    if (points.length < 2) return null;
    return Rect.fromPoints(points.first, points.last);
  }
}

class _StrokeEntry {
  final int page;
  final Stroke stroke;
  _StrokeEntry(this.page, this.stroke);
}

class AnnotationState {
  final List<_StrokeEntry> _history = [];
  final List<_StrokeEntry> _redoStack = [];

  List<Stroke> strokes(int page) =>
      _history.where((e) => e.page == page).map((e) => e.stroke).toList();

  bool get hasAnnotations => _history.isNotEmpty;
  bool get canUndo => _history.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void addStroke(int page, Stroke stroke) {
    _history.add(_StrokeEntry(page, stroke));
    _redoStack.clear();
  }

  void undo() {
    if (_history.isEmpty) return;
    _redoStack.add(_history.removeLast());
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _history.add(_redoStack.removeLast());
  }

  void clearAll() {
    _history.clear();
    _redoStack.clear();
  }
}
