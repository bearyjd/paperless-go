import 'package:flutter_test/flutter_test.dart';

void main() {
  test('_displaySelectValue returns label for matching id', () {
    final options = [
      {'id': 0, 'label': 'Pending'},
      {'id': 1, 'label': 'Approved'},
    ];
    expect(_displaySelectValue(1, options), 'Approved');
    expect(_displaySelectValue(null, options), 'Not set');
    expect(_displaySelectValue(99, options), '99');
  });

  test('_displaySelectValue handles string options', () {
    final options = ['Red', 'Green', 'Blue'];
    expect(_displaySelectValue('Green', options), 'Green');
    expect(_displaySelectValue(null, options), 'Not set');
  });
}

// Extracted helper (matches implementation below)
String _displaySelectValue(dynamic val, List<dynamic> options) {
  if (val == null) return 'Not set';
  for (final opt in options) {
    if (opt is Map) {
      if (opt['id'] == val || opt['id'].toString() == val.toString()) {
        return opt['label'].toString();
      }
    } else if (opt.toString() == val.toString()) {
      return opt.toString();
    }
  }
  return val.toString();
}
