import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_providers.dart';
import '../../core/models/custom_field.dart';
import 'custom_field_helpers.dart';

class CustomFieldsScreen extends ConsumerWidget {
  const CustomFieldsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldsAsync = ref.watch(customFieldsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Custom Fields')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(customFieldsProvider),
        child: fieldsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text('Error: $err', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(customFieldsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (fields) {
            final sorted = fields.values.toList()
              ..sort((a, b) => a.name.compareTo(b.name));

            if (sorted.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.extension, size: 48),
                    SizedBox(height: 12),
                    Text('No custom fields'),
                    SizedBox(height: 4),
                    Text(
                      'Tap + to create one',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: sorted.length,
              itemBuilder: (_, i) {
                final field = sorted[i];
                final subtitle = _buildSubtitle(field);
                return ListTile(
                  leading: CircleAvatar(
                    child: Icon(dataTypeIcon(field.dataType), size: 20),
                  ),
                  title: Text(field.name),
                  subtitle: Text(subtitle),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () => _showDeleteDialog(context, ref, field),
                  ),
                  onTap: () => _showRenameDialog(context, ref, field),
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

  String _buildSubtitle(CustomField field) {
    final label = dataTypeLabel(field.dataType);
    if (field.dataType == 'select') {
      final options = field.extraData['select_options'];
      if (options is List) {
        return 'Select · ${options.length} options';
      }
      return 'Select · 0 options';
    }
    return label;
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final optionsController = TextEditingController();
    String selectedType = 'string';

    const dataTypes = [
      'string',
      'url',
      'date',
      'boolean',
      'integer',
      'float',
      'monetary',
      'document_link',
      'select',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Create Custom Field'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: dataTypes
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(dataTypeLabel(t)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => selectedType = v);
                },
              ),
              if (selectedType == 'select') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: optionsController,
                  decoration: const InputDecoration(
                    labelText: 'Options (comma-separated)',
                    hintText: 'e.g. Option A, Option B, Option C',
                  ),
                ),
              ],
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

                Map<String, dynamic>? extraData;
                if (selectedType == 'select') {
                  final options = optionsController.text
                      .split(',')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList();
                  if (options.isNotEmpty) {
                    extraData = {'select_options': options};
                  }
                }

                if (ctx.mounted) Navigator.pop(ctx);

                try {
                  final api = ref.read(paperlessApiProvider);
                  await api.createCustomField(
                    name: name,
                    dataType: selectedType,
                    extraData: extraData,
                  );
                  ref.invalidate(customFieldsProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Custom field created')),
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
      ),
    );
  }

  void _showRenameDialog(
      BuildContext context, WidgetRef ref, CustomField field) {
    final nameController = TextEditingController(text: field.name);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Field'),
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

              if (name == field.name) return;

              try {
                final api = ref.read(paperlessApiProvider);
                await api.updateCustomField(field.id, name: name);
                ref.invalidate(customFieldsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Field renamed')),
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
      BuildContext context, WidgetRef ref, CustomField field) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Custom Field?'),
        content: Text(
          'Delete "${field.name}"? This will remove the field from all documents and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);

              try {
                final api = ref.read(paperlessApiProvider);
                await api.deleteCustomField(field.id);
                ref.invalidate(customFieldsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Custom field deleted')),
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
