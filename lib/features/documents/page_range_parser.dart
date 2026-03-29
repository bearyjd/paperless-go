class PageRangeResult {
  final bool isValid;
  final String? normalized;
  final String? error;

  const PageRangeResult.valid(String this.normalized)
      : isValid = true,
        error = null;

  const PageRangeResult.invalid(String this.error)
      : isValid = false,
        normalized = null;
}

PageRangeResult parsePageRanges(String input, {required int totalPages}) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) {
    return const PageRangeResult.invalid('Page ranges cannot be empty');
  }

  final parts = trimmed.split(',');
  final normalizedParts = <String>[];

  for (final part in parts) {
    final stripped = part.trim();
    if (stripped.isEmpty) continue;

    if (stripped.contains('-')) {
      final bounds = stripped.split('-');
      if (bounds.length != 2) {
        return PageRangeResult.invalid('Invalid range: "$stripped"');
      }
      final start = int.tryParse(bounds[0].trim());
      final end = int.tryParse(bounds[1].trim());
      if (start == null || end == null) {
        return PageRangeResult.invalid('Invalid number in range: "$stripped"');
      }
      if (start < 1) {
        return PageRangeResult.invalid('Page numbers start at 1, got $start');
      }
      if (end > totalPages) {
        return PageRangeResult.invalid(
            'Page $end exceeds document length of $totalPages');
      }
      if (start > end) {
        return PageRangeResult.invalid(
            'Start page cannot be greater than end page in "$stripped"');
      }
      normalizedParts.add('$start-$end');
    } else {
      final page = int.tryParse(stripped);
      if (page == null) {
        return PageRangeResult.invalid('Invalid page number: "$stripped"');
      }
      if (page < 1) {
        return PageRangeResult.invalid('Page numbers start at 1, got $page');
      }
      if (page > totalPages) {
        return PageRangeResult.invalid(
            'Page $page exceeds document length of $totalPages');
      }
      normalizedParts.add('$page');
    }
  }

  if (normalizedParts.isEmpty) {
    return const PageRangeResult.invalid('Page ranges cannot be empty');
  }

  return PageRangeResult.valid(normalizedParts.join(','));
}
