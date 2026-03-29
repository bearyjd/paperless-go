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

    test('rect returns null for pen tool', () {
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
      state.addStroke(0, Stroke(tool: AnnotationTool.pen, points: [const Offset(0, 0)], color: const Color(0xFF000000), strokeWidth: 2.0));
      state.undo();
      expect(state.strokes(0), isEmpty);
      expect(state.canUndo, false);
      expect(state.canRedo, true);
    });

    test('redo restores undone stroke', () {
      state.addStroke(0, Stroke(tool: AnnotationTool.pen, points: [const Offset(0, 0)], color: const Color(0xFF000000), strokeWidth: 2.0));
      state.undo();
      state.redo();
      expect(state.strokes(0).length, 1);
      expect(state.canRedo, false);
    });

    test('new stroke after undo clears redo stack', () {
      state.addStroke(0, Stroke(tool: AnnotationTool.pen, points: [const Offset(0, 0)], color: const Color(0xFF000000), strokeWidth: 2.0));
      state.undo();
      state.addStroke(0, Stroke(tool: AnnotationTool.pen, points: [const Offset(5, 5)], color: const Color(0xFF000000), strokeWidth: 2.0));
      expect(state.canRedo, false);
      expect(state.strokes(0).length, 1);
    });

    test('strokes are isolated per page', () {
      state.addStroke(0, Stroke(tool: AnnotationTool.pen, points: [const Offset(0, 0)], color: const Color(0xFF000000), strokeWidth: 2.0));
      state.addStroke(1, Stroke(tool: AnnotationTool.pen, points: [const Offset(5, 5)], color: const Color(0xFFFF0000), strokeWidth: 2.0));
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
