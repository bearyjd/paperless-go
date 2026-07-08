import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/api/api_providers.dart';
import '../../core/models/document.dart';
import '../scanner/processing/metadata_matcher.dart';

part 'inbox_suggestions_provider.g.dart';

/// Metadata suggestions for an inbox document, matched from the server-side
/// OCR text ([Document.content]) — no local OCR needed, so this works in the
/// degoogled build too.
///
/// Suggestions are pre-filtered for the accept flow:
///  - inbox tags and tags already on the document are dropped
///  - correspondent/document type are only suggested when currently unset
@riverpod
Future<MetadataSuggestions> inboxSuggestions(Ref ref, Document doc) async {
  final text = doc.content ?? '';
  if (text.trim().isEmpty) return const MetadataSuggestions();

  final correspondents = await ref.watch(correspondentsProvider.future);
  final docTypes = await ref.watch(documentTypesProvider.future);
  final tags = await ref.watch(tagsProvider.future);

  final raw = await compute(
    MetadataMatcher.match,
    MatchParams(
      text: text,
      correspondents: correspondents.values.toList(),
      documentTypes: docTypes.values.toList(),
      tags: tags.values.toList(),
    ),
  );

  final existing = doc.tags.toSet();
  final tagIds = raw.tagIds
      .where((id) => !existing.contains(id))
      .where((id) => !(tags[id]?.isInboxTag ?? false))
      .toList();

  return MetadataSuggestions(
    correspondentId: doc.correspondent == null ? raw.correspondentId : null,
    documentTypeId: doc.documentType == null ? raw.documentTypeId : null,
    tagIds: tagIds,
    detectedDate: raw.detectedDate,
  );
}
