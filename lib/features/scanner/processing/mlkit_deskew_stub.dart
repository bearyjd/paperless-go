/// Stub replacement for mlkit_deskew.dart used in F-Droid builds.
/// google_mlkit_text_recognition is not available — always returns null
/// so the caller falls back to the pure-Dart projection profile deskew.
Future<double?> detectAngleWithMlKit(String imagePath) async {
  return null;
}
