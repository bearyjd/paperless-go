import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/api/api_providers.dart';
import '../../core/models/document.dart';
import '../../shared/widgets/document_card.dart';

part 'similar_screen.g.dart';

@riverpod
Future<List<Document>> similarDocuments(Ref ref, int documentId) async {
  final api = ref.watch(paperlessApiProvider);
  final response = await api.getDocuments(
    moreLikeId: documentId,
    pageSize: 20,
    truncateContent: true,
  );
  return response.results;
}

class SimilarScreen extends ConsumerWidget {
  final int documentId;
  const SimilarScreen({super.key, required this.documentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final similarAsync = ref.watch(similarDocumentsProvider(documentId));
    final tagsAsync = ref.watch(tagsProvider);
    final correspondentsAsync = ref.watch(correspondentsProvider);
    final docTypesAsync = ref.watch(documentTypesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Similar Documents')),
      body: similarAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48,
                  color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text('Failed to find similar documents'),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(similarDocumentsProvider(documentId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (documents) {
          final tags = tagsAsync.valueOrNull ?? {};
          final correspondents = correspondentsAsync.valueOrNull ?? {};
          final docTypes = docTypesAsync.valueOrNull ?? {};

          if (documents.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.find_in_page, size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('No similar documents found',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            );
          }

          final api = ref.watch(paperlessApiProvider);
          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              return DocumentCard(
                document: doc,
                tags: tags,
                correspondents: correspondents,
                documentTypes: docTypes,
                thumbnailUrl: api.thumbnailUrl(doc.id),
                authToken: api.authToken,
                onTap: () => context.push('/documents/${doc.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
