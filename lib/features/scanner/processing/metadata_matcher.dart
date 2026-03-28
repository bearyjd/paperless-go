import 'package:flutter/foundation.dart';

import '../../../core/models/correspondent.dart';
import '../../../core/models/document_type.dart';
import '../../../core/models/tag.dart';

/// Suggestions extracted from OCR text by matching against Paperless-ngx entities.
class MetadataSuggestions {
  final int? correspondentId;
  final int? documentTypeId;
  final List<int> tagIds;
  final DateTime? detectedDate;

  const MetadataSuggestions({
    this.correspondentId,
    this.documentTypeId,
    this.tagIds = const [],
    this.detectedDate,
  });
}

/// Pure Dart matching logic that runs entity matching algorithms
/// against OCR-extracted text. Respects Paperless-ngx `matchingAlgorithm` field.
class MetadataMatcher {
  MetadataMatcher._();

  /// Match OCR text against all entity types.
  /// Can run in a background isolate via [compute].
  static MetadataSuggestions match(MatchParams params) {
    final text = params.text;
    final textLower = text.toLowerCase();

    final correspondentId = _matchEntity(
      text,
      textLower,
      params.correspondents.map(
        (c) => _Entity(
          c.id,
          c.name,
          c.match,
          c.matchingAlgorithm,
          c.isInsensitive,
        ),
      ),
    );

    final documentTypeId = _matchEntity(
      text,
      textLower,
      params.documentTypes.map(
        (dt) => _Entity(
          dt.id,
          dt.name,
          dt.match,
          dt.matchingAlgorithm,
          dt.isInsensitive,
        ),
      ),
    );

    final tagIds = <int>[];
    for (final tag in params.tags) {
      final entity = _Entity(
        tag.id,
        tag.name,
        tag.match,
        tag.matchingAlgorithm,
        tag.isInsensitive,
      );
      if (_entityMatches(text, textLower, entity)) {
        tagIds.add(tag.id);
      }
    }

    final detectedDate = _detectDate(text);

    return MetadataSuggestions(
      correspondentId: correspondentId,
      documentTypeId: documentTypeId,
      tagIds: tagIds,
      detectedDate: detectedDate,
    );
  }

  static int? _matchEntity(
    String text,
    String textLower,
    Iterable<_Entity> entities,
  ) {
    for (final entity in entities) {
      if (_entityMatches(text, textLower, entity)) {
        return entity.id;
      }
    }
    return null;
  }

  static bool _entityMatches(String text, String textLower, _Entity entity) {
    switch (entity.matchingAlgorithm) {
      case 1: // any word
        if (entity.matchStr.isEmpty) return false;
        final words = entity.matchStr.split(RegExp(r'[\s,]+'));
        return words.any(
          (w) => w.isNotEmpty && textLower.contains(w.toLowerCase()),
        );

      case 2: // all words
        if (entity.matchStr.isEmpty) return false;
        final words = entity.matchStr.split(RegExp(r'[\s,]+'));
        return words
            .where((w) => w.isNotEmpty)
            .every((w) => textLower.contains(w.toLowerCase()));

      case 3: // exact match
        if (entity.matchStr.isEmpty) return false;
        if (entity.isInsensitive) {
          return textLower.contains(entity.matchStr.toLowerCase());
        }
        return text.contains(entity.matchStr);

      case 4: // regex
        if (entity.matchStr.isEmpty) return false;
        try {
          final regex = RegExp(
            entity.matchStr,
            caseSensitive: !entity.isInsensitive,
          );
          // Use original-case text for case-sensitive regex, lowered for insensitive.
          return regex.hasMatch(entity.isInsensitive ? textLower : text);
        } catch (_) {
          return false;
        }

      case 5: // fuzzy — case-insensitive substring of match or name
        final matchNeedle = entity.matchStr.isNotEmpty
            ? entity.matchStr.toLowerCase()
            : entity.name.toLowerCase();
        return textLower.contains(matchNeedle);

      case 6: // auto — name as case-insensitive substring
        return textLower.contains(entity.name.toLowerCase());

      case 0: // none — fallback: try name as substring
      default:
        return textLower.contains(entity.name.toLowerCase());
    }
  }

  /// Detect dates in OCR text using common formats.
  /// Returns the most recent non-future date found.
  static DateTime? _detectDate(String text) {
    final now = DateTime.now();
    final dates = <DateTime>[];

    // YYYY-MM-DD
    for (final m in RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})').allMatches(text)) {
      final d = _tryParse(
        int.parse(m.group(1)!),
        int.parse(m.group(2)!),
        int.parse(m.group(3)!),
      );
      if (d != null) dates.add(d);
    }

    // MM/DD/YYYY
    for (final m in RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})').allMatches(text)) {
      final d = _tryParse(
        int.parse(m.group(3)!),
        int.parse(m.group(1)!),
        int.parse(m.group(2)!),
      );
      if (d != null) dates.add(d);
    }

    // DD.MM.YYYY
    for (final m in RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{4})').allMatches(text)) {
      final d = _tryParse(
        int.parse(m.group(3)!),
        int.parse(m.group(2)!),
        int.parse(m.group(1)!),
      );
      if (d != null) dates.add(d);
    }

    // Month DD, YYYY
    final months = {
      'january': 1,
      'february': 2,
      'march': 3,
      'april': 4,
      'may': 5,
      'june': 6,
      'july': 7,
      'august': 8,
      'september': 9,
      'october': 10,
      'november': 11,
      'december': 12,
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };
    final monthPattern = months.keys.join('|');
    for (final m in RegExp(
      '($monthPattern)\\.?\\s+(\\d{1,2}),?\\s+(\\d{4})',
      caseSensitive: false,
    ).allMatches(text)) {
      final month = months[m.group(1)!.toLowerCase()];
      if (month != null) {
        final d = _tryParse(
          int.parse(m.group(3)!),
          month,
          int.parse(m.group(2)!),
        );
        if (d != null) dates.add(d);
      }
    }

    // Filter out future dates and pick the most recent
    final valid = dates.where((d) => !d.isAfter(now)).toList();
    if (valid.isEmpty) return null;
    valid.sort((a, b) => b.compareTo(a));
    return valid.first;
  }

  static DateTime? _tryParse(int year, int month, int day) {
    if (year < 1900 || year > 2100) return null;
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > 31) return null;
    try {
      final d = DateTime(year, month, day);
      // Validate that the date is real (e.g., no Feb 30)
      if (d.month != month || d.day != day) return null;
      return d;
    } catch (_) {
      return null;
    }
  }
}

/// Parameters for [MetadataMatcher.match], serializable for [compute].
class MatchParams {
  final String text;
  final List<Correspondent> correspondents;
  final List<DocumentType> documentTypes;
  final List<Tag> tags;

  MatchParams({
    required this.text,
    required this.correspondents,
    required this.documentTypes,
    required this.tags,
  });
}

class _Entity {
  final int id;
  final String name;
  final String matchStr;
  final int matchingAlgorithm;
  final bool isInsensitive;

  _Entity(
    this.id,
    this.name,
    this.matchStr,
    this.matchingAlgorithm,
    this.isInsensitive,
  );
}
