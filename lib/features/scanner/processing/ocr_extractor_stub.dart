/// Stub for ocr_extractor.dart — used in F-Droid builds where ML Kit is unavailable.
/// Returns empty string so metadata suggestions are skipped.
class OcrExtractor {
  OcrExtractor._();

  static Future<String> extractText(String imagePath) async {
    return '';
  }
}
