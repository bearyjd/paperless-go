import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/features/dashboard/dashboard_statistics.dart';

void main() {
  group('DashboardStatistics.fromJson', () {
    test('parses all integer fields', () {
      final stats = DashboardStatistics.fromJson({
        'documents_total': 142,
        'documents_inbox': 5,
        'tag_count': 25,
        'correspondent_count': 18,
        'document_type_count': 8,
        'storage_path_count': 3,
        'character_count': 1234567,
      });
      expect(stats.documentsTotal, 142);
      expect(stats.documentsInbox, 5);
      expect(stats.tagCount, 25);
      expect(stats.correspondentCount, 18);
      expect(stats.documentTypeCount, 8);
      expect(stats.storagePathCount, 3);
      expect(stats.characterCount, 1234567);
    });

    test('defaults all fields to 0 when JSON is empty', () {
      final stats = DashboardStatistics.fromJson({});
      expect(stats.documentsTotal, 0);
      expect(stats.documentsInbox, 0);
      expect(stats.tagCount, 0);
      expect(stats.correspondentCount, 0);
      expect(stats.documentTypeCount, 0);
      expect(stats.storagePathCount, 0);
      expect(stats.characterCount, 0);
    });

    test('handles num (double) values from JSON decoder', () {
      final stats = DashboardStatistics.fromJson({
        'documents_total': 142.0,
        'tag_count': 25.0,
        'correspondent_count': 18.0,
      });
      expect(stats.documentsTotal, 142);
      expect(stats.tagCount, 25);
      expect(stats.correspondentCount, 18);
    });

    test('ignores unknown fields without throwing', () {
      final stats = DashboardStatistics.fromJson({
        'documents_total': 10,
        'inbox_tag': 1,
        'inbox_tag_name': 'inbox',
        'document_file_type_counts': [
          {'mime_type': 'application/pdf', 'mime_type_count': 10}
        ],
        'current_asn': 0,
      });
      expect(stats.documentsTotal, 10);
    });
  });
}
