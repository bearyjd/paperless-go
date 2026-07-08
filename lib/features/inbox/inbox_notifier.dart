import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/api/api_providers.dart';
import '../../core/models/document.dart';
import '../../core/api/api_error_mapper.dart';
import '../scanner/processing/metadata_matcher.dart';

part 'inbox_notifier.g.dart';

class InboxState {
  final List<Document> documents;
  final int totalCount;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? loadMoreError;

  const InboxState({
    this.documents = const [],
    this.totalCount = 0,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.loadMoreError,
  });

  InboxState copyWith({
    List<Document>? documents,
    int? totalCount,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? loadMoreError,
    bool clearLoadMoreError = false,
  }) {
    return InboxState(
      documents: documents ?? this.documents,
      totalCount: totalCount ?? this.totalCount,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      loadMoreError:
          clearLoadMoreError ? null : (loadMoreError ?? this.loadMoreError),
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

    final loadingState = current.copyWith(isLoadingMore: true);
    state = AsyncData(loadingState);

    try {
      final api = ref.read(paperlessApiProvider);
      final nextPage = current.currentPage + 1;
      final response = await api.getDocuments(
        isInInbox: true,
        pageSize: _pageSize,
        page: nextPage,
        ordering: '-created',
      );

      // A concurrent refresh replaced the list while this page was in flight —
      // discard the stale page instead of appending to a fresh list.
      // identical() relies on AsyncData(x).valueOrNull returning the same
      // instance; do NOT weaken to == (a refresh yields an equal-by-value state
      // and the guard would stop firing).
      if (!identical(state.valueOrNull, loadingState)) return;
      state = AsyncData(loadingState.copyWith(
        documents: [...loadingState.documents, ...response.results],
        isLoadingMore: false,
        hasMore: response.next != null,
        currentPage: nextPage,
      ));
    } catch (e) {
      if (!identical(state.valueOrNull, loadingState)) return;
      state = AsyncData(loadingState.copyWith(
        isLoadingMore: false,
        loadMoreError: 'Failed to load more: ${friendlyApiMessage(e)}',
      ));
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  /// Document ids with a remove-from-inbox in flight. Guards against the swipe
  /// gesture and the actions menu both firing for the same document, which would
  /// issue a redundant API write and decrement totalCount twice.
  final Set<int> _removing = {};

  /// Accept OCR/match suggestions for [doc]: applies suggested tags,
  /// correspondent, and document type in a single update that also strips the
  /// inbox tags (so accepting files the document out of the inbox).
  ///
  /// Returns the document's previous values for those fields so the caller
  /// can offer Undo via [undoAccept]. Throws on API failure. A concurrent
  /// accept/remove in flight for the same document is a no-op returning null.
  Future<Map<String, dynamic>?> acceptSuggestions(
    Document doc,
    MetadataSuggestions suggestions,
  ) async {
    if (!_removing.add(doc.id)) return null;
    try {
      final api = ref.read(paperlessApiProvider);
      final tagsMap = await ref.read(tagsProvider.future);
      final inboxTagIds =
          tagsMap.values.where((t) => t.isInboxTag).map((t) => t.id).toSet();

      final newTags = <int>{
        ...doc.tags.where((id) => !inboxTagIds.contains(id)),
        ...suggestions.tagIds,
      }.toList();

      final previous = <String, dynamic>{
        'tags': doc.tags,
        'correspondent': doc.correspondent,
        'document_type': doc.documentType,
      };

      final data = <String, dynamic>{'tags': newTags};
      if (suggestions.correspondentId != null && doc.correspondent == null) {
        data['correspondent'] = suggestions.correspondentId;
      }
      if (suggestions.documentTypeId != null && doc.documentType == null) {
        data['document_type'] = suggestions.documentTypeId;
      }

      await api.updateDocument(doc.id, data);

      final current = state.valueOrNull;
      if (current != null) {
        state = AsyncData(current.copyWith(
          documents: current.documents.where((d) => d.id != doc.id).toList(),
          totalCount: (current.totalCount - 1).clamp(0, current.totalCount),
        ));
      }
      return previous;
    } finally {
      _removing.remove(doc.id);
    }
  }

  /// Revert a previously accepted document to [previous] (from
  /// [acceptSuggestions]) and reload the inbox so it reappears.
  Future<void> undoAccept(int documentId, Map<String, dynamic> previous) async {
    final api = ref.read(paperlessApiProvider);
    await api.updateDocument(documentId, previous);
    ref.invalidateSelf();
  }

  /// Remove a document from inbox by removing inbox tags.
  /// Throws on API failure so the caller can handle rollback. A concurrent
  /// remove already in flight for the same document is a no-op.
  Future<void> removeFromInbox(Document doc) async {
    if (!_removing.add(doc.id)) return;
    try {
      final api = ref.read(paperlessApiProvider);
      final tagsMap = await ref.read(tagsProvider.future);
      final inboxTagIds = tagsMap.values
          .where((t) => t.isInboxTag)
          .map((t) => t.id)
          .toSet();
      final newTags =
          doc.tags.where((id) => !inboxTagIds.contains(id)).toList();

      // API call first — if it fails, exception propagates to caller
      await api.updateDocument(doc.id, {'tags': newTags});

      // Only update local state on success
      final current = state.valueOrNull;
      if (current != null) {
        final remaining =
            current.documents.where((d) => d.id != doc.id).toList();
        state = AsyncData(current.copyWith(
          documents: remaining,
          totalCount: (current.totalCount - 1).clamp(0, current.totalCount),
        ));
      }
    } finally {
      _removing.remove(doc.id);
    }
  }
}
