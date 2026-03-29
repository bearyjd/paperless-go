import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_providers.dart';
import '../../core/models/correspondent.dart';
import '../../core/models/document_type.dart';
import '../../core/models/storage_path.dart';
import '../../core/models/tag.dart';
import '../../core/models/workflow.dart';
import 'workflow_helpers.dart';

class WorkflowDetailScreen extends ConsumerWidget {
  final int workflowId;

  const WorkflowDetailScreen({super.key, required this.workflowId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workflowsAsync = ref.watch(workflowsProvider);
    final tagsAsync = ref.watch(tagsProvider);
    final correspondentsAsync = ref.watch(correspondentsProvider);
    final documentTypesAsync = ref.watch(documentTypesProvider);
    final storagePathsAsync = ref.watch(storagePathsProvider);

    return workflowsAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Workflow')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Workflow')),
        body: Center(child: Text('Error: $err')),
      ),
      data: (workflows) {
        final workflow = workflows.where((w) => w.id == workflowId).firstOrNull;
        if (workflow == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Workflow')),
            body: const Center(child: Text('Workflow not found')),
          );
        }

        final tags = tagsAsync.valueOrNull ?? <int, Tag>{};
        final correspondents = correspondentsAsync.valueOrNull ?? <int, Correspondent>{};
        final documentTypes = documentTypesAsync.valueOrNull ?? <int, DocumentType>{};
        final storagePaths = storagePathsAsync.valueOrNull ?? <int, StoragePath>{};

        return Scaffold(
          appBar: AppBar(
            title: Text(workflow.name),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => _confirmDelete(context, ref, workflow),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Status card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Chip(
                        label: Text(workflow.enabled ? 'Enabled' : 'Disabled'),
                        backgroundColor: workflow.enabled
                            ? Colors.green.withAlpha(40)
                            : Colors.grey.withAlpha(40),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Triggers section
              Text(
                'Triggers',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              if (workflow.triggers.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No triggers'),
                  ),
                )
              else
                ...workflow.triggers.map(
                  (trigger) => _TriggerCard(
                    trigger: trigger,
                    tags: tags,
                    correspondents: correspondents,
                    documentTypes: documentTypes,
                  ),
                ),
              const SizedBox(height: 16),

              // Actions section
              Text(
                'Actions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              if (workflow.actions.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No actions'),
                  ),
                )
              else
                ...workflow.actions.map(
                  (action) => _ActionCard(
                    action: action,
                    tags: tags,
                    correspondents: correspondents,
                    documentTypes: documentTypes,
                    storagePaths: storagePaths,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Workflow workflow) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Workflow?'),
        content: Text('Delete "${workflow.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      final api = ref.read(paperlessApiProvider);
      await api.deleteWorkflow(workflow.id);
      ref.invalidate(workflowsProvider);
      if (context.mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workflow deleted')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete workflow: $e')),
        );
      }
    }
  }
}

class _TriggerCard extends StatelessWidget {
  final WorkflowTrigger trigger;
  final Map<int, Tag> tags;
  final Map<int, Correspondent> correspondents;
  final Map<int, DocumentType> documentTypes;

  const _TriggerCard({
    required this.trigger,
    required this.tags,
    required this.correspondents,
    required this.documentTypes,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      _InfoRow('Type', triggerTypeLabel(trigger.type)),
      if (trigger.sources.isNotEmpty)
        _InfoRow(
          'Sources',
          trigger.sources.map((s) => sourceLabel(s)).join(', '),
        ),
      if (trigger.match.isNotEmpty) ...[
        _InfoRow('Match', trigger.match),
        _InfoRow('Algorithm', matchingAlgorithmLabel(trigger.matchingAlgorithm)),
        if (trigger.isInsensitive)
          _InfoRow('Case insensitive', 'Yes'),
      ],
      if (trigger.filterFilename != null)
        _InfoRow('Filename filter', trigger.filterFilename!),
      if (trigger.filterPath != null)
        _InfoRow('Path filter', trigger.filterPath!),
      if (trigger.filterHasTags.isNotEmpty)
        _InfoRow(
          'Filter tags',
          trigger.filterHasTags
              .map((id) => tags[id]?.name ?? '#$id')
              .join(', '),
        ),
      if (trigger.filterHasCorrespondent != null)
        _InfoRow(
          'Filter correspondent',
          correspondents[trigger.filterHasCorrespondent]?.name ??
              '#${trigger.filterHasCorrespondent}',
        ),
      if (trigger.filterHasDocumentType != null)
        _InfoRow(
          'Filter doc type',
          documentTypes[trigger.filterHasDocumentType]?.name ??
              '#${trigger.filterHasDocumentType}',
        ),
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rows,
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final WorkflowAction action;
  final Map<int, Tag> tags;
  final Map<int, Correspondent> correspondents;
  final Map<int, DocumentType> documentTypes;
  final Map<int, StoragePath> storagePaths;

  const _ActionCard({
    required this.action,
    required this.tags,
    required this.correspondents,
    required this.documentTypes,
    required this.storagePaths,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      _InfoRow('Type', actionTypeLabel(action.type)),
      if (action.assignTitle != null && action.assignTitle!.isNotEmpty)
        _InfoRow('Assign title', action.assignTitle!),
      if (action.assignTags.isNotEmpty)
        _InfoRow(
          'Assign tags',
          action.assignTags
              .map((id) => tags[id]?.name ?? '#$id')
              .join(', '),
        ),
      if (action.assignCorrespondent != null)
        _InfoRow(
          'Assign correspondent',
          correspondents[action.assignCorrespondent]?.name ??
              '#${action.assignCorrespondent}',
        ),
      if (action.assignDocumentType != null)
        _InfoRow(
          'Assign doc type',
          documentTypes[action.assignDocumentType]?.name ??
              '#${action.assignDocumentType}',
        ),
      if (action.assignStoragePath != null)
        _InfoRow(
          'Assign storage path',
          storagePaths[action.assignStoragePath]?.name ??
              '#${action.assignStoragePath}',
        ),
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rows,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
