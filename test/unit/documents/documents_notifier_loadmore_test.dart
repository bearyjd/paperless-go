import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/api/api_providers.dart';
import 'package:paperless_go/core/api/paperless_api.dart';
import 'package:paperless_go/core/models/api_response.dart';
import 'package:paperless_go/core/models/document.dart';
import 'package:paperless_go/features/documents/documents_notifier.dart';

/// Fake API whose page-2 response can be gated, so we can deterministically
/// interleave a slow `loadMore()` with a concurrent `applyFilter()`.
class _FakeApi extends PaperlessApi {
  _FakeApi() : super(Dio());

  Completer<void>? page2Gate;

  @override
  Future<PaginatedResponse<Document>> getDocuments({
    int page = 1,
    int pageSize = 25,
    String? query,
    String ordering = '-created',
    bool? isInInbox,
    List<int>? tagIds,
    int? correspondentId,
    int? documentTypeId,
    int? moreLikeId,
    bool truncateContent = true,
    DateTime? createdDateFrom,
    DateTime? createdDateTo,
  }) async {
    if (page == 2) {
      final gate = page2Gate;
      if (gate != null) await gate.future;
      return _resp([_doc(3), _doc(4)], next: null);
    }
    // Page 1: the refreshed filter returns a completely different list.
    if (query == 'refreshed') {
      return _resp([_doc(99)], next: null);
    }
    return _resp([_doc(1), _doc(2)], next: 'page2');
  }
}

Document _doc(int id) => Document(id: id, title: 'doc$id');

PaginatedResponse<Document> _resp(List<Document> docs, {String? next}) =>
    PaginatedResponse(count: 100, next: next, results: docs);

void main() {
  group('DocumentsNotifier.loadMore race', () {
    test('discards its page when a concurrent applyFilter replaces the list',
        () async {
      final fake = _FakeApi();
      final container = ProviderContainer(
        overrides: [paperlessApiProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      // Initial load (page 1) → [1, 2].
      final initial = await container.read(documentsNotifierProvider.future);
      expect(initial.documents.map((d) => d.id), [1, 2]);

      final notifier = container.read(documentsNotifierProvider.notifier);

      // Begin loadMore (page 2) but hold its response in flight.
      fake.page2Gate = Completer<void>();
      final loadMoreFuture = notifier.loadMore();

      // While page 2 is pending, a filter change resets the list to [99].
      await notifier.applyFilter(const DocumentsFilter(query: 'refreshed'));
      expect(
        container.read(documentsNotifierProvider).value!.documents.map((d) => d.id),
        [99],
      );

      // Release the stale page-2 response.
      fake.page2Gate!.complete();
      await loadMoreFuture;

      // The stale page must NOT be appended onto the refreshed list.
      final finalIds = container
          .read(documentsNotifierProvider)
          .value!
          .documents
          .map((d) => d.id)
          .toList();
      expect(
        finalIds,
        [99],
        reason: 'stale page-2 results leaked over a concurrent refresh',
      );
    });

    test('appends normally when no concurrent refresh happens', () async {
      final fake = _FakeApi();
      final container = ProviderContainer(
        overrides: [paperlessApiProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      await container.read(documentsNotifierProvider.future);
      final notifier = container.read(documentsNotifierProvider.notifier);

      await notifier.loadMore();

      final ids = container
          .read(documentsNotifierProvider)
          .value!
          .documents
          .map((d) => d.id)
          .toList();
      expect(ids, [1, 2, 3, 4]);
      expect(container.read(documentsNotifierProvider).value!.hasMore, isFalse);
    });
  });
}
