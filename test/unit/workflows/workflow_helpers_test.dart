import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/features/workflows/workflow_helpers.dart';

void main() {
  group('triggerTypeLabel', () {
    test('returns label for known types', () {
      expect(triggerTypeLabel(1), 'Consumption');
      expect(triggerTypeLabel(2), 'Document Added');
      expect(triggerTypeLabel(3), 'Document Updated');
      expect(triggerTypeLabel(4), 'Removal');
      expect(triggerTypeLabel(5), 'Scheduled');
    });

    test('returns Unknown for invalid type', () {
      expect(triggerTypeLabel(99), 'Unknown');
    });
  });

  group('actionTypeLabel', () {
    test('returns label for known types', () {
      expect(actionTypeLabel(1), 'Assignment');
      expect(actionTypeLabel(2), 'Removal');
      expect(actionTypeLabel(3), 'Email');
    });

    test('returns Unknown for invalid type', () {
      expect(actionTypeLabel(0), 'Unknown');
    });
  });

  group('sourceLabel', () {
    test('returns label for known sources', () {
      expect(sourceLabel(1), 'Consume Folder');
      expect(sourceLabel(2), 'API Upload');
      expect(sourceLabel(3), 'Mail Fetch');
    });

    test('returns Unknown for invalid source', () {
      expect(sourceLabel(42), 'Unknown');
    });
  });

  group('matchingAlgorithmLabel', () {
    test('returns label for known algorithms', () {
      expect(matchingAlgorithmLabel(0), 'None');
      expect(matchingAlgorithmLabel(1), 'Any word');
      expect(matchingAlgorithmLabel(2), 'All words');
      expect(matchingAlgorithmLabel(3), 'Exact match');
      expect(matchingAlgorithmLabel(4), 'RegEx');
      expect(matchingAlgorithmLabel(5), 'Fuzzy');
      expect(matchingAlgorithmLabel(6), 'Auto');
    });

    test('returns Unknown for invalid algorithm', () {
      expect(matchingAlgorithmLabel(99), 'Unknown');
    });
  });
}
