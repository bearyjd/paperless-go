import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Custom cache manager for document thumbnails with 200MB LRU eviction.
class ThumbnailCacheManager {
  static const key = 'paperless_thumbnails';

  static final instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 2000,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}
