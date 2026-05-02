import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/design_tokens.dart';
import '../../core/models/correspondent.dart';
import '../../core/models/document_type.dart';
import '../../core/models/tag.dart';
import 'documents_notifier.dart';

class ActiveFiltersBar extends StatelessWidget {
  final DocumentsFilter filter;
  final Map<int, Tag> tags;
  final Map<int, Correspondent> correspondents;
  final Map<int, DocumentType> docTypes;
  final VoidCallback onClear;
  final VoidCallback onSave;

  const ActiveFiltersBar({
    super.key,
    required this.filter,
    required this.tags,
    required this.correspondents,
    required this.docTypes,
    required this.onClear,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (filter.correspondentId != null) {
      final name =
          correspondents[filter.correspondentId]?.name ?? '?';
      chips.add(Chip(
        label: Text('Corr: $name',
            style: Theme.of(context).textTheme.bodySmall),
        visualDensity: VisualDensity.compact,
      ));
    }
    if (filter.documentTypeId != null) {
      final name =
          docTypes[filter.documentTypeId]?.name ?? '?';
      chips.add(Chip(
        label: Text('Type: $name',
            style: Theme.of(context).textTheme.bodySmall),
        visualDensity: VisualDensity.compact,
      ));
    }
    if (filter.tagIds != null) {
      for (final tagId in filter.tagIds!) {
        final name = tags[tagId]?.name ?? '?';
        chips.add(Chip(
          label:
              Text(name, style: Theme.of(context).textTheme.bodySmall),
          visualDensity: VisualDensity.compact,
        ));
      }
    }
    if (filter.createdDateFrom != null ||
        filter.createdDateTo != null) {
      final from = filter.createdDateFrom != null
          ? DateFormat.yMd().format(filter.createdDateFrom!)
          : '...';
      final to = filter.createdDateTo != null
          ? DateFormat.yMd().format(filter.createdDateTo!)
          : '...';
      chips.add(Chip(
        label: Text('Date: $from – $to',
            style: Theme.of(context).textTheme.bodySmall),
        visualDensity: VisualDensity.compact,
      ));
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.xs),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: chips
                    .map((c) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: c,
                        ))
                    .toList(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: 'Save as view',
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
