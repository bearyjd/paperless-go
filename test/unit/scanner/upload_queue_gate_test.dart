import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/features/scanner/upload_notifier.dart';

/// Which failures park a document in the upload queue instead of dropping it.
///
/// The regression this guards: a file shared into the app while no server was
/// configured surfaced as a plain failure and was lost. "No server configured"
/// arrives as a StateError from dioProvider, and an unreachable self-hosted
/// hostname arrives as DioExceptionType.unknown wrapping a SocketException —
/// neither is a connectionError, so neither used to be queued.
void main() {
  final request = RequestOptions(path: '/api/documents/post_document/');

  DioException dio(DioExceptionType type, {Object? error}) =>
      DioException(requestOptions: request, type: type, error: error);

  group('queues, so the document survives', () {
    test('no server configured / not authenticated', () {
      expect(
        UploadNotifier.shouldQueueForLater(StateError('Not authenticated')),
        isTrue,
      );
    });

    test('server hostname does not resolve (wrapped SocketException)', () {
      expect(
        UploadNotifier.shouldQueueForLater(
          dio(DioExceptionType.unknown,
              error: const SocketException('Failed host lookup')),
        ),
        isTrue,
      );
    });

    test('a bare SocketException', () {
      expect(
        UploadNotifier.shouldQueueForLater(
          const SocketException('No route to host'),
        ),
        isTrue,
      );
    });

    test('connection error and pre-send timeouts', () {
      expect(
        UploadNotifier.shouldQueueForLater(dio(DioExceptionType.connectionError)),
        isTrue,
      );
      expect(
        UploadNotifier.shouldQueueForLater(
            dio(DioExceptionType.connectionTimeout)),
        isTrue,
      );
      expect(
        UploadNotifier.shouldQueueForLater(dio(DioExceptionType.sendTimeout)),
        isTrue,
      );
    });
  });

  group('does not queue', () {
    test('a server response — a 4xx will not fix itself on retry', () {
      expect(
        UploadNotifier.shouldQueueForLater(dio(DioExceptionType.badResponse)),
        isFalse,
      );
    });

    test('receiveTimeout — the upload was sent, retrying risks a duplicate',
        () {
      expect(
        UploadNotifier.shouldQueueForLater(dio(DioExceptionType.receiveTimeout)),
        isFalse,
      );
    });

    test('a cancelled request or a bad certificate', () {
      expect(
        UploadNotifier.shouldQueueForLater(dio(DioExceptionType.cancel)),
        isFalse,
      );
      expect(
        UploadNotifier.shouldQueueForLater(dio(DioExceptionType.badCertificate)),
        isFalse,
      );
    });

    test('an unknown error that is not a socket failure', () {
      expect(
        UploadNotifier.shouldQueueForLater(
          dio(DioExceptionType.unknown, error: FormatException('bad json')),
        ),
        isFalse,
      );
    });
  });
}
