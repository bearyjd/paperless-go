import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Extracts text from an image using ML Kit text recognition.
/// Must run on the main isolate (ML Kit uses platform channels).
class OcrExtractor {
  OcrExtractor._();

  /// Extract all text from the image at [imagePath].
  /// Returns concatenated text blocks separated by newlines.
  static Future<String> extractText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizer = TextRecognizer();
    try {
      final result = await recognizer.processImage(inputImage);
      return result.blocks.map((b) => b.text).join('\n');
    } finally {
      recognizer.close();
    }
  }
}
