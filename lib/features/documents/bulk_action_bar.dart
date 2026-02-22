import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_providers.dart';
import '../../core/models/tag.dart';
import '../../core/models/correspondent.dart';
import '../../core/models/document_type.dart';
import '../../core/models/storage_path.dart';

/// Floating action bar shown during multi-select mode.
class BulkActionBar extends ConsumerWidget {
  final Set<int> selectedIds;
  final VoidCallback onClearSelection;
  final VoidCallback onRefresh;

  const BulkActionBar({
    super.key,
    required this.selectedIds,
    required this.onClearSelection,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Clear selection',
              onPressed: onClearSelection,
            ),
            Text(
              '${selectedIds.length} selected',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 8),
            _ActionButton(
              icon: Icons.label_outline,
              tooltip: 'Add tags',
              onPressed: () => _showBulkTagDialog(context, ref),
            ),
            _ActionButton(
              icon: Icons.person_outline,
              tooltip: 'Set correspondent',
              onPressed: () => _showBulkCorrespondentDialog(context, ref),
            ),
            _ActionButton(
              icon: Icons.category_outlined,
              tooltip: 'Set document type',
              onPressed: () => _showBulkDocTypeDialog(context, ref),
            ),
            _ActionButton(
              icon: Icons.folder_outlined,
              tooltip: 'Set storage path',
              onPressed: () => _showBulkStoragePathDialog(context, ref),
            ),
            if (selectedIds.length >= 2)
              _ActionButton(
                icon: Icons.merge,
                tooltip: 'Merge',
                onPressed: () => _showBulkMergeDialog(context, ref),
              ),
            _ActionButton(
              icon: Icons.rotate_right,
              tooltip: 'Rotate',
              onPressed: () => _showBulkRotateDialog(context, ref),
            ),
            _ActionButton(
              icon: Icons.delete_outline,
              tooltip: 'Delete',
              onPressed: () => _showBulkDeleteDialog(context, ref),
              color: colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBulkTagDialog(BuildContext context, WidgetRef ref) async {
    final tagsMap = ref.read(tagsProvider).valueOrNull ?? {};
    final allTags = tagsMap.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final selected = await showDialog<Set<int>>(
      context: context,
      builder: (ctx) => _BulkTagPicker(tags: allTags),
    );

    if (selected != null && selected.isNotEmpty && context.mounted) {
      try {
        final api = ref.read(paperlessApiProvider);
        await api.bulkEdit(
          documents: selectedIds.toList(),
          method: 'set_tags',
          parameters: {'tags': selected.toList(), 'mode': 'add'},
        );
        if (!context.mounted) return;
        onClearSelection();
        onRefresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tags added to ${selectedIds.length} documents')),
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add tags: $e')),
          );
        }
      }
    }
  }

  Future<void> _showBulkCorrespondentDialog(BuildContext context, WidgetRef ref) async {
    final corrsMap = ref.read(correspondentsProvider).valueOrNull ?? {};
    final allCorrs = corrsMap.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final selected = await showDialog<int?>(
      context: context,
      builder: (ctx) => _BulkSinglePicker<Correspondent>(
        title: 'Set Correspondent',
        items: allCorrs,
        displayName: (c) => c.name,
        getId: (c) => c.id,
      ),
    );

    if (selected != null && context.mounted) {
      try {
        final api = ref.read(paperlessApiProvider);
        await api.bulkEdit(
          documents: selectedIds.toList(),
          method: 'set_correspondent',
          parameters: {'correspondent': selected},
        );
        if (!context.mounted) return;
        onClearSelection();
        onRefresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Correspondent set on ${selectedIds.length} documents')),
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to set correspondent: $e')),
          );
        }
      }
    }
  }

  Future<void> _showBulkDocTypeDialog(BuildContext context, WidgetRef ref) async {
    final typesMap = ref.read(documentTypesProvider).valueOrNull ?? {};
    final allTypes = typesMap.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final selected = await showDialog<int?>(
      context: context,
      builder: (ctx) => _BulkSinglePicker<DocumentType>(
        title: 'Set Document Type',
        items: allTypes,
        displayName: (dt) => dt.name,
        getId: (dt) => dt.id,
      ),
    );

    if (selected != null && context.mounted) {
      try {
        final api = ref.read(paperlessApiProvider);
        await api.bulkEdit(
          documents: selectedIds.toList(),
          method: 'set_document_type',
          parameters: {'document_type': selected},
        );
        if (!context.mounted) return;
        onClearSelection();
        onRefresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Document type set on ${selectedIds.length} documents')),
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to set document type: $e')),
          );
        }
      }
    }
  }

  Future<void> _showBulkStoragePathDialog(BuildContext context, WidgetRef ref) async {
    final pathsMap = ref.read(storagePathsProvider).valueOrNull ?? {};
    final allPaths = pathsMap.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final selected = await showDialog<int?>(
      context: context,
      builder: (ctx) => _BulkSinglePicker<StoragePath>(
        title: 'Set Storage Path',
        items: allPaths,
        displayName: (sp) => sp.name,
        getId: (sp) => sp.id,
      ),
    );

    if (selected != null && context.mounted) {
      try {
        final api = ref.read(paperlessApiProvider);
        await api.bulkEdit(
          documents: selectedIds.toList(),
          method: 'set_storage_path',
          parameters: {'storage_path': selected},
        );
        if (!context.mounted) return;
        onClearSelection();
        onRefresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Storage path set on ${selectedIds.length} documents')),
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to set storage path: $e')),
          );
        }
      }
    }
  }

  Future<void> _showBulkMergeDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Merge documents?'),
        content: Text(
          'Merge ${selectedIds.length} documents into one? '
          'The first selected document will be the primary.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Merge'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final api = ref.read(paperlessApiProvider);
        final docIds = selectedIds.toList();
        await api.bulkEdit(
          documents: docIds,
          method: 'merge',
          parameters: {'metadata_document_id': docIds.first},
        );
        if (!context.mounted) return;
        onClearSelection();
        onRefresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${selectedIds.length} documents merged')),
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to merge: $e')),
          );
        }
      }
    }
  }

  Future<void> _showBulkRotateDialog(BuildContext context, WidgetRef ref) async {
    final degrees = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Rotate documents'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 90),
            child: const Text('90 degrees clockwise'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 180),
            child: const Text('180 degrees'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 270),
            child: const Text('270 degrees clockwise'),
          ),
        ],
      ),
    );

    if (degrees != null && context.mounted) {
      try {
        final api = ref.read(paperlessApiProvider);
        await api.bulkEdit(
          documents: selectedIds.toList(),
          method: 'rotate',
          parameters: {'degrees': degrees},
        );
        if (!context.mounted) return;
        onClearSelection();
        onRefresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${selectedIds.length} documents rotated')),
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to rotate: $e')),
          );
        }
      }
    }
  }

  Future<void> _showBulkDeleteDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Move to trash?'),
        content: Text(
          'Move ${selectedIds.length} documents to trash?',
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
            child: const Text('Move to trash'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final api = ref.read(paperlessApiProvider);
        await api.trashDocuments(selectedIds.toList());
        if (!context.mounted) return;
        onClearSelection();
        onRefresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${selectedIds.length} documents moved to trash')),
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: color),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
}

class _BulkTagPicker extends StatefulWidget {
  final List<Tag> tags;
  const _BulkTagPicker({required this.tags});

  @override
  State<_BulkTagPicker> createState() => _BulkTagPickerState();
}

class _BulkTagPickerState extends State<_BulkTagPicker> {
  final _selected = <int>{};
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.tags
        .where((t) => t.name.toLowerCase().contains(_filter.toLowerCase()))
        .toList();

    return AlertDialog(
      title: const Text('Add Tags'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search tags...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _filter = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final tag = filtered[i];
                  final isSelected = _selected.contains(tag.id);
                  return CheckboxListTile(
                    value: isSelected,
                    title: Text(tag.name),
                    dense: true,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selected.add(tag.id);
                        } else {
                          _selected.remove(tag.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selected.isEmpty ? null : () => Navigator.pop(context, _selected),
          child: Text('Add (${_selected.length})'),
        ),
      ],
    );
  }
}

class _BulkSinglePicker<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T) displayName;
  final int Function(T) getId;

  const _BulkSinglePicker({
    required this.title,
    required this.items,
    required this.displayName,
    required this.getId,
  });

  @override
  State<_BulkSinglePicker<T>> createState() => _BulkSinglePickerState<T>();
}

class _BulkSinglePickerState<T> extends State<_BulkSinglePicker<T>> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items
        .where((item) => widget.displayName(item).toLowerCase().contains(_filter.toLowerCase()))
        .toList();

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _filter = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final item = filtered[i];
                  return ListTile(
                    title: Text(widget.displayName(item)),
                    dense: true,
                    onTap: () => Navigator.pop(context, widget.getId(item)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
