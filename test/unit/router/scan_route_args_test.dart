import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/router/scan_route_args.dart';

void main() {
  group('parsePdfPreviewArgs', () {
    test('returns null when extra is not a map', () {
      expect(parsePdfPreviewArgs(null), isNull);
      expect(parsePdfPreviewArgs('nope'), isNull);
      expect(parsePdfPreviewArgs(<String>['a']), isNull);
    });

    test('returns null when imagePaths is missing (the crash case)', () {
      expect(parsePdfPreviewArgs(<String, dynamic>{}), isNull);
      expect(
        parsePdfPreviewArgs(<String, dynamic>{'preProcessed': true}),
        isNull,
      );
    });

    test('returns null when imagePaths is not a list or is empty', () {
      expect(parsePdfPreviewArgs(<String, dynamic>{'imagePaths': 'x'}), isNull);
      expect(
        parsePdfPreviewArgs(<String, dynamic>{'imagePaths': <String>[]}),
        isNull,
      );
    });

    test('parses a valid payload with defaults', () {
      final args = parsePdfPreviewArgs(<String, dynamic>{
        'imagePaths': ['/a.jpg', '/b.jpg'],
      });
      expect(args, isNotNull);
      expect(args!.imagePaths, ['/a.jpg', '/b.jpg']);
      expect(args.preProcessed, isFalse);
      expect(args.ocrImagePath, isNull);
    });

    test('parses optional preProcessed and ocrImagePath', () {
      final args = parsePdfPreviewArgs(<String, dynamic>{
        'imagePaths': ['/a.jpg'],
        'preProcessed': true,
        'ocrImagePath': '/ocr.jpg',
      });
      expect(args!.preProcessed, isTrue);
      expect(args.ocrImagePath, '/ocr.jpg');
    });
  });

  group('parseUploadArgs', () {
    test('returns null when extra is not a map', () {
      expect(parseUploadArgs(null), isNull);
      expect(parseUploadArgs(42), isNull);
    });

    test('returns null when filePath or filename is missing/empty', () {
      expect(parseUploadArgs(<String, dynamic>{'filename': 'a.pdf'}), isNull);
      expect(parseUploadArgs(<String, dynamic>{'filePath': '/a.pdf'}), isNull);
      expect(
        parseUploadArgs(<String, dynamic>{'filePath': '', 'filename': 'a.pdf'}),
        isNull,
      );
      expect(
        parseUploadArgs(<String, dynamic>{'filePath': '/a.pdf', 'filename': ''}),
        isNull,
      );
    });

    test('returns the params map when valid', () {
      final params = parseUploadArgs(<String, dynamic>{
        'filePath': '/a.pdf',
        'filename': 'a.pdf',
        'ocrImagePath': '/a.jpg',
      });
      expect(params, isNotNull);
      expect(params!['filePath'], '/a.pdf');
      expect(params['filename'], 'a.pdf');
    });
  });
}
