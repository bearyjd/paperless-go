/// Appends a cache-busting token derived from [modified] to a thumbnail [url].
///
/// Document thumbnails are served from a stable URL (`…/thumb/`) that doesn't
/// change when the rendered page does (e.g. after a rotate). `CachedNetworkImage`
/// keys on the URL, so without a changing token it keeps serving the stale
/// cached image. Tying the token to the document's `modified` timestamp makes
/// the URL change on every edit, forcing a reload — while staying stable (cache
/// hit) when nothing changed.
String cacheBustedThumbnailUrl(String url, DateTime? modified) {
  final version = modified?.millisecondsSinceEpoch ?? 0;
  final separator = url.contains('?') ? '&' : '?';
  return '$url${separator}v=$version';
}
