import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/thumbnail_cache.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/pdf_tools_service.dart';
import '../../core/api/api_providers.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/correspondent.dart';
import '../../core/models/custom_field.dart';
import '../../core/models/document_type.dart';
import '../../core/models/storage_path.dart';
import '../../core/models/tag.dart';
import '../../shared/widgets/tag_chip.dart';
import 'ai_edit_trail_notifier.dart';
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
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'rotate_cw', child: ListTile(
                    leading: Icon(Icons.rotate_right),
                    title: Text('Rotate 90° CW'),
                    contentPadding: EdgeInsets.zero,
                  )),
                  const PopupMenuItem(value: 'rotate_180', child: ListTile(
                    leading: Icon(Icons.rotate_90_degrees_cw),
                    title: Text('Rotate 180°'),
                    contentPadding: EdgeInsets.zero,
                  )),
                  const PopupMenuItem(value: 'rotate_ccw', child: ListTile(
                    leading: Icon(Icons.rotate_left),
                    title: Text('Rotate 90° CCW'),
                    contentPadding: EdgeInsets.zero,
                  )),
                  const PopupMenuItem(value: 'split', child: ListTile(
                    leading: Icon(Icons.call_split),
                    title: Text('Split document'),
                    contentPadding: EdgeInsets.zero,
                  )),
                  const PopupMenuItem(value: 'annotate', child: ListTile(
                    leading: Icon(Icons.draw),
                    title: Text('Annotate'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  )),
                  const PopupMenuItem(value: 'compress_share', child: ListTile(
                    leading: Icon(Icons.compress),
                    title: Text('Compress & Share'),
                    contentPadding: EdgeInsets.zero,
                  )),
                  const PopupMenuItem(value: 'protect_share', child: ListTile(
                    leading: Icon(Icons.lock_outline),
                    title: Text('Password Protect & Share'),
                    contentPadding: EdgeInsets.zero,
                  )),
                  const PopupMenuDivider(),
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
                subtitle: Text(doc.created != null ? DateFormat.yMMMd().format(doc.created!) : 'Unknown'),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: doc.created ?? DateTime.now(),
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

              // Scan date shortcut — shown below created date
              if (doc.added != null) ...[
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: Row(
                    children: [
                      Icon(
                        Icons.upload_file_outlined,
                        size: 14,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Scanned ${DateFormat.yMMMd().format(doc.added!)}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const Spacer(),
                      if (doc.added!.toIso8601String().split('T').first !=
                          (doc.created?.toIso8601String().split('T').first ??
                              ''))
                        TextButton(
                          style: TextButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            textStyle:
                                Theme.of(context).textTheme.labelSmall,
                          ),
                          onPressed: () async {
                            final scanDate = doc.added!
                                .toIso8601String()
                                .split('T')
                                .first;
                            try {
                              await ref
                                  .read(documentDetailProvider(documentId)
                                      .notifier)
                                  .updateField({'created': scanDate});
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Failed to update date: $e')),
                                );
                              }
                            }
                          },
                          child: const Text('Use as created'),
                        ),
                    ],
                  ),
                ),
              ],

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
              const Divider(height: 32),
              _CustomFieldsSection(
                documentId: documentId,
                fieldInstances: doc.customFields,
              ),

              const Divider(height: 32),

              // Notes
              _NotesSection(documentId: documentId),

              // AI edit trail
              _AiEditTrailSection(documentId: documentId),

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
      case 'rotate_cw':
      case 'rotate_180':
      case 'rotate_ccw':
        final degrees = switch (action) {
          'rotate_cw' => 90,
          'rotate_180' => 180,
          _ => 270,
        };
        try {
          await ref.read(paperlessApiProvider).bulkEdit(
                documents: [documentId],
                method: 'rotate',
                parameters: {'degrees': degrees},
              );
          ref.invalidate(documentDetailProvider(documentId));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Rotated $degrees°')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to rotate: $e')),
            );
          }
        }
      case 'split':
        final controller = TextEditingController();
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Split document'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Page ranges',
                hintText: 'e.g. 1-3, 4-6',
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Split'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          final input = controller.text.trim();
          if (input.isEmpty) break;
          try {
            await ref.read(paperlessApiProvider).bulkEdit(
                  documents: [documentId],
                  method: 'split',
                  parameters: {'pages': input},
                );
            ref.invalidate(documentsNotifierProvider);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Document split successfully')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to split: $e')),
              );
            }
          }
        }
      case 'annotate':
        try {
          final dir = await getTemporaryDirectory();
          final path = '${dir.path}/annotate_$documentId.pdf';
          await ref.read(paperlessApiProvider).downloadDocument(documentId, path);
          if (context.mounted) {
            context.push('/annotate', extra: {'pdfPath': path, 'title': title});
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load document: $e')),
            );
          }
        }
      case 'compress_share':
        final selectedQuality = await showDialog<CompressionQuality>(
          context: context,
          builder: (ctx) => SimpleDialog(
            title: const Text('Select compression quality'),
            children: CompressionQuality.values.map((q) => SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, q),
              child: Text(q.label),
            )).toList(),
          ),
        );
        if (selectedQuality == null) break;
        if (!context.mounted) break;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compressing...')),
        );
        try {
          final tempPath = await ref.read(
            documentDownloadProvider(documentId, title).future,
          );
          final outputPath = await compressPdf(
            inputPath: tempPath,
            quality: selectedQuality,
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            await Share.shareXFiles([XFile(outputPath)]);
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Compress failed: $e')),
            );
          }
        }
      case 'protect_share':
        final passwordController = TextEditingController();
        String? validationError;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setState) => AlertDialog(
              title: const Text('Password protect PDF'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      errorText: validationError,
                    ),
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
                    final err = validatePassword(passwordController.text);
                    if (err != null) {
                      setState(() => validationError = err);
                    } else {
                      Navigator.pop(ctx, true);
                    }
                  },
                  child: const Text('Protect & Share'),
                ),
              ],
            ),
          ),
        );
        if (confirmed != true) break;
        if (!context.mounted) break;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Encrypting...')),
        );
        try {
          final tempPath = await ref.read(
            documentDownloadProvider(documentId, title).future,
          );
          final outputPath = await protectPdf(
            inputPath: tempPath,
            password: passwordController.text,
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            await Share.shareXFiles([XFile(outputPath)]);
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Protect failed: $e')),
            );
          }
        }
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
            await api.trashDocuments([documentId]);
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
      isScrollControlled: true,
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

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
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
            Expanded(
              child: ListView.builder(
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
        ),
      ),
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
        Row(
          children: [
            Text('Custom Fields',
                style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add, size: 20),
              onPressed: fieldsAsync.isLoading
                  ? null
                  : () => _showAddFieldPicker(context, ref, fieldDefs),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (fieldInstances.isEmpty && fieldDefs.isEmpty)
          Text(
            'No custom fields configured on this server',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          )
        else if (fieldInstances.isEmpty)
          Text(
            'No values set — tap + to add',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          )
        else
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
                extraData: fieldDef?.extraData,
                onSave: (newValue) async {
                  final updatedFields = fieldInstances.map((fi) {
                    if (fi.field == instance.field) {
                      return {'field': fi.field, 'value': newValue};
                    }
                    return {'field': fi.field, 'value': fi.value};
                  }).toList();
                  try {
                    await ref
                        .read(documentDetailProvider(documentId).notifier)
                        .updateField({'custom_fields': updatedFields});
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Failed to update field: $e')),
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

  void _showAddFieldPicker(
    BuildContext context,
    WidgetRef ref,
    Map<int, CustomField> fieldDefs,
  ) {
    // Only show fields that aren't already assigned
    final assignedIds = fieldInstances.map((fi) => fi.field).toSet();
    final available = fieldDefs.values
        .where((f) => !assignedIds.contains(f.id))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All custom fields already assigned')),
      );
      return;
    }

    showModalBottomSheet<CustomField>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Add Custom Field',
                    style: Theme.of(ctx).textTheme.titleMedium),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: available
                      .map((f) => ListTile(
                            title: Text(f.name),
                            subtitle: Text(f.dataType,
                                style: Theme.of(ctx).textTheme.bodySmall),
                            onTap: () => Navigator.pop(ctx, f),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ).then((selectedField) async {
      if (selectedField == null || !context.mounted) return;
      // If the user dismisses the edit dialog without saving, nothing is persisted.
      // This is intentional — the field picker can be re-opened via '+'.
      await _editCustomFieldValue(
        context: context,
        fieldName: selectedField.name,
        dataType: selectedField.dataType,
        currentValue: null,
        extraData: selectedField.extraData,
        onSave: (newValue) async {
          final updatedFields = [
            ...fieldInstances
                .map((fi) => {'field': fi.field, 'value': fi.value}),
            {'field': selectedField.id, 'value': newValue},
          ];
          try {
            await ref
                .read(documentDetailProvider(documentId).notifier)
                .updateField({'custom_fields': updatedFields});
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to add field: $e')),
              );
            }
          }
        },
      );
    });
  }
}

/// Returns a display string for a custom field value.
/// Package-visible so tests can call it directly.
String displayCustomFieldValue(dynamic val, String type,
    {Map<String, dynamic>? extraData}) {
  if (val == null) return 'Not set';
  if (type == 'boolean') return val == true ? 'Yes' : 'No';
  if (type == 'date' && val is String && val.isNotEmpty) {
    try {
      return DateFormat.yMMMd().format(DateTime.parse(val));
    } catch (_) {
      return val;
    }
  }
  if (type == 'monetary') return '\$${val.toString()}';
  if (type == 'select') {
    final options = extraData?['select_options'] as List<dynamic>? ?? [];
    return _displaySelectValue(val, options);
  }
  return val.toString();
}

String _displaySelectValue(dynamic val, List<dynamic> options) {
  if (val == null) return 'Not set';
  for (final opt in options) {
    if (opt is Map) {
      if (opt['id'] == val || opt['id'].toString() == val.toString()) {
        return opt['label']?.toString() ?? opt['id']?.toString() ?? '';
      }
    } else if (opt.toString() == val.toString()) {
      return opt.toString();
    }
  }
  return val.toString();
}

/// Core editing logic for a single custom field. Used by both _CustomFieldTile
/// (via its onTap) and _showAddFieldPicker (for newly added fields).
Future<void> _editCustomFieldValue({
  required BuildContext context,
  required String fieldName,
  required String dataType,
  required dynamic currentValue,
  required Map<String, dynamic>? extraData,
  required ValueChanged<dynamic> onSave,
}) async {
  switch (dataType) {
    case 'boolean':
      onSave(currentValue != true);
    case 'date':
      final current = currentValue is String && currentValue.toString().isNotEmpty
          ? DateTime.tryParse(currentValue.toString())
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
      await _editCustomFieldText(context, fieldName, currentValue, TextInputType.number, onSave, dataType);
    case 'float' || 'monetary':
      await _editCustomFieldText(context, fieldName, currentValue, const TextInputType.numberWithOptions(decimal: true), onSave, dataType);
    case 'url':
      await _editCustomFieldText(context, fieldName, currentValue, TextInputType.url, onSave, dataType);
    case 'select':
      await _editCustomFieldSelect(context, fieldName, currentValue, extraData, onSave);
    default:
      await _editCustomFieldText(context, fieldName, currentValue, TextInputType.text, onSave, dataType);
  }
}

Future<void> _editCustomFieldText(
  BuildContext context,
  String fieldName,
  dynamic currentValue,
  TextInputType keyboardType,
  ValueChanged<dynamic> onSave,
  String dataType,
) async {
  final controller = TextEditingController(text: currentValue?.toString() ?? '');
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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

Future<void> _editCustomFieldSelect(
  BuildContext context,
  String fieldName,
  dynamic currentValue,
  Map<String, dynamic>? extraData,
  ValueChanged<dynamic> onSave,
) async {
  const selectNone = '__none__';
  final options = extraData?['select_options'] as List<dynamic>? ?? [];
  if (options.isEmpty) {
    await _editCustomFieldText(context, fieldName, currentValue, TextInputType.text, onSave, 'string');
    return;
  }
  final result = await showModalBottomSheet<dynamic>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(fieldName, style: Theme.of(ctx).textTheme.titleMedium),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    title: const Text('None'),
                    trailing: currentValue == null ? const Icon(Icons.check) : null,
                    onTap: () => Navigator.pop(ctx, selectNone),
                  ),
                  ...options.map((opt) {
                    final id = opt is Map ? opt['id'] : opt;
                    final label = opt is Map
                        ? (opt['label']?.toString() ?? opt['id']?.toString() ?? '')
                        : opt.toString();
                    final isSelected = id == currentValue ||
                        id.toString() == currentValue.toString();
                    return ListTile(
                      title: Text(label),
                      trailing: isSelected ? const Icon(Icons.check) : null,
                      onTap: () => Navigator.pop(ctx, id),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
  if (result == null) return;
  onSave(result == selectNone ? null : result);
}

class _CustomFieldTile extends StatelessWidget {
  final int documentId;
  final String fieldName;
  final String dataType;
  final int fieldId;
  final dynamic value;
  final Map<String, dynamic>? extraData;
  final ValueChanged<dynamic> onSave;

  const _CustomFieldTile({
    required this.documentId,
    required this.fieldName,
    required this.dataType,
    required this.fieldId,
    required this.value,
    this.extraData,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(_iconForType(dataType)),
      title: Text(fieldName, style: Theme.of(context).textTheme.labelSmall),
      subtitle: Text(
        displayCustomFieldValue(value, dataType, extraData: extraData),
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

  Future<void> _editField(BuildContext context) => _editCustomFieldValue(
    context: context,
    fieldName: fieldName,
    dataType: dataType,
    currentValue: value,
    extraData: extraData,
    onSave: onSave,
  );
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

class _AiEditTrailSection extends ConsumerWidget {
  final int documentId;
  const _AiEditTrailSection({required this.documentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trailAsync = ref.watch(aiEditTrailProvider(documentId));
    return trailAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, __) {
        debugPrint('AiEditTrailSection error: $e');
        return const SizedBox.shrink();
      },
      data: (edits) {
        if (edits.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 32),
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Applied at Upload',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...edits.map(
              (edit) => _AiEditRow(documentId: documentId, edit: edit),
            ),
          ],
        );
      },
    );
  }
}

class _AiEditRow extends ConsumerWidget {
  final int documentId;
  final AiEditEntry edit;
  const _AiEditRow({required this.documentId, required this.edit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.auto_awesome,
        size: 16,
        color: Theme.of(context).colorScheme.tertiary,
      ),
      title: Text(
        _fieldLabel(edit.fieldName),
        style: Theme.of(context).textTheme.labelMedium,
      ),
      subtitle: edit.newValue != null
          ? Text(
              edit.newValue!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : Text(
              'Cleared',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 18),
        tooltip: 'Remove from history',
        onPressed: () {
          ref
              .read(aiEditTrailProvider(documentId).notifier)
              .deleteEdit(edit.id)
              .catchError((Object e) {
                debugPrint('Failed to delete AI edit: $e');
              });
        },
      ),
    );
  }

  String _fieldLabel(String fieldName) {
    return switch (fieldName) {
      'title' => 'Title',
      'correspondent' => 'Correspondent',
      'document_type' => 'Document Type',
      'tags' => 'Tags',
      'created' => 'Created Date',
      _ => fieldName
              .split('_')
              .map((w) => w.isEmpty
                  ? ''
                  : '${w[0].toUpperCase()}${w.substring(1)}')
              .join(' '),
    };
  }
}
