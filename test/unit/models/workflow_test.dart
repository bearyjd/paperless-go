import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/models/workflow.dart';

void main() {
  group('WorkflowTrigger', () {
    test('parses from JSON', () {
      final json = {
        'id': 1,
        'type': 1,
        'sources': [1, 2],
        'filter_filename': '*.pdf',
        'filter_path': null,
        'filter_mailrule': null,
        'matching_algorithm': 1,
        'match': 'invoice',
        'is_insensitive': true,
        'filter_has_tags': [3],
        'filter_has_correspondent': 2,
        'filter_has_document_type': null,
      };
      final trigger = WorkflowTrigger.fromJson(json);
      expect(trigger.id, 1);
      expect(trigger.type, 1);
      expect(trigger.sources, [1, 2]);
      expect(trigger.filterFilename, '*.pdf');
      expect(trigger.match, 'invoice');
      expect(trigger.isInsensitive, true);
      expect(trigger.filterHasTags, [3]);
      expect(trigger.filterHasCorrespondent, 2);
      expect(trigger.filterHasDocumentType, isNull);
    });

    test('round-trips through toJson/fromJson', () {
      final trigger = WorkflowTrigger(
        id: 5,
        type: 2,
        sources: [3],
        filterFilename: null,
        filterPath: '/docs',
        filterMailrule: null,
        matchingAlgorithm: 0,
        match: '',
        isInsensitive: false,
        filterHasTags: [],
        filterHasCorrespondent: null,
        filterHasDocumentType: 7,
      );
      final restored = WorkflowTrigger.fromJson(trigger.toJson());
      expect(restored, trigger);
    });
  });

  group('WorkflowAction', () {
    test('parses from JSON', () {
      final json = {
        'id': 1,
        'type': 1,
        'assign_title': null,
        'assign_tags': [3, 5],
        'assign_correspondent': 2,
        'assign_document_type': 4,
        'assign_storage_path': null,
        'assign_owner': null,
        'assign_view_users': <int>[],
        'assign_view_groups': <int>[],
        'assign_change_users': <int>[],
        'assign_change_groups': <int>[],
        'assign_custom_fields': <int>[],
      };
      final action = WorkflowAction.fromJson(json);
      expect(action.id, 1);
      expect(action.type, 1);
      expect(action.assignTags, [3, 5]);
      expect(action.assignCorrespondent, 2);
      expect(action.assignDocumentType, 4);
      expect(action.assignStoragePath, isNull);
    });

    test('round-trips through toJson/fromJson', () {
      final action = WorkflowAction(
        id: 2,
        type: 2,
        assignTitle: 'Test',
        assignTags: [1],
        assignCorrespondent: null,
        assignDocumentType: null,
        assignStoragePath: 3,
        assignOwner: null,
        assignViewUsers: [],
        assignViewGroups: [],
        assignChangeUsers: [],
        assignChangeGroups: [],
        assignCustomFields: [],
      );
      final restored = WorkflowAction.fromJson(action.toJson());
      expect(restored, action);
    });
  });

  group('Workflow', () {
    test('parses from JSON with nested triggers and actions', () {
      final json = {
        'id': 1,
        'name': 'Auto-tag invoices',
        'order': 0,
        'enabled': true,
        'triggers': [
          {
            'id': 1,
            'type': 1,
            'sources': [1, 2],
            'filter_filename': '*.pdf',
            'filter_path': null,
            'filter_mailrule': null,
            'matching_algorithm': 1,
            'match': 'invoice',
            'is_insensitive': true,
            'filter_has_tags': <int>[],
            'filter_has_correspondent': null,
            'filter_has_document_type': null,
          }
        ],
        'actions': [
          {
            'id': 1,
            'type': 1,
            'assign_title': null,
            'assign_tags': [3],
            'assign_correspondent': 2,
            'assign_document_type': null,
            'assign_storage_path': null,
            'assign_owner': null,
            'assign_view_users': <int>[],
            'assign_view_groups': <int>[],
            'assign_change_users': <int>[],
            'assign_change_groups': <int>[],
            'assign_custom_fields': <int>[],
          }
        ],
      };
      final workflow = Workflow.fromJson(json);
      expect(workflow.id, 1);
      expect(workflow.name, 'Auto-tag invoices');
      expect(workflow.enabled, true);
      expect(workflow.triggers.length, 1);
      expect(workflow.triggers.first.type, 1);
      expect(workflow.actions.length, 1);
      expect(workflow.actions.first.assignTags, [3]);
    });

    test('handles empty triggers and actions', () {
      final json = {
        'id': 2,
        'name': 'Empty workflow',
        'order': 1,
        'enabled': false,
        'triggers': <Map<String, dynamic>>[],
        'actions': <Map<String, dynamic>>[],
      };
      final workflow = Workflow.fromJson(json);
      expect(workflow.triggers, isEmpty);
      expect(workflow.actions, isEmpty);
      expect(workflow.enabled, false);
    });

    test('round-trips through toJson/fromJson', () {
      final workflow = Workflow(
        id: 3,
        name: 'Test workflow',
        order: 5,
        enabled: true,
        triggers: [
          WorkflowTrigger(
            id: 10,
            type: 3,
            sources: [],
            filterFilename: null,
            filterPath: null,
            filterMailrule: null,
            matchingAlgorithm: 0,
            match: '',
            isInsensitive: false,
            filterHasTags: [],
            filterHasCorrespondent: null,
            filterHasDocumentType: null,
          ),
        ],
        actions: [],
      );
      final restored = Workflow.fromJson(workflow.toJson());
      expect(restored, workflow);
    });
  });
}
