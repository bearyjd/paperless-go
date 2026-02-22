import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_providers.dart';
import '../../shared/widgets/tag_chip.dart';
import 'documents_notifier.dart';

class FilterBottomSheet extends ConsumerStatefulWidget {
  final DocumentsFilter currentFilter;
  final ValueChanged<DocumentsFilter> onApply;

  const FilterBottomSheet({
    super.key,
    required this.currentFilter,
    required this.onApply,
  });

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  late int? _correspondentId;
  late int? _documentTypeId;
  late List<int> _tagIds;

  @override
  void initState() {
    super.initState();
    _correspondentId = widget.currentFilter.correspondentId;
    _documentTypeId = widget.currentFilter.documentTypeId;
    _tagIds = List.from(widget.currentFilter.tagIds ?? []);
  }

  bool get _hasFilters =>
      _correspondentId != null ||
      _documentTypeId != null ||
      _tagIds.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final correspondentsAsync = ref.watch(correspondentsProvider);
    final docTypesAsync = ref.watch(documentTypesProvider);
    final tagsAsync = ref.watch(tagsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text('Filters', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                if (_hasFilters)
                  TextButton(
                    onPressed: () => setState(() {
                      _correspondentId = null;
                      _documentTypeId = null;
                      _tagIds.clear();
                    }),
                    child: const Text('Clear all'),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Filter content
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                // Correspondent
                Text('Correspondent', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                correspondentsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Failed to load'),
                  data: (correspondents) => Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: correspondents.values.map((c) {
                      final selected = _correspondentId == c.id;
                      return FilterChip(
                        label: Text(c.name),
                        selected: selected,
                        onSelected: (v) => setState(() {
                          _correspondentId = v ? c.id : null;
                        }),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 20),

                // Document Type
                Text('Document Type', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                docTypesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Failed to load'),
                  data: (docTypes) => Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: docTypes.values.map((dt) {
                      final selected = _documentTypeId == dt.id;
                      return FilterChip(
                        label: Text(dt.name),
                        selected: selected,
                        onSelected: (v) => setState(() {
                          _documentTypeId = v ? dt.id : null;
                        }),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 20),

                // Tags
                Text('Tags', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                tagsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Failed to load'),
                  data: (tags) => Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: tags.values.map((tag) {
                      final selected = _tagIds.contains(tag.id);
                      return FilterChip(
                        label: Text(tag.name),
                        selected: selected,
                        backgroundColor: TagChip.parseColor(tag.colour),
                        selectedColor: TagChip.parseColor(tag.colour)?.withValues(alpha: 0.8),
                        labelStyle: TextStyle(
                          color: selected
                              ? TagChip.parseColor(tag.textColor)
                              : null,
                          fontSize: 13,
                        ),
                        checkmarkColor: TagChip.parseColor(tag.textColor),
                        onSelected: (v) => setState(() {
                          if (v) {
                            _tagIds.add(tag.id);
                          } else {
                            _tagIds.remove(tag.id);
                          }
                        }),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // Apply button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  widget.onApply(widget.currentFilter.copyWith(
                    correspondentId: _correspondentId,
                    documentTypeId: _documentTypeId,
                    tagIds: _tagIds.isEmpty ? null : _tagIds,
                    clearCorrespondent: _correspondentId == null,
                    clearDocumentType: _documentTypeId == null,
                    clearTags: _tagIds.isEmpty,
                  ));
                  Navigator.pop(context);
                },
                child: const Text('Apply Filters'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
