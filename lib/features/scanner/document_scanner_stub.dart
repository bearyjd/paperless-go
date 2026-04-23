import 'package:file_picker/file_picker.dart';

class DocumentScanner {
  static Future<List<String>?> getPictures({
    bool isGalleryImportAllowed = true,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return null;
    return result.files
        .where((f) => f.path != null)
        .map((f) => f.path!)
        .toList();
  }
}
