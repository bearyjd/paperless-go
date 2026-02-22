import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'core/auth/auth_provider.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/upload_queue_service.dart';
import 'core/theme.dart';
import 'features/login/lock_screen.dart';
import 'features/upload/share_intent_handler.dart';
import 'features/ai_chat/chat_screen.dart';
import 'features/labels/labels_screen.dart';
import 'features/search/search_screen.dart';
import 'features/documents/document_detail_screen.dart';
import 'features/documents/document_preview_screen.dart';
import 'features/documents/documents_screen.dart';
import 'features/inbox/inbox_screen.dart';
import 'features/login/login_screen.dart';
import 'features/scanner/scan_review_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/scanner/scanner_screen.dart';
import 'features/scanner/upload_screen.dart';
import 'features/search/similar_screen.dart';
import 'features/trash/trash_screen.dart';

part 'app.g.dart';

/// A ChangeNotifier that triggers GoRouter refreshes when auth state changes.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final refreshNotifier = _AuthChangeNotifier(ref);
  ref.onDispose(() => refreshNotifier.dispose());

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authStatus = ref.read(authStateProvider).valueOrNull;
      final isAuthenticated = authStatus?.isAuthenticated ?? false;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isAuthenticated && !isLoginRoute) return '/login';
      if (isAuthenticated && isLoginRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/search',
        builder: (_, __) => const SearchScreen(),
      ),
      GoRoute(
        path: '/labels',
        builder: (_, __) => const LabelsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/trash',
        builder: (_, __) => const TrashScreen(),
      ),
      GoRoute(
        path: '/search/similar/:id',
        builder: (_, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) return const Scaffold(body: Center(child: Text('Invalid ID')));
          return SimilarScreen(documentId: id);
        },
      ),
      GoRoute(
        path: '/scan/review',
        builder: (_, state) => ScanReviewScreen(
          imagePaths: (state.extra as List<dynamic>).cast<String>(),
        ),
      ),
      GoRoute(
        path: '/scan/upload',
        builder: (_, state) => UploadScreen(
          params: state.extra as Map<String, dynamic>,
        ),
      ),
      GoRoute(
        path: '/documents/:id',
        builder: (_, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) return const Scaffold(body: Center(child: Text('Invalid document ID')));
          return DocumentDetailScreen(documentId: id);
        },
        routes: [
          GoRoute(
            path: 'preview',
            builder: (_, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');
              if (id == null) return const Scaffold(body: Center(child: Text('Invalid document ID')));
              return DocumentPreviewScreen(documentId: id);
            },
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => _AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const InboxScreen()),
          GoRoute(path: '/documents', builder: (_, __) => const DocumentsScreen()),
          GoRoute(path: '/scan', builder: (_, __) => const ScannerScreen()),
          GoRoute(path: '/chat', builder: (_, __) => const ChatScreen()),
        ],
      ),
    ],
  );
}

class PaperlessGoApp extends ConsumerStatefulWidget {
  const PaperlessGoApp({super.key});

  @override
  ConsumerState<PaperlessGoApp> createState() => _PaperlessGoAppState();
}

class _PaperlessGoAppState extends ConsumerState<PaperlessGoApp>
    with WidgetsBindingObserver {
  bool _isLocked = true;
  final _shareIntentHandler = ShareIntentHandler();
  bool _shareIntentInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _shareIntentHandler.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-lock when app goes to background
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      final biometricEnabled = ref.read(biometricLockProvider);
      if (biometricEnabled) {
        setState(() => _isLocked = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeNotifierProvider);
    final biometricEnabled = ref.watch(biometricLockProvider);

    // Show lock screen if biometric is enabled and app is locked
    if (biometricEnabled && _isLocked) {
      return MaterialApp(
        title: 'Paperless Go',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        debugShowCheckedModeBanner: false,
        home: LockScreen(
          onUnlocked: () => setState(() => _isLocked = false),
        ),
      );
    }

    return MaterialApp.router(
      title: 'Paperless Go',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Initialize share intent handler once
        if (!_shareIntentInitialized) {
          _shareIntentInitialized = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              _shareIntentHandler.initialize(context);
            }
          });
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}

class _AppShell extends ConsumerWidget {
  final Widget child;
  const _AppShell({required this.child});

  static int _indexFromLocation(String location) {
    if (location.startsWith('/documents')) return 1;
    if (location.startsWith('/scan')) return 2;
    if (location.startsWith('/chat')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexFromLocation(location);
    final isOnline = ref.watch(connectivityNotifierProvider);

    // Keep upload queue service alive
    ref.watch(uploadQueueServiceProvider);

    return Scaffold(
      body: Column(
        children: [
          if (!isOnline)
            MaterialBanner(
              content: const Text('No internet connection'),
              leading: const Icon(Icons.cloud_off),
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              actions: const [SizedBox.shrink()],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          Expanded(child: child),
        ],
      ),
      floatingActionButton: (currentIndex == 0 || currentIndex == 1)
          ? _SpeedDialFab(currentIndex: currentIndex)
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0: context.go('/');
            case 1: context.go('/documents');
            case 2: context.go('/scan');
            case 3: context.go('/chat');
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.inbox), label: 'Inbox'),
          NavigationDestination(icon: Icon(Icons.description_outlined), label: 'Docs'),
          NavigationDestination(icon: Icon(Icons.document_scanner_outlined), label: 'Scan'),
          NavigationDestination(icon: Icon(Icons.chat_outlined), label: 'Chat'),
        ],
      ),
    );
  }
}

class _SpeedDialFab extends StatefulWidget {
  final int currentIndex;
  const _SpeedDialFab({required this.currentIndex});

  @override
  State<_SpeedDialFab> createState() => _SpeedDialFabState();
}

class _SpeedDialFabState extends State<_SpeedDialFab>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  Future<void> _onScan() async {
    _toggle();
    try {
      final pictures = await CunningDocumentScanner.getPictures();
      if (pictures != null && pictures.isNotEmpty && mounted) {
        GoRouter.of(context).push('/scan/review', extra: pictures);
      }
    } catch (_) {
      // User cancelled or error
    }
  }

  Future<void> _onUploadFile() async {
    _toggle();
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null && mounted) {
        final file = result.files.single;
        GoRouter.of(context).push('/scan/upload', extra: {
          'filePath': file.path!,
          'filename': file.name,
        });
      }
    } catch (_) {
      // User cancelled or error
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Mini FABs
        ScaleTransition(
          scale: _animation,
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _onUploadFile,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Upload file',
                              style: TextStyle(
                                  color: colorScheme.onSecondaryContainer,
                                  fontSize: 12)),
                          const SizedBox(width: 8),
                          Icon(Icons.upload_file,
                              size: 20,
                              color: colorScheme.onSecondaryContainer),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ScaleTransition(
          scale: _animation,
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _onScan,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Scan',
                              style: TextStyle(
                                  color: colorScheme.onSecondaryContainer,
                                  fontSize: 12)),
                          const SizedBox(width: 8),
                          Icon(Icons.document_scanner_outlined,
                              size: 20,
                              color: colorScheme.onSecondaryContainer),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Main FAB
        FloatingActionButton(
          onPressed: _toggle,
          child: AnimatedRotation(
            turns: _isOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
