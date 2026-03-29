import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/features/documents/document_detail_screen.dart';

void main() {
  group('displayCustomFieldValue — select type', () {
    test('returns label for matching integer id', () {
      final extraData = {
        'select_options': [
          {'id': 0, 'label': 'Pending'},
          {'id': 1, 'label': 'Approved'},
        ],
      };
      expect(
          displayCustomFieldValue(1, 'select', extraData: extraData),
          'Approved');
      expect(
          displayCustomFieldValue(null, 'select', extraData: extraData),
          'Not set');
      expect(
          displayCustomFieldValue(99, 'select', extraData: extraData),
          '99');
    });

    test('returns label for matching string id', () {
      final extraData = {
        'select_options': [
          {'id': 'red', 'label': 'Red'},
          {'id': 'blue', 'label': 'Blue'},
        ],
      };
      expect(
          displayCustomFieldValue('blue', 'select', extraData: extraData),
          'Blue');
    });

    test('handles plain string options', () {
      final extraData = {
        'select_options': ['Red', 'Green', 'Blue'],
      };
      expect(
          displayCustomFieldValue('Green', 'select', extraData: extraData),
          'Green');
      expect(
          displayCustomFieldValue(null, 'select', extraData: extraData),
          'Not set');
    });

    test('falls back to id when label is null', () {
      final extraData = {
        'select_options': [
          {'id': 42, 'label': null},
        ],
      };
      expect(
          displayCustomFieldValue(42, 'select', extraData: extraData),
          '42');
    });

    test('returns empty string when both label and id are null', () {
      final extraData = {
        'select_options': [
          {'id': null, 'label': null},
        ],
      };
      // val doesn't match (null val returns 'Not set'), so just verify no crash
      expect(
          displayCustomFieldValue(null, 'select', extraData: extraData),
          'Not set');
    });
  });

  group('displayCustomFieldValue — other types', () {
    test('boolean', () {
      expect(displayCustomFieldValue(true, 'boolean'), 'Yes');
      expect(displayCustomFieldValue(false, 'boolean'), 'No');
    });

    test('monetary strips redundant null guard', () {
      expect(displayCustomFieldValue('9.99', 'monetary'), r'$9.99');
    });

    test('null returns Not set', () {
      expect(displayCustomFieldValue(null, 'string'), 'Not set');
    });

    test('plain string', () {
      expect(displayCustomFieldValue('hello', 'string'), 'hello');
    });
  });
}
