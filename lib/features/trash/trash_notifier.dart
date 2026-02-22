import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/api/api_providers.dart';
import '../../core/models/document.dart';

part 'trash_notifier.g.dart';

class TrashState {
  final List<Document> documents;
  final int totalCount;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;

  const TrashState({
    this.documents = const [],
    this.totalCount = 0,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
  });

  TrashState copyWith({
    List<Document>? documents,
    int? totalCount,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
  }) {
    return TrashState(
      documents: documents ?? this.documents,
      totalCount: totalCount ?? this.totalCount,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

@riverpod
class TrashNotifier extends _$TrashNotifier {
  static const _pageSize = 25;

  @override
  Future<TrashState> build() async {
    return _fetchPage(1);
  }

  Future<TrashState> _fetchPage(int page) async {
    final api = ref.read(paperlessApiProvider);
    final response = await api.getTrashedDocuments(
      page: page,
      pageSize: _pageSize,
    );
    return TrashState(
      documents: response.results,
      totalCount: response.count,
      hasMore: response.next != null,
      currentPage: page,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final api = ref.read(paperlessApiProvider);
      final nextPage = current.currentPage + 1;
      final response = await api.getTrashedDocuments(
        page: nextPage,
        pageSize: _pageSize,
      );

      state = AsyncData(current.copyWith(
        documents: [...current.documents, ...response.results],
        isLoadingMore: false,
        hasMore: response.next != null,
        currentPage: nextPage,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(1));
  }

  Future<bool> restoreDocuments(List<int> ids) async {
    try {
      final api = ref.read(paperlessApiProvider);
      await api.restoreFromTrash(ids);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> permanentlyDelete(List<int> ids) async {
    try {
      final api = ref.read(paperlessApiProvider);
      await api.emptyTrash(ids);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }
}
