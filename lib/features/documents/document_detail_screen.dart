import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/thumbnail_cache.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/api/api_providers.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/correspondent.dart';
import '../../core/models/custom_field.dart';
import '../../core/models/document_type.dart';
import '../../core/models/storage_path.dart';
import '../../core/models/tag.dart';
import '../../shared/widgets/tag_chip.dart';
import 'document_detail_notifier.dart';
import 'documents_notifier.dart';
import '../inbox/inbox_notifier.dart';

class DocumentDetailScreen extends ConsumerWidget {
  final int documentId;
  const DocumentDetailScreen({super.key, required this.documentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docAsync = ref.watch(documentDetailProvider(documentId));
    final tagsAsync = ref.watch(tagsProvider);
    final correspondentsAsync = ref.watch(correspondentsProvider);
    final docTypesAsync = ref.watch(documentTypesProvider);
    final storagePathsAsync = ref.watch(storagePathsProvider);

    return docAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48,
                  color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text('Failed to load document'),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(documentDetailProvider(documentId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (doc) {
        final tags = tagsAsync.valueOrNull ?? {};
        final correspondents = correspondentsAsync.valueOrNull ?? {};
        final docTypes = docTypesAsync.valueOrNull ?? {};
        final storagePaths = storagePathsAsync.valueOrNull ?? {};
        final correspondent = doc.correspondent != null
            ? correspondents[doc.correspondent]
            : null;
        final docType = doc.documentType != null
            ? docTypes[doc.documentType]
            : null;
        final storagePath = doc.storagePath != null
            ? storagePaths[doc.storagePath]
            : null;
        final docTags = doc.tags
            .map((id) => tags[id])
            .whereType<Tag>()
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(doc.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: 'Preview PDF',
                onPressed: () => context.push('/documents/$documentId/preview'),
              ),
              if (ref.watch(aiChatUrlProvider) != null && ref.watch(aiChatUrlProvider)!.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.smart_toy),
                  tooltip: 'Chat about document',
                  onPressed: () => context.push(
                    '/documents/$documentId/chat?title=${Uri.encodeComponent(doc.title)}',
                  ),
                ),
              PopupMenuButton<String>(
                onSelected: (action) => _handleAction(context, ref, action, doc.title),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'download', child: ListTile(
                    leading: Icon(Icons.download),
                    title: Text('Download'),
                    contentPadding: EdgeInsets.zero,
                  )),
                  const PopupMenuItem(value: 'share', child: ListTile(
                    leading: Icon(Icons.share),
                    title: Text('Share'),
                    contentPadding: EdgeInsets.zero,
                  )),
                  const PopupMenuItem(value: 'more_like', child: ListTile(
                    leading: Icon(Icons.find_in_page),
                    title: Text('More like this'),
                    contentPadding: EdgeInsets.zero,
                  )),
                  const PopupMenuItem(value: 'delete', child: ListTile(
                    leading: Icon(Icons.delete_outline, color: Colors.red),
                    title: Text('Delete', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  )),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Thumbnail header
              GestureDetector(
                onTap: () => context.push('/documents/$documentId/preview'),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CachedNetworkImage(
                    imageUrl: ref.watch(paperlessApiProvider).thumbnailUrl(documentId),
                    httpHeaders: {'Authorization': ref.watch(paperlessApiProvider).authToken},
                    cacheManager: ThumbnailCacheManager.instance,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => Center(
                      child: Icon(Icons.description_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    errorWidget: (_, __, ___) => Center(
                      child: Icon(Icons.broken_image_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ),

              // Title (editable)
              _EditableTile(
                label: 'Title',
                value: doc.title,
                onSave: (v) async {
                  try {
                    await ref.read(documentDetailProvider(documentId).notifier)
                        .updateField({'title': v});
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update title: $e')),
                      );
                    }
                  }
                },
              ),

              const Divider(height: 32),

              // Correspondent
              _MetadataDropdown<Correspondent>(
                label: 'Correspondent',
                value: correspondent,
                items: correspondents.values.toList(),
                displayName: (c) => c.name,
                onChanged: (c) async {
                  try {
                    await ref.read(documentDetailProvider(documentId).notifier)
                        .updateField({'correspondent': c?.id});
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update: $e')),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 12),

              // Document Type
              _MetadataDropdown<DocumentType>(
                label: 'Document Type',
                value: docType,
                items: docTypes.values.toList(),
                displayName: (dt) => dt.name,
                onChanged: (dt) async {
                  try {
                    await ref.read(documentDetailProvider(documentId).notifier)
                        .updateField({'document_type': dt?.id});
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update: $e')),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 12),

              // Storage Path
              _MetadataDropdown<StoragePath>(
                label: 'Storage Path',
                value: storagePath,
                items: storagePaths.values.toList(),
                displayName: (sp) => sp.name,
                onChanged: (sp) async {
                  try {
                    await ref.read(documentDetailProvider(documentId).notifier)
                        .updateField({'storage_path': sp?.id});
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update: $e')),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 12),

              // Date
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Created'),
                subtitle: Text(DateFormat.yMMMd().format(doc.created)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: doc.created,
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null && context.mounted) {
                    try {
                      await ref.read(documentDetailProvider(documentId).notifier)
                          .updateField({'created': picked.toIso8601String().split('T').first});
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to update date: $e')),
                        );
                      }
                    }
                  }
                },
              ),

              // ASN (editable)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.tag),
                title: Text('Archive Serial Number',
                    style: Theme.of(context).textTheme.labelSmall),
                subtitle: Text(
                  doc.archiveSerialNumber?.toString() ?? 'Not set',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                onTap: () async {
                  final controller = TextEditingController(
                    text: doc.archiveSerialNumber?.toString() ?? '',
                  );
                  try {
                    final result = await showDialog<String>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Edit ASN'),
                        content: TextField(
                          controller: controller,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Archive serial number',
                            helperText: 'Leave empty to clear',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, controller.text),
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    );
                    if (result != null && context.mounted) {
                      final asn = result.isEmpty ? null : int.tryParse(result);
                      if (result.isNotEmpty && asn == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invalid number')),
                        );
                        return;
                      }
                      try {
                        await ref.read(documentDetailProvider(documentId).notifier)
                            .updateField({'archive_serial_number': asn});
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to update ASN: $e')),
                          );
                        }
                      }
                    }
                  } catch (_) {
                    // Dialog cancelled — no action needed
                  }
                },
              ),

              const Divider(height: 32),

              // Tags
              _TagsSection(
                documentId: documentId,
                docTags: docTags,
                allTags: tags,
              ),

              // Custom fields
              if (doc.customFields.isNotEmpty) ...[
                const Divider(height: 32),
                _CustomFieldsSection(
                  documentId: documentId,
                  fieldInstances: doc.customFields,
                ),
              ],

              const Divider(height: 32),

              // Notes
              _NotesSection(documentId: documentId),

              const Divider(height: 32),

              // Share links
              _ShareLinksSection(documentId: documentId),

              // Content preview
              if (doc.content != null && doc.content!.isNotEmpty) ...[
                const Divider(height: 32),
                Text('Content', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    doc.content!,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 20,
                    overflow: TextOverflow.fade,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleAction(
    BuildContext context, WidgetRef ref, String action, String title,
  ) async {
    switch (action) {
      case 'download':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Downloading...')),
        );
        try {
          final path = await ref.read(
            documentDownloadProvider(documentId, title).future,
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Downloaded to $path')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Download failed: $e')),
            );
          }
        }
      case 'share':
        try {
          final path = await ref.read(
            documentDownloadProvider(documentId, title).future,
          );
          await Share.shareXFiles([XFile(path)]);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Share failed: $e')),
            );
          }
        }
      case 'more_like':
        context.push('/search/similar/$documentId');
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Move to trash?'),
            content: const Text('The document will be moved to the trash. You can restore it later.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Move to Trash'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          try {
            final api = ref.read(paperlessApiProvider);
            await api.deleteDocument(documentId);
            ref.invalidate(documentsNotifierProvider);
            ref.invalidate(inboxNotifierProvider);
            if (context.mounted) context.pop();
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Delete failed: $e')),
              );
            }
          }
        }
    }
  }
}

class _EditableTile extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onSave;

  const _EditableTile({
    required this.label,
    required this.value,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.edit_outlined),
      title: Text(label, style: Theme.of(context).textTheme.labelSmall),
      subtitle: Text(value, style: Theme.of(context).textTheme.titleMedium),
      onTap: () async {
        final controller = TextEditingController(text: value);
        try {
          final result = await showDialog<String>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('Edit $label'),
              content: TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(hintText: label),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, controller.text),
                  child: const Text('Save'),
                ),
              ],
            ),
          );
          if (result != null && result != value) {
            onSave(result);
          }
        } catch (_) {
          // Dialog cancelled
        }
      },
    );
  }
}

class _MetadataDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) displayName;
  final ValueChanged<T?> onChanged;

  const _MetadataDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.displayName,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Guard: if value is not in items, treat as null to avoid assertion error
    final effectiveValue = (value != null && items.contains(value)) ? value : null;

    return Row(
      children: [
        Expanded(
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: effectiveValue,
                isExpanded: true,
                isDense: true,
                hint: Text('None'),
                items: [
                  DropdownMenuItem<T>(value: null, child: Text('None')),
                  ...items.map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(displayName(item), overflow: TextOverflow.ellipsis),
                  )),
                ],
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TagsSection extends ConsumerWidget {
  final int documentId;
  final List<Tag> docTags;
  final Map<int, Tag> allTags;

  const _TagsSection({
    required this.documentId,
    required this.docTags,
    required this.allTags,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Tags', style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add, size: 20),
              onPressed: () => _showTagPicker(context, ref),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: docTags.map((tag) {
            final bgColor = TagChip.parseColor(tag.colour);
            final fgColor = bgColor != null ? TagChip.contrastColor(bgColor) : null;
            return InputChip(
              label: Text(tag.name, style: const TextStyle(fontSize: 12)),
              backgroundColor: bgColor,
              labelStyle: TextStyle(color: fgColor),
              deleteIconColor: fgColor,
              onDeleted: () => ref.read(documentDetailProvider(documentId).notifier)
                  .removeTag(tag.id),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showTagPicker(BuildContext context, WidgetRef ref) {
    final availableTags = allTags.values
        .where((t) => !docTags.any((dt) => dt.id == t.id))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    showModalBottomSheet(
      context: context,
      builder: (ctx) => _TagPickerSheet(
        tags: availableTags,
        onSelected: (tag) {
          ref.read(documentDetailProvider(documentId).notifier).addTag(tag.id);
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _TagPickerSheet extends StatefulWidget {
  final List<Tag> tags;
  final ValueChanged<Tag> onSelected;

  const _TagPickerSheet({required this.tags, required this.onSelected});

  @override
  State<_TagPickerSheet> createState() => _TagPickerSheetState();
}

class _TagPickerSheetState extends State<_TagPickerSheet> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.tags
        .where((t) => t.name.toLowerCase().contains(_filter.toLowerCase()))
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search tags...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _filter = v),
          ),
        ),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final tag = filtered[i];
              return ListTile(
                leading: CircleAvatar(
                  radius: 12,
                  backgroundColor: TagChip.parseColor(tag.colour) ??
                      Theme.of(context).colorScheme.secondaryContainer,
                ),
                title: Text(tag.name),
                onTap: () => widget.onSelected(tag),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CustomFieldsSection extends ConsumerWidget {
  final int documentId;
  final List<CustomFieldInstance> fieldInstances;

  const _CustomFieldsSection({
    required this.documentId,
    required this.fieldInstances,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldsAsync = ref.watch(customFieldsProvider);
    final fieldDefs = fieldsAsync.valueOrNull ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Custom Fields', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ...fieldInstances.map((instance) {
          final fieldDef = fieldDefs[instance.field];
          final fieldName = fieldDef?.name ?? 'Field ${instance.field}';
          final dataType = fieldDef?.dataType ?? 'string';

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _CustomFieldTile(
              documentId: documentId,
              fieldName: fieldName,
              dataType: dataType,
              fieldId: instance.field,
              value: instance.value,
              onSave: (newValue) async {
                final updatedFields = fieldInstances.map((fi) {
                  if (fi.field == instance.field) {
                    return {'field': fi.field, 'value': newValue};
                  }
                  return {'field': fi.field, 'value': fi.value};
                }).toList();
                try {
                  await ref.read(documentDetailProvider(documentId).notifier)
                      .updateField({'custom_fields': updatedFields});
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update field: $e')),
                    );
                  }
                }
              },
            ),
          );
        }),
      ],
    );
  }
}

class _CustomFieldTile extends StatelessWidget {
  final int documentId;
  final String fieldName;
  final String dataType;
  final int fieldId;
  final dynamic value;
  final ValueChanged<dynamic> onSave;

  const _CustomFieldTile({
    required this.documentId,
    required this.fieldName,
    required this.dataType,
    required this.fieldId,
    required this.value,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(_iconForType(dataType)),
      title: Text(fieldName, style: Theme.of(context).textTheme.labelSmall),
      subtitle: Text(
        _displayValue(value, dataType),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      onTap: () => _editField(context),
    );
  }

  IconData _iconForType(String type) {
    return switch (type) {
      'string' => Icons.text_fields,
      'url' => Icons.link,
      'date' => Icons.calendar_today,
      'boolean' => Icons.toggle_on_outlined,
      'integer' || 'float' => Icons.numbers,
      'monetary' => Icons.attach_money,
      'documentlink' => Icons.description,
      _ => Icons.extension,
    };
  }

  String _displayValue(dynamic val, String type) {
    if (val == null) return 'Not set';
    if (type == 'boolean') return val == true ? 'Yes' : 'No';
    if (type == 'date' && val is String && val.isNotEmpty) {
      try {
        return DateFormat.yMMMd().format(DateTime.parse(val));
      } catch (_) {
        return val;
      }
    }
    if (type == 'monetary' && val != null) {
      return '\$${val.toString()}';
    }
    return val.toString();
  }

  Future<void> _editField(BuildContext context) async {
    switch (dataType) {
      case 'boolean':
        onSave(value != true);
      case 'date':
        final current = value is String && value.toString().isNotEmpty
            ? DateTime.tryParse(value.toString())
            : null;
        final picked = await showDatePicker(
          context: context,
          initialDate: current ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now().add(const Duration(days: 3650)),
        );
        if (picked != null) {
          onSave(picked.toIso8601String().split('T').first);
        }
      case 'integer':
        await _editTextValue(context, TextInputType.number);
      case 'float' || 'monetary':
        await _editTextValue(
            context, const TextInputType.numberWithOptions(decimal: true));
      case 'url':
        await _editTextValue(context, TextInputType.url);
      case 'select':
        await _editSelectValue(context);
      default:
        await _editTextValue(context, TextInputType.text);
    }
  }

  Future<void> _editSelectValue(BuildContext context) async {
    // Select custom fields require the option ID (integer).
    // Full option picker would need the field definition's extra_data.
    await _editTextValue(context, TextInputType.number);
  }

  Future<void> _editTextValue(BuildContext context, TextInputType keyboardType) async {
    final controller = TextEditingController(text: value?.toString() ?? '');
    try {
      final result = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Edit $fieldName'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: keyboardType,
            decoration: InputDecoration(hintText: fieldName),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Save'),
            ),
          ],
        ),
      );
      if (result != null) {
        if (dataType == 'integer') {
          onSave(int.tryParse(result));
        } else if (dataType == 'float' || dataType == 'monetary') {
          onSave(double.tryParse(result));
        } else {
          onSave(result.isEmpty ? null : result);
        }
      }
    } catch (_) {
      // Dialog cancelled
    }
  }
}

class _NotesSection extends ConsumerWidget {
  final int documentId;
  const _NotesSection({required this.documentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(documentNotesProvider(documentId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Notes', style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add, size: 20),
              onPressed: () => _addNote(context, ref),
            ),
          ],
        ),
        const SizedBox(height: 8),
        notesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Text('Failed to load notes: $err'),
          data: (notes) {
            if (notes.isEmpty) {
              return Text(
                'No notes yet',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              );
            }
            return Column(
              children: notes.map((note) => Card(
                child: ListTile(
                  title: Text(note.note),
                  subtitle: Text(DateFormat.yMMMd().add_Hm().format(note.created)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () async {
                      try {
                        await ref.read(documentNotesProvider(documentId).notifier)
                            .deleteNote(note.id);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to delete note: $e')),
                          );
                        }
                      }
                    },
                  ),
                ),
              )).toList(),
            );
          },
        ),
      ],
    );
  }

  void _addNote(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Note'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Enter note...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              Navigator.pop(ctx, text.isNotEmpty ? text : null);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    ).then((noteText) {
      if (noteText != null && context.mounted) {
        ref.read(documentNotesProvider(documentId).notifier)
            .addNote(noteText)
            .catchError((e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to add note: $e')),
            );
          }
        });
      }
    });
  }
}

class _ShareLinksSection extends ConsumerStatefulWidget {
  final int documentId;
  const _ShareLinksSection({required this.documentId});

  @override
  ConsumerState<_ShareLinksSection> createState() => _ShareLinksSectionState();
}

class _ShareLinksSectionState extends ConsumerState<_ShareLinksSection> {
  List<Map<String, dynamic>>? _links;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLinks();
  }

  Future<void> _loadLinks() async {
    try {
      final api = ref.read(paperlessApiProvider);
      final links = await api.getShareLinks(widget.documentId);
      if (mounted) setState(() { _links = links; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _links = []; _loading = false; });
    }
  }

  Future<void> _createLink() async {
    try {
      final api = ref.read(paperlessApiProvider);
      await api.createShareLink(documentId: widget.documentId);
      await _loadLinks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Share link created')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create link: $e')),
        );
      }
    }
  }

  Future<void> _deleteLink(int linkId) async {
    try {
      final api = ref.read(paperlessApiProvider);
      await api.deleteShareLink(linkId);
      await _loadLinks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Share link deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete link: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Share Links', style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add_link, size: 20),
              onPressed: _createLink,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_links == null || _links!.isEmpty)
          Text(
            'No share links',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          )
        else
          ...(_links!.map((link) {
            final slug = link['slug'] as String? ?? '';
            final api = ref.watch(paperlessApiProvider);
            final linkUrl = '${api.baseUrl}share/$slug';
            final expiration = link['expiration'] as String?;
            final linkId = link['id'] as int;

            return Card(
              child: ListTile(
                leading: const Icon(Icons.link, size: 20),
                title: Text(linkUrl,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                subtitle: expiration != null
                    ? Text('Expires: $expiration',
                        style: const TextStyle(fontSize: 11))
                    : const Text('No expiration',
                        style: TextStyle(fontSize: 11)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => _deleteLink(linkId),
                ),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: linkUrl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link copied to clipboard')),
                  );
                },
              ),
            );
          })),
      ],
    );
  }
}
