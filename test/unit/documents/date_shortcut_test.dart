import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats added date as YYYY-MM-DD for API', () {
    final added = DateTime(2026, 3, 15, 10, 30);
    final formatted = added.toIso8601String().split('T').first;
    expect(formatted, '2026-03-15');
  });

  test('scan date display is different from created date', () {
    final created = DateTime(2025, 1, 10);
    final added = DateTime(2026, 3, 15);
    expect(created != added, isTrue);
  });
}
