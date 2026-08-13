import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:paperless_go/app.dart';
import 'package:paperless_go/core/auth/auth_provider.dart';

class _FakeAuthenticated extends AuthState {
  @override
  Future<AuthStatus> build() async => const AuthStatus.authenticated(
        serverUrl: 'https://paperless.example.com',
        token: 'test-token',
      );
}

class _FakeUnauthenticated extends AuthState {
  @override
  Future<AuthStatus> build() async => const AuthStatus.unauthenticated();
}

Future<GoRouterHarness> _harness(
  WidgetTester tester,
  AuthState Function() authState,
) async {
  final container = ProviderContainer(
    overrides: [authStateProvider.overrideWith(authState)],
  );
  await container.read(authStateProvider.future);
  final router = container.read(routerProvider);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();

  return GoRouterHarness(container, router);
}

class GoRouterHarness {
  GoRouterHarness(this.container, this.router);
  final ProviderContainer container;
  final GoRouter router;
}

void main() {
  testWidgets(
      'a content:// share/open-with route lands on /inbox, not the '
      'unmatched intermediate "/" '
      '(regression: onNewIntent-pushed routes on a reused singleTask '
      'Activity showed "Page not found" instead of following through a '
      'second redirect pass)', (tester) async {
    final harness = await _harness(tester, _FakeAuthenticated.new);
    addTearDown(harness.container.dispose);

    harness.router.go(
      'content://com.android.providers.downloads.documents/document/1',
    );
    await tester.pumpAndSettle();

    expect(
      harness.router.routerDelegate.currentConfiguration.uri.toString(),
      '/inbox',
    );
  });

  testWidgets(
      'a content:// route while logged out lands on /login, not the '
      'unmatched intermediate "/"', (tester) async {
    final harness = await _harness(tester, _FakeUnauthenticated.new);
    addTearDown(harness.container.dispose);

    harness.router.go(
      'content://com.android.providers.downloads.documents/document/1',
    );
    await tester.pumpAndSettle();

    expect(
      harness.router.routerDelegate.currentConfiguration.uri.toString(),
      '/login',
    );
  });
}
