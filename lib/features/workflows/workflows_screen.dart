import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_providers.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_skeleton.dart';

class WorkflowsScreen extends ConsumerWidget {
  const WorkflowsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workflowsAsync = ref.watch(workflowsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workflows'),
      ),
      body: workflowsAsync.when(
        loading: () => const WorkflowsSkeleton(),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (workflows) {
          if (workflows.isEmpty) {
            return const EmptyState(
              icon: Icons.route_outlined,
              title: 'No workflows configured',
              description: 'Workflows are created in the Paperless-ngx web UI',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(workflowsProvider),
            child: ListView.builder(
              itemCount: workflows.length,
              itemBuilder: (context, i) {
                final workflow = workflows[i];
                return ListTile(
                  title: Text(workflow.name),
                  subtitle: Text(
                    '${workflow.triggers.length} trigger${workflow.triggers.length == 1 ? '' : 's'} · '
                    '${workflow.actions.length} action${workflow.actions.length == 1 ? '' : 's'}',
                  ),
                  trailing: Switch(
                    value: workflow.enabled,
                    onChanged: (value) async {
                      try {
                        final api = ref.read(paperlessApiProvider);
                        await api.toggleWorkflow(workflow.id, enabled: value);
                        ref.invalidate(workflowsProvider);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to update workflow: $e')),
                          );
                        }
                      }
                    },
                  ),
                  onTap: () => context.push('/workflows/${workflow.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
