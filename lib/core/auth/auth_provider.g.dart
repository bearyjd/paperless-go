// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$secureStorageHash() => r'9005f3948067dc99e23856b40aa14612f85932cf';

/// See also [secureStorage].
@ProviderFor(secureStorage)
final secureStorageProvider =
    AutoDisposeProvider<SecureStorageService>.internal(
      secureStorage,
      name: r'secureStorageProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$secureStorageHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SecureStorageRef = AutoDisposeProviderRef<SecureStorageService>;
String _$authServiceHash() => r'eab008beac96e459972191badcdfb6b03b131ed8';

/// See also [authService].
@ProviderFor(authService)
final authServiceProvider = AutoDisposeProvider<AuthService>.internal(
  authService,
  name: r'authServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthServiceRef = AutoDisposeProviderRef<AuthService>;
String _$dioHash() => r'd9465f2619e7b4985ce531fad4c779897f2ce107';

/// Provides an authenticated Dio instance. Throws if not authenticated.
/// Closes the previous instance when auth state changes.
///
/// Copied from [dio].
@ProviderFor(dio)
final dioProvider = Provider<Dio>.internal(
  dio,
  name: r'dioProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dioHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DioRef = ProviderRef<Dio>;
String _$authStateHash() => r'd155cad7e13cb4eb541f84127a8bcde358ea1502';

/// See also [AuthState].
@ProviderFor(AuthState)
final authStateProvider =
    AutoDisposeAsyncNotifierProvider<AuthState, AuthStatus>.internal(
      AuthState.new,
      name: r'authStateProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$authStateHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AuthState = AutoDisposeAsyncNotifier<AuthStatus>;
String _$aiChatUrlHash() => r'9799c319afb7644716c0d7a9bf08fc49890f1c2e';

/// See also [AiChatUrl].
@ProviderFor(AiChatUrl)
final aiChatUrlProvider =
    AutoDisposeNotifierProvider<AiChatUrl, String?>.internal(
      AiChatUrl.new,
      name: r'aiChatUrlProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$aiChatUrlHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AiChatUrl = AutoDisposeNotifier<String?>;
String _$aiChatUsernameHash() => r'88379c2ab3a199eee5ec786b8485ceb68456da63';

/// See also [AiChatUsername].
@ProviderFor(AiChatUsername)
final aiChatUsernameProvider =
    AutoDisposeNotifierProvider<AiChatUsername, String?>.internal(
      AiChatUsername.new,
      name: r'aiChatUsernameProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$aiChatUsernameHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AiChatUsername = AutoDisposeNotifier<String?>;
String _$aiChatPasswordHash() => r'c6d42bfff4af92fe41ed0568ec5cc911b90089ed';

/// See also [AiChatPassword].
@ProviderFor(AiChatPassword)
final aiChatPasswordProvider =
    AutoDisposeNotifierProvider<AiChatPassword, String?>.internal(
      AiChatPassword.new,
      name: r'aiChatPasswordProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$aiChatPasswordHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AiChatPassword = AutoDisposeNotifier<String?>;
String _$themeModeNotifierHash() => r'3c2093caf09a2166a1fcf0dc1acf9decaba14e4b';

/// See also [ThemeModeNotifier].
@ProviderFor(ThemeModeNotifier)
final themeModeNotifierProvider =
    AutoDisposeNotifierProvider<ThemeModeNotifier, ThemeMode>.internal(
      ThemeModeNotifier.new,
      name: r'themeModeNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$themeModeNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ThemeModeNotifier = AutoDisposeNotifier<ThemeMode>;
String _$biometricLockHash() => r'a9192c544c9a05260c7105288ebcadb8d4bc7499';

/// See also [BiometricLock].
@ProviderFor(BiometricLock)
final biometricLockProvider =
    AutoDisposeNotifierProvider<BiometricLock, bool>.internal(
      BiometricLock.new,
      name: r'biometricLockProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$biometricLockHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$BiometricLock = AutoDisposeNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
