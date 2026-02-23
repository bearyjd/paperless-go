import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_providers.dart';
import '../../shared/widgets/document_card.dart';
import '../../shared/widgets/loading_skeleton.dart';
import 'inbox_notifier.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inboxState = ref.watch(inboxNotifierProvider);
    final tagsAsync = ref.watch(tagsProvider);
    final correspondentsAsync = ref.watch(correspondentsProvider);
    final docTypesAsync = ref.watch(documentTypesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: inboxState.when(
        loading: () => const DocumentListSkeleton(),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text('Failed to load inbox', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(err.toString(), style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(inboxNotifierProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (inbox) {
          final tags = tagsAsync.valueOrNull ?? {};
          final correspondents = correspondentsAsync.valueOrNull ?? {};
          final docTypes = docTypesAsync.valueOrNull ?? {};
          final api = ref.watch(paperlessApiProvider);

          if (inbox.documents.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined, size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('Inbox is empty',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('All caught up!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(inboxNotifierProvider.notifier).refresh(),
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollEndNotification &&
                    notification.metrics.pixels >=
                        notification.metrics.maxScrollExtent - 200) {
                  ref.read(inboxNotifierProvider.notifier).loadMore();
                }
                return false;
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        'Inbox (${inbox.totalCount})',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  SliverList.builder(
                    itemCount: inbox.documents.length + (inbox.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= inbox.documents.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final doc = inbox.documents[index];
                      return Dismissible(
                        key: ValueKey(doc.id),
                        direction: DismissDirection.horizontal,
                        background: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 24),
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(Icons.done,
                              color: Theme.of(context).colorScheme.onPrimaryContainer),
                        ),
                        secondaryBackground: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          color: Theme.of(context).colorScheme.tertiaryContainer,
                          child: Icon(Icons.edit,
                              color: Theme.of(context).colorScheme.onTertiaryContainer),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.endToStart) {
                            // Quick-assign: show bottom sheet, don't actually dismiss
                            if (context.mounted) {
                              _showQuickAssign(context, ref, doc.id);
                            }
                            return false;
                          }
                          // Swipe right: remove from inbox
                          try {
                            await ref.read(inboxNotifierProvider.notifier).removeFromInbox(doc);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Removed "${doc.title}" from inbox')),
                              );
                            }
                            return true;
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to remove: $e')),
                              );
                            }
                            return false;
                          }
                        },
                        child: DocumentCard(
                          document: doc,
                          tags: tags,
                          correspondents: correspondents,
                          documentTypes: docTypes,
                          thumbnailUrl: api.thumbnailUrl(doc.id),
                          authToken: api.authToken,
                          onTap: () => context.push('/documents/${doc.id}'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showQuickAssign(BuildContext context, WidgetRef ref, int documentId) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _QuickAssignSheet(
        documentId: documentId,
        onDone: () {
          ref.invalidate(inboxNotifierProvider);
        },
      ),
    );
  }
}

class _QuickAssignSheet extends ConsumerStatefulWidget {
  final int documentId;
  final VoidCallback onDone;

  const _QuickAssignSheet({required this.documentId, required this.onDone});

  @override
  ConsumerState<_QuickAssignSheet> createState() => _QuickAssignSheetState();
}

class _QuickAssignSheetState extends ConsumerState<_QuickAssignSheet> {
  int? _correspondentId;
  int? _documentTypeId;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final correspondentsAsync = ref.watch(correspondentsProvider);
    final docTypesAsync = ref.watch(documentTypesProvider);

    final correspondents = correspondentsAsync.valueOrNull ?? {};
    final docTypes = docTypesAsync.valueOrNull ?? {};

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Assign', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),

          // Correspondent
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Correspondent',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: _correspondentId,
                isExpanded: true,
                isDense: true,
                hint: const Text('None'),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('None')),
                  ...correspondents.values.map((c) => DropdownMenuItem<int?>(
                    value: c.id,
                    child: Text(c.name, overflow: TextOverflow.ellipsis),
                  )),
                ],
                onChanged: (v) => setState(() => _correspondentId = v),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Document Type
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Document Type',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: _documentTypeId,
                isExpanded: true,
                isDense: true,
                hint: const Text('None'),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('None')),
                  ...docTypes.values.map((dt) => DropdownMenuItem<int?>(
                    value: dt.id,
                    child: Text(dt.name, overflow: TextOverflow.ellipsis),
                  )),
                ],
                onChanged: (v) => setState(() => _documentTypeId = v),
              ),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Assign'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_correspondentId == null && _documentTypeId == null) {
      Navigator.pop(context);
      return;
    }
    setState(() => _saving = true);
    try {
      final api = ref.read(paperlessApiProvider);
      final data = <String, dynamic>{};
      if (_correspondentId != null) data['correspondent'] = _correspondentId;
      if (_documentTypeId != null) data['document_type'] = _documentTypeId;
      await api.updateDocument(widget.documentId, data);
      widget.onDone();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
        setState(() => _saving = false);
      }
    }
  }
}
