import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/api/api_providers.dart';
import '../../core/models/document.dart';
import '../../core/models/saved_view.dart';
import '../../shared/widgets/document_card.dart';
import '../../shared/widgets/loading_skeleton.dart';
import 'bulk_action_bar.dart';
import 'document_detail_notifier.dart';
import 'documents_notifier.dart';
import 'filter_bottom_sheet.dart';
import 'saved_view_helpers.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  String _ordering = '-created';
  final _selectedIds = <int>{};
  bool get _isSelecting => _selectedIds.isNotEmpty;
  int? _activeSavedViewId;

  static const _sortOptions = {
    '-created': 'Newest first',
    'created': 'Oldest first',
    '-added': 'Recently added',
    'title': 'Title A-Z',
    '-title': 'Title Z-A',
    'archive_serial_number': 'ASN',
  };

  void _toggleSelection(int docId) {
    setState(() {
      if (_selectedIds.contains(docId)) {
        _selectedIds.remove(docId);
      } else {
        _selectedIds.add(docId);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedIds.clear());
  }

  Future<void> _shareDocument(BuildContext context, WidgetRef ref, int docId, String title) async {
    try {
      final path = await ref.read(documentDownloadProvider(docId, title).future);
      await Share.shareXFiles([XFile(path)]);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    }
  }

  Future<void> _showDocumentContextMenu(
    BuildContext context,
    WidgetRef ref,
    Document doc,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share'),
              onTap: () => Navigator.pop(context, 'share'),
            ),
            ListTile(
              leading: const Icon(Icons.check_box_outline_blank),
              title: const Text('Select'),
              onTap: () => Navigator.pop(context, 'select'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (action == 'share') {
      await _shareDocument(context, ref, doc.id, doc.title);
    } else if (action == 'select') {
      _toggleSelection(doc.id);
    }
  }

  void _applySavedView(SavedView view) {
    final ordering = view.sortReverse
        ? '-${view.sortField}'
        : view.sortField;

    setState(() {
      _activeSavedViewId = view.id;
      _ordering = ordering;
    });

    ref.read(documentsNotifierProvider.notifier).applyFilter(
          filterRulesToDocumentsFilter(view.filterRules, ordering),
        );
  }

  @override
  Widget build(BuildContext context) {
    final docsState = ref.watch(documentsNotifierProvider);
    final tagsAsync = ref.watch(tagsProvider);
    final correspondentsAsync = ref.watch(correspondentsProvider);
    final docTypesAsync = ref.watch(documentTypesProvider);
    final savedViewsAsync = ref.watch(savedViewsProvider);

    // Show loadMore errors as SnackBar
    ref.listen(documentsNotifierProvider, (prev, next) {
      final error = next.valueOrNull?.loadMoreError;
      if (error != null && error != prev?.valueOrNull?.loadMoreError) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
      }
    });

    final currentFilter = docsState.valueOrNull?.filter ?? const DocumentsFilter();
    final hasActiveFilters = currentFilter.correspondentId != null ||
        currentFilter.documentTypeId != null ||
        (currentFilter.tagIds != null && currentFilter.tagIds!.isNotEmpty) ||
        currentFilter.createdDateFrom != null ||
        currentFilter.createdDateTo != null;

    return Scaffold(
      appBar: _isSelecting
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
              ),
              title: Text('${_selectedIds.length} selected'),
            )
          : AppBar(
              title: const Text('Documents'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Search',
                  onPressed: () => context.push('/search'),
                ),
                IconButton(
                  icon: Badge(
                    isLabelVisible: hasActiveFilters,
                    child: const Icon(Icons.filter_list),
                  ),
                  tooltip: 'Filter',
                  onPressed: () => _showFilterSheet(context, currentFilter),
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: 'Settings',
                  onPressed: () => context.push('/settings'),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort),
                  tooltip: 'Sort',
                  onSelected: (ordering) {
                    setState(() => _ordering = ordering);
                    ref.read(documentsNotifierProvider.notifier)
                        .applyFilter(currentFilter.copyWith(ordering: ordering));
                  },
                  itemBuilder: (_) => _sortOptions.entries.map((e) {
                    return PopupMenuItem(
                      value: e.key,
                      child: Row(
                        children: [
                          if (e.key == _ordering)
                            const Icon(Icons.check, size: 18)
                          else
                            const SizedBox(width: 18),
                          const SizedBox(width: 8),
                          Text(e.value),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
      body: Stack(
        children: [
          docsState.when(
            loading: () => const DocumentListSkeleton(),
            error: (err, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, size: 48, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text('Failed to load documents', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(err.toString(), style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: () => ref.read(documentsNotifierProvider.notifier).refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (docsData) {
              final tags = tagsAsync.valueOrNull ?? {};
              final correspondents = correspondentsAsync.valueOrNull ?? {};
              final docTypes = docTypesAsync.valueOrNull ?? {};

              if (docsData.documents.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.description_outlined, size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text('No documents found',
                          style: Theme.of(context).textTheme.titleMedium),
                      if (hasActiveFilters) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            ref.read(documentsNotifierProvider.notifier)
                                .applyFilter(const DocumentsFilter());
                          },
                          child: const Text('Clear filters'),
                        ),
                      ],
                    ],
                  ),
                );
              }

              final api = ref.watch(paperlessApiProvider);

              return RefreshIndicator(
                onRefresh: () => ref.read(documentsNotifierProvider.notifier).refresh(),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollEndNotification &&
                        notification.metrics.pixels >=
                            notification.metrics.maxScrollExtent - 200) {
                      ref.read(documentsNotifierProvider.notifier).loadMore();
                    }
                    return false;
                  },
                  child: CustomScrollView(
                    slivers: [
                      // Saved views bar
                      if (savedViewsAsync.valueOrNull?.isNotEmpty == true)
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 48,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              children: [
                                for (final view in savedViewsAsync.valueOrNull!)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: FilterChip(
                                      label: Text(view.name),
                                      selected: _activeSavedViewId == view.id,
                                      onSelected: (_) {
                                        if (_activeSavedViewId == view.id) {
                                          setState(() => _activeSavedViewId = null);
                                          ref.read(documentsNotifierProvider.notifier)
                                              .applyFilter(DocumentsFilter(ordering: _ordering));
                                        } else {
                                          _applySavedView(view);
                                        }
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      // Active filters bar
                      if (hasActiveFilters)
                        SliverToBoxAdapter(
                          child: _ActiveFiltersBar(
                            filter: currentFilter,
                            tags: tags,
                            correspondents: correspondents,
                            docTypes: docTypes,
                            onClear: () {
                              ref.read(documentsNotifierProvider.notifier)
                                  .applyFilter(DocumentsFilter(ordering: _ordering));
                            },
                            onSave: () => _showSaveViewDialog(context, currentFilter),
                          ),
                        ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Text(
                            '${docsData.totalCount} documents',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      SliverList.builder(
                        itemCount: docsData.documents.length + (docsData.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= docsData.documents.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final doc = docsData.documents[index];
                          final isSelected = _selectedIds.contains(doc.id);
                          return Stack(
                            key: ValueKey(doc.id),
                            children: [
                              DocumentCard(
                                document: doc,
                                tags: tags,
                                correspondents: correspondents,
                                documentTypes: docTypes,
                                thumbnailUrl: api.thumbnailUrl(doc.id),
                                authToken: api.authToken,
                                onTap: _isSelecting
                                    ? () => _toggleSelection(doc.id)
                                    : () => context.push('/documents/${doc.id}'),
                                onLongPress: _isSelecting
                                    ? () => _toggleSelection(doc.id)
                                    : () => _showDocumentContextMenu(context, ref, doc),
                              ),
                              if (isSelected)
                                Positioned.fill(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.primary,
                                        width: 2,
                                      ),
                                    ),
                                    child: Align(
                                      alignment: Alignment.topRight,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Icon(
                                          Icons.check_circle,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Floating bulk action bar
          if (_isSelecting)
            Positioned(
              bottom: 80,
              left: 16,
              right: 16,
              child: Center(
                child: BulkActionBar(
                  selectedIds: _selectedIds,
                  onClearSelection: _clearSelection,
                  onRefresh: () =>
                      ref.read(documentsNotifierProvider.notifier).refresh(),
                  onShare: () => _shareSelected(context, ref),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<bool?> _confirmBulkShare(BuildContext context, int count) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Share documents?'),
        content: Text(
          'Sharing $count documents requires downloading them all. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareSelected(BuildContext context, WidgetRef ref) async {
    final docs = ref.read(documentsNotifierProvider).valueOrNull?.documents ?? [];
    final selectedDocs = docs.where((d) => _selectedIds.contains(d.id)).toList();
    if (selectedDocs.isEmpty) return;

    if (selectedDocs.length > 5) {
      final confirmed = await _confirmBulkShare(context, selectedDocs.length);
      if (confirmed != true || !context.mounted) return;
    }

    final paths = <String>[];
    final failures = <String>[];

    for (final doc in selectedDocs) {
      try {
        final path = await ref.read(
          documentDownloadProvider(doc.id, doc.title).future,
        );
        paths.add(path);
      } catch (_) {
        failures.add(doc.title);
      }
    }

    if (paths.isNotEmpty && context.mounted) {
      await Share.shareXFiles(paths.map((p) => XFile(p)).toList());
      if (context.mounted) _clearSelection();
    }

    if (failures.isNotEmpty && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download: ${failures.join(', ')}'),
        ),
      );
    }
  }

  Future<void> _showSaveViewDialog(
      BuildContext context, DocumentsFilter currentFilter) async {
    final nameController = TextEditingController();
    try {
      bool showOnDashboard = false;
      bool showInSidebar = true;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Save as view'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'View name',
                    hintText: 'e.g. Invoices 2024',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show in sidebar'),
                  value: showInSidebar,
                  onChanged: (v) => setDialogState(() => showInSidebar = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show on dashboard'),
                  value: showOnDashboard,
                  onChanged: (v) => setDialogState(() => showOnDashboard = v),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) return;
                  Navigator.pop(ctx, true);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      );

      if (confirmed != true || !context.mounted) return;

      final name = nameController.text.trim();
      final rules = documentsFilterToFilterRules(currentFilter);
      final (sortField, sortReverse) = parseOrdering(currentFilter.ordering);

      try {
        await ref.read(paperlessApiProvider).createSavedView(
              name: name,
              filterRules: rules,
              sortField: sortField,
              sortReverse: sortReverse,
              showOnDashboard: showOnDashboard,
              showInSidebar: showInSidebar,
            );
        ref.invalidate(savedViewsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"$name" saved')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save view: $e')),
          );
        }
      }
    } finally {
      nameController.dispose();
    }
  }

  void _showFilterSheet(BuildContext context, DocumentsFilter currentFilter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => FilterBottomSheet(
        currentFilter: currentFilter,
        onApply: (filter) {
          ref.read(documentsNotifierProvider.notifier).applyFilter(filter);
        },
      ),
    );
  }
}

class _ActiveFiltersBar extends StatelessWidget {
  final DocumentsFilter filter;
  final Map<int, dynamic> tags;
  final Map<int, dynamic> correspondents;
  final Map<int, dynamic> docTypes;
  final VoidCallback onClear;
  final VoidCallback onSave;

  const _ActiveFiltersBar({
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
      final name = (correspondents[filter.correspondentId] as dynamic)?.name ?? '?';
      chips.add(Chip(
        label: Text('Corr: $name', style: const TextStyle(fontSize: 12)),
        visualDensity: VisualDensity.compact,
      ));
    }
    if (filter.documentTypeId != null) {
      final name = (docTypes[filter.documentTypeId] as dynamic)?.name ?? '?';
      chips.add(Chip(
        label: Text('Type: $name', style: const TextStyle(fontSize: 12)),
        visualDensity: VisualDensity.compact,
      ));
    }
    if (filter.tagIds != null) {
      for (final tagId in filter.tagIds!) {
        final name = (tags[tagId] as dynamic)?.name ?? '?';
        chips.add(Chip(
          label: Text(name, style: const TextStyle(fontSize: 12)),
          visualDensity: VisualDensity.compact,
        ));
      }
    }
    if (filter.createdDateFrom != null || filter.createdDateTo != null) {
      final from = filter.createdDateFrom != null
          ? DateFormat.yMd().format(filter.createdDateFrom!)
          : '...';
      final to = filter.createdDateTo != null
          ? DateFormat.yMd().format(filter.createdDateTo!)
          : '...';
      chips.add(Chip(
        label: Text('Date: $from – $to', style: const TextStyle(fontSize: 12)),
        visualDensity: VisualDensity.compact,
      ));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: chips.map((c) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: c,
                )).toList(),
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
