import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../api/dio_client.dart';
import '../database/cache_provider.dart';
import 'auth_service.dart';
import 'secure_storage.dart';

part 'auth_provider.g.dart';

@riverpod
SecureStorageService secureStorage(Ref ref) => SecureStorageService();

@riverpod
AuthService authService(Ref ref) =>
    AuthService(storage: ref.watch(secureStorageProvider));

@riverpod
class AuthState extends _$AuthState {
  @override
  Future<AuthStatus> build() async {
    final authService = ref.watch(authServiceProvider);
    final credentials = await authService.getSavedCredentials();
    if (credentials != null) {
      return AuthStatus.authenticated(
        serverUrl: credentials.serverUrl,
        token: credentials.token,
      );
    }
    return const AuthStatus.unauthenticated();
  }

  Future<void> loginWithCredentials(String serverUrl, String username, String password) async {
    state = const AsyncLoading();
    try {
      final authService = ref.read(authServiceProvider);
      final token = await authService.loginWithCredentials(serverUrl, username, password);
      state = AsyncData(AuthStatus.authenticated(serverUrl: serverUrl, token: token));
    } catch (e) {
      state = const AsyncData(AuthStatus.unauthenticated());
      rethrow;
    }
  }

  Future<void> loginWithToken(String serverUrl, String token) async {
    state = const AsyncLoading();
    try {
      final authService = ref.read(authServiceProvider);
      await authService.loginWithToken(serverUrl, token);
      state = AsyncData(AuthStatus.authenticated(serverUrl: serverUrl, token: token));
    } catch (e) {
      state = const AsyncData(AuthStatus.unauthenticated());
      rethrow;
    }
  }

  Future<void> logout() async {
    final authService = ref.read(authServiceProvider);
    try {
      final cache = ref.read(cacheRepositoryProvider);
      await cache.clearAll();
    } catch (_) {
      // Cache may not be initialized yet
    }
    await authService.logout();
    state = const AsyncData(AuthStatus.unauthenticated());
  }
}

/// Provides an authenticated Dio instance. Throws if not authenticated.
/// Closes the previous instance when auth state changes.
@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final authStatus = ref.watch(authStateProvider).valueOrNull;
  if (authStatus == null || !authStatus.isAuthenticated) {
    throw StateError('Not authenticated');
  }
  final dio = DioClient.create(authStatus.serverUrl!, authStatus.token!);
  ref.onDispose(() => dio.close());
  return dio;
}

sealed class AuthStatus {
  const AuthStatus();
  const factory AuthStatus.authenticated({
    required String serverUrl,
    required String token,
  }) = Authenticated;
  const factory AuthStatus.unauthenticated() = Unauthenticated;

  bool get isAuthenticated => this is Authenticated;
  String? get serverUrl => switch (this) {
    Authenticated(:final serverUrl) => serverUrl,
    _ => null,
  };
  String? get token => switch (this) {
    Authenticated(:final token) => token,
    _ => null,
  };
}

class Authenticated extends AuthStatus {
  @override
  final String serverUrl;
  @override
  final String token;
  const Authenticated({required this.serverUrl, required this.token});
}

class Unauthenticated extends AuthStatus {
  const Unauthenticated();
}

@riverpod
class AiChatUrl extends _$AiChatUrl {
  bool _userChanged = false;

  @override
  String? build() {
    _userChanged = false;
    _loadUrl();
    return null;
  }

  Future<void> _loadUrl() async {
    final storage = ref.read(secureStorageProvider);
    final url = await storage.getAiChatUrl();
    if (!_userChanged && url != null && url.isNotEmpty) {
      state = url;
    }
  }

  Future<void> setUrl(String url) async {
    _userChanged = true;
    final storage = ref.read(secureStorageProvider);
    await storage.saveAiChatUrl(url);
    state = url.isEmpty ? null : url;
  }
}

@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  bool _userChanged = false;

  @override
  ThemeMode build() {
    _userChanged = false;
    _loadThemeMode();
    return ThemeMode.system;
  }

  Future<void> _loadThemeMode() async {
    final storage = ref.read(secureStorageProvider);
    final mode = await storage.getThemeMode();
    if (!_userChanged && mode != null) {
      state = ThemeMode.values.firstWhere(
        (m) => m.name == mode,
        orElse: () => ThemeMode.system,
      );
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _userChanged = true;
    final storage = ref.read(secureStorageProvider);
    await storage.saveThemeMode(mode.name);
    state = mode;
  }
}

@riverpod
class BiometricLock extends _$BiometricLock {
  bool _userChanged = false;

  @override
  bool build() {
    _userChanged = false;
    _loadSetting();
    return false;
  }

  Future<void> _loadSetting() async {
    final storage = ref.read(secureStorageProvider);
    final enabled = await storage.getBiometricLock();
    if (!_userChanged) {
      state = enabled;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    _userChanged = true;
    final storage = ref.read(secureStorageProvider);
    await storage.saveBiometricLock(enabled);
    state = enabled;
  }
}
