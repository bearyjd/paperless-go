import 'package:cunning_document_scanner/cunning_document_scanner.dart';

class DocumentScanner {
  static Future<List<String>?> getPictures({
    bool isGalleryImportAllowed = true,
  }) {
    return CunningDocumentScanner.getPictures(
      isGalleryImportAllowed: isGalleryImportAllowed,
    );
  }
}
