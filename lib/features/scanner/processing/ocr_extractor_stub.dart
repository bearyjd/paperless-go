/// Stub replacement for ocr_extractor.dart used in F-Droid builds.
/// google_mlkit_text_recognition is not available — returns empty string
/// so metadata suggestions are skipped (no OCR text to match against).
class OcrExtractor {
  OcrExtractor._();

  /// Returns empty string — OCR not available in F-Droid build.
  static Future<String> extractText(String imagePath) async {
    return '';
  }
}
