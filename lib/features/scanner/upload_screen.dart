import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_providers.dart';
import '../../core/design_tokens.dart';
import '../../core/models/document_template.dart';
import '../../core/services/template_service.dart';
import '../../shared/widgets/metadata_sheet.dart';
import '../../shared/widgets/stamp_chip.dart';
import '../../shared/widgets/tag_chip.dart';
import 'providers/metadata_suggestion_provider.dart';
import 'processing/metadata_matcher.dart';
import 'upload_notifier.dart';
import '../documents/ai_edit_trail_notifier.dart';
import '../../core/api/api_error_mapper.dart';

/// Metadata entry and upload screen.
///
/// At rest this is a confirm surface: a preview, an editable title, OCR
/// suggestions shown as tappable stamp chips, and one Upload action. The full
/// metadata editor lives behind a quiet "Edit details" sheet.
class UploadScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> params;
  const UploadScreen({super.key, required this.params});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  final _titleController = TextEditingController();
  int? _correspondent;
  int? _documentType;
  final List<int> _selectedTags = [];
  DateTime? _created;

  // Track which fields were auto-filled by OCR suggestions
  bool _suggestedCorrespondent = false;
  bool _suggestedDocType = false;
  bool _suggestedTags = false;
  bool _suggestedDate = false;
  bool _suggestionsApplied = false;
  MetadataSuggestions? _suggestions;
  // Maps field name → applied value for AI edit trail recording
  final Map<String, ({String? oldValue, String? newValue})> _appliedAiEdits = {};

  bool get _isScannedImages => widget.params.containsKey('imagePaths');
  List<String> get _imagePaths =>
      (widget.params['imagePaths'] as List<dynamic>?)?.cast<String>() ?? [];
  String get _filePath => widget.params['filePath'] as String? ?? '';
  String get _filename => widget.params['filename'] as String? ?? '';
  String? get _ocrImagePath => widget.params['ocrImagePath'] as String?;

  /// A local image path suitable for a preview thumbnail, if we have one.
  String? get _previewImagePath =>
      _ocrImagePath ?? (_isScannedImages && _imagePaths.isNotEmpty
          ? _imagePaths.first
          : null);

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _applySuggestions(MetadataSuggestions suggestions) {
    if (_suggestionsApplied) return;
    _suggestionsApplied = true;

    setState(() {
      _suggestions = suggestions;
      if (suggestions.correspondentId != null && _correspondent == null) {
        _correspondent = suggestions.correspondentId;
        _suggestedCorrespondent = true;
        _appliedAiEdits['correspondent'] = (
          oldValue: null,
          newValue: suggestions.correspondentId.toString(),
        );
      }
      if (suggestions.documentTypeId != null && _documentType == null) {
        _documentType = suggestions.documentTypeId;
        _suggestedDocType = true;
        _appliedAiEdits['document_type'] = (
          oldValue: null,
          newValue: suggestions.documentTypeId.toString(),
        );
      }
      if (suggestions.tagIds.isNotEmpty && _selectedTags.isEmpty) {
        _selectedTags.addAll(suggestions.tagIds);
        _suggestedTags = true;
        _appliedAiEdits['tags'] = (
          oldValue: null,
          newValue: suggestions.tagIds.join(', '),
        );
      }
      if (suggestions.detectedDate != null && _created == null) {
        _created = suggestions.detectedDate;
        _suggestedDate = true;
        _appliedAiEdits['created'] = (
          oldValue: null,
          newValue:
              suggestions.detectedDate!.toIso8601String().split('T').first,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(uploadNotifierProvider);
    final tokens = AppTokens.of(context);

    // Listen for OCR metadata suggestions
    if (_ocrImagePath != null) {
      ref.listen(
        metadataSuggestionsProvider(_ocrImagePath!),
        (prev, next) {
          if (next.hasValue) {
            _applySuggestions(next.value!);
          }
        },
      );
    }

    // Listen for upload completion
    ref.listen(uploadNotifierProvider, (prev, next) {
      if (!context.mounted) return;
      if (next.status == UploadStatus.success) {
        // Record AI edits if suggestions were applied and we have a document ID
        if (_appliedAiEdits.isNotEmpty && next.documentId != null) {
          ref
              .read(aiEditTrailProvider(next.documentId!).notifier)
              .recordEdits(_appliedAiEdits, 'ocr_suggestion')
              .catchError((Object e) {
                debugPrint('Failed to record AI edit trail: $e');
              });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully!')),
        );
        context.go('/scan');
      } else if (next.status == UploadStatus.failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${next.errorMessage ?? "Unknown error"}')),
        );
      } else if (next.status == UploadStatus.queued) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No connection — upload queued for later')),
        );
        context.go('/scan');
      }
    });

    final isUploading = uploadState.status == UploadStatus.uploading ||
        uploadState.status == UploadStatus.processing;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isScannedImages ? 'Upload Scan' : 'Upload File'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            tooltip: 'Apply template',
            onPressed: isUploading ? null : () => _showTemplatePicker(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: [
          _buildPreview(tokens),
          const SizedBox(height: Spacing.lg),

          // Title
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              hintText: 'Leave empty for auto-detection',
            ),
          ),
          const SizedBox(height: Spacing.lg),

          // OCR suggestions + applied metadata as stamp chips.
          _buildMetadataChips(tokens),
          const SizedBox(height: Spacing.md),

          // Quiet entry to the full editor.
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: isUploading ? null : _openDetailsSheet,
              icon: const Icon(Icons.tune, size: 18),
              label: const Text('Edit details'),
            ),
          ),

          const SizedBox(height: Spacing.xl),

          // Single primary action.
          if (isUploading) ...[
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: Spacing.md),
            Text(
              uploadState.status == UploadStatus.uploading
                  ? 'Uploading...'
                  : 'Processing document...',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: tokens.inkSoft),
            ),
          ] else ...[
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.cloud_upload_outlined, size: 18),
              label: const Text('Upload'),
            ),
            const SizedBox(height: Spacing.sm),
            TextButton.icon(
              onPressed: () => _saveAsTemplate(context),
              icon: const Icon(Icons.bookmark_add_outlined, size: 18),
              label: const Text('Save as template'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreview(AppTokens tokens) {
    final preview = _previewImagePath;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 88,
            child: preview != null
                ? Image.file(File(preview), fit: BoxFit.cover)
                : ColoredBox(
                    color: tokens.paper,
                    child: Icon(Icons.picture_as_pdf_outlined,
                        color: tokens.inkSoft, size: 32),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Text(
                _isScannedImages
                    ? '${_imagePaths.length} scanned ${_imagePaths.length == 1 ? 'page' : 'pages'}'
                    : _filename,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Applied metadata as chips; OCR-suggested values wear the stamp motif and a
  /// delete affordance, rejected suggestions can be re-accepted with a tap.
  Widget _buildMetadataChips(AppTokens tokens) {
    final correspondents = ref.watch(correspondentsProvider).valueOrNull ?? {};
    final docTypes = ref.watch(documentTypesProvider).valueOrNull ?? {};
    final tags = ref.watch(tagsProvider).valueOrNull ?? {};
    final s = _suggestions;

    final chips = <Widget>[];

    // Correspondent
    if (_correspondent != null && correspondents[_correspondent] != null) {
      chips.add(_appliedChip(
        label: correspondents[_correspondent]!.name,
        icon: Icons.person_outline,
        suggested: _suggestedCorrespondent,
        onRemove: () => setState(() {
          _correspondent = null;
          _suggestedCorrespondent = false;
          _appliedAiEdits.remove('correspondent');
        }),
      ));
    } else if (s?.correspondentId != null &&
        correspondents[s!.correspondentId] != null) {
      chips.add(_reAcceptChip(
        'Add ${correspondents[s.correspondentId]!.name}',
        () => setState(() {
          _correspondent = s.correspondentId;
          _suggestedCorrespondent = true;
          _appliedAiEdits['correspondent'] =
              (oldValue: null, newValue: s.correspondentId.toString());
        }),
      ));
    }

    // Document type
    if (_documentType != null && docTypes[_documentType] != null) {
      chips.add(_appliedChip(
        label: docTypes[_documentType]!.name,
        icon: Icons.category_outlined,
        suggested: _suggestedDocType,
        onRemove: () => setState(() {
          _documentType = null;
          _suggestedDocType = false;
          _appliedAiEdits.remove('document_type');
        }),
      ));
    } else if (s?.documentTypeId != null &&
        docTypes[s!.documentTypeId] != null) {
      chips.add(_reAcceptChip(
        'Add ${docTypes[s.documentTypeId]!.name}',
        () => setState(() {
          _documentType = s.documentTypeId;
          _suggestedDocType = true;
          _appliedAiEdits['document_type'] =
              (oldValue: null, newValue: s.documentTypeId.toString());
        }),
      ));
    }

    // Date
    if (_created != null) {
      chips.add(_appliedChip(
        label: DateFormat.yMMMd().format(_created!),
        icon: Icons.calendar_today_outlined,
        suggested: _suggestedDate,
        onRemove: () => setState(() {
          _created = null;
          _suggestedDate = false;
          _appliedAiEdits.remove('created');
        }),
      ));
    } else if (s?.detectedDate != null) {
      chips.add(_reAcceptChip(
        'Add ${DateFormat.yMMMd().format(s!.detectedDate!)}',
        () => setState(() {
          _created = s.detectedDate;
          _suggestedDate = true;
          _appliedAiEdits['created'] = (
            oldValue: null,
            newValue: s.detectedDate!.toIso8601String().split('T').first,
          );
        }),
      ));
    }

    // Tags
    for (final id in _selectedTags) {
      final tag = tags[id];
      if (tag == null) continue;
      chips.add(_appliedChip(
        label: tag.name,
        icon: Icons.sell_outlined,
        suggested: _suggestedTags,
        tint: TagChip.parseColor(tag.colour),
        onRemove: () => setState(() {
          _selectedTags.remove(id);
          if (_selectedTags.isEmpty) _suggestedTags = false;
          _appliedAiEdits.remove('tags');
        }),
      ));
    }

    if (chips.isEmpty) {
      return Text(
        'No metadata yet — add details below',
        style:
            Theme.of(context).textTheme.bodySmall?.copyWith(color: tokens.inkSoft),
      );
    }

    return Wrap(spacing: Spacing.sm, runSpacing: Spacing.xs, children: chips);
  }

  Widget _appliedChip({
    required String label,
    required IconData icon,
    required bool suggested,
    required VoidCallback onRemove,
    Color? tint,
  }) {
    if (suggested) {
      return StampChip(
        label: label,
        icon: icon,
        tint: tint,
        rotated: false,
        onDeleted: onRemove,
      );
    }
    return InputChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onDeleted: onRemove,
    );
  }

  Widget _reAcceptChip(String label, VoidCallback onAdd) {
    return ActionChip(
      avatar: const Icon(Icons.add, size: 16),
      label: Text(label),
      onPressed: onAdd,
    );
  }

  void _openDetailsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => MetadataSheet(
        correspondentId: _correspondent,
        documentTypeId: _documentType,
        tagIds: List.of(_selectedTags),
        created: _created,
        suggestedCorrespondent: _suggestedCorrespondent,
        suggestedDocumentType: _suggestedDocType,
        suggestedDate: _suggestedDate,
        suggestedTagIds: _suggestedTags ? _selectedTags.toSet() : const {},
        onSave: _applySheetResult,
      ),
    );
  }

  void _applySheetResult(MetadataSheetResult r) {
    setState(() {
      // A field the user changed in the sheet is a manual edit — drop the OCR
      // suggestion marker and its edit-trail entry for that field.
      if (r.correspondentId != _correspondent) {
        _suggestedCorrespondent = false;
        _appliedAiEdits.remove('correspondent');
      }
      if (r.documentTypeId != _documentType) {
        _suggestedDocType = false;
        _appliedAiEdits.remove('document_type');
      }
      if (r.created != _created) {
        _suggestedDate = false;
        _appliedAiEdits.remove('created');
      }
      if (!_sameTags(r.tagIds, _selectedTags)) {
        _suggestedTags = false;
        _appliedAiEdits.remove('tags');
      }
      _correspondent = r.correspondentId;
      _documentType = r.documentTypeId;
      _created = r.created;
      _selectedTags
        ..clear()
        ..addAll(r.tagIds);
    });
  }

  bool _sameTags(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    final sa = a.toSet();
    return b.every(sa.contains);
  }

  void _applyTemplate(DocumentTemplate template) {
    setState(() {
      if (template.correspondentId != null) {
        _correspondent = template.correspondentId;
        _suggestedCorrespondent = false;
        _appliedAiEdits.remove('correspondent');
      }
      if (template.documentTypeId != null) {
        _documentType = template.documentTypeId;
        _suggestedDocType = false;
        _appliedAiEdits.remove('document_type');
      }
      if (template.tagIds.isNotEmpty) {
        for (final id in template.tagIds) {
          if (!_selectedTags.contains(id)) {
            _selectedTags.add(id);
          }
        }
        _suggestedTags = false;
        _appliedAiEdits.remove('tags');
      }
    });
  }

  void _showTemplatePicker(BuildContext context) {
    final templatesAsync = ref.read(templatesProvider);
    final templates = templatesAsync.valueOrNull ?? [];

    if (templates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No templates saved yet')),
      );
      return;
    }

    final sorted = [...templates]..sort((a, b) => a.name.compareTo(b.name));

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SizedBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Spacing.lg, Spacing.lg, Spacing.lg, Spacing.sm),
              child: Text(
                'Apply Template',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            ...sorted.map(
              (t) => ListTile(
                leading: const Icon(Icons.bookmark_outline),
                title: Text(t.name),
                onTap: () {
                  Navigator.pop(ctx);
                  _applyTemplate(t);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Applied template "${t.name}"')),
                  );
                },
              ),
            ),
            const SizedBox(height: Spacing.sm),
          ],
        ),
      ),
    );
  }

  void _saveAsTemplate(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save as Template'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Template name',
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
                await ref.read(templateServiceProvider).create(
                      name: name,
                      correspondentId: _correspondent,
                      documentTypeId: _documentType,
                      tagIds: List<int>.from(_selectedTags),
                    );
                ref.invalidate(templatesProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Saved template "$name"')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to save template: ${friendlyApiMessage(e)}')),
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

  void _submit() {
    final notifier = ref.read(uploadNotifierProvider.notifier);
    final title = _titleController.text.trim().isEmpty
        ? null
        : _titleController.text.trim();

    if (_isScannedImages) {
      notifier.uploadScannedImages(
        imagePaths: _imagePaths,
        title: title,
        correspondent: _correspondent,
        documentType: _documentType,
        tags: _selectedTags.isEmpty ? null : _selectedTags,
        created: _created,
      );
    } else {
      notifier.uploadFile(
        filePath: _filePath,
        filename: _filename,
        title: title,
        correspondent: _correspondent,
        documentType: _documentType,
        tags: _selectedTags.isEmpty ? null : _selectedTags,
        created: _created,
      );
    }
  }
}
