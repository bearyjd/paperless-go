// HTTP-mock contract tests for PaperlessApi.
//
// Uses http_mock_adapter's DioAdapter (UrlRequestMatcher — path + method
// only, so query-string construction can change without breaking these
// tests) to replay recorded Paperless-ngx response shapes from
// test/fixtures/api/ without touching a live server. These fixtures encode
// the known API gotchas documented in CLAUDE.md:
//   - `created` is a date-only string, not a datetime
//   - custom field `select` values are {id, label} objects, not plain strings
//   - a note's `user` field is a user object, not just an ID
//   - /api/tasks/ returns a bare list, and an empty list means PENDING
//
// Run: flutter test test/unit/api/paperless_api_test.dart

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:paperless_go/core/api/paperless_api.dart';

dynamic _loadFixture(String name) {
  final file = File('test/fixtures/api/$name');
  return jsonDecode(file.readAsStringSync());
}

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late PaperlessApi api;

  setUp(() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://paperless.example.com/',
        headers: {'Authorization': 'Token test-token'},
        validateStatus: (status) => status != null && status >= 200 && status < 300,
      ),
    );
    // UrlRequestMatcher matches on path + method only, not the full query
    // string — PaperlessApi builds query params from many optional named
    // arguments and these tests care about response parsing, not exact
    // query-string reproduction.
    adapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher(matchMethod: true));
    api = PaperlessApi(dio);
  });

  group('getDocuments — paginated response with known gotchas', () {
    test('parses count/next/previous and both documents', () async {
      adapter.onGet(
        'api/documents/',
        (server) => server.reply(200, _loadFixture('documents_page1.json')),
      );

      final page = await api.getDocuments();

      expect(page.count, equals(2));
      expect(page.next, isNotNull);
      expect(page.previous, isNull);
      expect(page.results, hasLength(2));
    });

    test('parses date-only `created` field without throwing', () async {
      adapter.onGet(
        'api/documents/',
        (server) => server.reply(200, _loadFixture('documents_page1.json')),
      );

      final page = await api.getDocuments();
      final doc = page.results.firstWhere((d) => d.id == 42);

      expect(doc.created, isNotNull);
      expect(doc.created!.year, equals(2026));
      expect(doc.created!.month, equals(3));
      expect(doc.created!.day, equals(14));
    });

    test('parses select-type custom field value as an {id, label} object', () async {
      adapter.onGet(
        'api/documents/',
        (server) => server.reply(200, _loadFixture('documents_page1.json')),
      );

      final page = await api.getDocuments();
      final doc = page.results.firstWhere((d) => d.id == 42);

      expect(doc.customFields, hasLength(1));
      final field = doc.customFields.first;
      expect(field.field, equals(7));
      expect(field.value, isA<Map>());
      expect(field.value['id'], equals(2));
      expect(field.value['label'], equals('Reimbursable'));
    });

    test('parses a note\'s `user` field as a user object, not a bare ID', () async {
      adapter.onGet(
        'api/documents/',
        (server) => server.reply(200, _loadFixture('documents_page1.json')),
      );

      final page = await api.getDocuments();
      final doc = page.results.firstWhere((d) => d.id == 42);

      expect(doc.notes, hasLength(1));
      final note = doc.notes.first;
      expect(note.user, isA<Map>());
      expect(note.user!['id'], equals(1));
      expect(note.user!['username'], equals('jd'));
    });

    test('a document with no tags/custom fields/notes parses to empty lists', () async {
      adapter.onGet(
        'api/documents/',
        (server) => server.reply(200, _loadFixture('documents_page1.json')),
      );

      final page = await api.getDocuments();
      final doc = page.results.firstWhere((d) => d.id == 43);

      expect(doc.tags, isEmpty);
      expect(doc.customFields, isEmpty);
      expect(doc.notes, isEmpty);
      expect(doc.correspondent, isNull);
    });
  });

  group('getCustomFields — select-type field definition', () {
    test('parses select_options from extra_data', () async {
      adapter.onGet(
        'api/custom_fields/',
        (server) => server.reply(200, _loadFixture('custom_fields_select.json')),
      );

      final page = await api.getCustomFields();

      expect(page.results, hasLength(1));
      final field = page.results.first;
      expect(field.dataType, equals('select'));
      final options = field.extraData['select_options'] as List;
      expect(options, hasLength(3));
      expect(options[1]['label'], equals('Reimbursable'));
    });
  });

  group('getTaskStatus — /api/tasks/ poll response', () {
    test('returns PENDING when the task list is empty (not yet queued)', () async {
      adapter.onGet(
        'api/tasks/',
        (server) => server.reply(200, _loadFixture('tasks_poll_pending.json')),
      );

      final status = await api.getTaskStatus('b3f1c2a0-1234-4abc-9def-0123456789ab');

      expect(status['status'], equals('PENDING'));
    });

    test('returns the task object when SUCCESS', () async {
      adapter.onGet(
        'api/tasks/',
        (server) => server.reply(200, _loadFixture('tasks_poll_success.json')),
      );

      final status = await api.getTaskStatus('b3f1c2a0-1234-4abc-9def-0123456789ab');

      expect(status['status'], equals('SUCCESS'));
      expect(status['related_document'], equals('42'));
    });
  });
}
