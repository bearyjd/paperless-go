/// Turns a stored `pending_uploads.lastError` into something worth showing.
///
/// The queue stores `e.toString()`, so the raw value is a `DioException` dump
/// (with the full request URL) or a bare `SocketException`. `friendlyApiMessage`
/// cannot help here — it keys off the live exception object, and by the time a
/// row reaches this screen the exception is long gone and only its string
/// survives.
///
/// Pure and string-only so it can be table-tested without a database.
library;

/// A one-line summary of [rawError], suitable for a queue row.
///
/// Returns null when there is nothing useful to say, so callers can omit the
/// line entirely rather than render "An unexpected error occurred." under every
/// row that is simply still waiting.
String? queueErrorSummary(String? rawError) {
  if (rawError == null) return null;
  final raw = rawError.trim();
  if (raw.isEmpty) return null;

  // Ordered most-specific first: a DioException wrapping a SocketException
  // matches several of these, and "could not reach the server" is the more
  // useful of the two readings.
  const patterns = <String, String>{
    'Gave up after': 'Given up on after waiting too long to reach the server.',
    'no longer available': 'The file is no longer on this device.',
    'unreadable': 'The saved tags for this document could not be read.',
    'SocketException': 'Could not reach the server.',
    'Failed host lookup': 'Could not find that server address.',
    'connectionTimeout': 'The server took too long to respond.',
    'receiveTimeout': 'The server took too long to respond.',
    'sendTimeout': 'The upload timed out.',
    'connectionError': 'Could not reach the server.',
    'NotAuthenticatedException': 'You were not signed in.',
    '401': 'Your server rejected the sign-in for this upload.',
    '403': 'Your account is not allowed to upload this document.',
    '413': 'The server rejected this document as too large.',
    '500': 'The server had a problem accepting this document.',
  };

  for (final entry in patterns.entries) {
    if (raw.contains(entry.key)) return entry.value;
  }
  return 'The upload did not complete.';
}
