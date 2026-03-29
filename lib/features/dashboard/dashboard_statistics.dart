import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/api/api_providers.dart';
import '../../core/services/home_widget_service.dart';

part 'dashboard_statistics.g.dart';

/// Parsed result of the Paperless-ngx `GET api/statistics/` endpoint.
class DashboardStatistics {
  final int documentsTotal;
  final int documentsInbox;
  final int tagCount;
  final int correspondentCount;
  final int documentTypeCount;
  final int storagePathCount;

  const DashboardStatistics({
    required this.documentsTotal,
    required this.documentsInbox,
    required this.tagCount,
    required this.correspondentCount,
    required this.documentTypeCount,
    required this.storagePathCount,
  });

  factory DashboardStatistics.fromJson(Map<String, dynamic> json) {
    return DashboardStatistics(
      documentsTotal: (json['documents_total'] as num?)?.toInt() ?? 0,
      documentsInbox: (json['documents_inbox'] as num?)?.toInt() ?? 0,
      tagCount: (json['tag_count'] as num?)?.toInt() ?? 0,
      correspondentCount: (json['correspondent_count'] as num?)?.toInt() ?? 0,
      documentTypeCount: (json['document_type_count'] as num?)?.toInt() ?? 0,
      storagePathCount: (json['storage_path_count'] as num?)?.toInt() ?? 0,
    );
  }
}

@riverpod
class DashboardStatisticsNotifier extends _$DashboardStatisticsNotifier {
  @override
  Future<DashboardStatistics> build() async {
    final json = await ref.watch(paperlessApiProvider).getStatistics();
    final stats = DashboardStatistics.fromJson(json);
    HomeWidgetService.updateDocCount(stats.documentsTotal);
    return stats;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
