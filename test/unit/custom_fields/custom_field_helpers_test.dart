import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/features/custom_fields/custom_field_helpers.dart';

void main() {
  group('dataTypeLabel', () {
    test('returns label for all known data types', () {
      expect(dataTypeLabel('string'), 'Text');
      expect(dataTypeLabel('url'), 'URL');
      expect(dataTypeLabel('date'), 'Date');
      expect(dataTypeLabel('boolean'), 'Boolean');
      expect(dataTypeLabel('integer'), 'Integer');
      expect(dataTypeLabel('float'), 'Float');
      expect(dataTypeLabel('monetary'), 'Monetary');
      expect(dataTypeLabel('document_link'), 'Document Link');
      expect(dataTypeLabel('select'), 'Select');
    });

    test('returns input string for unknown type', () {
      expect(dataTypeLabel('custom_new_type'), 'custom_new_type');
    });
  });

  group('dataTypeIcon', () {
    test('returns distinct icons for each type', () {
      for (final type in [
        'string', 'url', 'date', 'boolean', 'integer',
        'float', 'monetary', 'document_link', 'select',
      ]) {
        expect(dataTypeIcon(type), isNotNull);
      }
    });

    test('returns fallback icon for unknown type', () {
      expect(dataTypeIcon('unknown_type'), isNotNull);
    });
  });
}
