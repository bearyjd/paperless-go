import 'package:dio/dio.dart';
import '../api/dio_client.dart';
import 'secure_storage.dart';

class AuthService {
  final SecureStorageService _storage;

  AuthService({SecureStorageService? storage})
      : _storage = storage ?? SecureStorageService();

  /// Login with username/password, returns the API token.
  Future<String> loginWithCredentials(String serverUrl, String username, String password) async {
    final dio = DioClient.createUnauthenticated(serverUrl);
    try {
      final response = await dio.post(
        'api/token/',
        data: {'username': username, 'password': password},
      );
      final token = response.data['token'] as String?;
      if (token == null) throw AuthException('No token in response');
      await _storage.saveServerUrl(serverUrl);
      await _storage.saveApiToken(token);
      await _storage.saveUsername(username);
      return token;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 || e.response?.statusCode == 401) {
        throw AuthException('Invalid username or password');
      }
      throw AuthException('Connection failed: ${e.message}');
    }
  }

  /// Login with a pre-existing API token.
  Future<void> loginWithToken(String serverUrl, String token) async {
    final dio = DioClient.create(serverUrl, token);
    try {
      await dio.get('api/statistics/');
      await _storage.saveServerUrl(serverUrl);
      await _storage.saveApiToken(token);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw AuthException('Invalid or expired token');
      }
      throw AuthException('Connection failed: ${e.message}');
    }
  }

  /// Test connection to server (unauthenticated).
  Future<bool> testConnection(String serverUrl) async {
    try {
      final dio = DioClient.createUnauthenticated(serverUrl);
      // A reachable Paperless-ngx server returns 200 or throws 401/403
      await dio.get('api/');
      return true;
    } on DioException catch (e) {
      // 401/403 means the server IS reachable (just needs auth)
      final status = e.response?.statusCode;
      return status == 401 || status == 403;
    } catch (_) {
      return false;
    }
  }

  /// Check if we have saved credentials.
  Future<bool> isAuthenticated() async {
    final token = await _storage.getApiToken();
    final url = await _storage.getServerUrl();
    return token != null && url != null;
  }

  Future<({String serverUrl, String token})?> getSavedCredentials() async {
    final token = await _storage.getApiToken();
    final url = await _storage.getServerUrl();
    if (token != null && url != null) {
      return (serverUrl: url, token: token);
    }
    return null;
  }

  Future<void> logout() => _storage.clearAll();
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
