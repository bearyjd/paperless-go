import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';

/// The redesign's signature motif: a "stamp" chip — pill shape, dashed
/// border, slight −1° rotation, accent-tinted background.
///
/// Used for OCR-suggested tags and active filters throughout the app. When a
/// Paperless server tag carries a user-defined color, pass it as [tint]; the
/// stamp styling stays, tinted by that color. Otherwise the accentSoft token
/// is used.
///
/// This is the one recurring decorative device — do not introduce competing
/// motifs elsewhere.
class StampChip extends StatelessWidget {
  const StampChip({
    super.key,
    required this.label,
    this.icon,
    this.tint,
    this.onTap,
    this.onDeleted,
    this.rotated = true,
  });

  final String label;
  final IconData? icon;

  /// Optional server-defined tag color; falls back to accentSoft/accent.
  final Color? tint;

  final VoidCallback? onTap;
  final VoidCallback? onDeleted;

  /// Set false in dense horizontal strips where rotation would clip.
  final bool rotated;

  static const _rotationRad = -1 * math.pi / 180; // −1°

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color border;
    final Color background;
    final Color foreground;
    if (tint == null) {
      border = tokens.accentEmphasis;
      background = tokens.accentSoft;
      foreground =
          isDark ? tokens.accentEmphasis : tokens.accentFill;
    } else {
      border = tint!;
      background = Color.alphaBlend(
        tint!.withValues(alpha: isDark ? 0.28 : 0.16),
        tokens.card,
      );
      foreground = isDark
          ? Color.alphaBlend(Colors.white.withValues(alpha: 0.55), tint!)
          : Color.alphaBlend(Colors.black.withValues(alpha: 0.45), tint!);
    }

    final chip = CustomPaint(
      painter: _DashedStadiumPainter(color: border),
      child: Material(
        color: background,
        shape: const StadiumBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: 6,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: foreground),
                  const SizedBox(width: Spacing.xs),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: foreground),
                  ),
                ),
                if (onDeleted != null) ...[
                  const SizedBox(width: Spacing.xs),
                  InkWell(
                    onTap: onDeleted,
                    customBorder: const CircleBorder(),
                    child: Icon(Icons.close, size: 16, color: foreground),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    // Keep a ≥48dp effective tap target even though the pill is visually
    // shorter; the transparent hit area extends vertically.
    final constrained = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 32),
      child: chip,
    );

    return Semantics(
      button: onTap != null,
      label: label,
      child: SizedBox(
        height: onTap != null || onDeleted != null ? 48 : null,
        child: Center(
          child: rotated
              ? Transform.rotate(angle: _rotationRad, child: constrained)
              : constrained,
        ),
      ),
    );
  }
}

class _DashedStadiumPainter extends CustomPainter {
  const _DashedStadiumPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    );
    final path = Path()..addRRect(rrect);

    const dashLength = 4.0;
    const gapLength = 3.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedStadiumPainter oldDelegate) =>
      oldDelegate.color != color;
}
