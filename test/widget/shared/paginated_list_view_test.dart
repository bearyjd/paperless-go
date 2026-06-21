import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/shared/widgets/paginated_list_view.dart';

void main() {
  group('PaginatedListView', () {
    testWidgets('shows the trailing spinner when isLoadingMore is true',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaginatedListView(
              onRefresh: () async {},
              onLoadMore: () {},
              isLoadingMore: true,
              slivers: const [
                SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows no spinner when isLoadingMore is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaginatedListView(
              onRefresh: () async {},
              onLoadMore: () {},
              isLoadingMore: false,
              slivers: const [
                SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('fires onLoadMore when scrolled to the end', (tester) async {
      var loadMoreCalls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaginatedListView(
              onRefresh: () async {},
              onLoadMore: () => loadMoreCalls++,
              isLoadingMore: false,
              slivers: [
                SliverList.builder(
                  itemCount: 50,
                  itemBuilder: (_, i) =>
                      SizedBox(height: 100, child: Text('item $i')),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.fling(
          find.byType(CustomScrollView), const Offset(0, -5000), 5000);
      await tester.pumpAndSettle();

      expect(loadMoreCalls, greaterThan(0));
    });
  });
}
