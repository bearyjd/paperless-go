import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/models/saved_view.dart';
import 'package:paperless_go/features/documents/documents_notifier.dart';
import 'package:paperless_go/features/documents/saved_view_helpers.dart';

void main() {
  group('filterRulesToDocumentsFilter', () {
    test('converts correspondent rule', () {
      final filter = filterRulesToDocumentsFilter(
        [const FilterRule(ruleType: 3, value: '5')],
        '-created',
      );
      expect(filter.correspondentId, 5);
      expect(filter.ordering, '-created');
    });

    test('converts document type rule', () {
      final filter = filterRulesToDocumentsFilter(
        [const FilterRule(ruleType: 4, value: '12')],
        'title',
      );
      expect(filter.documentTypeId, 12);
      expect(filter.ordering, 'title');
    });

    test('converts has-tag rules (multiple)', () {
      final filter = filterRulesToDocumentsFilter(
        [
          const FilterRule(ruleType: 6, value: '1'),
          const FilterRule(ruleType: 6, value: '2'),
        ],
        '-created',
      );
      expect(filter.tagIds, containsAll([1, 2]));
    });

    test('converts full-text query rule (type 22)', () {
      final filter = filterRulesToDocumentsFilter(
        [const FilterRule(ruleType: 22, value: 'invoice')],
        '-created',
      );
      expect(filter.query, 'invoice');
    });

    test('converts title contains rules (types 0, 1, 2) as query', () {
      for (final type in [0, 1, 2]) {
        final filter = filterRulesToDocumentsFilter(
          [FilterRule(ruleType: type, value: 'test')],
          '-created',
        );
        expect(filter.query, 'test',
            reason: 'rule type $type should map to query');
      }
    });

    test('converts created after rule (type 9)', () {
      final filter = filterRulesToDocumentsFilter(
        [const FilterRule(ruleType: 9, value: '2024-01-01')],
        '-created',
      );
      expect(filter.createdDateFrom, DateTime(2024, 1, 1));
    });

    test('converts created before rule (type 10)', () {
      final filter = filterRulesToDocumentsFilter(
        [const FilterRule(ruleType: 10, value: '2024-12-31')],
        '-created',
      );
      expect(filter.createdDateTo, DateTime(2024, 12, 31));
    });

    test('ignores unknown rule types without throwing', () {
      expect(
        () => filterRulesToDocumentsFilter(
          [const FilterRule(ruleType: 999, value: 'x')],
          '-created',
        ),
        returnsNormally,
      );
    });

    test('empty rules returns default filter with given ordering', () {
      final filter = filterRulesToDocumentsFilter([], 'title');
      expect(filter.ordering, 'title');
      expect(filter.query, isNull);
      expect(filter.tagIds, isNull);
    });
  });

  group('documentsFilterToFilterRules', () {
    test('converts query to full-text rule', () {
      const filter = DocumentsFilter(query: 'invoice 2024', ordering: '-created');
      final rules = documentsFilterToFilterRules(filter);
      expect(rules.any((r) => r.ruleType == 22 && r.value == 'invoice 2024'),
          isTrue);
    });

    test('converts correspondent to rule type 3', () {
      const filter = DocumentsFilter(correspondentId: 7, ordering: '-created');
      final rules = documentsFilterToFilterRules(filter);
      expect(rules.any((r) => r.ruleType == 3 && r.value == '7'), isTrue);
    });

    test('converts each tag to a separate rule type 6', () {
      const filter = DocumentsFilter(tagIds: [1, 2, 3], ordering: '-created');
      final rules = documentsFilterToFilterRules(filter);
      final tagRules = rules.where((r) => r.ruleType == 6).toList();
      expect(tagRules.map((r) => r.value).toSet(), {'1', '2', '3'});
    });

    test('converts date range to rules 9 and 10', () {
      final filter = DocumentsFilter(
        createdDateFrom: DateTime(2024, 1, 1),
        createdDateTo: DateTime(2024, 12, 31),
        ordering: '-created',
      );
      final rules = documentsFilterToFilterRules(filter);
      expect(rules.any((r) => r.ruleType == 9 && r.value == '2024-01-01'),
          isTrue);
      expect(rules.any((r) => r.ruleType == 10 && r.value == '2024-12-31'),
          isTrue);
    });

    test('empty filter produces empty rules', () {
      const filter = DocumentsFilter(ordering: '-created');
      expect(documentsFilterToFilterRules(filter), isEmpty);
    });

    test('round-trip: filter → rules → filter preserves fields', () {
      const original = DocumentsFilter(
        query: 'test',
        correspondentId: 3,
        documentTypeId: 4,
        tagIds: [1, 2],
        ordering: '-created',
      );
      final rules = documentsFilterToFilterRules(original);
      final restored = filterRulesToDocumentsFilter(rules, original.ordering);
      expect(restored.query, original.query);
      expect(restored.correspondentId, original.correspondentId);
      expect(restored.documentTypeId, original.documentTypeId);
      expect(restored.tagIds, containsAll(original.tagIds!));
      expect(restored.ordering, original.ordering);
    });
  });

  group('parseOrdering', () {
    test('parses descending ordering', () {
      final (field, reverse) = parseOrdering('-created');
      expect(field, 'created');
      expect(reverse, isTrue);
    });

    test('parses ascending ordering', () {
      final (field, reverse) = parseOrdering('title');
      expect(field, 'title');
      expect(reverse, isFalse);
    });
  });
}
