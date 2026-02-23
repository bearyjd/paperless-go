import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/auth/server_profiles.dart';
import '../../core/services/biometric_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiUrl = ref.watch(aiChatUrlProvider);
    final authState = ref.watch(authStateProvider).valueOrNull;
    final themeMode = ref.watch(themeModeNotifierProvider);
    final biometricEnabled = ref.watch(biometricLockProvider);
    final profilesState = ref.watch(serverProfilesNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Account section
          const _SectionHeader(title: 'Account'),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Server'),
            subtitle: Text(authState?.serverUrl ?? 'Not connected'),
          ),

          // Server profiles
          if (profilesState.profiles.length > 1)
            ...profilesState.profiles.asMap().entries.map((entry) {
              final idx = entry.key;
              final profile = entry.value;
              final isActive = idx == profilesState.activeIndex;
              return ListTile(
                leading: Icon(
                  isActive ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isActive ? Theme.of(context).colorScheme.primary : null,
                ),
                title: Text(profile.name.isEmpty ? profile.serverUrl : profile.name),
                subtitle: Text(profile.serverUrl,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: isActive
                    ? null
                    : () => ref
                        .read(serverProfilesNotifierProvider.notifier)
                        .switchToProfile(idx),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => ref
                      .read(serverProfilesNotifierProvider.notifier)
                      .removeProfile(idx),
                ),
              );
            }),

          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Save current server as profile'),
            onTap: () => _addProfile(context, ref),
          ),

          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign out?'),
                  content: const Text('You will need to log in again.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(authStateProvider.notifier).logout();
              }
            },
          ),

          const Divider(),

          // Appearance
          const _SectionHeader(title: 'Appearance'),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            subtitle: Text(_themeModeLabel(themeMode)),
            onTap: () => _showThemePicker(context, ref, themeMode),
          ),

          const Divider(),

          // Security
          const _SectionHeader(title: 'Security'),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint),
            title: const Text('Biometric Lock'),
            subtitle: const Text('Require authentication on app launch'),
            value: biometricEnabled,
            onChanged: (enabled) => _toggleBiometric(context, ref, enabled),
          ),

          const Divider(),

          // AI Chat section
          const _SectionHeader(title: 'AI Chat'),
          ListTile(
            leading: const Icon(Icons.smart_toy),
            title: const Text('Paperless-AI URL'),
            subtitle: Text(
              aiUrl?.isNotEmpty == true ? aiUrl! : 'Not configured',
              style: TextStyle(
                color: aiUrl?.isNotEmpty == true
                    ? null
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: const Icon(Icons.edit, size: 18),
            onTap: () => _editAiUrl(context, ref, aiUrl),
          ),
          ListTile(
            leading: const Icon(Icons.key),
            title: const Text('Paperless-AI Credentials'),
            subtitle: Text(
              ref.watch(aiChatUsernameProvider)?.isNotEmpty == true
                  ? 'Logged in as ${ref.watch(aiChatUsernameProvider)}'
                  : 'Not configured (required for document chat)',
              style: TextStyle(
                color: ref.watch(aiChatUsernameProvider)?.isNotEmpty == true
                    ? null
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: const Icon(Icons.edit, size: 18),
            onTap: () => _editAiCredentials(context, ref),
          ),

          const Divider(),

          // Data management
          const _SectionHeader(title: 'Data'),
          ListTile(
            leading: const Icon(Icons.label_outline),
            title: const Text('Manage Labels'),
            subtitle: const Text('Tags, correspondents, document types'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/labels'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Trash'),
            subtitle: const Text('View and restore deleted documents'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/trash'),
          ),

          const Divider(),

          // About
          const _SectionHeader(title: 'About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Paperless Go'),
            subtitle: Text('v1.0.0'),
          ),
        ],
      ),
    );
  }

  void _addProfile(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Server Profile'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Profile name',
            hintText: 'e.g., Home Server',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(serverProfilesNotifierProvider.notifier)
                    .addCurrentAsProfile(name);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  String _themeModeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => 'System default',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };
  }

  void _showThemePicker(BuildContext context, WidgetRef ref, ThemeMode current) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Theme'),
        children: ThemeMode.values.map((mode) {
          return ListTile(
            leading: Icon(
              mode == current ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: mode == current ? Theme.of(ctx).colorScheme.primary : null,
            ),
            title: Text(_themeModeLabel(mode)),
            onTap: () {
              ref.read(themeModeNotifierProvider.notifier).setThemeMode(mode);
              Navigator.pop(ctx);
            },
          );
        }).toList(),
      ),
    );
  }

  Future<void> _toggleBiometric(
      BuildContext context, WidgetRef ref, bool enabled) async {
    if (enabled) {
      final biometricService = BiometricService();
      final isAvailable = await biometricService.isAvailable();
      if (!isAvailable) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Biometric authentication is not available on this device')),
          );
        }
        return;
      }
      // Verify biometric before enabling
      final authenticated = await biometricService.authenticate(
        reason: 'Verify to enable biometric lock',
      );
      if (!authenticated || !context.mounted) return;
    }
    ref.read(biometricLockProvider.notifier).setEnabled(enabled);
  }

  void _editAiCredentials(BuildContext context, WidgetRef ref) {
    final usernameController = TextEditingController(
      text: ref.read(aiChatUsernameProvider) ?? '',
    );
    final passwordController = TextEditingController(
      text: ref.read(aiChatPasswordProvider) ?? '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Paperless-AI Credentials'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your Paperless-AI login credentials. Required for document chat.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: usernameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(aiChatUsernameProvider.notifier).set(usernameController.text.trim());
              ref.read(aiChatPasswordProvider.notifier).set(passwordController.text);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((_) {
      usernameController.dispose();
      passwordController.dispose();
    });
  }

  void _editAiUrl(BuildContext context, WidgetRef ref, String? currentUrl) {
    final controller = TextEditingController(text: currentUrl ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Paperless-AI URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the URL of your Paperless-AI instance (e.g., http://192.168.1.21:8083)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'http://192.168.1.21:8083',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(aiChatUrlProvider.notifier).setUrl(controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
