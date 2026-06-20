import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Maps an error (typically a [DioException]) to a short, user-friendly message.
///
/// Never exposes internals: no server URL, no request/response body, no stack
/// trace, no raw `DioException.toString()`. Screens must interpolate the RESULT
/// of this function, never the raw error object:
///
/// ```dart
/// // SnackBar that keeps an action prefix:
/// Text('Failed to share: ${friendlyApiMessage(e)}')
/// // Full-screen error where the screen implies the action:
/// Text(friendlyApiMessage(err, fallback: 'Failed to load documents.'))
/// ```
String friendlyApiMessage(
  Object? error, {
  String fallback = 'An unexpected error occurred.',
}) {
  // Debug-only breadcrumb: keep the real error visible to developers without
  // ever leaking it into the release UI. assert(...) is stripped in release.
  assert(() {
    if (error != null) debugPrint('API error: $error');
    return true;
  }());
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The server took too long to respond. '
            'Check your connection and try again.';
      case DioExceptionType.connectionError:
        return 'Could not reach the server. Check your connection.';
      case DioExceptionType.badCertificate:
        return "The server's security certificate could not be verified.";
      case DioExceptionType.cancel:
        // Callers that cancel intentionally (navigation, a superseded request)
        // should not render this — it's only meaningful for an unexpected cancel.
        return 'The request was cancelled.';
      case DioExceptionType.badResponse:
        return _messageForStatus(error.response?.statusCode, fallback);
      case DioExceptionType.unknown:
        return fallback;
    }
  }
  return fallback;
}

String _messageForStatus(int? status, String fallback) {
  if (status == null) return fallback;
  if (status == 400 || status == 422) {
    return 'The server rejected the request.';
  }
  if (status == 401 || status == 403) {
    return 'Your session has expired. Please sign in again.';
  }
  if (status == 404) return 'That item could not be found.';
  if (status == 409) {
    return 'This conflicts with the current state — it may have changed.';
  }
  if (status == 413) return 'The file is too large for the server.';
  if (status == 429) {
    return 'Too many requests. Please wait a moment and try again.';
  }
  if (status >= 500 && status < 600) {
    return 'The server had a problem. Please try again.';
  }
  return fallback;
}
