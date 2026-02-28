import 'dart:async';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dio/dio.dart';

import '../../core/api/api_providers.dart';
import '../../core/database/cache_provider.dart';
import '../../core/services/notification_service.dart';
import 'pdf/pdf_generator.dart';

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
    return PdfGenerator.generatePdf(
      imagePaths: imagePaths,
      jpegQuality: 85,
    );
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
