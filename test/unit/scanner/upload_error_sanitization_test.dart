import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/api/api_providers.dart';
import 'package:paperless_go/core/api/paperless_api.dart';
import 'package:paperless_go/features/scanner/upload_notifier.dart';

/// Fake API whose upload throws a [DioException] carrying the server host —
/// the exact value that must NOT reach the UI via the stored errorMessage.
class _ThrowingApi extends PaperlessApi {
  _ThrowingApi() : super(Dio());

  @override
  Future<String> uploadDocument({
    required String filePath,
    required String filename,
    String? title,
    int? correspondent,
    int? documentType,
    List<int>? tags,
    DateTime? created,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final opts = RequestOptions(
      path: 'https://secret-host.example.com/api/documents/post_document/',
    );
    throw DioException(
      requestOptions: opts,
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: opts,
        statusCode: 500,
        data: {'detail': 'internal stack trace leak'},
      ),
    );
  }
}

void main() {
  test('upload failure stores a sanitized errorMessage (no URL/internals leak)',
      () async {
    final container = ProviderContainer(
      overrides: [paperlessApiProvider.overrideWithValue(_ThrowingApi())],
    );
    addTearDown(container.dispose);

    final notifier = container.read(uploadNotifierProvider.notifier);
    await notifier.uploadFile(filePath: '/tmp/x.pdf', filename: 'x.pdf');

    final state = container.read(uploadNotifierProvider);
    expect(state.status, UploadStatus.failure);
    expect(state.errorMessage, isNotNull);
    expect(state.errorMessage!.contains('example.com'), isFalse,
        reason: 'server URL leaked into errorMessage');
    expect(state.errorMessage!.contains('/api/'), isFalse);
    expect(state.errorMessage!.contains('DioException'), isFalse);
    expect(state.errorMessage!.contains('stack trace leak'), isFalse);
  });
}
