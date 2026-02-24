import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/app.dart';
import 'package:paperless_go/core/auth/auth_provider.dart';

void main() {
  testWidgets('App renders login screen when unauthenticated', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => _UnauthenticatedAuthState()),
        ],
        child: const PaperlessGoApp(),
      ),
    );
    // Pump frames for the router redirect
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Paperless Go'), findsOneWidget);
    expect(find.text('Connect to your Paperless-ngx server'), findsOneWidget);
  });
}

class _UnauthenticatedAuthState extends AuthState {
  @override
  Future<AuthStatus> build() async => const AuthStatus.unauthenticated();
}
