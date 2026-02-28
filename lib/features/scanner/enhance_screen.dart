import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'processing/image_enhancer.dart';
import 'processing/presets.dart';

/// Screen for enhancing scanned images with filter presets.
/// Shows before/after comparison and allows preset selection.
class EnhanceScreen extends StatefulWidget {
  final List<String> imagePaths;
  const EnhanceScreen({super.key, required this.imagePaths});

  @override
  State<EnhanceScreen> createState() => _EnhanceScreenState();
}

class _EnhanceScreenState extends State<EnhanceScreen> {
  late List<String> _originalPaths;
  late List<String?> _enhancedPaths;
  ProcessingPreset _selectedPreset = ProcessingPreset.auto;
  int _currentPage = 0;
  bool _isProcessing = false;
  bool _showOriginal = false;

  // Preview bytes for fast before/after
  Uint8List? _previewOriginal;
  Uint8List? _previewEnhanced;

  @override
  void initState() {
    super.initState();
    _originalPaths = List.from(widget.imagePaths);
    _enhancedPaths = List.filled(_originalPaths.length, null);
    _loadPreview();
    _processAllPages();
  }

  Future<void> _loadPreview() async {
    final bytes = await File(_originalPaths[_currentPage]).readAsBytes();
    if (!mounted) return;
    setState(() => _previewOriginal = bytes);
    _updatePreviewEnhanced(bytes);
  }

  Future<void> _updatePreviewEnhanced(Uint8List originalBytes) async {
    if (_selectedPreset == ProcessingPreset.none) {
      setState(() => _previewEnhanced = originalBytes);
      return;
    }
    try {
      final enhanced = await ImageEnhancer.previewEnhancement(
        imageBytes: originalBytes,
        preset: _selectedPreset,
      );
      if (mounted) setState(() => _previewEnhanced = enhanced);
    } catch (e) {
      // Preview failed, keep showing original
      if (mounted) setState(() => _previewEnhanced = originalBytes);
    }
  }

  Future<void> _processAllPages() async {
    setState(() => _isProcessing = true);
    for (var i = 0; i < _originalPaths.length; i++) {
      if (!mounted) return;
      try {
        if (_selectedPreset == ProcessingPreset.none) {
          _enhancedPaths[i] = _originalPaths[i];
        } else {
          final enhanced = await ImageEnhancer.enhanceImage(
            inputPath: _originalPaths[i],
            preset: _selectedPreset,
          );
          if (mounted) {
            setState(() => _enhancedPaths[i] = enhanced);
          }
        }
      } catch (e) {
        // If enhancement fails, use original
        if (mounted) {
          setState(() => _enhancedPaths[i] = _originalPaths[i]);
        }
      }
    }
    if (mounted) setState(() => _isProcessing = false);
  }

  Future<void> _onPresetChanged(ProcessingPreset preset) async {
    if (preset == _selectedPreset) return;
    setState(() {
      _selectedPreset = preset;
      _enhancedPaths = List.filled(_originalPaths.length, null);
      _previewEnhanced = null;
    });
    if (_previewOriginal != null) {
      _updatePreviewEnhanced(_previewOriginal!);
    }
    _processAllPages();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _loadPreview();
  }

  void _onContinue() {
    // Use enhanced paths where available, fall back to originals
    final paths = List.generate(_originalPaths.length, (i) {
      return _enhancedPaths[i] ?? _originalPaths[i];
    });
    context.push('/scan/pdf-preview', extra: {
      'imagePaths': paths,
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final allDone = !_enhancedPaths.contains(null);

    return Scaffold(
      appBar: AppBar(
        title: Text('Enhance (${_currentPage + 1}/${_originalPaths.length})'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: allDone || _selectedPreset == ProcessingPreset.none
                  ? _onContinue
                  : null,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Image preview with before/after
          Expanded(
            child: GestureDetector(
              onLongPressStart: (_) => setState(() => _showOriginal = true),
              onLongPressEnd: (_) => setState(() => _showOriginal = false),
              child: _buildImagePreview(),
            ),
          ),

          // Processing indicator
          if (_isProcessing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const LinearProgressIndicator(),
                  const SizedBox(height: 4),
                  Text(
                    'Processing ${_enhancedPaths.where((p) => p != null).length}/${_originalPaths.length} pages...',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Hint
          Text(
            'Long press to see original',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),

          const SizedBox(height: 8),

          // Page thumbnails (if multi-page)
          if (_originalPaths.length > 1)
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _originalPaths.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _onPageChanged(i),
                  child: Container(
                    width: 48,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: i == _currentPage
                            ? colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.file(
                            File(_enhancedPaths[i] ?? _originalPaths[i]),
                            fit: BoxFit.cover,
                            width: 48,
                            height: 60,
                          ),
                        ),
                        if (_enhancedPaths[i] == null && _selectedPreset != ProcessingPreset.none)
                          const Positioned.fill(
                            child: Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Preset selector
          _buildPresetSelector(colorScheme),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_previewOriginal == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final displayBytes = _showOriginal ? _previewOriginal! : (_previewEnhanced ?? _previewOriginal!);

    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: InteractiveViewer(
              child: Image.memory(
                displayBytes,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
            ),
          ),
        ),
        // Before/After label
        Positioned(
          top: 24,
          left: 0,
          right: 0,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Container(
                key: ValueKey(_showOriginal),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _showOriginal ? 'Original' : _selectedPreset.label,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetSelector(ColorScheme colorScheme) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: ProcessingPreset.values.map((preset) {
          final isSelected = preset == _selectedPreset;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(preset.label),
              selected: isSelected,
              onSelected: _isProcessing ? null : (_) => _onPresetChanged(preset),
              tooltip: preset.description,
            ),
          );
        }).toList(),
      ),
    );
  }
}
