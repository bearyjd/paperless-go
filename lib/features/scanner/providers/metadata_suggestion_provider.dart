import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_providers.dart';
import '../processing/metadata_matcher.dart';
import '../processing/ocr_extractor.dart';

part 'metadata_suggestion_provider.g.dart';

/// Extracts text from a scanned image via OCR and matches it against
/// cached correspondents, document types, and tags to generate suggestions.
@riverpod
Future<MetadataSuggestions> metadataSuggestions(
  Ref ref,
  String imagePath,
) async {
  final text = await OcrExtractor.extractText(imagePath);
  if (text.trim().isEmpty) return const MetadataSuggestions();

  final correspondents = await ref.read(correspondentsProvider.future);
  final docTypes = await ref.read(documentTypesProvider.future);
  final tags = await ref.read(tagsProvider.future);

  final params = MatchParams(
    text: text,
    correspondents: correspondents.values.toList(),
    documentTypes: docTypes.values.toList(),
    tags: tags.values.toList(),
  );

  return compute(MetadataMatcher.match, params);
}
