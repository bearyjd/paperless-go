import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_providers.dart';
import '../../core/models/correspondent.dart';
import '../../core/models/document_type.dart';
import '../../core/models/storage_path.dart';
import '../../core/models/tag.dart';
import '../../shared/widgets/tag_chip.dart';
import 'labels_notifier.dart';

class LabelsScreen extends ConsumerWidget {
  const LabelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Labels'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Tags'),
              Tab(text: 'Correspondents'),
              Tab(text: 'Doc Types'),
              Tab(text: 'Paths'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _TagsTab(),
            _CorrespondentsTab(),
            _DocumentTypesTab(),
            _StoragePathsTab(),
          ],
        ),
      ),
    );
  }
}

class _TagsTab extends ConsumerWidget {
  const _TagsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(tagsProvider);

    return tagsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (tags) {
        final sorted = tags.values.toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        return Scaffold(
          body: sorted.isEmpty
              ? const Center(child: Text('No tags'))
              : ListView.builder(
                  itemCount: sorted.length,
                  itemBuilder: (_, i) {
                    final tag = sorted[i];
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: TagChip.parseColor(tag.colour) ??
                            Theme.of(context).colorScheme.secondaryContainer,
                      ),
                      title: Text(tag.name),
                      subtitle: Text('${tag.documentCount} documents'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => _editTag(context, ref, tag),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, size: 20,
                                color: Theme.of(context).colorScheme.error),
                            onPressed: () => _deleteTag(context, ref, tag),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _createTag(context, ref),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _createTag(BuildContext context, WidgetRef ref) {
    _showTagDialog(context, ref, null);
  }

  void _editTag(BuildContext context, WidgetRef ref, Tag tag) {
    _showTagDialog(context, ref, tag);
  }

  void _showTagDialog(BuildContext context, WidgetRef ref, Tag? existing) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final colourController = TextEditingController(text: existing?.colour ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Create Tag' : 'Edit Tag'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: colourController,
              decoration: const InputDecoration(
                labelText: 'Color (hex, e.g. #ff0000)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final data = <String, dynamic>{'name': name};
              final colour = colourController.text.trim();
              if (colour.isNotEmpty) data['color'] = colour;

              final notifier = ref.read(labelsNotifierProvider.notifier);
              final success = existing != null
                  ? await notifier.updateTag(existing.id, data)
                  : await notifier.createTag(data);
              if (ctx.mounted) Navigator.pop(ctx);
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed: ${notifier.lastError}')),
                );
              }
            },
            child: Text(existing == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _deleteTag(BuildContext context, WidgetRef ref, Tag tag) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Tag?'),
        content: Text('Delete "${tag.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final notifier = ref.read(labelsNotifierProvider.notifier);
              Navigator.pop(ctx);
              final success = await notifier.deleteTag(tag.id);
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Delete failed: ${notifier.lastError}')),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _CorrespondentsTab extends ConsumerWidget {
  const _CorrespondentsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final corrsAsync = ref.watch(correspondentsProvider);

    return corrsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (correspondents) {
        final sorted = correspondents.values.toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        return Scaffold(
          body: sorted.isEmpty
              ? const Center(child: Text('No correspondents'))
              : ListView.builder(
                  itemCount: sorted.length,
                  itemBuilder: (_, i) {
                    final corr = sorted[i];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(corr.name.isNotEmpty
                            ? corr.name[0].toUpperCase()
                            : '?'),
                      ),
                      title: Text(corr.name),
                      subtitle: Text('${corr.documentCount} documents'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () =>
                                _editCorrespondent(context, ref, corr),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, size: 20,
                                color: Theme.of(context).colorScheme.error),
                            onPressed: () =>
                                _deleteCorrespondent(context, ref, corr),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _createCorrespondent(context, ref),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _createCorrespondent(BuildContext context, WidgetRef ref) {
    _showCorrespondentDialog(context, ref, null);
  }

  void _editCorrespondent(
      BuildContext context, WidgetRef ref, Correspondent corr) {
    _showCorrespondentDialog(context, ref, corr);
  }

  void _showCorrespondentDialog(
      BuildContext context, WidgetRef ref, Correspondent? existing) {
    final nameController = TextEditingController(text: existing?.name ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            Text(existing == null ? 'Create Correspondent' : 'Edit Correspondent'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final notifier = ref.read(labelsNotifierProvider.notifier);
              final success = existing != null
                  ? await notifier.updateCorrespondent(existing.id, {'name': name})
                  : await notifier.createCorrespondent({'name': name});
              if (ctx.mounted) Navigator.pop(ctx);
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed: ${notifier.lastError}')),
                );
              }
            },
            child: Text(existing == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _deleteCorrespondent(
      BuildContext context, WidgetRef ref, Correspondent corr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Correspondent?'),
        content: Text('Delete "${corr.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final notifier = ref.read(labelsNotifierProvider.notifier);
              Navigator.pop(ctx);
              final success = await notifier.deleteCorrespondent(corr.id);
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Delete failed: ${notifier.lastError}')),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _DocumentTypesTab extends ConsumerWidget {
  const _DocumentTypesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typesAsync = ref.watch(documentTypesProvider);

    return typesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (docTypes) {
        final sorted = docTypes.values.toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        return Scaffold(
          body: sorted.isEmpty
              ? const Center(child: Text('No document types'))
              : ListView.builder(
                  itemCount: sorted.length,
                  itemBuilder: (_, i) {
                    final dt = sorted[i];
                    return ListTile(
                      leading: const CircleAvatar(
                          child: Icon(Icons.description_outlined)),
                      title: Text(dt.name),
                      subtitle: Text('${dt.documentCount} documents'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () =>
                                _editDocType(context, ref, dt),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, size: 20,
                                color: Theme.of(context).colorScheme.error),
                            onPressed: () =>
                                _deleteDocType(context, ref, dt),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _createDocType(context, ref),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _createDocType(BuildContext context, WidgetRef ref) {
    _showDocTypeDialog(context, ref, null);
  }

  void _editDocType(BuildContext context, WidgetRef ref, DocumentType dt) {
    _showDocTypeDialog(context, ref, dt);
  }

  void _showDocTypeDialog(
      BuildContext context, WidgetRef ref, DocumentType? existing) {
    final nameController = TextEditingController(text: existing?.name ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            Text(existing == null ? 'Create Document Type' : 'Edit Document Type'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final notifier = ref.read(labelsNotifierProvider.notifier);
              final success = existing != null
                  ? await notifier.updateDocumentType(existing.id, {'name': name})
                  : await notifier.createDocumentType({'name': name});
              if (ctx.mounted) Navigator.pop(ctx);
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed: ${notifier.lastError}')),
                );
              }
            },
            child: Text(existing == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _deleteDocType(BuildContext context, WidgetRef ref, DocumentType dt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document Type?'),
        content: Text('Delete "${dt.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final notifier = ref.read(labelsNotifierProvider.notifier);
              Navigator.pop(ctx);
              final success = await notifier.deleteDocumentType(dt.id);
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Delete failed: ${notifier.lastError}')),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _StoragePathsTab extends ConsumerWidget {
  const _StoragePathsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pathsAsync = ref.watch(storagePathsProvider);

    return pathsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (storagePaths) {
        final sorted = storagePaths.values.toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        return Scaffold(
          body: sorted.isEmpty
              ? const Center(child: Text('No storage paths'))
              : ListView.builder(
                  itemCount: sorted.length,
                  itemBuilder: (_, i) {
                    final sp = sorted[i];
                    return ListTile(
                      leading: const CircleAvatar(
                          child: Icon(Icons.folder_outlined)),
                      title: Text(sp.name),
                      subtitle: Text('${sp.documentCount} documents — ${sp.path}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () =>
                                _editStoragePath(context, ref, sp),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, size: 20,
                                color: Theme.of(context).colorScheme.error),
                            onPressed: () =>
                                _deleteStoragePath(context, ref, sp),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _createStoragePath(context, ref),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _createStoragePath(BuildContext context, WidgetRef ref) {
    _showStoragePathDialog(context, ref, null);
  }

  void _editStoragePath(
      BuildContext context, WidgetRef ref, StoragePath sp) {
    _showStoragePathDialog(context, ref, sp);
  }

  void _showStoragePathDialog(
      BuildContext context, WidgetRef ref, StoragePath? existing) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final pathController = TextEditingController(text: existing?.path ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            Text(existing == null ? 'Create Storage Path' : 'Edit Storage Path'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pathController,
              decoration: const InputDecoration(
                labelText: 'Path',
                hintText: 'e.g. archive/{correspondent}/{title}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final path = pathController.text.trim();
              if (name.isEmpty) return;
              final data = <String, dynamic>{
                'name': name,
                if (path.isNotEmpty) 'path': path,
              };
              final notifier = ref.read(labelsNotifierProvider.notifier);
              final success = existing != null
                  ? await notifier.updateStoragePath(existing.id, data)
                  : await notifier.createStoragePath(data);
              if (ctx.mounted) Navigator.pop(ctx);
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed: ${notifier.lastError}')),
                );
              }
            },
            child: Text(existing == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _deleteStoragePath(
      BuildContext context, WidgetRef ref, StoragePath sp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Storage Path?'),
        content: Text('Delete "${sp.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final notifier = ref.read(labelsNotifierProvider.notifier);
              Navigator.pop(ctx);
              final success = await notifier.deleteStoragePath(sp.id);
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Delete failed: ${notifier.lastError}')),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
