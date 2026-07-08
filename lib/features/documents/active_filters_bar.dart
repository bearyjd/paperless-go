import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/design_tokens.dart';
import '../../core/models/correspondent.dart';
import '../../core/models/document_type.dart';
import '../../core/models/tag.dart';
import '../../shared/widgets/stamp_chip.dart';
import 'documents_notifier.dart';

/// The active-filter strip: one dismissible stamp pill per applied filter,
/// shown only when at least one filter is set. Dismissing a pill emits a
/// reduced [DocumentsFilter] via [onChanged]; trailing actions save the current
/// filter as a view or clear everything.
class ActiveFiltersBar extends StatelessWidget {
  final DocumentsFilter filter;
  final Map<int, Tag> tags;
  final Map<int, Correspondent> correspondents;
  final Map<int, DocumentType> docTypes;
  final ValueChanged<DocumentsFilter> onChanged;
  final VoidCallback onClear;
  final VoidCallback onSave;

  const ActiveFiltersBar({
    super.key,
    required this.filter,
    required this.tags,
    required this.correspondents,
    required this.docTypes,
    required this.onChanged,
    required this.onClear,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final pills = <Widget>[];

    if (filter.correspondentId != null) {
      final name = correspondents[filter.correspondentId]?.name ?? '?';
      pills.add(StampChip(
        label: name,
        icon: Icons.person_outline,
        rotated: false,
        onDeleted: () => onChanged(filter.copyWith(clearCorrespondent: true)),
      ));
    }
    if (filter.documentTypeId != null) {
      final name = docTypes[filter.documentTypeId]?.name ?? '?';
      pills.add(StampChip(
        label: name,
        icon: Icons.category_outlined,
        rotated: false,
        onDeleted: () => onChanged(filter.copyWith(clearDocumentType: true)),
      ));
    }
    if (filter.tagIds != null) {
      for (final tagId in filter.tagIds!) {
        final name = tags[tagId]?.name ?? '?';
        final remaining = filter.tagIds!.where((id) => id != tagId).toList();
        pills.add(StampChip(
          label: name,
          icon: Icons.sell_outlined,
          rotated: false,
          onDeleted: () => onChanged(filter.copyWith(
            tagIds: remaining.isEmpty ? null : remaining,
            clearTags: remaining.isEmpty,
          )),
        ));
      }
    }
    if (filter.createdDateFrom != null || filter.createdDateTo != null) {
      final from = filter.createdDateFrom != null
          ? DateFormat.yMd().format(filter.createdDateFrom!)
          : '…';
      final to = filter.createdDateTo != null
          ? DateFormat.yMd().format(filter.createdDateTo!)
          : '…';
      pills.add(StampChip(
        label: '$from – $to',
        icon: Icons.event_outlined,
        rotated: false,
        onDeleted: () => onChanged(filter.copyWith(clearDateRange: true)),
      ));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Spacing.xl, 0, Spacing.md, Spacing.sm),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final pill in pills)
                    Padding(
                      padding: const EdgeInsets.only(right: Spacing.sm),
                      child: pill,
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: 'Save as view',
            color: tokens.accentEmphasis,
            onPressed: onSave,
          ),
          TextButton(
            onPressed: onClear,
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
