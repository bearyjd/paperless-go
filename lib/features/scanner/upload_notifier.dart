import 'dart:async';
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dio/dio.dart';

import '../../core/api/api_providers.dart';
import '../../core/database/cache_provider.dart';
import '../../core/services/notification_service.dart';

part 'upload_notifier.g.dart';

enum UploadStatus { idle, uploading, processing, success, failure, queued }

class UploadState {
  final UploadStatus status;
  final String? taskId;
  final String? errorMessage;
  final double? progress;

  const UploadState({
    this.status = UploadStatus.idle,
    this.taskId,
    this.errorMessage,
    this.progress,
  });

  UploadState copyWith({
    UploadStatus? status,
    String? taskId,
    String? errorMessage,
    double? progress,
  }) {
    return UploadState(
      status: status ?? this.status,
      taskId: taskId ?? this.taskId,
      errorMessage: errorMessage ?? this.errorMessage,
      progress: progress ?? this.progress,
    );
  }
}

@Riverpod(keepAlive: true)
class UploadNotifier extends _$UploadNotifier {
  Timer? _pollTimer;
  bool _disposed = false;

  @override
  UploadState build() {
    _disposed = false;
    ref.onDispose(() {
      _pollTimer?.cancel();
      _disposed = true;
    });
    return const UploadState();
  }

  /// Convert scanned images to a single PDF and upload.
  Future<void> uploadScannedImages({
    required List<String> imagePaths,
    String? title,
    int? correspondent,
    int? documentType,
    List<int>? tags,
    DateTime? created,
  }) async {
    state = const UploadState(status: UploadStatus.uploading);

    String? pdfPath;
    String? safeFilename;
    try {
      pdfPath = await _imagesToPdf(imagePaths);
      safeFilename = _safeFilename(title ?? 'scan');

      final api = ref.read(paperlessApiProvider);
      final taskId = await api.uploadDocument(
        filePath: pdfPath,
        filename: '$safeFilename.pdf',
        title: title,
        correspondent: correspondent,
        documentType: documentType,
        tags: tags,
        created: created,
        onSendProgress: (sent, total) {
          if (total > 0) {
            state = state.copyWith(progress: sent / total);
          }
        },
      );

      // Clean up temp PDF after successful upload
      _deleteTempFile(pdfPath);

      state = UploadState(
        status: UploadStatus.processing,
        taskId: taskId,
      );

      _startPolling(taskId);
    } catch (e) {
      // Clean up temp PDF on failure too (unless queuing for later)
      if (_isNetworkError(e) && pdfPath != null && safeFilename != null) {
        await _enqueueForLater(
          filePath: pdfPath,
          filename: '$safeFilename.pdf',
          title: title,
          correspondent: correspondent,
          documentType: documentType,
          tags: tags,
          created: created,
        );
        return;
      }
      if (pdfPath != null) _deleteTempFile(pdfPath);
      state = UploadState(
        status: UploadStatus.failure,
        errorMessage: e.toString(),
      );
    }
  }

  /// Upload a file directly (from file picker).
  Future<void> uploadFile({
    required String filePath,
    required String filename,
    String? title,
    int? correspondent,
    int? documentType,
    List<int>? tags,
    DateTime? created,
  }) async {
    state = const UploadState(status: UploadStatus.uploading);

    try {
      final api = ref.read(paperlessApiProvider);
      final taskId = await api.uploadDocument(
        filePath: filePath,
        filename: filename,
        title: title,
        correspondent: correspondent,
        documentType: documentType,
        tags: tags,
        created: created,
        onSendProgress: (sent, total) {
          if (total > 0) {
            state = state.copyWith(progress: sent / total);
          }
        },
      );

      state = UploadState(
        status: UploadStatus.processing,
        taskId: taskId,
      );

      _startPolling(taskId);
    } catch (e) {
      if (_isNetworkError(e)) {
        await _enqueueForLater(
          filePath: filePath,
          filename: filename,
          title: title,
          correspondent: correspondent,
          documentType: documentType,
          tags: tags,
          created: created,
        );
        return;
      }
      state = UploadState(
        status: UploadStatus.failure,
        errorMessage: e.toString(),
      );
    }
  }

  bool _isNetworkError(Object e) {
    if (e is DioException) {
      return e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout;
    }
    return false;
  }

  Future<void> _enqueueForLater({
    required String filePath,
    required String filename,
    String? title,
    int? correspondent,
    int? documentType,
    List<int>? tags,
    DateTime? created,
  }) async {
    final cache = ref.read(cacheRepositoryProvider);
    await cache.enqueueUpload(
      filePath: filePath,
      filename: filename,
      title: title,
      correspondent: correspondent,
      documentType: documentType,
      tags: tags,
      created: created,
    );
    state = const UploadState(status: UploadStatus.queued);
  }

  static const _maxPollAttempts = 150; // 150 * 2s = 5 minutes

  void _startPolling(String taskId) {
    _pollTimer?.cancel();
    var attempts = 0;
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_disposed) { timer.cancel(); return; }
      attempts++;
      if (attempts > _maxPollAttempts) {
        timer.cancel();
        state = UploadState(
          status: UploadStatus.failure,
          taskId: taskId,
          errorMessage: 'Processing timed out after 5 minutes. The document may still be processing on the server.',
        );
        return;
      }
      try {
        final api = ref.read(paperlessApiProvider);
        final result = await api.getTaskStatus(taskId);
        final status = result['status'] as String? ?? 'PENDING';

        if (status == 'SUCCESS') {
          timer.cancel();
          state = UploadState(status: UploadStatus.success, taskId: taskId);
          NotificationService.showUploadComplete(
            title: 'Document processed',
            body: 'Your document has been added to Paperless.',
          );
        } else if (status == 'FAILURE') {
          timer.cancel();
          final errorMsg = result['result'] as String? ?? 'Upload processing failed';
          state = UploadState(
            status: UploadStatus.failure,
            taskId: taskId,
            errorMessage: errorMsg,
          );
          NotificationService.showUploadFailed(
            title: 'Document processing failed',
            error: errorMsg,
          );
        }
        // PENDING / STARTED → keep polling
      } catch (_) {
        // Ignore polling errors, keep trying
      }
    });
  }

  void reset() {
    _pollTimer?.cancel();
    state = const UploadState();
  }

  /// Convert a list of image paths to a single PDF file.
  Future<String> _imagesToPdf(List<String> imagePaths) async {
    final dir = await getTemporaryDirectory();
    final pdfPath = '${dir.path}/scan_${DateTime.now().millisecondsSinceEpoch}.pdf';

    // Use the image package to read images and create a simple PDF
    final images = <img.Image>[];
    for (final path in imagePaths) {
      final bytes = await File(path).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded != null) {
        images.add(decoded);
      }
    }

    if (images.isEmpty) {
      throw Exception('No valid images to convert');
    }

    // Continue with successfully decoded images; don't abort the entire scan

    // Create a minimal PDF with embedded images
    final pdfBytes = _buildPdfFromImages(images);
    await File(pdfPath).writeAsBytes(pdfBytes);
    return pdfPath;
  }

  /// Build a minimal PDF from images.
  List<int> _buildPdfFromImages(List<img.Image> images) {
    final buf = <int>[];
    final offsets = <int>[];
    var objCount = 0;

    void write(String s) => buf.addAll(s.codeUnits);

    write('%PDF-1.4\n');

    // For each image, create: image XObject + page
    final pageObjIds = <int>[];
    final imageDataList = <List<int>>[];

    // Encode all images to JPEG first
    for (final image in images) {
      imageDataList.add(img.encodeJpg(image, quality: 85));
    }

    // Object 1: Catalog
    objCount++;
    offsets.add(buf.length);
    write('$objCount 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n');

    // Object 2: Pages (placeholder, will be updated)
    objCount++;
    offsets.add(buf.length);

    // Reserve space — we'll come back to this
    // Actually, let's pre-calculate object IDs
    // Objects: 1=Catalog, 2=Pages, then for each image: ImageXObj, Page
    // So image i: imageObj = 3 + i*2, pageObj = 4 + i*2

    // Reset and rebuild with known IDs
    buf.clear();
    offsets.clear();
    objCount = 0;

    write('%PDF-1.4\n');

    final totalImages = images.length;
    // Obj 1: Catalog
    // Obj 2: Pages
    // For each image i (0-based):
    //   Obj 3+i*2: Image XObject
    //   Obj 4+i*2: Page
    // Total objects: 2 + totalImages * 2

    // Object 1: Catalog
    objCount++;
    offsets.add(buf.length);
    write('1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n');

    // Object 2: Pages
    objCount++;
    offsets.add(buf.length);
    final pageRefs = List.generate(totalImages, (i) => '${4 + i * 2} 0 R').join(' ');
    write('2 0 obj\n<< /Type /Pages /Kids [ $pageRefs ] /Count $totalImages >>\nendobj\n');

    for (var i = 0; i < totalImages; i++) {
      final image = images[i];
      final jpegData = imageDataList[i];
      final imageObjId = 3 + i * 2;
      final pageObjId = 4 + i * 2;

      // A4-ish dimensions: scale image to fit 612x792 points
      final scaleX = 612.0 / image.width;
      final scaleY = 792.0 / image.height;
      final scale = scaleX < scaleY ? scaleX : scaleY;
      final w = (image.width * scale).round();
      final h = (image.height * scale).round();

      // Image XObject
      objCount++;
      offsets.add(buf.length);
      write('$imageObjId 0 obj\n');
      write('<< /Type /XObject /Subtype /Image /Width ${image.width} /Height ${image.height} ');
      write('/ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode ');
      write('/Length ${jpegData.length} >>\nstream\n');
      buf.addAll(jpegData);
      write('\nendstream\nendobj\n');

      // Page
      objCount++;
      offsets.add(buf.length);
      write('$pageObjId 0 obj\n');
      write('<< /Type /Page /Parent 2 0 R /MediaBox [0 0 $w $h] ');
      write('/Contents ${2 + totalImages * 2 + i + 1} 0 R ');
      write('/Resources << /XObject << /Img$i $imageObjId 0 R >> >> >>\n');
      write('endobj\n');

      pageObjIds.add(pageObjId);
    }

    // Content streams for each page
    for (var i = 0; i < totalImages; i++) {
      final image = images[i];
      final scaleX = 612.0 / image.width;
      final scaleY = 792.0 / image.height;
      final scale = scaleX < scaleY ? scaleX : scaleY;
      final w = (image.width * scale).round();
      final h = (image.height * scale).round();

      objCount++;
      offsets.add(buf.length);
      final contentStr = 'q $w 0 0 $h 0 0 cm /Img$i Do Q';
      write('$objCount 0 obj\n<< /Length ${contentStr.length} >>\nstream\n$contentStr\nendstream\nendobj\n');
    }

    // XRef
    final xrefOffset = buf.length;
    write('xref\n0 ${objCount + 1}\n');
    write('0000000000 65535 f \n');
    for (final offset in offsets) {
      write('${offset.toString().padLeft(10, '0')} 00000 n \n');
    }

    write('trailer\n<< /Size ${objCount + 1} /Root 1 0 R >>\n');
    write('startxref\n$xrefOffset\n%%EOF\n');

    return buf;
  }

  String _safeFilename(String name) {
    var safe = name.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    if (safe.isEmpty) safe = 'document';
    return safe;
  }

  void _deleteTempFile(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (_) {
      // Best-effort cleanup
    }
  }
}
