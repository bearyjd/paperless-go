import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/api/api_providers.dart';

class DocumentPreviewScreen extends ConsumerStatefulWidget {
  final int documentId;
  const DocumentPreviewScreen({super.key, required this.documentId});

  @override
  ConsumerState<DocumentPreviewScreen> createState() => _DocumentPreviewScreenState();
}

class _DocumentPreviewScreenState extends ConsumerState<DocumentPreviewScreen> {
  late final PdfControllerPinch _pdfController;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfControllerPinch(
      document: _loadPdf(),
    );
  }

  Future<PdfDocument> _loadPdf() async {
    final api = ref.read(paperlessApiProvider);
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/preview_${widget.documentId}.pdf';
    await api.downloadDocument(widget.documentId, path);
    if (_disposed) throw Exception('Widget disposed during PDF download');
    return PdfDocument.openFile(path);
  }

  @override
  void dispose() {
    _disposed = true;
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: PdfPageNumber(
          controller: _pdfController,
          builder: (context, loadingState, page, pagesCount) =>
              Text(pagesCount != null ? 'Page $page of $pagesCount' : 'Loading...'),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: PdfViewPinch(
        controller: _pdfController,
        padding: 8,
        scrollDirection: Axis.vertical,
        builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
          options: const DefaultBuilderOptions(),
          documentLoaderBuilder: (_) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          pageLoaderBuilder: (_) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          errorBuilder: (_, error) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.white54),
                const SizedBox(height: 16),
                Text('Failed to load PDF',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Text(error.toString(),
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
