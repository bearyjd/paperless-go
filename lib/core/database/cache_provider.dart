import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'cache_repository.dart';
import 'database_provider.dart';

part 'cache_provider.g.dart';

@Riverpod(keepAlive: true)
CacheRepository cacheRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return CacheRepository(db);
}
