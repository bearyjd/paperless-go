import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/api/api_providers.dart';
import '../../core/models/document.dart';

part 'search_notifier.g.dart';

sealed class SearchState {
  const SearchState();

  const factory SearchState.idle() = SearchIdle;
  const factory SearchState.loading() = SearchLoading;
  const factory SearchState.results(
    List<Document> documents,
    int totalCount,
    String query,
  ) = SearchResults;
  const factory SearchState.error(String message) = SearchError;

  T when<T>({
    required T Function() idle,
    required T Function() loading,
    required T Function(List<Document> documents, int totalCount, String query) results,
    required T Function(String message) error,
  }) {
    return switch (this) {
      SearchIdle() => idle(),
      SearchLoading() => loading(),
      SearchResults(documents: var d, totalCount: var c, query: var q) => results(d, c, q),
      SearchError(message: var m) => error(m),
    };
  }
}

class SearchIdle extends SearchState {
  const SearchIdle();
}

class SearchLoading extends SearchState {
  const SearchLoading();
}

class SearchResults extends SearchState {
  final List<Document> documents;
  final int totalCount;
  final String query;
  const SearchResults(this.documents, this.totalCount, this.query);
}

class SearchError extends SearchState {
  final String message;
  const SearchError(this.message);
}

@riverpod
class SearchNotifier extends _$SearchNotifier {
  @override
  SearchState build() => const SearchState.idle();

  Future<void> search(String query) async {
    state = const SearchState.loading();

    try {
      final api = ref.read(paperlessApiProvider);
      final response = await api.getDocuments(
        query: query,
        pageSize: 50,
        truncateContent: true,
      );
      state = SearchState.results(
        response.results,
        response.count,
        query,
      );
    } catch (e) {
      state = SearchState.error(e.toString());
    }
  }

  void clear() {
    state = const SearchState.idle();
  }
}

@riverpod
class AutocompleteNotifier extends _$AutocompleteNotifier {
  @override
  List<String> build() => [];

  Future<void> suggest(String term) async {
    if (term.length < 2) {
      state = [];
      return;
    }
    try {
      final api = ref.read(paperlessApiProvider);
      state = await api.searchAutocomplete(term);
    } catch (_) {
      state = [];
    }
  }

  void clear() => state = [];
}
