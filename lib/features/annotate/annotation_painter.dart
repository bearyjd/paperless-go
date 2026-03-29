import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'annotation_model.dart';

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
        break;
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
      strokes != oldDelegate.strokes || activeStroke != oldDelegate.activeStroke;
}
