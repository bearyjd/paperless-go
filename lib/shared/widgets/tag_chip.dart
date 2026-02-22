import 'package:flutter/material.dart';
import '../../core/models/tag.dart';

class TagChip extends StatelessWidget {
  final Tag tag;
  const TagChip({super.key, required this.tag});

  @override
  Widget build(BuildContext context) {
    final bgColor = parseColor(tag.colour) ??
        Theme.of(context).colorScheme.secondaryContainer;
    final fgColor = parseColor(tag.textColor) ??
        Theme.of(context).colorScheme.onSecondaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        tag.name,
        style: TextStyle(
          fontSize: 11,
          color: fgColor,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  static Color? parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final cleaned = hex.replaceFirst('#', '');
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
  }
}

class TagOverflowChip extends StatelessWidget {
  final int count;
  const TagOverflowChip({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '+$count',
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
