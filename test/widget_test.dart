import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/app.dart';

void main() {
  testWidgets('App renders login screen when unauthenticated', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PaperlessGoApp()));
    // Pump a few frames for the async auth check and router redirect
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Paperless Go'), findsOneWidget);
    expect(find.text('Connect to your Paperless-ngx server'), findsOneWidget);
  });
}
