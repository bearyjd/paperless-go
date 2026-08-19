import '../../core/database/app_database.dart';

/// What a queued row is actually doing, as far as the user is concerned.
///
/// Deliberately separate from the drain's `UploadDecision`: that classifies
/// what to DO with a row on this pass (and depends on live state like whether
/// the file is on disk), while this classifies what to SAY about it. Reusing
/// the drain's type here would tie the screen to the drain's guard order and
/// force the UI to answer questions it has no business asking, like whether a
/// file exists, on every rebuild.
enum QueueRowStatus {
  /// Waiting for its next attempt. Nothing has gone wrong yet.
  waiting,

  /// Has failed at least once but has retries left.
  retrying,

  /// Terminally failed — the drain will not try this again without a reset.
  failed,

  /// Queued for a server that is not the active one. Skipped, not broken;
  /// signing back into that profile is enough to make it upload.
  otherServer,

  /// Predates the serverUrl column, so the drain refuses to guess where it
  /// belongs rather than risk sending it to the wrong account.
  legacy,
}

/// Classifies [upload] for display against the currently active server.
///
/// [activeServer] is null when nobody is signed in, which is NOT the same as a
/// row having no server: signed out, every row is simply waiting for a session,
/// not stranded on another profile. Reporting them all as "queued for another
/// server" while signed out would be alarming and wrong.
QueueRowStatus queueRowStatus(PendingUpload upload, {String? activeServer}) {
  if (upload.isFailed) return QueueRowStatus.failed;
  if (upload.serverUrl == null) return QueueRowStatus.legacy;
  if (activeServer != null && upload.serverUrl != activeServer) {
    return QueueRowStatus.otherServer;
  }
  if (upload.retryCount > 0) return QueueRowStatus.retrying;
  return QueueRowStatus.waiting;
}

/// True when the row needs the user to do something. Drives the badge and the
/// banner — a queue full of rows that are merely waiting for signal is not a
/// problem worth interrupting anyone about.
bool queueRowNeedsAttention(QueueRowStatus status) {
  switch (status) {
    case QueueRowStatus.failed:
    case QueueRowStatus.legacy:
      return true;
    case QueueRowStatus.waiting:
    case QueueRowStatus.retrying:
    case QueueRowStatus.otherServer:
      return false;
  }
}
