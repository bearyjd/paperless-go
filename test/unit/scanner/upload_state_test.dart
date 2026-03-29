import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/features/scanner/upload_notifier.dart';

void main() {
  group('UploadState.copyWith', () {
    test('documentId is preserved through status-changing copyWith', () {
      const base = UploadState(
        status: UploadStatus.processing,
        taskId: 'abc',
        documentId: 42,
      );
      final next = base.copyWith(status: UploadStatus.success);
      expect(next.documentId, 42);
    });

    test('documentId is null in default state', () {
      const s = UploadState();
      expect(s.documentId, isNull);
    });

    test('documentId can be set via copyWith', () {
      const s = UploadState(status: UploadStatus.processing);
      final next = s.copyWith(documentId: 7);
      expect(next.documentId, 7);
    });
  });
}
