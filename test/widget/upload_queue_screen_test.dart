import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/auth/auth_provider.dart';
import 'package:paperless_go/core/database/app_database.dart';
import 'package:paperless_go/core/theme.dart';
import 'package:paperless_go/features/upload_queue/upload_queue_notifier.dart';
import 'package:paperless_go/features/upload_queue/upload_queue_screen.dart';

class _FakeAuthenticated extends AuthState {
  @override
  Future<AuthStatus> build() async => const AuthStatus.authenticated(
        serverUrl: 'https://paperless.example.com',
        token: 'test-token',
      );
}

PendingUpload _row({
  int id = 1,
  String filename = 'invoice.pdf',
  String? title,
  bool isFailed = false,
  int retryCount = 0,
  String? serverUrl = 'https://paperless.example.com',
  String? lastError,
}) {
  return PendingUpload(
    id: id,
    filePath: '/queue/$filename',
    filename: filename,
    title: title,
    queuedAt: DateTime(2026, 8, 1),
    retryCount: retryCount,
    isFailed: isFailed,
    serverUrl: serverUrl,
    lastError: lastError,
  );
}

void main() {
  Future<void> pumpQueue(WidgetTester tester, List<PendingUpload> rows,
      {int unreadable = 0}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pendingUploadsProvider.overrideWith((ref) => Stream.value(rows)),
          unreadableUploadsProvider.overrideWith((ref) async => unreadable),
          authStateProvider.overrideWith(_FakeAuthenticated.new),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const UploadQueueScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('an empty queue explains what would appear here', (tester) async {
    await pumpQueue(tester, const []);

    expect(find.text('Nothing waiting'), findsOneWidget);
    // No bulk action offered when there is nothing to act on.
    expect(find.byTooltip('Delete all failed'), findsNothing);
  });

  testWidgets('a waiting upload is not dressed up as a problem',
      (tester) async {
    await pumpQueue(tester, [_row()]);

    expect(find.text('invoice.pdf'), findsOneWidget);
    expect(find.textContaining('Waiting'), findsOneWidget);
    expect(find.byTooltip('Delete all failed'), findsNothing,
        reason: 'nothing has failed, so nothing to bulk delete');
  });

  testWidgets('a failed upload shows a readable reason, not the raw error',
      (tester) async {
    await pumpQueue(tester, [
      _row(
        isFailed: true,
        lastError: 'DioException [connectionError]: SocketException: '
            'Connection refused (OS Error), address = paperless.private.lan',
      ),
    ]);

    expect(find.textContaining('Failed'), findsOneWidget);
    expect(find.text('Could not reach the server.'), findsOneWidget);
    // The raw string carries the user's server address; it belongs behind the
    // Details expander, not on the collapsed card.
    expect(find.textContaining('paperless.private.lan'), findsNothing);
  });

  testWidgets('the raw error is available once expanded', (tester) async {
    await pumpQueue(tester, [
      _row(isFailed: true, lastError: 'DioException: paperless.private.lan'),
    ]);

    await tester.tap(find.text('invoice.pdf'));
    await tester.pumpAndSettle();

    expect(find.textContaining('paperless.private.lan'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('a retention row does not repeat itself in Details',
      (tester) async {
    // Seen on a Pixel 9: the summary and the Details line said the same thing
    // in slightly different words, one directly under the other.
    await pumpQueue(tester, [
      _row(
        isFailed: true,
        lastError: 'Gave up after 30 days without reaching the server.',
      ),
    ]);
    await tester.tap(find.text('invoice.pdf'));
    await tester.pumpAndSettle();

    expect(find.text('Stopped trying after waiting too long to reach it.'),
        findsOneWidget);
    expect(find.text('Details'), findsNothing,
        reason: 'the stored message IS the explanation; do not restate it');
    // The actions still have to be there.
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('deleting asks first, and says what is lost', (tester) async {
    await pumpQueue(tester, [_row(isFailed: true)]);
    await tester.tap(find.text('invoice.pdf'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete this upload?'), findsOneWidget);
    expect(find.textContaining('last copy'), findsOneWidget,
        reason: 'a generic "are you sure" hides that this destroys a document');
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('bulk delete discloses that it spans other server profiles',
      (tester) async {
    // The action deliberately covers every profile (an other-server row can
    // only be marked failed by retention, so those are the abandoned ones a
    // scoped sweep could never clear in bulk). What it must not do is span
    // profiles silently: this dialog is the only place the user finds out.
    await pumpQueue(tester, [
      _row(id: 1, filename: 'mine.pdf', isFailed: true),
      _row(
        id: 2,
        filename: 'theirs.pdf',
        isFailed: true,
        serverUrl: 'https://other.example.com',
      ),
    ]);

    await tester.tap(find.byTooltip('Delete all failed'));
    await tester.pumpAndSettle();

    expect(find.text('Delete 2 failed uploads?'), findsOneWidget);
    expect(find.textContaining('queued for a different server'), findsOneWidget,
        reason: 'deleting another profile\'s only copy cannot be silent');
    expect(find.textContaining('https://other.example.com'), findsOneWidget,
        reason: 'name the server so the user can tell what they are losing');
  });

  testWidgets('bulk delete stays quiet when every row is this server\'s',
      (tester) async {
    await pumpQueue(tester, [
      _row(id: 1, filename: 'mine.pdf', isFailed: true),
      _row(id: 2, filename: 'also-mine.pdf', isFailed: true),
    ]);

    await tester.tap(find.byTooltip('Delete all failed'));
    await tester.pumpAndSettle();

    expect(find.textContaining('different server'), findsNothing,
        reason: 'no cross-profile warning when there is nothing to warn about');
  });

  testWidgets('bulk delete flags rows that predate server profiles',
      (tester) async {
    await pumpQueue(tester, [
      _row(id: 1, filename: 'legacy.pdf', isFailed: true, serverUrl: null),
    ]);

    await tester.tap(find.byTooltip('Delete all failed'));
    await tester.pumpAndSettle();

    expect(find.textContaining('before server profiles existed'), findsOneWidget);
  });

  testWidgets('a row for another server explains itself rather than failing',
      (tester) async {
    await pumpQueue(tester, [
      _row(serverUrl: 'https://other.example.com'),
    ]);

    expect(find.textContaining('Queued for another server'), findsOneWidget);
  });

  testWidgets('a title is preferred over the filename when present',
      (tester) async {
    await pumpQueue(tester, [_row(title: '電気料金 2026')]);

    expect(find.text('電気料金 2026'), findsOneWidget);
    expect(find.text('invoice.pdf'), findsNothing);
  });

  testWidgets('the retention footnote explains why files are kept',
      (tester) async {
    await pumpQueue(tester, [_row(isFailed: true)]);

    expect(find.textContaining('may be the only copy'), findsOneWidget);
  });

  testWidgets('a damaged row is reported rather than vanishing', (tester) async {
    // It cannot be decoded, so it cannot be listed or deleted — but it still
    // holds a file. Saying nothing would be the invisible-storage failure this
    // screen exists to end.
    await pumpQueue(tester, [_row()], unreadable: 2);

    expect(find.textContaining('2 queued items are damaged'), findsOneWidget);
  });

  testWidgets('no damage notice when nothing is damaged', (tester) async {
    await pumpQueue(tester, [_row()]);

    expect(find.textContaining('damaged'), findsNothing);
  });
}
