// Pure parsers for the `extra` payloads passed to `/scan/*` routes.
//
// Returning `null` on a malformed payload lets the route render an error
// screen instead of crashing on an unchecked cast. Keeping the logic here
// (rather than inline in the GoRoute builders) makes it unit-testable without
// standing up the full router, auth redirect, and app shell.

/// Parsed arguments for the `/scan/pdf-preview` route.
class PdfPreviewArgs {
  const PdfPreviewArgs({
    required this.imagePaths,
    required this.preProcessed,
    this.ocrImagePath,
  });

  final List<String> imagePaths;
  final bool preProcessed;
  final String? ocrImagePath;
}

/// Parse `/scan/pdf-preview` `extra`. Returns `null` when the payload is not a
/// map, is missing `imagePaths`, or `imagePaths` is not a non-empty list.
PdfPreviewArgs? parsePdfPreviewArgs(Object? extra) {
  if (extra is! Map<String, dynamic>) return null;
  final rawPaths = extra['imagePaths'];
  if (rawPaths is! List || rawPaths.isEmpty) return null;
  return PdfPreviewArgs(
    imagePaths: rawPaths.cast<String>(),
    preProcessed: extra['preProcessed'] as bool? ?? false,
    ocrImagePath: extra['ocrImagePath'] as String?,
  );
}

/// Parse `/scan/upload` `extra`. Returns the validated params map, or `null`
/// when `filePath`/`filename` are missing or empty.
Map<String, dynamic>? parseUploadArgs(Object? extra) {
  if (extra is! Map<String, dynamic>) return null;
  final filePath = extra['filePath'];
  final filename = extra['filename'];
  if (filePath is! String ||
      filePath.isEmpty ||
      filename is! String ||
      filename.isEmpty) {
    return null;
  }
  return extra;
}
