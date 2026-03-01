import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants.dart';

class DioClient {
  static Dio create(String baseUrl, String token) {
    final normalizedUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final dio = Dio(BaseOptions(
      baseUrl: normalizedUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      followRedirects: true,
      maxRedirects: ApiConstants.maxRedirects,
      validateStatus: (status) => status != null && status >= 200 && status < 300,
      headers: {
        'Accept': ApiConstants.acceptHeader,
        'Authorization': 'Token $token',
      },
    ));

    dio.interceptors.addAll([
      _RetryInterceptor(dio: dio),
      if (kDebugMode)
        LogInterceptor(
          requestHeader: false,
          requestBody: false, // Don't log bodies — may contain PII/credentials
          responseBody: false,
          logPrint: (o) => debugPrint(o.toString()),
        ),
    ]);

    return dio;
  }

  /// Create a Dio instance without auth for login requests.
  static Dio createUnauthenticated(String baseUrl) {
    final normalizedUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    return Dio(BaseOptions(
      baseUrl: normalizedUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      followRedirects: true,
      maxRedirects: ApiConstants.maxRedirects,
      validateStatus: (status) => status != null && status >= 200 && status < 300,
      headers: {
        'Accept': ApiConstants.acceptHeader,
      },
    ));
  }
}

class _RetryInterceptor extends Interceptor {
  final Dio dio;
  static const int _maxRetries = 3;

  _RetryInterceptor({required this.dio});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final currentRetry = (err.requestOptions.extra['retryCount'] as int?) ?? 0;
    if (_shouldRetry(err) && currentRetry < _maxRetries) {
      final nextRetry = currentRetry + 1;
      err.requestOptions.extra['retryCount'] = nextRetry;

      final delay = Duration(milliseconds: 500 * nextRetry);
      await Future.delayed(delay);

      try {
        final response = await dio.fetch(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (e) {
        if (e is DioException) {
          handler.next(e);
          return;
        }
      }
    }
    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    // Only retry idempotent methods (GET, HEAD, OPTIONS) to avoid
    // duplicate side effects on POST/PATCH/DELETE
    final method = err.requestOptions.method.toUpperCase();
    if (method != 'GET' && method != 'HEAD' && method != 'OPTIONS') {
      return false;
    }
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;
  }
}
