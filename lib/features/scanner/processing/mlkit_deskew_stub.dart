/// Stub for mlkit_deskew.dart — used in F-Droid builds where ML Kit is unavailable.
/// Returns null so the caller falls back to the pure-Dart projection profile deskew.
Future<double?> detectAngleWithMlKit(String imagePath) async {
  return null;
}
