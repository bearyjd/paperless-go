import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../../core/models/tag.dart';

class TagChip extends StatelessWidget {
  final Tag tag;
  const TagChip({super.key, required this.tag});

  @override
  Widget build(BuildContext context) {
    final bgColor = parseColor(tag.colour) ??
        Theme.of(context).colorScheme.secondaryContainer;
    final fgColor = bgColor.computeLuminance() > 0.5
        ? Colors.black87
        : Colors.white;

    return Semantics(
      label: '${tag.name} tag',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: Spacing.xs),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Text(
          tag.name,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: fgColor,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  /// Compute a contrasting text color for a given background color.
  static Color contrastColor(Color bg) {
    return bg.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
  }

  static Color? parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final cleaned = hex.replaceFirst('#', '');
    try {
      int r, g, b, a = 0xFF;
      if (cleaned.length == 6) {
        r = int.parse(cleaned.substring(0, 2), radix: 16);
        g = int.parse(cleaned.substring(2, 4), radix: 16);
        b = int.parse(cleaned.substring(4, 6), radix: 16);
      } else if (cleaned.length == 8) {
        a = int.parse(cleaned.substring(0, 2), radix: 16);
        r = int.parse(cleaned.substring(2, 4), radix: 16);
        g = int.parse(cleaned.substring(4, 6), radix: 16);
        b = int.parse(cleaned.substring(6, 8), radix: 16);
      } else {
        return null;
      }
      return Color.fromARGB(a, r, g, b);
    } catch (_) {
      return null;
    }
  }
}

class TagOverflowChip extends StatelessWidget {
  final int count;
  const TagOverflowChip({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$count more tags',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: Spacing.xs),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Text(
          '+$count',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
