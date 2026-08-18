import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/database/app_database.dart';
import 'package:paperless_go/core/services/upload_decision.dart';

/// The drain's row classifier, tested without a database, a filesystem or a
/// server — which is the point of it being pure. The guard chain it replaced
/// could only be exercised by driving a whole drain.
void main() {
  PendingUpload row({
    bool isFailed = false,
    String? serverUrl = 'https://paperless.example.com',
    String? tagsJson,
  }) {
    return PendingUpload(
      id: 1,
      filePath: '/queue/doc.pdf',
      filename: 'doc.pdf',
      queuedAt: DateTime(2026, 8, 18),
      retryCount: 0,
      isFailed: isFailed,
      serverUrl: serverUrl,
      tagsJson: tagsJson,
    );
  }

  UploadDecision decide(
    PendingUpload upload, {
    String? activeServer = 'https://paperless.example.com',
    bool fileExists = true,
  }) {
    return decideUpload(
      upload,
      activeServer: activeServer,
      fileExists: fileExists,
    );
  }

  test('a healthy row is sent', () {
    expect(decide(row()), isA<SendUpload>().having((d) => d.tags, 'tags', null));
  });

  test('tags are decoded for the send', () {
    expect(
      decide(row(tagsJson: '[3, 7]')),
      isA<SendUpload>().having((d) => d.tags, 'tags', [3, 7]),
    );
  });

  test('a terminally failed row is skipped', () {
    expect(decide(row(isFailed: true)), isA<SkipUpload>());
  });

  test('a row for another server is skipped, not failed', () {
    // Failing it would be worse than waiting: the profile may come back, and
    // the row keeps its file either way.
    expect(
      decide(row(serverUrl: 'https://other.example.com')),
      isA<SkipUpload>(),
    );
  });

  test('a row with no recorded server is skipped rather than guessed at', () {
    // Predates the serverUrl column. Uploading to whatever server happens to
    // be active is how documents reached the wrong account.
    expect(decide(row(serverUrl: null)), isA<SkipUpload>());
  });

  test('being signed out skips every row rather than failing them', () {
    expect(decide(row(), activeServer: null), isA<SkipUpload>());
  });

  test('a missing file is failed, not skipped', () {
    expect(
      decide(row(), fileExists: false),
      isA<FailUpload>().having(
        (d) => d.reason,
        'reason',
        contains('no longer available'),
      ),
    );
  });

  test('terminal state is checked before the file exists', () {
    // Order matters: a failed row must not be re-reported as a missing file
    // every pass, overwriting the real reason it failed.
    expect(
      decide(row(isFailed: true), fileExists: false),
      isA<SkipUpload>(),
    );
  });

  group('unreadable tags are terminal, not retryable', () {
    test('not JSON at all', () {
      expect(decide(row(tagsJson: 'not json')), isA<FailUpload>());
    });

    test('JSON of the wrong shape', () {
      expect(decide(row(tagsJson: '{"a": 1}')), isA<FailUpload>());
    });

    test('a list of the wrong element type', () {
      expect(decide(row(tagsJson: '["a", "b"]')), isA<FailUpload>());
    });

    test('the reason names the tags, so the queue UI can say why', () {
      expect(
        decide(row(tagsJson: 'not json')),
        isA<FailUpload>()
            .having((d) => d.reason, 'reason', contains('tags')),
      );
    });
  });
}
