import 'dart:convert';

import '../database/app_database.dart';

/// What the drain has decided to do with one queued row.
///
/// Sealed so a new outcome breaks every switch loudly. The alternative — the
/// chain of sequential `if (...) continue;` guards this replaced — made
/// correctness depend on the ORDER of the guards, and a regression on this
/// queue came from exactly that: two separate fixes, each correct alone,
/// reordered the chain so one bypassed the other.
sealed class UploadDecision {
  const UploadDecision();
}

/// Leave the row alone this pass. Not an error: it is terminally failed, or
/// belongs to a server that is not the active one.
final class SkipUpload extends UploadDecision {
  const SkipUpload(this.why);

  /// Diagnostic only — nothing branches on this.
  final String why;
}

/// Record the row as failed. For failures that retrying cannot repair.
final class FailUpload extends UploadDecision {
  const FailUpload(this.reason);

  /// Shown to the user once the queue has a UI; stored as `lastError`.
  final String reason;
}

/// Send it.
final class SendUpload extends UploadDecision {
  const SendUpload(this.tags);

  final List<int>? tags;
}

/// Classifies one row. Pure: no I/O, no clock, no database — [fileExists] is
/// resolved by the caller, inside the caller's fault boundary, so this stays
/// exhaustively testable without a filesystem.
UploadDecision decideUpload(
  PendingUpload upload, {
  required String? activeServer,
  required bool fileExists,
}) {
  if (upload.isFailed) {
    return const SkipUpload('terminally failed');
  }

  // Never send someone's document to the wrong account. Switching server
  // profiles calls loginWithToken, which emits AsyncLoading before the new
  // authenticated state — the auth listener reads that as an
  // unauthenticated->authenticated edge and drains immediately, so without
  // this check every row queued for profile A went to profile B.
  //
  // A null serverUrl means the row predates that column. Skipping rather than
  // guessing: uploading to the wrong server is worse than waiting, and the row
  // keeps its file either way.
  if (upload.serverUrl != activeServer) {
    return const SkipUpload('queued for a different server');
  }

  // Queued files live in app-private storage (PendingUploadStore), so a
  // missing one means it was cleared out from under us. Retrying is pointless,
  // but deleting the row silently is how a document disappears without trace —
  // fail it so it stays on the record.
  if (!fileExists) {
    return const FailUpload(
      'The queued file is no longer available on this device.',
    );
  }

  final tagsJson = upload.tagsJson;
  if (tagsJson == null) return const SendUpload(null);

  // Unparseable metadata is terminal, not a retry. It used to ride the retry
  // path, which spent five attempts discovering that a string will not become
  // valid JSON on the sixth. The document itself is still on disk and the row
  // still records what happened.
  try {
    // Eager, not `.cast<int>()`. A lazy cast defers the type error to the
    // first read — which happens inside the upload, where it looks like a
    // failed attempt and spends the retry budget instead of being classified
    // here as the unrepairable metadata it is.
    return SendUpload(
      List<int>.from(jsonDecode(tagsJson) as List<dynamic>),
    );
  } on FormatException {
    return const FailUpload('The queued tags for this document are unreadable.');
  } on TypeError {
    return const FailUpload('The queued tags for this document are unreadable.');
  }
}
