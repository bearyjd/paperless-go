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
import 'features/custom_fields/custom_fields_screen.dart';
import 'features/workflows/workflow_detail_screen.dart';
import 'features/workflows/workflows_screen.dart';
import 'features/documents/document_detail_screen.dart';
import 'features/documents/document_preview_screen.dart';
import 'features/documents/documents_screen.dart';
import 'features/inbox/inbox_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/login/login_screen.dart';
import 'features/scanner/enhance_screen.dart';
import 'features/scanner/pdf_preview_screen.dart';
import 'features/scanner/scan_review_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/scanner/scanner_screen.dart';
import 'features/scanner/upload_screen.dart';
import 'features/annotate/annotate_screen.dart';
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
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final refreshNotifier = _AuthChangeNotifier(ref);
  ref.onDispose(() => refreshNotifier.dispose());

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64,
                color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text('Page not found',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(state.uri.toString(),
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: () => GoRouter.of(context).go('/'),
              child: const Text('Go home'),
            ),
          ],
        ),
      ),
    ),
    redirect: (context, state) {
      // Intercept Android VIEW intent URIs (content://, file://) before GoRouter
      // tries to treat them as deep link paths and shows "Page not found".
      // Redirect to '/' so the app shell renders and ShareIntentHandler picks up
      // the file via getInitialMedia() in its addPostFrameCallback.
      // Note: GoRouter re-evaluates this redirect for the returned '/' path,
      // so auth guards below still apply on the second pass.
      final scheme = state.uri.scheme;
      if (scheme == 'content' || scheme == 'file') return '/';

      final authState = ref.read(authStateProvider);
      // Don't redirect while auth state is still loading from storage
      if (authState.isLoading && !authState.hasError) return null;
      final isAuthenticated = authState.valueOrNull?.isAuthenticated ?? false;
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
        path: '/workflows',
        builder: (_, __) => const WorkflowsScreen(),
      ),
      GoRoute(
        path: '/custom-fields',
        builder: (_, __) => const CustomFieldsScreen(),
      ),
      GoRoute(
        path: '/workflows/:id',
        builder: (_, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) return const Scaffold(body: Center(child: Text('Invalid workflow ID')));
          return WorkflowDetailScreen(workflowId: id);
        },
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
        path: '/inbox',
        builder: (_, __) => const InboxScreen(),
      ),
      GoRoute(
        path: '/annotate',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) return const Scaffold(body: Center(child: Text('No data')));
          return AnnotateScreen(
            pdfPath: extra['pdfPath'] as String,
            title: extra['title'] as String,
          );
        },
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
        builder: (_, state) {
          final extra = state.extra;
          if (extra is! List) {
            return const Scaffold(body: Center(child: Text('No images provided')));
          }
          return ScanReviewScreen(imagePaths: extra.cast<String>());
        },
      ),
      GoRoute(
        path: '/scan/enhance',
        builder: (_, state) {
          final extra = state.extra;
          if (extra is! List) {
            return const Scaffold(body: Center(child: Text('No images provided')));
          }
          return EnhanceScreen(imagePaths: extra.cast<String>());
        },
      ),
      GoRoute(
        path: '/scan/pdf-preview',
        builder: (_, state) {
          final extra = state.extra;
          if (extra is! Map<String, dynamic>) {
            return const Scaffold(body: Center(child: Text('No images provided')));
          }
          final paths = (extra['imagePaths'] as List<dynamic>).cast<String>();
          final preProcessed = extra['preProcessed'] as bool? ?? false;
          final ocrImagePath = extra['ocrImagePath'] as String?;
          return PdfPreviewScreen(imagePaths: paths, preProcessed: preProcessed, ocrImagePath: ocrImagePath);
        },
      ),
      GoRoute(
        path: '/scan/upload',
        builder: (_, state) {
          final extra = state.extra;
          if (extra is! Map<String, dynamic>) {
            return const Scaffold(body: Center(child: Text('No upload data provided')));
          }
          return UploadScreen(params: extra);
        },
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
          GoRoute(
            path: 'chat',
            builder: (_, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');
              if (id == null) return const Scaffold(body: Center(child: Text('Invalid document ID')));
              final title = state.uri.queryParameters['title'] ?? 'Document $id';
              return ChatScreen(documentId: id, documentTitle: title);
            },
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => _AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
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
  bool _isLocked = false;
  late final _shareIntentHandler = ShareIntentHandler(rootNavigatorKey);
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
    if (state == AppLifecycleState.paused) {
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
            _shareIntentHandler.initialize();
          });
        }
        final content = child ?? const SizedBox.shrink();
        // Always wrap in Stack to avoid widget tree restructuring
        // that causes '_dependents.isEmpty' assertion failures when
        // the biometric lock state changes asynchronously.
        return Stack(
          children: [
            content,
            if (biometricEnabled && _isLocked)
              Positioned.fill(
                child: LockScreen(
                  onUnlocked: () => setState(() => _isLocked = false),
                ),
              ),
          ],
        );
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
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scanner error: $e')),
        );
      }
    }
  }

  Future<void> _onBatchScan() async {
    _toggle();
    try {
      final pictures = await CunningDocumentScanner.getPictures(
        isGalleryImportAllowed: false,
      );
      if (pictures != null && pictures.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scanned ${pictures.length} ${pictures.length == 1 ? 'page' : 'pages'}'),
            duration: const Duration(seconds: 2),
          ),
        );
        GoRouter.of(context).push('/scan/review', extra: pictures);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scanner error: $e')),
        );
      }
    }
  }

  Future<void> _onUploadFile() async {
    _toggle();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'tiff', 'webp'],
      );
      if (result != null && result.files.single.path != null && mounted) {
        final file = result.files.single;
        final ext = file.extension?.toLowerCase();
        final isImage = ext == 'png' || ext == 'jpg' || ext == 'jpeg' ||
            ext == 'tiff' || ext == 'webp';
        GoRouter.of(context).push('/scan/upload', extra: {
          'filePath': file.path!,
          'filename': file.name,
          if (isImage) 'ocrImagePath': file.path!,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File picker error: $e')),
        );
      }
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
                    onTap: _onBatchScan,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Batch scan',
                              style: TextStyle(
                                  color: colorScheme.onSecondaryContainer,
                                  fontSize: 12)),
                          const SizedBox(width: 8),
                          Icon(Icons.burst_mode,
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
