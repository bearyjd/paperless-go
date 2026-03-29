import '../../core/models/saved_view.dart';
import 'documents_notifier.dart';

// Paperless-ngx filter rule type constants
const int _kRuleTitle = 0;
const int _kRuleTitleWord = 1;
const int _kRuleExtendedMatch = 2;
const int _kRuleCorrespondent = 3;
const int _kRuleDocumentType = 4;
const int _kRuleHasTag = 6;
const int _kRuleHasAnyTag = 7;
const int _kRuleCreatedAfter = 9;
const int _kRuleCreatedBefore = 10;
const int _kRuleFullTextQuery = 22;

/// Converts a saved view's [filterRules] + [ordering] to a [DocumentsFilter].
DocumentsFilter filterRulesToDocumentsFilter(
    List<FilterRule> rules, String ordering) {
  String? query;
  int? correspondentId;
  int? documentTypeId;
  List<int>? tagIds;
  DateTime? createdDateFrom;
  DateTime? createdDateTo;

  for (final rule in rules) {
    switch (rule.ruleType) {
      case _kRuleTitle:
      case _kRuleTitleWord:
      case _kRuleExtendedMatch:
      case _kRuleFullTextQuery:
        // If multiple query-type rules exist, the last one wins.
        // Paperless-ngx web UI may create views with both title and
        // full-text rules; we collapse them to a single query here.
        if (rule.value != null && rule.value!.isNotEmpty) {
          query = rule.value;
        }
      case _kRuleCorrespondent:
        correspondentId = int.tryParse(rule.value ?? '');
      case _kRuleDocumentType:
        documentTypeId = int.tryParse(rule.value ?? '');
      case _kRuleHasTag:
      case _kRuleHasAnyTag:
        final id = int.tryParse(rule.value ?? '');
        if (id != null) {
          tagIds = [...?tagIds, id];
        }
      case _kRuleCreatedAfter:
        final date = DateTime.tryParse(rule.value ?? '');
        if (date != null) createdDateFrom = date;
      case _kRuleCreatedBefore:
        final date = DateTime.tryParse(rule.value ?? '');
        if (date != null) createdDateTo = date;
    }
  }

  return DocumentsFilter(
    query: query,
    ordering: ordering,
    tagIds: tagIds,
    correspondentId: correspondentId,
    documentTypeId: documentTypeId,
    createdDateFrom: createdDateFrom,
    createdDateTo: createdDateTo,
  );
}

/// Converts a [DocumentsFilter] to filter rules for saving as a saved view.
List<FilterRule> documentsFilterToFilterRules(DocumentsFilter filter) {
  final rules = <FilterRule>[];

  if (filter.query != null && filter.query!.isNotEmpty) {
    rules.add(FilterRule(ruleType: _kRuleFullTextQuery, value: filter.query));
  }
  if (filter.correspondentId != null) {
    rules.add(FilterRule(
        ruleType: _kRuleCorrespondent,
        value: filter.correspondentId.toString()));
  }
  if (filter.documentTypeId != null) {
    rules.add(FilterRule(
        ruleType: _kRuleDocumentType,
        value: filter.documentTypeId.toString()));
  }
  // Note: Paperless-ngx distinguishes "has tag" (type 6, all match) from
  // "has any tag" (type 7, any match). During conversion, both are collapsed
  // into tagIds and re-emitted as type 6. This means a saved view originally
  // using "any" semantics will become "all" after re-saving from the app.
  for (final tagId in filter.tagIds ?? []) {
    rules.add(FilterRule(ruleType: _kRuleHasTag, value: tagId.toString()));
  }
  if (filter.createdDateFrom != null) {
    rules.add(FilterRule(
        ruleType: _kRuleCreatedAfter,
        value: filter.createdDateFrom!.toIso8601String().split('T').first));
  }
  if (filter.createdDateTo != null) {
    rules.add(FilterRule(
        ruleType: _kRuleCreatedBefore,
        value: filter.createdDateTo!.toIso8601String().split('T').first));
  }

  return rules;
}

/// Parses an ordering string (e.g., `'-created'`) into a `(sortField, sortReverse)` record.
(String sortField, bool sortReverse) parseOrdering(String ordering) {
  if (ordering.isEmpty) return ('created', true);
  if (ordering.startsWith('-')) {
    return (ordering.substring(1), true);
  }
  return (ordering, false);
}
