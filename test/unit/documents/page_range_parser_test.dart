import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/features/documents/page_range_parser.dart';

void main() {
  group('parsePageRanges', () {
    test('parses single page', () {
      final result = parsePageRanges('3', totalPages: 10);
      expect(result.isValid, true);
      expect(result.normalized, '3');
      expect(result.error, isNull);
    });

    test('parses page range', () {
      final result = parsePageRanges('1-5', totalPages: 10);
      expect(result.isValid, true);
      expect(result.normalized, '1-5');
    });

    test('parses multiple ranges with spaces', () {
      final result = parsePageRanges('1-3, 5, 7-9', totalPages: 10);
      expect(result.isValid, true);
      expect(result.normalized, '1-3,5,7-9');
    });

    test('rejects empty input', () {
      final result = parsePageRanges('', totalPages: 10);
      expect(result.isValid, false);
      expect(result.error, contains('empty'));
    });

    test('rejects page exceeding total', () {
      final result = parsePageRanges('1-15', totalPages: 10);
      expect(result.isValid, false);
      expect(result.error, contains('10'));
    });

    test('rejects page 0', () {
      final result = parsePageRanges('0-3', totalPages: 10);
      expect(result.isValid, false);
      expect(result.error, contains('1'));
    });

    test('rejects reversed range', () {
      final result = parsePageRanges('5-3', totalPages: 10);
      expect(result.isValid, false);
      expect(result.error, contains('greater'));
    });

    test('rejects non-numeric input', () {
      final result = parsePageRanges('abc', totalPages: 10);
      expect(result.isValid, false);
    });

    test('handles all pages as single range', () {
      final result = parsePageRanges('1-10', totalPages: 10);
      expect(result.isValid, true);
      expect(result.normalized, '1-10');
    });

    test('trims whitespace around ranges', () {
      final result = parsePageRanges(' 1 - 3 , 5 ', totalPages: 10);
      expect(result.isValid, true);
      expect(result.normalized, '1-3,5');
    });
  });
}
