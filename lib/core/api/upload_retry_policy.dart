import 'dart:io';

import 'package:dio/dio.dart';

import '../auth/auth_provider.dart';

/// Whether a failure means "we could not reach the server", as opposed to
/// "the server rejected this document".
///
/// Two callers depend on this distinction and they must agree, which is why it
/// lives in core rather than beside either of them:
///
///  - the upload screen parks the document in the queue instead of showing a
///    dead end;
///  - the drain records the error WITHOUT consuming a retry, because five
///    launches out of signal must not terminally fail a good upload.
///
/// Covered:
///  - transport failures dio types explicitly (`connectionError`,
///    `connectionTimeout`, `sendTimeout`);
///  - `DioExceptionType.unknown` wrapping a `SocketException` — DNS failure
///    against a self-hosted hostname is the single most likely way this app
///    fails to reach its server;
///  - [NotAuthenticatedException] from `dioProvider`: no server configured, or
///    no session. Deliberately a named type — matching bare `StateError` would
///    also swallow every unrelated bad-state bug into a silent retry loop.
///
/// Excluded: `badResponse` (the server answered; a 4xx will not fix itself) and
/// `receiveTimeout` (the body was fully sent, so a retry risks a duplicate).
///
/// Note the duplicate risk is not exclusive to `receiveTimeout`: a connection
/// reset mid-transfer can also land after the server accepted the body. Those
/// are queued anyway — losing the document is worse than uploading it twice —
/// but that is a judgement call, not a guarantee of exactly-once.
bool isUnreachableServerError(Object e) {
  if (e is NotAuthenticatedException) return true;
  if (e is SocketException) return true;
  if (e is DioException) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
        return true;
      case DioExceptionType.unknown:
        return e.error is SocketException;
      case DioExceptionType.badResponse:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
        return false;
    }
  }
  return false;
}
