import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_providers.dart';
import '../../core/api/api_error_mapper.dart';
import '../../core/models/correspondent.dart';
import '../../core/models/document.dart';
import '../../core/models/document_type.dart';
import '../../shared/widgets/document_card.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/metadata_dropdown.dart';
import '../../shared/widgets/paginated_list_view.dart';
import 'inbox_notifier.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inboxState = ref.watch(inboxNotifierProvider);

    // Surface loadMore failures as a SnackBar (mirrors the documents screen).
    ref.listen(inboxNotifierProvider, (prev, next) {
      final error = next.valueOrNull?.loadMoreError;
      if (error != null && error != prev?.valueOrNull?.loadMoreError) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
      }
    });
    final tagsAsync = ref.watch(tagsProvider);
    final correspondentsAsync = ref.watch(correspondentsProvider);
    final docTypesAsync = ref.watch(documentTypesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
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
              Text(friendlyApiMessage(err, fallback: 'Failed to load inbox.'), style: Theme.of(context).textTheme.bodySmall),
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

          return PaginatedListView(
            onRefresh: () => ref.read(inboxNotifierProvider.notifier).refresh(),
            onLoadMore: () => ref.read(inboxNotifierProvider.notifier).loadMore(),
            isLoadingMore: inbox.isLoadingMore,
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
                    itemCount: inbox.documents.length,
                    itemBuilder: (context, index) {
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
                          return _removeFromInbox(context, ref, doc);
                        },
                        child: DocumentCard(
                          document: doc,
                          tags: tags,
                          correspondents: correspondents,
                          documentTypes: docTypes,
                          thumbnailUrl: api.thumbnailUrl(doc.id),
                          authToken: api.authToken,
                          onTap: () => context.push('/documents/${doc.id}'),
                          // Non-swipe accessible alternative to the Dismissible
                          // gestures (kept above for sighted users).
                          trailing: PopupMenuButton<String>(
                            tooltip: 'Inbox actions',
                            onSelected: (action) async {
                              if (action == 'assign') {
                                _showQuickAssign(context, ref, doc.id);
                                return;
                              }
                              await _removeFromInbox(context, ref, doc);
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'remove',
                                child: ListTile(
                                  leading: Icon(Icons.done),
                                  title: Text('Remove from inbox'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'assign',
                                child: ListTile(
                                  leading: Icon(Icons.edit),
                                  title: Text('Quick assign'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
          );
        },
      ),
    );
  }

  /// Remove [doc] from the inbox, surfacing success/failure as a SnackBar.
  /// Returns true on success so the swipe path can confirm dismissal; the
  /// actions-menu path ignores the result. The notifier guards against a
  /// concurrent remove for the same document.
  Future<bool> _removeFromInbox(
      BuildContext context, WidgetRef ref, Document doc) async {
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
          SnackBar(content: Text('Failed to remove: ${friendlyApiMessage(e)}')),
        );
      }
      return false;
    }
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
          MetadataDropdown<Correspondent>(
            label: 'Correspondent',
            value: correspondents[_correspondentId],
            items: correspondents.values.toList(),
            displayName: (c) => c.name,
            onChanged: (c) => setState(() => _correspondentId = c?.id),
          ),
          const SizedBox(height: 12),

          // Document Type
          MetadataDropdown<DocumentType>(
            label: 'Document Type',
            value: docTypes[_documentTypeId],
            items: docTypes.values.toList(),
            displayName: (dt) => dt.name,
            onChanged: (dt) => setState(() => _documentTypeId = dt?.id),
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
          SnackBar(content: Text('Failed to update: ${friendlyApiMessage(e)}')),
        );
        setState(() => _saving = false);
      }
    }
  }
}
