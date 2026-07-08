import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'core/auth/auth_provider.dart';
import 'core/router/scan_route_args.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/edit_queue_processor.dart';
import 'core/services/upload_queue_service.dart';
import 'core/design_tokens.dart';
import 'core/theme.dart';
import 'features/login/lock_screen.dart';
import 'features/upload/share_intent_handler.dart';
import 'features/ai_chat/chat_screen.dart';
import 'features/labels/labels_screen.dart';
import 'features/search/search_screen.dart';
import 'features/custom_fields/custom_fields_screen.dart';
import 'features/templates/templates_screen.dart';
import 'features/workflows/workflow_detail_screen.dart';
import 'features/workflows/workflows_screen.dart';
import 'features/documents/document_detail_screen.dart';
import 'features/documents/document_preview_screen.dart';
import 'features/documents/documents_screen.dart';
import 'features/inbox/inbox_screen.dart';
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
    initialLocation: '/inbox',
    refreshListenable: refreshNotifier,
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64,
                color: Theme.of(context).colorScheme.error),
            const SizedBox(height: Spacing.lg),
            Text('Page not found',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Spacing.sm),
            Text(state.uri.toString(),
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: Spacing.xl),
            FilledButton.tonal(
              onPressed: () => GoRouter.of(context).go('/inbox'),
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
      if (scheme == 'paperlessgo') {
        final path = state.uri.host;
        if (path == 'scan') return '/scan';
        if (path == 'upload') return '/scan';
        return '/';
      }

      // Dashboard was retired in the redesign; '/' now lands on Inbox (the
      // highest-frequency workflow). Keeping the redirect (rather than
      // deleting the path) preserves old deep links and widget intents.
      if (state.uri.path == '/') return '/inbox';

      final authState = ref.read(authStateProvider);
      // Don't redirect while auth state is still loading from storage
      if (authState.isLoading && !authState.hasError) return null;
      final isAuthenticated = authState.valueOrNull?.isAuthenticated ?? false;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isAuthenticated && !isLoginRoute) return '/login';
      if (isAuthenticated && isLoginRoute) return '/inbox';
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
        path: '/templates',
        builder: (_, __) => const TemplatesScreen(),
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
          final args = parsePdfPreviewArgs(state.extra);
          if (args == null) {
            return const Scaffold(body: Center(child: Text('No images provided')));
          }
          return PdfPreviewScreen(
            imagePaths: args.imagePaths,
            preProcessed: args.preProcessed,
            ocrImagePath: args.ocrImagePath,
          );
        },
      ),
      GoRoute(
        path: '/scan/upload',
        builder: (_, state) {
          final params = parseUploadArgs(state.extra);
          if (params == null) {
            return const Scaffold(body: Center(child: Text('No upload data provided')));
          }
          return UploadScreen(params: params);
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
          GoRoute(path: '/inbox', builder: (_, __) => const InboxScreen()),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final isOnline = ref.watch(connectivityNotifierProvider);

    // Keep upload queue service alive
    ref.watch(uploadQueueServiceProvider);
    // Keep edit queue processor alive; re-runs when connectivity changes
    ref.watch(editQueueProcessorProvider);

    return Scaffold(
      body: Column(
        children: [
          if (!isOnline)
            MaterialBanner(
              content: const Text('No internet connection'),
              leading: const Icon(Icons.cloud_off),
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              actions: const [SizedBox.shrink()],
              padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.lg, vertical: Spacing.sm),
            ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: _ShellNavBar(location: location),
    );
  }
}

/// Redesigned bottom nav: 3 destinations (Inbox, Library, Chat) plus a
/// raised circular accent-filled Scan button in the center — the single
/// visually-elevated primary action of the shell.
class _ShellNavBar extends StatelessWidget {
  const _ShellNavBar({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final onScan = location.startsWith('/scan');

    return Container(
      decoration: BoxDecoration(
        color: tokens.card,
        border: Border(top: BorderSide(color: tokens.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.inbox_outlined,
                selectedIcon: Icons.inbox,
                label: 'Inbox',
                selected: location.startsWith('/inbox'),
                onTap: () => context.go('/inbox'),
              ),
              _NavItem(
                icon: Icons.folder_outlined,
                selectedIcon: Icons.folder,
                label: 'Library',
                selected: location.startsWith('/documents'),
                onTap: () => context.go('/documents'),
              ),
              Expanded(
                child: Center(
                  child: Transform.translate(
                    offset: const Offset(0, -12),
                    child: Material(
                      color: tokens.accentFill,
                      shape: CircleBorder(
                        side: onScan
                            ? BorderSide(color: tokens.accentEmphasis, width: 2)
                            : BorderSide.none,
                      ),
                      child: InkWell(
                        onTap: () => context.go('/scan'),
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          width: 56,
                          height: 56,
                          child: Icon(
                            Icons.document_scanner_outlined,
                            color: Colors.white,
                            semanticLabel: 'Scan',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _NavItem(
                icon: Icons.chat_bubble_outline,
                selectedIcon: Icons.chat_bubble,
                label: 'Chat',
                selected: location.startsWith('/chat'),
                onTap: () => context.go('/chat'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final color = selected ? tokens.accentEmphasis : tokens.inkSoft;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Semantics(
          selected: selected,
          button: true,
          label: label,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? selectedIcon : icon, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
