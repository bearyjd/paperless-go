import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'trash_notifier.dart';

class TrashScreen extends ConsumerStatefulWidget {
  const TrashScreen({super.key});

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen> {
  final _selectedIds = <int>{};
  bool get _isSelecting => _selectedIds.isNotEmpty;

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _clearSelection() => setState(() => _selectedIds.clear());

  @override
  Widget build(BuildContext context) {
    final trashState = ref.watch(trashNotifierProvider);

    return Scaffold(
      appBar: _isSelecting
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
              ),
              title: Text('${_selectedIds.length} selected'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.restore),
                  tooltip: 'Restore selected',
                  onPressed: () => _restoreSelected(context),
                ),
                IconButton(
                  icon: Icon(Icons.delete_forever,
                      color: Theme.of(context).colorScheme.error),
                  tooltip: 'Delete permanently',
                  onPressed: () => _deleteSelected(context),
                ),
              ],
            )
          : AppBar(title: const Text('Trash')),
      body: trashState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48,
                  color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text('Failed to load trash',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(trashNotifierProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (data) {
          if (data.documents.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_outline, size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('Trash is empty',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Deleted documents will appear here',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          )),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(trashNotifierProvider.notifier).refresh(),
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollEndNotification &&
                    notification.metrics.pixels >=
                        notification.metrics.maxScrollExtent - 200) {
                  ref.read(trashNotifierProvider.notifier).loadMore();
                }
                return false;
              },
              child: ListView.builder(
                itemCount: data.documents.length + (data.isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= data.documents.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final doc = data.documents[index];
                  final isSelected = _selectedIds.contains(doc.id);

                  return ListTile(
                    leading: isSelected
                        ? Icon(Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary)
                        : const Icon(Icons.description_outlined),
                    title: Text(doc.title,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      doc.modified != null
                          ? 'Deleted ${DateFormat.yMMMd().format(doc.modified!)}'
                          : 'Deleted ${DateFormat.yMMMd().format(doc.created)}',
                    ),
                    selected: isSelected,
                    onTap: () => _toggleSelection(doc.id),
                    trailing: !_isSelecting
                        ? PopupMenuButton<String>(
                            onSelected: (action) {
                              if (action == 'restore') {
                                _restore(context, [doc.id]);
                              } else if (action == 'delete') {
                                _confirmPermanentDelete(context, [doc.id]);
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'restore',
                                child: ListTile(
                                  leading: Icon(Icons.restore),
                                  title: Text('Restore'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(Icons.delete_forever,
                                      color: Theme.of(context).colorScheme.error),
                                  title: Text('Delete permanently',
                                      style: TextStyle(
                                          color: Theme.of(context).colorScheme.error)),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          )
                        : null,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _restoreSelected(BuildContext context) async {
    await _restore(context, _selectedIds.toList());
    if (mounted) _clearSelection();
  }

  Future<void> _deleteSelected(BuildContext context) async {
    await _confirmPermanentDelete(context, _selectedIds.toList());
  }

  Future<void> _restore(BuildContext context, List<int> ids) async {
    final success = await ref.read(trashNotifierProvider.notifier).restoreDocuments(ids);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? '${ids.length} document(s) restored'
              : 'Failed to restore documents'),
        ),
      );
    }
  }

  Future<void> _confirmPermanentDelete(BuildContext context, List<int> ids) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete permanently?'),
        content: Text(
          'Permanently delete ${ids.length} document(s)? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(trashNotifierProvider.notifier).permanentlyDelete(ids);
      if (!context.mounted) return;
      _clearSelection();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? '${ids.length} document(s) permanently deleted'
                : 'Failed to delete documents'),
          ),
        );
      }
    }
  }
}
