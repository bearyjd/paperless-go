import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'auth_provider.dart';

part 'server_profiles.g.dart';

class ServerProfile {
  final String name;
  final String serverUrl;
  final String token;

  const ServerProfile({
    required this.name,
    required this.serverUrl,
    required this.token,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'serverUrl': serverUrl,
        'token': token,
      };

  factory ServerProfile.fromJson(Map<String, dynamic> json) => ServerProfile(
        name: json['name'] as String? ?? '',
        serverUrl: json['serverUrl'] as String? ?? '',
        token: json['token'] as String? ?? '',
      );
}

class ServerProfilesState {
  final List<ServerProfile> profiles;
  final int activeIndex;

  const ServerProfilesState({
    this.profiles = const [],
    this.activeIndex = 0,
  });

  ServerProfile? get activeProfile =>
      profiles.isNotEmpty && activeIndex < profiles.length
          ? profiles[activeIndex]
          : null;
}

@Riverpod(keepAlive: true)
class ServerProfilesNotifier extends _$ServerProfilesNotifier {
  bool _loaded = false;

  @override
  ServerProfilesState build() {
    if (!_loaded) {
      _loaded = true;
      _loadProfiles();
    }
    return const ServerProfilesState();
  }

  Future<void> _loadProfiles() async {
    final storage = ref.read(secureStorageProvider);
    final json = await storage.getServerProfiles();
    final activeIdx = await storage.getActiveProfileIndex();

    if (json != null && json.isNotEmpty) {
      try {
        final list = (jsonDecode(json) as List<dynamic>)
            .map((e) => ServerProfile.fromJson(e as Map<String, dynamic>))
            .toList();
        state = ServerProfilesState(
          profiles: list,
          activeIndex: activeIdx.clamp(0, list.isEmpty ? 0 : list.length - 1),
        );
      } catch (_) {
        // Corrupted data, start fresh
      }
    }
  }

  Future<void> _save() async {
    final storage = ref.read(secureStorageProvider);
    final json = jsonEncode(state.profiles.map((p) => p.toJson()).toList());
    await storage.saveServerProfiles(json);
    await storage.saveActiveProfileIndex(state.activeIndex);
  }

  /// Add current session as a profile.
  Future<void> addCurrentAsProfile(String name) async {
    final authStatus = ref.read(authStateProvider).valueOrNull;
    if (authStatus == null || !authStatus.isAuthenticated) return;

    final profile = ServerProfile(
      name: name,
      serverUrl: authStatus.serverUrl!,
      token: authStatus.token!,
    );

    final profiles = [...state.profiles, profile];
    state = ServerProfilesState(
      profiles: profiles,
      activeIndex: profiles.length - 1,
    );
    await _save();
  }

  /// Add a profile directly.
  Future<void> addProfile(ServerProfile profile) async {
    final profiles = [...state.profiles, profile];
    state = ServerProfilesState(
      profiles: profiles,
      activeIndex: state.activeIndex,
    );
    await _save();
  }

  /// Switch to a different profile and re-authenticate.
  Future<void> switchToProfile(int index) async {
    if (index < 0 || index >= state.profiles.length) return;
    final profile = state.profiles[index];

    state = ServerProfilesState(
      profiles: state.profiles,
      activeIndex: index,
    );
    await _save();

    // Re-login with the profile's token
    await ref.read(authStateProvider.notifier).loginWithToken(
          profile.serverUrl,
          profile.token,
        );
  }

  /// Remove a profile.
  Future<void> removeProfile(int index) async {
    if (index < 0 || index >= state.profiles.length) return;

    final wasActive = index == state.activeIndex;
    final profiles = [...state.profiles]..removeAt(index);
    var activeIdx = state.activeIndex;
    if (activeIdx >= profiles.length && profiles.isNotEmpty) {
      activeIdx = profiles.length - 1;
    }

    state = ServerProfilesState(
      profiles: profiles,
      activeIndex: activeIdx,
    );
    await _save();

    // Re-auth with the new active profile, or logout if none remain
    if (profiles.isEmpty) {
      await ref.read(authStateProvider.notifier).logout();
    } else if (wasActive) {
      final profile = profiles[activeIdx];
      await ref.read(authStateProvider.notifier).loginWithToken(
            profile.serverUrl,
            profile.token,
          );
    }
  }

  /// Update a profile name.
  Future<void> renameProfile(int index, String newName) async {
    if (index < 0 || index >= state.profiles.length) return;

    final profiles = [...state.profiles];
    final old = profiles[index];
    profiles[index] = ServerProfile(
      name: newName,
      serverUrl: old.serverUrl,
      token: old.token,
    );

    state = ServerProfilesState(
      profiles: profiles,
      activeIndex: state.activeIndex,
    );
    await _save();
  }
}
