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
                        direction: DismissDirection.startToEnd,
                        background: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 24),
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(Icons.done,
                              color: Theme.of(context).colorScheme.onPrimaryContainer),
                        ),
                        confirmDismiss: (_) async {
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
}
