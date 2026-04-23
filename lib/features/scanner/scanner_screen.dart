import 'document_scanner.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ScannerScreen extends ConsumerWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan & Upload'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Icon(
              Icons.document_scanner_outlined,
              size: 80,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Add a document',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Scan a physical document or upload an existing file',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            // Scan Document
            _ScanOptionCard(
              icon: Icons.camera_alt,
              title: 'Scan Document',
              subtitle: 'Quick scan with gallery import',
              color: colorScheme.primary,
              onColor: colorScheme.onPrimary,
              onTap: () => _startScan(context),
            ),
            const SizedBox(height: 12),
            // Batch Scan
            _ScanOptionCard(
              icon: Icons.burst_mode,
              title: 'Batch Scan',
              subtitle: 'Scan multiple pages continuously',
              color: colorScheme.secondaryContainer,
              onColor: colorScheme.onSecondaryContainer,
              onTap: () => _startBatchScan(context),
            ),
            const SizedBox(height: 12),
            // Upload File
            OutlinedButton.icon(
              onPressed: () => _pickFile(context),
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload File'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startScan(BuildContext context) async {
    try {
      final images = await DocumentScanner.getPictures(
        isGalleryImportAllowed: true,
      );
      if (images != null && images.isNotEmpty && context.mounted) {
        context.push('/scan/review', extra: images);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scanner error: $e')),
        );
      }
    }
  }

  Future<void> _startBatchScan(BuildContext context) async {
    try {
      final images = await DocumentScanner.getPictures(
        isGalleryImportAllowed: false,
      );
      if (images != null && images.isNotEmpty && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scanned ${images.length} ${images.length == 1 ? 'page' : 'pages'}'),
            duration: const Duration(seconds: 2),
          ),
        );
        context.push('/scan/review', extra: images);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scanner error: $e')),
        );
      }
    }
  }

  Future<void> _pickFile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'tiff', 'webp'],
      );
      if (result != null && result.files.single.path != null && context.mounted) {
        final file = result.files.single;
        context.push('/scan/upload', extra: {
          'filePath': file.path!,
          'filename': file.name,
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File picker error: $e')),
        );
      }
    }
  }
}

class _ScanOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color onColor;
  final VoidCallback onTap;

  const _ScanOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: onColor, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: onColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: onColor.withValues(alpha: 0.8),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: onColor.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}
