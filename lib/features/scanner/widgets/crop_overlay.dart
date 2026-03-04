import 'dart:math';
import 'package:flutter/material.dart';

/// Interactive crop rectangle overlay with draggable handles.
/// Stores crop rect as normalized (0-1) coordinates relative to the image.
class CropOverlay extends StatefulWidget {
  final Size imageSize;
  final Size displaySize;
  final ValueChanged<Rect> onCropChanged;
  final Rect? initialCrop;

  const CropOverlay({
    super.key,
    required this.imageSize,
    required this.displaySize,
    required this.onCropChanged,
    this.initialCrop,
  });

  @override
  State<CropOverlay> createState() => CropOverlayState();
}

class CropOverlayState extends State<CropOverlay> {
  late Rect _crop; // normalized 0-1

  static const _handleSize = 24.0;
  static const _minCropFraction = 0.05;

  @override
  void initState() {
    super.initState();
    _crop = widget.initialCrop ?? const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8);
  }

  Rect get _displayRect {
    return Rect.fromLTWH(
      _crop.left * widget.displaySize.width,
      _crop.top * widget.displaySize.height,
      _crop.width * widget.displaySize.width,
      _crop.height * widget.displaySize.height,
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final rect = _displayRect;
    final colorScheme = Theme.of(context).colorScheme;
    final handleColor = colorScheme.primary;

    return Stack(
      children: [
        // Semi-transparent mask
        Positioned.fill(
          child: CustomPaint(
            painter: _MaskPainter(cropRect: rect),
          ),
        ),
        // Rule-of-thirds grid
        Positioned(
          left: rect.left,
          top: rect.top,
          width: rect.width,
          height: rect.height,
          child: CustomPaint(
            painter: _GridPainter(color: Colors.white.withValues(alpha: 0.4)),
          ),
        ),
        // Crop border
        Positioned(
          left: rect.left,
          top: rect.top,
          width: rect.width,
          height: rect.height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
        // Corner handles
        _buildHandle(rect.topLeft, _HandlePosition.topLeft, handleColor),
        _buildHandle(rect.topRight, _HandlePosition.topRight, handleColor),
        _buildHandle(rect.bottomLeft, _HandlePosition.bottomLeft, handleColor),
        _buildHandle(
            rect.bottomRight, _HandlePosition.bottomRight, handleColor),
        // Edge handles
        _buildHandle(
          Offset(rect.center.dx, rect.top),
          _HandlePosition.topCenter,
          handleColor,
        ),
        _buildHandle(
          Offset(rect.center.dx, rect.bottom),
          _HandlePosition.bottomCenter,
          handleColor,
        ),
        _buildHandle(
          Offset(rect.left, rect.center.dy),
          _HandlePosition.centerLeft,
          handleColor,
        ),
        _buildHandle(
          Offset(rect.right, rect.center.dy),
          _HandlePosition.centerRight,
          handleColor,
        ),
      ],
    );
  }

  Widget _buildHandle(
      Offset position, _HandlePosition handlePos, Color color) {
    return Positioned(
      left: position.dx - _handleSize / 2,
      top: position.dy - _handleSize / 2,
      child: GestureDetector(
        onPanUpdate: (details) => _onHandleDrag(handlePos, details.delta),
        child: Container(
          width: _handleSize,
          height: _handleSize,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }

  void _onHandleDrag(_HandlePosition handle, Offset delta) {
    final rect = _displayRect;
    final dw = widget.displaySize.width;
    final dh = widget.displaySize.height;
    final minPx = _minCropFraction * min(dw, dh);

    var left = rect.left;
    var top = rect.top;
    var right = rect.right;
    var bottom = rect.bottom;

    switch (handle) {
      case _HandlePosition.topLeft:
        left = (left + delta.dx).clamp(0.0, right - minPx);
        top = (top + delta.dy).clamp(0.0, bottom - minPx);
      case _HandlePosition.topRight:
        right = (right + delta.dx).clamp(left + minPx, dw);
        top = (top + delta.dy).clamp(0.0, bottom - minPx);
      case _HandlePosition.bottomLeft:
        left = (left + delta.dx).clamp(0.0, right - minPx);
        bottom = (bottom + delta.dy).clamp(top + minPx, dh);
      case _HandlePosition.bottomRight:
        right = (right + delta.dx).clamp(left + minPx, dw);
        bottom = (bottom + delta.dy).clamp(top + minPx, dh);
      case _HandlePosition.topCenter:
        top = (top + delta.dy).clamp(0.0, bottom - minPx);
      case _HandlePosition.bottomCenter:
        bottom = (bottom + delta.dy).clamp(top + minPx, dh);
      case _HandlePosition.centerLeft:
        left = (left + delta.dx).clamp(0.0, right - minPx);
      case _HandlePosition.centerRight:
        right = (right + delta.dx).clamp(left + minPx, dw);
    }

    setState(() {
      _updateFromDisplay(Rect.fromLTRB(left, top, right, bottom));
    });
  }

  /// Reset crop to full image.
  void reset() {
    setState(() {
      _crop = const Rect.fromLTWH(0.0, 0.0, 1.0, 1.0);
      widget.onCropChanged(_crop);
    });
  }
}

enum _HandlePosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  topCenter,
  bottomCenter,
  centerLeft,
  centerRight,
}

/// Paints a semi-transparent dark mask outside the crop rectangle.
class _MaskPainter extends CustomPainter {
  final Rect cropRect;
  _MaskPainter({required this.cropRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black54;
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.saveLayer(fullRect, Paint());
    canvas.drawRect(fullRect, paint);
    canvas.drawRect(cropRect, Paint()..blendMode = BlendMode.clear);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MaskPainter old) => old.cropRect != cropRect;
}

/// Paints rule-of-thirds grid lines inside the crop area.
class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    for (var i = 1; i < 3; i++) {
      final x = size.width * i / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var i = 1; i < 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
