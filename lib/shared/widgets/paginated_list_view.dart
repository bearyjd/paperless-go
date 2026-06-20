import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';

/// Shared pull-to-refresh + infinite-scroll scaffold used by the documents,
/// inbox, and trash lists.
///
/// Owns the [RefreshIndicator], the scroll-threshold loadMore trigger, and the
/// trailing "loading more" spinner. Callers supply their own content [slivers]
/// (headers, the item list, etc.) WITHOUT a trailing spinner item — this widget
/// appends the spinner when [isLoadingMore] is true.
///
/// The pagination race guard (`identical(state.valueOrNull, loadingState)`)
/// lives in each notifier's `loadMore()` and is intentionally NOT duplicated
/// here — this is a widget extraction only.
class PaginatedListView extends StatelessWidget {
  const PaginatedListView({
    super.key,
    required this.onRefresh,
    required this.onLoadMore,
    required this.isLoadingMore,
    required this.slivers,
    this.loadMoreThreshold = 200,
  });

  /// Pull-to-refresh handler.
  final Future<void> Function() onRefresh;

  /// Called when the user scrolls within [loadMoreThreshold] px of the end.
  final VoidCallback onLoadMore;

  /// Whether a next-page fetch is in flight (drives the trailing spinner).
  final bool isLoadingMore;

  /// Screen-specific content slivers (headers, the item list, etc.).
  final List<Widget> slivers;

  /// Distance from the bottom (in px) at which to trigger [onLoadMore].
  final double loadMoreThreshold;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - loadMoreThreshold) {
            onLoadMore();
          }
          return false;
        },
        child: CustomScrollView(
          slivers: [
            ...slivers,
            if (isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(Spacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
