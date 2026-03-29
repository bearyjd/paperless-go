import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_providers.dart';
import '../../core/models/tag.dart';
import '../../shared/widgets/tag_chip.dart';
import 'providers/metadata_suggestion_provider.dart';
import 'processing/metadata_matcher.dart';
import 'upload_notifier.dart';
import '../documents/ai_edit_trail_notifier.dart';

/// Metadata entry and upload screen.
/// Receives either imagePaths (for scanned images)
/// or filePath+filename (for picked files) via params map.
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
  // Maps field name → applied value for AI edit trail recording
  final Map<String, ({String? oldValue, String? newValue})> _appliedAiEdits = {};

  bool get _isScannedImages => widget.params.containsKey('imagePaths');
  List<String> get _imagePaths =>
      (widget.params['imagePaths'] as List<dynamic>?)?.cast<String>() ?? [];
  String get _filePath => widget.params['filePath'] as String? ?? '';
  String get _filename => widget.params['filename'] as String? ?? '';
  String? get _ocrImagePath => widget.params['ocrImagePath'] as String?;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _applySuggestions(MetadataSuggestions suggestions) {
    if (_suggestionsApplied) return;
    _suggestionsApplied = true;

    setState(() {
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
          newValue: suggestions.detectedDate!
              .toIso8601String()
              .split('T')
              .first,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(uploadNotifierProvider);
    final correspondentsAsync = ref.watch(correspondentsProvider);
    final docTypesAsync = ref.watch(documentTypesProvider);
    final tagsAsync = ref.watch(tagsProvider);

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
              .recordEdits(_appliedAiEdits, 'ocr_suggestion');
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
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Source info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    _isScannedImages ? Icons.document_scanner : Icons.insert_drive_file,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isScannedImages
                          ? '${_imagePaths.length} scanned ${_imagePaths.length == 1 ? 'page' : 'pages'}'
                          : _filename,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title (optional)',
              border: OutlineInputBorder(),
              hintText: 'Leave empty for auto-detection',
            ),
          ),
          const SizedBox(height: 16),

          // Correspondent
          correspondentsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (correspondents) => InputDecorator(
              decoration: InputDecoration(
                labelText: 'Correspondent',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                suffix: _suggestedCorrespondent ? _suggestedBadge() : null,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: _correspondent,
                  isExpanded: true,
                  isDense: true,
                  hint: const Text('None'),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('None')),
                    ...correspondents.values.map((c) => DropdownMenuItem<int?>(
                          value: c.id,
                          child: Text(c.name, overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: isUploading
                      ? null
                      : (v) => setState(() {
                            _correspondent = v;
                            _suggestedCorrespondent = false;
                          }),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Document Type
          docTypesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (docTypes) => InputDecorator(
              decoration: InputDecoration(
                labelText: 'Document Type',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                suffix: _suggestedDocType ? _suggestedBadge() : null,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: _documentType,
                  isExpanded: true,
                  isDense: true,
                  hint: const Text('None'),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('None')),
                    ...docTypes.values.map((dt) => DropdownMenuItem<int?>(
                          value: dt.id,
                          child: Text(dt.name, overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: isUploading
                      ? null
                      : (v) => setState(() {
                            _documentType = v;
                            _suggestedDocType = false;
                          }),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Date
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today),
            title: Row(
              children: [
                const Text('Date'),
                if (_suggestedDate) ...[
                  const SizedBox(width: 8),
                  _suggestedBadge(),
                ],
              ],
            ),
            subtitle: Text(_created != null
                ? DateFormat.yMMMd().format(_created!)
                : 'Auto-detect'),
            onTap: isUploading
                ? null
                : () async {
                    await _pickDate(context);
                    _suggestedDate = false;
                  },
            trailing: _created != null
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => setState(() {
                      _created = null;
                      _suggestedDate = false;
                    }),
                  )
                : null,
          ),

          const Divider(height: 32),

          // Tags
          _buildTagsSection(tagsAsync),

          const SizedBox(height: 32),

          // Upload button
          if (isUploading) ...[
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 12),
            Text(
              uploadState.status == UploadStatus.uploading
                  ? 'Uploading...'
                  : 'Processing document...',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ] else
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Upload'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
        ],
      ),
    );
  }

  Widget _suggestedBadge() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.auto_awesome, size: 14, color: Theme.of(context).colorScheme.tertiary),
        const SizedBox(width: 2),
        Text(
          'Suggested',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.tertiary,
              ),
        ),
      ],
    );
  }

  Widget _buildTagsSection(AsyncValue<Map<int, Tag>> tagsAsync) {
    return tagsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const Text('Failed to load tags'),
      data: (allTags) {
        final selectedTagObjects = _selectedTags
            .map((id) => allTags[id])
            .whereType<Tag>()
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Tags', style: Theme.of(context).textTheme.titleSmall),
                if (_suggestedTags) ...[
                  const SizedBox(width: 8),
                  _suggestedBadge(),
                ],
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () => _showTagPicker(context, allTags),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (selectedTagObjects.isEmpty)
              Text(
                'No tags selected',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: selectedTagObjects.map((tag) {
                  final bgColor = TagChip.parseColor(tag.colour);
                  final fgColor = bgColor != null ? TagChip.contrastColor(bgColor) : null;
                  return InputChip(
                    label: Text(tag.name, style: const TextStyle(fontSize: 12)),
                    backgroundColor: bgColor,
                    labelStyle: TextStyle(color: fgColor),
                    deleteIconColor: fgColor,
                    onDeleted: () => setState(() {
                      _selectedTags.remove(tag.id);
                      _suggestedTags = false;
                    }),
                  );
                }).toList(),
              ),
          ],
        );
      },
    );
  }

  void _showTagPicker(BuildContext context, Map<int, Tag> allTags) {
    final available = allTags.values
        .where((t) => !_selectedTags.contains(t.id))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _TagPickerSheet(
        tags: available,
        onSelected: (tag) {
          setState(() {
            _selectedTags.add(tag.id);
            _suggestedTags = false;
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _created ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _created = picked);
    }
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
