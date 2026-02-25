import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/api/api_providers.dart';
import '../../core/models/document.dart';

part 'inbox_notifier.g.dart';

class InboxState {
  final List<Document> documents;
  final int totalCount;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;

  const InboxState({
    this.documents = const [],
    this.totalCount = 0,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
  });

  InboxState copyWith({
    List<Document>? documents,
    int? totalCount,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
  }) {
    return InboxState(
      documents: documents ?? this.documents,
      totalCount: totalCount ?? this.totalCount,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

@riverpod
class InboxNotifier extends _$InboxNotifier {
  static const _pageSize = 25;

  @override
  Future<InboxState> build() async {
    final api = ref.watch(paperlessApiProvider);
    final response = await api.getDocuments(
      isInInbox: true,
      pageSize: _pageSize,
      ordering: '-created',
    );
    return InboxState(
      documents: response.results,
      totalCount: response.count,
      hasMore: response.next != null,
      currentPage: 1,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final api = ref.read(paperlessApiProvider);
      final nextPage = current.currentPage + 1;
      final response = await api.getDocuments(
        isInInbox: true,
        pageSize: _pageSize,
        page: nextPage,
        ordering: '-created',
      );

      final fresh = state.valueOrNull ?? current;
      state = AsyncData(fresh.copyWith(
        documents: [...fresh.documents, ...response.results],
        isLoadingMore: false,
        hasMore: response.next != null,
        currentPage: nextPage,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  /// Remove a document from inbox by removing inbox tags.
  /// Throws on API failure so the caller can handle rollback.
  Future<void> removeFromInbox(Document doc) async {
    final api = ref.read(paperlessApiProvider);
    final tagsMap = await ref.read(tagsProvider.future);
    final inboxTagIds = tagsMap.values
        .where((t) => t.isInboxTag)
        .map((t) => t.id)
        .toSet();
    final newTags = doc.tags.where((id) => !inboxTagIds.contains(id)).toList();

    // API call first — if it fails, exception propagates to caller
    await api.updateDocument(doc.id, {'tags': newTags});

    // Only update local state on success
    final current = state.valueOrNull;
    if (current != null) {
      final remaining = current.documents.where((d) => d.id != doc.id).toList();
      state = AsyncData(current.copyWith(
        documents: remaining,
        totalCount: (current.totalCount - 1).clamp(0, current.totalCount),
      ));
    }
  }
}
