import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/document_template.dart';
import '../../core/services/template_service.dart';
import '../../shared/widgets/empty_state.dart';

class TemplatesScreen extends ConsumerWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(templatesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Upload Templates')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(templatesProvider),
        child: templatesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 16),
                Text('Failed to load\n$err', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () => ref.invalidate(templatesProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (templates) {
            final sorted = [...templates]
              ..sort((a, b) => a.name.compareTo(b.name));

            if (sorted.isEmpty) {
              return const EmptyState(
                icon: Icons.bookmark_outline,
                title: 'No templates yet',
                description: 'Tap + to create one, or use "Save as template" on the upload screen',
              );
            }

            return ListView.builder(
              itemCount: sorted.length,
              itemBuilder: (_, i) {
                final template = sorted[i];
                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.bookmark_outline, size: 20),
                  ),
                  title: Text(template.name),
                  subtitle: _buildSubtitle(template),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () => _showDeleteDialog(context, ref, template),
                  ),
                  onTap: () => _showRenameDialog(context, ref, template),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget? _buildSubtitle(DocumentTemplate template) {
    final parts = <String>[];
    if (template.correspondentId != null) parts.add('Correspondent set');
    if (template.documentTypeId != null) parts.add('Doc type set');
    if (template.tagIds.isNotEmpty) {
      parts.add('${template.tagIds.length} tag${template.tagIds.length == 1 ? '' : 's'}');
    }
    if (template.storagePathId != null) parts.add('Storage path set');
    if (parts.isEmpty) return const Text('No metadata');
    return Text(parts.join(' · '));
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Template'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'e.g. Invoice, Bank Statement',
          ),
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
              if (ctx.mounted) Navigator.pop(ctx);
              try {
                await ref.read(templateServiceProvider).create(name: name);
                ref.invalidate(templatesProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Template created')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to create: $e')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(
      BuildContext context, WidgetRef ref, DocumentTemplate template) {
    final nameController = TextEditingController(text: template.name);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Template'),
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
              if (ctx.mounted) Navigator.pop(ctx);
              if (name == template.name) return;
              try {
                await ref
                    .read(templateServiceProvider)
                    .update(template.id, name: name);
                ref.invalidate(templatesProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Template renamed')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to rename: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, WidgetRef ref, DocumentTemplate template) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Template?'),
        content: Text('Delete "${template.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(templateServiceProvider)
                    .delete(template.id);
                ref.invalidate(templatesProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Template deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
